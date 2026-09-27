local _, ns = ...
local FUI = ns.FUI

local module = { frames = {} }
FUI:RegisterModule("unitFrames", module)

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function SafeCall(callback, ...)
    local ok, a, b, c = pcall(callback, ...)
    if not ok or IsSecret(a) or IsSecret(b) or IsSecret(c) then return nil end
    return a, b, c
end

local function SetUnitText(font, kind, unit)
    if not font then return end
    local ok = pcall(function()
        if kind == "None" then
            font:SetText("")
        elseif kind == "Name" then
            font:SetText(UnitName(unit))
        elseif kind == "Level + Name" then
            font:SetFormattedText("%d %s", UnitLevel(unit), UnitName(unit))
        elseif kind == "Health %" then
            if UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100 then
                font:SetFormattedText("%d%%", UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
            else
                local current, maximum = UnitHealth(unit), UnitHealthMax(unit)
                font:SetFormattedText("%d%%", maximum > 0 and current / maximum * 100 or 0)
            end
        elseif kind == "Health" then
            font:SetFormattedText("%d", UnitHealth(unit))
        elseif kind == "Health / Max" then
            font:SetFormattedText("%d / %d", UnitHealth(unit), UnitHealthMax(unit))
        elseif kind == "Power %" then
            if UnitPowerPercent and CurveConstants and CurveConstants.ScaleTo100 then
                font:SetFormattedText("%d%%", UnitPowerPercent(unit, UnitPowerType(unit), true, CurveConstants.ScaleTo100))
            else
                local current, maximum = UnitPower(unit), UnitPowerMax(unit)
                font:SetFormattedText("%d%%", maximum > 0 and current / maximum * 100 or 0)
            end
        elseif kind == "Power" then
            font:SetFormattedText("%d", UnitPower(unit))
        else
            font:SetText("")
        end
    end)
    if not ok then pcall(font.SetText, font, "") end
end

local function FrameSettings(unit)
    local db = FUI.db and FUI.db.unitFrames
    return db and db.frames and db.frames[unit]
end

local function SetHealthColor(frame, settings)
    local color = settings.customHealthColor or FUI.colors.health
    if settings.healthColor == "Class" then
        local _, class = SafeCall(UnitClass, frame.unit)
        if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then color = RAID_CLASS_COLORS[class] end
    end
    frame.health:SetStatusBarColor(color.r or color[1], color.g or color[2], color.b or color[3], settings.healthOpacity or 1)
end

local function SetPowerColor(frame, settings)
    local color = settings.customPowerColor or FUI.colors.power
    if settings.powerColor == "Power Type" then
        local powerType, token = SafeCall(UnitPowerType, frame.unit)
        local candidate = PowerBarColor and (PowerBarColor[token] or PowerBarColor[powerType])
        if candidate then color = candidate end
    end
    frame.power:SetStatusBarColor(color.r or color[1], color.g or color[2], color.b or color[3], settings.powerOpacity or 1)
end

function module:UpdateVisibility(frame)
    local settings = FrameSettings(frame.unit)
    if not settings then return end
    local mode = settings.visibility or "Always"
    local visible = true
    if mode == "Solo" then visible = not IsInGroup()
    elseif mode == "Party" then visible = IsInGroup() and not IsInRaid()
    elseif mode == "Raid" then visible = IsInRaid()
    elseif mode == "In Combat" then visible = InCombatLockdown()
    end
    frame:SetAlpha(visible and 1 or 0)
end

function module:UpdateCast(frame)
    local settings = FrameSettings(frame.unit)
    if not settings or not settings.showCastbar then frame.castbar:Hide() return end
    local ok, cast = pcall(function()
        local name, text, texture, startTime, endTime, _, _, notInterruptible = UnitCastingInfo(frame.unit)
        local channeling = false
        if not name then
            name, text, texture, startTime, endTime, _, notInterruptible = UnitChannelInfo(frame.unit)
            channeling = name and true or false
        end
        if not name then return nil end
        return { name = name, texture = texture, startTime = startTime, endTime = endTime, channeling = channeling, locked = notInterruptible }
    end)
    if not ok or not cast then frame.castbar:Hide() return end
    local rendered = pcall(function()
        frame.castbar.startTime = cast.startTime
        frame.castbar.endTime = cast.endTime
        frame.castbar.channeling = cast.channeling
        frame.castbar:SetMinMaxValues(cast.startTime, cast.endTime)
        frame.castbar:SetValue(cast.channeling and cast.endTime or cast.startTime)
        frame.castName:SetText(cast.name)
        frame.castIcon:SetTexture(cast.texture)
        frame.castbar:SetStatusBarColor(cast.locked and 0.45 or settings.castColor[1], cast.locked and 0.45 or settings.castColor[2], cast.locked and 0.45 or settings.castColor[3], settings.castOpacity)
    end)
    frame.castbar:SetShown(rendered)
end

function module:UpdateIndicators(frame)
    local settings = FrameSettings(frame.unit)
    if not settings then return end
    local marker = SafeCall(GetRaidTargetIndex, frame.unit)
    frame.raidMarker:SetShown(settings.raidMarker and marker ~= nil)
    if marker then pcall(SetRaidTargetIconTexture, frame.raidMarker, marker) end
    local leader = SafeCall(UnitIsGroupLeader, frame.unit)
    frame.leaderIndicator:SetShown(settings.leaderIndicator and leader == true)
    local combat = SafeCall(UnitAffectingCombat, frame.unit)
    frame.combatIndicator:SetShown(settings.combatIndicator and combat == true)
end

function module:UpdateFrame(frame)
    local unit = frame.unit
    local settings = FrameSettings(unit)
    local exists = SafeCall(UnitExists, unit)
    if not settings or exists == false then return end
    local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
    local power, maxPower = UnitPower(unit), UnitPowerMax(unit)
    pcall(frame.health.SetMinMaxValues, frame.health, 0, maxHealth)
    pcall(frame.health.SetValue, frame.health, health)
    pcall(frame.power.SetMinMaxValues, frame.power, 0, maxPower)
    pcall(frame.power.SetValue, frame.power, power)
    SetHealthColor(frame, settings)
    SetPowerColor(frame, settings)
    SetUnitText(frame.leftText, settings.leftText, unit)
    SetUnitText(frame.rightText, settings.rightText, unit)
    SetUnitText(frame.centerText, settings.centerText, unit)
    SetUnitText(frame.extraText, settings.extraText, unit)
    SetUnitText(frame.powerText, settings.powerText, unit)
    local dead, connected = SafeCall(UnitIsDeadOrGhost, unit), SafeCall(UnitIsConnected, unit)
    if dead == true then frame.state:SetText("DEAD") frame.state:Show()
    elseif connected == false then frame.state:SetText("OFFLINE") frame.state:Show()
    else frame.state:Hide() end
    if frame.portrait:IsShown() then pcall(SetPortraitTexture, frame.portrait, unit) end
    self:UpdateCast(frame)
    self:UpdateIndicators(frame)
    self:UpdateVisibility(frame)
end

local function CreateText(frame, anchor, justify)
    local text = FUI:CreateFont(frame.health, 12)
    text:SetPoint(anchor, frame.health, anchor, anchor == "LEFT" and 7 or anchor == "RIGHT" and -7 or 0, 0)
    text:SetJustifyH(justify or anchor)
    return text
end

function module:CreateUnitFrame(unit, positionKey)
    local frame = CreateFrame("Button", "FlowdiUI_" .. unit:gsub("^%l", string.upper), UIParent, "SecureUnitButtonTemplate")
    frame:SetSize(181, 54)
    frame:SetAttribute("unit", unit)
    frame:SetAttribute("type1", "target")
    frame:SetAttribute("type2", "togglemenu")
    frame:RegisterForClicks("AnyUp")
    frame.unit, frame.positionKey = unit, positionKey
    RegisterUnitWatch(frame)
    FUI:RestorePosition(frame, positionKey)
    FUI:CreateBackdrop(frame, 1)
    FUI:MakeMovable(frame, positionKey)

    frame.portrait = frame:CreateTexture(nil, "ARTWORK")
    frame.portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.health = CreateFrame("StatusBar", nil, frame)
    frame.health:SetStatusBarTexture(FUI:GetStatusBarTexture(false))
    frame.healthBG = frame.health:CreateTexture(nil, "BACKGROUND")
    frame.healthBG:SetAllPoints()
    frame.power = CreateFrame("StatusBar", nil, frame)
    frame.power:SetStatusBarTexture(FUI:GetStatusBarTexture(true))
    frame.powerBG = frame.power:CreateTexture(nil, "BACKGROUND")
    frame.powerBG:SetAllPoints()

    frame.castbar = CreateFrame("StatusBar", nil, frame)
    frame.castbar:SetStatusBarTexture(FUI:GetStatusBarTexture(false))
    frame.castbarBG = frame.castbar:CreateTexture(nil, "BACKGROUND")
    frame.castbarBG:SetAllPoints()
    frame.castbarBG:SetColorTexture(0.025, 0.03, 0.045, 0.96)
    frame.castIcon = frame.castbar:CreateTexture(nil, "ARTWORK")
    frame.castIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.castName = FUI:CreateFont(frame.castbar, 10)
    frame.castName:SetPoint("LEFT", 5, 0)
    frame.castName:SetPoint("RIGHT", -42, 0)
    frame.castName:SetJustifyH("LEFT")
    frame.castTime = FUI:CreateFont(frame.castbar, 9)
    frame.castTime:SetPoint("RIGHT", -4, 0)
    frame.castbar:SetScript("OnUpdate", function(self)
        if not self.startTime or not self.endTime then return end
        pcall(function()
            local now = GetTime() * 1000
            local value = self.channeling and math.max(self.startTime, self.endTime - (now - self.startTime)) or math.min(self.endTime, now)
            self:SetValue(value)
            frame.castTime:SetText(string.format("%.1f", math.max(0, self.endTime - now) / 1000))
            if now >= self.endTime then self:Hide() end
        end)
    end)

    frame.raidMarker = frame:CreateTexture(nil, "OVERLAY")
    frame.raidMarker:SetPoint("TOP", frame, "TOP", 0, 10)
    frame.leaderIndicator = frame:CreateTexture(nil, "OVERLAY")
    frame.leaderIndicator:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    frame.leaderIndicator:SetPoint("TOPLEFT", frame, "TOPLEFT", -3, 3)
    frame.combatIndicator = frame:CreateTexture(nil, "OVERLAY")
    frame.combatIndicator:SetColorTexture(1, 0.18, 0.08, 0.95)
    frame.combatIndicator:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)

    frame.leftText = CreateText(frame, "LEFT", "LEFT")
    frame.rightText = CreateText(frame, "RIGHT", "RIGHT")
    frame.centerText = CreateText(frame, "CENTER", "CENTER")
    frame.extraText = FUI:CreateFont(frame.health, 11)
    frame.extraText:SetPoint("TOP", frame.health, "TOP", 0, -3)
    frame.powerText = FUI:CreateFont(frame.power, 9)
    frame.powerText:SetPoint("CENTER", frame.power)
    frame.state = FUI:CreateFont(frame.health, 10)
    frame.state:SetPoint("CENTER", frame.health)
    frame.state:SetTextColor(1, 0.35, 0.35)

    frame:SetScript("OnEnter", function(self)
        local settings = FrameSettings(self.unit)
        if settings and settings.hoverBorder then self.FlowdiBackdrop:SetBackdropBorderColor(0.3, 0.7, 1, 1) end
        if settings and settings.showTooltip and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            pcall(GameTooltip.SetUnit, GameTooltip, self.unit)
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function(self)
        self.FlowdiBackdrop:SetBackdropBorderColor(unpack(FUI.colors.border))
        if GameTooltip then GameTooltip:Hide() end
    end)

    for _, event in ipairs({ "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
        "UNIT_NAME_UPDATE", "UNIT_CONNECTION", "UNIT_PORTRAIT_UPDATE", "UNIT_MODEL_CHANGED", "PLAYER_TARGET_CHANGED",
        "PLAYER_FOCUS_CHANGED", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
        "RAID_TARGET_UPDATE", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
        "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_CHANNEL_STOP" }) do
        frame:RegisterEvent(event)
    end
    frame:SetScript("OnEvent", function(self, event, eventUnit)
        if not eventUnit or eventUnit == self.unit or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then module:UpdateFrame(self) end
    end)
    self.frames[unit] = frame
    return frame
end

local function HideBlizzardFrame(frame)
    if not frame then return end
    frame:SetAlpha(0)
    if frame.EnableMouse then frame:EnableMouse(false) end
    if frame.HookScript and not frame.FlowdiHiddenHook then
        frame.FlowdiHiddenHook = true
        frame:HookScript("OnShow", function(self) self:SetAlpha(0) end)
    end
end

function module:HideDefaults()
    HideBlizzardFrame(PlayerFrame)
    HideBlizzardFrame(TargetFrame)
    HideBlizzardFrame(FocusFrame)
end

function module:SetLocked(locked)
    for _, frame in pairs(self.frames) do
        if locked then frame.FlowdiBackdrop:SetBackdropBorderColor(unpack(FUI.colors.border))
        else frame.FlowdiBackdrop:SetBackdropBorderColor(1, 0.72, 0.12, 1) end
    end
end

local function TexturePath(settings)
    if settings.texture == "Global" then return FUI:GetStatusBarTexture(false) end
    return FUI.textures[settings.texture] or FUI:GetStatusBarTexture(false)
end

function module:ApplyFrame(frame, settings)
    local portraitShown = settings.showPortrait and settings.portraitMode ~= "None"
    local portraitSize = portraitShown and settings.portraitSize or 0
    local powerShown = settings.powerPosition ~= "Hidden" and settings.powerHeight > 0
    local powerHeight, gap = powerShown and settings.powerHeight or 0, powerShown and 2 or 0
    local totalHeight = settings.healthHeight + powerHeight + gap
    local totalWidth = settings.width + (portraitShown and portraitSize + 2 or 0)
    frame:SetSize(totalWidth, totalHeight)
    frame:SetScale((FUI.db.scale or 1) * (FUI.db.unitFrames.scale or 1))
    frame:SetFrameStrata(settings.frameStrata or "MEDIUM")

    frame.portrait:ClearAllPoints()
    frame.portrait:SetShown(portraitShown)
    if portraitShown then
        frame.portrait:SetSize(portraitSize, totalHeight)
        frame.portrait:SetPoint(settings.portraitPosition == "Right" and "RIGHT" or "LEFT", frame)
    end
    local leftInset = portraitShown and settings.portraitPosition == "Left" and portraitSize + 2 or 1
    local rightInset = portraitShown and settings.portraitPosition == "Right" and portraitSize + 2 or 1
    frame.health:ClearAllPoints()
    frame.power:ClearAllPoints()
    if settings.powerPosition == "Above Health Bar" and powerShown then
        frame.power:SetPoint("TOPLEFT", frame, "TOPLEFT", leftInset, -1)
        frame.power:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -rightInset, -1)
        frame.power:SetHeight(powerHeight)
        frame.health:SetPoint("TOPLEFT", frame.power, "BOTTOMLEFT", 0, -gap)
        frame.health:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -rightInset, 1)
    else
        frame.health:SetPoint("TOPLEFT", frame, "TOPLEFT", leftInset, -1)
        frame.health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -rightInset, -1)
        frame.health:SetHeight(settings.healthHeight)
        if powerShown then
            frame.power:SetPoint("TOPLEFT", frame.health, "BOTTOMLEFT", 0, -gap)
            frame.power:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -rightInset, 1)
        end
    end
    frame.power:SetShown(powerShown)
    frame.health:SetStatusBarTexture(TexturePath(settings))
    frame.power:SetStatusBarTexture(FUI:GetStatusBarTexture(true))
    local hb, pb = settings.healthBackground, settings.powerBackground
    frame.healthBG:SetColorTexture(hb[1], hb[2], hb[3], hb[4] or 1)
    frame.powerBG:SetColorTexture(pb[1], pb[2], pb[3], pb[4] or 1)
    frame.castbar:ClearAllPoints()
    frame.castbar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -3)
    frame.castbar:SetSize(totalWidth, settings.castHeight)
    frame.castIcon:SetShown(settings.showCastIcon)
    frame.castIcon:ClearAllPoints()
    frame.castIcon:SetPoint("RIGHT", frame.castbar, "LEFT", -2, 0)
    frame.castIcon:SetSize(settings.castHeight, settings.castHeight)
    frame.raidMarker:SetSize(settings.raidMarkerSize, settings.raidMarkerSize)
    frame.leaderIndicator:SetSize(settings.leaderIndicatorSize, settings.leaderIndicatorSize)
    frame.combatIndicator:SetSize(settings.combatIndicatorSize, settings.combatIndicatorSize)
    frame.FlowdiBackdrop:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = settings.borderSize or 1 })
    frame.FlowdiBackdrop:SetBackdropColor(0.01, 0.015, 0.025, 0.95)
    frame.FlowdiBackdrop:SetBackdropBorderColor(unpack(FUI.colors.border))
    for _, text in ipairs({ frame.leftText, frame.rightText, frame.centerText, frame.extraText }) do
        text:SetFont(FUI:GetModuleFontPath("unitFrames"), settings.textSize, FUI.db.global.fontOutline)
    end
    frame.powerText:SetFont(FUI:GetModuleFontPath("unitFrames"), math.max(8, settings.textSize - 2), FUI.db.global.fontOutline)
    self:UpdateFrame(frame)
end

function module:Apply()
    if InCombatLockdown() then return end
    for unit, frame in pairs(self.frames) do
        local settings = FrameSettings(unit)
        if settings then self:ApplyFrame(frame, settings) end
    end
end

function module:Initialize()
    self:CreateUnitFrame("player", "player")
    self:CreateUnitFrame("target", "target")
    self:CreateUnitFrame("focus", "focus")
    self:HideDefaults()
    self:Apply()
end

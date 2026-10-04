local _, ns = ...
local FUI = ns.FUI

local module = { units = {}, previews = {} }
FUI:RegisterModule("nameplates", module)

local function Color(dbColor, fallback)
    local value = dbColor or fallback
    return value[1], value[2], value[3], value[4] or 1
end

local function FindHealth(frame)
    return frame and (frame.healthBar or frame.HealthBar or
        frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar)
end

local function FindCast(frame)
    return frame and (frame.castBar or frame.CastBar or frame.castbar)
end

local function FindAuraFrame(frame)
    return frame and (frame.BuffFrame or frame.buffFrame or frame.AurasFrame or frame.auras)
end

local function BarTexture(value, secondary)
    if value and value ~= "Global" and FUI.textures[value] then return FUI.textures[value] end
    return FUI:GetStatusBarTexture(secondary)
end

local function ConfigureBorder(bar)
    if not bar.FlowdiBorder then
        local border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetFrameLevel(math.max(0, bar:GetFrameLevel() - 1))
        bar.FlowdiBorder = border
    end
    local size = math.max(1, FUI.db.nameplates.borderSize or 1)
    bar.FlowdiBorder:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = size })
    bar.FlowdiBorder:SetBackdropColor(0.008, 0.016, 0.035, FUI.db.nameplates.backgroundAlpha or 0.82)
    bar.FlowdiBorder:SetBackdropBorderColor(unpack(FUI.colors.border))
    return bar.FlowdiBorder
end

local function HealthColor(unit)
    local db = FUI.db.nameplates
    if UnitIsTapDenied and UnitIsTapDenied(unit) then return Color(db.tappedColor, { 0.42, 0.44, 0.48, 1 }) end
    if db.threatColor and UnitCanAttack("player", unit) then
        local status = UnitThreatSituation and UnitThreatSituation("player", unit)
        if status == 3 then return Color(db.threatTankColor, { 0.92, 0.16, 0.12, 1 }) end
        if status == 2 then return Color(db.threatHighColor, { 1.0, 0.48, 0.08, 1 }) end
        if status == 1 then return Color(db.threatLowColor, { 0.96, 0.78, 0.10, 1 }) end
    end
    if db.classColorPlayers and UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then return color.r, color.g, color.b, 1 end
    end
    if UnitIsFriend("player", unit) then return Color(db.friendlyColor, { 0.16, 0.68, 0.38, 1 }) end
    if UnitCanAttack("player", unit) then return Color(db.hostileColor, { 0.78, 0.16, 0.18, 1 }) end
    return Color(db.neutralColor, { 0.82, 0.68, 0.16, 1 })
end

function module:CreateElements(frame, health)
    if frame.FlowdiElements then return frame.FlowdiElements end
    local elements = {}
    elements.percent = FUI:CreateFont(health, 9)
    elements.percent:SetPoint("RIGHT", health, "RIGHT", -3, 0)
    elements.percent:SetJustifyH("RIGHT")
    elements.level = FUI:CreateFont(health, 9)
    elements.level:SetPoint("LEFT", health, "LEFT", 3, 0)
    elements.level:SetJustifyH("LEFT")
    elements.threat = FUI:CreateFont(health, 9)
    elements.threat:SetPoint("BOTTOMRIGHT", health, "TOPRIGHT", 0, 3)
    elements.threat:SetTextColor(1, 0.74, 0.18)

    elements.target = CreateFrame("Frame", nil, health, "BackdropTemplate")
    elements.target:SetPoint("TOPLEFT", -3, 3)
    elements.target:SetPoint("BOTTOMRIGHT", 3, -3)
    elements.target:SetFrameLevel(health:GetFrameLevel() + 4)
    elements.target:SetBackdrop({ edgeFile = FUI.textures.Flat, edgeSize = 2 })
    elements.target:SetBackdropBorderColor(0.22, 0.68, 1, 0.95)
    elements.target:Hide()

    elements.leftArrow = FUI:CreateFont(health, 18)
    elements.leftArrow:SetPoint("RIGHT", health, "LEFT", -5, 0)
    elements.leftArrow:SetText(">")
    elements.leftArrow:SetTextColor(0.35, 0.75, 1)
    elements.rightArrow = FUI:CreateFont(health, 18)
    elements.rightArrow:SetPoint("LEFT", health, "RIGHT", 5, 0)
    elements.rightArrow:SetText("<")
    elements.rightArrow:SetTextColor(0.35, 0.75, 1)
    frame.FlowdiElements = elements
    return elements
end

function module:StyleAuras(frame)
    local auraFrame = FindAuraFrame(frame)
    if not auraFrame or not auraFrame.GetChildren then return end
    local size = FUI.db.nameplates.auraSize or 22
    local maximum = FUI.db.nameplates.maxDebuffs or 4
    local index = 0
    for _, button in ipairs({ auraFrame:GetChildren() }) do
        local icon = button.Icon or button.icon or button.IconTexture
        if icon then
            index = index + 1
            button:SetSize(size, size)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            if not button.FlowdiAuraBorder then
                button.FlowdiAuraBorder = FUI:CreateBackdrop(button, 1)
            end
            button:SetShown(index <= maximum)
        end
    end
end

function module:UpdateCast(unit, frame)
    local cast = FindCast(frame)
    if not cast then return end
    local name, _, texture, startTime, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
    local channel
    if not name then
        name, _, texture, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
        channel = name ~= nil
    end
    local active = name ~= nil
    if cast.FlowdiTimer then
        cast.FlowdiTimer:SetShown(active and FUI.db.nameplates.castTimer)
        cast.FlowdiTimer.unit = active and unit or nil
        cast.FlowdiTimer.endTime = active and endTime and endTime / 1000 or nil
    end
    local icon = cast.Icon or cast.icon
    if icon then
        icon:SetShown(FUI.db.nameplates.castIcon and active)
        if active and texture then icon:SetTexture(texture) end
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    if active then
        local color = notInterruptible and FUI.db.nameplates.castUninterruptibleColor or FUI.db.nameplates.castColor
        cast:SetStatusBarColor(Color(color, { 0.22, 0.62, 1, 1 }))
        cast.FlowdiChannel = channel
    end
end

function module:StyleCast(unit, frame, health)
    local cast = FindCast(frame)
    if not cast then return end
    local db = FUI.db.nameplates
    cast:SetStatusBarTexture(BarTexture(db.castTexture, true))
    cast:SetSize(db.width, db.castHeight)
    cast:ClearAllPoints()
    cast:SetPoint("TOP", health, "BOTTOM", 0, db.castOffsetY or -3)
    ConfigureBorder(cast)
    local castText = cast.Text or cast.text or cast.CastName or cast.castName
    if castText and castText.SetFont then
        castText:SetFont(FUI:GetModuleFontPath("nameplates"), math.max(8, db.fontSize - 2), FUI.db.global.fontOutline)
    end
    if not cast.FlowdiTimer then
        local timer = FUI:CreateFont(cast, math.max(8, db.fontSize - 2))
        timer:SetPoint("RIGHT", cast, "RIGHT", -3, 0)
        timer:SetJustifyH("RIGHT")
        cast.FlowdiTimer = timer
    end
    self:UpdateCast(unit, frame)
end

function module:UpdatePlate(unit)
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
    local frame = plate and plate.UnitFrame
    if not frame then return end
    local health = FindHealth(frame)
    if not health then return end
    local db = FUI.db.nameplates
    local elements = self:CreateElements(frame, health)
    local isTarget = UnitIsUnit(unit, "target")
    local friendly = UnitIsFriend("player", unit)
    local nameOnly = friendly and db.friendlyNameOnly
    local r, g, b = HealthColor(unit)
    health:SetStatusBarColor(r, g, b)
    health:SetShown(not nameOnly)
    local cast = FindCast(frame)
    if cast and nameOnly then cast:Hide() end
    local current, maximum = UnitHealth(unit) or 0, UnitHealthMax(unit) or 0
    elements.percent:SetText(db.healthText and maximum > 0 and string.format("%d%%", math.floor(current / maximum * 100 + 0.5)) or "")
    local level = UnitLevel(unit)
    elements.level:SetText(db.levelText and level and level > 0 and level or (db.levelText and level == -1 and "??" or ""))
    elements.target:SetShown(db.targetGlow and isTarget and not nameOnly)
    elements.leftArrow:SetShown(db.targetArrows and isTarget and not nameOnly)
    elements.rightArrow:SetShown(db.targetArrows and isTarget and not nameOnly)
    local _, status, threat = UnitDetailedThreatSituation and UnitDetailedThreatSituation("player", unit)
    elements.threat:SetText(db.threatPercent and threat and status and string.format("%d%%", threat) or "")
    frame:SetScale(isTarget and (db.targetScale or 1) or 1)
    frame:SetAlpha(isTarget and 1 or (db.nonTargetAlpha or 1))
    self:UpdateCast(unit, frame)
    self:StyleAuras(frame)
end

function module:StylePlate(unit)
    if not FUI.db.modules.nameplates then return end
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
    local frame = plate and plate.UnitFrame
    if not frame then return end
    self.units[unit] = frame
    local db = FUI.db.nameplates
    local health = FindHealth(frame)
    if health then
        health:SetStatusBarTexture(BarTexture(db.healthTexture, false))
        health:SetSize(db.width, db.height)
        ConfigureBorder(health)
        self:CreateElements(frame, health)
        self:StyleCast(unit, frame, health)
    end
    local name = frame.name or frame.Name
    if name and name.SetFont then
        name:SetFont(FUI:GetModuleFontPath("nameplates"), db.fontSize, FUI.db.global.fontOutline)
        name:SetShadowOffset(0, 0)
        if health then
            name:ClearAllPoints()
            name:SetPoint("BOTTOM", health, "TOP", 0, 3)
        end
    end
    if frame.selectionHighlight then frame.selectionHighlight:SetAlpha(0) end
    frame.FlowdiStyled = true
    self:UpdatePlate(unit)
end

function module:StyleVisiblePlates()
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        if plate.namePlateUnitToken then self:StylePlate(plate.namePlateUnitToken) end
    end
end

function module:RegisterPreview(preview)
    self.previews[#self.previews + 1] = preview
    self:UpdatePreview(preview)
end

function module:UpdatePreview(preview)
    if not preview then return end
    local db = FUI.db.nameplates
    preview.health:SetSize(db.width, db.height)
    preview.health:SetStatusBarTexture(BarTexture(db.healthTexture, false))
    preview.health:SetStatusBarColor(Color(db.hostileColor, { 0.78, 0.16, 0.18, 1 }))
    preview.health:SetValue(64)
    preview.health.border:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = db.borderSize or 1 })
    preview.health.border:SetBackdropColor(0.008, 0.016, 0.035, db.backgroundAlpha or 0.82)
    preview.health.border:SetBackdropBorderColor(unpack(FUI.colors.border))
    preview.healthText:SetShown(db.healthText)
    preview.level:SetShown(db.levelText)
    preview.leftArrow:SetShown(db.targetArrows)
    preview.rightArrow:SetShown(db.targetArrows)
    preview.glow:SetShown(db.targetGlow)
    preview.cast:SetSize(db.width, db.castHeight)
    preview.cast:ClearAllPoints()
    preview.cast:SetPoint("TOP", preview.health, "BOTTOM", 0, db.castOffsetY or -3)
    preview.cast:SetStatusBarTexture(BarTexture(db.castTexture, true))
    preview.cast:SetStatusBarColor(Color(db.castColor, { 0.22, 0.62, 1, 1 }))
    preview.cast.border:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = db.borderSize or 1 })
    preview.cast.border:SetBackdropColor(0.008, 0.016, 0.035, db.backgroundAlpha or 0.82)
    preview.cast.border:SetBackdropBorderColor(unpack(FUI.colors.border))
    preview.castTimer:SetShown(db.castTimer)
    preview.castIcon:SetShown(db.castIcon)
    preview.castIcon:SetSize(math.max(14, db.castHeight + 2), math.max(14, db.castHeight + 2))
    preview.name:SetFont(FUI:GetModuleFontPath("nameplates"), db.fontSize, FUI.db.global.fontOutline)
    for index, aura in ipairs(preview.auras) do
        aura:SetSize(db.auraSize, db.auraSize)
        aura:SetShown(index <= db.maxDebuffs)
    end
end

function module:UpdatePreviews()
    for _, preview in ipairs(self.previews) do self:UpdatePreview(preview) end
end

function module:ApplyCVars()
    local db = FUI.db.nameplates
    if not SetCVar then return end
    pcall(SetCVar, "nameplateShowFriends", db.showFriendly and "1" or "0")
    pcall(SetCVar, "nameplateShowFriendlyPlayers", db.showFriendly and "1" or "0")
    pcall(SetCVar, "nameplateShowFriendlyNPCs", db.showFriendlyNPCs and "1" or "0")
    pcall(SetCVar, "nameplateShowFriendlyNpcs", db.showFriendlyNPCs and "1" or "0")
    pcall(SetCVar, "nameplateShowEnemyPets", db.showEnemyPets and "1" or "0")
    pcall(SetCVar, "nameplateShowOnlyNameForFriendlyPlayerUnits", db.friendlyNameOnly and "1" or "0")
    if C_CVar and C_CVar.SetCVarBitfield and Enum and Enum.NamePlateStackType then
        pcall(C_CVar.SetCVarBitfield, "nameplateStackingTypes", Enum.NamePlateStackType.Enemy, db.stacking and true or false)
    else
        pcall(SetCVar, "nameplateMotion", db.stacking and "1" or "0")
    end
    pcall(SetCVar, "nameplateOverlapV", tostring(db.verticalSpacing or 1))
end

function module:Apply()
    self:ApplyCVars()
    self:StyleVisiblePlates()
    self:UpdatePreviews()
end

function module:Initialize()
    local events = CreateFrame("Frame")
    for _, event in ipairs({
        "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED",
        "UNIT_HEALTH", "UNIT_AURA", "UNIT_THREAT_LIST_UPDATE", "UNIT_THREAT_SITUATION_UPDATE",
        "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
    }) do pcall(events.RegisterEvent, events, event) end
    events:SetScript("OnEvent", function(_, event, unit)
        if event == "NAME_PLATE_UNIT_ADDED" then
            module:StylePlate(unit)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            module.units[unit] = nil
        elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            module:Apply()
        elseif unit and unit:match("^nameplate") then
            module:UpdatePlate(unit)
        end
    end)
    events:SetScript("OnUpdate", function(_, elapsed)
        module.elapsed = (module.elapsed or 0) + elapsed
        if module.elapsed < 0.08 then return end
        module.elapsed = 0
        for unit, frame in pairs(module.units) do
            if UnitExists(unit) then
                local cast = FindCast(frame)
                local timer = cast and cast.FlowdiTimer
                if timer and timer:IsShown() and timer.endTime then timer:SetText(string.format("%.1f", math.max(0, timer.endTime - GetTime()))) end
            end
        end
    end)
    self.events = events
    self:Apply()
end

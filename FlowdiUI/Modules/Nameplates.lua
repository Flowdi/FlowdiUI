local _, ns = ...
local FUI = ns.FUI

-- CompactUnitFrame is repainted continuously by Blizzard. FlowdiUI therefore
-- renders a separate presentation layer and keeps the native base for clicks.
local module = { units = {}, previews = {} }
FUI:RegisterModule("nameplates", module)

local function Color(value, fallback)
    value = value or fallback
    return value[1], value[2], value[3], value[4] or 1
end

local function BarTexture(value, secondary)
    if value and value ~= "Global" and FUI.textures[value] then return FUI.textures[value] end
    return FUI:GetStatusBarTexture(secondary)
end

local function SafeNumber(value, fallback)
    local ok, result = pcall(tonumber, value)
    return ok and result or fallback
end

local function IsTargetUnit(unit, plate)
    -- UnitIsUnit/GUID comparison is authoritative. On the Forever client,
    -- GetNamePlateForUnit("target") can briefly return a recycled plate and
    -- made target-only effects appear on unrelated mobs.
    if UnitIsUnit then
        local ok, result = pcall(UnitIsUnit, unit, "target")
        if ok then return result and true or false end
    end
    if UnitGUID then
        local okUnit, unitGUID = pcall(UnitGUID, unit)
        local okTarget, targetGUID = pcall(UnitGUID, "target")
        if okUnit and okTarget and unitGUID and targetGUID then return unitGUID == targetGUID end
    end
    local targetPlate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit("target")
    return targetPlate ~= nil and targetPlate == plate
end

local function UnitColor(unit)
    local db = FUI.db.nameplates
    if UnitIsTapDenied and UnitIsTapDenied(unit) then return Color(db.tappedColor, { .42, .44, .48, 1 }) end
    if db.threatColor and UnitCanAttack("player", unit) and UnitThreatSituation then
        local ok, status = pcall(UnitThreatSituation, "player", unit)
        if ok and status == 3 then return Color(db.threatTankColor, { .92, .16, .12, 1 }) end
        if ok and status == 2 then return Color(db.threatHighColor, { 1, .48, .08, 1 }) end
        if ok and status == 1 then return Color(db.threatLowColor, { .96, .78, .10, 1 }) end
    end
    if db.classColorPlayers and UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        local classColor = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if classColor then return classColor.r, classColor.g, classColor.b, 1 end
    end
    if UnitIsFriend("player", unit) then return Color(db.friendlyColor, { .16, .68, .38, 1 }) end
    if UnitCanAttack("player", unit) then return Color(db.hostileColor, { .78, .16, .18, 1 }) end
    return Color(db.neutralColor, { .82, .68, .16, 1 })
end

local function CreateBorder(parent)
    local border = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetFrameLevel(math.max(0, parent:GetFrameLevel() - 1))
    return border
end

local function ApplyBorder(border)
    local db = FUI.db.nameplates
    border:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = math.max(1, db.borderSize or 1) })
    border:SetBackdropColor(.008, .016, .035, db.backgroundAlpha or .82)
    border:SetBackdropBorderColor(unpack(FUI.colors.border))
end

function module:SuppressNative(plate, suppress)
    local native = plate and plate.UnitFrame
    if not native then return end
    native:SetAlpha(suppress and 0 or 1)
    if suppress and not native.FlowdiAlphaHooked then
        native.FlowdiAlphaHooked = true
        hooksecurefunc(native, "SetAlpha", function(self, alpha)
            if FUI.db and FUI.db.modules.nameplates and alpha ~= 0 and not self.FlowdiSettingAlpha then
                self.FlowdiSettingAlpha = true
                self:SetAlpha(0)
                self.FlowdiSettingAlpha = nil
            end
        end)
    end
end

function module:CreateCustomPlate(plate)
    if plate.FlowdiPlate then return plate.FlowdiPlate end
    local custom = CreateFrame("Frame", nil, plate)
    custom:SetSize(260, 90)
    custom:SetPoint("CENTER", plate, "CENTER", 0, 0)
    custom:SetFrameStrata(plate:GetFrameStrata())
    custom:SetFrameLevel((plate:GetFrameLevel() or 0) + 20)
    custom:EnableMouse(false)

    local health = CreateFrame("StatusBar", nil, custom)
    health:SetPoint("CENTER", custom, "CENTER", 0, 0)
    health:SetMinMaxValues(0, 1)
    health:SetValue(1)
    health.border = CreateBorder(health)
    custom.health = health
    custom.name = FUI:CreateFont(custom, 11)
    custom.name:SetPoint("BOTTOM", health, "TOP", 0, 3)
    custom.name:SetJustifyH("CENTER")
    custom.level = FUI:CreateFont(health, 9)
    custom.level:SetPoint("LEFT", 3, 0)
    custom.percent = FUI:CreateFont(health, 9)
    custom.percent:SetPoint("RIGHT", -3, 0)
    custom.threat = FUI:CreateFont(custom, 9)
    custom.threat:SetPoint("BOTTOMRIGHT", health, "TOPRIGHT", 0, 3)
    custom.threat:SetTextColor(1, .74, .18)

    custom.target = CreateFrame("Frame", nil, health, "BackdropTemplate")
    custom.target:SetPoint("TOPLEFT", -3, 3)
    custom.target:SetPoint("BOTTOMRIGHT", 3, -3)
    custom.target:SetFrameLevel(health:GetFrameLevel() + 5)
    custom.target:SetBackdrop({ edgeFile = FUI.textures.Flat, edgeSize = 2 })
    custom.target:Hide()
    custom.targetGlow = CreateFrame("Frame", nil, custom)
    custom.targetGlow:SetPoint("CENTER", health, "CENTER", 0, 0)
    custom.targetGlow:SetFrameLevel(health:GetFrameLevel() + 3)
    custom.targetGlow:EnableMouse(false)
    custom.targetGlow.layers = {}
    for index = 1, 3 do
        local glow = custom.targetGlow:CreateTexture(nil, "OVERLAY")
        glow:SetPoint("CENTER")
        glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        glow:SetBlendMode("ADD")
        glow:SetVertexColor(.18, .62, 1, .72 / index)
        custom.targetGlow.layers[index] = glow
    end
    custom.targetGlow.anim = custom.targetGlow:CreateAnimationGroup()
    custom.targetGlow.anim:SetLooping("BOUNCE")
    local fade = custom.targetGlow.anim:CreateAnimation("Alpha")
    fade:SetFromAlpha(.38)
    fade:SetToAlpha(1)
    fade:SetDuration(.65)
    fade:SetSmoothing("IN_OUT")
    custom.targetGlow:Hide()
    custom.leftArrow = FUI:CreateFont(custom, 18)
    custom.leftArrow:SetPoint("RIGHT", health, "LEFT", -5, 0)
    custom.leftArrow:SetText(">")
    custom.leftArrow:SetTextColor(.35, .75, 1)
    custom.rightArrow = FUI:CreateFont(custom, 18)
    custom.rightArrow:SetPoint("LEFT", health, "RIGHT", 5, 0)
    custom.rightArrow:SetText("<")
    custom.rightArrow:SetTextColor(.35, .75, 1)

    local cast = CreateFrame("StatusBar", nil, custom)
    cast:SetMinMaxValues(0, 1)
    cast.border = CreateBorder(cast)
    cast.name = FUI:CreateFont(cast, 9)
    cast.name:SetPoint("LEFT", 3, 0)
    cast.name:SetJustifyH("LEFT")
    cast.timer = FUI:CreateFont(cast, 9)
    cast.timer:SetPoint("RIGHT", -3, 0)
    cast.timer:SetJustifyH("RIGHT")
    cast.icon = cast:CreateTexture(nil, "ARTWORK")
    cast.icon:SetPoint("RIGHT", cast, "LEFT", -3, 0)
    cast.icon:SetTexCoord(.08, .92, .08, .92)
    custom.cast = cast
    custom.raidIcon = custom:CreateTexture(nil, "OVERLAY")
    custom.raidIcon:SetPoint("BOTTOM", custom.name, "TOP", 0, 2)
    custom.raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    custom.raidIcon:SetSize(18, 18)
    custom.raidIcon:Hide()
    plate.FlowdiPlate = custom
    return custom
end

function module:CreateAuras(custom, unit)
    local db = FUI.db.nameplates
    local signature = table.concat({ db.maxDebuffs or 0, db.auraSize or 22, tostring(db.auraDuration), tostring(db.auraStacks) }, ":")
    if custom.auraSignature == signature and custom.auras then
        if custom.auras.SetUnit then custom.auras:SetUnit(unit) end
        return
    end
    if custom.auraSignature == signature and custom.auraPending then return end
    if custom.auras and FUI.AuraEngine then FUI.AuraEngine:Release(custom.auras) end
    custom.auras, custom.auraSignature, custom.auraPending = nil, signature, true
    if not FUI.AuraEngine or (db.maxDebuffs or 0) <= 0 then custom.auraPending = nil return end
    local settings = {
        size = db.auraSize or 22, spacing = 2, perRow = math.max(1, db.maxDebuffs or 4), rows = 1,
        point = "Bottom Left", relativePoint = "Top Left", x = 0, y = 6,
        growthX = "Right", growthY = "Up", borderSize = 1, cooldown = true, tooltip = true,
        showDuration = db.auraDuration ~= false, showStacks = db.auraStacks ~= false,
        durationSize = 9, stackSize = 9, durationPosition = "Bottom", stackPosition = "Top Right",
    }
    FUI.AuraEngine:QueueCreate(function(container)
        custom.auraPending = nil
        if custom and custom.GetParent and custom:GetParent() and custom.auraSignature == signature then
            custom.auras = container
        elseif container then
            FUI.AuraEngine:Release(container)
        end
    end, custom, unit, "debuff", settings, "nameplates", custom:GetFrameLevel() + 7,
        custom.health, db.maxDebuffs, { groupKey = "FlowdiNameplateDebuffs", filter = "HARMFUL" })
end

function module:Layout(custom)
    local db = FUI.db.nameplates
    custom:SetSize(math.max(260, db.width + 80), 90)
    custom.health:SetSize(db.width, db.height)
    custom.health:SetStatusBarTexture(BarTexture(db.healthTexture, false))
    ApplyBorder(custom.health.border)
    custom.targetGlow:SetSize(db.width + 22, db.height + 22)
    for index, glow in ipairs(custom.targetGlow.layers) do
        glow:SetSize(db.width + 15 + index * 7, db.height + 15 + index * 7)
    end
    custom.name:SetFont(FUI:GetModuleFontPath("nameplates"), db.fontSize, FUI.db.global.fontOutline)
    custom.name:ClearAllPoints()
    if db.namePosition == "Inside" then custom.name:SetPoint("CENTER", custom.health, "CENTER", 0, 0)
    else custom.name:SetPoint("BOTTOM", custom.health, "TOP", 0, 3) end
    custom.name:SetShown(db.namePosition ~= "Hidden")
    custom.cast:SetSize(db.width, db.castHeight)
    custom.cast:ClearAllPoints()
    custom.cast:SetPoint("TOP", custom.health, "BOTTOM", 0, db.castOffsetY or -3)
    custom.cast:SetStatusBarTexture(BarTexture(db.castTexture, true))
    ApplyBorder(custom.cast.border)
    custom.cast.name:SetFont(FUI:GetModuleFontPath("nameplates"), math.max(8, db.fontSize - 2), FUI.db.global.fontOutline)
    custom.cast.timer:SetFont(FUI:GetModuleFontPath("nameplates"), math.max(8, db.fontSize - 2), FUI.db.global.fontOutline)
    custom.cast.icon:SetSize(math.max(14, db.castHeight + 2), math.max(14, db.castHeight + 2))
end

function module:UpdateCast(custom, unit)
    local db = FUI.db.nameplates
    local name, _, texture, startTime, endTime, _, _, notInterruptible = UnitCastingInfo(unit)
    local channel = false
    if not name then
        name, _, texture, startTime, endTime, _, notInterruptible = UnitChannelInfo(unit)
        channel = name ~= nil
    end
    if not name then custom.cast:Hide() return end
    custom.cast:Show()
    custom.cast.name:SetShown(db.castText ~= false)
    custom.cast.name:SetText(db.castText ~= false and name or "")
    custom.cast.timer:SetShown(db.castTimer)
    custom.cast.icon:SetShown(db.castIcon)
    if texture then custom.cast.icon:SetTexture(texture) end
    custom.cast.startTime = SafeNumber(startTime, 0) / 1000
    custom.cast.endTime = SafeNumber(endTime, 0) / 1000
    custom.cast.channel = channel
    custom.cast:SetStatusBarColor(Color(notInterruptible and db.castUninterruptibleColor or db.castColor, { .22, .62, 1, 1 }))
end

function module:UpdatePlate(unit)
    local record = self.units[unit]
    if not record or not UnitExists(unit) then return end
    local plate, custom = record.plate, record.custom
    self:SuppressNative(plate, true)
    self:Layout(custom)
    local db = FUI.db.nameplates
    local friendly = UnitIsFriend("player", unit)
    local nameOnly = friendly and db.friendlyNameOnly
    local target = IsTargetUnit(unit, plate)
    custom:SetScale(target and (db.targetScale or 1) or 1)
    custom:SetAlpha(target and 1 or (db.nonTargetAlpha or 1))
    custom.name:SetText(UnitName(unit) or "")
    custom.health:SetStatusBarColor(UnitColor(unit))
    local okHealth, current = pcall(UnitHealth, unit)
    local okMax, maximum = pcall(UnitHealthMax, unit)
    current, maximum = SafeNumber(okHealth and current, 0), math.max(1, SafeNumber(okMax and maximum, 1))
    custom.health:SetMinMaxValues(0, maximum)
    custom.health:SetValue(math.max(0, current))
    local percent = math.floor((current / maximum) * 100 + .5)
    local mode = db.healthTextMode or (db.healthText and "Percent" or "None")
    if mode == "Current" then custom.percent:SetText(tostring(current))
    elseif mode == "Current / Max" then custom.percent:SetText(current .. " / " .. maximum)
    elseif mode == "Percent" then custom.percent:SetText(percent .. "%")
    else custom.percent:SetText("") end
    local level = UnitLevel(unit)
    custom.level:SetText(db.levelText and (level == -1 and "??" or level or "") or "")
    custom.health:SetShown(not nameOnly)
    custom.level:SetShown(not nameOnly)
    custom.percent:SetShown(not nameOnly)
    custom.leftArrow:SetShown(db.targetArrows and target and not nameOnly)
    custom.rightArrow:SetShown(db.targetArrows and target and not nameOnly)
    local _, status, threat = UnitDetailedThreatSituation and UnitDetailedThreatSituation("player", unit)
    threat = SafeNumber(threat, nil)
    custom.threat:SetText(db.threatPercent and status and threat and string.format("%d%%", threat) or "")
    local raidIndex = GetRaidTargetIndex and GetRaidTargetIndex(unit)
    custom.raidIcon:SetShown(db.raidMarker ~= false and raidIndex ~= nil)
    if raidIndex and SetRaidTargetIconTexture then SetRaidTargetIconTexture(custom.raidIcon, raidIndex) end
    local execute = (db.executeThreshold or 0) > 0 and percent <= db.executeThreshold and UnitCanAttack("player", unit)
    custom.target:SetBackdropBorderColor(1, .35, .08, 1)
    custom.target:SetShown(execute and db.executeGlow and not nameOnly)
    local showGlow = db.targetGlow and target and not nameOnly
    custom.targetGlow:SetShown(showGlow)
    if showGlow then
        if not custom.targetGlow.anim:IsPlaying() then custom.targetGlow.anim:Play() end
    else
        custom.targetGlow.anim:Stop()
    end
    if nameOnly then custom.cast:Hide() else self:UpdateCast(custom, unit) end
    self:CreateAuras(custom, unit)
    if custom.auras then custom.auras:SetShown(not nameOnly and (db.maxDebuffs or 0) > 0) end
end

function module:StylePlate(unit)
    if not FUI.db.modules.nameplates then return end
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
    if not plate then return end
    local custom = self:CreateCustomPlate(plate)
    custom.unit = unit
    custom:Show()
    self.units[unit] = { plate = plate, custom = custom }
    self:UpdatePlate(unit)
end

function module:ReleasePlate(unit)
    local record = self.units[unit]
    if not record then return end
    if record.custom then record.custom:Hide() end
    self:SuppressNative(record.plate, false)
    self.units[unit] = nil
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
    preview.health:SetStatusBarColor(Color(db.hostileColor, { .78, .16, .18, 1 }))
    preview.health:SetValue(64)
    preview.health.border:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = db.borderSize or 1 })
    preview.health.border:SetBackdropColor(.008, .016, .035, db.backgroundAlpha or .82)
    preview.health.border:SetBackdropBorderColor(unpack(FUI.colors.border))
    preview.healthText:SetShown((db.healthTextMode or "Percent") ~= "None")
    preview.level:SetShown(db.levelText)
    preview.leftArrow:SetShown(db.targetArrows)
    preview.rightArrow:SetShown(db.targetArrows)
    preview.glow:SetShown(db.targetGlow)
    preview.glow:SetSize(db.width + 22, db.height + 22)
    if preview.glow.layers then
        for index, glow in ipairs(preview.glow.layers) do glow:SetSize(db.width + 15 + index * 7, db.height + 15 + index * 7) end
    end
    if preview.glow.anim then
        if db.targetGlow and not preview.glow.anim:IsPlaying() then preview.glow.anim:Play()
        elseif not db.targetGlow then preview.glow.anim:Stop() end
    end
    preview.cast:SetSize(db.width, db.castHeight)
    preview.cast:ClearAllPoints()
    preview.cast:SetPoint("TOP", preview.health, "BOTTOM", 0, db.castOffsetY or -3)
    preview.cast:SetStatusBarTexture(BarTexture(db.castTexture, true))
    preview.cast:SetStatusBarColor(Color(db.castColor, { .22, .62, 1, 1 }))
    preview.cast.border:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = db.borderSize or 1 })
    preview.cast.border:SetBackdropColor(.008, .016, .035, db.backgroundAlpha or .82)
    preview.cast.border:SetBackdropBorderColor(unpack(FUI.colors.border))
    preview.castTimer:SetShown(db.castTimer)
    preview.castName:SetShown(db.castText ~= false)
    preview.castIcon:SetShown(db.castIcon)
    preview.castIcon:SetSize(math.max(14, db.castHeight + 2), math.max(14, db.castHeight + 2))
    preview.name:SetFont(FUI:GetModuleFontPath("nameplates"), db.fontSize, FUI.db.global.fontOutline)
    preview.name:SetShown(db.namePosition ~= "Hidden")
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
    pcall(SetCVar, "nameplateMotion", db.stacking and "1" or "0")
    pcall(SetCVar, "nameplateOverlapV", tostring(db.verticalSpacing or 1))
    pcall(SetCVar, "nameplateOverlapH", tostring(db.horizontalSpacing or .8))
    pcall(SetCVar, "nameplateMaxDistance", tostring(db.maxDistance or 41))
end

function module:Apply()
    self:ApplyCVars()
    if FUI.db.modules.nameplates then self:StyleVisiblePlates()
    else for unit in pairs(self.units) do self:ReleasePlate(unit) end end
    self:UpdatePreviews()
end

function module:Initialize()
    local events = CreateFrame("Frame")
    for _, event in ipairs({
        "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED",
        "RAID_TARGET_UPDATE", "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_NAME_UPDATE", "UNIT_FACTION", "UNIT_AURA",
        "UNIT_THREAT_LIST_UPDATE", "UNIT_THREAT_SITUATION_UPDATE", "UNIT_SPELLCAST_START",
        "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
    }) do pcall(events.RegisterEvent, events, event) end
    events:SetScript("OnEvent", function(_, event, unit)
        if event == "NAME_PLATE_UNIT_ADDED" then module:StylePlate(unit)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then module:ReleasePlate(unit)
        elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_ENTERING_WORLD" or event == "RAID_TARGET_UPDATE" then module:Apply()
        elseif unit and unit:match("^nameplate") then module:UpdatePlate(unit) end
    end)
    events:SetScript("OnUpdate", function(_, elapsed)
        module.elapsed = (module.elapsed or 0) + elapsed
        if module.elapsed < .05 then return end
        module.elapsed = 0
        for unit, record in pairs(module.units) do
            if UnitExists(unit) then
                module:SuppressNative(record.plate, true)
                -- Forever refreshes and recycles nameplates aggressively.
                -- Reapply live settings and target state on the same cadence
                -- instead of relying only on events that are not always sent.
                module:UpdatePlate(unit)
                local cast = record.custom.cast
                if cast:IsShown() and cast.endTime and cast.startTime then
                    local now, duration = GetTime(), math.max(.001, cast.endTime - cast.startTime)
                    local progress = math.max(0, math.min(duration, now - cast.startTime))
                    cast:SetMinMaxValues(0, duration)
                    cast:SetValue(cast.channel and (duration - progress) or progress)
                    cast.timer:SetText(FUI.db.nameplates.castTimer and string.format("%.1f", math.max(0, cast.endTime - now)) or "")
                end
            end
        end
    end)
    self.events = events
    self:Apply()
end

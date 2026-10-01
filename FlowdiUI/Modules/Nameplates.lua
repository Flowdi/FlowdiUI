local _, ns = ...
local FUI = ns.FUI

local module = { units = {} }
FUI:RegisterModule("nameplates", module)

local function AddPlateBorder(bar)
    if bar.FlowdiBorder then return bar.FlowdiBorder end
    local border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetFrameLevel(math.max(0, bar:GetFrameLevel() - 1))
    border:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    border:SetBackdropColor(0.008, 0.016, 0.035, 0.94)
    border:SetBackdropBorderColor(0.08, 0.32, 0.75, 0.95)
    bar.FlowdiBorder = border
    return border
end

local function HealthColor(unit)
    local db = FUI.db.nameplates
    if db.threatColor and UnitCanAttack("player", unit) then
        local status = UnitThreatSituation and UnitThreatSituation("player", unit)
        if status == 3 then return 0.92, 0.16, 0.12 end
        if status == 2 then return 1.00, 0.48, 0.08 end
        if status == 1 then return 0.96, 0.78, 0.10 end
    end
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
        if color then return color.r, color.g, color.b end
    end
    if UnitIsFriend("player", unit) then return 0.16, 0.68, 0.38 end
    if UnitCanAttack("player", unit) then return 0.78, 0.16, 0.18 end
    return 0.72, 0.66, 0.18
end

local function FindHealth(frame)
    return frame and (frame.healthBar or frame.HealthBar or
        frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar)
end

local function FindCast(frame)
    return frame and (frame.castBar or frame.CastBar or frame.castbar)
end

function module:CreateElements(frame, health)
    if frame.FlowdiElements then return frame.FlowdiElements end
    local elements = {}
    local percent = FUI:CreateFont(health, 9)
    percent:SetPoint("RIGHT", health, "RIGHT", -3, 0)
    percent:SetJustifyH("RIGHT")
    elements.percent = percent

    local level = FUI:CreateFont(health, 9)
    level:SetPoint("LEFT", health, "LEFT", 3, 0)
    level:SetJustifyH("LEFT")
    elements.level = level

    local target = CreateFrame("Frame", nil, health, "BackdropTemplate")
    target:SetPoint("TOPLEFT", -3, 3)
    target:SetPoint("BOTTOMRIGHT", 3, -3)
    target:SetFrameLevel(health:GetFrameLevel() + 4)
    target:SetBackdrop({ edgeFile = FUI.textures.Flat, edgeSize = 2 })
    target:SetBackdropBorderColor(0.22, 0.68, 1, 0.95)
    target:Hide()
    elements.target = target

    frame.FlowdiElements = elements
    return elements
end

function module:UpdatePlate(unit)
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
    local frame = plate and plate.UnitFrame
    if not frame then return end
    local health = FindHealth(frame)
    if not health then return end
    local elements = self:CreateElements(frame, health)
    local r, g, b = HealthColor(unit)
    health:SetStatusBarColor(r, g, b)
    local current = UnitHealth(unit) or 0
    local maximum = UnitHealthMax(unit) or 0
    elements.percent:SetText(FUI.db.nameplates.healthText and maximum > 0 and string.format("%d%%", math.floor(current / maximum * 100 + 0.5)) or "")
    local level = UnitLevel(unit)
    elements.level:SetText(FUI.db.nameplates.levelText and level and level > 0 and level or (FUI.db.nameplates.levelText and level == -1 and "??" or ""))
    elements.target:SetShown(FUI.db.nameplates.targetGlow and UnitIsUnit(unit, "target"))
end

function module:StylePlate(unit)
    if not FUI.db.modules.nameplates then return end
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
    local frame = plate and plate.UnitFrame
    if not frame then return end
    self.units[unit] = frame

    local health = FindHealth(frame)
    if health then
        health:SetStatusBarTexture(FUI:GetStatusBarTexture(false))
        health:SetSize(FUI.db.nameplates.width, FUI.db.nameplates.height)
        AddPlateBorder(health)
        self:CreateElements(frame, health)
    end

    local cast = FindCast(frame)
    if cast then
        cast:SetStatusBarTexture(FUI:GetStatusBarTexture(true))
        cast:SetSize(FUI.db.nameplates.width, FUI.db.nameplates.castHeight)
        AddPlateBorder(cast)
        local castText = cast.Text or cast.text or cast.CastName or cast.castName
        if castText and castText.SetFont then
            castText:SetFont(FUI:GetModuleFontPath("nameplates"), math.max(8, FUI.db.nameplates.fontSize - 2), FUI.db.global.fontOutline)
        end
    end

    local name = frame.name or frame.Name
    if name and name.SetFont then
        name:SetFont(FUI:GetModuleFontPath("nameplates"), FUI.db.nameplates.fontSize, FUI.db.global.fontOutline)
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

function module:Apply()
    if SetCVar then pcall(SetCVar, "nameplateShowFriends", FUI.db.nameplates.showFriendly and "1" or "0") end
    self:StyleVisiblePlates()
end

function module:Initialize()
    local events = CreateFrame("Frame")
    events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("PLAYER_TARGET_CHANGED")
    events:RegisterEvent("UNIT_HEALTH")
    pcall(events.RegisterEvent, events, "UNIT_THREAT_LIST_UPDATE")
    pcall(events.RegisterEvent, events, "UNIT_THREAT_SITUATION_UPDATE")
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
    self.events = events
    self:Apply()
end

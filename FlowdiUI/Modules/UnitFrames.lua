local _, ns = ...
local FUI = ns.FUI

local module = { frames = {} }
FUI:RegisterModule("unitFrames", module)

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function SafeUnitFlag(callback, unit)
    local ok, value = pcall(callback, unit)
    if not ok or IsSecret(value) then return nil end
    return value and true or false
end

local function SetSafeText(font, value)
    if not font then return end
    pcall(font.SetText, font, value)
end

local function SetUnitColor(frame)
    local color = FUI.colors.health
    local ok, _, class = pcall(UnitClass, frame.unit)
    if ok and not IsSecret(class) and class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        color = RAID_CLASS_COLORS[class]
    end
    frame.health:SetStatusBarColor(color.r or color[1], color.g or color[2], color.b or color[3], 1)
end

function module:UpdateFrame(frame)
    local unit = frame.unit
    if not UnitExists(unit) then return end

    local maxHealth = UnitHealthMax(unit)
    local health = UnitHealth(unit)
    frame.health:SetMinMaxValues(0, maxHealth)
    frame.health:SetValue(health)

    local maxPower = UnitPowerMax(unit)
    local power = UnitPower(unit)
    frame.power:SetMinMaxValues(0, maxPower)
    frame.power:SetValue(power)

    SetSafeText(frame.name, UnitName(unit))
    SetUnitColor(frame)

    local dead = SafeUnitFlag(UnitIsDeadOrGhost, unit)
    local connected = SafeUnitFlag(UnitIsConnected, unit)
    if dead == true then
        frame.state:SetText("TOT")
        frame.state:Show()
    elseif connected == false then
        frame.state:SetText("OFFLINE")
        frame.state:Show()
    else
        frame.state:Hide()
    end
end

function module:CreateUnitFrame(unit, width, height, positionKey)
    local frame = CreateFrame("Button", "FlowdiUI_" .. unit:gsub("^%l", string.upper), UIParent, "SecureUnitButtonTemplate")
    frame:SetSize(width, height)
    frame:SetAttribute("unit", unit)
    frame:SetAttribute("type1", "target")
    frame:SetAttribute("type2", "togglemenu")
    frame:RegisterForClicks("AnyUp")
    frame.unit = unit
    frame.positionKey = positionKey
    RegisterUnitWatch(frame)

    FUI:RestorePosition(frame, positionKey)
    FUI:CreateBackdrop(frame, 2)
    FUI:MakeMovable(frame, positionKey)

    local health = CreateFrame("StatusBar", nil, frame)
    health:SetPoint("TOPLEFT", 1, -1)
    health:SetPoint("TOPRIGHT", -1, -1)
    health:SetHeight(height - 12)
    health:SetStatusBarTexture(FUI:GetStatusBarTexture(false))
    health:SetStatusBarColor(unpack(FUI.colors.health))
    frame.health = health

    local healthBG = health:CreateTexture(nil, "BACKGROUND")
    healthBG:SetAllPoints()
    healthBG:SetColorTexture(0.025, 0.04, 0.055, 0.95)

    local power = CreateFrame("StatusBar", nil, frame)
    power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -2)
    power:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    power:SetStatusBarTexture(FUI:GetStatusBarTexture(true))
    power:SetStatusBarColor(unpack(FUI.colors.power))
    frame.power = power

    local powerBG = power:CreateTexture(nil, "BACKGROUND")
    powerBG:SetAllPoints()
    powerBG:SetColorTexture(0.02, 0.03, 0.06, 0.95)

    local name = FUI:CreateFont(frame, 12)
    name:SetPoint("LEFT", health, "LEFT", 8, 0)
    name:SetPoint("RIGHT", health, "RIGHT", -8, 0)
    name:SetJustifyH("LEFT")
    frame.name = name

    local state = FUI:CreateFont(frame, 10)
    state:SetPoint("RIGHT", health, "RIGHT", -6, 0)
    state:SetTextColor(1, 0.35, 0.35)
    frame.state = state

    local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(0.15, 0.5, 1, 0.11)

    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_MAXHEALTH")
    frame:RegisterEvent("UNIT_POWER_UPDATE")
    frame:RegisterEvent("UNIT_MAXPOWER")
    frame:RegisterEvent("UNIT_DISPLAYPOWER")
    frame:RegisterEvent("UNIT_NAME_UPDATE")
    frame:RegisterEvent("UNIT_CONNECTION")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(self, event, eventUnit)
        if not eventUnit or eventUnit == self.unit or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" then
            module:UpdateFrame(self)
        end
    end)

    self.frames[unit] = frame
    self:UpdateFrame(frame)
    return frame
end

local function HideBlizzardFrame(frame)
    if not frame then return end
    frame:SetAlpha(0)
    if frame.EnableMouse then frame:EnableMouse(false) end
    if frame.HookScript and not frame.FlowdiHiddenHook then
        frame.FlowdiHiddenHook = true
        frame:HookScript("OnShow", function(self)
            self:SetAlpha(0)
        end)
    end
end

function module:HideDefaults()
    HideBlizzardFrame(PlayerFrame)
    HideBlizzardFrame(TargetFrame)
    HideBlizzardFrame(FocusFrame)
end

function module:SetLocked(locked)
    for _, frame in pairs(self.frames) do
        if locked then
            frame.FlowdiBackdrop:SetBackdropBorderColor(unpack(FUI.colors.border))
        else
            frame.FlowdiBackdrop:SetBackdropBorderColor(1, 0.72, 0.12, 1)
        end
    end
end

function module:Apply()
    local scale = (FUI.db.scale or 1) * FUI.db.unitFrames.scale
    local db = FUI.db.unitFrames
    for unit, frame in pairs(self.frames) do
        local width = unit == "player" and db.playerWidth or unit == "target" and db.targetWidth or db.focusWidth
        local height = unit == "focus" and db.focusHeight or db.height
        frame:SetSize(width, height)
        frame:SetScale(scale)
        frame.health:ClearAllPoints()
        frame.health:SetPoint("TOPLEFT", 1, -1)
        frame.health:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, db.powerHeight + 2)
        frame.power:ClearAllPoints()
        frame.power:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
        frame.power:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        frame.power:SetHeight(db.powerHeight)
        frame.health:SetStatusBarTexture(FUI:GetStatusBarTexture(false))
        frame.power:SetStatusBarTexture(FUI:GetStatusBarTexture(true))
        frame.name:SetFont(FUI:GetModuleFontPath("unitFrames"), db.fontSize, FUI.db.global.fontOutline)
    end
end

function module:Initialize()
    self:CreateUnitFrame("player", 230, 46, "player")
    self:CreateUnitFrame("target", 230, 46, "target")
    self:CreateUnitFrame("focus", 185, 38, "focus")
    self:HideDefaults()
    self:Apply()
end

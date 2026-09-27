local _, ns = ...
local FUI = ns.FUI

local module = { frames = {} }
FUI:RegisterModule("groupFrames", module)

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function SafeUnitFlag(callback, unit)
    local ok, value = pcall(callback, unit)
    if not ok or IsSecret(value) then return nil end
    return value and true or false
end

local function UnitColor(unit)
    local ok, _, class = pcall(UnitClass, unit)
    if ok and not IsSecret(class) and class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
        local color = RAID_CLASS_COLORS[class]
        return color.r, color.g, color.b
    end
    return unpack(FUI.colors.health)
end

function module:UpdateButton(button)
    if not UnitExists(button.unit) then return end
    button.health:SetMinMaxValues(0, UnitHealthMax(button.unit))
    button.health:SetValue(UnitHealth(button.unit))
    button.health:SetStatusBarColor(UnitColor(button.unit))
    pcall(button.name.SetText, button.name, UnitName(button.unit))
    button.power:SetMinMaxValues(0, UnitPowerMax(button.unit))
    button.power:SetValue(UnitPower(button.unit))

    local dead = SafeUnitFlag(UnitIsDeadOrGhost, button.unit)
    local connected = SafeUnitFlag(UnitIsConnected, button.unit)
    if dead == true then
        button.state:SetText("TOT")
        button.state:Show()
    elseif connected == false then
        button.state:SetText("OFF")
        button.state:Show()
    else
        button.state:Hide()
    end
end

function module:CreateButton(parent, unit, width, height)
    local button = CreateFrame("Button", nil, parent, "SecureUnitButtonTemplate")
    button:SetSize(width, height)
    button:SetAttribute("unit", unit)
    button:SetAttribute("type1", "target")
    button:SetAttribute("type2", "togglemenu")
    button:RegisterForClicks("AnyUp")
    button.unit = unit
    RegisterUnitWatch(button)
    FUI:CreateBackdrop(button, 1)

    local health = CreateFrame("StatusBar", nil, button)
    health:SetPoint("TOPLEFT", 1, -1)
    health:SetPoint("BOTTOMRIGHT", -1, 5)
    health:SetStatusBarTexture(FUI:GetStatusBarTexture(false))
    button.health = health

    local healthBG = health:CreateTexture(nil, "BACKGROUND")
    healthBG:SetAllPoints()
    healthBG:SetColorTexture(0.025, 0.04, 0.055, 0.96)

    local power = CreateFrame("StatusBar", nil, button)
    power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -1)
    power:SetPoint("BOTTOMRIGHT", -1, 1)
    power:SetStatusBarTexture(FUI:GetStatusBarTexture(true))
    power:SetStatusBarColor(unpack(FUI.colors.power))
    button.power = power

    local name = FUI:CreateFont(button, height > 30 and 11 or 9)
    name:SetPoint("LEFT", health, "LEFT", 5, 0)
    name:SetPoint("RIGHT", health, "RIGHT", -4, 0)
    name:SetJustifyH("LEFT")
    button.name = name

    local state = FUI:CreateFont(button, 9)
    state:SetPoint("RIGHT", health, "RIGHT", -4, 0)
    state:SetTextColor(1, 0.35, 0.35)
    button.state = state

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(0.15, 0.5, 1, 0.12)

    button:RegisterEvent("UNIT_HEALTH")
    button:RegisterEvent("UNIT_MAXHEALTH")
    button:RegisterEvent("UNIT_POWER_UPDATE")
    button:RegisterEvent("UNIT_MAXPOWER")
    button:RegisterEvent("UNIT_NAME_UPDATE")
    button:RegisterEvent("UNIT_CONNECTION")
    button:RegisterEvent("GROUP_ROSTER_UPDATE")
    button:RegisterEvent("PLAYER_ENTERING_WORLD")
    button:SetScript("OnEvent", function(self, event, eventUnit)
        if not eventUnit or eventUnit == self.unit then
            module:UpdateButton(self)
        end
    end)

    self.frames[#self.frames + 1] = button
    return button
end

local function HideBlizzardGroupFrames()
    local frameNames = { "CompactPartyFrame", "CompactRaidFrameManager", "CompactRaidFrameContainer", "PartyFrame" }
    for _, frameName in ipairs(frameNames) do
        local frame = _G[frameName]
        if frame then
            frame:SetAlpha(0)
            if frame.EnableMouse then frame:EnableMouse(false) end
            if frame.HookScript and not frame.FlowdiHiddenHook then
                frame.FlowdiHiddenHook = true
                frame:HookScript("OnShow", function(self)
                    self:SetAlpha(0)
                end)
            end
        end
    end
end

function module:CreatePartyFrames()
    local container = CreateFrame("Frame", "FlowdiUI_Party", UIParent, "SecureHandlerStateTemplate")
    container:SetSize(180, 190)
    FUI:RestorePosition(container, "party")
    FUI:MakeMovable(container, "party")
    self.party = container

    for index = 1, 4 do
        local button = self:CreateButton(container, "party" .. index, 180, 42)
        button:SetPoint("TOPLEFT", 0, -(index - 1) * 47)
    end
    RegisterStateDriver(container, "visibility", "[group:raid] hide; [group:party] show; hide")
end

function module:CreateRaidFrames()
    local container = CreateFrame("Frame", "FlowdiUI_Raid", UIParent, "SecureHandlerStateTemplate")
    container:SetSize(648, 150)
    FUI:RestorePosition(container, "raid")
    FUI:MakeMovable(container, "raid")
    self.raid = container

    for index = 1, 40 do
        local column = math.floor((index - 1) / 5)
        local row = (index - 1) % 5
        local button = self:CreateButton(container, "raid" .. index, 78, 26)
        button:SetPoint("TOPLEFT", column * 81, -row * 29)
    end
    RegisterStateDriver(container, "visibility", "[group:raid] show; hide")
end

function module:SetLocked(locked)
    for _, button in ipairs(self.frames) do
        if locked then
            button.FlowdiBackdrop:SetBackdropBorderColor(0.07, 0.22, 0.42, 0.9)
        else
            button.FlowdiBackdrop:SetBackdropBorderColor(1, 0.72, 0.12, 1)
        end
    end
end

function module:Apply()
    local globalScale = FUI.db.scale or 1
    local db = FUI.db.groupFrames
    if self.party then
        self.party:SetScale(globalScale * db.partyScale)
        self.party:SetSize(db.partyWidth, (db.partyHeight + 5) * 4)
    end
    if self.raid then
        self.raid:SetScale(globalScale * db.raidScale)
        self.raid:SetSize((db.raidWidth + 3) * 8, (db.raidHeight + 3) * 5)
    end
    for _, button in ipairs(self.frames) do
        local partyIndex = tonumber(button.unit:match("^party(%d+)$"))
        local raidIndex = tonumber(button.unit:match("^raid(%d+)$"))
        button:ClearAllPoints()
        if partyIndex then
            button:SetSize(db.partyWidth, db.partyHeight)
            button:SetPoint("TOPLEFT", self.party, "TOPLEFT", 0, -(partyIndex - 1) * (db.partyHeight + 5))
        elseif raidIndex then
            local column = math.floor((raidIndex - 1) / 5)
            local row = (raidIndex - 1) % 5
            button:SetSize(db.raidWidth, db.raidHeight)
            button:SetPoint("TOPLEFT", self.raid, "TOPLEFT", column * (db.raidWidth + 3), -row * (db.raidHeight + 3))
        end
        button.health:SetStatusBarTexture(FUI:GetStatusBarTexture(false))
        button.power:SetStatusBarTexture(FUI:GetStatusBarTexture(true))
        button.name:SetFont(FUI:GetModuleFontPath("groupFrames"), db.fontSize, FUI.db.global.fontOutline)
    end
end

function module:Initialize()
    self:CreatePartyFrames()
    self:CreateRaidFrames()
    HideBlizzardGroupFrames()
    self:Apply()
end

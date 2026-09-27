local _, ns = ...
local FUI = ns.FUI

local module = {}
FUI:RegisterModule("actionBars", module)

local buttonPrefixes = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarRightButton",
    "MultiBarLeftButton",
    "MultiBar5Button",
    "MultiBar6Button",
    "MultiBar7Button",
    "PetActionButton",
    "StanceButton",
}

function module:SkinActionButton(button)
    if not button then return end
    FUI:SkinButton(button)

    local name = button:GetName()
    local hotkey = button.HotKey or (name and _G[name .. "HotKey"])
    local count = button.Count or (name and _G[name .. "Count"])
    local macro = button.Name or (name and _G[name .. "Name"])
    if hotkey then
        hotkey:SetFont(FUI:GetModuleFontPath("actionBars"), 10, FUI.db.global.fontOutline)
        hotkey:SetTextColor(0.72, 0.82, 1)
    end
    if count then count:SetFont(FUI:GetModuleFontPath("actionBars"), 11, FUI.db.global.fontOutline) end
    if macro then macro:SetFont(FUI:GetModuleFontPath("actionBars"), 9, FUI.db.global.fontOutline) end
    if hotkey then hotkey:SetShown(FUI.db.actionBars.showHotkeys) end
    if macro then macro:SetShown(FUI.db.actionBars.showMacroText) end
end

function module:SkinAllButtons()
    for _, prefix in ipairs(buttonPrefixes) do
        for index = 1, 12 do
            self:SkinActionButton(_G[prefix .. index])
        end
    end

    if ExtraActionButton1 then self:SkinActionButton(ExtraActionButton1) end
    if ZoneAbilityFrame and ZoneAbilityFrame.SpellButton then
        self:SkinActionButton(ZoneAbilityFrame.SpellButton)
    end
end

function module:Apply()
    local scale = (FUI.db.scale or 1) * FUI.db.actionBars.scale
    local barNames = {
        "MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight",
        "MultiBarRight", "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7",
        "PetActionBar", "StanceBar",
    }
    for _, name in ipairs(barNames) do
        local bar = _G[name]
        if bar and not InCombatLockdown() then bar:SetScale(scale) end
    end
    self:SkinAllButtons()
end

function module:Initialize()
    self:SkinAllButtons()
    self:Apply()

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    eventFrame:RegisterEvent("UPDATE_BINDINGS")
    eventFrame:SetScript("OnEvent", function()
        module:SkinAllButtons()
    end)

    if ActionButton_Update then
        hooksecurefunc("ActionButton_Update", function(button)
            module:SkinActionButton(button)
        end)
    end
end

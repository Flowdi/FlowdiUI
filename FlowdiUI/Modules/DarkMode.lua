local _, ns = ...
local FUI = ns.FUI

local module = {}
FUI:RegisterModule("darkMode", module)

local fallbackWindows = {
    "SpellBookFrame", "PlayerSpellsFrame", "PVEFrame", "FriendsFrame",
    "CommunitiesFrame", "AuctionHouseFrame", "ProfessionsFrame",
    "EncounterJournal", "CollectionsJournal", "AchievementFrame",
    "DressUpFrame", "TradeFrame", "SettingsPanel", "GameMenuFrame",
}

function module:Scan(refresh)
    if refresh then FUI:RefreshSkins() else FUI:RunAvailableSkins() end
    for _, name in ipairs(fallbackWindows) do
        local frame = _G[name]
        if frame then
            FUI:SkinWindow(frame)
            FUI:SkinCloseButton(frame.CloseButton)
        end
    end
end

function module:Apply()
    self:Scan(true)
end

function module:Initialize()
    self:Scan(false)
    local events = CreateFrame("Frame")
    for _, event in ipairs({
        "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "BANKFRAME_OPENED",
        "MERCHANT_SHOW", "MAIL_SHOW", "GOSSIP_SHOW", "QUEST_DETAIL",
    }) do events:RegisterEvent(event) end
    events:SetScript("OnEvent", function(_, event)
        module:Scan(event ~= "ADDON_LOADED" and event ~= "PLAYER_ENTERING_WORLD")
    end)
end

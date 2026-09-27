local _, ns = ...
local FUI = ns.FUI

local equipmentSlots = {
    "CharacterHeadSlot", "CharacterNeckSlot", "CharacterShoulderSlot", "CharacterBackSlot",
    "CharacterChestSlot", "CharacterShirtSlot", "CharacterTabardSlot", "CharacterWristSlot",
    "CharacterHandsSlot", "CharacterWaistSlot", "CharacterLegsSlot", "CharacterFeetSlot",
    "CharacterFinger0Slot", "CharacterFinger1Slot", "CharacterTrinket0Slot", "CharacterTrinket1Slot",
    "CharacterMainHandSlot", "CharacterSecondaryHandSlot",
}

local function ApplyCharacterSkin()
    local frame = CharacterFrame
    if not frame then return end

    FUI:SkinWindow(frame)
    FUI:SkinCloseButton(frame.CloseButton or CharacterFrameCloseButton)
    FUI:SkinInset(frame.LeftPaneHost)
    FUI:SkinInset(frame.RightPaneHost)

    for _, name in ipairs(equipmentSlots) do
        FUI:SkinItemButton(_G[name])
    end

    if frame.ModeTabs and frame.ModeTabs.Tabs then
        for _, tab in ipairs(frame.ModeTabs.Tabs) do FUI:SkinTab(tab) end
    end
    for index = 1, 4 do FUI:SkinTab(_G["PaperDollSidebarTab" .. index]) end

    local scrollFrames = {
        CharacterStatsPaneScrollBox, CharacterStatsPanePetScrollBox,
        ReputationFrame and ReputationFrame.ScrollBar,
        TokenFrame and TokenFrame.ScrollBar,
        SkillsFrame and SkillsFrame.ScrollBar,
    }
    for _, scroll in pairs(scrollFrames) do
        if scroll then FUI:SkinScrollBar(scroll.ScrollBar or scroll) end
    end
end

FUI:RegisterSkin("Blizzard_UIPanels_Game", "Character", function()
    if not FUI.db.darkMode.skins.character then return end
    ApplyCharacterSkin()
    if CharacterFrame and not CharacterFrame.FlowdiShowHook then
        CharacterFrame.FlowdiShowHook = true
        CharacterFrame:HookScript("OnShow", ApplyCharacterSkin)
    end
end)

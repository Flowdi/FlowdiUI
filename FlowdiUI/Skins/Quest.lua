local _, ns = ...
local FUI = ns.FUI

local function SkinRewardButtons(prefix)
    for index = 1, 12 do
        local button = _G[prefix .. index]
        if button then FUI:SkinItemButton(button) end
    end
end

local function ApplyQuestSkin()
    if QuestFrame then
        FUI:SkinWindow(QuestFrame)
        FUI:SkinCloseButton(QuestFrame.CloseButton or QuestFrameCloseButton)

        local buttons = {
            QuestFrameAcceptButton, QuestFrameCompleteButton, QuestFrameCompleteQuestButton,
            QuestFrameDeclineButton, QuestFrameGoodbyeButton, QuestFrameGreetingGoodbyeButton,
        }
        for _, button in pairs(buttons) do FUI:SkinStandardButton(button) end

        local scrollFrames = {
            QuestDetailScrollFrame, QuestProgressScrollFrame, QuestGreetingScrollFrame,
            QuestRewardScrollFrame, QuestLogPopupDetailFrameScrollFrame,
        }
        for _, scroll in pairs(scrollFrames) do
            if scroll then
                FUI:SkinInset(scroll)
                FUI:SkinScrollBar(scroll.ScrollBar)
            end
        end
        SkinRewardButtons("QuestInfoRewardsFrameQuestInfoItem")
        SkinRewardButtons("QuestInfoItem")
    end

    if GossipFrame then
        FUI:SkinWindow(GossipFrame)
        FUI:SkinCloseButton(GossipFrame.CloseButton)
        if GossipFrame.GreetingPanel then
            FUI:SkinInset(GossipFrame.GreetingPanel)
            FUI:SkinScrollBar(GossipFrame.GreetingPanel.ScrollBar)
            FUI:SkinStandardButton(GossipFrame.GreetingPanel.GoodbyeButton)
        end
    end

    if ItemTextFrame then
        FUI:SkinWindow(ItemTextFrame)
        FUI:SkinCloseButton(ItemTextFrameCloseButton)
        FUI:SkinInset(ItemTextScrollFrame)
        FUI:SkinScrollBar(ItemTextScrollFrame and ItemTextScrollFrame.ScrollBar)
    end
end

FUI:RegisterSkin("Blizzard_UIPanels_Game", "QuestAndGossip", function()
    if not FUI.db.darkMode.skins.quest then return end
    ApplyQuestSkin()
    for _, frame in pairs({ QuestFrame, GossipFrame, ItemTextFrame }) do
        if frame and not frame.FlowdiShowHook then
            frame.FlowdiShowHook = true
            frame:HookScript("OnShow", ApplyQuestSkin)
        end
    end
end)

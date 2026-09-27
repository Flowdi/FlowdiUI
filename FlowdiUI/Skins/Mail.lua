local _, ns = ...
local FUI = ns.FUI

local function ApplyMailSkin()
    if not MailFrame then return end
    FUI:SkinWindow(MailFrame)
    FUI:SkinCloseButton(MailFrame.CloseButton or MailFrameCloseButton)
    FUI:SkinTab(MailFrameTab1)
    FUI:SkinTab(MailFrameTab2)
    FUI:SkinButton(InboxFrame and InboxFrame.PrevPageButton)
    FUI:SkinButton(InboxFrame and InboxFrame.NextPageButton)

    FUI:SkinInset(SendMailScrollFrame)
    FUI:SkinScrollBar(SendMailScrollFrame and SendMailScrollFrame.ScrollBar)
    FUI:SkinEditBox(SendMailNameEditBox)
    FUI:SkinEditBox(SendMailSubjectEditBox)
    FUI:SkinEditBox(SendMailMoneyGold)
    FUI:SkinEditBox(SendMailMoneySilver)
    FUI:SkinEditBox(SendMailMoneyCopper)
    FUI:SkinStandardButton(SendMailMailButton)
    FUI:SkinStandardButton(SendMailCancelButton)

    if OpenMailFrame then
        FUI:SkinInset(OpenMailFrame)
        FUI:SkinCloseButton(OpenMailFrameCloseButton)
        FUI:SkinScrollBar(OpenMailScrollFrame and OpenMailScrollFrame.ScrollBar)
        FUI:SkinStandardButton(OpenMailReportSpamButton)
        FUI:SkinStandardButton(OpenMailReplyButton)
        FUI:SkinStandardButton(OpenMailDeleteButton)
        FUI:SkinStandardButton(OpenMailCancelButton)
        FUI:SkinStandardButton(OpenAllMail)
        FUI:SkinItemButton(OpenMailLetterButton)
        FUI:SkinItemButton(OpenMailMoneyButton)
    end
end

FUI:RegisterSkin("Blizzard_MailFrame", "Mail", function()
    if not FUI.db.darkMode.skins.mail then return end
    ApplyMailSkin()
    if MailFrame and not MailFrame.FlowdiShowHook then
        MailFrame.FlowdiShowHook = true
        MailFrame:HookScript("OnShow", ApplyMailSkin)
    end
end)

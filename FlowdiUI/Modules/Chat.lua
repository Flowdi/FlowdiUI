local _, ns = ...
local FUI = ns.FUI

local module = {}
FUI:RegisterModule("chat", module)

function module:CreateCopyWindow()
    if self.copyWindow then return self.copyWindow end
    local frame = CreateFrame("Frame", "FlowdiUIChatCopy", UIParent, "BackdropTemplate")
    frame:SetSize(620, 420)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    frame:SetBackdropColor(0.008, 0.014, 0.03, 0.985)
    frame:SetBackdropBorderColor(unpack(FUI.colors.border))
    frame:Hide()
    tinsert(UISpecialFrames, frame:GetName())

    local title = FUI:CreateFont(frame, 16)
    title:SetPoint("TOPLEFT", 18, -16)
    title:SetText("Chat kopieren")

    local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    editBox:SetPoint("TOPLEFT", 18, -50)
    editBox:SetPoint("BOTTOMRIGHT", -18, 48)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(0)
    editBox:SetFont(FUI.media.font, 12, "")
    editBox:SetTextInsets(8, 8, 8, 8)
    editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    FUI:SkinEditBox(editBox)
    frame.editBox = editBox

    local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    close:SetSize(90, 25)
    close:SetPoint("BOTTOMRIGHT", -16, 13)
    close:SetText("Close")
    close:SetScript("OnClick", function() frame:Hide() end)
    self.copyWindow = frame
    return frame
end

function module:OpenCopyWindow(chatFrame)
    local frame = self:CreateCopyWindow()
    local messages = {}
    if chatFrame and chatFrame.GetNumMessages and chatFrame.GetMessageInfo then
        for index = 1, chatFrame:GetNumMessages() do
            local message = chatFrame:GetMessageInfo(index)
            if message then messages[#messages + 1] = message end
        end
    end
    frame.editBox:SetText(table.concat(messages, "\n"))
    frame:Show()
    frame.editBox:HighlightText()
    frame.editBox:SetFocus()
end

function module:StyleChatFrame(frame)
    if not frame then return end
    frame:SetFont(FUI:GetModuleFontPath("chat"), FUI.db.chat.fontSize, FUI.db.global.fontOutline)
    frame:SetShadowOffset(0, 0)
    frame:SetFading(FUI.db.chat.fade)
    frame:SetTimeVisible(FUI.db.chat.timeVisible)

    if not frame.FlowdiBackdrop then
        local backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        backdrop:SetPoint("TOPLEFT", -7, 8)
        backdrop:SetPoint("BOTTOMRIGHT", 7, -8)
        backdrop:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
        backdrop:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
        backdrop:SetBackdropBorderColor(0.07, 0.24, 0.55, 0.75)
        frame.FlowdiBackdrop = backdrop
    end
    frame.FlowdiBackdrop:SetBackdropColor(0.015, 0.025, 0.05, FUI.db.chat.backgroundAlpha)

    local name = frame:GetName()
    local editBox = name and _G[name .. "EditBox"]
    if editBox then
        FUI:CreateBackdrop(editBox, 2)
        editBox:SetAltArrowKeyMode(false)
    end


    if not frame.FlowdiCopyButton then
        local copy = CreateFrame("Button", nil, frame, "BackdropTemplate")
        copy:SetSize(20, 20)
        copy:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 4, 5)
        copy:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
        copy:SetBackdropColor(0.02, 0.04, 0.08, 0.9)
        copy:SetBackdropBorderColor(unpack(FUI.colors.border))
        local label = FUI:CreateFont(copy, 10)
        label:SetPoint("CENTER")
        label:SetText("C")
        copy:SetScript("OnClick", function() module:OpenCopyWindow(frame) end)
        copy:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Chat kopieren")
            GameTooltip:Show()
        end)
        copy:SetScript("OnLeave", GameTooltip_Hide)
        frame.FlowdiCopyButton = copy
    end
    frame.FlowdiCopyButton:SetShown(FUI.db.chat.copyButton)
end

function module:Apply()
    CHAT_TIMESTAMP_FORMAT = FUI.db.chat.timestamps and "[%H:%M] " or nil
    self:StyleAll()
end

function module:StyleAll()
    for index = 1, NUM_CHAT_WINDOWS do
        self:StyleChatFrame(_G["ChatFrame" .. index])
    end

    if ChatFrameMenuButton then FUI:SkinButton(ChatFrameMenuButton) end
    if ChatFrameChannelButton then FUI:SkinButton(ChatFrameChannelButton) end
end

function module:Initialize()
    self:Apply()
    if FCF_OpenTemporaryWindow then
        hooksecurefunc("FCF_OpenTemporaryWindow", function()
            module:StyleAll()
        end)
    end
end

local _, ns = ...
local FUI = ns.FUI

local module = {}
FUI:RegisterModule("chat", module)

local function HideChatControl(frame)
    if not frame then return end
    frame:SetAlpha(0)
    if frame.EnableMouse then frame:EnableMouse(false) end
    if frame.HookScript and not frame.FlowdiHiddenHook then
        frame.FlowdiHiddenHook = true
        frame:HookScript("OnShow", function(self)
            self:SetAlpha(0)
            if self.EnableMouse then self:EnableMouse(false) end
        end)
    end
end

local function SuppressEditModeChild(frame)
    if not frame then return end
    frame:SetAlpha(0)
    if frame.SetMouseClickEnabled then
        frame:SetMouseClickEnabled(false)
        frame:SetMouseMotionEnabled(false)
    elseif frame.EnableMouse then
        frame:EnableMouse(false)
    end
end

function module:SuppressNativeEditMode()
    if not ChatFrame1 then return end
    SuppressEditModeChild(ChatFrame1.Selection)
    SuppressEditModeChild(ChatFrame1.EditModeResizeButton)
end

function module:AnchorPrimaryChat()
    local frame = ChatFrame1
    if not frame or self.anchoring then return end
    self.anchoring = true
    FUI:RestorePosition(frame, "chat")
    self.anchoring = false
end

function module:CreateAnchor()
    if self.anchor or not ChatFrame1 then return self.anchor end
    local anchor = ChatFrame1
    self.anchor = ChatFrame1
    self:AnchorPrimaryChat()
    FUI:RegisterMover(anchor, "chat", "Chat")
    if hooksecurefunc and ChatFrame1.ApplySystemAnchor then
        hooksecurefunc(ChatFrame1, "ApplySystemAnchor", function()
            C_Timer.After(0, function()
                if module.anchor and not InCombatLockdown() then module:AnchorPrimaryChat() end
            end)
        end)
    end
    if EditModeManagerFrame and not self.editModeHooked then
        self.editModeHooked = true
        EditModeManagerFrame:HookScript("OnShow", function()
            C_Timer.After(0, function() module:SuppressNativeEditMode() end)
        end)
    end
    self:SuppressNativeEditMode()
    return ChatFrame1
end

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

    local textArea = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    textArea:SetPoint("TOPLEFT", 18, -50)
    textArea:SetPoint("BOTTOMRIGHT", -18, 48)
    textArea:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    textArea:SetBackdropColor(0.005, 0.012, 0.025, 0.98)
    textArea:SetBackdropBorderColor(unpack(FUI.colors.border))

    local scroll = CreateFrame("ScrollFrame", nil, textArea, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    scroll:EnableMouseWheel(true)
    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetPoint("TOPLEFT")
    editBox:SetWidth(548)
    editBox:SetHeight(1)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(0)
    editBox:SetFont(FUI:GetModuleFontPath("chat"), 12, "")
    editBox:SetTextInsets(2, 2, 2, 2)
    editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    editBox:SetScript("OnTextChanged", function(self)
        local textHeight = self.GetTextHeight and self:GetTextHeight() or 1
        self:SetHeight(math.max(scroll:GetHeight(), textHeight + 12))
    end)
    scroll:SetScript("OnSizeChanged", function(self, width)
        editBox:SetWidth(math.max(40, width - 4))
    end)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local maximum = math.max(0, editBox:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(maximum, self:GetVerticalScroll() - delta * 36)))
    end)
    scroll:SetScrollChild(editBox)
    frame.scroll = scroll
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
    frame.scroll:SetVerticalScroll(0)
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
    if frame.FontStringContainer then
        frame.FontStringContainer:ClearAllPoints()
        frame.FontStringContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", -3, 3)
        frame.FontStringContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 3, -3)
    end

    if not frame.FlowdiBackdrop then
        local backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        backdrop:SetAllPoints(frame)
        backdrop:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
        backdrop:EnableMouse(false)
        backdrop:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
        backdrop:SetBackdropBorderColor(0.07, 0.24, 0.55, 0.75)
        frame.FlowdiBackdrop = backdrop
    end
    frame.FlowdiBackdrop:SetBackdropColor(0.015, 0.025, 0.05, FUI.db.chat.backgroundAlpha)
    HideChatControl(frame.buttonFrame)
    if frame.buttonFrame then
        frame.buttonFrame:ClearAllPoints()
        frame.buttonFrame:SetPoint("TOP", frame, "BOTTOM", 0, -90000)
        if frame.buttonFrame.SetClipsChildren then frame.buttonFrame:SetClipsChildren(true) end
    end

    local name = frame:GetName()
    local editBox = name and _G[name .. "EditBox"]
    if editBox then
        FUI:CreateBackdrop(editBox, 2)
        editBox:SetAltArrowKeyMode(false)
        editBox:ClearAllPoints()
        if FUI.db.chat.editBoxPosition == "Above" then
            editBox:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -5, 7)
            editBox:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 5, 7)
        else
            editBox:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -5, -7)
            editBox:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 5, -7)
        end
    end


    if not frame.FlowdiCopyButton then
        local copyParent = frame
        local copy = CreateFrame("Button", nil, copyParent, "BackdropTemplate")
        copy:SetSize(20, 20)
        copy:SetPoint("TOPRIGHT", copyParent, "TOPRIGHT", 4, 5)
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
    self:CreateAnchor()
    self:AnchorPrimaryChat()
    self:StyleAll()
end

function module:StyleAll()
    for index = 1, NUM_CHAT_WINDOWS do
        self:StyleChatFrame(_G["ChatFrame" .. index])
    end

    for _, globalName in ipairs({ "ChatFrameMenuButton", "ChatFrameChannelButton", "ChatFrameToggleVoiceDeafenButton", "ChatFrameToggleVoiceMuteButton", "QuickJoinToastButton" }) do
        HideChatControl(_G[globalName])
    end
    HideChatControl(TextToSpeechButtonFrame)
    HideChatControl(TextToSpeechButton)
    self:SuppressNativeEditMode()
end

function module:Initialize()
    self:Apply()
    if FCF_OpenTemporaryWindow then
        hooksecurefunc("FCF_OpenTemporaryWindow", function()
            module:StyleAll()
        end)
    end
    if FCF_SetButtonSide then
        hooksecurefunc("FCF_SetButtonSide", function(frame)
            if frame and frame.buttonFrame then
                frame.buttonFrame:ClearAllPoints()
                frame.buttonFrame:SetPoint("TOP", frame, "BOTTOM", 0, -90000)
                if frame.buttonFrame.SetClipsChildren then frame.buttonFrame:SetClipsChildren(true) end
            end
        end)
    end
end

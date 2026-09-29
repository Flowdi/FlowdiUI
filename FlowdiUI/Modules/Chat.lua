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

local nativeSuffixes = {
    "ButtonFrame", "ResizeButton", "MinimizeButton", "TabConversationIcon",
}

local tabGhosts = {}

local function SuppressTabRegions(tab)
    if not tab or not tab.GetRegions then return end
    for index = 1, select("#", tab:GetRegions()) do
        local region = select(index, tab:GetRegions())
        if region and region.SetAlpha then region:SetAlpha(0) end
    end
end

local function CreateTabGhost(index)
    local ghost = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    ghost:SetFrameStrata("MEDIUM")
    ghost:SetFrameLevel(150)
    ghost:EnableMouse(false)
    ghost:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    ghost.label = FUI:CreateFont(ghost, 11)
    ghost.label:SetPoint("LEFT", 9, 0)
    ghost.label:SetPoint("RIGHT", -9, 0)
    ghost.label:SetJustifyH("CENTER")
    ghost.label:SetWordWrap(false)
    ghost:Hide()
    tabGhosts[index] = ghost
    return ghost
end

function module:RefreshTabs()
    local dock = GENERAL_CHAT_DOCK
    local frames = dock and dock.DOCKED_CHAT_FRAMES
    local selected = dock and FCFDock_GetSelectedWindow and FCFDock_GetSelectedWindow(dock)
    local count = 0
    if type(frames) == "table" then
        for index = 1, #frames do
            local chatFrame = frames[index]
            local tab = chatFrame and _G[chatFrame:GetName() .. "Tab"]
            if tab then
                count = count + 1
                SuppressTabRegions(tab)
                local ghost = tabGhosts[count] or CreateTabGhost(count)
                ghost:ClearAllPoints()
                ghost:SetPoint("TOPRIGHT", tab, "TOPRIGHT", 0, 0)
                ghost:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
                ghost:SetWidth(math.max(86, tab:GetWidth() or 86))
                if chatFrame.isTemporary then
                    local label = chatFrame.chatTarget
                    if issecretvalue and issecretvalue(label) then
                        ghost.label:SetText(label)
                    elseif label ~= nil then
                        ghost.label:SetText(label)
                    else
                        ghost.label:SetText("...")
                    end
                else
                    local name = GetChatWindowInfo and GetChatWindowInfo(chatFrame:GetID())
                    ghost.label:SetText(name or ("Chat " .. chatFrame:GetID()))
                end
                local active = chatFrame == selected
                ghost:SetBackdropColor(active and 0.035 or 0.012, active and 0.10 or 0.025, active and 0.19 or 0.05, active and 0.98 or 0.90)
                if active then
                    ghost:SetBackdropBorderColor(unpack(FUI.colors.accent))
                    ghost.label:SetTextColor(0.88, 0.96, 1, 1)
                else
                    ghost:SetBackdropBorderColor(0.07, 0.24, 0.55, 0.9)
                    ghost.label:SetTextColor(0.55, 0.68, 0.82, 1)
                end
                ghost:SetShown(tab:IsShown())
            end
        end
    end
    for index = count + 1, #tabGhosts do tabGhosts[index]:Hide() end
end

function module:HideNativeChrome(frame)
    if not frame then return end
    local name = frame:GetName()
    if name then
        for _, suffix in ipairs(nativeSuffixes) do HideChatControl(_G[name .. suffix]) end
    end
    HideChatControl(frame.buttonFrame)
    HideChatControl(frame.ResizeButton)
    HideChatControl(frame.resizeButton)
    HideChatControl(frame.Selection)
    HideChatControl(frame.EditModeResizeButton)
end

function module:LayoutPrimaryChat()
    local frame, host = ChatFrame1, self.anchor
    if not frame or not host or self.anchoring then return end
    self.anchoring = true
    host:SetSize(math.max(260, FUI.db.chat.width or 470), math.max(120, FUI.db.chat.height or 260))
    local frames = GENERAL_CHAT_DOCK and GENERAL_CHAT_DOCK.DOCKED_CHAT_FRAMES
    if type(frames) ~= "table" then frames = { frame } end
    local topInset = FUI.db.chat.editBoxPosition == "Above" and self.editBoxActive and 39 or 7
    for index = 1, #frames do
        local chatFrame = frames[index]
        if chatFrame then
            if chatFrame.SetParent and chatFrame:GetParent() ~= host then pcall(chatFrame.SetParent, chatFrame, host) end
            chatFrame:ClearAllPoints()
            chatFrame:SetPoint("TOPLEFT", host, "TOPLEFT", 7, -topInset)
            chatFrame:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -18, 7)
            chatFrame:SetFrameStrata(host:GetFrameStrata())
            chatFrame:SetFrameLevel(host:GetFrameLevel() + 2)
            if chatFrame.SetClampedToScreen then chatFrame:SetClampedToScreen(false) end
            if chatFrame.SetClampRectInsets then pcall(chatFrame.SetClampRectInsets, chatFrame, 0, 0, 0, 0) end
            if chatFrame.SetMovable then chatFrame:SetMovable(false) end
            if chatFrame.SetResizable then chatFrame:SetResizable(false) end
            self:HideNativeChrome(chatFrame)
        end
    end
    self:RefreshTabs()
    self.anchoring = false
end

function module:CreateAnchor()
    if self.anchor or not ChatFrame1 then return self.anchor end
    local frame = ChatFrame1
    local anchor = CreateFrame("Frame", "FlowdiUIChatFrame", UIParent, "BackdropTemplate")
    anchor:SetSize(FUI.db.chat.width or 470, FUI.db.chat.height or 260)
    anchor:SetClampedToScreen(false)
    anchor:EnableMouse(false)
    anchor:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    anchor:SetBackdropBorderColor(0.07, 0.24, 0.55, 0.9)
    self.anchor = anchor
    FUI:RestorePosition(anchor, "chat")
    if FCF_SetLocked then pcall(FCF_SetLocked, frame, true) end
    self:LayoutPrimaryChat()
    FUI:RegisterMover(anchor, "chat", "Chat", function() module:LayoutPrimaryChat() end)
    if hooksecurefunc and ChatFrame1.ApplySystemAnchor then
        hooksecurefunc(ChatFrame1, "ApplySystemAnchor", function()
            C_Timer.After(0, function()
                if module.anchor and not InCombatLockdown() then module:LayoutPrimaryChat() end
            end)
        end)
    end
    if EditModeManagerFrame and not self.editModeHooked then
        self.editModeHooked = true
        EditModeManagerFrame:HookScript("OnShow", function()
            C_Timer.After(0, function()
                module:SuppressNativeEditMode()
                module:LayoutPrimaryChat()
            end)
        end)
        EditModeManagerFrame:HookScript("OnHide", function()
            C_Timer.After(0, function() module:LayoutPrimaryChat() end)
        end)
    end
    self:SuppressNativeEditMode()
    return anchor
end

function module:CreateCopyButton()
    if self.copyButton or not self.anchor then return self.copyButton end
    local copy = CreateFrame("Button", nil, self.anchor, "BackdropTemplate")
    copy:SetSize(82, 24)
    copy:SetPoint("BOTTOMRIGHT", self.anchor, "TOPRIGHT", 0, 2)
    copy:SetFrameLevel(self.anchor:GetFrameLevel() + 20)
    copy:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    copy:SetBackdropColor(0.02, 0.04, 0.08, 0.95)
    copy:SetBackdropBorderColor(unpack(FUI.colors.border))
    local label = FUI:CreateFont(copy, 10)
    label:SetPoint("CENTER")
    label:SetText("Kopieren")
    copy:SetScript("OnClick", function()
        local selected = GENERAL_CHAT_DOCK and FCFDock_GetSelectedWindow and FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK)
        module:OpenCopyWindow(selected or ChatFrame1)
    end)
    copy:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Chat kopieren")
        GameTooltip:Show()
    end)
    copy:SetScript("OnLeave", GameTooltip_Hide)
    self.copyButton = copy
    return copy
end

function module:StyleChatScrollbar(frame)
    local bar = frame and (frame.ScrollBar or frame.scrollBar)
    if not bar then return end
    FUI:StripTextures(bar)
    if bar.Track then FUI:StripTextures(bar.Track) end
    if bar.Back then FUI:StripTextures(bar.Back) end
    if bar.Forward then FUI:StripTextures(bar.Forward) end
    if bar.ScrollUpButton then FUI:StripTextures(bar.ScrollUpButton) end
    if bar.ScrollDownButton then FUI:StripTextures(bar.ScrollDownButton) end

    if not frame.FlowdiScrollTrack then
        local track = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        track:SetPoint("TOP", bar, "TOP", 0, -1)
        track:SetPoint("BOTTOM", bar, "BOTTOM", 0, 1)
        track:SetWidth(8)
        track:SetFrameLevel(bar:GetFrameLevel() + 4)
        track:EnableMouse(false)
        track:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
        track:SetBackdropColor(0.006, 0.014, 0.03, 0.92)
        track:SetBackdropBorderColor(0.06, 0.20, 0.42, 0.9)
        frame.FlowdiScrollTrack = track

        local thumb = (bar.Track and bar.Track.Thumb) or bar.Thumb
        if thumb then
            local visual = CreateFrame("Frame", nil, frame, "BackdropTemplate")
            visual:SetPoint("TOP", thumb, "TOP", 0, 0)
            visual:SetPoint("BOTTOM", thumb, "BOTTOM", 0, 0)
            visual:SetWidth(6)
            visual:SetFrameLevel(track:GetFrameLevel() + 1)
            visual:EnableMouse(false)
            visual:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
            visual:SetBackdropColor(0.08, 0.38, 0.72, 1)
            visual:SetBackdropBorderColor(unpack(FUI.colors.accent))
            frame.FlowdiScrollThumb = visual
        end
    end

    local bottom = frame.ScrollToBottomButton
    if bottom then
        FUI:StripTextures(bottom)
        local backdrop = FUI:CreateBackdrop(bottom, 0)
        backdrop:SetBackdropColor(0.012, 0.035, 0.07, 0.96)
        backdrop:SetBackdropBorderColor(unpack(FUI.colors.border))
        if not bottom.FlowdiArrow then
            local arrow = FUI:CreateFont(bottom, 10)
            arrow:SetPoint("CENTER", 0, 1)
            arrow:SetText("v")
            arrow:SetTextColor(0.55, 0.82, 1, 1)
            bottom.FlowdiArrow = arrow
        end
    end
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
    local isHosted = self.anchor and frame:GetParent() == self.anchor
    if frame.FontStringContainer then
        frame.FontStringContainer:ClearAllPoints()
        frame.FontStringContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        frame.FontStringContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    end

    if isHosted then
        if frame.FlowdiBackdrop then frame.FlowdiBackdrop:Hide() end
        self.anchor:SetBackdropColor(0.015, 0.025, 0.05, FUI.db.chat.backgroundAlpha)
    else
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
    end
    self:HideNativeChrome(frame)
    self:StyleChatScrollbar(frame)

    local name = frame:GetName()
    local editBox = name and _G[name .. "EditBox"]
    if editBox then
        FUI:SkinEditBox(editBox)
        local editBackdrop = editBox.FlowdiBackdrop
        if editBackdrop then
            editBackdrop:SetBackdropColor(0.008, 0.018, 0.04, 0.98)
            editBackdrop:SetBackdropBorderColor(unpack(FUI.colors.border))
        end
        editBox:SetAltArrowKeyMode(false)
        editBox:SetHeight(28)
        editBox:ClearAllPoints()
        if FUI.db.chat.editBoxPosition == "Above" then
            editBox:SetPoint("TOPLEFT", isHosted and self.anchor or frame, "TOPLEFT", 7, -7)
            editBox:SetPoint("TOPRIGHT", isHosted and self.anchor or frame, "TOPRIGHT", -18, -7)
        else
            editBox:SetPoint("TOPLEFT", isHosted and self.anchor or frame, "BOTTOMLEFT", 0, -5)
            editBox:SetPoint("TOPRIGHT", isHosted and self.anchor or frame, "BOTTOMRIGHT", 0, -5)
        end
        if not editBox.FlowdiVisibilityHook then
            editBox.FlowdiVisibilityHook = true
            editBox:HookScript("OnEditFocusGained", function(self)
                if self.FlowdiBackdrop then self.FlowdiBackdrop:Show() end
                module.editBoxActive = true
                C_Timer.After(0, function() module:LayoutPrimaryChat() end)
            end)
            editBox:HookScript("OnEditFocusLost", function(self)
                if self.FlowdiBackdrop then self.FlowdiBackdrop:Hide() end
                module.editBoxActive = false
                C_Timer.After(0, function() module:LayoutPrimaryChat() end)
            end)
            editBox:HookScript("OnHide", function(self)
                if self.FlowdiBackdrop then self.FlowdiBackdrop:Hide() end
                module.editBoxActive = false
                C_Timer.After(0, function() module:LayoutPrimaryChat() end)
            end)
        end
        if editBackdrop and not (editBox.HasFocus and editBox:HasFocus()) then editBackdrop:Hide() end
    end
end

function module:Apply()
    CHAT_TIMESTAMP_FORMAT = FUI.db.chat.timestamps and "[%H:%M] " or nil
    self:CreateAnchor()
    self:LayoutPrimaryChat()
    self:StyleAll()
    local copy = self:CreateCopyButton()
    if copy then copy:SetShown(FUI.db.chat.copyButton) end
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
    local function RefreshStructure()
        C_Timer.After(0, function()
            module:LayoutPrimaryChat()
            module:StyleAll()
            module:RefreshTabs()
        end)
    end
    local tabUpdater = CreateFrame("Frame")
    local elapsed = 0
    tabUpdater:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed < 0.20 then return end
        elapsed = 0
        module:RefreshTabs()
    end)
    self.tabUpdater = tabUpdater
    if FCF_OpenTemporaryWindow then
        hooksecurefunc("FCF_OpenTemporaryWindow", RefreshStructure)
    end
    if FCF_OpenNewWindow then hooksecurefunc("FCF_OpenNewWindow", RefreshStructure) end
    if FCF_DockFrame then hooksecurefunc("FCF_DockFrame", RefreshStructure) end
    if FCF_SetButtonSide then
        hooksecurefunc("FCF_SetButtonSide", function(frame)
            module:HideNativeChrome(frame)
        end)
    end
    if FCF_SetWindowSize then
        hooksecurefunc("FCF_SetWindowSize", function(frame)
            if frame == ChatFrame1 and module.anchor and not module.anchoring then
                C_Timer.After(0, function() module:LayoutPrimaryChat() end)
            end
        end)
    end
end

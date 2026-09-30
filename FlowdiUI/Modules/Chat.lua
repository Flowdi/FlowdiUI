local _, ns = ...
local FUI = ns.FUI

local module = {}
FUI:RegisterModule("chat", module)

local alphaLocked = setmetatable({}, { __mode = "k" })
local alphaLockActive = setmetatable({}, { __mode = "k" })
local nativeScrollVoid = CreateFrame("Frame")
nativeScrollVoid:Hide()

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

local function LockVisualAlpha(frame)
    if not frame or not frame.SetAlpha then return end
    if not alphaLocked[frame] then
        alphaLocked[frame] = true
        hooksecurefunc(frame, "SetAlpha", function(self, alpha)
            if alpha ~= 0 and not alphaLockActive[self] then
                alphaLockActive[self] = true
                self:SetAlpha(0)
                alphaLockActive[self] = nil
            end
        end)
    end
    frame:SetAlpha(0)
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
local tabSlots = {}
local unreadFrames = setmetatable({}, { __mode = "k" })
local lcaLib
local whisperEvents = {
    CHAT_MSG_WHISPER = true,
    CHAT_MSG_BN_WHISPER = true,
}

-- Blizzard owns the unread state even though FlowdiUI owns the visuals.
-- LibChatAnims (embedded by a few popular addons) stores that state in its
-- own table instead of tab.alerting, so support both sources.
local function TabAlerting(tab)
    if tab.alerting then return true end
    lcaLib = lcaLib or (LibStub and LibStub("LibChatAnims", true))
    return lcaLib and lcaLib.IsAlerting and lcaLib:IsAlerting(tab) and true or false
end

local function IsDockedChatFrame(frame)
    local frames = GENERAL_CHAT_DOCK and GENERAL_CHAT_DOCK.DOCKED_CHAT_FRAMES
    if type(frames) ~= "table" then return frame == ChatFrame1 end
    for index = 1, #frames do
        if frames[index] == frame then return true end
    end
    return false
end

local function SetEditBoxMouse(editBox, enabled)
    if editBox.SetMouseClickEnabled then
        editBox:SetMouseClickEnabled(enabled)
        editBox:SetMouseMotionEnabled(enabled)
    elseif editBox.EnableMouse then
        editBox:EnableMouse(enabled)
    end
end

local function DisableMouseTree(frame)
    if not frame then return end
    if frame.SetMouseClickEnabled then
        frame:SetMouseClickEnabled(false)
        frame:SetMouseMotionEnabled(false)
    elseif frame.EnableMouse then
        frame:EnableMouse(false)
    end
    if frame.GetChildren then
        for index = 1, select("#", frame:GetChildren()) do
            DisableMouseTree(select(index, frame:GetChildren()))
        end
    end
end

function module:SuppressCombatLogChrome()
    for _, name in ipairs({ "CombatLogQuickButtonFrame_Custom", "CombatLogQuickButtonFrame" }) do
        local frame = _G[name]
        if frame then
            frame:SetAlpha(0)
            DisableMouseTree(frame)
            if frame.GetRegions then
                for index = 1, select("#", frame:GetRegions()) do
                    local region = select(index, frame:GetRegions())
                    if region and region.SetAlpha then region:SetAlpha(0) end
                end
            end
        end
    end
end

local function SuppressTabRegions(tab)
    if not tab or not tab.GetRegions then return end
    -- Keep the live Blizzard tab as the click/drag plane, but never let its
    -- fade or new-message animation become visible behind our mirror.
    LockVisualAlpha(tab)
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
    ghost.label:SetPoint("LEFT", 5, 0)
    ghost.label:SetPoint("RIGHT", -5, 0)
    ghost.label:SetJustifyH("CENTER")
    ghost.label:SetWordWrap(false)

    -- Slow FlowdiUI unread pulse: a light-blue inner border instead of
    -- Blizzard's orange tab sheet flashing through from underneath.
    ghost.alertBorder = CreateFrame("Frame", nil, ghost, "BackdropTemplate")
    ghost.alertBorder:SetPoint("TOPLEFT", ghost, "TOPLEFT", 2, -2)
    ghost.alertBorder:SetPoint("BOTTOMRIGHT", ghost, "BOTTOMRIGHT", -2, 2)
    ghost.alertBorder:SetFrameLevel(ghost:GetFrameLevel() + 2)
    ghost.alertBorder:EnableMouse(false)
    ghost.alertBorder:SetBackdrop({ edgeFile = FUI.textures.Flat, edgeSize = 2 })
    ghost.alertBorder:SetBackdropBorderColor(0.25, 0.72, 1, 1)
    ghost.alertBorder:Hide()
    ghost.alertPulse = ghost.alertBorder:CreateAnimationGroup()
    ghost.alertPulse:SetLooping("BOUNCE")
    local pulse = ghost.alertPulse:CreateAnimation("Alpha")
    pulse:SetFromAlpha(0.18)
    pulse:SetToAlpha(0.95)
    pulse:SetDuration(0.9)
    function ghost:StartAlertPulse()
        if not self.alertPulse:IsPlaying() then
            self.alertBorder:SetAlpha(0.18)
            self.alertBorder:Show()
            self.alertPulse:Play()
        end
    end
    function ghost:StopAlertPulse()
        if self.alertPulse:IsPlaying() then self.alertPulse:Stop() end
        self.alertBorder:Hide()
    end
    ghost:Hide()
    tabGhosts[index] = ghost
    return ghost
end

function module:RefreshTabs()
    local dock = GENERAL_CHAT_DOCK
    local frames = dock and dock.DOCKED_CHAT_FRAMES
    local selected = dock and FCFDock_GetSelectedWindow and FCFDock_GetSelectedWindow(dock)
    local count = 0
    local hostLeft = self.anchor and self.anchor:GetLeft()
    if type(frames) == "table" then
        for index = 1, #frames do
            local chatFrame = frames[index]
            local tab = chatFrame and _G[chatFrame:GetName() .. "Tab"]
            if tab then
                count = count + 1
                SuppressTabRegions(tab)
                local ghost = tabGhosts[count] or CreateTabGhost(count)
                local slot = tabSlots[count] or {}
                if not self.editBoxActive and hostLeft then
                    local tabLeft, tabRight = tab:GetLeft(), tab:GetRight()
                    local tabHeight = tab:GetHeight()
                    if tabLeft and tabRight and tabHeight then
                        slot.x = count == 1 and 0 or tabLeft - hostLeft
                        slot.width = tabRight - hostLeft - slot.x + 1
                        slot.height = tabHeight
                        tabSlots[count] = slot
                    end
                end
                ghost:ClearAllPoints()
                if self.anchor and slot.x and slot.width and slot.height then
                    ghost:SetPoint("BOTTOMLEFT", self.anchor, "TOPLEFT", slot.x, 0)
                    ghost:SetSize(slot.width, slot.height)
                else
                    ghost:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, 0)
                    ghost:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 1, 0)
                end
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
                    unreadFrames[chatFrame] = nil
                    ghost:SetBackdropBorderColor(unpack(FUI.colors.accent))
                    ghost.label:SetTextColor(0.88, 0.96, 1, 1)
                    ghost:StopAlertPulse()
                else
                    ghost:SetBackdropBorderColor(0.07, 0.24, 0.55, 0.9)
                    ghost.label:SetTextColor(0.55, 0.68, 0.82, 1)
                    if unreadFrames[chatFrame] or TabAlerting(tab) then
                        ghost:StartAlertPulse()
                    else
                        ghost:StopAlertPulse()
                    end
                end
                -- Blizzard temporarily hides/fades the real tab strip while
                -- its edit box owns focus. The visual mirror must stay up;
                -- the real tabs remain the unchanged click plane underneath.
                ghost:Show()
                self:StyleChatScrollbar(chatFrame)
            end
        end
    end
    for index = count + 1, #tabGhosts do
        tabGhosts[index]:StopAlertPulse()
        tabGhosts[index]:Hide()
    end
    self:SuppressCombatLogChrome()
end

function module:ObserveTabMessage(chatFrame, event)
    if not chatFrame or not event then return end
    if issecretvalue and issecretvalue(event) then return end
    if not whisperEvents[event] then return end
    local selected = GENERAL_CHAT_DOCK and FCFDock_GetSelectedWindow and FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK)
    if chatFrame ~= selected and IsDockedChatFrame(chatFrame) then
        unreadFrames[chatFrame] = true
    end
end

function module:InstallMessageObserver(frame)
    if not frame or frame.FlowdiMessageObserver then return end
    local open
    if frame.isTemporary then
        open = frame.inUse == true
    else
        local id = frame:GetID()
        open = id and id > 0 and FCF_IsChatWindowIndexActive and FCF_IsChatWindowIndexActive(id)
    end
    if not open then return end
    frame.FlowdiMessageObserver = true
    hooksecurefunc(frame, "AddMessage", function(chatFrame, _, _, _, _, _, _, _, event)
        module:ObserveTabMessage(chatFrame, event)
    end)
end

function module:HideNativeChrome(frame)
    if not frame then return end
    local name = frame:GetName()
    if name then
        for _, suffix in ipairs(nativeSuffixes) do HideChatControl(_G[name .. suffix]) end
    end
    local buttonFrame = frame.buttonFrame or (name and _G[name .. "ButtonFrame"])
    HideChatControl(buttonFrame)
    LockVisualAlpha(buttonFrame)
    HideChatControl(frame.ScrollToBottomButton)
    LockVisualAlpha(frame.ScrollToBottomButton)
    HideChatControl(frame.Background)
    HideChatControl(frame.background)
    if name then HideChatControl(_G[name .. "Background"]) end
    if frame.NineSlice then FUI:StripTextures(frame.NineSlice) end
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
    copy:SetSize(18, 18)
    copy:SetPoint("BOTTOMRIGHT", self.anchor, "BOTTOMRIGHT", -1, 1)
    copy:SetFrameLevel(self.anchor:GetFrameLevel() + 20)
    copy:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    copy:SetBackdropColor(0.02, 0.04, 0.08, 0.95)
    copy:SetBackdropBorderColor(unpack(FUI.colors.border))
    local label = FUI:CreateFont(copy, 10)
    label:SetPoint("CENTER")
    label:SetText("C")
    copy:SetScript("OnClick", function()
        local selected = GENERAL_CHAT_DOCK and FCFDock_GetSelectedWindow and FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK)
        module:OpenCopyWindow(selected or ChatFrame1)
    end)
    copy:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Copy Chat")
        GameTooltip:Show()
    end)
    copy:SetScript("OnLeave", GameTooltip_Hide)
    self.copyButton = copy
    return copy
end

function module:CreateScrollBottomButton()
    if self.scrollBottomButton or not self.anchor then return self.scrollBottomButton end
    local button = CreateFrame("Button", nil, self.anchor, "BackdropTemplate")
    button:SetSize(18, 18)
    button:SetPoint("BOTTOMRIGHT", self.anchor, "BOTTOMRIGHT", -1, 22)
    button:SetFrameLevel(self.anchor:GetFrameLevel() + 20)
    button:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    button:SetBackdropColor(0.012, 0.035, 0.07, 0.96)
    button:SetBackdropBorderColor(unpack(FUI.colors.border))
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAtlas("minimal-scrollbar-arrow-returntobottom")
    icon:SetSize(14, 14)
    icon:SetPoint("CENTER")
    icon:SetDesaturated(true)
    icon:SetVertexColor(0.55, 0.82, 1, 1)
    button:SetScript("OnClick", function()
        local selected = GENERAL_CHAT_DOCK and FCFDock_GetSelectedWindow and FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK)
        selected = selected or ChatFrame1
        if selected and selected.ScrollToBottom then selected:ScrollToBottom() end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Scroll to latest message")
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    self.scrollBottomButton = button
    return button
end

function module:StyleChatScrollbar(frame)
    local bar = frame and (frame.ScrollBar or frame.scrollBar)
    if not bar then return end
    FUI:StripTextures(bar)
    -- Blizzard fades the entire bar back in while the player scrolls. Lock
    -- the parent itself at zero; FlowdiUI's track/thumb are sibling frames
    -- on the chat frame and therefore remain visible and fully independent.
    LockVisualAlpha(bar)
    if bar.Track then
        FUI:StripTextures(bar.Track)
        LockVisualAlpha(bar.Track)
    end
    for _, control in ipairs({ bar.Back, bar.Forward, bar.ScrollUpButton, bar.ScrollDownButton }) do
        if control then
            FUI:StripTextures(control)
            HideChatControl(control)
            LockVisualAlpha(control)
            if control.SetParent and control:GetParent() ~= nativeScrollVoid then
                control:SetParent(nativeScrollVoid)
            end
        end
    end

    if not frame.FlowdiScrollTrack then
        local track = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        track:SetWidth(8)
        track:SetFrameLevel(bar:GetFrameLevel() + 4)
        track:EnableMouse(false)
        track:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
        track:SetBackdropColor(0.006, 0.014, 0.03, 0.92)
        track:SetBackdropBorderColor(0.06, 0.20, 0.42, 0.9)
        frame.FlowdiScrollTrack = track

        local thumb = (bar.Track and bar.Track.Thumb) or bar.Thumb
        if thumb then
            LockVisualAlpha(thumb)
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

    local track = frame.FlowdiScrollTrack
    if track then
        track:ClearAllPoints()
        if self.anchor and self.scrollBottomButton and IsDockedChatFrame(frame) then
            -- ChatFrame's right edge is 18px inside the host. +8 puts this
            -- axis at -10: exactly the center of the 18px button at -1.
            track:SetPoint("TOP", frame, "TOPRIGHT", 8, 0)
            track:SetPoint("BOTTOM", self.scrollBottomButton, "TOP", 0, 0)
        else
            track:SetPoint("TOP", bar, "TOP", 0, -1)
            track:SetPoint("BOTTOM", bar, "BOTTOM", 0, 1)
        end

        local thumb = (bar.Track and bar.Track.Thumb) or bar.Thumb
        local visual = frame.FlowdiScrollThumb
        if thumb then LockVisualAlpha(thumb) end
        if thumb and visual then
            local trackX = track:GetCenter()
            local thumbX = thumb:GetCenter()
            local secret = issecretvalue and ((trackX and issecretvalue(trackX)) or (thumbX and issecretvalue(thumbX)))
            if trackX and thumbX and not secret then
                local offsetX = trackX - thumbX
                visual:ClearAllPoints()
                visual:SetPoint("TOP", thumb, "TOP", offsetX, 0)
                visual:SetPoint("BOTTOM", thumb, "BOTTOM", offsetX, 0)
            end
        end
    end

    local bottom = frame.ScrollToBottomButton
    if bottom then
        HideChatControl(bottom)
        LockVisualAlpha(bottom)
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
    title:SetText("Copy Chat")

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
    local scrollBar = scroll.ScrollBar
    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetPoint("TOPLEFT")
    editBox:SetWidth(548)
    editBox:SetHeight(1)
    editBox:SetMultiLine(true)
    editBox:EnableMouse(true)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(0)
    editBox:SetFont(FUI:GetModuleFontPath("chat"), 12, "")
    editBox:SetTextInsets(2, 2, 2, 2)
    editBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    local function RefreshCopyScroll()
        if scroll.UpdateScrollChildRect then scroll:UpdateScrollChildRect() end
        local maximum = scroll.GetVerticalScrollRange and scroll:GetVerticalScrollRange()
            or math.max(0, editBox:GetHeight() - scroll:GetHeight())
        maximum = math.max(0, maximum or 0)
        if scrollBar then
            scrollBar:SetMinMaxValues(0, maximum)
            local value = math.min(scrollBar:GetValue() or 0, maximum)
            scrollBar:SetValue(value)
            scrollBar:SetShown(maximum > 0)
        end
    end
    editBox:SetScript("OnTextChanged", function(self)
        local textHeight = self.GetTextHeight and self:GetTextHeight() or 1
        self:SetHeight(math.max(scroll:GetHeight(), textHeight + 12))
        C_Timer.After(0, RefreshCopyScroll)
    end)
    scroll:SetScript("OnSizeChanged", function(self, width)
        editBox:SetWidth(math.max(40, width - 4))
        C_Timer.After(0, RefreshCopyScroll)
    end)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local maximum = self.GetVerticalScrollRange and self:GetVerticalScrollRange()
            or math.max(0, editBox:GetHeight() - self:GetHeight())
        local value = math.max(0, math.min(maximum, self:GetVerticalScroll() - delta * 36))
        if scrollBar then
            scrollBar:SetValue(value)
        else
            self:SetVerticalScroll(value)
        end
    end)
    scroll:SetScrollChild(editBox)
    frame.scroll = scroll
    frame.scrollBar = scrollBar
    frame.refreshScroll = RefreshCopyScroll
    frame.editBox = editBox
    frame:SetScript("OnHide", function() editBox:ClearFocus() end)

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
    frame:Show()
    frame.editBox:SetText(table.concat(messages, "\n"))
    frame.editBox:SetFocus()
    frame.editBox:SetCursorPosition(0)
    frame.editBox:HighlightText(0, 0)
    frame.scroll:SetVerticalScroll(0)
    if frame.scrollBar then frame.scrollBar:SetValue(0) end
    C_Timer.After(0, frame.refreshScroll)
end

function module:StyleChatFrame(frame)
    if not frame then return end
    frame:SetFont(FUI:GetModuleFontPath("chat"), FUI.db.chat.fontSize, FUI.db.global.fontOutline)
    frame:SetShadowOffset(0, 0)
    frame:SetFading(FUI.db.chat.fade)
    frame:SetTimeVisible(FUI.db.chat.timeVisible)
    local isHosted = self.anchor and IsDockedChatFrame(frame)
    if frame.FontStringContainer then
        frame.FontStringContainer:ClearAllPoints()
        frame.FontStringContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        frame.FontStringContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    end

    if isHosted then
        FUI:StripTextures(frame)
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
    self:InstallMessageObserver(frame)

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
                self:SetAlpha(1)
                SetEditBoxMouse(self, true)
                if self.FlowdiBackdrop then self.FlowdiBackdrop:Show() end
                module.editBoxActive = true
                C_Timer.After(0, function() module:LayoutPrimaryChat() end)
            end)
            editBox:HookScript("OnEditFocusLost", function(self)
                self:SetAlpha(0)
                SetEditBoxMouse(self, false)
                if self.FlowdiBackdrop then self.FlowdiBackdrop:Hide() end
                module.editBoxActive = false
                C_Timer.After(0, function() module:LayoutPrimaryChat() end)
            end)
            editBox:HookScript("OnHide", function(self)
                self:SetAlpha(0)
                SetEditBoxMouse(self, false)
                if self.FlowdiBackdrop then self.FlowdiBackdrop:Hide() end
                module.editBoxActive = false
                C_Timer.After(0, function() module:LayoutPrimaryChat() end)
            end)
        end
        local focused = editBox.HasFocus and editBox:HasFocus()
        editBox:SetAlpha(focused and 1 or 0)
        SetEditBoxMouse(editBox, focused and true or false)
        if editBackdrop and not focused then editBackdrop:Hide() end
    end
end

function module:Apply()
    CHAT_TIMESTAMP_FORMAT = FUI.db.chat.timestamps and "[%H:%M] " or nil
    self:CreateAnchor()
    self:LayoutPrimaryChat()
    self:StyleAll()
    local copy = self:CreateCopyButton()
    if copy then copy:SetShown(FUI.db.chat.copyButton) end
    self:CreateScrollBottomButton()
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

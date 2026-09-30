local _, ns = ...
local FUI = ns.FUI

local module = {
    addonButtons = {},
    addonButtonSet = {},
}
FUI:RegisterModule("minimap", module)

local MASK_SQUARE = 130937
local CONTROL_GAP = 3
local DRAWER_GAP = 5

local decorationNames = {
    "MinimapBackdrop",
    "MinimapBorder",
    "MinimapBorderTop",
    "MinimapCompassTexture",
    "MinimapCompassTextureUnderlay",
    "MiniMapWorldMapButton",
    "MinimapZoneTextButton",
    "MinimapToggleButton",
}

local addonButtonBlacklist = {
    AddonCompartmentFrame = true,
    ExpansionLandingPageMinimapButton = true,
    GameTimeFrame = true,
    MiniMapMailFrame = true,
    MiniMapTracking = true,
    MiniMapTrackingButton = true,
    MinimapBackdrop = true,
    MinimapZoomIn = true,
    MinimapZoomOut = true,
    QueueStatusMinimapButton = true,
}

local pinPatterns = {
    "^GatherMate",
    "^HandyNotes",
    "^HereBeDragons",
    "^Pin",
    "^Questie",
    "^TomTom",
    "^pin",
}

local function IsPinName(name)
    if not name then return false end
    for _, pattern in ipairs(pinPatterns) do
        if name:match(pattern) then return true end
    end
    return false
end

local function HideFrame(frame)
    if not frame then return end
    frame:SetAlpha(0)
    if frame.EnableMouse then frame:EnableMouse(false) end
    frame:Hide()
    if not frame.FlowdiMinimapHideHook then
        frame.FlowdiMinimapHideHook = true
        hooksecurefunc(frame, "Show", function(self)
            if FUI:IsModuleEnabled("minimap") then
                self:SetAlpha(0)
                if self.EnableMouse then self:EnableMouse(false) end
            end
        end)
    end
end

local function ShowTooltip(owner, title, description)
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:AddLine(title, 0.35, 0.68, 1)
    if description then GameTooltip:AddLine(description, 0.72, 0.8, 0.92, true) end
    GameTooltip:Show()
end

function module:CreateControl(parent, text, tooltip, description, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    button:SetBackdropColor(0.012, 0.025, 0.052, 0.94)
    button:SetBackdropBorderColor(unpack(FUI.colors.border))
    button:RegisterForClicks("AnyUp")

    local label = FUI:CreateFont(button, 12)
    label:SetPoint("CENTER", 0, 0)
    label:SetText(text or "")
    button.label = label

    local hover = button:CreateTexture(nil, "HIGHLIGHT")
    hover:SetPoint("TOPLEFT", 1, -1)
    hover:SetPoint("BOTTOMRIGHT", -1, 1)
    hover:SetColorTexture(0.18, 0.55, 1, 0.22)

    button:SetScript("OnEnter", function(self) ShowTooltip(self, tooltip, description) end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnClick", callback)
    return button
end

function module:GetTrackingButton()
    local clusterTracking = MinimapCluster and MinimapCluster.Tracking
    local candidates = {
        _G.MiniMapTrackingButton,
        _G.MiniMapTracking,
        clusterTracking and clusterTracking.Button,
        clusterTracking,
        Minimap and Minimap.Tracking and Minimap.Tracking.Button,
        Minimap and Minimap.Tracking,
    }
    for _, candidate in pairs(candidates) do
        if candidate and candidate.Click then return candidate end
    end
end

function module:OpenTracking()
    local tracking = self:GetTrackingButton()
    if tracking then
        if tracking.OpenMenu then
            if tracking.menu and tracking.menu:IsShown() then
                tracking.menu:Hide()
                return
            end
            tracking:ClearAllPoints()
            tracking:SetPoint("CENTER", self.trackingButton, "CENTER", 0, 0)
            tracking:SetAlpha(0)
            tracking:EnableMouse(false)
            local ok = pcall(tracking.OpenMenu, tracking)
            if ok then
                if tracking.menu then
                    tracking.menu:ClearAllPoints()
                    tracking.menu:SetPoint("TOPRIGHT", self.trackingButton, "TOPLEFT", -4, 0)
                end
                return
            end
        end
        local ok = pcall(tracking.Click, tracking, "LeftButton")
        if ok then return end
    end
    local dropdown = _G.MiniMapTrackingDropDown
    if dropdown and ToggleDropDownMenu then
        ToggleDropDownMenu(1, nil, dropdown, self.trackingButton, 0, 0)
        return
    end
    FUI:Print("The tracking menu is not available yet.")
end

function module:OpenCalendar()
    if C_AddOns and C_AddOns.LoadAddOn and not _G.CalendarFrame then
        pcall(C_AddOns.LoadAddOn, "Blizzard_Calendar")
    end
    if ToggleCalendar then
        ToggleCalendar()
    elseif _G.GameTimeFrame and _G.GameTimeFrame.Click then
        pcall(_G.GameTimeFrame.Click, _G.GameTimeFrame, "LeftButton")
    end
end

function module:CreateGridIcon(button)
    button.label:SetText("")
    button.grid = {}
    for index = 1, 4 do
        local square = button:CreateTexture(nil, "ARTWORK")
        square:SetSize(5, 5)
        square:SetColorTexture(unpack(FUI.colors.accent))
        local x = (index - 1) % 2
        local y = math.floor((index - 1) / 2)
        square:SetPoint("TOPLEFT", button, "CENTER", -6 + x * 7, 6 - y * 7)
        button.grid[index] = square
    end
end

function module:CreateFrames()
    if self.holder then return end

    local holder = CreateFrame("Frame", "FlowdiUI_MinimapHolder", UIParent, "BackdropTemplate")
    holder:SetFrameStrata("LOW")
    holder:SetFrameLevel(5)
    holder:SetClampedToScreen(true)
    holder:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    holder:SetBackdropColor(0.008, 0.016, 0.035, 0.98)
    holder:SetBackdropBorderColor(unpack(FUI.colors.border))
    self.holder = holder

    local controls = CreateFrame("Frame", "FlowdiUI_MinimapControls", UIParent)
    controls:SetFrameStrata("MEDIUM")
    controls:SetFrameLevel(20)
    self.controls = controls

    self.calendarButton = self:CreateControl(controls, date("%d"), "Calendar", "Open the in-game calendar.", function() module:OpenCalendar() end)
    self.trackingButton = self:CreateControl(controls, "T", "Tracking", "Choose which resources are tracked on the Minimap.", function() module:OpenTracking() end)
    local trackingIcon = self.trackingButton:CreateTexture(nil, "ARTWORK")
    trackingIcon:SetPoint("TOPLEFT", 4, -4)
    trackingIcon:SetPoint("BOTTOMRIGHT", -4, 4)
    local hasTrackingAtlas = pcall(trackingIcon.SetAtlas, trackingIcon, "UI-HUD-Minimap-Tracking-Up")
    if hasTrackingAtlas then
        self.trackingButton.label:SetText("")
    else
        trackingIcon:Hide()
    end
    self.trackingButton.icon = trackingIcon
    self.zoomInButton = self:CreateControl(controls, "+", "Zoom in", "Increase the Minimap zoom level.", function()
        if Minimap then Minimap:SetZoom(math.min(5, (Minimap:GetZoom() or 0) + 1)) end
    end)
    self.zoomOutButton = self:CreateControl(controls, "-", "Zoom out", "Decrease the Minimap zoom level.", function()
        if Minimap then Minimap:SetZoom(math.max(0, (Minimap:GetZoom() or 0) - 1)) end
    end)
    self.drawerButton = self:CreateControl(controls, "", "Addon buttons", "Show or hide collected Minimap buttons from other addons.", function()
        module:ToggleDrawer()
    end)
    self:CreateGridIcon(self.drawerButton)

    local count = FUI:CreateFont(self.drawerButton, 8)
    count:SetPoint("BOTTOMRIGHT", -2, 1)
    count:SetTextColor(0.65, 0.82, 1)
    self.drawerButton.count = count

    local drawer = CreateFrame("Frame", "FlowdiUI_MinimapButtonDrawer", UIParent, "BackdropTemplate")
    drawer:SetFrameStrata("DIALOG")
    drawer:SetFrameLevel(30)
    drawer:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    drawer:SetBackdropColor(0.008, 0.016, 0.035, 0.98)
    drawer:SetBackdropBorderColor(unpack(FUI.colors.border))
    drawer:Hide()
    self.drawer = drawer

    local hidden = CreateFrame("Frame", "FlowdiUI_MinimapHidden", UIParent)
    hidden:Hide()
    self.hidden = hidden

    local events = CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("UI_SCALE_CHANGED")
    events:RegisterEvent("DISPLAY_SIZE_CHANGED")
    events:SetScript("OnEvent", function(_, event)
        if event == "ADDON_LOADED" then
            C_Timer.After(0.1, function() module:RefreshAddonButtons() end)
        else
            C_Timer.After(0, function() module:Apply() end)
            C_Timer.After(0.5, function() module:Apply() module:RefreshAddonButtons() end)
        end
    end)
    local elapsed = 0
    events:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed >= 3 then
            elapsed = 0
            module:RefreshAddonButtons()
            if module.calendarButton then module.calendarButton.label:SetText(date("%d")) end
        end
    end)
    self.events = events
end

function module:IsAddonButton(child)
    if not child or self.addonButtonSet[child] then return false end
    if child == self.drawerButton or child == self.calendarButton or child == self.trackingButton or child == self.zoomInButton or child == self.zoomOutButton then return false end
    local name = child.GetName and child:GetName()
    if not name or addonButtonBlacklist[name] or name:match("^FlowdiUI_") or IsPinName(name) then return false end
    if not child.IsObjectType or (not child:IsObjectType("Button") and not name:match("^LibDBIcon10_")) then return false end
    if not (name:match("[Mm]inimap") or name:match("[Mm]ini[Mm]ap") or name:match("^LibDBIcon10_") or name:match("^Lib_GPI_Minimap_")) then return false end
    local width = child.GetWidth and child:GetWidth() or 0
    local height = child.GetHeight and child:GetHeight() or 0
    return child:IsShown() and width >= 14 and width <= 80 and height >= 14 and height <= 80
end

function module:CaptureAddonButton(button)
    if self.addonButtonSet[button] then return end
    if InCombatLockdown() and button.IsProtected and button:IsProtected() then return end
    self.addonButtonSet[button] = true
    self.addonButtons[#self.addonButtons + 1] = button
    if button.SetFixedFrameStrata then button:SetFixedFrameStrata(false) end
    if button.SetFixedFrameLevel then button:SetFixedFrameLevel(false) end
    button:SetParent(self.drawer)
    button:SetFrameStrata("DIALOG")
    button:SetFrameLevel(self.drawer:GetFrameLevel() + 2)
    local backdrop = FUI:CreateBackdrop(button, 1)
    backdrop:SetBackdropColor(0.008, 0.016, 0.035, 0.98)
    backdrop:SetBackdropBorderColor(unpack(FUI.colors.border))
end

function module:RefreshAddonButtons()
    if not self.drawer or InCombatLockdown() then return end
    local sources = { Minimap, MinimapCluster, self.drawer }
    for _, source in pairs(sources) do
        if source and source.GetChildren then
            for _, child in ipairs({ source:GetChildren() }) do
                if self:IsAddonButton(child) then self:CaptureAddonButton(child) end
            end
        end
    end
    table.sort(self.addonButtons, function(a, b)
        return (a:GetName() or ""):lower() < (b:GetName() or ""):lower()
    end)
    self.drawerButton.count:SetText(#self.addonButtons > 0 and tostring(#self.addonButtons) or "")
    self:LayoutDrawer()
end

function module:LayoutDrawer()
    if not self.drawer then return end
    local db = FUI.db.minimap
    local size = db.addonButtonSize or 28
    local columns = math.max(1, math.min(6, db.addonButtonColumns or 4))
    local count = #self.addonButtons
    local usedColumns = math.max(1, math.min(columns, count))
    local rows = math.max(1, math.ceil(count / columns))
    local padding = 6
    self.drawer:SetSize(padding * 2 + usedColumns * size + math.max(0, usedColumns - 1) * CONTROL_GAP,
        padding * 2 + rows * size + math.max(0, rows - 1) * CONTROL_GAP)
    self.drawer:ClearAllPoints()
    self.drawer:SetPoint("TOPRIGHT", self.controls, "TOPLEFT", -DRAWER_GAP, 0)
    for index, button in ipairs(self.addonButtons) do
        if not (InCombatLockdown() and button.IsProtected and button:IsProtected()) then
            if button:GetParent() ~= self.drawer then button:SetParent(self.drawer) end
            local column = (index - 1) % columns
            local row = math.floor((index - 1) / columns)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", self.drawer, "TOPLEFT", padding + column * (size + CONTROL_GAP), -padding - row * (size + CONTROL_GAP))
            button:SetSize(size, size)
            button:SetAlpha(1)
        end
    end
end

function module:ToggleDrawer()
    self:RefreshAddonButtons()
    self.drawer:SetShown(not self.drawer:IsShown())
    self.drawerButton:SetBackdropBorderColor(unpack(self.drawer:IsShown() and FUI.colors.accent or FUI.colors.border))
end

function module:HideBlizzardElements()
    for _, name in ipairs(decorationNames) do HideFrame(_G[name]) end
    if MinimapCluster then
        MinimapCluster:SetAlpha(0)
        MinimapCluster:EnableMouse(false)
    end
    local zoomIn = Minimap and Minimap.ZoomIn or _G.MinimapZoomIn
    local zoomOut = Minimap and Minimap.ZoomOut or _G.MinimapZoomOut
    if zoomIn then
        zoomIn:SetParent(self.hidden)
        zoomIn:Hide()
    end
    if zoomOut then
        zoomOut:SetParent(self.hidden)
        zoomOut:Hide()
    end
end

function module:Apply()
    if not self.holder or not Minimap then return end
    if InCombatLockdown() then
        FUI.pendingApply = true
        return
    end
    local db = FUI.db.minimap
    local size = db.size or 180
    local buttonSize = db.buttonSize or 24
    local topInset = 12
    local data = FUI.db.dataPanels
    if data and data.minimapEnabled and data.minimapPosition == "TOP" then
        topInset = topInset + (data.minimapHeight or 20) * (data.scale or 1)
    end

    self.holder:SetSize(size, size)
    self.holder:ClearAllPoints()
    self.holder:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -12, -topInset)

    if Minimap:GetParent() ~= self.holder then Minimap:SetParent(self.holder) end
    Minimap:ClearAllPoints()
    Minimap:SetAllPoints(self.holder)
    Minimap:SetSize(size, size)
    Minimap:SetScale(1)
    Minimap:SetFrameStrata("LOW")
    Minimap:SetFrameLevel(self.holder:GetFrameLevel() + 1)
    Minimap:SetMaskTexture(MASK_SQUARE)
    Minimap:SetClampedToScreen(true)
    Minimap:SetHitRectInsets(0, 0, 0, 0)
    if Minimap.SetArchBlobRingScalar then Minimap:SetArchBlobRingScalar(0) end
    if Minimap.SetQuestBlobRingScalar then Minimap:SetQuestBlobRingScalar(0) end
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(_, delta)
        if not FUI.db.minimap.mouseWheelZoom then return end
        Minimap:SetZoom(math.max(0, math.min(5, (Minimap:GetZoom() or 0) + (delta > 0 and 1 or -1))))
    end)

    self.holder:SetBackdropColor(0.008, 0.016, 0.035, 0.98)
    self.holder:SetBackdropBorderColor(unpack(FUI.colors.border))
    self.controls:SetSize(buttonSize, buttonSize * 5 + CONTROL_GAP * 4)
    self.controls:ClearAllPoints()
    self.controls:SetPoint("TOPRIGHT", self.holder, "TOPLEFT", -4, 0)
    local buttons = { self.calendarButton, self.trackingButton, self.zoomInButton, self.zoomOutButton, self.drawerButton }
    for index, button in ipairs(buttons) do
        button:SetSize(buttonSize, buttonSize)
        button:ClearAllPoints()
        button:SetPoint("TOP", self.controls, "TOP", 0, -(index - 1) * (buttonSize + CONTROL_GAP))
        button:SetBackdropBorderColor(unpack(FUI.colors.border))
        button.label:SetFont(FUI:GetFontPath(FUI.db.global.font), index <= 2 and 11 or 14, FUI.db.global.fontOutline)
    end
    self.calendarButton.label:SetText(date("%d"))
    self:HideBlizzardElements()
    self:LayoutDrawer()
    self:RefreshAddonButtons()

    local dataPanels = FUI.modules.dataPanels
    if dataPanels and dataPanels.minimap then dataPanels:Apply() end
end

function module:Initialize()
    self:CreateFrames()
    self:Apply()
    C_Timer.After(1, function() module:Apply() module:RefreshAddonButtons() end)
end

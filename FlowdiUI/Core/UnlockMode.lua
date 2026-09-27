local _, ns = ...
local FUI = ns.FUI

local function CreateToolbarButton(parent, label, width, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, 26)
    button:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    button:SetBackdropColor(0.025, 0.045, 0.08, 0.98)
    button:SetBackdropBorderColor(0.12, 0.38, 0.72, 1)
    local text = FUI:CreateFont(button, 11)
    text:SetPoint("CENTER")
    text:SetText(label)
    button.label = text
    button:SetScript("OnEnter", function(self) self:SetBackdropColor(0.08, 0.28, 0.55, 0.98) end)
    button:SetScript("OnLeave", function(self) self:SetBackdropColor(0.025, 0.045, 0.08, 0.98) end)
    button:SetScript("OnClick", callback)
    return button
end

function FUI:RefreshUnlockGrid()
    if not self.unlockMode then return end
    local grid = self.unlockMode.grid
    grid:SetShown(self.db.global.moverGrid)
    if not self.db.global.moverGrid then return end
    local spacing = math.max(16, math.min(128, self.db.global.moverGridSize or 32))
    local width, height = UIParent:GetWidth(), UIParent:GetHeight()
    local needed, index = math.ceil(width / spacing) + math.ceil(height / spacing) + 2, 1
    while #grid.lines < needed do
        local line = grid:CreateTexture(nil, "BACKGROUND")
        line:SetColorTexture(0.18, 0.55, 1, 0.18)
        grid.lines[#grid.lines + 1] = line
    end
    for _, line in ipairs(grid.lines) do line:Hide() end
    for x = spacing, width - 1, spacing do
        local line = grid.lines[index]
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", grid, "TOPLEFT", x, 0)
        line:SetPoint("BOTTOMLEFT", grid, "BOTTOMLEFT", x, 0)
        line:SetWidth(1)
        line:Show()
        index = index + 1
    end
    for y = spacing, height - 1, spacing do
        local line = grid.lines[index]
        line:ClearAllPoints()
        line:SetPoint("BOTTOMLEFT", grid, "BOTTOMLEFT", 0, y)
        line:SetPoint("BOTTOMRIGHT", grid, "BOTTOMRIGHT", 0, y)
        line:SetHeight(1)
        line:Show()
        index = index + 1
    end
end

function FUI:SyncMoverOverlay(mover)
    if not mover or not mover.frame or not mover.overlay then return end
    local target, overlay = mover.frame, mover.overlay
    local centerX, centerY = target:GetCenter()
    if not centerX or not centerY then
        local position = self.db.positions[mover.key]
        if position then
            overlay:ClearAllPoints()
            overlay:SetPoint(position[1], UIParent, position[2], position[3], position[4])
        end
    else
        overlay:ClearAllPoints()
        overlay:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
    end
    local uiScale = UIParent:GetEffectiveScale()
    local ratio = uiScale > 0 and target:GetEffectiveScale() / uiScale or 1
    overlay:SetSize(math.max(48, target:GetWidth() * ratio), math.max(24, target:GetHeight() * ratio))
end

function FUI:CreateMoverOverlay(mover)
    if mover.overlay then return mover.overlay end
    local overlay = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    overlay:SetFrameStrata("DIALOG")
    overlay:SetFrameLevel(120)
    overlay:SetMovable(true)
    overlay:SetClampedToScreen(true)
    overlay:EnableMouse(true)
    overlay:RegisterForDrag("LeftButton")
    overlay:SetBackdrop({ bgFile = self.textures.Flat, edgeFile = self.textures.Flat, edgeSize = 2 })
    overlay:SetBackdropColor(0.02, 0.07, 0.12, 0.78)
    overlay:SetBackdropBorderColor(0.12, 0.62, 1, 1)
    local label = self:CreateFont(overlay, 11)
    label:SetPoint("CENTER")
    label:SetText(mover.label)
    label:SetTextColor(0.82, 0.93, 1)
    overlay:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.04, 0.18, 0.32, 0.88)
        self:SetBackdropBorderColor(0.35, 0.82, 1, 1)
    end)
    overlay:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.02, 0.07, 0.12, 0.78)
        self:SetBackdropBorderColor(0.12, 0.62, 1, 1)
    end)
    overlay:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    overlay:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local target = mover.frame
        local centerX, centerY = self:GetCenter()
        if centerX and centerY then
            target:ClearAllPoints()
            target:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
            FUI:SavePosition(target, mover.key)
            if mover.onMoved then mover.onMoved(mover) end
        end
    end)
    overlay:Hide()
    mover.overlay = overlay
    return overlay
end

function FUI:CreateUnlockMode()
    if self.unlockMode then return self.unlockMode end
    local mode = {}
    local grid = CreateFrame("Frame", nil, UIParent)
    grid:SetAllPoints(UIParent)
    grid:SetFrameStrata("DIALOG")
    grid:SetFrameLevel(1)
    grid:EnableMouse(false)
    grid.lines = {}
    grid:SetScript("OnSizeChanged", function()
        if FUI.unlockMode and FUI.unlockMode.active then FUI:RefreshUnlockGrid() end
    end)
    grid:Hide()
    mode.grid = grid

    local toolbar = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    toolbar:SetSize(720, 46)
    toolbar:SetPoint("TOP", UIParent, "TOP", 0, -12)
    toolbar:SetFrameStrata("TOOLTIP")
    toolbar:SetFrameLevel(250)
    toolbar:SetBackdrop({ bgFile = self.textures.Flat, edgeFile = self.textures.Flat, edgeSize = 1 })
    toolbar:SetBackdropColor(0.008, 0.015, 0.028, 0.98)
    toolbar:SetBackdropBorderColor(0.12, 0.52, 0.95, 1)
    local title = self:CreateFont(toolbar, 13)
    title:SetPoint("LEFT", 14, 0)
    title:SetText("FlowdiUI Unlock Mode")
    title:SetTextColor(0.35, 0.75, 1)

    local gridButton = CreateToolbarButton(toolbar, "", 92, function()
        FUI.db.global.moverGrid = not FUI.db.global.moverGrid
        FUI.unlockMode.gridButton.label:SetText(FUI.db.global.moverGrid and "Grid: On" or "Grid: Off")
        FUI:RefreshUnlockGrid()
    end)
    gridButton:SetPoint("LEFT", 188, 0)
    mode.gridButton = gridButton
    local minus = CreateToolbarButton(toolbar, "−", 32, function()
        FUI.db.global.moverGridSize = math.max(16, (FUI.db.global.moverGridSize or 32) - 8)
        FUI.unlockMode.sizeLabel:SetText(FUI.db.global.moverGridSize .. " px")
        FUI:RefreshUnlockGrid()
    end)
    minus:SetPoint("LEFT", gridButton, "RIGHT", 8, 0)
    local sizeLabel = self:CreateFont(toolbar, 11)
    sizeLabel:SetSize(54, 24)
    sizeLabel:SetPoint("LEFT", minus, "RIGHT", 4, 0)
    sizeLabel:SetJustifyH("CENTER")
    mode.sizeLabel = sizeLabel
    local plus = CreateToolbarButton(toolbar, "+", 32, function()
        FUI.db.global.moverGridSize = math.min(128, (FUI.db.global.moverGridSize or 32) + 8)
        FUI.unlockMode.sizeLabel:SetText(FUI.db.global.moverGridSize .. " px")
        FUI:RefreshUnlockGrid()
    end)
    plus:SetPoint("LEFT", sizeLabel, "RIGHT", 4, 0)
    local save = CreateToolbarButton(toolbar, "Save & Exit", 130, function() FUI:ExitUnlockMode(true) end)
    save:SetPoint("RIGHT", -12, 0)
    toolbar:Hide()
    mode.toolbar = toolbar
    self.unlockMode = mode
    return mode
end

function FUI:EnterUnlockMode()
    if InCombatLockdown() then self:Print("Unlock Mode is unavailable during combat.") return end
    local mode = self:CreateUnlockMode()
    if self.settings then self.settings:Hide() end
    self:SetLocked(false)
    mode.active = true
    mode.gridButton.label:SetText(self.db.global.moverGrid and "Grid: On" or "Grid: Off")
    mode.sizeLabel:SetText((self.db.global.moverGridSize or 32) .. " px")
    self:RefreshUnlockGrid()
    for _, mover in pairs(self.movers) do
        local overlay = self:CreateMoverOverlay(mover)
        self:SyncMoverOverlay(mover)
        overlay:Show()
    end
    mode.toolbar:Show()
end

function FUI:ExitUnlockMode(openSettings)
    if self.unlockMode then
        self.unlockMode.active = false
        self.unlockMode.grid:Hide()
        self.unlockMode.toolbar:Hide()
        for _, mover in pairs(self.movers) do
            if mover.overlay then mover.overlay:Hide() end
        end
    end
    self:SetLocked(true)
    self:ApplySettings()
    if openSettings then self:OpenSettings() end
end

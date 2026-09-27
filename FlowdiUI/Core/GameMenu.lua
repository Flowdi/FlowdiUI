local _, ns = ...
local FUI = ns.FUI

function FlowdiUI_AddonCompartmentFunc()
    FUI:OpenSettings()
end

local function OpenFlowdiUI()
    if not InCombatLockdown() then HideUIPanel(GameMenuFrame) end
    FUI:OpenSettings()
end

local function GetButtonLabel(button, branded)
    if branded then return "FlowdiUI" end
    local label = button.GetText and button:GetText()
    local nativeText = button.GetFontString and button:GetFontString()
    if (not label or label == "") and nativeText and nativeText.GetText then label = nativeText:GetText() end
    return label or RETURN_TO_GAME or "Return to Game"
end

local function EnsureButtonCover(button)
    if button.FlowdiDarkCover then return button.FlowdiDarkCover end
    local cover = CreateFrame("Frame", nil, button, "BackdropTemplate")
    cover:SetAllPoints(button)
    cover:EnableMouse(false)
    local label = cover:CreateFontString(nil, "OVERLAY")
    label:SetPoint("CENTER")
    cover.label = label
    button.FlowdiDarkCover = cover
    button:HookScript("OnEnter", function(self)
        self.FlowdiHovered = true
        if self.FlowdiRefreshStyle then self:FlowdiRefreshStyle() end
    end)
    button:HookScript("OnLeave", function(self)
        self.FlowdiHovered = false
        if self.FlowdiRefreshStyle then self:FlowdiRefreshStyle() end
    end)
    return cover
end

local function ApplyButtonStyle(button, branded, darkEnabled)
    local enabled = branded or darkEnabled
    local cover = EnsureButtonCover(button)
    cover:SetFrameStrata(button:GetFrameStrata())
    cover:SetFrameLevel(button:GetFrameLevel() + 100)
    cover:SetShown(enabled)

    local nativeText = button.GetFontString and button:GetFontString()
    if nativeText then nativeText:SetAlpha(enabled and 0 or 1) end
    if not enabled then return end

    local hovered = button.FlowdiHovered
    local accent = FUI.colors.accent or { 0.18, 0.55, 1, 1 }
    cover:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = branded and 2 or 1 })
    if branded then
        cover:SetBackdropColor(hovered and 0.045 or 0.025, hovered and 0.15 or 0.075, hovered and 0.30 or 0.15, 1)
        cover:SetBackdropBorderColor(accent[1], accent[2], accent[3], 1)
    else
        cover:SetBackdropColor(hovered and 0.13 or 0.065, hovered and 0.15 or 0.070, hovered and 0.19 or 0.080, 1)
        cover:SetBackdropBorderColor(hovered and 0.30 or 0.24, hovered and 0.48 or 0.26, hovered and 0.72 or 0.30, 1)
    end
    cover.label:SetText(GetButtonLabel(button, branded))
    cover.label:SetTextColor(1, 1, 1, 1)
    cover.label:SetFont(FUI:GetFontPath(FUI.db and FUI.db.global.font), branded and 13 or 12, "OUTLINE")
    button.FlowdiRefreshStyle = function(self)
        ApplyButtonStyle(self, branded, FUI.db and FUI.db.global.darkGameMenu)
    end
end

local function SetRegionAlpha(frame, alpha, storage)
    if not frame or not frame.GetRegions then return end
    for index = 1, select("#", frame:GetRegions()) do
        local region = select(index, frame:GetRegions())
        if region and region ~= frame.FlowdiDarkBackground and region.GetObjectType and region:GetObjectType() == "Texture" then
            if storage[region] == nil then storage[region] = region:GetAlpha() end
            region:SetAlpha(alpha)
        end
    end
end

local function StyleMenuFrame(menu, enabled)
    if not menu.FlowdiOriginalRegions then menu.FlowdiOriginalRegions = {} end
    if not menu.FlowdiDarkBackground then
        local background = menu:CreateTexture(nil, "BACKGROUND", nil, -8)
        background:SetPoint("TOPLEFT", 3, -3)
        background:SetPoint("BOTTOMRIGHT", -3, 3)
        background:SetColorTexture(0.006, 0.010, 0.018, 0.985)
        menu.FlowdiDarkBackground = background

        local border = CreateFrame("Frame", nil, menu, "BackdropTemplate")
        border:SetAllPoints()
        border:SetFrameLevel(menu:GetFrameLevel() + 20)
        border:EnableMouse(false)
        border:SetBackdrop({ edgeFile = FUI.textures.Flat, edgeSize = 2 })
        menu.FlowdiDarkBorder = border
    end

    menu.FlowdiDarkBackground:SetShown(enabled)
    menu.FlowdiDarkBorder:SetShown(enabled)
    menu.FlowdiDarkBorder:SetBackdropBorderColor(0.08, 0.32, 0.62, 0.95)
    if enabled then
        SetRegionAlpha(menu, 0, menu.FlowdiOriginalRegions)
        if menu.NineSlice then menu.NineSlice:SetAlpha(0) end
        if menu.Border then menu.Border:SetAlpha(0) end
    else
        for region, alpha in pairs(menu.FlowdiOriginalRegions) do region:SetAlpha(alpha) end
        if menu.NineSlice then menu.NineSlice:SetAlpha(1) end
        if menu.Border then menu.Border:SetAlpha(1) end
    end

    local header = menu.Header
    if header then
        if not header.FlowdiOriginalRegions then header.FlowdiOriginalRegions = {} end
        if enabled then SetRegionAlpha(header, 0, header.FlowdiOriginalRegions) else
            for region, alpha in pairs(header.FlowdiOriginalRegions) do region:SetAlpha(alpha) end
        end
        local text = header.Text or header.text
        if text then
            text:SetAlpha(1)
            text:SetTextColor(enabled and 0.45 or 1, enabled and 0.75 or 0.82, 1, 1)
        end
    end
end

local function StyleAllButtons(menu)
    local darkEnabled = FUI.db and FUI.db.global.darkGameMenu
    StyleMenuFrame(menu, darkEnabled)
    if menu.buttonPool then
        for button in menu.buttonPool:EnumerateActive() do ApplyButtonStyle(button, false, darkEnabled) end
    end
    if menu.FlowdiUIButton then ApplyButtonStyle(menu.FlowdiUIButton, true, true) end
end

local function PositionButton(menu)
    local custom = menu and menu.FlowdiUIButton
    local pool = menu and menu.buttonPool
    if not custom or not pool then return end

    local anchor
    local lowerButtons = {}
    for button in pool:EnumerateActive() do
        local label = button:GetText()
        if label == OPTIONS then anchor = button end
    end
    if not anchor then
        for button in pool:EnumerateActive() do if button:GetText() == ADDONS then anchor = button end end
    end
    if not anchor then return end

    local anchorTop = anchor:GetTop()
    if anchorTop then
        for button in pool:EnumerateActive() do
            local top = button:GetTop()
            if button ~= anchor and top and top < anchorTop then lowerButtons[#lowerButtons + 1] = button end
        end
    end

    custom:ClearAllPoints()
    custom:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
    custom:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -10)
    custom:SetHeight(anchor:GetHeight())
    custom:Show()

    local shift = custom:GetHeight() + 10
    for _, button in ipairs(lowerButtons) do
        local point, relativeTo, relativePoint, x, y = button:GetPoint(1)
        if point then
            button:ClearAllPoints()
            button:SetPoint(point, relativeTo, relativePoint, x, y - shift)
        end
    end

    local currentHeight = menu:GetHeight()
    if currentHeight ~= menu.FlowdiExtendedHeight then menu.FlowdiExtendedHeight = currentHeight + shift end
    menu:SetHeight(menu.FlowdiExtendedHeight)
    menu:SetScale((FUI.db and FUI.db.global and FUI.db.global.gameMenuScale) or 1)
    StyleAllButtons(menu)
end

local function InstallGameMenuButton()
    if not GameMenuFrame or GameMenuFrame.FlowdiUIButton then return end
    local button = CreateFrame("Button", "FlowdiUI_GameMenuButton", GameMenuFrame, "MainMenuFrameButtonTemplate")
    button:SetText("FlowdiUI")
    button:SetScript("OnClick", OpenFlowdiUI)
    GameMenuFrame.FlowdiUIButton = button
    hooksecurefunc(GameMenuFrame, "Layout", PositionButton)
    hooksecurefunc(GameMenuFrame, "InitButtons", function(menu) StyleAllButtons(menu) end)
    GameMenuFrame:HookScript("OnShow", function(menu) StyleAllButtons(menu) end)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", InstallGameMenuButton)

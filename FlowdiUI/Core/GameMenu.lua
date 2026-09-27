local _, ns = ...
local FUI = ns.FUI

function FlowdiUI_AddonCompartmentFunc()
    FUI:OpenSettings()
end

local function OpenFlowdiUI()
    if not InCombatLockdown() then HideUIPanel(GameMenuFrame) end
    FUI:OpenSettings()
end

local textureMethods = { "GetNormalTexture", "GetPushedTexture", "GetHighlightTexture", "GetDisabledTexture" }

local function SetNativeArtwork(button, visible)
    for _, method in ipairs(textureMethods) do
        local texture = button[method] and button[method](button)
        if texture then
            texture:SetAlpha(visible and 1 or 0)
            if visible and texture.SetDesaturated then
                texture:SetDesaturated(false)
                texture:SetVertexColor(1, 1, 1, 1)
            end
        end
    end
    local text = button:GetFontString()
    if text then text:SetAlpha(visible and 1 or 0) end
end

local function ResolveButtonLabel(button, branded)
    if branded then return "FLOWDIUI" end
    if button.FlowdiOriginalLabel and button.FlowdiOriginalLabel ~= "" then return button.FlowdiOriginalLabel end

    local label = button.GetText and button:GetText()
    local fontString = button.GetFontString and button:GetFontString()
    if (not label or label == "") and fontString and fontString.GetText then label = fontString:GetText() end
    for _, key in ipairs({ "Text", "text", "Label", "label" }) do
        local region = button[key]
        if (not label or label == "") and region and region.GetText then label = region:GetText() end
    end
    local name = button.GetName and button:GetName()
    local namedText = name and _G[name .. "Text"]
    if (not label or label == "") and namedText and namedText.GetText then label = namedText:GetText() end
    if not label or label == "" then label = RETURN_TO_GAME or "Return to Game" end
    button.FlowdiOriginalLabel = label
    return label
end

local function EnsureButtonOverlay(button)
    if button.FlowdiDarkSurface then return end
    local surface = button:CreateTexture(nil, "OVERLAY", nil, 6)
    surface:SetPoint("TOPLEFT", 2, -2)
    surface:SetPoint("BOTTOMRIGHT", -2, 2)
    button.FlowdiDarkSurface = surface

    button.FlowdiDarkEdges = {}
    for index = 1, 4 do
        local edge = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.FlowdiDarkEdges[index] = edge
    end
    local top, bottom, left, right = unpack(button.FlowdiDarkEdges)
    top:SetPoint("TOPLEFT", 1, -1)
    top:SetPoint("TOPRIGHT", -1, -1)
    top:SetHeight(1)
    bottom:SetPoint("BOTTOMLEFT", 1, 1)
    bottom:SetPoint("BOTTOMRIGHT", -1, 1)
    bottom:SetHeight(1)
    left:SetPoint("TOPLEFT", 1, -1)
    left:SetPoint("BOTTOMLEFT", 1, 1)
    left:SetWidth(1)
    right:SetPoint("TOPRIGHT", -1, -1)
    right:SetPoint("BOTTOMRIGHT", -1, 1)
    right:SetWidth(1)

    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER", 0, 0)
    button.FlowdiDarkText = text
    button:HookScript("OnEnter", function(self)
        self.FlowdiHovered = true
        if self.FlowdiRefreshStyle then self:FlowdiRefreshStyle() end
    end)
    button:HookScript("OnLeave", function(self)
        self.FlowdiHovered = false
        if self.FlowdiRefreshStyle then self:FlowdiRefreshStyle() end
    end)
end

local function ApplyButtonStyle(button, branded, darkEnabled)
    local enabled = branded or darkEnabled
    local label = ResolveButtonLabel(button, branded)
    EnsureButtonOverlay(button)
    button.FlowdiDarkSurface:SetShown(enabled)
    button.FlowdiDarkText:SetShown(enabled)
    for _, edge in ipairs(button.FlowdiDarkEdges) do edge:SetShown(enabled) end
    SetNativeArtwork(button, not enabled)
    if not enabled then return end

    local accent = FUI.colors.accent or { 0.18, 0.55, 1, 1 }
    local hovered = button.FlowdiHovered
    local thickness = branded and 2 or 1
    button.FlowdiDarkEdges[1]:SetHeight(thickness)
    button.FlowdiDarkEdges[2]:SetHeight(thickness)
    button.FlowdiDarkEdges[3]:SetWidth(thickness)
    button.FlowdiDarkEdges[4]:SetWidth(thickness)
    if branded then
        button.FlowdiDarkSurface:SetColorTexture(hovered and 0.025 or 0.008, hovered and 0.16 or 0.035, hovered and 0.34 or 0.075, 1)
        for _, edge in ipairs(button.FlowdiDarkEdges) do edge:SetColorTexture(accent[1], accent[2], accent[3], 1) end
        button.FlowdiDarkText:SetTextColor(1, 1, 1, 1)
    else
        button.FlowdiDarkSurface:SetColorTexture(hovered and 0.10 or 0.035, hovered and 0.14 or 0.045, hovered and 0.20 or 0.065, 1)
        for _, edge in ipairs(button.FlowdiDarkEdges) do
            edge:SetColorTexture(hovered and 0.30 or 0.16, hovered and 0.58 or 0.22, hovered and 0.92 or 0.34, 1)
        end
        button.FlowdiDarkText:SetTextColor(hovered and 1 or 0.92, hovered and 1 or 0.95, 1, 1)
    end
    button.FlowdiDarkText:SetText(label)
    button.FlowdiDarkText:SetFont(FUI:GetFontPath(FUI.db and FUI.db.global.font), branded and 13 or 12, "OUTLINE")
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
        if label == MACROS then anchor = button end
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
    GameMenuFrame:HookScript("OnShow", function(menu) StyleAllButtons(menu) end)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", InstallGameMenuButton)

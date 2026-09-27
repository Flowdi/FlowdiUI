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
local textureStates = setmetatable({}, { __mode = "k" })

local function SaveTexture(texture)
    if not texture or textureStates[texture] then return end
    textureStates[texture] = {
        atlas = texture.GetAtlas and texture:GetAtlas(),
        file = texture:GetTexture(),
        alpha = texture:GetAlpha(),
        vertex = { texture:GetVertexColor() },
        texCoord = { texture:GetTexCoord() },
    }
end

local function RestoreTexture(texture)
    local state = texture and textureStates[texture]
    if not state then return end
    if state.atlas and texture.SetAtlas then texture:SetAtlas(state.atlas) else texture:SetTexture(state.file) end
    texture:SetAlpha(state.alpha or 1)
    texture:SetVertexColor(unpack(state.vertex))
    texture:SetTexCoord(unpack(state.texCoord))
end

local function PaintTexture(texture, red, green, blue, alpha)
    if not texture then return end
    SaveTexture(texture)
    texture:SetColorTexture(red, green, blue, alpha or 1)
    texture:SetAlpha(alpha or 1)
    texture:SetTexCoord(0, 1, 0, 1)
end

local function EnsureButtonBorder(button)
    if button.FlowdiDarkBorder then return button.FlowdiDarkBorder end
    local border = CreateFrame("Frame", nil, button, "BackdropTemplate")
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", 0, 0)
    border:EnableMouse(false)
    border:SetBackdrop({ edgeFile = FUI.textures.Flat, edgeSize = 1 })
    button.FlowdiDarkBorder = border
    return border
end

local function ApplyButtonStyle(button, branded, darkEnabled)
    local enabled = branded or darkEnabled
    local border = EnsureButtonBorder(button)
    border:SetFrameLevel(button:GetFrameLevel() + 10)
    border:SetShown(enabled)

    local normal = button.GetNormalTexture and button:GetNormalTexture()
    local pushed = button.GetPushedTexture and button:GetPushedTexture()
    local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
    local disabled = button.GetDisabledTexture and button:GetDisabledTexture()
    if enabled then
        PaintTexture(normal, 0.055, 0.055, 0.060, 1)
        PaintTexture(pushed, 0.08, 0.12, 0.18, 1)
        PaintTexture(highlight, 0.10, 0.30, 0.58, 0.55)
        PaintTexture(disabled, 0.025, 0.025, 0.030, 0.85)
        local accent = FUI.colors.accent or { 0.18, 0.55, 1, 1 }
        if branded then
            border:SetBackdrop({ edgeFile = FUI.textures.Flat, edgeSize = 2 })
            border:SetBackdropBorderColor(accent[1], accent[2], accent[3], 1)
        else
            border:SetBackdrop({ edgeFile = FUI.textures.Flat, edgeSize = 1 })
            border:SetBackdropBorderColor(0.28, 0.30, 0.34, 1)
        end
    else
        for _, method in ipairs(textureMethods) do
            local texture = button[method] and button[method](button)
            RestoreTexture(texture)
        end
    end

    local text = button.GetFontString and button:GetFontString()
    if text then
        text:SetAlpha(1)
        text:SetTextColor(1, 1, 1, 1)
        text:SetFont(FUI:GetFontPath(FUI.db and FUI.db.global.font), branded and 13 or 12, "OUTLINE")
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

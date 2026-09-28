local _, ns = ...
local FUI = ns.FUI

local module = {}
FUI:RegisterModule("actionBars", module)

module.barOrder = {
    { key = "main", label = "Action Bar 1 (Main)", frame = "MainActionBar", fallbackFrame = "MainMenuBar", prefix = "ActionButton", maximum = 12 },
    { key = "bottomLeft", label = "Action Bar 2", frame = "MultiBarBottomLeft", prefix = "MultiBarBottomLeftButton", maximum = 12 },
    { key = "bottomRight", label = "Action Bar 3", frame = "MultiBarBottomRight", prefix = "MultiBarBottomRightButton", maximum = 12 },
    { key = "right", label = "Action Bar 4", frame = "MultiBarRight", prefix = "MultiBarRightButton", maximum = 12 },
    { key = "left", label = "Action Bar 5", frame = "MultiBarLeft", prefix = "MultiBarLeftButton", maximum = 12 },
    { key = "bar5", label = "Action Bar 6", frame = "MultiBar5", prefix = "MultiBar5Button", maximum = 12 },
    { key = "bar6", label = "Action Bar 7", frame = "MultiBar6", prefix = "MultiBar6Button", maximum = 12 },
    { key = "bar7", label = "Action Bar 8", frame = "MultiBar7", prefix = "MultiBar7Button", maximum = 12 },
    { key = "pet", label = "Pet Bar", frame = "PetActionBar", prefix = "PetActionButton", maximum = 10 },
    { key = "stance", label = "Stance Bar", frame = "StanceBar", prefix = "StanceButton", maximum = 10 },
}

local definitionsByPrefix = {}
for _, definition in ipairs(module.barOrder) do definitionsByPrefix[definition.prefix] = definition end
local function IsSecret(value) return issecretvalue and issecretvalue(value) end
local function ResolveBar(definition)
    return _G[definition.frame] or (definition.fallbackFrame and _G[definition.fallbackFrame])
end

local function SuppressMainPager()
    local bar = MainActionBar
    local pager = bar and bar.ActionBarPageNumber
    if pager then
        pager:SetAlpha(0)
        if pager.EnableMouse then pager:EnableMouse(false) end
        if pager.EnableMouseClicks then pager:EnableMouseClicks(false) end
        if pager.EnableMouseMotion then pager:EnableMouseMotion(false) end
        if pager.GetChildren then
            for index = 1, pager:GetNumChildren() do
                local child = select(index, pager:GetChildren())
                if child then
                    child:SetAlpha(0)
                    if child.EnableMouse then child:EnableMouse(false) end
                    if child.EnableMouseClicks then child:EnableMouseClicks(false) end
                    if child.EnableMouseMotion then child:EnableMouseMotion(false) end
                end
            end
        end
    end
    if MainMenuBarPageNumber then MainMenuBarPageNumber:Hide() end
end

local function ButtonIsEmpty(button)
    if button.HasAction then
        local ok, hasAction = pcall(button.HasAction, button)
        if ok and not IsSecret(hasAction) then return hasAction ~= true end
    end
    if not HasAction then return false end
    local action = button.action
    if not action and button.GetAttribute then
        local ok, value = pcall(button.GetAttribute, button, "action")
        if ok and not IsSecret(value) then action = value end
    end
    if not action or IsSecret(action) then return false end
    local ok, hasAction = pcall(HasAction, action)
    return ok and not IsSecret(hasAction) and hasAction ~= true
end

local function BarSettings(definition)
    local db = FUI.db and FUI.db.actionBars
    return db and db.bars and db.bars[definition.key]
end

local function ButtonRegions(button)
    local name = button and button:GetName()
    return button and (button.HotKey or (name and _G[name .. "HotKey"])),
        button and (button.Count or (name and _G[name .. "Count"])),
        button and (button.Name or (name and _G[name .. "Name"]))
end

local function SuppressNativeButtonEffects(button)
    if not button or button.FlowdiNativeEffectsSuppressed then return end
    button.FlowdiNativeEffectsSuppressed = true
    local name = button:GetName()
    local flash = button.Flash or (name and _G[name .. "Flash"])
    local action = button.NewActionTexture
    local highlight = button.SpellHighlightTexture
    local pushed = button.GetPushedTexture and button:GetPushedTexture()
    for _, region in pairs({ flash, action, highlight, pushed }) do
        if region then region:SetAlpha(0) end
    end
    for _, effect in pairs({ button.SpellCastAnimFrame, button.InterruptDisplay, button.TargetReticleAnimFrame }) do
        if effect then
            effect:SetAlpha(0)
            if effect.HookScript and not effect.FlowdiHiddenHook then
                effect.FlowdiHiddenHook = true
                effect:HookScript("OnShow", function(self) self:SetAlpha(0) end)
            end
        end
    end
end

function module:SkinActionButton(button, settings)
    if not button then return end
    FUI:SkinButton(button)
    settings = settings or FUI.db.actionBars
    local name = button:GetName()
    local hotkey, count, macro = ButtonRegions(button)
    local empty = ButtonIsEmpty(button)
    local icon = button.icon or button.Icon or _G[name and (name .. "Icon")]
    local normal = button.GetNormalTexture and button:GetNormalTexture()
    if normal then normal:SetAlpha(0) end
    if button.SlotBackground then button.SlotBackground:SetAlpha(0) end
    SuppressNativeButtonEffects(button)
    if icon then icon:SetAlpha(empty and 0 or 1) end
    if hotkey then
        if _G.RANGE_INDICATOR and hotkey:GetText() == _G.RANGE_INDICATOR then
            hotkey:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
        else
            hotkey:SetFont(FUI:GetModuleFontPath("actionBars"), settings.hotkeySize or 10, FUI.db.global.fontOutline)
        end
        hotkey:SetTextColor(0.72, 0.82, 1)
        hotkey:SetShown(FUI.db.actionBars.showHotkeys ~= false)
        hotkey:SetAlpha(empty and 0 or 1)
    end
    if count then count:SetFont(FUI:GetModuleFontPath("actionBars"), settings.countSize or 11, FUI.db.global.fontOutline) end
    if macro then
        macro:SetFont(FUI:GetModuleFontPath("actionBars"), settings.macroSize or 9, FUI.db.global.fontOutline)
        macro:SetShown(FUI.db.actionBars.showMacroText ~= false)
    end
    if settings.buttons and name then
        local index = tonumber(name:match("(%d+)$")) or 1
        local configured = index <= (settings.buttons or 12)
        button:SetAlpha(configured and (settings.showEmpty or not empty) and 1 or 0)
        if button.EnableMouse and not InCombatLockdown() then
            button:EnableMouse(configured and settings.enabled ~= false and not settings.clickThrough)
        end
    end
end

function module:ApplyBar(definition)
    local settings = BarSettings(definition)
    local bar = ResolveBar(definition)
    if not settings or not bar or InCombatLockdown() then return end
    local count = math.max(1, math.min(definition.maximum, math.floor(settings.buttons or definition.maximum)))
    local rows = math.max(1, math.min(count, math.floor(settings.rows or 1)))
    local columns = math.ceil(count / rows)
    local scale = (FUI.db.scale or 1) * (FUI.db.actionBars.scale or 1) * (settings.scale or 1)
    local size = (settings.iconSize or 36) * scale
    local spacing = (settings.spacing or 2) * scale
    bar:SetScale(1)

    for index = 1, definition.maximum do
        local button = _G[definition.prefix .. index]
        if button then
            self:SkinActionButton(button, settings)
            if button.FlowdiBackdrop then
                local borderSize = math.max(0, settings.borderSize or 1)
                button.FlowdiBackdrop:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = borderSize > 0 and FUI.textures.Flat or nil, edgeSize = math.max(1, borderSize) })
                local color = settings.borderColor or FUI.colors.border
                local background = settings.backgroundColor or FUI.colors.background
                button.FlowdiBackdrop:SetBackdropColor(background[1], background[2], background[3], settings.backgroundOpacity or background[4] or 1)
                button.FlowdiBackdrop:SetBackdropBorderColor(color[1], color[2], color[3], color[4] or 1)
            end
            button:SetSize(size, size)
            button:ClearAllPoints()
            local row, column
            if settings.vertical then
                row = (index - 1) % rows
                column = math.floor((index - 1) / rows)
            else
                column = (index - 1) % columns
                row = math.floor((index - 1) / columns)
            end
            button:SetPoint("TOPLEFT", bar, "TOPLEFT", column * (size + spacing), -row * (size + spacing))
            local configured = index <= count
            local empty = ButtonIsEmpty(button)
            button:SetAlpha(configured and (settings.showEmpty or not empty) and 1 or 0)
            if button.EnableMouse then button:EnableMouse(configured and settings.enabled ~= false and not settings.clickThrough) end
        end
    end
    bar:SetSize(columns * size + math.max(0, columns - 1) * spacing, rows * size + math.max(0, rows - 1) * spacing)
    local key = "actionBar" .. definition.key:sub(1, 1):upper() .. definition.key:sub(2)
    if FUI.movers and FUI.movers[key] then
        local mover = FUI.movers[key]
        FUI:SyncMoverOverlay(mover)
        if FUI.unlockMode and FUI.unlockMode.active and mover.overlay then
            local show = not mover.shouldShow or mover.shouldShow(mover) ~= false
            mover.overlay:SetShown(show)
            if not show and mover.overlay.coordinatePanel then mover.overlay.coordinatePanel:Hide() end
        end
    end
    self:UpdateBarVisibility(definition)
end

function module:UpdateBarVisibility(definition)
    local settings = BarSettings(definition)
    local bar = ResolveBar(definition)
    if not settings or not bar then return end
    local visible = settings.enabled ~= false
    local mode = settings.visibility or "Always"
    if visible and mode == "Mouseover" then
        local ok, hovered = pcall(bar.IsMouseOver, bar)
        visible = ok and not IsSecret(hovered) and hovered == true
    end
    bar:SetAlpha(visible and (settings.alpha or 1) or 0)
end

function module:SkinAllButtons()
    for _, definition in ipairs(self.barOrder) do
        local settings = BarSettings(definition)
        for index = 1, definition.maximum do self:SkinActionButton(_G[definition.prefix .. index], settings) end
    end
    if ExtraActionButton1 then self:SkinActionButton(ExtraActionButton1) end
    if ZoneAbilityFrame and ZoneAbilityFrame.SpellButton then self:SkinActionButton(ZoneAbilityFrame.SpellButton) end
end

function module:Apply()
    if InCombatLockdown() then FUI.pendingApply = true return end
    for _, definition in ipairs(self.barOrder) do self:ApplyBar(definition) end
    self:SkinAllButtons()
    SuppressMainPager()
end

function module:RegisterMovers()
    for _, definition in ipairs(self.barOrder) do
        local moverDefinition = definition
        local bar = ResolveBar(definition)
        if bar then
            local key = "actionBar" .. definition.key:sub(1, 1):upper() .. definition.key:sub(2)
            if not FUI.db.positions[key] then
                local centerX, centerY = bar:GetCenter()
                if centerX and centerY then
                    FUI.db.positions[key] = { "CENTER", "BOTTOMLEFT", centerX, centerY }
                end
            else
                FUI:RestorePosition(bar, key)
            end
            FUI:RegisterMover(bar, key, definition.label, function() module:ApplyBar(moverDefinition) end)
            FUI.movers[key].shouldShow = function()
                local currentSettings = BarSettings(moverDefinition)
                local currentBar = ResolveBar(moverDefinition)
                return currentSettings and currentSettings.enabled ~= false and currentBar and currentBar:IsShown()
            end
        end
    end
end

function module:Initialize()
    self:Apply()
    self:RegisterMovers()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    eventFrame:RegisterEvent("UPDATE_BINDINGS")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD" then
            module:Apply()
            if event == "PLAYER_ENTERING_WORLD" and C_Timer and C_Timer.After then
                C_Timer.After(0, function() module:Apply() end)
                C_Timer.After(0.5, function() module:Apply() end)
            end
        else module:SkinAllButtons() end
        for _, definition in ipairs(module.barOrder) do module:UpdateBarVisibility(definition) end
    end)
    eventFrame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.10 then return end
        self.elapsed = 0
        for _, definition in ipairs(module.barOrder) do module:UpdateBarVisibility(definition) end
    end)
    if ActionButton_Update then
        hooksecurefunc("ActionButton_Update", function(button)
            local name = button and button:GetName() or ""
            for prefix, definition in pairs(definitionsByPrefix) do
                if name:find(prefix, 1, true) == 1 then
                    module:SkinActionButton(button, BarSettings(definition))
                    return
                end
            end
            module:SkinActionButton(button)
        end)
    end
end

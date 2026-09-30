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
local effectAlphaLocked = setmetatable({}, { __mode = "k" })
local effectAlphaActive = setmetatable({}, { __mode = "k" })
local effectFramesHooked = setmetatable({}, { __mode = "k" })
local effectButtonsHooked = setmetatable({}, { __mode = "k" })
local pressFeedbacks = setmetatable({}, { __mode = "k" })
local pressStateHooked = setmetatable({}, { __mode = "k" })
local pressedButtons = setmetatable({}, { __mode = "k" })
local pressVisibleUntil = setmetatable({}, { __mode = "k" })
local cooldownVisuals = setmetatable({}, { __mode = "k" })
local cooldownFramesHooked = setmetatable({}, { __mode = "k" })
local nativeSwipeLock = setmetatable({}, { __mode = "k" })
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

local function LockEffectAlpha(region)
    if not region or not region.SetAlpha then return end
    region:SetAlpha(0)
    if effectAlphaLocked[region] then return end
    effectAlphaLocked[region] = true
    hooksecurefunc(region, "SetAlpha", function(self, alpha)
        if effectAlphaActive[self] then return end
        if IsSecret(alpha) or alpha ~= 0 then
            effectAlphaActive[self] = true
            self:SetAlpha(0)
            effectAlphaActive[self] = nil
        end
    end)
end

local function HideAnimatedEffect(effect)
    if not effect then return end
    effect:SetAlpha(0)
    if effect.GetAnimationGroups then
        for index = 1, select("#", effect:GetAnimationGroups()) do
            local group = select(index, effect:GetAnimationGroups())
            if group and group.Stop then group:Stop() end
        end
    end
    if effect.Hide and not (effect.IsForbidden and effect:IsForbidden()) then pcall(effect.Hide, effect) end
    if effectFramesHooked[effect] or not effect.HookScript then return end
    effectFramesHooked[effect] = true
    effect:HookScript("OnShow", function(self)
        self:SetAlpha(0)
        if self.GetAnimationGroups then
            for index = 1, select("#", self:GetAnimationGroups()) do
                local group = select(index, self:GetAnimationGroups())
                if group and group.Stop then group:Stop() end
            end
        end
        if self.Hide and not (self.IsForbidden and self:IsForbidden()) then pcall(self.Hide, self) end
    end)
end

local function SuppressNativeButtonEffects(button)
    if not button then return end
    local name = button:GetName()
    local flash = button.Flash or (name and _G[name .. "Flash"])
    local methodHighlight = button.GetHighlightTexture and button:GetHighlightTexture()
    local methodPushed = button.GetPushedTexture and button:GetPushedTexture()
    local methodChecked = button.GetCheckedTexture and button:GetCheckedTexture()
    for _, region in pairs({
        flash,
        button.NewActionTexture,
        button.SpellHighlightTexture,
        button.HighlightTexture,
        methodHighlight,
        button.PushedTexture,
        methodPushed,
        button.CheckedTexture,
        methodChecked,
        button.Border,
        button.BorderShadow,
        button.FlyoutBorder,
        button.FlyoutBorderShadow,
    }) do
        LockEffectAlpha(region)
    end
    for _, effect in pairs({ button.SpellCastAnimFrame, button.InterruptDisplay, button.TargetReticleAnimFrame }) do
        HideAnimatedEffect(effect)
    end
    if not effectButtonsHooked[button] and button.HookScript then
        effectButtonsHooked[button] = true
        button:HookScript("OnEnter", function(self) SuppressNativeButtonEffects(self) end)
        button:HookScript("OnMouseDown", function(self) SuppressNativeButtonEffects(self) end)
        button:HookScript("OnMouseUp", function(self) SuppressNativeButtonEffects(self) end)
    end
end

local function EnsurePressFeedback(button)
    local feedback = pressFeedbacks[button]
    if not feedback then
        feedback = CreateFrame("Frame", nil, button, "BackdropTemplate")
        feedback:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
        feedback:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        feedback:SetFrameLevel(button:GetFrameLevel() + 8)
        feedback:EnableMouse(false)
        feedback:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 2 })
        feedback:SetBackdropColor(0.04, 0.20, 0.55, 0.32)
        feedback:SetBackdropBorderColor(0.28, 0.72, 1, 0.95)
        feedback:Hide()
        pressFeedbacks[button] = feedback
    end
    if pressStateHooked[button] then return feedback end
    pressStateHooked[button] = true

    local function SetPressed(down)
        if down then
            pressedButtons[button] = true
            pressVisibleUntil[button] = GetTime() + 0.10
            feedback:Show()
            return
        end
        pressedButtons[button] = nil
        local remaining = (pressVisibleUntil[button] or 0) - GetTime()
        if remaining <= 0 then
            feedback:Hide()
        else
            C_Timer.After(remaining, function()
                if not pressedButtons[button] and GetTime() >= (pressVisibleUntil[button] or 0) then
                    feedback:Hide()
                end
            end)
        end
    end

    if button.SetButtonState then
        hooksecurefunc(button, "SetButtonState", function(_, state)
            SetPressed(state == "PUSHED")
        end)
    end
    if button.HookScript then
        button:HookScript("OnMouseDown", function() SetPressed(true) end)
        button:HookScript("OnMouseUp", function() SetPressed(false) end)
        button:HookScript("OnHide", function()
            pressedButtons[button] = nil
            feedback:Hide()
        end)
    end
    return feedback
end

local RefreshActionCooldown

local function EnsureActionCooldownVisual(button)
    if not button then return end
    local name = button.GetName and button:GetName()
    local native = button.cooldown or button.Cooldown or (name and _G[name .. "Cooldown"])
    if not native then return end

    local visual = cooldownVisuals[button]
    if not visual then
        visual = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        visual:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
        visual:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        visual:SetFrameLevel(button:GetFrameLevel() + 5)
        if visual.SetDrawSwipe then visual:SetDrawSwipe(true) end
        if visual.SetDrawEdge then visual:SetDrawEdge(false) end
        if visual.SetDrawBling then visual:SetDrawBling(false) end
        if visual.SetHideCountdownNumbers then visual:SetHideCountdownNumbers(true) end
        if visual.SetSwipeTexture then visual:SetSwipeTexture(FUI.textures.Flat) end
        if visual.SetSwipeColor then visual:SetSwipeColor(0.015, 0.16, 0.42, 0.82) end
        visual:Hide()
        cooldownVisuals[button] = visual
    end

    -- The native cooldown keeps ownership of its countdown text. FlowdiUI draws
    -- only the swipe one frame below it so both always share the exact same timer.
    visual:SetFrameLevel(button:GetFrameLevel() + 5)
    native:SetFrameLevel(button:GetFrameLevel() + 6)
    nativeSwipeLock[native] = true
    if native.SetDrawSwipe then native:SetDrawSwipe(false) end
    if native.SetDrawEdge then native:SetDrawEdge(false) end
    if native.SetDrawBling then native:SetDrawBling(false) end
    nativeSwipeLock[native] = nil

    if cooldownFramesHooked[native] then return visual end
    cooldownFramesHooked[native] = true
    if native.SetDrawSwipe then
        hooksecurefunc(native, "SetDrawSwipe", function(self, enabled)
            if nativeSwipeLock[self] or enabled == false then return end
            nativeSwipeLock[self] = true
            self:SetDrawSwipe(false)
            nativeSwipeLock[self] = nil
        end)
    end
    if native.SetCooldownFromDurationObject and visual.SetCooldownFromDurationObject then
        hooksecurefunc(native, "SetCooldownFromDurationObject", function(_, durationObject)
            if not durationObject then return end
            visual:SetCooldownFromDurationObject(durationObject)
            visual:Show()
        end)
    end
    if native.SetCooldown then
        hooksecurefunc(native, "SetCooldown", function()
            if RefreshActionCooldown then RefreshActionCooldown(button) end
        end)
    end
    if native.Clear then
        hooksecurefunc(native, "Clear", function()
            visual:Clear()
            visual:Hide()
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    if RefreshActionCooldown then RefreshActionCooldown(button) end
                end)
            end
        end)
    end
    return visual
end

RefreshActionCooldown = function(button)
    local visual = EnsureActionCooldownVisual(button)
    if not visual then return end
    local action = button.GetAttribute and button:GetAttribute("action")
    if action and C_ActionBar and C_ActionBar.GetActionCooldown then
        local info = C_ActionBar.GetActionCooldown(action)
        if info and info.isActive and C_ActionBar.GetActionCooldownDuration
            and visual.SetCooldownFromDurationObject then
            local durationObject = C_ActionBar.GetActionCooldownDuration(action)
            if durationObject then
                visual:SetCooldownFromDurationObject(durationObject)
                visual:Show()
                return
            end
        end
    end
    visual:Clear()
    visual:Hide()
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
    EnsurePressFeedback(button)
    RefreshActionCooldown(button)
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

function module:RefreshCooldownVisuals()
    for _, definition in ipairs(self.barOrder) do
        for index = 1, definition.maximum do
            RefreshActionCooldown(_G[definition.prefix .. index])
        end
    end
    RefreshActionCooldown(ExtraActionButton1)
    RefreshActionCooldown(ZoneAbilityFrame and ZoneAbilityFrame.SpellButton)
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
    eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "SPELL_UPDATE_COOLDOWN" or event == "ACTIONBAR_UPDATE_COOLDOWN"
            or event:find("^UNIT_SPELLCAST_") then
            module:RefreshCooldownVisuals()
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function() module:RefreshCooldownVisuals() end)
                C_Timer.After(0.05, function() module:RefreshCooldownVisuals() end)
                C_Timer.After(0.15, function() module:RefreshCooldownVisuals() end)
            end
        elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD" then
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

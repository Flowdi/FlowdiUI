local _, ns = ...
local FUI = ns.FUI

local module = {}
FUI:RegisterModule("actionBars", module)

module.barOrder = {
    { key = "main", label = "Action Bar 1 (Main)", frame = "MainMenuBar", prefix = "ActionButton", maximum = 12 },
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

function module:SkinActionButton(button, settings)
    if not button then return end
    FUI:SkinButton(button)
    settings = settings or FUI.db.actionBars
    local name = button:GetName()
    local hotkey, count, macro = ButtonRegions(button)
    if hotkey then
        hotkey:SetFont(FUI:GetModuleFontPath("actionBars"), settings.hotkeySize or 10, FUI.db.global.fontOutline)
        hotkey:SetTextColor(0.72, 0.82, 1)
        hotkey:SetShown(FUI.db.actionBars.showHotkeys ~= false)
    end
    if count then count:SetFont(FUI:GetModuleFontPath("actionBars"), settings.countSize or 11, FUI.db.global.fontOutline) end
    if macro then
        macro:SetFont(FUI:GetModuleFontPath("actionBars"), settings.macroSize or 9, FUI.db.global.fontOutline)
        macro:SetShown(FUI.db.actionBars.showMacroText ~= false)
    end
    if settings.buttons and name then
        local index = tonumber(name:match("(%d+)$")) or 1
        local configured = index <= (settings.buttons or 12)
        local empty = button.action and HasAction and not HasAction(button.action)
        button:SetAlpha(configured and (settings.showEmpty or not empty) and 1 or 0)
        if button.EnableMouse and not InCombatLockdown() then
            button:EnableMouse(configured and settings.enabled ~= false and not settings.clickThrough)
        end
    end
end

function module:ApplyBar(definition)
    local settings = BarSettings(definition)
    local bar = _G[definition.frame]
    if not settings or not bar or InCombatLockdown() then return end
    local count = math.max(1, math.min(definition.maximum, math.floor(settings.buttons or definition.maximum)))
    local rows = math.max(1, math.min(count, math.floor(settings.rows or 1)))
    local columns = math.ceil(count / rows)
    local size = settings.iconSize or 36
    local spacing = settings.spacing or 2
    bar:SetScale((FUI.db.scale or 1) * (FUI.db.actionBars.scale or 1))

    for index = 1, definition.maximum do
        local button = _G[definition.prefix .. index]
        if button then
            self:SkinActionButton(button, settings)
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
            local empty = button.action and HasAction and not HasAction(button.action)
            button:SetAlpha(configured and (settings.showEmpty or not empty) and 1 or 0)
            if button.EnableMouse then button:EnableMouse(configured and settings.enabled ~= false and not settings.clickThrough) end
        end
    end
    bar:SetSize(columns * size + math.max(0, columns - 1) * spacing, rows * size + math.max(0, rows - 1) * spacing)
    self:UpdateBarVisibility(definition)
end

function module:UpdateBarVisibility(definition)
    local settings = BarSettings(definition)
    local bar = _G[definition.frame]
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
end

function module:Initialize()
    self:Apply()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    eventFrame:RegisterEvent("UPDATE_BINDINGS")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_ENTERING_WORLD" then module:Apply()
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

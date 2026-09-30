local _, ns = ...
local FUI = ns.FUI

local module = {
    bars = {},
    proxies = {},
}
FUI:RegisterModule("utilityFrames", module)

local microDefinitions = {
    { names = { "CharacterMicroButton" }, label = "Character" },
    { names = { "PlayerSpellsMicroButton", "SpellbookMicroButton" }, label = "Spells" },
    { names = { "ProfessionMicroButton" }, label = "Professions" },
    { names = { "AchievementMicroButton" }, label = "Achievements" },
    { names = { "QuestLogMicroButton" }, label = "Quest Log" },
    { names = { "GuildMicroButton" }, label = "Guild" },
    { names = { "LFDMicroButton" }, label = "Group Finder" },
    { names = { "EJMicroButton" }, label = "Adventure Guide" },
    { names = { "CollectionsMicroButton" }, label = "Collections" },
    { names = { "HousingMicroButton" }, label = "Housing" },
    { names = { "StoreMicroButton" }, label = "Shop" },
    { names = { "HelpMicroButton" }, label = "Support" },
    { names = { "MainMenuMicroButton" }, label = "Game Menu" },
}

local bagDefinitions = {
    { names = { "MainMenuBarBackpackButton" }, label = "Backpack" },
    { names = { "CharacterBag0Slot" }, label = "Bag 1" },
    { names = { "CharacterBag1Slot" }, label = "Bag 2" },
    { names = { "CharacterBag2Slot" }, label = "Bag 3" },
    { names = { "CharacterBag3Slot" }, label = "Bag 4" },
    { names = { "CharacterReagentBag0Slot" }, label = "Reagent Bag" },
}

local function ResolveNative(definition)
    for _, name in ipairs(definition.names) do
        if _G[name] then return _G[name], name end
    end
end

local function IsHovered(frame)
    if not frame or not frame.IsMouseOver then return false end
    local ok, value = pcall(frame.IsMouseOver, frame)
    return ok and not (issecretvalue and issecretvalue(value)) and value == true
end

local function Tooltip(owner, text)
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:AddLine(text, 0.35, 0.68, 1)
    GameTooltip:Show()
end

local function CopyTexture(source, destination)
    if not source or not destination then return false end
    local atlas = source.GetAtlas and source:GetAtlas()
    if atlas then
        local ok = pcall(destination.SetAtlas, destination, atlas)
        if ok then return true end
    end
    local texture = source.GetTexture and source:GetTexture()
    if not texture then return false end
    destination:SetTexture(texture)
    if source.GetTexCoord then
        local coordinates = { source:GetTexCoord() }
        if #coordinates >= 8 then destination:SetTexCoord(unpack(coordinates)) end
    end
    return true
end

function module:RefreshProxyIcon(proxy)
    local native = proxy and proxy.native
    if not native then return end
    local source = native.icon or native.Icon or native.IconTexture
    if not source and native.GetNormalTexture then source = native:GetNormalTexture() end
    if CopyTexture(source, proxy.icon) then
        proxy.icon:Show()
        proxy.fallback:Hide()
    else
        proxy.icon:Hide()
        proxy.fallback:Show()
    end
end

function module:CreateProxy(kind, definition, index)
    local native, nativeName = ResolveNative(definition)
    if not native or (native.IsForbidden and native:IsForbidden()) then return end
    local key = kind .. ":" .. nativeName
    if self.proxies[key] then return self.proxies[key] end
    local bar = self.bars[kind]
    local name = "FlowdiUI_" .. kind .. "Button" .. index
    local proxy = CreateFrame("Button", name, bar.holder, "SecureActionButtonTemplate,BackdropTemplate")
    proxy:RegisterForClicks("AnyUp")
    proxy:SetAttribute("type", "click")
    proxy:SetAttribute("clickbutton", native)
    proxy:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    proxy:SetBackdropColor(0.008, 0.016, 0.035, 0.96)
    proxy:SetBackdropBorderColor(unpack(FUI.colors.border))
    proxy.native = native
    proxy.definition = definition

    local icon = proxy:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 3, -3)
    icon:SetPoint("BOTTOMRIGHT", -3, 3)
    proxy.icon = icon
    local fallback = FUI:CreateFont(proxy, 10)
    fallback:SetPoint("CENTER")
    fallback:SetText(definition.label:sub(1, 1))
    proxy.fallback = fallback
    local hover = proxy:CreateTexture(nil, "HIGHLIGHT")
    hover:SetPoint("TOPLEFT", 1, -1)
    hover:SetPoint("BOTTOMRIGHT", -1, 1)
    hover:SetColorTexture(0.18, 0.55, 1, 0.24)
    local pushed = proxy:CreateTexture(nil, "ARTWORK", nil, 2)
    pushed:SetPoint("TOPLEFT", 2, -2)
    pushed:SetPoint("BOTTOMRIGHT", -2, 2)
    pushed:SetColorTexture(0.08, 0.32, 0.7, 0.38)
    proxy:SetPushedTexture(pushed)
    proxy:SetScript("OnEnter", function(self)
        Tooltip(self, definition.label)
        module:UpdateBarAlpha(kind, true)
    end)
    proxy:SetScript("OnLeave", function()
        GameTooltip_Hide()
        C_Timer.After(0.08, function() module:UpdateBarAlpha(kind) end)
    end)
    self:RefreshProxyIcon(proxy)
    self.proxies[key] = proxy
    bar.buttons[#bar.buttons + 1] = proxy
    return proxy
end

function module:CreateBar(kind, definitions)
    if self.bars[kind] then return self.bars[kind] end
    local holder = CreateFrame("Frame", "FlowdiUI_" .. kind .. "Holder", UIParent, "BackdropTemplate")
    holder:SetFrameStrata("MEDIUM")
    holder:SetFrameLevel(15)
    holder:SetClampedToScreen(true)
    holder:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    holder:SetBackdropColor(0.008, 0.016, 0.035, 0.92)
    holder:SetBackdropBorderColor(unpack(FUI.colors.border))
    holder:EnableMouse(true)
    holder:SetScript("OnEnter", function() module:UpdateBarAlpha(kind, true) end)
    holder:SetScript("OnLeave", function() C_Timer.After(0.08, function() module:UpdateBarAlpha(kind) end) end)
    local bar = { holder = holder, buttons = {}, definitions = definitions }
    self.bars[kind] = bar
    return bar
end

function module:BuildBar(kind)
    local bar = self.bars[kind]
    if not bar or InCombatLockdown() then return end
    for index, definition in ipairs(bar.definitions) do self:CreateProxy(kind, definition, index) end
end

function module:LayoutBar(kind)
    local bar = self.bars[kind]
    if not bar then return end
    local db = FUI.db.utilityFrames[kind]
    local size = db.buttonSize
    local spacing = db.spacing
    local count = #bar.buttons
    bar.holder:SetSize(math.max(1, count * size + math.max(0, count - 1) * spacing + 4), size + 4)
    FUI:RestorePosition(bar.holder, kind)
    for index, button in ipairs(bar.buttons) do
        button:SetSize(size, size)
        button:ClearAllPoints()
        button:SetPoint("LEFT", bar.holder, "LEFT", 2 + (index - 1) * (size + spacing), 0)
        button:SetBackdropBorderColor(unpack(FUI.colors.border))
    end
    bar.holder:SetShown(db.enabled and count > 0)
    local mover = FUI.movers and FUI.movers[kind]
    if mover then FUI:SyncMoverOverlay(mover) end
end

function module:UpdateBarAlpha(kind, force)
    local bar = self.bars[kind]
    if not bar then return end
    local db = FUI.db.utilityFrames[kind]
    if not db.enabled then return end
    local unlocked = FUI.db and FUI.db.locked == false
    local visible = unlocked or db.visibility ~= "Mouseover" or force or IsHovered(bar.holder)
    bar.holder:SetAlpha(visible and 1 or 0)
end

function module:SetNativeBarState(kind)
    local db = FUI.db.utilityFrames[kind]
    local custom = db and db.enabled
    local container = kind == "microBar" and _G.MicroMenuContainer or _G.BagsBar
    if container then
        container:SetAlpha(custom and 0 or 1)
        if not InCombatLockdown() and container.EnableMouse then container:EnableMouse(not custom) end
    end
    local bar = self.bars[kind]
    if not bar or InCombatLockdown() then return end
    for _, proxy in ipairs(bar.buttons) do
        if proxy.native and proxy.native.EnableMouse then proxy.native:EnableMouse(not custom) end
    end
end

function module:CreateTrackerHolder()
    if self.trackerHolder then return end
    local holder = CreateFrame("Frame", "FlowdiUI_ObjectiveTrackerHolder", UIParent, "BackdropTemplate")
    holder:SetFrameStrata("MEDIUM")
    holder:SetFrameLevel(5)
    holder:SetClampedToScreen(true)
    holder:EnableMouse(false)
    holder:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    holder:SetBackdropBorderColor(unpack(FUI.colors.border))
    self.trackerHolder = holder
end

function module:StyleTrackerFonts()
    local db = FUI.db.utilityFrames.objectiveTracker
    local path = FUI:GetFontPath(FUI.db.global.font)
    local outline = FUI.db.global.fontOutline
    local headers = { _G.ObjectiveTrackerHeaderFont }
    local lines = { _G.ObjectiveTrackerLineFont }
    for index = 1, 20 do lines[#lines + 1] = _G["ObjectiveTrackerFont" .. index] end
    for _, fontObject in pairs(headers) do
        if fontObject and fontObject.SetFont then
            fontObject:SetFont(path, db.headerSize, outline)
            if fontObject.SetTextColor then fontObject:SetTextColor(unpack(FUI.colors.accent)) end
        end
    end
    for _, fontObject in pairs(lines) do
        if fontObject and fontObject.SetFont then
            fontObject:SetFont(path, db.textSize, outline)
            if fontObject.SetTextColor then fontObject:SetTextColor(unpack(FUI.colors.text)) end
        end
    end
end

function module:AnchorTracker()
    local tracker = _G.ObjectiveTrackerFrame
    local holder = self.trackerHolder
    local db = FUI.db.utilityFrames.objectiveTracker
    if not tracker or not holder or not db.enabled or InCombatLockdown() then return end
    local clear = tracker.ClearAllPointsBase or tracker.ClearAllPoints
    local setPoint = tracker.SetPointBase or tracker.SetPoint
    pcall(clear, tracker)
    pcall(setPoint, tracker, "TOPRIGHT", holder, "TOPRIGHT", -6, -6)
    pcall(tracker.SetSize, tracker, math.max(1, db.width - 12), math.max(1, db.height - 12))
end

function module:ApplyTracker()
    local holder = self.trackerHolder
    if not holder then return end
    local db = FUI.db.utilityFrames.objectiveTracker
    holder:SetSize(db.width, db.height)
    FUI:RestorePosition(holder, "objectiveTracker")
    holder:SetShown(db.enabled)
    holder:SetBackdropColor(0.008, 0.016, 0.035, db.backgroundAlpha)
    holder:SetBackdropBorderColor(unpack(FUI.colors.border))
    self:StyleTrackerFonts()
    self:AnchorTracker()
    local tracker = _G.ObjectiveTrackerFrame
    if tracker and not self.trackerHooks then
        self.trackerHooks = true
        if tracker.ApplySystemAnchor then
            hooksecurefunc(tracker, "ApplySystemAnchor", function()
                C_Timer.After(0, function() module:AnchorTracker() end)
            end)
        end
        tracker:HookScript("OnShow", function() C_Timer.After(0, function() module:AnchorTracker() end) end)
    end
    local mover = FUI.movers and FUI.movers.objectiveTracker
    if mover then FUI:SyncMoverOverlay(mover) end
end

function module:Apply()
    if not self.bars.microBar then return end
    if InCombatLockdown() then
        FUI.pendingApply = true
        return
    end
    self:BuildBar("microBar")
    self:BuildBar("bagBar")
    self:LayoutBar("microBar")
    self:LayoutBar("bagBar")
    self:SetNativeBarState("microBar")
    self:SetNativeBarState("bagBar")
    self:UpdateBarAlpha("microBar")
    self:UpdateBarAlpha("bagBar")
    self:ApplyTracker()
end

function module:SetLocked(locked)
    if not locked then
        if self.bars.microBar then self.bars.microBar.holder:SetAlpha(1) end
        if self.bars.bagBar then self.bars.bagBar.holder:SetAlpha(1) end
    else
        self:UpdateBarAlpha("microBar")
        self:UpdateBarAlpha("bagBar")
    end
end

function module:RegisterMovers()
    FUI:RegisterMover(self.bars.microBar.holder, "microBar", "Micro Bar")
    FUI.movers.microBar.shouldShow = function() return FUI.db.utilityFrames.microBar.enabled and #module.bars.microBar.buttons > 0 end
    FUI:RegisterMover(self.bars.bagBar.holder, "bagBar", "Bag Bar")
    FUI.movers.bagBar.shouldShow = function() return FUI.db.utilityFrames.bagBar.enabled and #module.bars.bagBar.buttons > 0 end
    FUI:RegisterMover(self.trackerHolder, "objectiveTracker", "Objective Tracker", function() module:AnchorTracker() end)
    FUI.movers.objectiveTracker.shouldShow = function() return FUI.db.utilityFrames.objectiveTracker.enabled end
end

function module:Initialize()
    self:CreateBar("microBar", microDefinitions)
    self:CreateBar("bagBar", bagDefinitions)
    self:CreateTrackerHolder()
    self:RegisterMovers()
    self:Apply()

    local events = CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:SetScript("OnEvent", function(_, event, addonName)
        if event ~= "ADDON_LOADED" or addonName == "Blizzard_ObjectiveTracker" or addonName == "Blizzard_MainMenu" then
            C_Timer.After(0, function() module:Apply() end)
            C_Timer.After(0.5, function() module:Apply() end)
        end
    end)
    local hoverElapsed, refreshElapsed = 0, 0
    events:SetScript("OnUpdate", function(_, delta)
        hoverElapsed = hoverElapsed + delta
        refreshElapsed = refreshElapsed + delta
        if hoverElapsed >= 0.05 then
            hoverElapsed = 0
            module:UpdateBarAlpha("microBar")
            module:UpdateBarAlpha("bagBar")
        end
        if refreshElapsed >= 1 then
            refreshElapsed = 0
            module:SetNativeBarState("microBar")
            module:SetNativeBarState("bagBar")
            for _, proxy in pairs(module.proxies) do module:RefreshProxyIcon(proxy) end
            module:StyleTrackerFonts()
        end
    end)
    self.events = events
end

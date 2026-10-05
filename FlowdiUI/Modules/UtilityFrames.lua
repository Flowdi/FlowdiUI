local _, ns = ...
local FUI = ns.FUI

local module = {
    bars = {},
    proxies = {},
}
FUI:RegisterModule("utilityFrames", module)

local microDefinitions = {
    { names = { "CharacterMicroButton" }, label = "Character Info", portrait = true },
    { names = { "ProfessionMicroButton" }, label = "Professions", icon = "Interface\\Icons\\Trade_BlackSmithing" },
    { names = { "SpellbookMicroButton" }, label = "Spellbook", icon = "Interface\\Icons\\INV_Misc_Book_09" },
    { names = { "TalentMicroButton" }, label = "Talents", icon = "Interface\\Icons\\Ability_Marksmanship" },
    { names = { "AchievementMicroButton" }, label = "Legacy", icon = "Interface\\Icons\\Achievement_General" },
    { names = { "QuestLogMicroButton" }, label = "Quest Log", icon = "Interface\\Icons\\INV_Misc_Note_01" },
    { names = { "GuildMicroButton" }, label = "Guild & Communities", icon = "Interface\\Icons\\INV_Banner_03" },
    { names = { "LFDMicroButton" }, label = "Group Finder", icon = "Interface\\Icons\\INV_Helmet_08" },
    { names = { "CollectionsMicroButton" }, label = "Account Collections", icon = "Interface\\Icons\\INV_Misc_Toy_10" },
    { names = { "StoreMicroButton" }, label = "Shop", icon = "Interface\\Icons\\INV_Misc_Coin_01" },
    { names = { "MainMenuMicroButton" }, label = "Game Menu", action = "gameMenu", icon = "Interface\\Icons\\INV_Misc_Gear_01" },
}

local bagDefinitions = {
    { names = { "MainMenuBarBackpackButton" }, label = "Backpack", bagID = 0 },
    { names = { "CharacterBag0Slot" }, label = "Bag 1", bagID = 1 },
    { names = { "CharacterBag1Slot" }, label = "Bag 2", bagID = 2 },
    { names = { "CharacterBag2Slot" }, label = "Bag 3", bagID = 3 },
    { names = { "CharacterBag3Slot" }, label = "Bag 4", bagID = 4 },
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
    if proxy.definition and proxy.definition.portrait and SetPortraitTexture then
        local ok = pcall(SetPortraitTexture, proxy.icon, "player")
        if ok then
            proxy.icon:SetTexCoord(0, 1, 0, 1)
            proxy.icon:Show()
            proxy.fallback:Hide()
            return
        end
    end
    if proxy.definition and proxy.definition.icon then
        proxy.icon:SetTexture(proxy.definition.icon)
        proxy.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        proxy.icon:SetDesaturated(true)
        proxy.icon:SetVertexColor(0.45, 0.72, 1)
        proxy.icon:Show()
        proxy.fallback:Hide()
        return
    end
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

local function ToggleGameMenu()
    if GameMenuFrame and GameMenuFrame:IsShown() then
        if HideUIPanel then HideUIPanel(GameMenuFrame) else GameMenuFrame:Hide() end
    elseif GameMenuFrame_Show then
        GameMenuFrame_Show()
    elseif GameMenuFrame then
        if ShowUIPanel then ShowUIPanel(GameMenuFrame) else GameMenuFrame:Show() end
    end
end

local function ToggleBagByID(bagID, native, mouseButton)
    if FUI.db.bags and FUI.db.bags.combined and ToggleAllBags then
        ToggleAllBags()
    elseif bagID == 0 and ToggleBackpack then
        ToggleBackpack()
    elseif ToggleBag then
        ToggleBag(bagID)
    elseif native and native.Click then
        native:Click(mouseButton or "LeftButton")
    end
end

function module:CreateProxy(kind, definition, index)
    local native, nativeName = ResolveNative(definition)
    if not native or (native.IsForbidden and native:IsForbidden()) then return end
    local key = kind .. ":" .. nativeName
    if self.proxies[key] then return self.proxies[key] end
    local bar = self.bars[kind]
    local name = "FlowdiUI_" .. kind .. "Button" .. index
    local template = kind == "microBar" and "SecureActionButtonTemplate,BackdropTemplate" or "BackdropTemplate"
    local proxy = CreateFrame("Button", name, bar.holder, template)
    proxy:RegisterForClicks("AnyUp")
    if kind == "microBar" and not definition.action then
        -- Forever accepts secure /click actions for its micro buttons, while
        -- an indirect secure type="click" frame reference is ignored.
        proxy:SetAttribute("type", "macro")
        proxy:SetAttribute("macrotext", "/click " .. nativeName)
    elseif definition.action == "gameMenu" then
        proxy:SetScript("OnClick", ToggleGameMenu)
    elseif kind == "bagBar" then
        proxy:SetScript("OnClick", function(_, mouseButton)
            ToggleBagByID(definition.bagID, native, mouseButton)
        end)
    end
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
    local holder = CreateFrame("Frame", "FlowdiUI_ObjectiveTrackerHolder", UIParent)
    holder:SetFrameStrata("MEDIUM")
    holder:SetFrameLevel(5)
    holder:SetClampedToScreen(true)
    if holder.SetClipsChildren then holder:SetClipsChildren(true) end
    holder:EnableMouse(true)
    if holder.EnableMouseWheel then holder:EnableMouseWheel(true) end
    local background = CreateFrame("Frame", "FlowdiUI_ObjectiveTrackerBackground", UIParent, "BackdropTemplate")
    background:SetFrameStrata("BACKGROUND")
    background:SetFrameLevel(0)
    background:SetAllPoints(holder)
    background:EnableMouse(false)
    background:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    background:SetBackdropBorderColor(unpack(FUI.colors.border))
    local scrollTrack = holder:CreateTexture(nil, "ARTWORK")
    scrollTrack:SetWidth(2)
    scrollTrack:SetPoint("TOPRIGHT", -2, -6)
    scrollTrack:SetPoint("BOTTOMRIGHT", -2, 6)
    scrollTrack:SetColorTexture(.08, .18, .3, .85)
    local scrollThumb = holder:CreateTexture(nil, "OVERLAY")
    scrollThumb:SetWidth(4)
    scrollThumb:SetColorTexture(.18, .62, 1, .95)
    local scrollFrame = CreateFrame("ScrollFrame", "FlowdiUI_ObjectiveTrackerScrollFrame", holder)
    scrollFrame:SetPoint("TOPLEFT", 6, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", -7, 6)
    scrollFrame:SetFrameLevel(holder:GetFrameLevel() + 1)
    if scrollFrame.EnableMouseWheel then scrollFrame:EnableMouseWheel(true) end
    scrollFrame:SetScript("OnMouseWheel", function(_, delta) module:ScrollTracker(delta) end)
    local scrollChild = CreateFrame("Frame", "FlowdiUI_ObjectiveTrackerScrollChild", scrollFrame)
    scrollChild:SetSize(1, 1)
    scrollFrame:SetScrollChild(scrollChild)
    holder:SetScript("OnMouseWheel", function(_, delta) module:ScrollTracker(delta) end)
    self.trackerHolder = holder
    self.trackerBackground = background
    self.trackerScrollTrack = scrollTrack
    self.trackerScrollThumb = scrollThumb
    self.trackerScrollFrame = scrollFrame
    self.trackerScrollChild = scrollChild
end

function module:StyleTrackerFonts()
    self:RefreshQuestTracker()
end

local function QuestLogIndex(questID)
    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then return C_QuestLog.GetLogIndexForQuestID(questID) end
    if GetQuestLogIndexByID then return GetQuestLogIndexByID(questID) end
end

local function AddTrackedQuest(result, seen, questID, logIndex)
    if not questID or questID <= 0 or seen[questID] or #result >= 40 then return end
    seen[questID] = true
    logIndex = logIndex or QuestLogIndex(questID)
    local title, level
    if C_QuestLog and C_QuestLog.GetInfo and logIndex and logIndex > 0 then
        local info = C_QuestLog.GetInfo(logIndex)
        if info then title, level = info.title, info.level end
    elseif GetQuestLogTitle and logIndex and logIndex > 0 then
        title, level = GetQuestLogTitle(logIndex)
    end
    if not title and C_QuestLog and C_QuestLog.GetTitleForQuestID then title = C_QuestLog.GetTitleForQuestID(questID) end
    result[#result + 1] = { id = questID, index = logIndex, title = title or ("Quest " .. questID), level = tonumber(level) }
end

local function GetTrackedQuestData()
    local result, seen = {}, {}
    if C_QuestLog and C_QuestLog.GetNumQuestWatches and C_QuestLog.GetQuestIDForQuestWatchIndex then
        for watchIndex = 1, math.min(40, C_QuestLog.GetNumQuestWatches() or 0) do
            AddTrackedQuest(result, seen, C_QuestLog.GetQuestIDForQuestWatchIndex(watchIndex))
        end
    end
    if #result == 0 and C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        for index = 1, C_QuestLog.GetNumQuestLogEntries() do
            local info = C_QuestLog.GetInfo(index)
            if info and not info.isHeader and info.questID then
                local watched = not C_QuestLog.GetQuestWatchType or C_QuestLog.GetQuestWatchType(info.questID) ~= nil
                if watched then AddTrackedQuest(result, seen, info.questID, index) end
            end
        end
    elseif #result == 0 and GetNumQuestLogEntries and GetQuestLogTitle then
        for index = 1, GetNumQuestLogEntries() do
            local _, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(index)
            if not isHeader and questID and (not IsQuestWatched or IsQuestWatched(index)) then AddTrackedQuest(result, seen, questID, index) end
        end
    end
    return result
end

local function GetObjectiveLines(quest)
    local lines = {}
    if C_QuestLog and C_QuestLog.GetQuestObjectives then
        local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, quest.id)
        if ok and type(objectives) == "table" then
            for _, objective in ipairs(objectives) do
                if objective.text and objective.text ~= "" then lines[#lines + 1] = "• " .. objective.text end
            end
        end
    end
    if #lines == 0 and quest.index and GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
        for index = 1, GetNumQuestLeaderBoards(quest.index) do
            local description = GetQuestLogLeaderBoard(index, quest.index)
            if description then lines[#lines + 1] = "• " .. description end
        end
    end
    return lines
end

function module:AcquireQuestRow(index)
    self.questRows = self.questRows or {}
    if self.questRows[index] then return self.questRows[index] end
    local row = CreateFrame("Button", nil, self.trackerScrollChild)
    row:EnableMouse(true)
    if row.EnableMouseWheel then row:EnableMouseWheel(true) end
    row:SetScript("OnMouseWheel", function(_, delta) module:ScrollTracker(delta) end)
    row:SetScript("OnClick", function(self)
        if self.questID and QuestMapFrame_OpenToQuestDetails then pcall(QuestMapFrame_OpenToQuestDetails, self.questID)
        elseif ToggleQuestLog then ToggleQuestLog() end
    end)
    row.title = FUI:CreateFont(row, 12)
    row.title:SetPoint("TOPLEFT", 7, -2)
    row.title:SetJustifyH("LEFT")
    row.objectives = FUI:CreateFont(row, 11)
    row.objectives:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 10, -2)
    row.objectives:SetJustifyH("LEFT")
    row.objectives:SetTextColor(.82, .86, .92)
    self.questRows[index] = row
    return row
end

function module:RefreshQuestTracker()
    local child, scrollFrame = self.trackerScrollChild, self.trackerScrollFrame
    local db = FUI.db.utilityFrames.objectiveTracker
    if not child or not scrollFrame then return end
    local width = math.max(120, scrollFrame:GetWidth())
    local path, outline = FUI:GetFontPath(FUI.db.global.font), FUI.db.global.fontOutline
    if not self.questTrackerTitle then
        self.questTrackerTitle = FUI:CreateFont(child, db.headerSize)
        self.questTrackerSection = FUI:CreateFont(child, db.headerSize)
        self.questTrackerEmpty = FUI:CreateFont(child, db.textSize)
    end
    local quests = GetTrackedQuestData()
    self.questTrackerTitle:ClearAllPoints()
    self.questTrackerTitle:SetPoint("TOPLEFT", child, "TOPLEFT", 2, -2)
    self.questTrackerTitle:SetFont(path, db.headerSize, outline)
    self.questTrackerTitle:SetTextColor(unpack(FUI.colors.accent))
    self.questTrackerTitle:SetText(string.format("All Objectives  %d/40", #quests))
    self.questTrackerSection:ClearAllPoints()
    self.questTrackerSection:SetPoint("TOPLEFT", child, "TOPLEFT", 2, -27)
    self.questTrackerSection:SetFont(path, db.headerSize, outline)
    self.questTrackerSection:SetTextColor(.35, .75, 1)
    self.questTrackerSection:SetText("Quests")
    local y = -52
    for index, quest in ipairs(quests) do
        local row = self:AcquireQuestRow(index)
        row.questID = quest.id
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, y)
        row:SetWidth(width)
        row.title:SetFont(path, db.textSize + 1, outline)
        row.title:SetWidth(width - 14)
        row.title:SetText(string.format("[%s] %s", quest.level or "?", quest.title))
        local color = quest.level and GetQuestDifficultyColor and GetQuestDifficultyColor(quest.level)
        row.title:SetTextColor(color and color.r or 1, color and color.g or .82, color and color.b or .2)
        local objectives = GetObjectiveLines(quest)
        row.objectives:SetFont(path, db.textSize, outline)
        row.objectives:SetWidth(width - 25)
        row.objectives:SetText(table.concat(objectives, "\n"))
        row.objectives:SetShown(#objectives > 0)
        local titleHeight = math.max(db.textSize + 3, row.title:GetStringHeight() or 0)
        local objectiveHeight = #objectives > 0 and math.max(db.textSize + 2, row.objectives:GetStringHeight() or 0) + 3 or 0
        local height = titleHeight + objectiveHeight + 5
        row:SetHeight(height)
        row:Show()
        y = y - height
    end
    for index = #quests + 1, #(self.questRows or {}) do self.questRows[index]:Hide() end
    self.questTrackerEmpty:ClearAllPoints()
    self.questTrackerEmpty:SetPoint("TOPLEFT", child, "TOPLEFT", 12, y - 2)
    self.questTrackerEmpty:SetFont(path, db.textSize, outline)
    self.questTrackerEmpty:SetTextColor(.62, .68, .76)
    self.questTrackerEmpty:SetText("No tracked quests")
    self.questTrackerEmpty:SetShown(#quests == 0)
    if #quests == 0 then y = y - 24 end
    self.trackerContentHeight = math.max(80, -y + 6)
    self:SyncTrackerHeight()
end

function module:AnchorTracker()
    self:RefreshQuestTracker()
end

function module:SyncTrackerHeight()
    local holder = self.trackerHolder
    local scrollFrame, scrollChild = self.trackerScrollFrame, self.trackerScrollChild
    local db = FUI.db.utilityFrames.objectiveTracker
    if not holder or not scrollFrame or not scrollChild or not db.enabled then return end
    local contentHeight = self.trackerContentHeight or 80
    if FUI.db.questing and FUI.db.questing.autoTrackerHeight then
        local top = holder:GetTop()
        local available = top and math.max(120, top - 8) or db.height
        holder:SetHeight(math.min(math.max(120, contentHeight + 12), available))
    else
        holder:SetHeight(db.height)
    end
    local viewport = math.max(1, scrollFrame:GetHeight())
    local maximum = math.max(0, contentHeight - viewport)
    self.trackerScrollOffset = math.max(0, math.min(self.trackerScrollOffset or 0, maximum))
    scrollChild:SetSize(math.max(1, scrollFrame:GetWidth()), math.max(viewport, contentHeight))
    scrollFrame:SetVerticalScroll(self.trackerScrollOffset)
    local track, thumb = self.trackerScrollTrack, self.trackerScrollThumb
    if track and thumb then
        local show = maximum > 0
        track:SetShown(show)
        thumb:SetShown(show)
        if show then
            local trackHeight = math.max(1, holder:GetHeight() - 12)
            local thumbHeight = math.max(24, trackHeight * math.min(1, viewport / contentHeight))
            local travel = math.max(0, trackHeight - thumbHeight)
            thumb:SetHeight(thumbHeight)
            thumb:ClearAllPoints()
            thumb:SetPoint("TOP", track, "TOP", 0, -travel * (self.trackerScrollOffset / maximum))
        end
    end
end

function module:ScrollTracker(delta)
    if not delta or delta == 0 then return end
    self.trackerScrollOffset = math.max(0, (self.trackerScrollOffset or 0) - delta * 36)
    self:SyncTrackerHeight()
end

function module:ApplyTracker()
    local holder = self.trackerHolder
    if not holder then return end
    local db = FUI.db.utilityFrames.objectiveTracker
    local background = self.trackerBackground
    holder:SetSize(db.width, db.height)
    FUI:RestorePosition(holder, "objectiveTracker")
    local questing = FUI.db.questing
    local customEnabled = db.enabled and (not questing or (questing.enabled and questing.integrateTracker))
    holder:SetShown(customEnabled)
    if background then
        local color = db.backgroundColor or { 0.008, 0.016, 0.035, 1 }
        background:SetShown(customEnabled)
        background:SetBackdropColor(color[1], color[2], color[3], db.backgroundAlpha)
        background:SetBackdropBorderColor(unpack(FUI.colors.border))
    end
    local tracker = _G.ObjectiveTrackerFrame
    if tracker then
        tracker:SetAlpha(customEnabled and 0 or 1)
        if tracker.EnableMouse then tracker:EnableMouse(not customEnabled) end
    end
    self:RefreshQuestTracker()
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
    FUI.movers.objectiveTracker.resizeHeight = function(height)
        local settings = FUI.db.utilityFrames.objectiveTracker
        settings.height = math.max(150, math.min(900, math.floor(height + .5)))
        FUI.db.questing.autoTrackerHeight = false
        module.trackerScrollOffset = 0
        module:ApplyTracker()
    end
    FUI.movers.objectiveTracker.minHeight = 150
    FUI.movers.objectiveTracker.maxHeight = 900
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
    events:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    for _, event in ipairs({ "QUEST_LOG_UPDATE", "QUEST_WATCH_LIST_CHANGED", "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN" }) do
        pcall(events.RegisterEvent, events, event)
    end
    events:SetScript("OnEvent", function(_, event, addonName)
        if event == "UNIT_PORTRAIT_UPDATE" and addonName ~= "player" then return end
        if event == "QUEST_LOG_UPDATE" or event == "QUEST_WATCH_LIST_CHANGED" or event == "QUEST_ACCEPTED" or event == "QUEST_REMOVED" or event == "QUEST_TURNED_IN" then
            C_Timer.After(0, function() module:RefreshQuestTracker() end)
            return
        end
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
            module:RefreshQuestTracker()
            local tracker = _G.ObjectiveTrackerFrame
            local questing = FUI.db.questing
            local hideNative = FUI.db.utilityFrames.objectiveTracker.enabled and questing and questing.enabled and questing.integrateTracker
            if tracker then
                tracker:SetAlpha(hideNative and 0 or 1)
                if tracker.EnableMouse then tracker:EnableMouse(not hideNative) end
            end
        end
    end)
    self.events = events
end

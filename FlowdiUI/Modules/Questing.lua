local _, ns = ...
local FUI = ns.FUI

local module = {
    questieReady = false,
    callbacksRegistered = false,
}
FUI:RegisterModule("questing", module)

local function CopyLocation(location)
    if type(location) ~= "table" then return nil end
    return { location[1], location[2], location[3], location[4], location[5] }
end

local function IsQuestieLoaded()
    if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded("Questie") end
    return IsAddOnLoaded and IsAddOnLoaded("Questie")
end

local function AddonExists(name)
    if C_AddOns and C_AddOns.DoesAddOnExist then return C_AddOns.DoesAddOnExist(name) end
    if GetAddOnInfo then return GetAddOnInfo(name) ~= nil end
    return false
end

function module:EnsureQuestieProvider()
    if IsQuestieLoaded() then return true end
    if not AddonExists("Questie") or not AddonExists("QuestieDB") then
        self.providerState = "missing"
        return false
    end
    if C_AddOns and C_AddOns.EnableAddOn then
        pcall(C_AddOns.EnableAddOn, "QuestieDB")
        pcall(C_AddOns.EnableAddOn, "Questie")
    elseif EnableAddOn then
        pcall(EnableAddOn, "QuestieDB")
        pcall(EnableAddOn, "Questie")
    end
    local loaded, reason
    if C_AddOns and C_AddOns.LoadAddOn then
        local ok
        ok, loaded, reason = pcall(C_AddOns.LoadAddOn, "Questie")
        if not ok then loaded, reason = false, loaded end
    elseif LoadAddOn then
        local ok
        ok, loaded, reason = pcall(LoadAddOn, "Questie")
        if not ok then loaded, reason = false, loaded end
    end
    self.providerState = loaded and "loaded" or "reload"
    if not loaded and not self.providerNotice then
        self.providerNotice = true
        FUI:Print("Questie and QuestieDB were enabled for the Questing module. Reload the UI once to activate map pins.")
    end
    return loaded == true
end

function module:GetQuestieModule(name)
    if not QuestieLoader or not QuestieLoader.ImportModule then return nil end
    local ok, result = pcall(QuestieLoader.ImportModule, QuestieLoader, name)
    return ok and result or nil
end

function module:CaptureQuestieSettings(profile)
    local db = FUI.db.questing
    if db.questieBackup then return end
    db.questieBackup = {
        enableMapIcons = profile.enableMapIcons,
        enableMiniMapIcons = profile.enableMiniMapIcons,
        enableObjectives = profile.enableObjectives,
        enableAvailable = profile.enableAvailable,
        enableAvailableItems = profile.enableAvailableItems,
        enableTurnins = profile.enableTurnins,
        enabled = profile.enabled,
        trackerEnabled = profile.trackerEnabled,
        iconTheme = profile.iconTheme,
        ICON_SLAY = profile.ICON_SLAY,
        ICON_LOOT = profile.ICON_LOOT,
        ICON_EVENT = profile.ICON_EVENT,
        ICON_OBJECT = profile.ICON_OBJECT,
        ICON_TALK = profile.ICON_TALK,
        ICON_INTERACT = profile.ICON_INTERACT,
        TrackerWidth = profile.TrackerWidth,
        TrackerHeight = profile.TrackerHeight,
        TrackerLocation = CopyLocation(profile.TrackerLocation),
        trackerBackdropEnabled = profile.trackerBackdropEnabled,
        trackerBorderEnabled = profile.trackerBorderEnabled,
        sizerHidden = profile.sizerHidden,
        trackerLocked = profile.trackerLocked,
        trackerFontHeader = profile.trackerFontHeader,
        trackerFontZone = profile.trackerFontZone,
        trackerFontQuest = profile.trackerFontQuest,
        trackerFontObjective = profile.trackerFontObjective,
        trackerFontSizeHeader = profile.trackerFontSizeHeader,
        trackerFontSizeZone = profile.trackerFontSizeZone,
        trackerFontSizeQuest = profile.trackerFontSizeQuest,
        trackerFontSizeObjective = profile.trackerFontSizeObjective,
        trackerFontOutline = profile.trackerFontOutline,
    }
end

function module:RestoreQuestieSettings()
    local backup = FUI.db.questing.questieBackup
    local profile = Questie and Questie.db and Questie.db.profile
    if not backup or not profile then return end
    profile.enableMapIcons = backup.enableMapIcons
    profile.enableMiniMapIcons = backup.enableMiniMapIcons
    profile.enableObjectives = backup.enableObjectives
    profile.enableAvailable = backup.enableAvailable
    profile.enableAvailableItems = backup.enableAvailableItems
    profile.enableTurnins = backup.enableTurnins
    profile.enabled = backup.enabled
    profile.trackerEnabled = backup.trackerEnabled
    profile.iconTheme = backup.iconTheme
    profile.ICON_SLAY = backup.ICON_SLAY
    profile.ICON_LOOT = backup.ICON_LOOT
    profile.ICON_EVENT = backup.ICON_EVENT
    profile.ICON_OBJECT = backup.ICON_OBJECT
    profile.ICON_TALK = backup.ICON_TALK
    profile.ICON_INTERACT = backup.ICON_INTERACT
    profile.TrackerWidth = backup.TrackerWidth
    profile.TrackerHeight = backup.TrackerHeight
    profile.TrackerLocation = CopyLocation(backup.TrackerLocation)
    profile.trackerBackdropEnabled = backup.trackerBackdropEnabled
    profile.trackerBorderEnabled = backup.trackerBorderEnabled
    profile.sizerHidden = backup.sizerHidden
    profile.trackerLocked = backup.trackerLocked
    profile.trackerFontHeader = backup.trackerFontHeader
    profile.trackerFontZone = backup.trackerFontZone
    profile.trackerFontQuest = backup.trackerFontQuest
    profile.trackerFontObjective = backup.trackerFontObjective
    profile.trackerFontSizeHeader = backup.trackerFontSizeHeader
    profile.trackerFontSizeZone = backup.trackerFontSizeZone
    profile.trackerFontSizeQuest = backup.trackerFontSizeQuest
    profile.trackerFontSizeObjective = backup.trackerFontSizeObjective
    profile.trackerFontOutline = backup.trackerFontOutline
    FUI.db.questing.questieBackup = nil
    if ObjectiveTrackerFrame then
        ObjectiveTrackerFrame:SetAlpha(1)
        if ObjectiveTrackerFrame.EnableMouse then ObjectiveTrackerFrame:EnableMouse(true) end
    end
    local questieQuest = self:GetQuestieModule("QuestieQuest")
    if questieQuest and questieQuest.SmoothReset then questieQuest:SmoothReset() end
    local tracker = self:GetQuestieModule("QuestieTracker")
    if tracker and tracker.Update then tracker:Update() end
end

function module:AnchorQuestieTracker()
    local db = FUI.db.questing
    if not db.enabled or not db.integrateTracker then return end
    local utility = FUI.modules.utilityFrames
    local holder = utility and utility.trackerHolder
    local frame = _G.Questie_BaseFrame
    if not holder or not frame or InCombatLockdown() then return end

    local trackerDB = FUI.db.utilityFrames.objectiveTracker
    local width = math.max(120, trackerDB.width - 12)
    local height = math.max(100, trackerDB.height - 12)
    local header = _G.Questie_HeaderFrame
    local questFrame = _G.TrackedQuests
    local scrollFrame = _G.TrackedQuestsScrollFrame
    local scrollChild = _G.TrackedQuestsScrollChildFrame
    local headerHeight = header and header:IsShown() and (header:GetHeight() + 20) or 20
    if db.autoTrackerHeight and scrollChild and scrollChild:GetHeight() > 1 then
        local maximum = math.max(140, (UIParent:GetHeight() / math.max(0.1, holder:GetEffectiveScale())) - 50)
        height = math.max(100, math.min(maximum, scrollChild:GetHeight() + headerHeight + 4))
        holder:SetHeight(height + 12)
    else
        holder:SetHeight(trackerDB.height)
    end
    holder:SetWidth(trackerDB.width)
    if holder.SetClipsChildren then holder:SetClipsChildren(true) end
    if frame:GetParent() ~= holder then frame:SetParent(holder) end
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", holder, "TOPLEFT", 6, -6)
    frame:SetSize(width, height)
    if frame.SetClipsChildren then frame:SetClipsChildren(true) end
    frame:SetBackdropColor(0, 0, 0, 0)
    frame:SetBackdropBorderColor(0, 0, 0, 0)

    -- Questie sizes its content frame from the full quest list. Constrain the
    -- actual viewport as well as the base frame, otherwise its lines continue
    -- below FlowdiUI's background even though TrackerHeight is correct.
    local contentHeight = math.max(40, height - headerHeight)
    if questFrame then
        questFrame:SetWidth(width)
        questFrame:SetHeight(contentHeight)
        if questFrame.SetClipsChildren then questFrame:SetClipsChildren(true) end
        questFrame:EnableMouse(true)
        questFrame:SetMovable(false)
        questFrame:SetResizable(false)
    end
    if scrollFrame then
        scrollFrame:ClearAllPoints()
        scrollFrame:SetAllPoints(questFrame)
        scrollFrame:EnableMouseWheel(true)
        if not scrollFrame.FlowdiWheel then
            scrollFrame.FlowdiWheel = true
            scrollFrame:SetScript("OnMouseWheel", function(self, delta)
                local child = self:GetScrollChild()
                local maximum = child and math.max(0, child:GetHeight() - self:GetHeight()) or 0
                self:SetVerticalScroll(math.max(0, math.min(maximum, self:GetVerticalScroll() - delta * 36)))
            end)
        end
        if scrollFrame.ScrollBar then scrollFrame.ScrollBar:Hide() end
    end
    if not trackerDB.enabled then frame:Hide() end
    holder:SetShown(trackerDB.enabled)
    if utility.trackerBackground then utility.trackerBackground:SetShown(trackerDB.enabled) end
end

function module:RefreshQuestieMap()
    if not self.questieReady then return end
    local db = FUI.db.questing
    local questieQuest = self:GetQuestieModule("QuestieQuest")
    local questieMap = self:GetQuestieModule("QuestieMap")
    if Questie and Questie.SetIcons then Questie.SetIcons() end
    if questieQuest then
        if questieQuest.ToggleAvailableQuests then questieQuest.ToggleAvailableQuests(db.showQuestGivers) end
        if questieQuest.ToggleNotes then questieQuest:ToggleNotes(db.showObjectives) end
    end
    if questieMap and questieMap.RescaleIcons then questieMap:RescaleIcons() end
end

function module:HookWorldMap()
    if not WorldMapFrame or WorldMapFrame.FlowdiQuestieHooked then return end
    WorldMapFrame.FlowdiQuestieHooked = true
    WorldMapFrame:HookScript("OnShow", function()
        C_Timer.After(0, function() module:RefreshQuestieMap() end)
        C_Timer.After(0.5, function() module:RefreshQuestieMap() end)
    end)
end

function module:ApplyQuestieSettings(forceRefresh)
    if not self.questieReady or not Questie or not Questie.db or not Questie.db.profile then return end
    local db = FUI.db.questing
    local profile = Questie.db.profile
    if not db.enabled then
        self:RestoreQuestieSettings()
        return
    end

    self:CaptureQuestieSettings(profile)
    local signature = table.concat({
        tostring(db.worldMapIcons), tostring(db.minimapIcons), tostring(db.showObjectives),
        tostring(db.showQuestGivers), tostring(db.showTurnIns), tostring(db.integrateTracker),
    }, ":")
    local mapChanged = self.lastSignature and self.lastSignature ~= signature
    self.lastSignature = signature

    profile.enableMapIcons = db.worldMapIcons
    profile.enableMiniMapIcons = db.minimapIcons
    profile.enableObjectives = db.showObjectives
    profile.enableAvailable = db.showQuestGivers
    profile.enableAvailableItems = db.showQuestGivers
    profile.enableTurnins = db.showTurnIns
    profile.enabled = true
    profile.trackerEnabled = true
    profile.iconTheme = "questie"
    if Questie.icons then
        profile.ICON_SLAY = Questie.icons.slay
        profile.ICON_LOOT = Questie.icons.loot
        profile.ICON_EVENT = Questie.icons.event
        profile.ICON_OBJECT = Questie.icons.object
        profile.ICON_TALK = Questie.icons.talk
        profile.ICON_INTERACT = Questie.icons.interact
    end
    if GetCVar and SetCVar and GetCVar("questPOI") then pcall(SetCVar, "questPOI", "0") end
    if Questie.SetIcons then Questie.SetIcons() end
    local trackerDB = FUI.db.utilityFrames.objectiveTracker
    if db.integrateTracker then
        local font = FUI.db.global.font or "Friz Quadrata"
        profile.trackerFontHeader = font
        profile.trackerFontZone = font
        profile.trackerFontQuest = font
        profile.trackerFontObjective = font
        profile.trackerFontSizeHeader = trackerDB.headerSize
        profile.trackerFontSizeZone = trackerDB.headerSize
        profile.trackerFontSizeQuest = trackerDB.textSize
        profile.trackerFontSizeObjective = trackerDB.textSize
        profile.trackerFontOutline = FUI.db.global.fontOutline or "OUTLINE"
        profile.TrackerWidth = math.max(120, trackerDB.width - 12)
        profile.TrackerHeight = math.max(100, trackerDB.height - 12)
        profile.TrackerLocation = { "TOPLEFT", "FlowdiUI_ObjectiveTrackerHolder", "TOPLEFT", 6, -6 }
        profile.trackerBackdropEnabled = false
        profile.trackerBorderEnabled = false
        profile.sizerHidden = true
        profile.trackerLocked = true
        if ObjectiveTrackerFrame then
            ObjectiveTrackerFrame:SetAlpha(0)
            if ObjectiveTrackerFrame.EnableMouse then ObjectiveTrackerFrame:EnableMouse(false) end
        end
    else
        local backup = db.questieBackup
        if backup then
            profile.TrackerWidth = backup.TrackerWidth
            profile.TrackerHeight = backup.TrackerHeight
            profile.TrackerLocation = CopyLocation(backup.TrackerLocation)
            profile.trackerBackdropEnabled = backup.trackerBackdropEnabled
            profile.trackerBorderEnabled = backup.trackerBorderEnabled
            profile.sizerHidden = backup.sizerHidden
            profile.trackerLocked = backup.trackerLocked
            profile.trackerFontHeader = backup.trackerFontHeader
            profile.trackerFontZone = backup.trackerFontZone
            profile.trackerFontQuest = backup.trackerFontQuest
            profile.trackerFontObjective = backup.trackerFontObjective
            profile.trackerFontSizeHeader = backup.trackerFontSizeHeader
            profile.trackerFontSizeZone = backup.trackerFontSizeZone
            profile.trackerFontSizeQuest = backup.trackerFontSizeQuest
            profile.trackerFontSizeObjective = backup.trackerFontSizeObjective
            profile.trackerFontOutline = backup.trackerFontOutline
        end
        if ObjectiveTrackerFrame then
            ObjectiveTrackerFrame:SetAlpha(1)
            if ObjectiveTrackerFrame.EnableMouse then ObjectiveTrackerFrame:EnableMouse(true) end
        end
    end

    if forceRefresh or mapChanged then
        local questieQuest = self:GetQuestieModule("QuestieQuest")
        if questieQuest then
            if questieQuest.ToggleAvailableQuests then questieQuest.ToggleAvailableQuests(db.showQuestGivers) end
            if questieQuest.ToggleNotes then questieQuest:ToggleNotes(db.showObjectives) end
            if questieQuest.SmoothReset then questieQuest:SmoothReset() end
        end
        C_Timer.After(1, function() module:RefreshQuestieMap() end)
        C_Timer.After(3, function() module:RefreshQuestieMap() end)
    end
    local tracker = self:GetQuestieModule("QuestieTracker")
    if tracker and tracker.Update then tracker:Update() end
    C_Timer.After(0, function() module:AnchorQuestieTracker() end)
end

function module:OnQuestieReady()
    if self.questieReady then return end
    self.questieReady = true
    self.providerState = "loaded"
    self:HookWorldMap()
    if Questie.API and Questie.API.RegisterForQuestUpdates and not self.callbacksRegistered then
        self.callbacksRegistered = true
        Questie.API.RegisterForQuestUpdates(function()
            C_Timer.After(0, function() module:AnchorQuestieTracker() end)
        end)
    end
    local tracker = self:GetQuestieModule("QuestieTracker")
    if tracker and tracker.Update and not self.trackerHooked then
        self.trackerHooked = true
        hooksecurefunc(tracker, "Update", function()
            C_Timer.After(0, function() module:AnchorQuestieTracker() end)
        end)
    end
    self:ApplyQuestieSettings(true)
end

function module:TryConnect()
    if self.questieReady then return end
    if not IsQuestieLoaded() then self:EnsureQuestieProvider() end
    if not IsQuestieLoaded() or not Questie or not Questie.API then return end
    if Questie.API.isReady then
        self:OnQuestieReady()
    elseif Questie.API.RegisterOnReady and not self.readyCallbackRegistered then
        self.readyCallbackRegistered = true
        Questie.API.RegisterOnReady(function() module:OnQuestieReady() end)
    end
end

function module:Apply()
    self:TryConnect()
    if self.questieReady then self:ApplyQuestieSettings(false) end
end

function module:Initialize()
    self:EnsureQuestieProvider()
    local events = CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:SetScript("OnEvent", function(_, event, addonName)
        if event == "ADDON_LOADED" and addonName ~= "Questie" then return end
        C_Timer.After(0, function() module:Apply() end)
        C_Timer.After(1, function() module:Apply() end)
    end)
    self.anchorTicker = C_Timer.NewTicker(0.2, function()
        if module.questieReady then module:AnchorQuestieTracker() end
    end)
    self.events = events
    self:Apply()
end

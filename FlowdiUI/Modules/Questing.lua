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
        enableTurnins = profile.enableTurnins,
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
    profile.enableTurnins = backup.enableTurnins
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
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", holder, "TOPLEFT", 6, -6)
    frame:SetSize(width, height)
    frame:SetBackdropColor(0, 0, 0, 0)
    frame:SetBackdropBorderColor(0, 0, 0, 0)
    if not trackerDB.enabled then frame:Hide() end
    holder:SetShown(trackerDB.enabled)
    if utility.trackerBackground then utility.trackerBackground:SetShown(trackerDB.enabled) end
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
    profile.enableTurnins = db.showTurnIns
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
        if questieQuest and questieQuest.SmoothReset then questieQuest:SmoothReset() end
    end
    local tracker = self:GetQuestieModule("QuestieTracker")
    if tracker and tracker.Update then tracker:Update() end
    C_Timer.After(0, function() module:AnchorQuestieTracker() end)
end

function module:OnQuestieReady()
    if self.questieReady then return end
    self.questieReady = true
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
    if self.questieReady or not IsQuestieLoaded() or not Questie or not Questie.API then return end
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
    local events = CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:SetScript("OnEvent", function(_, event, addonName)
        if event == "ADDON_LOADED" and addonName ~= "Questie" then return end
        C_Timer.After(0, function() module:Apply() end)
        C_Timer.After(1, function() module:Apply() end)
    end)
    self.anchorTicker = C_Timer.NewTicker(1, function()
        if module.questieReady then module:AnchorQuestieTracker() end
    end)
    self.events = events
    self:Apply()
end

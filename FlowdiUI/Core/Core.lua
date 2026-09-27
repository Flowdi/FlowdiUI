local ADDON_NAME, ns = ...

local FUI = CreateFrame("Frame")
ns.FUI = FUI
_G.FlowdiUI = FUI

FUI.name = ADDON_NAME
FUI.version = "0.7.2"
FUI.modules = {}
FUI.media = {}
FUI.pendingLayout = false
FUI.pendingApply = false
FUI.reputationValues = {}

local defaults = {
    profileVersion = 7,
    locked = true,
    scale = 1,
    global = {
        style = "FlowdiUI",
        font = "Friz Quadrata",
        nameFont = "Friz Quadrata",
        combatFont = "Friz Quadrata",
        fontSize = 12,
        fontOutline = "OUTLINE",
        applyFontToAll = false,
        primaryTexture = "FlowdiUI",
        secondaryTexture = "FlowdiUI Blank",
        castOnKeyDown = true,
        maxCameraDistance = 2.6,
        gameMenuScale = 1,
        optionsScale = 1,
        lagTolerance = 400,
        combatTextSize = 1,
        showCombatDamage = true,
        showCombatHealing = true,
        disableTutorials = false,
        acceptInvites = false,
        thinBorders = true,
        cropIcons = true,
        darkGameMenu = true,
        autoRepair = "None",
        autoTrackReputation = false,
        loginMessage = true,
        backgroundOpacity = 0.96,
        accent = { 0.18, 0.55, 1, 1 },
        background = { 0.025, 0.035, 0.065, 0.96 },
        health = { 0.10, 0.65, 0.32, 1 },
        power = { 0.12, 0.38, 0.90, 1 },
        moduleFonts = {
            actionBars = "Global",
            nameplates = "Name Font",
            unitFrames = "Name Font",
            groupFrames = "Name Font",
            chat = "Global",
            dataPanels = "Global",
        },
    },
    modules = {
        actionBars = true,
        nameplates = true,
        unitFrames = true,
        groupFrames = true,
        chat = true,
        bags = true,
        dataPanels = true,
        darkMode = true,
    },
    actionBars = {
        scale = 1,
        showHotkeys = true,
        showMacroText = true,
    },
    nameplates = {
        width = 120,
        height = 10,
        castHeight = 7,
        fontSize = 11,
    },
    unitFrames = {
        scale = 1,
        playerWidth = 230,
        targetWidth = 230,
        focusWidth = 185,
        height = 46,
        focusHeight = 38,
        powerHeight = 8,
        fontSize = 12,
        selectedFrame = "player",
        frames = {
            player = {
                width = 181, healthHeight = 46, powerHeight = 6, powerPosition = "Below Health Bar",
                texture = "Global", healthColor = "Class", customHealthColor = { 0.10, 0.65, 0.32, 1 },
                healthBackground = { 0.067, 0.067, 0.067, 1 }, healthOpacity = 0.90,
                powerColor = "Power Type", customPowerColor = { 0.12, 0.38, 0.90, 1 },
                powerBackground = { 0.02, 0.03, 0.06, 1 }, powerOpacity = 1,
                leftText = "Name", rightText = "Health %", centerText = "None", extraText = "None",
                powerText = "None", textSize = 12, borderSize = 1, frameStrata = "MEDIUM",
                hoverBorder = true, showTooltip = true, visibility = "Always",
                showPortrait = true, portraitMode = "2D Portrait", portraitPosition = "Left", portraitSize = 46,
                showCastbar = false, castHeight = 14, castOpacity = 1, showCastIcon = true,
                castColor = { 0.86, 0.82, 0.64, 1 }, raidMarker = true, raidMarkerSize = 22,
                leaderIndicator = true, leaderIndicatorSize = 16, combatIndicator = true, combatIndicatorSize = 12,
            },
            target = {
                width = 181, healthHeight = 46, powerHeight = 6, powerPosition = "Below Health Bar",
                texture = "Global", healthColor = "Class", customHealthColor = { 0.10, 0.65, 0.32, 1 },
                healthBackground = { 0.067, 0.067, 0.067, 1 }, healthOpacity = 0.90,
                powerColor = "Power Type", customPowerColor = { 0.12, 0.38, 0.90, 1 },
                powerBackground = { 0.02, 0.03, 0.06, 1 }, powerOpacity = 1,
                leftText = "Level + Name", rightText = "Health %", centerText = "None", extraText = "None",
                powerText = "None", textSize = 12, borderSize = 1, frameStrata = "MEDIUM",
                hoverBorder = true, showTooltip = true, visibility = "Always",
                showPortrait = true, portraitMode = "2D Portrait", portraitPosition = "Right", portraitSize = 46,
                showCastbar = true, castHeight = 14, castOpacity = 1, showCastIcon = true,
                castColor = { 0.86, 0.82, 0.64, 1 }, raidMarker = true, raidMarkerSize = 22,
                leaderIndicator = true, leaderIndicatorSize = 16, combatIndicator = false, combatIndicatorSize = 12,
            },
            focus = {
                width = 160, healthHeight = 34, powerHeight = 6, powerPosition = "Below Health Bar",
                texture = "Global", healthColor = "Class", customHealthColor = { 0.10, 0.65, 0.32, 1 },
                healthBackground = { 0.067, 0.067, 0.067, 1 }, healthOpacity = 0.90,
                powerColor = "Power Type", customPowerColor = { 0.12, 0.38, 0.90, 1 },
                powerBackground = { 0.02, 0.03, 0.06, 1 }, powerOpacity = 1,
                leftText = "Name", rightText = "Health %", centerText = "None", extraText = "None",
                powerText = "None", textSize = 11, borderSize = 1, frameStrata = "MEDIUM",
                hoverBorder = true, showTooltip = true, visibility = "Always",
                showPortrait = false, portraitMode = "2D Portrait", portraitPosition = "Left", portraitSize = 34,
                showCastbar = true, castHeight = 12, castOpacity = 1, showCastIcon = true,
                castColor = { 0.86, 0.82, 0.64, 1 }, raidMarker = true, raidMarkerSize = 20,
                leaderIndicator = false, leaderIndicatorSize = 14, combatIndicator = false, combatIndicatorSize = 10,
            },
        },
    },
    groupFrames = {
        partyScale = 1,
        raidScale = 1,
        partyWidth = 180,
        partyHeight = 42,
        raidWidth = 78,
        raidHeight = 26,
        fontSize = 10,
    },
    chat = {
        fontSize = 12,
        backgroundAlpha = 0.72,
        fade = true,
        timeVisible = 120,
        timestamps = true,
        copyButton = true,
    },
    bags = {
        darkness = 0.82,
        itemLevel = true,
        qualityBorders = true,
    },
    dataPanels = {
        scale = 1,
        opacity = 0.95,
        width = 620,
        height = 24,
        fontSize = 11,
        primaryCount = 5,
        slots = { "System", "Bags", "Gold", "Durability", "Time" },
        secondEnabled = false,
        secondWidth = 620,
        secondHeight = 24,
        secondCount = 5,
        secondSlots = { "Coordinates", "Experience", "Reputation", "Friends", "Guild" },
        minimapEnabled = false,
        minimapPosition = "BOTTOM",
        minimapHeight = 20,
        minimapCount = 2,
        minimapSlots = { "Guild", "Time" },
        backdrop = true,
        border = true,
        transparent = false,
    },
    darkMode = {
        intensity = 0.2,
        skins = {
            character = true,
            quest = true,
            bankBags = true,
            merchant = true,
            mail = true,
            worldMap = true,
        },
    },
    positions = {
        player = { "CENTER", "CENTER", -280, -155 },
        target = { "CENTER", "CENTER", 280, -155 },
        focus = { "CENTER", "CENTER", 280, -235 },
        party = { "LEFT", "LEFT", 42, 20 },
        raid = { "LEFT", "LEFT", 42, 20 },
        dataPanel = { "BOTTOM", "BOTTOM", 0, 4 },
        dataPanel2 = { "TOP", "TOP", 0, -4 },
        settings = { "CENTER", "CENTER", 0, 0 },
    },
}

local function CopyDefaults(source, destination)
    if type(destination) ~= "table" then
        destination = {}
    end

    for key, value in pairs(source) do
        if type(value) == "table" then
            destination[key] = CopyDefaults(value, destination[key])
        elseif destination[key] == nil then
            destination[key] = value
        end
    end
    return destination
end

function FUI:RegisterModule(key, module)
    module.key = key
    self.modules[key] = module
end

function FUI:IsModuleEnabled(key)
    return self.db and self.db.modules[key] ~= false
end

function FUI:SafeCall(label, callback, ...)
    local arguments = { ... }
    local ok, result = xpcall(function()
        return callback(unpack(arguments))
    end, geterrorhandler())
    if not ok then
        self:Print(label .. " could not be loaded.")
    end
    return ok, result
end

function FUI:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff55aaffFlowdiUI:|r " .. tostring(message))
end

function FUI:SavePosition(frame, key)
    if not frame or not key then return end
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    if point then
        self.db.positions[key] = { point, relativePoint, x, y }
    end
end

function FUI:RestorePosition(frame, key)
    local position = self.db.positions[key]
    if not position or type(position[1]) ~= "string" or type(position[2]) ~= "string" or type(position[3]) ~= "number" or type(position[4]) ~= "number" then
        position = defaults.positions[key]
        self.db.positions[key] = { unpack(position) }
    end
    frame:ClearAllPoints()
    frame:SetPoint(position[1], UIParent, position[2], position[3], position[4])
end

function FUI:ResetPositions()
    for key, position in pairs(defaults.positions) do
        self.db.positions[key] = { unpack(position) }
    end
    ReloadUI()
end

function FUI:ApplySettings()
    if InCombatLockdown() then
        self.pendingApply = true
        return
    end
    self:ApplyGlobalSettings()
    for key, module in pairs(self.modules) do
        if self:IsModuleEnabled(key) and module.Apply then
            self:SafeCall(key .. ":Apply", module.Apply, module)
        end
    end
end

function FUI:ApplyGlobalSettings()
    if not self.db or not self.db.global then return end
    local db = self.db.global
    self:RefreshMedia()
    DAMAGE_TEXT_FONT = self:GetFontPath(db.combatFont)
    SetCVar("ActionButtonUseKeyDown", db.castOnKeyDown and 1 or 0)
    SetCVar("cameraDistanceMaxZoomFactor", db.maxCameraDistance or 2.6)
    SetCVar("SpellQueueWindow", db.lagTolerance or 400)
    SetCVar("floatingCombatTextCombatDamage_v2", db.showCombatDamage and 1 or 0)
    SetCVar("floatingCombatTextCombatHealing_v2", db.showCombatHealing and 1 or 0)
    SetCVar("floatingCombatTextCombatDamage", db.showCombatDamage and 1 or 0)
    SetCVar("floatingCombatTextCombatHealing", db.showCombatHealing and 1 or 0)
    SetCVar("WorldTextScale_v2", db.combatTextSize or 1)
    SetCVar("showTutorials", db.disableTutorials and 0 or 1)
    if GameMenuFrame then GameMenuFrame:SetScale(db.gameMenuScale or 1) end
    if self.settings then self.settings:SetScale(db.optionsScale or 1) end

    if db.applyFontToAll and self.GetFontPath then
        local path = self:GetFontPath(db.font)
        local targets = { GameFontNormal, GameFontHighlight, GameFontDisable, GameFontNormalSmall,
            GameFontHighlightSmall, GameFontNormalLarge, GameFontHighlightLarge }
        for _, fontObject in ipairs(targets) do
            if fontObject and fontObject.GetFont then
                local _, size = fontObject:GetFont()
                fontObject:SetFont(path, size or db.fontSize, db.fontOutline or "OUTLINE")
            end
        end
    end
end

function FUI:UpdateTrackedReputation(selectChanged)
    local count = C_Reputation and C_Reputation.GetNumFactions and C_Reputation.GetNumFactions() or (GetNumFactions and GetNumFactions()) or 0
    local bestID, bestGain
    for index = 1, count do
        local factionID, value, isHeader
        if C_Reputation and C_Reputation.GetFactionDataByIndex then
            local data = C_Reputation.GetFactionDataByIndex(index)
            if data then factionID, value, isHeader = data.factionID, data.currentStanding, data.isHeader end
        elseif GetFactionInfo then
            local _, _, _, _, _, barValue, _, _, header, _, _, _, _, id = GetFactionInfo(index)
            factionID, value, isHeader = id, barValue, header
        end
        if factionID and value and not isHeader then
            local previous = self.reputationValues[factionID]
            local gain = previous and value - previous or 0
            if selectChanged and gain > (bestGain or 0) then bestID, bestGain = factionID, gain end
            self.reputationValues[factionID] = value
        end
    end
    if bestID then
        if C_Reputation and C_Reputation.SetWatchedFactionByID then
            C_Reputation.SetWatchedFactionByID(bestID)
        elseif SetWatchedFactionIndex and GetFactionInfo then
            for index = 1, count do
                local _, _, _, _, _, _, _, _, _, _, _, _, _, id = GetFactionInfo(index)
                if id == bestID then SetWatchedFactionIndex(index) break end
            end
        end
    end
end

function FUI:MakeMovable(frame, key)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:HookScript("OnDragStart", function(self)
        if not FUI.db.locked and not InCombatLockdown() then
            self:StartMoving()
        end
    end)
    frame:HookScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        FUI:SavePosition(self, key)
    end)
end

function FUI:SetLocked(locked)
    self.db.locked = locked and true or false
    for _, module in pairs(self.modules) do
        if module.SetLocked then
            self:SafeCall(module.key .. ":SetLocked", module.SetLocked, module, self.db.locked)
        end
    end
end

function FUI:Initialize()
    FlowdiUIDB = CopyDefaults(defaults, FlowdiUIDB or {})
    self.db = FlowdiUIDB
    local previousVersion = self.db.profileVersion or 0
    if previousVersion < 6 then self.db.global.darkGameMenu = true end
    if previousVersion < 7 then
        local unitDB = self.db.unitFrames
        unitDB.frames.player.width = unitDB.playerWidth or unitDB.frames.player.width
        unitDB.frames.target.width = unitDB.targetWidth or unitDB.frames.target.width
        unitDB.frames.focus.width = unitDB.focusWidth or unitDB.frames.focus.width
        unitDB.frames.player.healthHeight = unitDB.height or unitDB.frames.player.healthHeight
        unitDB.frames.target.healthHeight = unitDB.height or unitDB.frames.target.healthHeight
        unitDB.frames.focus.healthHeight = unitDB.focusHeight or unitDB.frames.focus.healthHeight
        for _, settings in pairs(unitDB.frames) do
            settings.powerHeight = unitDB.powerHeight or settings.powerHeight
            settings.textSize = unitDB.fontSize or settings.textSize
        end
    end
    self.db.profileVersion = defaults.profileVersion

    self:DiscoverSharedMedia()
    self:ApplyGlobalSettings()
    for key, module in pairs(self.modules) do
        if self:IsModuleEnabled(key) and module.Initialize then
            self:SafeCall(key, module.Initialize, module)
        end
    end

    self:SetLocked(self.db.locked)
    if self.db.global.loginMessage then
        self:Print("v" .. self.version .. " loaded. Type /fui to open settings.")
    end
    self:UpdateTrackedReputation(false)
end

FUI:RegisterEvent("PLAYER_LOGIN")
FUI:RegisterEvent("PLAYER_REGEN_ENABLED")
FUI:RegisterEvent("MERCHANT_SHOW")
FUI:RegisterEvent("UPDATE_FACTION")
FUI:RegisterEvent("PARTY_INVITE_REQUEST")
FUI:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:Initialize()
    elseif event == "PARTY_INVITE_REQUEST" then
        if self.db and self.db.global.acceptInvites and not InCombatLockdown() then
            AcceptGroup()
            if StaticPopup_Hide then StaticPopup_Hide("PARTY_INVITE") end
        end
    elseif event == "UPDATE_FACTION" then
        self:UpdateTrackedReputation(self.db and self.db.global.autoTrackReputation)
    elseif event == "MERCHANT_SHOW" then
        local mode = self.db and self.db.global and self.db.global.autoRepair
        if mode and mode ~= "None" and CanMerchantRepair and CanMerchantRepair() then
            local useGuild = mode == "Guild" and CanGuildBankRepair and CanGuildBankRepair()
            RepairAllItems(useGuild and true or false)
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if self.pendingLayout then
            self.pendingLayout = false
            self:SetLocked(self.db.locked)
        end
        if self.pendingApply then
            self.pendingApply = false
            self:ApplySettings()
        end
    end
end)

SLASH_FLOWDIUI1 = "/flowdi"
SLASH_FLOWDIUI2 = "/fui"
SlashCmdList.FLOWDIUI = function(message)
    message = (message or ""):lower():match("^%s*(.-)%s*$")
    if message == "unlock" then
        FUI:SetLocked(false)
        FUI:Print("Frames unlocked. Drag them with the left mouse button.")
    elseif message == "lock" then
        FUI:SetLocked(true)
        FUI:Print("Frames locked.")
    else
        FUI:OpenSettings()
    end
end

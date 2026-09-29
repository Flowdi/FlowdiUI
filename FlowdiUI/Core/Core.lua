local ADDON_NAME, ns = ...

local FUI = CreateFrame("Frame")
ns.FUI = FUI
_G.FlowdiUI = FUI

FUI.name = ADDON_NAME
FUI.version = "0.8.21"
FUI.modules = {}
FUI.media = {}
FUI.pendingLayout = false
FUI.pendingApply = false
FUI.reputationValues = {}
FUI.movers = {}

local function AuraDefaults(helpful)
    return {
        enabled = true,
        mineOnly = false,
        desaturate = false,
        tooltip = true,
        clickThrough = false,
        cooldown = true,
        size = 22,
        perRow = 8,
        rows = 1,
        spacing = 2,
        borderSize = 1,
        attachTo = "Frame",
        point = helpful and "Bottom Left" or "Bottom Right",
        relativePoint = helpful and "Top Left" or "Top Right",
        x = 0,
        y = 3,
        growthX = helpful and "Right" or "Left",
        growthY = "Up",
        sortBy = "Time Remaining",
        sortDirection = "Ascending",
        maxDuration = 0,
        showDuration = true,
        durationSize = 9,
        durationPosition = "Bottom",
        showStacks = true,
        stackSize = 10,
        stackPosition = "Top Right",
        allowList = "",
        blockList = "",
    }
end

local function CloneDefaults(source)
    if type(source) ~= "table" then return source end
    local copy = {}
    for key, value in pairs(source) do copy[key] = CloneDefaults(value) end
    return copy
end

local function GroupProfileDefaults(party)
    local profile = {
        enabled = true,
        scale = 1,
        width = party and 180 or 92,
        height = party and 42 or 34,
        spacing = 3,
        groupSpacing = 6,
        unitsPerColumn = 5,
        orientation = party and "Vertical" or "Columns",
        growthX = "Right",
        growthY = "Down",
        showWhenSolo = false,
        showSelf = true,
        showPets = true,
        petHeight = party and 18 or 13,
        petSpacing = 1,
        rangeIndicator = true,
        rangeFriendly = true,
        outOfRangeAlpha = 0.40,
        powerHeight = party and 5 or 3,
        healthColor = "Class",
        customHealthColor = { 0.10, 0.65, 0.32, 1 },
        healthBackground = { 0.025, 0.04, 0.055, 0.96 },
        healthOpacity = 0.92,
        powerOpacity = 1,
        borderSize = 1,
        hoverBorder = true,
        fontSize = party and 11 or 9,
        showName = true,
        showHealthPercent = true,
        showRole = true,
        showLeader = true,
        showRaidMarker = true,
        showReadyCheck = true,
        auras = { buff = AuraDefaults(true), debuff = AuraDefaults(false) },
        auraFilters = {
            mode = "Essential",
            maxIcons = party and 8 or 6,
            topLeftBuffs = "1243,1244,1245,2791,10937,10938,25389,48161,21562",
            topRightBuffs = "17,592,600,3747,6065,6066,10898,10899,10900,10901,25217,25218,48065,48066,139,6074,6075,6076,6077,6078,10927,10928,10929,25315,25221,25222,48067,48068,41635,194384,77489,774,8936,33763,48438,119611,124682,115175,974,61295,53563,156910,200025,364343,366155,367364,355941,376788",
            rightBuffs = "",
            bottomLeftDebuffs = "6788",
            showCrowdControl = true,
            centerDebuffs = "",
            showDispellable = true,
        },
    }
    profile.auras.buff.enabled = true
    profile.auras.buff.size = party and 16 or 12
    profile.auras.buff.perRow = party and 3 or 2
    profile.auras.buff.rows = 1
    profile.auras.buff.point = "Top Right"
    profile.auras.buff.relativePoint = "Top Right"
    profile.auras.buff.growthX = "Left"
    profile.auras.buff.x = -2
    profile.auras.buff.y = -2
    profile.auras.buff.showDuration = true
    profile.auras.buff.clickThrough = true
    profile.auras.buff.tooltip = false
    profile.auras.buff.mineOnly = true
    profile.auras.debuff.enabled = true
    profile.auras.debuff.size = party and 18 or 13
    profile.auras.debuff.perRow = party and 3 or 2
    profile.auras.debuff.rows = 1
    profile.auras.debuff.point = "Bottom Right"
    profile.auras.debuff.relativePoint = "Bottom Right"
    profile.auras.debuff.growthX = "Left"
    profile.auras.debuff.x = -2
    profile.auras.debuff.y = 2
    profile.auras.debuff.clickThrough = true
    profile.auras.debuff.tooltip = false
    return profile
end

local function ActionBarDefaults(vertical, maximum, iconSize)
    return {
        enabled = true, visibility = "Always", alpha = 1, scale = 1,
        iconSize = iconSize or 36, buttons = maximum or 12,
        rows = vertical and (maximum or 12) or 1, spacing = 2, vertical = vertical == true,
        showEmpty = true, clickThrough = false,
        borderSize = 1, borderColor = { 0.05, 0.35, 0.90, 1 },
        backgroundColor = { 0.015, 0.025, 0.045, 1 }, backgroundOpacity = 0.92,
        hotkeySize = 10, macroSize = 9, countSize = 11,
    }
end

local defaults = {
    profileVersion = 22,
    locked = true,
    scale = 1,
    global = {
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
        moverGrid = true,
        moverGridSize = 32,
        moverGridThickness = 1,
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
        selectedBar = "main",
        showHotkeys = true,
        showMacroText = true,
        bars = {
            main = ActionBarDefaults(false, 12, 36),
            bottomLeft = ActionBarDefaults(false, 12, 36),
            bottomRight = ActionBarDefaults(false, 12, 36),
            right = ActionBarDefaults(true, 12, 36),
            left = ActionBarDefaults(true, 12, 36),
            bar5 = ActionBarDefaults(false, 12, 36),
            bar6 = ActionBarDefaults(false, 12, 36),
            bar7 = ActionBarDefaults(false, 12, 36),
            pet = ActionBarDefaults(false, 10, 32),
            stance = ActionBarDefaults(false, 10, 30),
        },
    },
    nameplates = {
        width = 120,
        height = 10,
        castHeight = 7,
        fontSize = 11,
    },
    unitFrames = {
        scale = 1,
        selectedIndicator = "Raid Marker",
        selectedCastTab = "General",
        selectedAura = "Buffs",
        selectedAuraTab = "General",
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
                enabled = true,
                width = 181, healthHeight = 46, powerHeight = 6, powerPosition = "Below Health Bar",
                texture = "Global", healthColor = "Class", customHealthColor = { 0.10, 0.65, 0.32, 1 },
                healthBackground = { 0.067, 0.067, 0.067, 1 }, healthOpacity = 0.90,
                powerColor = "Power Type", customPowerColor = { 0.12, 0.38, 0.90, 1 },
                powerBackground = { 0.02, 0.03, 0.06, 1 }, powerOpacity = 1,
                leftText = "Name", rightText = "Health %", centerText = "None", extraText = "None",
                powerText = "None", textSize = 12, borderSize = 1, frameStrata = "MEDIUM",
                hoverBorder = true, showTooltip = true, visibility = "Always",
                showPortrait = true, portraitMode = "2D Portrait", portraitPosition = "Left", portraitSize = 46,
                showCastbar = false, castbarProvider = "Blizzard", castWidth = 229, castHeight = 14, castOpacity = 1, showCastIcon = true,
                castColor = { 0.86, 0.82, 0.64, 1 }, castBackground = { 0.025, 0.03, 0.045, 1 }, castBackgroundOpacity = 0.8,
                castTexture = "Global", castReverseFill = false, castDetached = false, castAttachTo = "Frame",
                castPoint = "Top Left", castRelativePoint = "Bottom Left", castX = 0, castY = -3, castFrameStrata = "MEDIUM",
                castNamePosition = "Left", castTimePosition = "Right", castIconPosition = "Left", castTextSize = 10, castTimeFormat = "Remaining",
                healPrediction = false, healPredictionMine = true, healPredictionOthers = true, healPredictionOpacity = 0.75,
                healPredictionMineColor = { 0.40, 0.95, 0.40, 1 }, healPredictionOtherColor = { 0.16, 0.67, 0.16, 1 },
                raidMarker = true, raidMarkerSize = 22,
                raidMarkerAttachTo = "Frame", raidMarkerPoint = "Center", raidMarkerRelativePoint = "Top", raidMarkerX = 0, raidMarkerY = 0,
                leaderIndicator = true, leaderIndicatorSize = 16,
                leaderIndicatorAttachTo = "Frame", leaderIndicatorPoint = "Center", leaderIndicatorRelativePoint = "Top Left", leaderIndicatorX = 0, leaderIndicatorY = 0,
                combatIndicator = true, combatIndicatorSize = 12,
                combatIndicatorAttachTo = "Frame", combatIndicatorPoint = "Center", combatIndicatorRelativePoint = "Top Right", combatIndicatorX = 0, combatIndicatorY = 0,
                auras = { buff = AuraDefaults(true), debuff = AuraDefaults(false) },
            },
            target = {
                enabled = true,
                width = 181, healthHeight = 46, powerHeight = 6, powerPosition = "Below Health Bar",
                texture = "Global", healthColor = "Class", customHealthColor = { 0.10, 0.65, 0.32, 1 },
                healthBackground = { 0.067, 0.067, 0.067, 1 }, healthOpacity = 0.90,
                powerColor = "Power Type", customPowerColor = { 0.12, 0.38, 0.90, 1 },
                powerBackground = { 0.02, 0.03, 0.06, 1 }, powerOpacity = 1,
                leftText = "Level + Name", rightText = "Health %", centerText = "None", extraText = "None",
                powerText = "None", textSize = 12, borderSize = 1, frameStrata = "MEDIUM",
                hoverBorder = true, showTooltip = true, visibility = "Always",
                showPortrait = true, portraitMode = "2D Portrait", portraitPosition = "Right", portraitSize = 46,
                showCastbar = true, castWidth = 229, castHeight = 14, castOpacity = 1, showCastIcon = true,
                castColor = { 0.86, 0.82, 0.64, 1 }, castBackground = { 0.025, 0.03, 0.045, 1 }, castBackgroundOpacity = 0.8,
                castTexture = "Global", castReverseFill = false, castDetached = false, castAttachTo = "Frame",
                castPoint = "Top Left", castRelativePoint = "Bottom Left", castX = 0, castY = -3, castFrameStrata = "MEDIUM",
                castNamePosition = "Left", castTimePosition = "Right", castIconPosition = "Left", castTextSize = 10, castTimeFormat = "Remaining",
                healPrediction = false, healPredictionMine = true, healPredictionOthers = true, healPredictionOpacity = 0.75,
                healPredictionMineColor = { 0.40, 0.95, 0.40, 1 }, healPredictionOtherColor = { 0.16, 0.67, 0.16, 1 },
                raidMarker = true, raidMarkerSize = 22,
                raidMarkerAttachTo = "Frame", raidMarkerPoint = "Center", raidMarkerRelativePoint = "Top", raidMarkerX = 0, raidMarkerY = 0,
                leaderIndicator = true, leaderIndicatorSize = 16,
                leaderIndicatorAttachTo = "Frame", leaderIndicatorPoint = "Center", leaderIndicatorRelativePoint = "Top Left", leaderIndicatorX = 0, leaderIndicatorY = 0,
                combatIndicator = false, combatIndicatorSize = 12,
                combatIndicatorAttachTo = "Frame", combatIndicatorPoint = "Center", combatIndicatorRelativePoint = "Top Right", combatIndicatorX = 0, combatIndicatorY = 0,
                auras = { buff = AuraDefaults(true), debuff = AuraDefaults(false) },
            },
            focus = {
                enabled = true,
                width = 160, healthHeight = 34, powerHeight = 6, powerPosition = "Below Health Bar",
                texture = "Global", healthColor = "Class", customHealthColor = { 0.10, 0.65, 0.32, 1 },
                healthBackground = { 0.067, 0.067, 0.067, 1 }, healthOpacity = 0.90,
                powerColor = "Power Type", customPowerColor = { 0.12, 0.38, 0.90, 1 },
                powerBackground = { 0.02, 0.03, 0.06, 1 }, powerOpacity = 1,
                leftText = "Name", rightText = "Health %", centerText = "None", extraText = "None",
                powerText = "None", textSize = 11, borderSize = 1, frameStrata = "MEDIUM",
                hoverBorder = true, showTooltip = true, visibility = "Always",
                showPortrait = false, portraitMode = "2D Portrait", portraitPosition = "Left", portraitSize = 34,
                showCastbar = true, castWidth = 160, castHeight = 12, castOpacity = 1, showCastIcon = true,
                castColor = { 0.86, 0.82, 0.64, 1 }, castBackground = { 0.025, 0.03, 0.045, 1 }, castBackgroundOpacity = 0.8,
                castTexture = "Global", castReverseFill = false, castDetached = false, castAttachTo = "Frame",
                castPoint = "Top Left", castRelativePoint = "Bottom Left", castX = 0, castY = -3, castFrameStrata = "MEDIUM",
                castNamePosition = "Left", castTimePosition = "Right", castIconPosition = "Left", castTextSize = 9, castTimeFormat = "Remaining",
                healPrediction = false, healPredictionMine = true, healPredictionOthers = true, healPredictionOpacity = 0.75,
                healPredictionMineColor = { 0.40, 0.95, 0.40, 1 }, healPredictionOtherColor = { 0.16, 0.67, 0.16, 1 },
                raidMarker = true, raidMarkerSize = 20,
                raidMarkerAttachTo = "Frame", raidMarkerPoint = "Center", raidMarkerRelativePoint = "Top", raidMarkerX = 0, raidMarkerY = 0,
                leaderIndicator = false, leaderIndicatorSize = 14,
                leaderIndicatorAttachTo = "Frame", leaderIndicatorPoint = "Center", leaderIndicatorRelativePoint = "Top Left", leaderIndicatorX = 0, leaderIndicatorY = 0,
                combatIndicator = false, combatIndicatorSize = 10,
                combatIndicatorAttachTo = "Frame", combatIndicatorPoint = "Center", combatIndicatorRelativePoint = "Top Right", combatIndicatorX = 0, combatIndicatorY = 0,
                auras = { buff = AuraDefaults(true), debuff = AuraDefaults(false) },
            },
        },
    },
    groupFrames = {
        selectedProfile = "Party",
        selectedTab = "General",
        preview = true,
        party = GroupProfileDefaults(true),
        raid = GroupProfileDefaults(false),
    },
    chat = {
        width = 470,
        height = 260,
        fontSize = 12,
        backgroundAlpha = 0.72,
        fade = true,
        timeVisible = 120,
        timestamps = true,
        copyButton = true,
        editBoxPosition = "Below",
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
        targettarget = { "CENTER", "CENTER", 500, -155 },
        targettargettarget = { "CENTER", "CENTER", 500, -205 },
        focus = { "CENTER", "CENTER", 280, -235 },
        pet = { "CENTER", "CENTER", -280, -220 },
        playerCastbar = { "CENTER", "CENTER", -280, -220 },
        petCastbar = { "CENTER", "CENTER", -280, -270 },
        targetCastbar = { "CENTER", "CENTER", 280, -220 },
        targettargetCastbar = { "CENTER", "CENTER", 500, -195 },
        targettargettargetCastbar = { "CENTER", "CENTER", 500, -245 },
        focusCastbar = { "CENTER", "CENTER", 280, -285 },
        party = { "LEFT", "LEFT", 42, 20 },
        raid = { "LEFT", "LEFT", 42, 20 },
        chat = { "BOTTOMLEFT", "BOTTOMLEFT", 28, 52 },
        dataPanel = { "BOTTOM", "BOTTOM", 0, 4 },
        dataPanel2 = { "TOP", "TOP", 0, -4 },
        settings = { "CENTER", "CENTER", 0, 0 },
    },
}

defaults.unitFrames.frames.targettarget = CloneDefaults(defaults.unitFrames.frames.focus)
defaults.unitFrames.frames.targettarget.width = 150
defaults.unitFrames.frames.targettarget.healthHeight = 30
defaults.unitFrames.frames.targettarget.leftText = "Name"
defaults.unitFrames.frames.targettarget.showCastbar = false
defaults.unitFrames.frames.targettarget.enabled = false
defaults.unitFrames.frames.targettargettarget = CloneDefaults(defaults.unitFrames.frames.targettarget)
defaults.unitFrames.frames.targettargettarget.width = 135
defaults.unitFrames.frames.targettargettarget.healthHeight = 26
defaults.unitFrames.frames.targettargettarget.textSize = 10
defaults.unitFrames.frames.pet = CloneDefaults(defaults.unitFrames.frames.focus)
defaults.unitFrames.frames.pet.enabled = true
defaults.unitFrames.frames.pet.width = 140
defaults.unitFrames.frames.pet.healthHeight = 30
defaults.unitFrames.frames.pet.powerHeight = 5
defaults.unitFrames.frames.pet.leftText = "Name"
defaults.unitFrames.frames.pet.rightText = "Health %"
defaults.unitFrames.frames.pet.showPortrait = false
defaults.unitFrames.frames.pet.showCastbar = false
defaults.unitFrames.frames.pet.healPrediction = false
defaults.unitFrames.frames.pet.leaderIndicator = false
defaults.unitFrames.frames.pet.combatIndicator = false
for unit, settings in pairs(defaults.unitFrames.frames) do
    settings.rangeIndicator = unit == "target"
    settings.rangeFriendly = unit == "target"
    settings.rangeHostile = unit == "target"
    settings.outOfRangeAlpha = 0.40
end

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

function FUI:ResolveGroupUnit(unit)
    if not unit or not UnitIsUnit then return nil end
    local candidates = { "player" }
    if IsInRaid and IsInRaid() then
        for index = 1, 40 do candidates[#candidates + 1] = "raid" .. index end
    else
        for index = 1, 4 do candidates[#candidates + 1] = "party" .. index end
    end
    for _, candidate in ipairs(candidates) do
        local ok, same = pcall(UnitIsUnit, unit, candidate)
        if ok and not (issecretvalue and issecretvalue(same)) and same == true then return candidate end
    end
    return nil
end

function FUI:IsGroupUnit(unit)
    return self:ResolveGroupUnit(unit) ~= nil
end

function FUI:IsUnitInConfiguredRange(unit, friendlyRange, hostileRange)
    if not unit or unit == "player" then return true end
    local attackOK, canAttack = false, false
    if UnitCanAttack then attackOK, canAttack = pcall(UnitCanAttack, "player", unit) end
    if hostileRange and attackOK and not (issecretvalue and issecretvalue(canAttack)) and canAttack == true and CheckInteractDistance then
        local ok, inRange = pcall(CheckInteractDistance, unit, 4)
        if ok and not (issecretvalue and issecretvalue(inRange)) then return inRange == true end
        return true
    end
    local assistOK, canAssist = false, false
    if UnitCanAssist then assistOK, canAssist = pcall(UnitCanAssist, "player", unit) end
    local groupUnit = friendlyRange and self:ResolveGroupUnit(unit)
    if groupUnit and assistOK and not (issecretvalue and issecretvalue(canAssist)) and canAssist == true and UnitInRange then
        local ok, inRange, checked = pcall(UnitInRange, groupUnit)
        if not ok or (issecretvalue and (issecretvalue(inRange) or issecretvalue(checked))) then return true end
        if checked == false then return true end
        return inRange == true
    end
    return true
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
    self:RegisterMover(frame, key)
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

function FUI:RegisterMover(frame, key, label, onMoved)
    if not frame or not key then return end
    local labels = {
        player = "Player Frame", pet = "Pet Frame", target = "Target Frame", focus = "Focus Frame",
        targettarget = "Target of Target", targettargettarget = "Target of Target of Target",
        playerCastbar = "Player Cast Bar", petCastbar = "Pet Cast Bar", targetCastbar = "Target Cast Bar", focusCastbar = "Focus Cast Bar",
        targettargetCastbar = "Target of Target Cast Bar", targettargettargetCastbar = "Target of Target of Target Cast Bar",
        party = "Party Frames", raid = "Raid Frames", chat = "Chat",
        dataPanel = "Primary Data Panel", dataPanel2 = "Second Data Panel",
    }
    self.movers[key] = { frame = frame, key = key, label = label or labels[key] or key, onMoved = onMoved }
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
    if previousVersion < 13 then
        local groupDB = self.db.groupFrames
        groupDB.party.scale = groupDB.partyScale or groupDB.party.scale
        groupDB.raid.scale = groupDB.raidScale or groupDB.raid.scale
        groupDB.party.width = groupDB.partyWidth or groupDB.party.width
        groupDB.party.height = groupDB.partyHeight or groupDB.party.height
        groupDB.raid.width = groupDB.raidWidth or groupDB.raid.width
        groupDB.raid.height = groupDB.raidHeight or groupDB.raid.height
        groupDB.party.fontSize = groupDB.fontSize or groupDB.party.fontSize
        groupDB.raid.fontSize = groupDB.fontSize or groupDB.raid.fontSize
    end
    if previousVersion < 15 then
        self.db.groupFrames.party.auras.buff.showDuration = true
        self.db.groupFrames.raid.auras.buff.showDuration = true
    end
    if previousVersion < 17 then
        self.db.groupFrames.party.auras.buff.mineOnly = true
        self.db.groupFrames.raid.auras.buff.mineOnly = true
    end
    if previousVersion < 21 then
        for _, settings in pairs(self.db.unitFrames.frames) do
            if settings.auras then
                settings.auras.buff.enabled = true
                settings.auras.buff.mineOnly = false
                settings.auras.debuff.enabled = true
                settings.auras.debuff.mineOnly = false
            end
        end
        for _, profile in pairs({ self.db.groupFrames.party, self.db.groupFrames.raid }) do
            profile.auras.buff.enabled = true
            profile.auras.buff.mineOnly = false
            profile.auras.debuff.enabled = true
            profile.auras.debuff.mineOnly = false
        end
    end
    if previousVersion < 22 then
        self.db.groupFrames.party.auras.buff.mineOnly = true
        self.db.groupFrames.raid.auras.buff.mineOnly = true
    end
    self.db.profileVersion = defaults.profileVersion

    self:DiscoverSharedMedia()
    self:ApplyGlobalSettings()
    for key, module in pairs(self.modules) do
        if self:IsModuleEnabled(key) and module.Initialize then
            self:SafeCall(key, module.Initialize, module)
        end
    end

    self.db.locked = true
    self:SetLocked(true)
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
        FUI:EnterUnlockMode()
    elseif message == "lock" then
        FUI:ExitUnlockMode(false)
    elseif message == "auradiag" and FUI.AuraEngine then
        FUI.AuraEngine:PrintDiagnostics()
    else
        FUI:OpenSettings()
    end
end

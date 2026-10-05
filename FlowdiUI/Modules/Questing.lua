local _, ns = ...
local FUI = ns.FUI

-- FlowdiUI owns the complete presentation and consumes QuestieDB only through
-- its documented public API. The Questie frontend is never required or read.
local module = {
    records = {}, availableByMap = {}, mapPins = {}, minimapPins = {}, objectiveState = {},
    nativeCache = {}, providerState = "waiting",
}
FUI:RegisterModule("questing", module)

local PIN_TEXTURES = {
    slay = "Interface\\AddOns\\FlowdiUI\\Media\\QuestPins\\slay_mono.tga",
    loot = "Interface\\AddOns\\FlowdiUI\\Media\\QuestPins\\loot_mono.tga",
    object = "Interface\\AddOns\\FlowdiUI\\Media\\QuestPins\\object_mono.tga",
    event = "Interface\\AddOns\\FlowdiUI\\Media\\QuestPins\\object_mono.tga",
}

local PIN_GLYPHS = {
    available = "!", turnin = "?",
}

local function PublicNumber(value)
    if issecretvalue and issecretvalue(value) then return nil end
    local ok, number = pcall(tonumber, value)
    return ok and number or nil
end

local function GetQuestLevel(questID, info)
    local level = info and (info.level or info.difficultyLevel)
    if not level and C_QuestLog and C_QuestLog.GetQuestDifficultyLevel then
        local ok, result = pcall(C_QuestLog.GetQuestDifficultyLevel, questID)
        if ok then level = result end
    end
    if not level and C_QuestLog and C_QuestLog.GetLogIndexForQuestID and GetQuestLogTitle then
        local index = C_QuestLog.GetLogIndexForQuestID(questID)
        if index and index > 0 then
            local _, legacyLevel = GetQuestLogTitle(index)
            level = legacyLevel
        end
    end
    return PublicNumber(level) or 0
end

local function QuestDifficultyColor(questLevel)
    local playerLevel = PublicNumber(UnitLevel("player")) or 1
    questLevel = PublicNumber(questLevel) or 0
    if questLevel <= 0 then return 1, .82, .10 end
    if questLevel < playerLevel then return .30, .86, .22 end
    if questLevel <= playerLevel + 2 then return 1, .82, .10 end
    if questLevel <= playerLevel + 4 then return 1, .42, .08 end
    return 1, .12, .08
end

local function Decode(source)
    if type(source) == "table" then return source end
    if type(source) ~= "string" or not loadstring then return {} end
    local chunk = loadstring(source, "=FlowdiUI.QuestieDB")
    if not chunk then return {} end
    local ok, value = pcall(chunk)
    return ok and type(value) == "table" and value or {}
end

function module:PrepareProvider()
    if type(LibQuestieDB) ~= "table" then
        self.provider, self.providerState = nil, "missing"
        return false
    end
    local compatible = LibQuestieDB.RequireContract and LibQuestieDB.RequireContract(2)
    if compatible == false then
        self.provider, self.providerState = nil, "incompatible"
        return false
    end
    self.provider, self.providerState = LibQuestieDB, "ready"
    local zones = LibQuestieDB.Support and LibQuestieDB.Support.Get and LibQuestieDB.Support.Get("ZoneDB")
    local private = zones and zones.private or {}
    self.areaToMap = Decode(private.areaIdToUiMapId)
    for areaID, mapID in pairs(Decode(private.areaIdToUiMapIdOverride)) do self.areaToMap[areaID] = mapID end
    return true
end

local function NormalizeCoordinate(value)
    value = PublicNumber(value)
    if not value then return nil end
    if value > 1 then value = value / 100 end
    if value < 0 or value > 1 then return nil end
    return value
end

local function GetQuestObjectives(questID)
    if C_QuestLog and C_QuestLog.GetQuestObjectives then
        local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, questID)
        if ok and type(objectives) == "table" then return objectives end
    end
    local index = C_QuestLog and C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questID)
    local result = {}
    if index and index > 0 and GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
        for objectiveIndex = 1, GetNumQuestLeaderBoards(index) do
            local text, objectiveType, finished = GetQuestLogLeaderBoard(objectiveIndex, index)
            result[#result + 1] = { text = text, type = objectiveType, finished = finished }
        end
    end
    return result
end

local function QuestReadyForTurnIn(questID)
    if C_QuestLog and C_QuestLog.ReadyForTurnIn then
        local ok, ready = pcall(C_QuestLog.ReadyForTurnIn, questID)
        if ok then return ready and true or false end
    end
    local objectives = GetQuestObjectives(questID)
    if #objectives == 0 then return false end
    for _, objective in ipairs(objectives) do
        if not objective.finished then return false end
    end
    return true
end

local function QuestCompleted(questID)
    local checker = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted or IsQuestFlaggedCompleted
    if not checker then return false end
    local ok, completed = pcall(checker, questID)
    return ok and completed and true or false
end

local function ObjectiveType(objective)
    if not objective then return "event" end
    local kind = tostring(objective.type or ""):lower()
    local text = tostring(objective.text or ""):lower()
    if kind:find("monster") or kind:find("kill") or text:find(" slain") or text:find(" killed") then return "slay" end
    if kind:find("item") or kind:find("loot") or text:find("collect") or text:find("gather") then return "loot" end
    if kind:find("object") or kind:find("interact") then return "object" end
    return "event"
end

local function FirstIncompleteObjective(questID)
    local objectives = GetQuestObjectives(questID)
    for _, objective in ipairs(objectives) do
        if not objective.finished then return objective end
    end
    return objectives[1]
end

local function ObjectiveSignature(questID)
    local parts = {}
    for index, objective in ipairs(GetQuestObjectives(questID)) do
        parts[index] = table.concat({
            tostring(objective.text or ""), tostring(objective.numFulfilled or ""),
            tostring(objective.numRequired or ""), tostring(objective.finished and 1 or 0),
        }, ":")
    end
    return table.concat(parts, "|")
end

local function AddQuestProgress(tooltip, questID, r, g, b)
    for _, objective in ipairs(GetQuestObjectives(questID)) do
        local current = PublicNumber(objective.numFulfilled)
        local required = PublicNumber(objective.numRequired)
        local text = objective.text
        if current and required and (not text or not text:match("%d+%s*/%s*%d+")) then
            text = string.format("%d/%d %s", current, required, text or "")
        end
        if text and text ~= "" then
            tooltip:AddLine(text, r or 1, g or .82, b or .10, true)
        end
    end
end

function module:GetTrackedQuests()
    local result = {}
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        for index = 1, C_QuestLog.GetNumQuestLogEntries() do
            local info = C_QuestLog.GetInfo(index)
            if info and not info.isHeader and info.questID and info.questID > 0 then
                local watched = true
                if C_QuestLog.GetQuestWatchType then watched = C_QuestLog.GetQuestWatchType(info.questID) ~= nil end
                if watched then
                    result[#result + 1] = {
                        id = info.questID,
                        title = info.title or (C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(info.questID)),
                        level = GetQuestLevel(info.questID, info),
                    }
                end
            end
        end
    elseif GetNumQuestLogEntries and GetQuestLogTitle then
        for index = 1, GetNumQuestLogEntries() do
            local title, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(index)
            if not isHeader and questID and (not IsQuestWatched or IsQuestWatched(index)) then
                result[#result + 1] = { id = questID, title = title, level = GetQuestLevel(questID) }
            end
        end
    end
    return result
end

function module:GetActiveQuestSet()
    local active = {}
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        for index = 1, C_QuestLog.GetNumQuestLogEntries() do
            local info = C_QuestLog.GetInfo(index)
            if info and not info.isHeader and info.questID then active[info.questID] = true end
        end
    end
    return active
end

local function MaskContains(mask, flag)
    mask, flag = PublicNumber(mask), PublicNumber(flag)
    if not mask or mask == 0 or not flag or flag == 0 then return true end
    return math.floor(mask / flag) % 2 >= 1
end

function module:IsQuestAvailable(questID, active)
    if active[questID] or QuestCompleted(questID) then return false end
    local db = self.provider
    local playerLevel = PublicNumber(UnitLevel("player")) or 1
    local requiredLevel = PublicNumber(db.Quest.Get(questID, "requiredLevel")) or 0
    local maximumLevel = PublicNumber(db.Quest.Get(questID, "requiredMaxLevel")) or 0
    if playerLevel < requiredLevel or (maximumLevel > 0 and playerLevel > maximumLevel) then return false end
    local _, _, raceID = UnitRace("player")
    local _, _, classID = UnitClass("player")
    local raceFlags = db.Enum and db.Enum.raceMaskById
    local raceFlag = raceFlags and raceFlags[raceID] or raceID and 2 ^ (raceID - 1)
    local classFlag = classID and 2 ^ (classID - 1)
    if not MaskContains(db.Quest.Get(questID, "requiredRaces"), raceFlag) then return false end
    if not MaskContains(db.Quest.Get(questID, "requiredClasses"), classFlag) then return false end
    for _, prerequisite in ipairs(db.Quest.Get(questID, "preQuestGroup") or {}) do
        if not QuestCompleted(prerequisite) then return false end
    end
    local alternatives = db.Quest.Get(questID, "preQuestSingle") or {}
    if #alternatives > 0 then
        local met = false
        for _, prerequisite in ipairs(alternatives) do if QuestCompleted(prerequisite) then met = true break end end
        if not met then return false end
    end
    local blocker = PublicNumber(db.Quest.Get(questID, "availableUntilCompleted")) or 0
    if blocker > 0 and QuestCompleted(blocker) then return false end
    local starter = PublicNumber(db.Quest.Get(questID, "availableStartingWith")) or 0
    if starter > 0 and not active[starter] and not QuestCompleted(starter) then return false end
    return true
end

local function AddSpawn(records, seen, quest, objective, iconType, areaID, coordinates)
    local mapID = module.areaToMap and module.areaToMap[areaID]
    if not mapID or mapID == 0 or type(coordinates) ~= "table" then return end
    for _, coordinate in ipairs(coordinates) do
        local x, y = PublicNumber(coordinate[1]), PublicNumber(coordinate[2])
        if x and y and x >= 0 and y >= 0 then
            local key = table.concat({ quest.id, iconType, mapID, string.format("%.3f", x), string.format("%.3f", y) }, ":")
            if not seen[key] then
                seen[key] = true
                records[#records + 1] = {
                    questID = quest.id, title = quest.title or ("Quest " .. quest.id), questLevel = quest.level,
                    objective = objective, iconType = iconType, mapID = mapID, x = x / 100, y = y / 100,
                }
            end
        end
    end
end

local function AddSpawnList(records, seen, quest, objective, iconType, spawns)
    if type(spawns) ~= "table" then return end
    for areaID, coordinates in pairs(spawns) do AddSpawn(records, seen, quest, objective, iconType, areaID, coordinates) end
end

function module:AddNpc(records, seen, quest, objective, iconType, npcID)
    if not npcID then return end
    local name = self.provider.Npc.Get(npcID, "name")
    AddSpawnList(records, seen, quest, objective or name, iconType, self.provider.Npc.Get(npcID, "spawns"))
end

function module:AddObject(records, seen, quest, objective, iconType, objectID)
    if not objectID then return end
    local name = self.provider.Object.Get(objectID, "name")
    AddSpawnList(records, seen, quest, objective or name, iconType, self.provider.Object.Get(objectID, "spawns"))
end

function module:AddItem(records, seen, quest, objective, itemID)
    if not itemID then return end
    local itemName = self.provider.Item.Get(itemID, "name")
    for _, npcID in ipairs(self.provider.Item.Get(itemID, "npcDrops") or {}) do
        self:AddNpc(records, seen, quest, objective or itemName, "loot", npcID)
    end
    for _, objectID in ipairs(self.provider.Item.Get(itemID, "objectDrops") or {}) do
        self:AddObject(records, seen, quest, objective or itemName, "loot", objectID)
    end
end

function module:GetAvailableQuestRecords(mapID)
    if not FUI.db.questing.showQuestGivers or self.providerState ~= "ready" then return {} end
    if self.availableByMap[mapID] then return self.availableByMap[mapID] end
    local records, candidates, seen = {}, {}, {}
    local db, active = self.provider, self:GetActiveQuestSet()
    for _, questID in ipairs(db.Quest.GetAllIds() or {}) do
        local areaID = PublicNumber(db.Quest.Get(questID, "zoneOrSort")) or 0
        if areaID > 0 and self.areaToMap[areaID] == mapID and self:IsQuestAvailable(questID, active) then
            local quest = {
                id = questID,
                title = db.Quest.Get(questID, "name"),
                level = PublicNumber(db.Quest.Get(questID, "questLevel")) or 0,
            }
            local starters = db.Quest.Get(questID, "startedBy") or {}
            for _, npcID in ipairs(starters[1] or {}) do self:AddNpc(candidates, seen, quest, "Quest available", "available", npcID) end
            for _, objectID in ipairs(starters[2] or {}) do self:AddObject(candidates, seen, quest, "Quest available", "available", objectID) end
        end
    end
    for _, record in ipairs(candidates) do if record.mapID == mapID then records[#records + 1] = record end end
    self.availableByMap[mapID] = records
    return records
end

function module:GetPlayerLocation()
    if not C_Map or not C_Map.GetBestMapForUnit or not C_Map.GetPlayerMapPosition then return end
    local mapID = C_Map.GetBestMapForUnit("player")
    local position = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
    if not position then return end
    local x, y = position:GetXY()
    x, y = NormalizeCoordinate(x), NormalizeCoordinate(y)
    if mapID and x and y and (x > 0 or y > 0) then return mapID, x, y end
end

function module:SaveLearnedLocation(questID, iconType, objective, title)
    if not FUI.db.questing.learningEnabled or not questID then return end
    local mapID, x, y = self:GetPlayerLocation()
    if not mapID then return end
    local learned = FUI.db.questing.learned
    learned[questID] = learned[questID] or {}
    for _, record in ipairs(learned[questID]) do
        if record.mapID == mapID and record.iconType == iconType and math.abs(record.x - x) < .012 and math.abs(record.y - y) < .012 then
            record.objective, record.title = objective or record.objective, title or record.title
            record.questLevel = GetQuestLevel(questID)
            return
        end
    end
    learned[questID][#learned[questID] + 1] = {
        mapID = mapID, x = x, y = y, iconType = iconType,
        objective = objective, title = title, questLevel = GetQuestLevel(questID), learnedAt = time and time() or 0,
    }
    while #learned[questID] > 80 do table.remove(learned[questID], 1) end
end

function module:LearnObjectiveChanges()
    for _, quest in ipairs(self:GetTrackedQuests()) do
        local signature = ObjectiveSignature(quest.id)
        local previous = self.objectiveState[quest.id]
        if previous and previous ~= signature then
            local objective = FirstIncompleteObjective(quest.id)
            self:SaveLearnedLocation(quest.id, ObjectiveType(objective), objective and objective.text, quest.title)
        end
        self.objectiveState[quest.id] = signature
    end
end

local function AddRecord(records, seen, record)
    local x, y = NormalizeCoordinate(record.x), NormalizeCoordinate(record.y)
    local mapID, questID = PublicNumber(record.mapID), PublicNumber(record.questID)
    if not x or not y or not mapID or not questID then return end
    local key = table.concat({ questID, record.iconType or "event", mapID, math.floor(x * 10000), math.floor(y * 10000) }, ":")
    if seen[key] then return end
    seen[key] = true
    record.x, record.y, record.mapID, record.questID = x, y, mapID, questID
    records[#records + 1] = record
end

function module:BuildRecords()
    self.records, self.availableByMap, self.nativeCache = {}, {}, {}
    local seen = {}
    if self.providerState == "ready" then
        local db = self.provider
        for _, quest in ipairs(self:GetTrackedQuests()) do
            if not quest.level or quest.level <= 0 then quest.level = PublicNumber(db.Quest.Get(quest.id, "questLevel")) or 0 end
            local objectives = db.Quest.Get(quest.id, "objectives") or {}
            if FUI.db.questing.showObjectives then
                for _, row in ipairs(objectives[1] or {}) do self:AddNpc(self.records, seen, quest, row[2], "slay", row[1]) end
                for _, row in ipairs(objectives[2] or {}) do self:AddObject(self.records, seen, quest, row[2], "object", row[1]) end
                for _, row in ipairs(objectives[3] or {}) do self:AddItem(self.records, seen, quest, row[2], row[1]) end
                for _, row in ipairs(objectives[5] or {}) do
                    for _, npcID in ipairs(row[1] or {}) do self:AddNpc(self.records, seen, quest, row[3], "slay", npcID) end
                end
                local trigger = db.Quest.Get(quest.id, "triggerEnd")
                if trigger then AddSpawnList(self.records, seen, quest, trigger[1], "event", trigger[2]) end
                for _, extra in ipairs(db.Quest.Get(quest.id, "extraObjectives") or {}) do
                    AddSpawnList(self.records, seen, quest, extra[3], "event", extra[1])
                end
            end
            if FUI.db.questing.showTurnIns and QuestReadyForTurnIn(quest.id) then
                local finishers = db.Quest.Get(quest.id, "finishedBy") or {}
                for _, npcID in ipairs(finishers[1] or {}) do self:AddNpc(self.records, seen, quest, "Quest turn-in", "turnin", npcID) end
                for _, objectID in ipairs(finishers[2] or {}) do self:AddObject(self.records, seen, quest, "Quest turn-in", "turnin", objectID) end
            end
        end
        return
    end
    local tracked = {}
    for _, quest in ipairs(self:GetTrackedQuests()) do tracked[quest.id] = quest end
    for questID, locations in pairs(FUI.db.questing.learned or {}) do
        local quest = tracked[questID]
        if quest and type(locations) == "table" then
            for _, location in ipairs(locations) do
                local show = (location.iconType == "turnin" and FUI.db.questing.showTurnIns and QuestReadyForTurnIn(questID))
                    or (location.iconType ~= "turnin" and location.iconType ~= "available" and FUI.db.questing.showObjectives)
                if show then
                    AddRecord(self.records, seen, {
                        questID = questID, title = quest.title or location.title, objective = location.objective,
                        iconType = location.iconType or "event", questLevel = quest.level or location.questLevel,
                        mapID = location.mapID, x = location.x, y = location.y,
                    })
                end
            end
        end
    end
end

local function ExtractMapPosition(info)
    if type(info) ~= "table" then return end
    local x, y = info.x, info.y
    local position = info.position or info.poiPosition
    if position and position.GetXY then x, y = position:GetXY() end
    return NormalizeCoordinate(x), NormalizeCoordinate(y)
end

function module:GetNativeRecords(mapID)
    if self.nativeCache[mapID] then return self.nativeCache[mapID] end
    local records, seen, tracked = {}, {}, {}
    for _, quest in ipairs(self:GetTrackedQuests()) do tracked[quest.id] = quest end
    if C_QuestLog and C_QuestLog.GetQuestsOnMap then
        local ok, quests = pcall(C_QuestLog.GetQuestsOnMap, mapID)
        if ok and type(quests) == "table" then
            for _, info in ipairs(quests) do
                local questID = PublicNumber(info.questID or info.questId)
                local quest = questID and tracked[questID]
                local x, y = ExtractMapPosition(info)
                if quest and x and y then
                    local objective = FirstIncompleteObjective(questID)
                    local ready = QuestReadyForTurnIn(questID)
                    if (ready and FUI.db.questing.showTurnIns) or (not ready and FUI.db.questing.showObjectives) then
                        AddRecord(records, seen, {
                            questID = questID, title = quest.title, objective = objective and objective.text,
                            iconType = ready and "turnin" or ObjectiveType(objective), questLevel = quest.level,
                            mapID = mapID, x = x, y = y,
                        })
                    end
                end
            end
        end
    end
    if C_QuestLog and C_QuestLog.GetNextWaypoint then
        for questID, quest in pairs(tracked) do
            local ok, waypointMap, x, y = pcall(C_QuestLog.GetNextWaypoint, questID)
            waypointMap = ok and PublicNumber(waypointMap) or nil
            x, y = NormalizeCoordinate(x), NormalizeCoordinate(y)
            if waypointMap == mapID and x and y then
                local objective = FirstIncompleteObjective(questID)
                local ready = QuestReadyForTurnIn(questID)
                if (ready and FUI.db.questing.showTurnIns) or (not ready and FUI.db.questing.showObjectives) then
                    AddRecord(records, seen, {
                        questID = questID, title = quest.title, objective = objective and objective.text,
                        iconType = ready and "turnin" or ObjectiveType(objective), questLevel = quest.level,
                        mapID = mapID, x = x, y = y,
                    })
                end
            end
        end
    end
    self.nativeCache[mapID] = records
    return records
end

function module:GetLearnedQuestGivers(mapID)
    if not FUI.db.questing.showQuestGivers then return {} end
    local records, active, seen = {}, self:GetActiveQuestSet(), {}
    for questID, locations in pairs(FUI.db.questing.learned or {}) do
        if not active[questID] and not QuestCompleted(questID) then
            for _, location in ipairs(locations) do
                if location.iconType == "available" and location.mapID == mapID then
                    AddRecord(records, seen, {
                        questID = questID, title = location.title, objective = "Quest available", iconType = "available",
                        questLevel = location.questLevel,
                        mapID = location.mapID, x = location.x, y = location.y,
                    })
                end
            end
        end
    end
    return records
end

function module:GetRecordsForMap(mapID)
    local records = {}
    for _, record in ipairs(self.records) do if record.mapID == mapID then records[#records + 1] = record end end
    if self.providerState == "ready" then
        for _, record in ipairs(self:GetAvailableQuestRecords(mapID)) do records[#records + 1] = record end
        return records
    end
    for _, record in ipairs(self:GetNativeRecords(mapID)) do records[#records + 1] = record end
    for _, record in ipairs(self:GetLearnedQuestGivers(mapID)) do records[#records + 1] = record end
    return records
end

local function StylePin(pin, mini)
    if pin.styled then return end
    pin.styled = true
    pin:SetSize(mini and 8 or 10, mini and 8 or 10)
    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetAllPoints()
    pin.symbolBackground = pin:CreateTexture(nil, "ARTWORK")
    pin.symbolBackground:SetPoint("CENTER")
    pin.symbolBackground:SetSize(mini and 7 or 9, mini and 7 or 9)
    pin.symbolBackground:SetTexture(FUI.textures.Flat)
    if pin.symbolBackground.SetRotation then pin.symbolBackground:SetRotation(math.pi / 4) end
    pin.glyph = FUI:CreateFont(pin, mini and 7 or 8)
    pin.glyph:SetPoint("CENTER", 0, 0)
    pin.glyph:SetTextColor(1, 1, 1)
    pin:EnableMouse(not mini)
    if not mini then
        pin:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local r, g, b = QuestDifficultyColor(self.data.questLevel)
            local level = PublicNumber(self.data.questLevel) or 0
            local title = self.data.title or "Quest"
            if level > 0 then title = string.format("[%d] %s", level, title) end
            GameTooltip:SetText(title, r, g, b)
            if self.data.objective and (self.data.iconType == "available" or self.data.iconType == "turnin" or self.data.iconType == "event") then
                GameTooltip:AddLine(self.data.objective, r, g, b, true)
            end
            AddQuestProgress(GameTooltip, self.data.questID, r, g, b)
            GameTooltip:AddLine("Flowdi Quest Atlas", .35, .7, 1)
            GameTooltip:Show()
        end)
        pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
end

local function ApplyPin(pin, record)
    pin.data = record
    local r, g, b = QuestDifficultyColor(record.questLevel)
    local texture = PIN_TEXTURES[record.iconType]
    if texture then
        pin.icon:SetTexture(texture)
        pin.icon:SetVertexColor(r, g, b, 1)
        pin.icon:Show()
        pin.symbolBackground:Hide()
        pin.glyph:SetText("")
    else
        pin.icon:Hide()
        pin.symbolBackground:SetVertexColor(r, g, b, 1)
        pin.symbolBackground:Show()
        pin.glyph:SetText(PIN_GLYPHS[record.iconType] or "*")
    end
end

function module:AcquireMapPin(index)
    if not self.mapPins[index] then
        self.mapPins[index] = CreateFrame("Button", nil, WorldMapFrame.ScrollContainer.Child)
        StylePin(self.mapPins[index], false)
    end
    self.mapPins[index]:SetParent(WorldMapFrame.ScrollContainer.Child)
    return self.mapPins[index]
end

function module:RefreshWorldMap()
    if not WorldMapFrame or not WorldMapFrame.ScrollContainer or not WorldMapFrame.ScrollContainer.Child then return end
    local mapID = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
    local child = WorldMapFrame.ScrollContainer.Child
    local width, height = child:GetWidth(), child:GetHeight()
    if not mapID or not width or width <= 1 or not height or height <= 1 then return end
    local used = 0
    if FUI.db.questing.enabled and FUI.db.questing.worldMapIcons then
        for _, record in ipairs(self:GetRecordsForMap(mapID)) do
            -- AddSpawn already removes byte-identical database rows. Do not
            -- merge nearby coordinates: each remaining row describes a real
            -- part of the objective's distribution on the map.
            used = used + 1
            local pin = self:AcquireMapPin(used)
            ApplyPin(pin, record)
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", child, "TOPLEFT", record.x * width, -record.y * height)
            pin:SetFrameLevel(child:GetFrameLevel() + 2100)
            pin:Show()
        end
    end
    for index = used + 1, #self.mapPins do self.mapPins[index]:Hide() end
end

function module:AcquireMinimapPin(index)
    if not self.minimapPins[index] then
        self.minimapPins[index] = CreateFrame("Frame", nil, Minimap)
        StylePin(self.minimapPins[index], true)
        self.minimapPins[index]:SetFrameLevel(Minimap:GetFrameLevel() + 12)
    end
    return self.minimapPins[index]
end

function module:RefreshMinimap()
    if not Minimap then return end
    local enabled = FUI.db.questing.enabled and FUI.db.questing.minimapIcons
    local mapID = enabled and C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local player = mapID and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID, "player")
    local px, py = player and player:GetXY()
    px, py = NormalizeCoordinate(px), NormalizeCoordinate(py)
    local radiusByZoom = { 466.7, 400, 333.3, 266.7, 200, 133.3 }
    local radius = radiusByZoom[(Minimap:GetZoom() or 0) + 1] or 200
    local halfW, halfH = Minimap:GetWidth() / 2, Minimap:GetHeight() / 2
    local used = 0
    if mapID and px and py and C_Map.GetWorldPosFromMapPos then
        local _, playerWorld = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(px, py))
        local pwx, pwy = playerWorld and playerWorld:GetXY()
        if pwx and pwy then
            for _, record in ipairs(self:GetRecordsForMap(mapID)) do
                local _, world = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(record.x, record.y))
                local wx, wy = world and world:GetXY()
                if wx and wy then
                    local dx, dy = wx - pwx, wy - pwy
                    if math.abs(dx) <= radius and math.abs(dy) <= radius then
                        used = used + 1
                        local pin = self:AcquireMinimapPin(used)
                        ApplyPin(pin, record)
                        pin:ClearAllPoints()
                        pin:SetPoint("CENTER", Minimap, "CENTER", dx / radius * halfW, -dy / radius * halfH)
                        pin:Show()
                    end
                end
            end
        end
    end
    for index = used + 1, #self.minimapPins do self.minimapPins[index]:Hide() end
end

function module:Refresh()
    self:BuildRecords()
    self:RefreshWorldMap()
    self:RefreshMinimap()
end

function module:HookWorldMap()
    if not WorldMapFrame or WorldMapFrame.FlowdiQuestPinsHooked then return end
    WorldMapFrame.FlowdiQuestPinsHooked = true
    WorldMapFrame:HookScript("OnShow", function() C_Timer.After(0, function() module:RefreshWorldMap() end) end)
    if WorldMapFrame.OnMapChanged then hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
        module.nativeCache = {}
        module:RefreshWorldMap()
    end) end
end

function module:Apply()
    if self.providerState ~= "ready" then self:PrepareProvider() end
    local utility = FUI.modules.utilityFrames
    local holder = utility and utility.trackerHolder
    if holder then holder:SetShown(FUI.db.questing.enabled and FUI.db.utilityFrames.objectiveTracker.enabled) end
    if utility and utility.ApplyTracker then utility:ApplyTracker() end
    self:Refresh()
end

function module:Initialize()
    self:PrepareProvider()
    self:HookWorldMap()
    self:LearnObjectiveChanges()
    local events = CreateFrame("Frame")
    for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "QUEST_LOG_UPDATE", "QUEST_WATCH_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "ZONE_CHANGED_NEW_AREA" }) do
        pcall(events.RegisterEvent, events, event)
    end
    events:SetScript("OnEvent", function(_, event, arg1, arg2)
        if event == "QUEST_ACCEPTED" then
            local questID = PublicNumber(arg2) or PublicNumber(arg1)
            local title = questID and C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)
            module:SaveLearnedLocation(questID, "available", "Quest available", title)
        elseif event == "QUEST_TURNED_IN" then
            local questID = PublicNumber(arg1)
            local title = questID and C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(questID)
            module:SaveLearnedLocation(questID, "turnin", "Quest turn-in", title)
        elseif event == "QUEST_LOG_UPDATE" or event == "QUEST_WATCH_UPDATE" then
            module:LearnObjectiveChanges()
        end
        module:HookWorldMap()
        module.refreshPending = true
        C_Timer.After(.25, function()
            if module.refreshPending then module.refreshPending = false module:Refresh() end
        end)
    end)
    events:SetScript("OnUpdate", function(_, elapsed)
        module.miniElapsed = (module.miniElapsed or 0) + elapsed
        if module.miniElapsed >= .20 then module.miniElapsed = 0 module:RefreshMinimap() end
    end)
    self.events = events
    self:Apply()
end

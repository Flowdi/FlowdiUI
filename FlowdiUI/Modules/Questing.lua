local _, ns = ...
local FUI = ns.FUI

-- QuestieDB is a provider with a public consumer API. FlowdiUI reads that API
-- directly and owns every frame below; the Questie frontend is neither loaded
-- nor required.
local module = { records = {}, mapPins = {}, minimapPins = {}, pinPool = {}, miniPool = {} }
FUI:RegisterModule("questing", module)

local ICONS = {
    slay = "Interface\\Icons\\INV_Sword_04",
    loot = "Interface\\Icons\\INV_Misc_Bag_10",
    object = "Interface\\Icons\\INV_Misc_Gear_01",
    turnin = "Interface\\Icons\\INV_Misc_QuestionMark",
    event = "Interface\\Icons\\INV_Misc_Note_01",
}

local function AddonExists(name)
    if C_AddOns and C_AddOns.DoesAddOnExist then return C_AddOns.DoesAddOnExist(name) end
    return GetAddOnInfo and GetAddOnInfo(name) ~= nil
end

local function IsLoaded(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded(name) end
    return IsAddOnLoaded and IsAddOnLoaded(name)
end

local function Enable(name, enabled)
    if C_AddOns then
        if enabled and C_AddOns.EnableAddOn then pcall(C_AddOns.EnableAddOn, name)
        elseif not enabled and C_AddOns.DisableAddOn then pcall(C_AddOns.DisableAddOn, name) end
    elseif enabled and EnableAddOn then pcall(EnableAddOn, name)
    elseif not enabled and DisableAddOn then pcall(DisableAddOn, name) end
end

local function Load(name)
    if IsLoaded(name) then return true end
    local loader = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
    if not loader then return false end
    local ok, loaded = pcall(loader, name)
    return ok and loaded ~= false
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
    -- Undo the old integration's activation of Questie. Removing Questie from
    -- OptionalDeps means FlowdiUI now loads first and can keep it disabled.
    if AddonExists("Questie") then Enable("Questie", false) end
    if not AddonExists("QuestieDB") then self.providerState = "missing" return false end
    Enable("QuestieDB", true)
    if not Load("QuestieDB") or type(LibQuestieDB) ~= "table" then
        self.providerState = "reload"
        return false
    end
    local ok = LibQuestieDB.RequireContract and LibQuestieDB.RequireContract(2)
    if ok == false then self.providerState = "incompatible" return false end
    self.providerState = "ready"
    self.provider = LibQuestieDB
    local zones = LibQuestieDB.Support and LibQuestieDB.Support.Get and LibQuestieDB.Support.Get("ZoneDB")
    local private = zones and zones.private or {}
    self.areaToMap = Decode(private.areaIdToUiMapId)
    for area, mapID in pairs(Decode(private.areaIdToUiMapIdOverride)) do self.areaToMap[area] = mapID end
    return true
end

function module:GetTrackedQuests()
    local result = {}
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        local count = C_QuestLog.GetNumQuestLogEntries()
        for index = 1, count do
            local info = C_QuestLog.GetInfo(index)
            if info and not info.isHeader and info.questID and info.questID > 0 then
                local watched = true
                if C_QuestLog.GetQuestWatchType then watched = C_QuestLog.GetQuestWatchType(info.questID) ~= nil end
                if watched then result[#result + 1] = { id = info.questID, title = info.title or (C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(info.questID)) } end
            end
        end
    elseif GetNumQuestLogEntries and GetQuestLogTitle then
        local count = GetNumQuestLogEntries()
        for index = 1, count do
            local title, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(index)
            if not isHeader and questID and (not IsQuestWatched or IsQuestWatched(index)) then
                result[#result + 1] = { id = questID, title = title }
            end
        end
    end
    return result
end

local function AddSpawn(records, seen, questID, title, objective, iconType, areaID, coords)
    local mapID = module.areaToMap and module.areaToMap[areaID]
    if not mapID or mapID == 0 or type(coords) ~= "table" then return end
    for _, coord in ipairs(coords) do
        local x, y = tonumber(coord[1]), tonumber(coord[2])
        if x and y and x >= 0 and y >= 0 then
            local key = table.concat({ questID, iconType, mapID, string.format("%.2f", x), string.format("%.2f", y) }, ":")
            if not seen[key] then
                seen[key] = true
                records[#records + 1] = {
                    questID = questID, title = title or ("Quest " .. questID), objective = objective,
                    iconType = iconType, texture = ICONS[iconType] or ICONS.event,
                    mapID = mapID, x = x / 100, y = y / 100,
                }
            end
        end
    end
end

local function AddSpawnList(records, seen, questID, title, objective, iconType, spawns)
    if type(spawns) ~= "table" then return end
    for areaID, coords in pairs(spawns) do AddSpawn(records, seen, questID, title, objective, iconType, areaID, coords) end
end

function module:AddNpc(records, seen, quest, objective, iconType, npcID)
    if not npcID then return end
    local db = self.provider
    local name = db.Npc.Get(npcID, "name")
    AddSpawnList(records, seen, quest.id, quest.title, objective or name, iconType, db.Npc.Get(npcID, "spawns"))
end

function module:AddObject(records, seen, quest, objective, iconType, objectID)
    if not objectID then return end
    local db = self.provider
    local name = db.Object.Get(objectID, "name")
    AddSpawnList(records, seen, quest.id, quest.title, objective or name, iconType, db.Object.Get(objectID, "spawns"))
end

function module:AddItem(records, seen, quest, objective, itemID)
    if not itemID then return end
    local db = self.provider
    local itemName = db.Item.Get(itemID, "name")
    for _, npcID in ipairs(db.Item.Get(itemID, "npcDrops") or {}) do self:AddNpc(records, seen, quest, objective or itemName, "loot", npcID) end
    for _, objectID in ipairs(db.Item.Get(itemID, "objectDrops") or {}) do self:AddObject(records, seen, quest, objective or itemName, "loot", objectID) end
end

function module:BuildRecords()
    self.records = {}
    if self.providerState ~= "ready" then return end
    local records, seen, db = self.records, {}, self.provider
    for _, quest in ipairs(self:GetTrackedQuests()) do
        local objectives = db.Quest.Get(quest.id, "objectives") or {}
        if FUI.db.questing.showObjectives then
            for _, row in ipairs(objectives[1] or {}) do self:AddNpc(records, seen, quest, row[2], "slay", row[1]) end
            for _, row in ipairs(objectives[2] or {}) do self:AddObject(records, seen, quest, row[2], "object", row[1]) end
            for _, row in ipairs(objectives[3] or {}) do self:AddItem(records, seen, quest, row[2], row[1]) end
            for _, row in ipairs(objectives[5] or {}) do
                for _, npcID in ipairs(row[1] or {}) do self:AddNpc(records, seen, quest, row[3], "slay", npcID) end
            end
            local trigger = db.Quest.Get(quest.id, "triggerEnd")
            if trigger then AddSpawnList(records, seen, quest.id, quest.title, trigger[1], "event", trigger[2]) end
            for _, extra in ipairs(db.Quest.Get(quest.id, "extraObjectives") or {}) do
                AddSpawnList(records, seen, quest.id, quest.title, extra[3], "event", extra[1])
            end
        end
        if FUI.db.questing.showTurnIns then
            local finishers = db.Quest.Get(quest.id, "finishedBy") or {}
            for _, npcID in ipairs(finishers[1] or {}) do self:AddNpc(records, seen, quest, "Quest turn-in", "turnin", npcID) end
            for _, objectID in ipairs(finishers[2] or {}) do self:AddObject(records, seen, quest, "Quest turn-in", "turnin", objectID) end
        end
    end
end

local function StylePin(pin, mini)
    if pin.styled then return end
    pin.styled = true
    -- Quest databases contain many spawn points in a small area. Keep the
    -- symbols deliberately compact so they describe the area instead of
    -- covering the map artwork.
    pin:SetSize(mini and 9 or 12, mini and 9 or 12)
    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetAllPoints()
    pin.icon:SetTexCoord(.08, .92, .08, .92)
    pin.icon:SetDrawLayer("OVERLAY", 1)
    pin:EnableMouse(not mini)
    if not mini then
        pin:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.data.title or "Quest", 1, .82, .2)
            if self.data.objective then GameTooltip:AddLine(self.data.objective, .85, .9, 1, true) end
            GameTooltip:Show()
        end)
        pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
end

function module:AcquireMapPin(index)
    local pin = self.mapPins[index] or table.remove(self.pinPool)
    if not pin then pin = CreateFrame("Button", nil, WorldMapFrame.ScrollContainer.Child) StylePin(pin, false) end
    pin:SetParent(WorldMapFrame.ScrollContainer.Child)
    self.mapPins[index] = pin
    return pin
end

function module:RefreshWorldMap()
    if not WorldMapFrame or not WorldMapFrame.ScrollContainer or not WorldMapFrame.ScrollContainer.Child then return end
    local mapID = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
    local child = WorldMapFrame.ScrollContainer.Child
    local width, height = child:GetWidth(), child:GetHeight()
    if not mapID or not width or width <= 1 or not height or height <= 1 then return end
    local used, occupied = 0, {}
    if FUI.db.questing.enabled and FUI.db.questing.worldMapIcons then
        for _, record in ipairs(self.records) do
            if record.mapID == mapID then
                -- Collapse virtually identical spawn coordinates. This keeps
                -- dense camps readable while retaining their overall shape.
                local gridX, gridY = math.floor(record.x / .0125), math.floor(record.y / .0125)
                local key = record.iconType .. ":" .. gridX .. ":" .. gridY
                if not occupied[key] then
                    occupied[key] = true
                    used = used + 1
                    local pin = self:AcquireMapPin(used)
                    pin.data = record
                    pin.icon:SetTexture(record.texture)
                    pin:ClearAllPoints()
                    pin:SetPoint("CENTER", child, "TOPLEFT", record.x * width, -record.y * height)
                    pin:SetFrameLevel(child:GetFrameLevel() + 2100)
                    pin:Show()
                end
            end
        end
    end
    for index = used + 1, #self.mapPins do self.mapPins[index]:Hide() end
end

function module:AcquireMinimapPin(index)
    if not self.minimapPins[index] then
        local pin = CreateFrame("Frame", nil, Minimap)
        StylePin(pin, true)
        pin:SetFrameLevel(Minimap:GetFrameLevel() + 12)
        self.minimapPins[index] = pin
    end
    return self.minimapPins[index]
end

function module:RefreshMinimap()
    if not Minimap then return end
    local enabled = FUI.db.questing.enabled and FUI.db.questing.minimapIcons
    local mapID = enabled and C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local player = mapID and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID, "player")
    local px, py = player and player:GetXY()
    local radiusByZoom = { 466.7, 400, 333.3, 266.7, 200, 133.3 }
    local radius = radiusByZoom[(Minimap:GetZoom() or 0) + 1] or 200
    local halfW, halfH = Minimap:GetWidth() / 2, Minimap:GetHeight() / 2
    local used = 0
    if mapID and px and py and C_Map.GetWorldPosFromMapPos then
        local _, playerWorld = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(px, py))
        local pwx, pwy = playerWorld and playerWorld:GetXY()
        if pwx and pwy then
            for _, record in ipairs(self.records) do
                if record.mapID == mapID then
                    local _, world = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(record.x, record.y))
                    local wx, wy = world and world:GetXY()
                    if wx and wy then
                        local dx, dy = wx - pwx, wy - pwy
                        if math.abs(dx) <= radius and math.abs(dy) <= radius then
                            used = used + 1
                            local pin = self:AcquireMinimapPin(used)
                            pin.icon:SetTexture(record.texture)
                            pin:ClearAllPoints()
                            pin:SetPoint("CENTER", Minimap, "CENTER", dx / radius * halfW, -dy / radius * halfH)
                            pin:Show()
                        end
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
    if WorldMapFrame.OnMapChanged then hooksecurefunc(WorldMapFrame, "OnMapChanged", function() module:RefreshWorldMap() end) end
end

function module:Apply()
    if not self.provider then self:PrepareProvider() end
    local utility = FUI.modules.utilityFrames
    local holder = utility and utility.trackerHolder
    if holder then holder:SetShown(FUI.db.questing.enabled and FUI.db.utilityFrames.objectiveTracker.enabled) end
    if ObjectiveTrackerFrame then
        ObjectiveTrackerFrame:SetAlpha(1)
        if ObjectiveTrackerFrame.EnableMouse then ObjectiveTrackerFrame:EnableMouse(true) end
    end
    self:Refresh()
end

function module:Initialize()
    self:PrepareProvider()
    self:HookWorldMap()
    local events = CreateFrame("Frame")
    for _, event in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "ZONE_CHANGED_NEW_AREA" }) do
        pcall(events.RegisterEvent, events, event)
    end
    events:SetScript("OnEvent", function()
        module:HookWorldMap()
        module.refreshPending = true
        C_Timer.After(.25, function()
            if module.refreshPending then module.refreshPending = false module:Refresh() end
        end)
    end)
    events:SetScript("OnUpdate", function(_, elapsed)
        module.miniElapsed = (module.miniElapsed or 0) + elapsed
        if module.miniElapsed >= .15 then module.miniElapsed = 0 module:RefreshMinimap() end
    end)
    self.events = events
    self:Apply()
end

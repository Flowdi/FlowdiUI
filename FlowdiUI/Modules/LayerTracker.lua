local _, ns = ...
local FUI = ns.FUI

local module = {
    prefix = "FUILayer",
    protocol = 1,
    maximumLayers = 40,
    lastBroadcast = 0,
    lastQuery = 0,
    lastReplies = {},
}
FUI:RegisterModule("layerTracker", module)

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function Now()
    return GetServerTime and GetServerTime() or time()
end

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function CleanToken(value)
    return tostring(value or ""):gsub("[^%w]", ""):lower()
end

function module:GetRealmToken()
    local realm = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName()
    return CleanToken(realm)
end

function module:GetFactionToken()
    local faction = UnitFactionGroup and UnitFactionGroup("player") or "Neutral"
    return CleanToken(faction)
end

function module:GetStore()
    local db = FUI.db.utilityFrames.layerTracker
    db.realms = type(db.realms) == "table" and db.realms or {}
    local key = self:GetRealmToken() .. ":" .. self:GetFactionToken()
    db.realms[key] = type(db.realms[key]) == "table" and db.realms[key] or { maps = {} }
    db.realms[key].maps = type(db.realms[key].maps) == "table" and db.realms[key].maps or {}
    return db.realms[key]
end

function module:GetMapStore(mapID, create)
    local store = self:GetStore()
    local key = tostring(mapID or 0)
    if create and type(store.maps[key]) ~= "table" then store.maps[key] = {} end
    return store.maps[key]
end

function module:GetRetentionSeconds()
    local minutes = tonumber(FUI.db.utilityFrames.layerTracker.retentionMinutes) or 120
    return Clamp(minutes, 15, 180) * 60
end

function module:GetCurrentMapID()
    local _, instanceType = GetInstanceInfo()
    if IsSecret(instanceType) then return nil, false end
    if instanceType and instanceType ~= "none" then return nil, true end
    if not C_Map or not C_Map.GetBestMapForUnit then return nil, false end
    local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
    if not ok or type(mapID) ~= "number" or IsSecret(mapID) or mapID <= 0 then return nil, false end
    return mapID, false
end

function module:GetMapName(mapID)
    if not mapID or not C_Map or not C_Map.GetMapInfo then return UNKNOWN or "Unknown" end
    local ok, info = pcall(C_Map.GetMapInfo, mapID)
    if ok and info and type(info.name) == "string" and not IsSecret(info.name) then return info.name end
    return UNKNOWN or "Unknown"
end

function module:Prune(mapID)
    local cutoff = Now() - self:GetRetentionSeconds()
    local maps = self:GetStore().maps
    local function PruneMap(key, layers)
        local remaining = 0
        if type(layers) == "table" then
            for layerID, data in pairs(layers) do
                if type(data) ~= "table" or type(data.lastSeen) ~= "number" or data.lastSeen < cutoff then
                    layers[layerID] = nil
                else
                    remaining = remaining + 1
                end
            end
        end
        if remaining == 0 then maps[key] = nil end
    end
    if mapID then
        local key = tostring(mapID)
        if maps[key] then PruneMap(key, maps[key]) end
    else
        for key, layers in pairs(maps) do PruneMap(key, layers) end
    end
    if self.currentSeen and self.currentSeen < cutoff then
        self.currentLayerID = nil
        self.currentSeen = nil
    end
end

function module:GetKnownLayers(mapID)
    if not mapID then return {} end
    self:Prune(mapID)
    local result = {}
    for layerID, data in pairs(self:GetMapStore(mapID, false) or {}) do
        local numericID = tonumber(layerID)
        if numericID and type(data) == "table" then
            result[#result + 1] = { id = numericID, lastSeen = data.lastSeen or 0 }
        end
    end
    table.sort(result, function(a, b) return a.id < b.id end)
    return result
end

function module:GetLayerIndex(mapID, layerID)
    if not layerID then return nil, #self:GetKnownLayers(mapID) end
    local layers = self:GetKnownLayers(mapID)
    for index, data in ipairs(layers) do
        if data.id == layerID then return index, #layers end
    end
    return nil, #layers
end

function module:RecordLayer(mapID, layerID, seenAt, isCurrent)
    mapID, layerID = tonumber(mapID), tonumber(layerID)
    if not mapID or not layerID or mapID <= 0 or layerID <= 0 or layerID > 4294967295 then return false end
    local layers = self:GetMapStore(mapID, true)
    local key = tostring(math.floor(layerID))
    local data = layers[key]
    local isNew = type(data) ~= "table"
    if isNew then
        local count = 0
        for _ in pairs(layers) do count = count + 1 end
        if count >= self.maximumLayers then return false end
        data = { firstSeen = seenAt or Now(), lastSeen = 0 }
        layers[key] = data
    end
    data.lastSeen = math.max(data.lastSeen or 0, seenAt or Now())
    if isCurrent then
        self.currentMapID = mapID
        self.currentLayerID = math.floor(layerID)
        self.currentSeen = seenAt or Now()
    end
    return isNew
end

function module:LayerFromUnit(unit)
    if not unit then return nil end
    local existsOK, exists = pcall(UnitExists, unit)
    if not existsOK or IsSecret(exists) or not exists then return nil end
    if UnitPlayerControlled then
        local ok, controlled = pcall(UnitPlayerControlled, unit)
        if ok and not IsSecret(controlled) and controlled then return nil end
    end
    local ok, guid = pcall(UnitGUID, unit)
    if not ok or type(guid) ~= "string" or IsSecret(guid) then return nil end
    local unitType, _, _, _, layerID = strsplit("-", guid)
    if unitType ~= "Creature" and unitType ~= "Vehicle" then return nil end
    layerID = tonumber(layerID)
    if not layerID or layerID <= 0 then return nil end
    return layerID
end

function module:ObserveUnit(unit)
    local mapID, instanced = self:GetCurrentMapID()
    if instanced or not mapID then return false end
    local layerID = self:LayerFromUnit(unit)
    if not layerID then return false end
    local isNew = self:RecordLayer(mapID, layerID, Now(), true)
    self:UpdateDisplay()
    if isNew then self:BroadcastSnapshot(mapID, true) end
    return true
end

function module:ScanVisibleUnits()
    local mapID, instanced = self:GetCurrentMapID()
    if instanced then
        self.currentMapID, self.currentLayerID, self.currentSeen = nil, nil, nil
        self:UpdateDisplay()
        return
    end
    if not mapID then return end
    if self.currentMapID and self.currentMapID ~= mapID then
        self.currentLayerID, self.currentSeen = nil, nil
    end
    self.currentMapID = mapID
    if self:ObserveUnit("mouseover") or self:ObserveUnit("target") then return end
    for index = 1, 40 do
        if self:ObserveUnit("nameplate" .. index) then return end
    end
    self:UpdateDisplay()
end

function module:BuildSnapshot(mapID)
    local entries = {}
    local now = Now()
    local header = string.format("D%d|%s|%s|%d|", self.protocol, self:GetRealmToken(), self:GetFactionToken(), mapID)
    local length = #header
    for _, data in ipairs(self:GetKnownLayers(mapID)) do
        local age = Clamp(math.floor((now - data.lastSeen) / 60), 0, 180)
        local entry = data.id .. ":" .. age
        local extra = #entry + (#entries > 0 and 1 or 0)
        if length + extra > 240 then break end
        entries[#entries + 1] = entry
        length = length + extra
    end
    return header .. table.concat(entries, ",")
end

function module:SendMessage(message, distribution, target)
    if not FUI.db.utilityFrames.layerTracker.syncEnabled then return false end
    if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then return false end
    local ok = pcall(C_ChatInfo.SendAddonMessage, self.prefix, message, distribution, target)
    return ok
end

function module:SendToAvailableChannels(message, includeYell)
    if IsInGuild and IsInGuild() then self:SendMessage(message, "GUILD") end
    if IsInGroup and IsInGroup() then
        self:SendMessage(message, IsInRaid and IsInRaid() and "RAID" or "PARTY")
    end
    if includeYell then self:SendMessage(message, "YELL") end
end

function module:BroadcastSnapshot(mapID, immediate)
    if not FUI.db.utilityFrames.layerTracker.syncEnabled or not mapID then return end
    local now = Now()
    if not immediate and now - self.lastBroadcast < 300 then return end
    self.lastBroadcast = now
    self:SendToAvailableChannels(self:BuildSnapshot(mapID), true)
end

function module:RequestSync(mapID)
    if not FUI.db.utilityFrames.layerTracker.syncEnabled or not mapID then return end
    local now = Now()
    if now - self.lastQuery < 15 then return end
    self.lastQuery = now
    local query = string.format("Q%d|%s|%s|%d", self.protocol, self:GetRealmToken(), self:GetFactionToken(), mapID)
    self:SendToAvailableChannels(query, true)
end

function module:IsMessageForPlayer(realm, faction)
    return CleanToken(realm) == self:GetRealmToken() and CleanToken(faction) == self:GetFactionToken()
end

function module:ReceiveSnapshot(payload)
    local version, realm, faction, mapText, entries = payload:match("^D(%d+)|([^|]+)|([^|]+)|(%d+)|(.*)$")
    if tonumber(version) ~= self.protocol or not self:IsMessageForPlayer(realm, faction) then return end
    local mapID = tonumber(mapText)
    if not mapID or mapID <= 0 or mapID > 100000 then return end
    local now, received = Now(), 0
    for entry in entries:gmatch("[^,]+") do
        if received >= self.maximumLayers then break end
        local layerText, ageText = entry:match("^(%d+):(%d+)$")
        local layerID, age = tonumber(layerText), tonumber(ageText)
        if layerID and age and age <= 180 then
            self:RecordLayer(mapID, layerID, now - age * 60, false)
            received = received + 1
        end
    end
    self:UpdateDisplay()
end

function module:ReceiveQuery(payload, sender)
    local version, realm, faction, mapText = payload:match("^Q(%d+)|([^|]+)|([^|]+)|(%d+)$")
    if tonumber(version) ~= self.protocol or not self:IsMessageForPlayer(realm, faction) then return end
    local mapID = tonumber(mapText)
    if not mapID or not sender or sender == "" or #self:GetKnownLayers(mapID) == 0 then return end
    local now = Now()
    if now - (self.lastReplies[sender] or 0) < 60 then return end
    self.lastReplies[sender] = now
    C_Timer.After(math.random(5, 20) / 10, function()
        module:SendMessage(module:BuildSnapshot(mapID), "WHISPER", sender)
    end)
end

function module:OnAddonMessage(prefix, payload, _, sender)
    if not FUI.db.utilityFrames.layerTracker.syncEnabled then return end
    if prefix ~= self.prefix or type(payload) ~= "string" then return end
    if payload:sub(1, 1) == "D" then
        self:ReceiveSnapshot(payload)
    elseif payload:sub(1, 1) == "Q" then
        self:ReceiveQuery(payload, sender)
    end
end

function module:GetStatus()
    local mapID, instanced = self:GetCurrentMapID()
    if instanced then return nil, 0, 0, nil, true end
    mapID = mapID or self.currentMapID
    local index, count = self:GetLayerIndex(mapID, self.currentLayerID)
    return index, count, mapID, self.currentLayerID, false
end

function module:GetDataText()
    local index, count, _, _, instanced = self:GetStatus()
    if instanced then return "Layer |cff55aaff--|r" end
    return string.format("Layer |cff55aaff%s|r/%d", index or "?", count)
end

function module:FormatAge(timestamp)
    local seconds = math.max(0, Now() - (timestamp or 0))
    if seconds < 60 then return "just now" end
    return string.format("%d min ago", math.floor(seconds / 60))
end

function module:AddTooltipLines()
    local index, count, mapID, currentID, instanced = self:GetStatus()
    GameTooltip:AddLine("FlowdiUI Layer Tracker", 0.35, 0.68, 1)
    if instanced then
        GameTooltip:AddLine("Layer tracking is paused inside instances.", 0.72, 0.8, 0.92, true)
        return
    end
    GameTooltip:AddDoubleLine("Zone", self:GetMapName(mapID), 1, 1, 1, 0.35, 0.68, 1)
    GameTooltip:AddDoubleLine("Current layer", index and ("Layer " .. index) or "Unknown", 1, 1, 1, index and 0.35 or 1, index and 0.85 or 0.72, index and 1 or 0.2)
    GameTooltip:AddDoubleLine("Known active", tostring(count), 1, 1, 1, 0.35, 0.68, 1)
    if count > 0 then
        GameTooltip:AddLine(" ")
        for layerIndex, data in ipairs(self:GetKnownLayers(mapID)) do
            local marker = data.id == currentID and "|cff55aaff> |r" or "  "
            GameTooltip:AddDoubleLine(marker .. "Layer " .. layerIndex, self:FormatAge(data.lastSeen), 0.92, 0.96, 1, 0.58, 0.7, 0.88)
        end
    end
    GameTooltip:AddLine(" ")
    if not index then GameTooltip:AddLine("Target or mouse over an outdoor NPC to identify your layer.", 1, 0.72, 0.2, true) end
    GameTooltip:AddLine("Recently observed layers are estimates, not an official Blizzard realm count.", 0.58, 0.7, 0.88, true)
    GameTooltip:AddLine("Left-click to scan and synchronize. Right-click for settings.", 0.45, 0.78, 1, true)
end

function module:UpdateDisplay()
    if not self.frame then return end
    local db = FUI.db.utilityFrames.layerTracker
    local index, count, mapID, _, instanced = self:GetStatus()
    if instanced then
        self.frame.value:SetText("--")
        self.frame.count:SetText("INSTANCE")
        self.frame.zone:SetText("Layer tracking paused")
        self.frame.state:SetText("PAUSED")
        self.frame.state:SetTextColor(0.65, 0.7, 0.8)
    else
        self.frame.value:SetText(index or "?")
        self.frame.count:SetFormattedText("%d ACTIVE", count)
        self.frame.zone:SetText(db.showZone and self:GetMapName(mapID) or (index and "Layer identified" or "Target an outdoor NPC"))
        self.frame.state:SetText(index and "LIVE" or "SCAN")
        self.frame.state:SetTextColor(index and 0.25 or 1, index and 0.9 or 0.72, index and 0.55 or 0.2)
    end
end

function module:OpenSettings()
    FUI:OpenSettings()
    FUI:SelectSettingsPage("utilityFrames")
    local page = FUI.settings and FUI.settings.pages and FUI.settings.pages.utilityFrames
    if page and page.SelectUtilityTab then page.SelectUtilityTab("Layer Tracker") end
end

function module:ManualRefresh(verbose)
    self:ScanVisibleUnits()
    local mapID = self:GetCurrentMapID()
    if mapID then
        self:RequestSync(mapID)
        self:BroadcastSnapshot(mapID, false)
    end
    if verbose then
        local index, count = self:GetStatus()
        FUI:Print(string.format("Layer %s of %d known active layers. Target an outdoor NPC if the current layer is unknown.", index or "?", count))
    end
end

function module:CreateFrame()
    local frame = CreateFrame("Button", "FlowdiUI_LayerTracker", UIParent, "BackdropTemplate")
    frame:SetSize(190, 42)
    frame:SetFrameStrata("LOW")
    frame:SetFrameLevel(5)
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    frame:SetBackdropColor(0.008, 0.016, 0.035, 0.96)
    frame:SetBackdropBorderColor(unpack(FUI.colors.border))

    frame.title = FUI:CreateFont(frame, 10)
    frame.title:SetPoint("TOPLEFT", 9, -7)
    frame.title:SetText("LAYER")
    frame.title:SetTextColor(0.58, 0.7, 0.88)
    frame.value = FUI:CreateFont(frame, 14)
    frame.value:SetPoint("LEFT", frame.title, "RIGHT", 6, 0)
    frame.value:SetTextColor(0.35, 0.75, 1)
    frame.count = FUI:CreateFont(frame, 10)
    frame.count:SetPoint("TOPRIGHT", -9, -7)
    frame.count:SetTextColor(0.58, 0.7, 0.88)
    frame.zone = FUI:CreateFont(frame, 10)
    frame.zone:SetPoint("BOTTOMLEFT", 9, 6)
    frame.zone:SetPoint("RIGHT", frame, "RIGHT", -50, 0)
    frame.zone:SetJustifyH("LEFT")
    frame.state = FUI:CreateFont(frame, 9)
    frame.state:SetPoint("BOTTOMRIGHT", -9, 6)

    local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(0.1, 0.4, 0.9, 0.13)
    frame:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.35, 0.82, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        module:AddTooltipLines()
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(FUI.colors.border))
        GameTooltip_Hide()
    end)
    frame:SetScript("OnClick", function(_, button)
        if button == "RightButton" then module:OpenSettings() else module:ManualRefresh(false) end
    end)

    FUI:RestorePosition(frame, "layerTracker")
    FUI:RegisterMover(frame, "layerTracker", "Layer Tracker")
    self.frame = frame
end

function module:Apply()
    if not self.frame then return end
    local db = FUI.db.utilityFrames.layerTracker
    self.frame:SetShown(db.enabled and not (WorldMapFrame and WorldMapFrame:IsShown()))
    self.frame:SetWidth(Clamp(tonumber(db.width) or 190, 150, 300))
    self.frame:SetScale(Clamp(tonumber(db.scale) or 1, 0.6, 1.6) * (FUI.db.scale or 1))
    self.frame:SetBackdropColor(0.008, 0.016, 0.035, FUI.db.global.backgroundOpacity or 0.96)
    self.frame:SetBackdropBorderColor(unpack(FUI.colors.border))
    local font, outline = FUI:GetModuleFontPath("layerTracker"), FUI.db.global.fontOutline
    local size = Clamp(tonumber(db.fontSize) or 12, 9, 18)
    self.frame.title:SetFont(font, math.max(8, size - 2), outline)
    self.frame.value:SetFont(font, size + 2, outline)
    self.frame.count:SetFont(font, math.max(8, size - 2), outline)
    self.frame.zone:SetFont(font, math.max(8, size - 2), outline)
    self.frame.state:SetFont(font, math.max(8, size - 3), outline)
    self:Prune()
    self:UpdateDisplay()
end

function module:HookFullscreenFrames()
    if not WorldMapFrame or WorldMapFrame.FlowdiLayerHooked then return end
    WorldMapFrame.FlowdiLayerHooked = true
    WorldMapFrame:HookScript("OnShow", function()
        if module.frame then module.frame:Hide() end
    end)
    WorldMapFrame:HookScript("OnHide", function() module:Apply() end)
end

function module:Initialize()
    self:CreateFrame()
    self:HookFullscreenFrames()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        pcall(C_ChatInfo.RegisterAddonMessagePrefix, self.prefix)
    end
    self.events = CreateFrame("Frame")
    for _, event in ipairs({
        "CHAT_MSG_ADDON", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "PLAYER_TARGET_CHANGED",
        "UPDATE_MOUSEOVER_UNIT", "NAME_PLATE_UNIT_ADDED", "GROUP_JOINED", "UNIT_PHASE", "ADDON_LOADED",
    }) do self.events:RegisterEvent(event) end
    self.events:SetScript("OnEvent", function(_, event, ...)
        if event == "ADDON_LOADED" then
            local addonName = ...
            if addonName == "Blizzard_WorldMap" then module:HookFullscreenFrames() end
        elseif event == "CHAT_MSG_ADDON" then
            module:OnAddonMessage(...)
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            module:ObserveUnit(...)
        elseif event == "PLAYER_TARGET_CHANGED" then
            module:ObserveUnit("target")
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            module:ObserveUnit("mouseover")
        elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
            module.currentLayerID, module.currentSeen = nil, nil
            C_Timer.After(1, function() module:ScanVisibleUnits() end)
            C_Timer.After(4, function()
                local mapID = module:GetCurrentMapID()
                if mapID then module:RequestSync(mapID) end
            end)
        elseif event == "GROUP_JOINED" then
            module.currentLayerID, module.currentSeen = nil, nil
            module:UpdateDisplay()
            C_Timer.After(2, function()
                module:ScanVisibleUnits()
                local mapID = module:GetCurrentMapID()
                if mapID then module:RequestSync(mapID) end
            end)
        elseif event == "UNIT_PHASE" then
            local unit = ...
            local leaderOK, isLeader = pcall(UnitIsGroupLeader, unit)
            if leaderOK and not IsSecret(isLeader) and isLeader then
                module.currentLayerID, module.currentSeen = nil, nil
                module:UpdateDisplay()
                C_Timer.After(2, function() module:ScanVisibleUnits() end)
            end
        end
    end)
    self.ticker = C_Timer.NewTicker(2, function() module:ScanVisibleUnits() end)
    self.pruneTicker = C_Timer.NewTicker(60, function()
        module:Prune()
        local mapID = module:GetCurrentMapID()
        if mapID then module:BroadcastSnapshot(mapID, false) end
        module:UpdateDisplay()
    end)
    self:Apply()
    C_Timer.After(5, function() module:ManualRefresh(false) end)
end


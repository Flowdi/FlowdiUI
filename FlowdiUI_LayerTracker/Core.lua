local ADDON_NAME = ...

local Tracker = CreateFrame("Frame")
_G.FlowdiUILayerTracker = Tracker

Tracker.version = "1.0.0"
Tracker.prefix = "FUILayer"
Tracker.protocol = 1
Tracker.maximumLayers = 40
Tracker.lastBroadcast = 0
Tracker.lastQuery = 0
Tracker.lastReplies = {}
Tracker.colors = {
    background = { 0.008, 0.016, 0.035, 0.96 },
    panel = { 0.018, 0.03, 0.065, 0.99 },
    border = { 0.11, 0.46, 1, 0.9 },
    accent = { 0.35, 0.75, 1, 1 },
    text = { 0.92, 0.96, 1, 1 },
    muted = { 0.58, 0.7, 0.88, 1 },
}
Tracker.defaults = {
    enabled = true,
    locked = true,
    syncEnabled = true,
    showZone = true,
    width = 190,
    scale = 1,
    fontSize = 12,
    retentionMinutes = 120,
    position = { "TOPRIGHT", "TOPRIGHT", -210, -12 },
    realms = {},
}

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

local function CopyDefaults(source, destination)
    destination = type(destination) == "table" and destination or {}
    for key, value in pairs(source) do
        if type(value) == "table" then
            destination[key] = CopyDefaults(value, destination[key])
        elseif destination[key] == nil then
            destination[key] = value
        end
    end
    return destination
end

local function CreateFont(parent, size)
    local font = parent:CreateFontString(nil, "OVERLAY")
    font:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "OUTLINE")
    font:SetTextColor(unpack(Tracker.colors.text))
    return font
end

local function StyleBackdrop(frame, background)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(background or Tracker.colors.background))
    frame:SetBackdropBorderColor(unpack(Tracker.colors.border))
end

function Tracker:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff55aaffFlowdiUI Layer Tracker:|r " .. tostring(message))
end

function Tracker:GetRealmToken()
    local realm = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName()
    return CleanToken(realm)
end

function Tracker:GetFactionToken()
    local faction = UnitFactionGroup and UnitFactionGroup("player") or "Neutral"
    return CleanToken(faction)
end

function Tracker:GetStore()
    self.db.realms = type(self.db.realms) == "table" and self.db.realms or {}
    local key = self:GetRealmToken() .. ":" .. self:GetFactionToken()
    self.db.realms[key] = type(self.db.realms[key]) == "table" and self.db.realms[key] or { maps = {} }
    self.db.realms[key].maps = type(self.db.realms[key].maps) == "table" and self.db.realms[key].maps or {}
    return self.db.realms[key]
end

function Tracker:GetMapStore(mapID, create)
    local store = self:GetStore()
    local key = tostring(mapID or 0)
    if create and type(store.maps[key]) ~= "table" then store.maps[key] = {} end
    return store.maps[key]
end

function Tracker:GetRetentionSeconds()
    return Clamp(tonumber(self.db.retentionMinutes) or 120, 15, 180) * 60
end

function Tracker:GetCurrentMapID()
    local _, instanceType = GetInstanceInfo()
    if IsSecret(instanceType) then return nil, false end
    if instanceType and instanceType ~= "none" then return nil, true end
    if not C_Map or not C_Map.GetBestMapForUnit then return nil, false end
    local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
    if not ok or type(mapID) ~= "number" or IsSecret(mapID) or mapID <= 0 then return nil, false end
    return mapID, false
end

function Tracker:GetMapName(mapID)
    if not mapID or not C_Map or not C_Map.GetMapInfo then return UNKNOWN or "Unknown" end
    local ok, info = pcall(C_Map.GetMapInfo, mapID)
    if ok and info and type(info.name) == "string" and not IsSecret(info.name) then return info.name end
    return UNKNOWN or "Unknown"
end

function Tracker:Prune(mapID)
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
        self.currentLayerID, self.currentSeen = nil, nil
    end
end

function Tracker:GetKnownLayers(mapID)
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

function Tracker:GetLayerIndex(mapID, layerID)
    local layers = self:GetKnownLayers(mapID)
    if layerID then
        for index, data in ipairs(layers) do
            if data.id == layerID then return index, #layers end
        end
    end
    return nil, #layers
end

function Tracker:RecordLayer(mapID, layerID, seenAt, isCurrent)
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

function Tracker:LayerFromUnit(unit)
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
    return layerID and layerID > 0 and layerID or nil
end

function Tracker:ObserveUnit(unit)
    local mapID, instanced = self:GetCurrentMapID()
    if instanced or not mapID then return false end
    local layerID = self:LayerFromUnit(unit)
    if not layerID then return false end
    local isNew = self:RecordLayer(mapID, layerID, Now(), true)
    self:UpdateDisplay()
    if isNew then self:BroadcastSnapshot(mapID, true) end
    return true
end

function Tracker:ScanVisibleUnits()
    local mapID, instanced = self:GetCurrentMapID()
    if instanced then
        self.currentMapID, self.currentLayerID, self.currentSeen = nil, nil, nil
        self:UpdateDisplay()
        return
    end
    if not mapID then return end
    if self.currentMapID and self.currentMapID ~= mapID then self.currentLayerID, self.currentSeen = nil, nil end
    self.currentMapID = mapID
    if self:ObserveUnit("mouseover") or self:ObserveUnit("target") then return end
    for index = 1, 40 do
        if self:ObserveUnit("nameplate" .. index) then return end
    end
    self:UpdateDisplay()
end

function Tracker:BuildSnapshot(mapID)
    local entries = {}
    local now = Now()
    local header = string.format("D%d|%s|%s|%d|", self.protocol, self:GetRealmToken(), self:GetFactionToken(), mapID)
    local length = #header
    for _, data in ipairs(self:GetKnownLayers(mapID)) do
        local entry = data.id .. ":" .. Clamp(math.floor((now - data.lastSeen) / 60), 0, 180)
        local extra = #entry + (#entries > 0 and 1 or 0)
        if length + extra > 240 then break end
        entries[#entries + 1] = entry
        length = length + extra
    end
    return header .. table.concat(entries, ",")
end

function Tracker:SendMessage(message, distribution, target)
    if not self.db.syncEnabled or not C_ChatInfo or not C_ChatInfo.SendAddonMessage then return false end
    return pcall(C_ChatInfo.SendAddonMessage, self.prefix, message, distribution, target)
end

function Tracker:SendToAvailableChannels(message, includeYell)
    if IsInGuild and IsInGuild() then self:SendMessage(message, "GUILD") end
    if IsInGroup and IsInGroup() then
        self:SendMessage(message, IsInRaid and IsInRaid() and "RAID" or "PARTY")
    end
    if includeYell then self:SendMessage(message, "YELL") end
end

function Tracker:BroadcastSnapshot(mapID, immediate)
    if not self.db.syncEnabled or not mapID then return end
    local now = Now()
    if not immediate and now - self.lastBroadcast < 300 then return end
    self.lastBroadcast = now
    self:SendToAvailableChannels(self:BuildSnapshot(mapID), true)
end

function Tracker:RequestSync(mapID)
    if not self.db.syncEnabled or not mapID then return end
    local now = Now()
    if now - self.lastQuery < 15 then return end
    self.lastQuery = now
    self:SendToAvailableChannels(string.format("Q%d|%s|%s|%d", self.protocol, self:GetRealmToken(), self:GetFactionToken(), mapID), true)
end

function Tracker:IsMessageForPlayer(realm, faction)
    return CleanToken(realm) == self:GetRealmToken() and CleanToken(faction) == self:GetFactionToken()
end

function Tracker:ReceiveSnapshot(payload)
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

function Tracker:ReceiveQuery(payload, sender)
    local version, realm, faction, mapText = payload:match("^Q(%d+)|([^|]+)|([^|]+)|(%d+)$")
    if tonumber(version) ~= self.protocol or not self:IsMessageForPlayer(realm, faction) then return end
    local mapID = tonumber(mapText)
    if not mapID or not sender or sender == "" or #self:GetKnownLayers(mapID) == 0 then return end
    local now = Now()
    if now - (self.lastReplies[sender] or 0) < 60 then return end
    self.lastReplies[sender] = now
    C_Timer.After(math.random(5, 20) / 10, function()
        Tracker:SendMessage(Tracker:BuildSnapshot(mapID), "WHISPER", sender)
    end)
end

function Tracker:OnAddonMessage(prefix, payload, _, sender)
    if not self.db.syncEnabled or prefix ~= self.prefix or type(payload) ~= "string" then return end
    if payload:sub(1, 1) == "D" then self:ReceiveSnapshot(payload) end
    if payload:sub(1, 1) == "Q" then self:ReceiveQuery(payload, sender) end
end

function Tracker:GetStatus()
    local mapID, instanced = self:GetCurrentMapID()
    if instanced then return nil, 0, nil, nil, true end
    mapID = mapID or self.currentMapID
    local index, count = self:GetLayerIndex(mapID, self.currentLayerID)
    return index, count, mapID, self.currentLayerID, false
end

function Tracker:FormatAge(timestamp)
    local seconds = math.max(0, Now() - (timestamp or 0))
    return seconds < 60 and "just now" or string.format("%d min ago", math.floor(seconds / 60))
end

function Tracker:AddTooltipLines()
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
    GameTooltip:AddLine("The count is based on recent observations, not an official Blizzard layer list.", 0.58, 0.7, 0.88, true)
    GameTooltip:AddLine("Left-click to scan. Right-click for settings.", 0.45, 0.78, 1, true)
end

function Tracker:UpdateDisplay()
    if not self.panel then return end
    local index, count, mapID, _, instanced = self:GetStatus()
    if instanced then
        self.panel.value:SetText("--")
        self.panel.count:SetText("INSTANCE")
        self.panel.zone:SetText("Layer tracking paused")
        self.panel.state:SetText("PAUSED")
        self.panel.state:SetTextColor(0.65, 0.7, 0.8)
    else
        self.panel.value:SetText(index or "?")
        self.panel.count:SetFormattedText("%d ACTIVE", count)
        self.panel.zone:SetText(self.db.showZone and self:GetMapName(mapID) or (index and "Layer identified" or "Target an outdoor NPC"))
        self.panel.state:SetText(index and "LIVE" or "SCAN")
        self.panel.state:SetTextColor(index and 0.25 or 1, index and 0.9 or 0.72, index and 0.55 or 0.2)
    end
end

function Tracker:SavePosition()
    if not self.panel then return end
    local point, _, relativePoint, x, y = self.panel:GetPoint(1)
    if point then self.db.position = { point, relativePoint, x, y } end
end

function Tracker:RestorePosition()
    local position = self.db.position or self.defaults.position
    self.panel:ClearAllPoints()
    self.panel:SetPoint(position[1], UIParent, position[2], position[3], position[4])
end

function Tracker:SyncMover()
    if not self.mover or not self.panel then return end
    local centerX, centerY = self.panel:GetCenter()
    if centerX and centerY then
        self.mover:ClearAllPoints()
        self.mover:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
    end
    self.mover:SetSize(math.max(80, self.panel:GetWidth() * self.panel:GetEffectiveScale() / UIParent:GetEffectiveScale()), math.max(30, self.panel:GetHeight() * self.panel:GetEffectiveScale() / UIParent:GetEffectiveScale()))
end

function Tracker:SetLocked(locked)
    self.db.locked = locked and true or false
    if self.db.locked then
        if self.mover then self.mover:Hide() end
        self:Print("position locked.")
    else
        self:SyncMover()
        self.mover:Show()
        self:Print("position unlocked; drag the blue mover and use /flayer lock when finished.")
    end
    if self.options and self.options.lockButton then self.options.lockButton.label:SetText(self.db.locked and "Unlock position" or "Lock position") end
end

function Tracker:CreateMover()
    local mover = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    mover:SetFrameStrata("TOOLTIP")
    mover:SetFrameLevel(200)
    mover:SetMovable(true)
    mover:SetClampedToScreen(true)
    mover:EnableMouse(true)
    mover:RegisterForDrag("LeftButton")
    mover:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
    mover:SetBackdropColor(0.02, 0.07, 0.12, 0.82)
    mover:SetBackdropBorderColor(0.12, 0.62, 1, 1)
    mover.label = CreateFont(mover, 11)
    mover.label:SetPoint("CENTER")
    mover.label:SetText("Layer Tracker")
    mover.label:SetTextColor(0.82, 0.93, 1)
    mover:SetScript("OnDragStart", function(self) self:StartMoving() end)
    mover:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        if x and y then
            Tracker.panel:ClearAllPoints()
            Tracker.panel:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
            Tracker:SavePosition()
            Tracker:SyncMover()
        end
    end)
    mover:Hide()
    self.mover = mover
end

function Tracker:CreatePanel()
    local panel = CreateFrame("Button", "FlowdiUIStandaloneLayerTracker", UIParent, "BackdropTemplate")
    panel:SetSize(190, 42)
    panel:SetFrameStrata("HIGH")
    panel:SetFrameLevel(20)
    panel:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    StyleBackdrop(panel)
    panel.title = CreateFont(panel, 10)
    panel.title:SetPoint("TOPLEFT", 9, -7)
    panel.title:SetText("LAYER")
    panel.title:SetTextColor(unpack(self.colors.muted))
    panel.value = CreateFont(panel, 14)
    panel.value:SetPoint("LEFT", panel.title, "RIGHT", 6, 0)
    panel.value:SetTextColor(unpack(self.colors.accent))
    panel.count = CreateFont(panel, 10)
    panel.count:SetPoint("TOPRIGHT", -9, -7)
    panel.count:SetTextColor(unpack(self.colors.muted))
    panel.zone = CreateFont(panel, 10)
    panel.zone:SetPoint("BOTTOMLEFT", 9, 6)
    panel.zone:SetPoint("RIGHT", panel, "RIGHT", -50, 0)
    panel.zone:SetJustifyH("LEFT")
    panel.state = CreateFont(panel, 9)
    panel.state:SetPoint("BOTTOMRIGHT", -9, 6)
    local highlight = panel:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(0.1, 0.4, 0.9, 0.13)
    panel:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.35, 0.82, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        Tracker:AddTooltipLines()
        GameTooltip:Show()
    end)
    panel:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(Tracker.colors.border))
        GameTooltip_Hide()
    end)
    panel:SetScript("OnClick", function(_, button)
        if button == "RightButton" then Tracker:ToggleOptions() else Tracker:ManualRefresh(false) end
    end)
    self.panel = panel
    self:RestorePosition()
    self:CreateMover()
end

local function CreateButton(parent, label, width, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 150, 28)
    StyleBackdrop(button, { 0.025, 0.045, 0.08, 0.98 })
    button.label = CreateFont(button, 11)
    button.label:SetPoint("CENTER")
    button.label:SetText(label)
    button:SetScript("OnEnter", function(self) self:SetBackdropColor(0.08, 0.28, 0.55, 0.98) end)
    button:SetScript("OnLeave", function(self) self:SetBackdropColor(0.025, 0.045, 0.08, 0.98) end)
    button:SetScript("OnClick", callback)
    return button
end

local function CreateCheckbox(parent, label, x, y, getter, setter)
    local box = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    box:SetPoint("TOPLEFT", x, y)
    box.Text:SetText(label)
    box.Text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    box:SetScript("OnShow", function(self) self:SetChecked(getter()) end)
    box:SetScript("OnClick", function(self) setter(self:GetChecked() and true or false) Tracker:Apply() end)
    return box
end

local function CreateSlider(parent, label, x, y, minimum, maximum, step, getter, setter, formatter)
    local title = CreateFont(parent, 11)
    title:SetPoint("TOPLEFT", x, y)
    title:SetText(label)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y - 22)
    slider:SetWidth(195)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    if slider.Low then slider.Low:SetText("") end
    if slider.High then slider.High:SetText("") end
    if slider.Text then slider.Text:SetText("") end
    local value = CreateFont(parent, 10)
    value:SetPoint("LEFT", slider, "RIGHT", 5, 0)
    value:SetTextColor(unpack(Tracker.colors.accent))
    slider:SetScript("OnShow", function(self)
        self.refreshing = true
        self:SetValue(getter())
        self.refreshing = false
        value:SetText(formatter(self:GetValue()))
    end)
    slider:SetScript("OnValueChanged", function(self, amount)
        value:SetText(formatter(amount))
        if not self.refreshing then setter(amount) Tracker:Apply() end
    end)
    return slider
end

function Tracker:CreateOptions()
    local frame = CreateFrame("Frame", "FlowdiUILayerTrackerOptions", UIParent, "BackdropTemplate")
    frame:SetSize(570, 470)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    StyleBackdrop(frame, { 0.012, 0.02, 0.04, 0.99 })
    tinsert(UISpecialFrames, frame:GetName())
    local title = CreateFont(frame, 21)
    title:SetPoint("TOPLEFT", 22, -20)
    title:SetText("FlowdiUI Layer Tracker")
    local version = CreateFont(frame, 10)
    version:SetPoint("TOPRIGHT", -42, -27)
    version:SetTextColor(unpack(self.colors.accent))
    version:SetText("FOREVER  •  " .. self.version)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3)
    close:SetScript("OnClick", function() frame:Hide() end)
    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(unpack(self.colors.accent))
    line:SetPoint("TOPLEFT", 22, -57)
    line:SetPoint("TOPRIGHT", -22, -57)
    line:SetHeight(1)
    local description = CreateFont(frame, 11)
    description:SetPoint("TOPLEFT", 22, -74)
    description:SetWidth(520)
    description:SetJustifyH("LEFT")
    description:SetTextColor(unpack(self.colors.muted))
    description:SetText("Standalone outdoor layer detection using NPC GUIDs and compatible peer observations. No FlowdiUI or NovaWorldBuffs installation is required.")

    CreateCheckbox(frame, "Enable panel", 22, -125, function() return Tracker.db.enabled end, function(v) Tracker.db.enabled = v end)
    CreateCheckbox(frame, "Share observations", 285, -125, function() return Tracker.db.syncEnabled end, function(v) Tracker.db.syncEnabled = v end)
    CreateCheckbox(frame, "Show current zone", 22, -165, function() return Tracker.db.showZone end, function(v) Tracker.db.showZone = v end)
    CreateSlider(frame, "Panel width", 22, -220, 150, 300, 5, function() return Tracker.db.width end, function(v) Tracker.db.width = v end, function(v) return string.format("%d px", v) end)
    CreateSlider(frame, "Scale", 285, -220, 0.6, 1.6, 0.05, function() return Tracker.db.scale end, function(v) Tracker.db.scale = v end, function(v) return string.format("%d%%", v * 100) end)
    CreateSlider(frame, "Font size", 22, -300, 9, 18, 1, function() return Tracker.db.fontSize end, function(v) Tracker.db.fontSize = v end, function(v) return string.format("%d px", v) end)
    CreateSlider(frame, "Active observation window", 285, -300, 15, 180, 15, function() return Tracker.db.retentionMinutes end, function(v) Tracker.db.retentionMinutes = v end, function(v) return string.format("%d min", v) end)

    frame.lockButton = CreateButton(frame, self.db.locked and "Unlock position" or "Lock position", 155, function() Tracker:SetLocked(not Tracker.db.locked) end)
    frame.lockButton:SetPoint("BOTTOMLEFT", 22, 22)
    local scan = CreateButton(frame, "Scan now", 130, function() Tracker:ManualRefresh(true) end)
    scan:SetPoint("LEFT", frame.lockButton, "RIGHT", 10, 0)
    local reset = CreateButton(frame, "Reset position", 145, function()
        Tracker.db.position = { unpack(Tracker.defaults.position) }
        Tracker:RestorePosition()
        Tracker:SyncMover()
    end)
    reset:SetPoint("LEFT", scan, "RIGHT", 10, 0)
    frame:Hide()
    self.options = frame
end

function Tracker:ToggleOptions()
    if not self.options then self:CreateOptions() end
    self.options:SetShown(not self.options:IsShown())
end

function Tracker:Apply()
    if not self.panel then return end
    self.panel:SetShown(self.db.enabled)
    self.panel:SetWidth(Clamp(tonumber(self.db.width) or 190, 150, 300))
    self.panel:SetScale(Clamp(tonumber(self.db.scale) or 1, 0.6, 1.6))
    self.panel:SetBackdropColor(0.008, 0.016, 0.035, 0.96)
    self.panel:SetBackdropBorderColor(unpack(self.colors.border))
    local size = Clamp(tonumber(self.db.fontSize) or 12, 9, 18)
    for _, data in ipairs({
        { self.panel.title, math.max(8, size - 2) }, { self.panel.value, size + 2 },
        { self.panel.count, math.max(8, size - 2) }, { self.panel.zone, math.max(8, size - 2) },
        { self.panel.state, math.max(8, size - 3) },
    }) do data[1]:SetFont("Fonts\\FRIZQT__.TTF", data[2], "OUTLINE") end
    self:Prune()
    self:UpdateDisplay()
    if self.mover and self.mover:IsShown() then self:SyncMover() end
end

function Tracker:ManualRefresh(verbose)
    self:ScanVisibleUnits()
    local mapID = self:GetCurrentMapID()
    if mapID then
        self:RequestSync(mapID)
        self:BroadcastSnapshot(mapID, false)
    end
    if verbose then
        local index, count = self:GetStatus()
        self:Print(string.format("Layer %s of %d known active layers. Target an outdoor NPC if the current layer is unknown.", index or "?", count))
    end
end

function Tracker:RegisterRuntimeEvents()
    for _, event in ipairs({
        "CHAT_MSG_ADDON", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "PLAYER_TARGET_CHANGED",
        "UPDATE_MOUSEOVER_UNIT", "NAME_PLATE_UNIT_ADDED", "GROUP_JOINED", "UNIT_PHASE",
    }) do self:RegisterEvent(event) end
end

function Tracker:Initialize()
    self.db = CopyDefaults(self.defaults, FlowdiUILayerTrackerDB or {})
    FlowdiUILayerTrackerDB = self.db
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then pcall(C_ChatInfo.RegisterAddonMessagePrefix, self.prefix) end
    self:CreatePanel()
    self:RegisterRuntimeEvents()
    self:Apply()
    C_Timer.After(5, function() Tracker:ManualRefresh(false) end)
    self.ticker = C_Timer.NewTicker(2, function() Tracker:ScanVisibleUnits() end)
    self.pruneTicker = C_Timer.NewTicker(60, function()
        Tracker:Prune()
        local mapID = Tracker:GetCurrentMapID()
        if mapID then Tracker:BroadcastSnapshot(mapID, false) end
        Tracker:UpdateDisplay()
    end)
end

Tracker:RegisterEvent("PLAYER_LOGIN")
Tracker:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        self:Initialize()
    elseif event == "CHAT_MSG_ADDON" then
        self:OnAddonMessage(...)
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        self:ObserveUnit(...)
    elseif event == "PLAYER_TARGET_CHANGED" then
        self:ObserveUnit("target")
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        self:ObserveUnit("mouseover")
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        self.currentLayerID, self.currentSeen = nil, nil
        C_Timer.After(1, function() Tracker:ScanVisibleUnits() end)
        C_Timer.After(4, function()
            local mapID = Tracker:GetCurrentMapID()
            if mapID then Tracker:RequestSync(mapID) end
        end)
    elseif event == "GROUP_JOINED" then
        self.currentLayerID, self.currentSeen = nil, nil
        self:UpdateDisplay()
        C_Timer.After(2, function()
            Tracker:ScanVisibleUnits()
            local mapID = Tracker:GetCurrentMapID()
            if mapID then Tracker:RequestSync(mapID) end
        end)
    elseif event == "UNIT_PHASE" then
        local unit = ...
        local ok, leader = pcall(UnitIsGroupLeader, unit)
        if ok and not IsSecret(leader) and leader then
            self.currentLayerID, self.currentSeen = nil, nil
            self:UpdateDisplay()
            C_Timer.After(2, function() Tracker:ScanVisibleUnits() end)
        end
    end
end)

SLASH_FLOWDILAYERTRACKER1 = "/flayer"
SLASH_FLOWDILAYERTRACKER2 = "/flowdilayer"
SlashCmdList.FLOWDILAYERTRACKER = function(message)
    message = (message or ""):lower():match("^%s*(.-)%s*$")
    if message == "unlock" then
        Tracker:SetLocked(false)
    elseif message == "lock" then
        Tracker:SetLocked(true)
    elseif message == "scan" or message == "refresh" then
        Tracker:ManualRefresh(true)
    elseif message == "reset" then
        Tracker.db.position = { unpack(Tracker.defaults.position) }
        Tracker:RestorePosition()
        Tracker:SyncMover()
        Tracker:Print("position reset.")
    else
        Tracker:ToggleOptions()
    end
end

function FlowdiUILayerTracker_AddonCompartmentFunc()
    Tracker:ToggleOptions()
end

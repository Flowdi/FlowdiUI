local _, ns = ...
local FUI = ns.FUI

local module = { providers = {}, providerOrder = {}, panels = {}, slots = {} }
FUI:RegisterModule("dataPanels", module)

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function FormatMoney(value)
    value = value or 0
    local gold = math.floor(value / 10000)
    local silver = math.floor((value % 10000) / 100)
    local copper = value % 100
    return string.format("|cffffd36b%d|rg |cffc7c7cf%d|rs |cffc98245%d|rc", gold, silver, copper)
end

local function Percent(current, maximum)
    if not maximum or maximum <= 0 then return 0 end
    return math.floor((current / maximum) * 100 + 0.5)
end

local function DurabilityPercent()
    local current, maximum = 0, 0
    for slot = 1, 18 do
        local value, maxValue = GetInventoryItemDurability(slot)
        if value and maxValue and maxValue > 0 then
            current = current + value
            maximum = maximum + maxValue
        end
    end
    return maximum > 0 and Percent(current, maximum) or nil
end

local function BagSpace()
    local free, total = 0, 0
    local maxBag = NUM_TOTAL_EQUIPPED_BAG_SLOTS or 4
    for bag = 0, maxBag do
        local slots = C_Container.GetContainerNumSlots(bag) or 0
        local empty = C_Container.GetContainerNumFreeSlots(bag) or 0
        total = total + slots
        free = free + empty
    end
    return free, total
end

local function SafeCoordinates()
    if not C_Map or not C_Map.GetBestMapForUnit then return nil end
    local okMap, mapID = pcall(C_Map.GetBestMapForUnit, "player")
    if not okMap or not mapID or IsSecret(mapID) then return nil end
    local okPosition, position = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
    if not okPosition or not position then return nil end
    local okXY, x, y = pcall(position.GetXY, position)
    if not okXY or IsSecret(x) or IsSecret(y) then return nil end
    return x, y, mapID
end

local function SafeNumber(callback, ...)
    local ok, value = pcall(callback, ...)
    if not ok or type(value) ~= "number" or IsSecret(value) then return 0 end
    return value
end

function module:RegisterProvider(name, provider)
    if self.providers[name] then return end
    provider.name = name
    self.providers[name] = provider
    self.providerOrder[#self.providerOrder + 1] = name
end

function module:GetProviderNames()
    local names = { "None" }
    local available = {}
    for _, name in ipairs(self.providerOrder) do available[#available + 1] = name end
    table.sort(available)
    for _, name in ipairs(available) do names[#names + 1] = name end
    return names
end

local function SimpleTooltip(title, description)
    GameTooltip:AddLine(title, 0.35, 0.68, 1)
    if description then GameTooltip:AddLine(description, 0.72, 0.8, 0.92, true) end
end

function module:RegisterStatProvider(name, statIndex)
    self:RegisterProvider(name, {
        Update = function()
            local value = SafeNumber(function() return select(2, UnitStat("player", statIndex)) end)
            return string.format("%s |cff55aaff%d|r", name, value)
        end,
        Tooltip = function() SimpleTooltip(name, "Current character value") end,
    })
end

function module:RegisterProviders()
    self:RegisterProvider("System", {
        Update = function()
            local _, _, home, world = GetNetStats()
            return string.format("FPS |cff55aaff%d|r  MS |cff55aaff%d|r", math.floor(GetFramerate()), world or home or 0)
        end,
        Tooltip = function()
            local down, up, home, world = GetNetStats()
            GameTooltip:AddLine("System", 0.35, 0.68, 1)
            GameTooltip:AddDoubleLine("FPS", math.floor(GetFramerate()), 1, 1, 1, 0.35, 0.68, 1)
            GameTooltip:AddDoubleLine("Home latency", (home or 0) .. " ms", 1, 1, 1, 0.35, 0.68, 1)
            GameTooltip:AddDoubleLine("World latency", (world or 0) .. " ms", 1, 1, 1, 0.35, 0.68, 1)
            GameTooltip:AddDoubleLine("Download", string.format("%.2f KB/s", down or 0), 1, 1, 1, 0.35, 0.68, 1)
            GameTooltip:AddDoubleLine("Upload", string.format("%.2f KB/s", up or 0), 1, 1, 1, 0.35, 0.68, 1)
        end,
    })

    self:RegisterProvider("Bags", {
        Update = function()
            local free, total = BagSpace()
            return string.format("Bags |cff55aaff%d|r/%d", total - free, total)
        end,
        Tooltip = function()
            local free, total = BagSpace()
            GameTooltip:AddLine("Bags", 0.35, 0.68, 1)
            GameTooltip:AddDoubleLine("Used", total - free, 1, 1, 1, 0.35, 0.68, 1)
            GameTooltip:AddDoubleLine("Free", free, 1, 1, 1, 0.35, 0.68, 1)
            GameTooltip:AddLine("Click to open all bags.", 0.6, 0.72, 0.9)
        end,
        OnClick = function() if OpenAllBags then OpenAllBags() end end,
    })

    self:RegisterProvider("Gold", {
        Update = function() return FormatMoney(GetMoney()) end,
        Tooltip = function()
            SimpleTooltip("Gold", "Current character wealth")
            GameTooltip:AddLine(FormatMoney(GetMoney()), 1, 1, 1)
        end,
    })

    self:RegisterProvider("Durability", {
        Update = function()
            local value = DurabilityPercent()
            if not value then return "Durability --" end
            local color = value < 30 and "|cffff5555" or "|cff55aaff"
            return "Durability " .. color .. value .. "%|r"
        end,
        Tooltip = function()
            GameTooltip:AddLine("Durability", 0.35, 0.68, 1)
            GameTooltip:AddDoubleLine("Average", (DurabilityPercent() or 0) .. "%", 1, 1, 1, 0.35, 0.68, 1)
            GameTooltip:AddLine("Click to open the character panel.", 0.6, 0.72, 0.9)
        end,
        OnClick = function() if ToggleCharacter then ToggleCharacter("PaperDollFrame") end end,
    })

    self:RegisterProvider("Time", {
        Update = function() return date("%H:%M") end,
        Tooltip = function()
            GameTooltip:AddLine(date("%A, %d %B %Y"), 0.35, 0.68, 1)
            GameTooltip:AddDoubleLine("Local time", date("%H:%M:%S"), 1, 1, 1, 0.35, 0.68, 1)
            GameTooltip:AddLine("Click to open the calendar.", 0.6, 0.72, 0.9)
        end,
        OnClick = function() if ToggleCalendar then ToggleCalendar() end end,
    })

    self:RegisterProvider("Date", {
        Update = function() return date("%d.%m.%Y") end,
        Tooltip = function() SimpleTooltip("Date", date("%A, %d %B %Y")) end,
    })

    self:RegisterProvider("Coordinates", {
        Update = function()
            local x, y = SafeCoordinates()
            return x and string.format("%.1f, %.1f", x * 100, y * 100) or "--, --"
        end,
        Tooltip = function()
            local x, y, mapID = SafeCoordinates()
            local info = mapID and C_Map.GetMapInfo(mapID)
            SimpleTooltip(info and info.name or "Coordinates", x and string.format("%.1f, %.1f", x * 100, y * 100) or "Unavailable")
        end,
        OnClick = function() if ToggleWorldMap then ToggleWorldMap() end end,
    })

    self:RegisterProvider("Location", {
        Update = function()
            local _, _, mapID = SafeCoordinates()
            local info = mapID and C_Map.GetMapInfo(mapID)
            return info and info.name or GetZoneText() or "Unknown"
        end,
        Tooltip = function() SimpleTooltip("Location", GetSubZoneText()) end,
        OnClick = function() if ToggleWorldMap then ToggleWorldMap() end end,
    })

    self:RegisterProvider("Friends", {
        Update = function()
            local online = C_FriendList and C_FriendList.GetNumOnlineFriends and C_FriendList.GetNumOnlineFriends() or 0
            local bnOnline = 0
            if BNGetNumFriends then
                local _, value = BNGetNumFriends()
                bnOnline = value or 0
            end
            return string.format("Friends |cff55aaff%d|r", (online or 0) + (bnOnline or 0))
        end,
        Tooltip = function() SimpleTooltip("Friends", "Click to open the friends list.") end,
        OnClick = function() if ToggleFriendsFrame then ToggleFriendsFrame(1) end end,
    })

    self:RegisterProvider("Guild", {
        Update = function()
            if not IsInGuild() then return "No Guild" end
            local _, online = GetNumGuildMembers()
            return string.format("Guild |cff55aaff%d|r", online or 0)
        end,
        Tooltip = function() SimpleTooltip(GetGuildInfo("player") or "Guild", "Click to open the guild panel.") end,
        OnClick = function() if ToggleGuildFrame then ToggleGuildFrame() end end,
    })

    self:RegisterProvider("Experience", {
        Update = function()
            local current, maximum = UnitXP("player") or 0, UnitXPMax("player") or 0
            return maximum > 0 and string.format("XP |cff55aaff%d%%|r", Percent(current, maximum)) or "XP MAX"
        end,
        Tooltip = function()
            local current, maximum = UnitXP("player") or 0, UnitXPMax("player") or 0
            GameTooltip:AddLine("Experience", 0.35, 0.68, 1)
            GameTooltip:AddDoubleLine(current, maximum, 1, 1, 1, 0.35, 0.68, 1)
        end,
    })

    self:RegisterProvider("Item Level", {
        Update = function()
            local value = GetAverageItemLevel and select(2, GetAverageItemLevel()) or 0
            return string.format("Item Level |cff55aaff%.1f|r", value or 0)
        end,
        Tooltip = function() SimpleTooltip("Item Level", "Equipped average item level") end,
        OnClick = function() if ToggleCharacter then ToggleCharacter("PaperDollFrame") end end,
    })

    self:RegisterProvider("Reputation", {
        Update = function()
            if C_Reputation and C_Reputation.GetWatchedFactionData then
                local data = C_Reputation.GetWatchedFactionData()
                if data and data.name then
                    local value = (data.currentStanding or 0) - (data.currentReactionThreshold or 0)
                    local maximum = (data.nextReactionThreshold or 0) - (data.currentReactionThreshold or 0)
                    return string.format("%s |cff55aaff%d%%|r", data.name, Percent(value, maximum))
                end
            elseif GetWatchedFactionInfo then
                local name, _, minimum, maximum, value = GetWatchedFactionInfo()
                if name then return string.format("%s |cff55aaff%d%%|r", name, Percent(value - minimum, maximum - minimum)) end
            end
            return "No Reputation"
        end,
        Tooltip = function() SimpleTooltip("Reputation", "Currently watched faction") end,
        OnClick = function() if ToggleCharacter then ToggleCharacter("ReputationFrame") end end,
    })

    self:RegisterProvider("Attack Power", {
        Update = function()
            local base, positive, negative = UnitAttackPower("player")
            return string.format("AP |cff55aaff%d|r", (base or 0) + (positive or 0) + (negative or 0))
        end,
        Tooltip = function() SimpleTooltip("Attack Power", "Current melee or ranged attack power") end,
    })
    self:RegisterProvider("Armor", {
        Update = function() return string.format("Armor |cff55aaff%d|r", SafeNumber(function() return select(2, UnitArmor("player")) end)) end,
        Tooltip = function() SimpleTooltip("Armor", "Current effective armor") end,
    })
    self:RegisterProvider("Crit", {
        Update = function() return string.format("Crit |cff55aaff%.1f%%|r", SafeNumber(GetCritChance)) end,
        Tooltip = function() SimpleTooltip("Critical Strike", "Current critical strike chance") end,
    })
    self:RegisterProvider("Haste", {
        Update = function() return string.format("Haste |cff55aaff%.1f%%|r", SafeNumber(GetHaste)) end,
        Tooltip = function() SimpleTooltip("Haste", "Current haste percentage") end,
    })
    self:RegisterProvider("Mastery", {
        Update = function() return string.format("Mastery |cff55aaff%.1f%%|r", SafeNumber(GetMasteryEffect)) end,
        Tooltip = function() SimpleTooltip("Mastery", "Current mastery effect") end,
    })
    self:RegisterProvider("Movement Speed", {
        Update = function()
            local speed = SafeNumber(function() return select(2, GetUnitSpeed("player")) end)
            return string.format("Speed |cff55aaff%d%%|r", math.floor((speed / 7) * 100 + 0.5))
        end,
        Tooltip = function() SimpleTooltip("Movement Speed", "Current movement speed") end,
    })
    self:RegisterProvider("Mail", {
        Update = function() return HasNewMail and HasNewMail() and "|cff55aaffNew Mail|r" or "No Mail" end,
        Tooltip = function() SimpleTooltip("Mail", "Unread mailbox status") end,
    })
    self:RegisterProvider("Volume", {
        Update = function() return string.format("Volume |cff55aaff%d%%|r", math.floor((tonumber(GetCVar("Sound_MasterVolume")) or 0) * 100 + 0.5)) end,
        Tooltip = function() SimpleTooltip("Volume", "Master sound volume") end,
    })

    self:RegisterStatProvider("Strength", 1)
    self:RegisterStatProvider("Agility", 2)
    self:RegisterStatProvider("Stamina", 3)
    self:RegisterStatProvider("Intellect", 4)
end

function module:UpdateSlot(slot)
    local providerName = slot.panel.slotValues[slot.index] or "None"
    local provider = self.providers[providerName]
    slot.provider = provider
    if provider and provider.Update then
        local ok, value = pcall(provider.Update)
        slot.text:SetText(ok and value or "--")
    else
        slot.text:SetText("")
    end
end

function module:Update()
    for _, slot in ipairs(self.slots) do
        if slot:IsShown() then self:UpdateSlot(slot) end
    end
end

function module:CreateSlot(panel, index)
    local slot = CreateFrame("Button", nil, panel)
    slot.index = index
    slot.panel = panel
    slot:RegisterForClicks("AnyUp")
    slot:RegisterForDrag("LeftButton")
    local text = FUI:CreateFont(slot, FUI.db.dataPanels.fontSize)
    text:SetPoint("LEFT", 5, 0)
    text:SetPoint("RIGHT", -5, 0)
    text:SetJustifyH("CENTER")
    slot.text = text
    local highlight = slot:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(0.1, 0.4, 0.9, 0.16)
    slot:SetScript("OnEnter", function(self)
        if not self.provider or not self.provider.Tooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        self.provider.Tooltip()
        GameTooltip:Show()
    end)
    slot:SetScript("OnLeave", GameTooltip_Hide)
    slot:SetScript("OnDragStart", function()
        if panel.positionKey and not FUI.db.locked and not InCombatLockdown() then panel:StartMoving() end
    end)
    slot:SetScript("OnDragStop", function()
        if not panel.positionKey then return end
        panel:StopMovingOrSizing()
        FUI:SavePosition(panel, panel.positionKey)
    end)
    slot:SetScript("OnClick", function(self, button)
        if panel.positionKey and not FUI.db.locked and button == "LeftButton" then
            FUI:OpenSettings()
        elseif self.provider and self.provider.OnClick then
            self.provider.OnClick(button)
        end
    end)
    self.slots[#self.slots + 1] = slot
    panel.slots[index] = slot
end

function module:CreatePanel(name, positionKey, maximumSlots)
    local panel = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    panel:SetFrameStrata("HIGH")
    panel:SetFrameLevel(20)
    panel:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    panel.positionKey = positionKey
    panel.slots = {}
    if positionKey then
        FUI:RestorePosition(panel, positionKey)
        FUI:MakeMovable(panel, positionKey)
    end
    for index = 1, maximumSlots do self:CreateSlot(panel, index) end
    self.panels[#self.panels + 1] = panel
    return panel
end

function module:ApplyPanel(panel, enabled, width, height, count, slotValues)
    panel.slotValues = slotValues
    panel:SetShown(enabled)
    if not enabled then return end
    local db = FUI.db.dataPanels
    panel:SetSize(width, height)
    panel:SetScale((FUI.db.scale or 1) * db.scale)
    panel:SetAlpha(db.opacity)
    local backgroundAlpha = db.backdrop and (db.transparent and 0.28 or 0.96) or 0
    panel:SetBackdropColor(0.008, 0.016, 0.035, backgroundAlpha)
    if db.border then panel:SetBackdropBorderColor(unpack(FUI.colors.border)) else panel:SetBackdropBorderColor(0, 0, 0, 0) end
    local slotWidth = width / math.max(1, count)
    for index, slot in ipairs(panel.slots) do
        slot:SetShown(index <= count)
        if index <= count then
            slot:ClearAllPoints()
            slot:SetPoint("TOPLEFT", panel, "TOPLEFT", (index - 1) * slotWidth, 0)
            slot:SetSize(slotWidth, height)
            slot.text:SetFont(FUI:GetModuleFontPath("dataPanels"), db.fontSize, FUI.db.global.fontOutline)
        end
    end
end

function module:Apply()
    if not self.primary then return end
    local db = FUI.db.dataPanels
    self:ApplyPanel(self.primary, true, db.width, db.height, db.primaryCount, db.slots)
    self:ApplyPanel(self.secondary, db.secondEnabled, db.secondWidth, db.secondHeight, db.secondCount, db.secondSlots)

    local minimapWidth = Minimap and Minimap:GetWidth() or 140
    self.minimap:ClearAllPoints()
    if Minimap then
        if db.minimapPosition == "TOP" then
            self.minimap:SetPoint("BOTTOM", Minimap, "TOP", 0, 0)
        else
            self.minimap:SetPoint("TOP", Minimap, "BOTTOM", 0, 0)
        end
    else
        self.minimap:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -180)
    end
    self:ApplyPanel(self.minimap, db.minimapEnabled, minimapWidth, db.minimapHeight, db.minimapCount, db.minimapSlots)
    self:Update()
end

function module:SetLocked(locked)
    for _, panel in ipairs(self.panels) do
        if panel:IsShown() then
            if FUI.db.dataPanels.border then
                panel:SetBackdropBorderColor(locked and 0.11 or 1, locked and 0.46 or 0.72, locked and 1 or 0.12, 1)
            end
        end
    end
end

function module:Initialize()
    self:RegisterProviders()
    self.primary = self:CreatePanel("FlowdiUI_DataPanel", "dataPanel", 5)
    self.secondary = self:CreatePanel("FlowdiUI_DataPanel2", "dataPanel2", 5)
    self.minimap = self:CreatePanel("FlowdiUI_MinimapDataPanel", nil, 2)

    local updater = CreateFrame("Frame")
    for _, event in ipairs({
        "BAG_UPDATE_DELAYED", "PLAYER_MONEY", "UPDATE_INVENTORY_DURABILITY", "PLAYER_EQUIPMENT_CHANGED",
        "FRIENDLIST_UPDATE", "BN_FRIEND_ACCOUNT_ONLINE", "BN_FRIEND_ACCOUNT_OFFLINE", "GUILD_ROSTER_UPDATE",
        "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD", "PLAYER_XP_UPDATE", "UPDATE_FACTION", "UPDATE_PENDING_MAIL",
    }) do updater:RegisterEvent(event) end
    updater:SetScript("OnEvent", function() module:Update() end)
    local elapsed = 0
    updater:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed >= 1 then elapsed = 0 module:Update() end
    end)
    self:Apply()
end

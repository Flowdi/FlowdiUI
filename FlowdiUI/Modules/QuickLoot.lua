local _, ns = ...
local FUI = ns.FUI

local module = {
    rows = {},
    activeEntries = {},
    quickSession = false,
}
FUI:RegisterModule("quickLoot", module)

local function AutoLootIsActive()
    local enabled
    if GetCVarBool then enabled = GetCVarBool("autoLootDefault") end
    if enabled == nil and GetCVar then enabled = GetCVar("autoLootDefault") == "1" end
    enabled = enabled and true or false
    local toggled = IsModifiedClick and IsModifiedClick("AUTOLOOTTOGGLE") or false
    return enabled ~= (toggled and true or false)
end

local function ItemIconFromMessage(message)
    local link = message and message:match("(|c%x+|Hitem:.-|h.-|h|r)")
    if not link then link = message and message:match("(|Hitem:.-|h.-|h)") end
    if not link then return "Interface\\Icons\\INV_Misc_Bag_08" end
    if GetItemInfoInstant then
        local icon = select(5, GetItemInfoInstant(link))
        if icon then return icon end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

function module:CreateFeed()
    if self.feed then return end
    local feed = CreateFrame("Frame", "FlowdiUI_LootFeed", UIParent)
    feed:SetFrameStrata("HIGH")
    feed:SetClampedToScreen(true)
    feed:EnableMouse(false)
    self.feed = feed
    FUI:RestorePosition(feed, "lootFeed")
    FUI:RegisterMover(feed, "lootFeed", "Loot Feed")
    FUI.movers.lootFeed.shouldShow = function()
        return FUI.db.quickLoot.enabled and FUI.db.quickLoot.feedEnabled
    end
end

function module:AcquireRow(index)
    if self.rows[index] then return self.rows[index] end
    local row = CreateFrame("Frame", nil, self.feed, "BackdropTemplate")
    row:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    row:SetBackdropColor(0.008, 0.016, 0.035, 0.9)
    row:SetBackdropBorderColor(0.08, 0.36, 0.7, 0.95)
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", 3, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.icon = icon
    local text = FUI:CreateFont(row, 11)
    text:SetPoint("LEFT", icon, "RIGHT", 7, 0)
    text:SetPoint("RIGHT", row, "RIGHT", -7, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    row.text = text
    row:Hide()
    self.rows[index] = row
    return row
end

function module:LayoutFeed()
    if not self.feed then return end
    local db = FUI.db.quickLoot
    local iconSize = db.feedIconSize or 22
    local rows = db.feedRows or 6
    local rowHeight = iconSize + 6
    self.feed:SetSize(285, rows * (rowHeight + 3))
    FUI:RestorePosition(self.feed, "lootFeed")
    for index = 1, rows do
        local row = self:AcquireRow(index)
        row:SetSize(285, rowHeight)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.feed, "TOPLEFT", 0, -(index - 1) * (rowHeight + 3))
        row.icon:SetSize(iconSize, iconSize)
    end
    for index = rows + 1, #self.rows do self.rows[index]:Hide() end
    local mover = FUI.movers and FUI.movers.lootFeed
    if mover then FUI:SyncMoverOverlay(mover) end
end

function module:AddFeedMessage(message, icon)
    local db = FUI.db.quickLoot
    if not db.enabled or not db.feedEnabled or not message or message == "" then return end
    table.insert(self.activeEntries, 1, {
        message = message,
        icon = icon or ItemIconFromMessage(message),
        created = GetTime(),
    })
    while #self.activeEntries > (db.feedRows or 6) do table.remove(self.activeEntries) end
    self:RefreshFeed()
end

function module:RefreshFeed()
    if not self.feed then return end
    local db = FUI.db.quickLoot
    local now = GetTime()
    local duration = db.feedDuration or 4
    for index = #self.activeEntries, 1, -1 do
        if now - self.activeEntries[index].created >= duration then table.remove(self.activeEntries, index) end
    end
    for index = 1, (db.feedRows or 6) do
        local row = self:AcquireRow(index)
        local entry = self.activeEntries[index]
        if entry and db.enabled and db.feedEnabled then
            local age = now - entry.created
            local fadeStart = math.max(0, duration - 0.7)
            local alpha = age > fadeStart and math.max(0, (duration - age) / math.max(0.1, duration - fadeStart)) or 1
            row.icon:SetTexture(entry.icon)
            row.text:SetText(entry.message)
            row:SetAlpha(alpha)
            row:Show()
        else
            row:Hide()
        end
    end
end

function module:LootAllSlots()
    if not self.quickSession or not FUI.db.quickLoot.enabled then return end
    local count = GetNumLootItems and GetNumLootItems() or 0
    for slot = count, 1, -1 do
        local hasItem = not LootSlotHasItem or LootSlotHasItem(slot)
        if hasItem then pcall(LootSlot, slot) end
    end
end

function module:HideLootWindow()
    if not self.quickSession or not FUI.db.quickLoot.hideLootWindow or not LootFrame then return end
    LootFrame:SetAlpha(0)
    LootFrame:Hide()
end

function module:BeginQuickLoot()
    self.quickSession = FUI.db.quickLoot.enabled and AutoLootIsActive()
    if not self.quickSession then
        if LootFrame then LootFrame:SetAlpha(1) end
        return
    end
    self:HideLootWindow()
    self:LootAllSlots()
    C_Timer.After(0, function() module:HideLootWindow() module:LootAllSlots() end)
    C_Timer.After(0.03, function() module:HideLootWindow() module:LootAllSlots() end)
    C_Timer.After(0.08, function()
        module:HideLootWindow()
        module:LootAllSlots()
        local remaining = false
        local count = GetNumLootItems and GetNumLootItems() or 0
        for slot = 1, count do
            if not LootSlotHasItem or LootSlotHasItem(slot) then remaining = true break end
        end
        if not remaining and CloseLoot then pcall(CloseLoot) end
    end)
end

function module:Apply()
    self:CreateFeed()
    self:LayoutFeed()
    self.feed:SetShown(FUI.db.quickLoot.enabled and FUI.db.quickLoot.feedEnabled and #self.activeEntries > 0)
    if not FUI.db.quickLoot.enabled and LootFrame then LootFrame:SetAlpha(1) end
end

function module:SetLocked(locked)
    if not locked then
        self.feed:Show()
    else
        self.feed:SetShown(FUI.db.quickLoot.enabled and FUI.db.quickLoot.feedEnabled and #self.activeEntries > 0)
    end
end

function module:Initialize()
    self:CreateFeed()
    self:LayoutFeed()
    local events = CreateFrame("Frame")
    events:RegisterEvent("LOOT_READY")
    events:RegisterEvent("LOOT_OPENED")
    events:RegisterEvent("LOOT_CLOSED")
    events:RegisterEvent("CHAT_MSG_LOOT")
    events:RegisterEvent("CHAT_MSG_MONEY")
    pcall(events.RegisterEvent, events, "CHAT_MSG_CURRENCY")
    events:SetScript("OnEvent", function(_, event, message)
        if event == "LOOT_READY" or event == "LOOT_OPENED" then
            module:BeginQuickLoot()
        elseif event == "LOOT_CLOSED" then
            module.quickSession = false
            if LootFrame then LootFrame:SetAlpha(1) end
        elseif event == "CHAT_MSG_LOOT" then
            module:AddFeedMessage(message, ItemIconFromMessage(message))
        elseif event == "CHAT_MSG_MONEY" then
            module:AddFeedMessage(message, "Interface\\Icons\\INV_Misc_Coin_01")
        elseif event == "CHAT_MSG_CURRENCY" then
            module:AddFeedMessage(message, "Interface\\Icons\\INV_Misc_Coin_02")
        end
    end)
    events:SetScript("OnUpdate", function(_, elapsed)
        module.elapsed = (module.elapsed or 0) + elapsed
        if module.elapsed >= 0.05 then
            module.elapsed = 0
            module:RefreshFeed()
            if module.feed and not (FUI.db.locked == false) then
                module.feed:SetShown(FUI.db.quickLoot.enabled and FUI.db.quickLoot.feedEnabled and #module.activeEntries > 0)
            end
        end
    end)
    self.events = events
    self:Apply()
end

local _, ns = ...
local FUI = ns.FUI

local module = {
    frames = {}, partyFrames = {}, partyPetFrames = {}, raidFrames = {}, raidPetFrames = {}, unitFrames = {},
}
FUI:RegisterModule("groupFrames", module)

local anchorPoints = {
    ["Top Left"] = "TOPLEFT", ["Top"] = "TOP", ["Top Right"] = "TOPRIGHT",
    ["Left"] = "LEFT", ["Center"] = "CENTER", ["Right"] = "RIGHT",
    ["Bottom Left"] = "BOTTOMLEFT", ["Bottom"] = "BOTTOM", ["Bottom Right"] = "BOTTOMRIGHT",
}

local function IsSecret(value) return issecretvalue and issecretvalue(value) end
local function SafeUnitFlag(callback, unit)
    local ok, value = pcall(callback, unit)
    if not ok or IsSecret(value) then return nil end
    return value and true or false
end
local function AuraNumber(value, fallback)
    if value == nil or IsSecret(value) then return fallback end
    local ok, number = pcall(tonumber, value)
    return ok and number or fallback
end
local function Profile(button)
    local db = FUI.db and FUI.db.groupFrames
    return db and db[button.profileKey]
end
local function UnitColor(unit, profile)
    if profile.healthColor == "Class" then
        local ok, _, class = pcall(UnitClass, unit)
        if ok and not IsSecret(class) and class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
            local color = RAID_CLASS_COLORS[class]
            return color.r, color.g, color.b
        end
    end
    local color = profile.customHealthColor or FUI.colors.health
    return color[1], color[2], color[3]
end

local function CollectAuras(unit, filter)
    local auras = {}
    if AuraUtil and AuraUtil.ForEachAura then
        local ok = pcall(AuraUtil.ForEachAura, unit, filter, 40, function(data)
            auras[#auras + 1] = {
                index = #auras + 1, name = data.name, spellId = data.spellId or data.spellID,
                icon = data.icon, applications = data.applications,
                duration = data.duration, expirationTime = data.expirationTime, dispelName = data.dispelName,
                sourceUnit = data.sourceUnit, isFromPlayerOrPlayerPet = data.isFromPlayerOrPlayerPet,
            }
        end, true)
        if ok then return auras end
        auras = {}
    end
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return auras end
    for index = 1, 40 do
        local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
        if not ok or not data then break end
        auras[#auras + 1] = {
            index = index, name = data.name, spellId = data.spellId or data.spellID,
            icon = data.icon, applications = data.applications,
            duration = data.duration, expirationTime = data.expirationTime, dispelName = data.dispelName,
            sourceUnit = data.sourceUnit, isFromPlayerOrPlayerPet = data.isFromPlayerOrPlayerPet,
        }
    end
    return auras
end

local function IsPlayerAura(aura)
    if aura.isFromPlayerOrPlayerPet ~= nil and not IsSecret(aura.isFromPlayerOrPlayerPet) then
        return aura.isFromPlayerOrPlayerPet == true
    end
    if not aura.sourceUnit or IsSecret(aura.sourceUnit) or not UnitIsUnit then return false end
    local ok, mine = pcall(UnitIsUnit, aura.sourceUnit, "player")
    if ok and mine then return true end
    ok, mine = pcall(UnitIsUnit, aura.sourceUnit, "pet")
    return ok and mine == true
end

local parsedFilterCache = {}
local function ParseSpellFilter(value)
    value = tostring(value or "")
    if parsedFilterCache[value] then return parsedFilterCache[value] end
    local result = { ids = {}, names = {} }
    for entry in value:gmatch("[^,;\n]+") do
        entry = entry:match("^%s*(.-)%s*$")
        local spellID = tonumber(entry)
        if spellID then result.ids[spellID] = true
        elseif entry ~= "" then result.names[entry:lower()] = true end
    end
    parsedFilterCache[value] = result
    return result
end

local function AuraMatchesFilter(aura, value)
    local filter = ParseSpellFilter(value)
    local spellID = not IsSecret(aura.spellId) and tonumber(aura.spellId) or nil
    if spellID and filter.ids[spellID] then return true end
    local name = not IsSecret(aura.name) and type(aura.name) == "string" and aura.name:lower() or nil
    return name and filter.names[name] == true or false
end

local _, playerClass = UnitClass("player")
local friendlyRangeSpells = {
    PRIEST = { 2061, 17, 139 }, PALADIN = { 19750, 20473, 633 },
    SHAMAN = { 8004, 1064, 331 }, DRUID = { 8936, 774, 5185 },
    MONK = { 116670, 124682, 115175 }, EVOKER = { 361469, 355913, 364343 },
}
local dispelTypes = {
    PRIEST = { Magic = true, Disease = true },
    PALADIN = { Magic = true, Poison = true, Disease = true },
    SHAMAN = { Magic = true, Curse = true },
    DRUID = { Magic = true, Curse = true, Poison = true },
    MONK = { Magic = true, Poison = true, Disease = true },
    EVOKER = { Magic = true, Poison = true },
    MAGE = { Curse = true },
}

local filterLayouts = {
    ["Top Left"] = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 2, y = -2, xDirection = 1, yDirection = -1 },
    ["Top Right"] = { point = "TOPRIGHT", relativePoint = "TOPRIGHT", x = -2, y = -2, xDirection = -1, yDirection = -1 },
    ["Bottom Left"] = { point = "BOTTOMLEFT", relativePoint = "BOTTOMLEFT", x = 2, y = 2, xDirection = 1, yDirection = 1 },
    ["Bottom Right"] = { point = "BOTTOMRIGHT", relativePoint = "BOTTOMRIGHT", x = -2, y = 2, xDirection = -1, yDirection = 1 },
    ["Center"] = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0, xDirection = 1, yDirection = -1 },
}

local function FilteredAuraPosition(profile, kind, aura)
    local filters = profile.auraFilters
    if not filters or filters.mode ~= "Essential" then return nil end
    if kind == "buff" then
        if AuraMatchesFilter(aura, filters.topLeftBuffs) then return "Top Left" end
        if AuraMatchesFilter(aura, filters.topRightBuffs) then return "Top Right" end
        return false
    end
    if AuraMatchesFilter(aura, filters.bottomLeftDebuffs) then return "Bottom Left" end
    if AuraMatchesFilter(aura, filters.centerDebuffs) then return "Center" end
    local dispelName = not IsSecret(aura.dispelName) and aura.dispelName or nil
    if filters.showDispellable and dispelName and dispelTypes[playerClass] and dispelTypes[playerClass][dispelName] then
        return "Bottom Right"
    end
    return false
end

local function FormatTime(seconds)
    if seconds >= 60 then return string.format("%dm", math.ceil(seconds / 60)) end
    if seconds >= 10 then return string.format("%d", math.ceil(seconds)) end
    return string.format("%.1f", math.max(0, seconds))
end

local function NativeCandidateFilters(profile, kind)
    local filters = profile.auraFilters
    if not filters or filters.mode ~= "Essential" then return nil end
    -- Dispellable debuffs cannot be selected by spell ID alone, so the native
    -- harmful container must retain the complete list when that mode is active.
    if kind == "debuff" and filters.showDispellable then return nil end
    local values = kind == "buff"
        and { filters.topLeftBuffs, filters.topRightBuffs }
        or { filters.bottomLeftDebuffs, filters.centerDebuffs }
    local include = {}
    for _, value in ipairs(values) do
        local parsed = ParseSpellFilter(value)
        for spellID in pairs(parsed.ids) do include[spellID] = true end
    end
    return next(include) and { includeSpellIDs = include } or nil
end

function module:CreateNativeAuras(button, kind)
    if button.isPet or not FUI.AuraEngine then return end
    button.nativeAuraQueued = button.nativeAuraQueued or {}
    if button.nativeAuraQueued[kind] then return end
    local profile = Profile(button)
    local settings = profile and profile.auras and profile.auras[kind]
    if not settings then return end
    local perRow = math.max(1, settings.perRow or 3)
    local maximum = profile.auraFilters and profile.auraFilters.mode == "Essential"
        and math.max(1, profile.auraFilters.maxIcons or 8)
        or perRow * math.max(1, settings.rows or 1)
    local unit = button.GetAttribute and button:GetAttribute("unit") or button.unit
    button.nativeAuraQueued[kind] = true
    FUI.AuraEngine:QueueCreate(function(container)
        button.nativeAuraQueued[kind] = nil
        if not container then return end
        button.nativeAuraContainers = button.nativeAuraContainers or {}
        button.nativeAuraContainers[kind] = container
        FUI.AuraEngine:SetUnit(container, button.GetAttribute and button:GetAttribute("unit") or button.unit, true)
        module:UpdateAuras(button, kind, true)
    end, button, unit or button.unit, kind, settings, "groupFrames",
        button:GetFrameLevel() + 25, button, maximum)
end

function module:EnsureNativeAuras(button)
    if button.isPet then return end
    button.nativeAuraContainers = button.nativeAuraContainers or {}
    for _, kind in ipairs({ "buff", "debuff" }) do
        if not button.nativeAuraContainers[kind] then self:CreateNativeAuras(button, kind) end
    end
end

function module:BindNativeAuras(button, refresh)
    local unit = button.GetAttribute and button:GetAttribute("unit") or button.unit
    unit = unit or button.unit or "none"
    for _, container in pairs(button.nativeAuraContainers or {}) do
        FUI.AuraEngine:SetUnit(container, unit, refresh)
    end
end

function module:CreateAuraButton(button, kind, index)
    local auraButton = CreateFrame("Button", nil, button, "BackdropTemplate")
    auraButton:SetFrameLevel(button:GetFrameLevel() + 20)
    auraButton:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    auraButton.icon = auraButton:CreateTexture(nil, "ARTWORK")
    auraButton.icon:SetPoint("TOPLEFT", 1, -1)
    auraButton.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    auraButton.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    auraButton.cooldown = CreateFrame("Cooldown", nil, auraButton, "CooldownFrameTemplate")
    auraButton.cooldown:SetAllPoints(auraButton.icon)
    if auraButton.cooldown.SetDrawEdge then auraButton.cooldown:SetDrawEdge(false) end
    if auraButton.cooldown.SetHideCountdownNumbers then auraButton.cooldown:SetHideCountdownNumbers(true) end
    auraButton.durationText = FUI:CreateFont(auraButton, 8)
    auraButton.durationText:SetPoint("BOTTOM", 0, 1)
    auraButton.stackText = FUI:CreateFont(auraButton, 8)
    auraButton.stackText:SetPoint("TOPRIGHT", -1, -1)
    auraButton:SetScript("OnEnter", function(self)
        local profile = Profile(button)
        local settings = profile and profile.auras[kind]
        if not settings or not settings.tooltip or settings.clickThrough or not self.auraIndex or not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if GameTooltip.SetUnitAura then pcall(GameTooltip.SetUnitAura, GameTooltip, button.unit, self.auraIndex, self.auraFilter) end
        GameTooltip:Show()
    end)
    auraButton:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    auraButton:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.15 then return end
        self.elapsed = 0
        local expiration = AuraNumber(self.expirationTime, 0)
        if self.showDuration and expiration > 0 then
            local remaining = expiration - GetTime()
            self.durationText:SetText(remaining > 0 and FormatTime(remaining) or "")
        else self.durationText:SetText("") end
    end)
    button.auraButtons[kind][index] = auraButton
    return auraButton
end

function module:UpdateAuras(button, kind, configure)
    local profile = Profile(button)
    local settings = profile and profile.auras and profile.auras[kind]
    local buttons = button.auraButtons[kind]
    for _, auraButton in ipairs(buttons) do auraButton:Hide() end
    local nativeContainer = button.nativeAuraContainers and button.nativeAuraContainers[kind]
    if nativeContainer then
        nativeContainer:SetShown(not button.isPet)
        return
    end
    if button.nativeAuraQueued and button.nativeAuraQueued[kind] then return end
    -- The provider owns combat-safe aura payloads. Do not enter the legacy
    -- addon-side iterator when a native build is pending or failed.
    do
        self:EnsureNativeAuras(button)
        return
    end
    if button.isPet or not settings or not settings.enabled then return end
    local filter = kind == "buff" and "HELPFUL" or "HARMFUL"
    if settings.mineOnly then filter = filter .. "|PLAYER" end
    local auras = CollectAuras(button.unit, filter)
    local perRow = math.max(1, settings.perRow or 3)
    local essentialFilters = profile.auraFilters and profile.auraFilters.mode == "Essential"
    local maximum = essentialFilters and math.max(1, profile.auraFilters.maxIcons or 8) or perRow * math.max(1, settings.rows or 1)
    local size, spacing = settings.size or 14, settings.spacing or 1
    local point = anchorPoints[settings.point] or "TOPRIGHT"
    local relativePoint = anchorPoints[settings.relativePoint] or "TOPRIGHT"
    local xDirection = settings.growthX == "Left" and -1 or 1
    local yDirection = settings.growthY == "Down" and -1 or 1
    local shown = 0
    local positionCounts = {}
    for _, aura in ipairs(auras) do
        local duration = AuraNumber(aura.duration, 0)
        local sourceAllowed = not settings.mineOnly or filter:find("PLAYER", 1, true) ~= nil or IsPlayerAura(aura)
        local filteredPosition = FilteredAuraPosition(profile, kind, aura)
        if sourceAllowed and filteredPosition ~= false and ((settings.maxDuration or 0) <= 0 or duration <= (settings.maxDuration or 0)) then
            shown = shown + 1
            if shown > maximum then break end
            local auraButton = buttons[shown] or self:CreateAuraButton(button, kind, shown)
            local placement = filteredPosition and filterLayouts[filteredPosition]
            local positionIndex = shown
            if placement then
                positionCounts[filteredPosition] = (positionCounts[filteredPosition] or 0) + 1
                positionIndex = positionCounts[filteredPosition]
            end
            local column, row = (positionIndex - 1) % perRow, math.floor((positionIndex - 1) / perRow)
            auraButton:ClearAllPoints()
            auraButton:SetPoint(placement and placement.point or point, button, placement and placement.relativePoint or relativePoint,
                (placement and placement.x or settings.x or 0) + column * (size + spacing) * (placement and placement.xDirection or xDirection),
                (placement and placement.y or settings.y or 0) + row * (size + spacing) * (placement and placement.yDirection or yDirection))
            auraButton:SetSize(size, size)
            auraButton:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = settings.borderSize or 1 })
            local border = FUI.colors.border
            if kind == "debuff" and DebuffTypeColor then
                local dispelName = IsSecret(aura.dispelName) and "none" or aura.dispelName
                border = DebuffTypeColor[dispelName or "none"] or DebuffTypeColor.none or border
            end
            auraButton:SetBackdropBorderColor(border.r or border[1], border.g or border[2], border.b or border[3], 1)
            auraButton.icon:SetTexture(aura.icon)
            if auraButton.icon.SetDesaturated then auraButton.icon:SetDesaturated(settings.desaturate == true) end
            auraButton.auraIndex, auraButton.auraFilter = aura.index, filter
            auraButton.expirationTime, auraButton.showDuration = aura.expirationTime, settings.showDuration
            auraButton:EnableMouse(not settings.clickThrough)
            auraButton.durationText:SetFont(FUI:GetModuleFontPath("groupFrames"), settings.durationSize or 8, FUI.db.global.fontOutline)
            auraButton.stackText:SetFont(FUI:GetModuleFontPath("groupFrames"), settings.stackSize or 8, FUI.db.global.fontOutline)
            local applications = AuraNumber(aura.applications, 0)
            auraButton.stackText:SetText(settings.showStacks and applications > 1 and applications or "")
            local expiration = AuraNumber(aura.expirationTime, 0)
            if settings.cooldown and duration > 0 and expiration > 0 then
                auraButton.cooldown:Show()
                pcall(auraButton.cooldown.SetCooldown, auraButton.cooldown, expiration - duration, duration)
            else auraButton.cooldown:Hide() end
            auraButton:Show()
        end
    end
end

function module:UpdateIndicators(button)
    local profile = Profile(button)
    if not profile then return end
    local marker = GetRaidTargetIndex(button.unit)
    if profile.showRaidMarker and marker then
        if IsSecret(marker) and button.raidMarker.SetSpriteSheetCell then
            pcall(button.raidMarker.SetSpriteSheetCell, button.raidMarker, marker, 4, 4, 64, 64)
        else
            pcall(SetRaidTargetIconTexture, button.raidMarker, marker)
        end
        button.raidMarker:Show()
    else button.raidMarker:Hide() end
    button.leader:SetShown(not button.isPet and profile.showLeader and SafeUnitFlag(UnitIsGroupLeader, button.unit) == true)
    local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(button.unit) or "NONE"
    if IsSecret(role) then role = "NONE" end
    button.role:SetText(not button.isPet and profile.showRole and role and role ~= "NONE" and role:sub(1, 1) or "")
    local ready = GetReadyCheckStatus and GetReadyCheckStatus(button.unit)
    local textures = {
        ready = "Interface\\RaidFrame\\ReadyCheck-Ready",
        notready = "Interface\\RaidFrame\\ReadyCheck-NotReady",
        waiting = "Interface\\RaidFrame\\ReadyCheck-Waiting",
    }
    if not button.isPet and profile.showReadyCheck and ready and textures[ready] then
        button.ready:SetTexture(textures[ready])
        button.ready:Show()
    else button.ready:Hide() end
end

function module:UpdateRange(button)
    local profile = Profile(button)
    if not profile then return end
    local isSelf = button.unit == "player"
    if not isSelf and UnitIsUnit then
        local ok, sameUnit = pcall(UnitIsUnit, button.unit, "player")
        isSelf = ok and not IsSecret(sameUnit) and sameUnit == true
    end
    if isSelf then
        button:SetAlpha(1)
        return
    end
    if (profile.rangeFriendly or profile.rangeIndicator) and C_Spell and C_Spell.IsSpellInRange and button.SetAlphaFromBoolean then
        for _, spellID in ipairs(friendlyRangeSpells[playerClass] or {}) do
            local inRange = C_Spell.IsSpellInRange(spellID, button.unit)
            if IsSecret(inRange) or inRange ~= nil then
                button:SetAlphaFromBoolean(inRange, 1, profile.outOfRangeAlpha or 0.40)
                return
            end
        end
    end
    if (profile.rangeFriendly or profile.rangeIndicator) and not FUI:IsUnitInConfiguredRange(button.unit, true, false) then
        button:SetAlpha(profile.outOfRangeAlpha or 0.40)
    else
        button:SetAlpha(1)
    end
end

function module:UpdateButton(button)
    local exists = SafeUnitFlag(UnitExists, button.unit)
    if exists == false then return end
    local profile = Profile(button)
    if not profile then return end
    pcall(button.health.SetMinMaxValues, button.health, 0, UnitHealthMax(button.unit))
    pcall(button.health.SetValue, button.health, UnitHealth(button.unit))
    local r, g, b = UnitColor(button.unit, profile)
    button.health:SetStatusBarColor(r, g, b, profile.healthOpacity or 1)
    pcall(button.name.SetText, button.name, profile.showName and UnitName(button.unit) or "")
    pcall(button.power.SetMinMaxValues, button.power, 0, UnitPowerMax(button.unit))
    pcall(button.power.SetValue, button.power, UnitPower(button.unit))
    if profile.showHealthPercent then
        pcall(function()
            if UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100 then
                button.healthText:SetFormattedText("%d%%", UnitHealthPercent(button.unit, true, CurveConstants.ScaleTo100))
            else
                local maximum = UnitHealthMax(button.unit)
                button.healthText:SetFormattedText("%d%%", maximum > 0 and UnitHealth(button.unit) / maximum * 100 or 0)
            end
        end)
    else button.healthText:SetText("") end
    local dead, connected = SafeUnitFlag(UnitIsDeadOrGhost, button.unit), SafeUnitFlag(UnitIsConnected, button.unit)
    if dead == true then button.state:SetText("DEAD") button.state:Show()
    elseif connected == false then button.state:SetText("OFF") button.state:Show()
    else button.state:Hide() end
    self:UpdateIndicators(button)
    self:UpdateRange(button)
end

function module:CreateButton(parent, unit, profileKey, isPet)
    local frameName = "FlowdiUI_Group_" .. unit:gsub("[^%w]", "")
    local button = CreateFrame("Button", frameName, parent, "SecureUnitButtonTemplate")
    button:SetAttribute("unit", unit)
    button:SetAttribute("type1", "target")
    button:SetAttribute("type2", "togglemenu")
    button:RegisterForClicks("AnyUp")
    button.unit, button.profileKey, button.isPet = unit, profileKey, isPet == true
    RegisterUnitWatch(button)
    button.unitWatchEnabled = true
    if button.SetClipsChildren then button:SetClipsChildren(false) end
    FUI:CreateBackdrop(button, 1)
    button.health = CreateFrame("StatusBar", nil, button)
    button.health:SetStatusBarTexture(FUI:GetStatusBarTexture(false))
    button.healthBG = button.health:CreateTexture(nil, "BACKGROUND")
    button.healthBG:SetAllPoints()
    button.power = CreateFrame("StatusBar", nil, button)
    button.power:SetStatusBarTexture(FUI:GetStatusBarTexture(true))
    button.power:SetStatusBarColor(unpack(FUI.colors.power))
    button.name = FUI:CreateFont(button.health, 10)
    button.name:SetJustifyH("LEFT")
    button.healthText = FUI:CreateFont(button.health, 9)
    button.healthText:SetJustifyH("RIGHT")
    button.state = FUI:CreateFont(button.health, 9)
    button.state:SetPoint("CENTER")
    button.state:SetTextColor(1, 0.35, 0.35)
    button.raidMarker = button:CreateTexture(nil, "OVERLAY", nil, 7)
    button.raidMarker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    button.raidMarker:SetSize(16, 16)
    button.raidMarker:SetPoint("TOP", 0, 5)
    button.leader = button:CreateTexture(nil, "OVERLAY", nil, 7)
    button.leader:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    button.leader:SetSize(12, 12)
    button.leader:SetPoint("TOPLEFT", -3, 3)
    button.role = FUI:CreateFont(button, 9)
    button.role:SetPoint("BOTTOMLEFT", 3, 2)
    button.role:SetTextColor(1, 0.82, 0.25)
    button.ready = button:CreateTexture(nil, "OVERLAY", nil, 7)
    button.ready:SetSize(16, 16)
    button.ready:SetPoint("CENTER")
    button.externalAuraAnchor = CreateFrame("Frame", frameName .. "_AuraAnchor", button)
    button.externalAuraAnchor:SetAllPoints(button)
    button.externalAuraAnchor:SetFrameLevel(button:GetFrameLevel() + 40)
    button.externalAuraAnchor:EnableMouse(false)
    if button.externalAuraAnchor.SetClipsChildren then button.externalAuraAnchor:SetClipsChildren(false) end
    button.FlowdiAuraAnchor = button.externalAuraAnchor
    button.auraButtons = { buff = {}, debuff = {} }
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(0.15, 0.5, 1, 0.14)
    button:SetScript("OnEnter", function(self)
        local profile = Profile(self)
        if profile and profile.hoverBorder then self.FlowdiBackdrop:SetBackdropBorderColor(0.35, 0.75, 1, 1) end
    end)
    button:SetScript("OnLeave", function(self) self.FlowdiBackdrop:SetBackdropBorderColor(unpack(FUI.colors.border)) end)
    for _, event in ipairs({
        "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_NAME_UPDATE", "UNIT_CONNECTION",
        "UNIT_AURA", "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD", "RAID_TARGET_UPDATE", "PLAYER_ROLES_ASSIGNED",
        "READY_CHECK", "READY_CHECK_CONFIRM", "READY_CHECK_FINISHED",
    }) do button:RegisterEvent(event) end
    button:SetScript("OnEvent", function(self, event, eventUnit)
        if not eventUnit or eventUnit == self.unit or event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
            if event == "PLAYER_ENTERING_WORLD" then
                module.worldReady = true
                module:EnsureNativeAuras(self)
                module:UpdateAuras(self, "buff")
                module:UpdateAuras(self, "debuff")
            end
            if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then module:BindNativeAuras(self, true) end
            module:UpdateButton(self)
        end
    end)
    button:SetScript("OnUpdate", function(self, elapsed)
        self.rangeElapsed = (self.rangeElapsed or 0) + elapsed
        if self.rangeElapsed < 0.20 then return end
        self.rangeElapsed = 0
        module:UpdateRange(self)
    end)
    self.frames[#self.frames + 1] = button
    self.unitFrames[unit] = button
    return button
end

function module:GetGroupUnitFrame(unit)
    return self.unitFrames[unit]
end

local function HideBlizzardGroupFrames()
    for _, frameName in ipairs({ "CompactPartyFrame", "CompactRaidFrameManager", "CompactRaidFrameContainer", "PartyFrame" }) do
        local frame = _G[frameName]
        if frame then
            frame:SetAlpha(0)
            if frame.EnableMouse then frame:EnableMouse(false) end
            if frame.HookScript and not frame.FlowdiHiddenHook then
                frame.FlowdiHiddenHook = true
                frame:HookScript("OnShow", function(self) self:SetAlpha(0) end)
            end
        end
    end
end

function module:CreatePartyFrames()
    local container = CreateFrame("Frame", "FlowdiUI_Party", UIParent, "SecureHandlerStateTemplate")
    FUI:RestorePosition(container, "party")
    FUI:MakeMovable(container, "party")
    self.party = container
    self.partyFrames[1] = self:CreateButton(container, "player", "party")
    self.partyPetFrames[1] = self:CreateButton(container, "pet", "party", true)
    for index = 1, 4 do self.partyFrames[index + 1] = self:CreateButton(container, "party" .. index, "party") end
    for index = 1, 4 do self.partyPetFrames[index + 1] = self:CreateButton(container, "partypet" .. index, "party", true) end
end

function module:CreateRaidFrames()
    local container = CreateFrame("Frame", "FlowdiUI_Raid", UIParent, "SecureHandlerStateTemplate")
    FUI:RestorePosition(container, "raid")
    FUI:MakeMovable(container, "raid")
    self.raid = container
    for index = 1, 40 do self.raidFrames[index] = self:CreateButton(container, "raid" .. index, "raid") end
    for index = 1, 40 do self.raidPetFrames[index] = self:CreateButton(container, "raidpet" .. index, "raid", true) end
end

function module:ApplyButton(button, profile)
    local frameHeight = button.isPet and (profile.petHeight or 14) or profile.height
    local powerHeight = button.isPet and 0 or math.max(0, profile.powerHeight or 0)
    button:SetSize(profile.width, frameHeight)
    button.health:ClearAllPoints()
    button.health:SetPoint("TOPLEFT", 1, -1)
    button.health:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, powerHeight > 0 and powerHeight + 2 or 1)
    button.power:ClearAllPoints()
    button.power:SetPoint("BOTTOMLEFT", 1, 1)
    button.power:SetPoint("BOTTOMRIGHT", -1, 1)
    button.power:SetHeight(powerHeight)
    button.power:SetShown(powerHeight > 0)
    button.health:SetStatusBarTexture(FUI:GetStatusBarTexture(false))
    button.power:SetStatusBarTexture(FUI:GetStatusBarTexture(true))
    local background = profile.healthBackground or { 0.025, 0.04, 0.055, 0.96 }
    button.healthBG:SetColorTexture(background[1], background[2], background[3], background[4] or 1)
    button.power:SetAlpha(profile.powerOpacity or 1)
    button.FlowdiBackdrop:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = profile.borderSize or 1 })
    button.FlowdiBackdrop:SetBackdropColor(0.01, 0.015, 0.025, 0.95)
    button.FlowdiBackdrop:SetBackdropBorderColor(unpack(FUI.colors.border))
    button.name:ClearAllPoints()
    button.name:SetPoint("LEFT", button.health, "LEFT", 4, 0)
    button.name:SetPoint("RIGHT", button.health, "CENTER", 12, 0)
    button.healthText:ClearAllPoints()
    button.healthText:SetPoint("RIGHT", button.health, "RIGHT", -4, 0)
    local fontSize = button.isPet and math.max(7, profile.fontSize - 2) or profile.fontSize
    button.name:SetFont(FUI:GetModuleFontPath("groupFrames"), fontSize, FUI.db.global.fontOutline)
    button.healthText:SetFont(FUI:GetModuleFontPath("groupFrames"), math.max(7, fontSize - 1), FUI.db.global.fontOutline)
    self:EnsureNativeAuras(button)
    self:BindNativeAuras(button, true)
    self:UpdateButton(button)
    self:UpdateAuras(button, "buff", true)
    self:UpdateAuras(button, "debuff", true)
end

function module:LayoutFrames(container, frames, petFrames, profile, isParty)
    local visibleFrames = {}
    local petShouldShow = {}
    for index, button in ipairs(frames) do
        local show = not isParty or index > 1 or profile.showSelf
        if isParty and index == 1 then
            if show and not button.unitWatchEnabled then RegisterUnitWatch(button) button.unitWatchEnabled = true
            elseif not show and button.unitWatchEnabled then UnregisterUnitWatch(button) button.unitWatchEnabled = false button:Hide() end
        end
        petShouldShow[index] = show and profile.showPets
        if show then visibleFrames[#visibleFrames + 1] = { button = button, index = index } end
    end
    local perColumn
    if isParty and profile.orientation == "Horizontal" then perColumn = 1
    elseif isParty then perColumn = #visibleFrames
    else perColumn = math.max(1, math.min(profile.unitsPerColumn or 5, #visibleFrames)) end
    local columns = math.max(1, math.ceil(#visibleFrames / perColumn))
    local rows = math.min(perColumn, #visibleFrames)
    local petExtra = profile.showPets and ((profile.petHeight or 14) + (profile.petSpacing or 1)) or 0
    local stackHeight = profile.height + petExtra
    container:SetSize(columns * profile.width + math.max(0, columns - 1) * ((profile.spacing or 0) + (profile.groupSpacing or 0)),
        rows * stackHeight + math.max(0, rows - 1) * (profile.spacing or 0))
    for index, pet in ipairs(petFrames) do
        if not petShouldShow[index] and pet.unitWatchEnabled then
            UnregisterUnitWatch(pet)
            pet.unitWatchEnabled = false
            pet:Hide()
        elseif petShouldShow[index] and not pet.unitWatchEnabled then
            RegisterUnitWatch(pet)
            pet.unitWatchEnabled = true
        end
    end
    for displayIndex, entry in ipairs(visibleFrames) do
        local button, pet = entry.button, petFrames[entry.index]
        self:ApplyButton(button, profile)
        local column = math.floor((displayIndex - 1) / perColumn)
        local row = (displayIndex - 1) % perColumn
        if profile.growthX == "Left" then column = columns - 1 - column end
        if profile.growthY == "Up" then row = rows - 1 - row end
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", container, "TOPLEFT",
            column * (profile.width + (profile.spacing or 0) + (profile.groupSpacing or 0)),
            -row * (stackHeight + (profile.spacing or 0)))
        if pet and profile.showPets then
            self:ApplyButton(pet, profile)
            pet:ClearAllPoints()
            pet:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -(profile.petSpacing or 1))
        end
    end
end

function module:SetLocked(locked)
    for _, button in ipairs(self.frames) do
        button.FlowdiBackdrop:SetBackdropBorderColor(locked and 0.07 or 1, locked and 0.22 or 0.72, locked and 0.42 or 0.12, 1)
    end
end

function module:Apply()
    if InCombatLockdown() then return end
    local db = FUI.db.groupFrames
    local party, raid = db.party, db.raid
    self.party:SetScale((FUI.db.scale or 1) * party.scale)
    self.raid:SetScale((FUI.db.scale or 1) * raid.scale)
    self:LayoutFrames(self.party, self.partyFrames, self.partyPetFrames, party, true)
    self:LayoutFrames(self.raid, self.raidFrames, self.raidPetFrames, raid, false)
    UnregisterStateDriver(self.party, "visibility")
    UnregisterStateDriver(self.raid, "visibility")
    if party.enabled then
        RegisterStateDriver(self.party, "visibility", party.showWhenSolo and "[group:raid] hide; [group:party] show; show" or "[group:raid] hide; [group:party] show; hide")
    else self.party:Hide() end
    if raid.enabled then RegisterStateDriver(self.raid, "visibility", "[group:raid] show; hide") else self.raid:Hide() end
end

function module:Initialize()
    self:CreatePartyFrames()
    self:CreateRaidFrames()
    HideBlizzardGroupFrames()
    self:Apply()
end

function FUI:GetGroupUnitFrame(unit)
    return module.unitFrames[unit]
end

function FUI:GetUnitFrame(unit)
    local unitModule = self.modules and self.modules.unitFrames
    local unitFrame = unitModule and unitModule.frames and unitModule.frames[unit] or nil
    return unitFrame or module.unitFrames[unit]
end

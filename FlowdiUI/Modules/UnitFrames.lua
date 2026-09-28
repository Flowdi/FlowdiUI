local _, ns = ...
local FUI = ns.FUI

local module = { frames = {} }
FUI:RegisterModule("unitFrames", module)

local anchorPoints = {
    ["Top Left"] = "TOPLEFT", ["Top"] = "TOP", ["Top Right"] = "TOPRIGHT",
    ["Left"] = "LEFT", ["Center"] = "CENTER", ["Right"] = "RIGHT",
    ["Bottom Left"] = "BOTTOMLEFT", ["Bottom"] = "BOTTOM", ["Bottom Right"] = "BOTTOMRIGHT",
}
local unitLabels = {
    player = "Player", target = "Target", focus = "Focus", pet = "Pet",
    targettarget = "Target of Target", targettargettarget = "Target of Target of Target",
}
local _, playerClass = UnitClass("player")
local friendlyRangeSpells = {
    PRIEST = 2061, PALADIN = 19750, SHAMAN = 8004,
    DRUID = 8936, MONK = 116670, EVOKER = 361469,
}

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function SafeCall(callback, ...)
    local ok, a, b, c = pcall(callback, ...)
    if not ok or IsSecret(a) or IsSecret(b) or IsSecret(c) then return nil end
    return a, b, c
end

local function SetUnitText(font, kind, unit)
    if not font then return end
    local ok = pcall(function()
        if kind == "None" then
            font:SetText("")
        elseif kind == "Name" then
            font:SetText(UnitName(unit))
        elseif kind == "Level + Name" then
            font:SetFormattedText("%d %s", UnitLevel(unit), UnitName(unit))
        elseif kind == "Health %" then
            if UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100 then
                font:SetFormattedText("%d%%", UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
            else
                local current, maximum = UnitHealth(unit), UnitHealthMax(unit)
                font:SetFormattedText("%d%%", maximum > 0 and current / maximum * 100 or 0)
            end
        elseif kind == "Health" then
            font:SetFormattedText("%d", UnitHealth(unit))
        elseif kind == "Health / Max" then
            font:SetFormattedText("%d / %d", UnitHealth(unit), UnitHealthMax(unit))
        elseif kind == "Power %" then
            if UnitPowerPercent and CurveConstants and CurveConstants.ScaleTo100 then
                font:SetFormattedText("%d%%", UnitPowerPercent(unit, UnitPowerType(unit), true, CurveConstants.ScaleTo100))
            else
                local current, maximum = UnitPower(unit), UnitPowerMax(unit)
                font:SetFormattedText("%d%%", maximum > 0 and current / maximum * 100 or 0)
            end
        elseif kind == "Power" then
            font:SetFormattedText("%d", UnitPower(unit))
        else
            font:SetText("")
        end
    end)
    if not ok then pcall(font.SetText, font, "") end
end

local function FrameSettings(unit)
    local db = FUI.db and FUI.db.unitFrames
    return db and db.frames and db.frames[unit]
end

local function SetHealthColor(frame, settings)
    local color = settings.customHealthColor or FUI.colors.health
    if settings.healthColor == "Class" then
        local _, class = SafeCall(UnitClass, frame.unit)
        if class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then color = RAID_CLASS_COLORS[class] end
    end
    frame.health:SetStatusBarColor(color.r or color[1], color.g or color[2], color.b or color[3], settings.healthOpacity or 1)
end

local function SetPowerColor(frame, settings)
    local color = settings.customPowerColor or FUI.colors.power
    if settings.powerColor == "Power Type" then
        local powerType, token = SafeCall(UnitPowerType, frame.unit)
        local candidate = PowerBarColor and (PowerBarColor[token] or PowerBarColor[powerType])
        if candidate then color = candidate end
    end
    frame.power:SetStatusBarColor(color.r or color[1], color.g or color[2], color.b or color[3], settings.powerOpacity or 1)
end

function module:UpdateVisibility(frame)
    local settings = FrameSettings(frame.unit)
    if not settings then return end
    local mode = settings.visibility or "Always"
    local visible = settings.enabled ~= false
    if visible then
        if mode == "Solo" then visible = not IsInGroup()
        elseif mode == "Party" then visible = IsInGroup() and not IsInRaid()
        elseif mode == "Raid" then visible = IsInRaid()
        elseif mode == "In Combat" then visible = InCombatLockdown()
        end
    end
    local alpha = visible and 1 or 0
    local friendlyRange = settings.rangeFriendly
    local hostileRange = settings.rangeHostile
    if friendlyRange == nil and settings.rangeIndicator then friendlyRange = true end
    if visible then
        local isSelf = frame.unit == "player"
        if not isSelf and UnitIsUnit then
            local ok, sameUnit = pcall(UnitIsUnit, frame.unit, "player")
            isSelf = ok and not IsSecret(sameUnit) and sameUnit == true
        end
        if isSelf then
            frame:SetAlpha(1)
            return
        end
    end
    if visible and friendlyRange and UnitInRange and frame.SetAlphaFromBoolean then
        local inRange = UnitInRange(frame.unit)
        if IsSecret(inRange) or inRange ~= nil then
            frame:SetAlphaFromBoolean(inRange, 1, settings.outOfRangeAlpha or 0.40)
            return
        end
    end
    if visible and friendlyRange and C_Spell and C_Spell.IsSpellInRange and frame.SetAlphaFromBoolean then
        local spellID = friendlyRangeSpells[playerClass]
        local canAssist = UnitCanAssist and UnitCanAssist("player", frame.unit)
        if spellID and not IsSecret(canAssist) and canAssist == true then
            local inRange = C_Spell.IsSpellInRange(spellID, frame.unit)
            if IsSecret(inRange) or inRange ~= nil then
                frame:SetAlphaFromBoolean(inRange, 1, settings.outOfRangeAlpha or 0.40)
                return
            end
        end
    end
    if visible and frame.unit ~= "player" and not FUI:IsUnitInConfiguredRange(frame.unit, friendlyRange, hostileRange) then
        alpha = settings.outOfRangeAlpha or 0.40
    end
    frame:SetAlpha(alpha)
end

function module:UpdateCast(frame)
    local settings = FrameSettings(frame.unit)
    if not settings or not settings.showCastbar or (frame.unit == "player" and settings.castbarProvider ~= "FlowdiUI") then
        frame.castbar:Hide()
        return
    end
    local ok, cast = pcall(function()
        local name, text, texture, startTime, endTime, _, _, notInterruptible = UnitCastingInfo(frame.unit)
        local channeling = false
        if not name then
            name, text, texture, startTime, endTime, _, notInterruptible = UnitChannelInfo(frame.unit)
            channeling = name and true or false
        end
        if not name then return nil end
        return { name = name, texture = texture, startTime = startTime, endTime = endTime, channeling = channeling, locked = notInterruptible }
    end)
    if not ok or not cast then
        if not FUI.db.locked then
            frame.castbar.preview = true
            frame.castbar.startTime, frame.castbar.endTime = nil, nil
            frame.castbar:SetMinMaxValues(0, 1)
            frame.castbar:SetValue(0.62)
            frame.castName:SetText((unitLabels[frame.unit] or frame.unit:gsub("^%l", string.upper)) .. " Cast Bar")
            frame.castTime:SetText("1.5")
            frame.castbar:Show()
        else
            frame.castbar:Hide()
        end
        return
    end
    local rendered = pcall(function()
        frame.castbar.preview = false
        frame.castbar.startTime = cast.startTime
        frame.castbar.endTime = cast.endTime
        frame.castbar.channeling = cast.channeling
        frame.castbar:SetMinMaxValues(cast.startTime, cast.endTime)
        frame.castbar:SetValue(cast.channeling and cast.endTime or cast.startTime)
        frame.castName:SetText(cast.name)
        frame.castIcon:SetTexture(cast.texture)
        frame.castbar:SetStatusBarColor(cast.locked and 0.45 or settings.castColor[1], cast.locked and 0.45 or settings.castColor[2], cast.locked and 0.45 or settings.castColor[3], settings.castOpacity)
    end)
    frame.castbar:SetShown(rendered)
end

function module:UpdateIndicators(frame)
    local settings = FrameSettings(frame.unit)
    if not settings then return end
    local marker = GetRaidTargetIndex(frame.unit)
    if settings.raidMarker and marker then
        frame.raidMarker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
        if IsSecret(marker) and frame.raidMarker.SetSpriteSheetCell then
            pcall(frame.raidMarker.SetSpriteSheetCell, frame.raidMarker, marker, 4, 4, 64, 64)
        else
            pcall(SetRaidTargetIconTexture, frame.raidMarker, marker)
        end
        frame.raidMarker:Show()
    else
        frame.raidMarker:Hide()
    end
    local leader = SafeCall(UnitIsGroupLeader, frame.unit)
    frame.leaderIndicator:SetShown(settings.leaderIndicator and leader == true)
    local combat = SafeCall(UnitAffectingCombat, frame.unit)
    frame.combatIndicator:SetShown(settings.combatIndicator and combat == true)
end

function module:UpdateHealPrediction(frame)
    local settings = FrameSettings(frame.unit)
    local calculator = frame.healPredictionCalculator
    if not settings or not settings.healPrediction or not calculator or not UnitGetDetailedHealPrediction then
        frame.healPredictionMine:Hide()
        frame.healPredictionOther:Hide()
        return
    end
    local ok = pcall(function()
        UnitGetDetailedHealPrediction(frame.unit, "player", calculator)
        local _, mine, others = calculator:GetIncomingHeals()
        local maximum = UnitHealthMax(frame.unit)
        frame.healPredictionMine:SetMinMaxValues(0, maximum)
        frame.healPredictionOther:SetMinMaxValues(0, maximum)
        if settings.healPredictionMine then frame.healPredictionMine:SetValue(mine)
        else frame.healPredictionMine:SetValue(0) end
        if settings.healPredictionOthers then frame.healPredictionOther:SetValue(others)
        else frame.healPredictionOther:SetValue(0) end
    end)
    frame.healPredictionMine:SetShown(ok and settings.healPredictionMine)
    frame.healPredictionOther:SetShown(ok and settings.healPredictionOthers)
end

local function AuraNumber(value, fallback)
    if value == nil or IsSecret(value) then return fallback end
    local ok, number = pcall(tonumber, value)
    return ok and number or fallback
end

local function ReadAura(unit, index, filter)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
        if ok and data then
            return {
                index = index,
                name = data.name,
                icon = data.icon,
                applications = data.applications,
                dispelName = data.dispelName,
                duration = data.duration,
                expirationTime = data.expirationTime,
                spellId = data.spellId,
                sourceUnit = data.sourceUnit,
                isFromPlayerOrPlayerPet = data.isFromPlayerOrPlayerPet,
            }
        end
    end
    local api = UnitAura
    if not api then api = filter:find("HELPFUL", 1, true) and UnitBuff or UnitDebuff end
    if not api then return nil end
    local values = { pcall(api, unit, index, filter) }
    if not values[1] or values[2] == nil then return nil end
    return {
        index = index,
        name = values[2],
        icon = values[3],
        applications = values[4],
        dispelName = values[5],
        duration = values[6],
        expirationTime = values[7],
        sourceUnit = values[8],
        spellId = values[11],
    }
end

local function CollectAuras(unit, filter)
    local auras = {}
    if AuraUtil and AuraUtil.ForEachAura then
        local ok = pcall(AuraUtil.ForEachAura, unit, filter, 80, function(data)
            auras[#auras + 1] = {
                index = #auras + 1,
                name = data.name,
                icon = data.icon,
                applications = data.applications,
                dispelName = data.dispelName,
                duration = data.duration,
                expirationTime = data.expirationTime,
                spellId = data.spellId,
                sourceUnit = data.sourceUnit,
                isFromPlayerOrPlayerPet = data.isFromPlayerOrPlayerPet,
            }
        end, true)
        if ok then return auras end
        auras = {}
    end
    for index = 1, 80 do
        local aura = ReadAura(unit, index, filter)
        if not aura then break end
        auras[#auras + 1] = aura
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

local function FormatAuraTime(seconds)
    if seconds >= 3600 then return string.format("%dh", math.ceil(seconds / 3600)) end
    if seconds >= 60 then return string.format("%dm", math.ceil(seconds / 60)) end
    if seconds >= 10 then return string.format("%d", math.ceil(seconds)) end
    return string.format("%.1f", math.max(0, seconds))
end

local function ApplyAuraTextPosition(text, position)
    local point = anchorPoints[position] or "CENTER"
    local x = point:find("LEFT", 1, true) and 2 or point:find("RIGHT", 1, true) and -2 or 0
    local y = point:find("TOP", 1, true) and -1 or point:find("BOTTOM", 1, true) and 1 or 0
    text:ClearAllPoints()
    text:SetPoint(point, x, y)
    text:SetJustifyH(point:find("LEFT", 1, true) and "LEFT" or point:find("RIGHT", 1, true) and "RIGHT" or "CENTER")
end

local nativeAuraGroups = { buff = "Buffs", debuff = "Debuffs" }

function module:CreateNativeAuras(frame, kind)
    if not C_AddOns then return end
    pcall(C_AddOns.LoadAddOn, "Blizzard_AuraContainer")
    local settings = FrameSettings(frame.unit)
    local auraSettings = settings and settings.auras and settings.auras[kind]
    if not auraSettings then return end
    local targets = { ["Frame"] = frame, ["Health Bar"] = frame.health, ["Power Bar"] = frame.power, ["Portrait"] = frame.portrait }
    local target = targets[auraSettings.attachTo] or frame
    local anchor = CreateFrame("Frame", nil, frame)
    anchor:SetSize(1, 1)
    anchor:SetFrameLevel(frame:GetFrameLevel() + 30)
    anchor:SetPoint("CENTER", target, anchorPoints[auraSettings.relativePoint] or "TOPRIGHT", auraSettings.x or 0, auraSettings.y or 3)
    if anchor.SetClipsChildren then anchor:SetClipsChildren(false) end
    local ok, container = pcall(CreateFrame, "AuraContainer", nil, anchor, "CustomAuraContainerTemplate, DisableUntrustedLayoutScriptsTemplate")
    if not ok or not container or not container.AddAuraGroup then return end
    container:SetSize(1, 1)
    container:SetPoint(anchorPoints[auraSettings.point] or "BOTTOMRIGHT", anchor, "CENTER", 0, 0)
    container:SetFrameLevel(anchor:GetFrameLevel() + 1)
    if container.SetClipsChildren then container:SetClipsChildren(false) end
    container.buttons = {}
    local maximum = math.max(1, auraSettings.perRow or 8) * math.max(1, auraSettings.rows or 1)
    local baseFilter = kind == "buff" and "HELPFUL" or "HARMFUL"
    local filter = auraSettings.mineOnly and (baseFilter .. "|PLAYER") or baseFilter
    local groupKey = nativeAuraGroups[kind]
    local added = pcall(container.AddAuraGroup, container, groupKey, filter, {
        maxFrameCount = maximum,
        layout = {
            elementWidth = auraSettings.size or 22,
            elementHeight = auraSettings.size or 22,
            elementSpacing = auraSettings.spacing or 2,
            lineSpacing = auraSettings.spacing or 2,
        },
        initializeFrame = function(button)
            if button.SetMouseClickEnabled then pcall(button.SetMouseClickEnabled, button, false)
            else button:EnableMouse(false) end
            local border = button:CreateTexture(nil, "BACKGROUND")
            border:SetAllPoints(button)
            border:SetColorTexture(0.01, 0.015, 0.025, 1)
            local icon = button:CreateTexture(nil, "ARTWORK")
            local borderSize = math.max(0, auraSettings.borderSize or 1)
            icon:SetPoint("TOPLEFT", borderSize, -borderSize)
            icon:SetPoint("BOTTOMRIGHT", -borderSize, borderSize)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            if icon.SetDesaturated then icon:SetDesaturated(auraSettings.desaturate == true) end
            local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
            cooldown:SetAllPoints(button)
            if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
            if cooldown.SetHideCountdownNumbers then cooldown:SetHideCountdownNumbers(true) end
            cooldown:SetShown(auraSettings.cooldown ~= false)
            local textLayer = CreateFrame("Frame", nil, button)
            textLayer:SetAllPoints(button)
            textLayer:SetFrameLevel(cooldown:GetFrameLevel() + 2)
            textLayer:EnableMouse(false)
            local duration = FUI:CreateFont(textLayer, auraSettings.durationSize or 9)
            ApplyAuraTextPosition(duration, auraSettings.durationPosition)
            duration:SetAlpha(auraSettings.showDuration and 1 or 0)
            local stacks = FUI:CreateFont(textLayer, auraSettings.stackSize or 10)
            ApplyAuraTextPosition(stacks, auraSettings.stackPosition)
            stacks:SetAlpha(auraSettings.showStacks and 1 or 0)
            button:SetIcon(icon)
            button:SetDurationCooldown(cooldown)
            button:SetApplicationCount(stacks, {})
            pcall(button.SetDurationText, button, duration, {})
            container.buttons[#container.buttons + 1] = {
                button = button, border = border, icon = icon, cooldown = cooldown,
                duration = duration, stacks = stacks,
            }
        end,
    })
    if not added then return end
    local setAnchor = container.SetFlowLayoutAnchorPoint or container.SetAuraLayoutAnchorPoint
    if setAnchor then pcall(setAnchor, container, anchorPoints[auraSettings.point] or "BOTTOMRIGHT") end
    local setLine = container.SetFlowLayoutMaximumLineSize or container.SetAuraLayoutRowWidth
    if setLine then pcall(setLine, container, math.max(1, auraSettings.perRow or 8) * ((auraSettings.size or 22) + (auraSettings.spacing or 2))) end
    local directions = AnchorUtil and AnchorUtil.FlowDirection
    local setGrowth = container.SetFlowLayoutGrowthDirection or container.SetAuraLayoutGrowthDirection
    if directions and setGrowth then
        local horizontal = auraSettings.growthX == "Left" and directions.Left or directions.Right
        local vertical = auraSettings.growthY == "Down" and directions.Down or directions.Up
        pcall(setGrowth, container, horizontal, vertical)
    end
    anchor:SetShown(auraSettings.enabled == true)
    container:SetUnit(frame.unit)
    if container.UpdateAllAuras then container:UpdateAllAuras() end
    frame.nativeAuraAnchors = frame.nativeAuraAnchors or {}
    frame.nativeAuraContainers = frame.nativeAuraContainers or {}
    frame.nativeAuraAnchors[kind] = anchor
    frame.nativeAuraContainers[kind] = container
end

function module:ApplyNativeAuras(frame, kind, auraSettings, configure)
    local container = frame.nativeAuraContainers and frame.nativeAuraContainers[kind]
    local anchor = frame.nativeAuraAnchors and frame.nativeAuraAnchors[kind]
    if not container or not anchor or not auraSettings then return false end
    local enabled = auraSettings.enabled == true
    if not configure then return true end
    local targets = { ["Frame"] = frame, ["Health Bar"] = frame.health, ["Power Bar"] = frame.power, ["Portrait"] = frame.portrait }
    local target = targets[auraSettings.attachTo] or frame
    anchor:ClearAllPoints()
    anchor:SetPoint("CENTER", target, anchorPoints[auraSettings.relativePoint] or "TOPRIGHT", auraSettings.x or 0, auraSettings.y or 3)
    anchor:SetShown(enabled)
    return true
end

function module:CreateAuraButton(frame, kind, index)
    local holder = frame.auraHolders[kind]
    local button = CreateFrame("Button", nil, holder, "BackdropTemplate")
    button:SetFrameLevel(holder:GetFrameLevel() + 1)
    button:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    button:SetBackdropColor(0.01, 0.015, 0.025, 0.98)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 2, -2)
    button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints(button.icon)
    if button.cooldown.SetDrawEdge then button.cooldown:SetDrawEdge(false) end
    if button.cooldown.SetHideCountdownNumbers then button.cooldown:SetHideCountdownNumbers(true) end
    button.durationText = FUI:CreateFont(button, 9)
    button.stackText = FUI:CreateFont(button, 10)
    button:SetScript("OnEnter", function(self)
        local settings = FrameSettings(frame.unit)
        local auraSettings = settings and settings.auras and settings.auras[kind]
        if not auraSettings or not auraSettings.tooltip or auraSettings.clickThrough or not self.auraIndex or not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local shown = false
        if GameTooltip.SetUnitAura then shown = pcall(GameTooltip.SetUnitAura, GameTooltip, frame.unit, self.auraIndex, self.auraFilter) end
        if not shown then
            local tooltipMethod = kind == "buff" and GameTooltip.SetUnitBuff or GameTooltip.SetUnitDebuff
            if tooltipMethod then pcall(tooltipMethod, GameTooltip, frame.unit, self.auraIndex, self.auraFilter) end
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    button:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.1 then return end
        self.elapsed = 0
        local expiration = AuraNumber(self.expirationTime, 0)
        if self.showDuration and expiration > 0 then
            local remaining = expiration - GetTime()
            if remaining > 0 then self.durationText:SetText(FormatAuraTime(remaining))
            else self.durationText:SetText("") end
        else
            self.durationText:SetText("")
        end
    end)
    holder.buttons[index] = button
    return button
end

local function AuraSortValue(aura, sortBy)
    if sortBy == "Name" then
        if IsSecret(aura.name) then return "" end
        return tostring(aura.name or "")
    elseif sortBy == "Duration" then
        return AuraNumber(aura.duration, 0)
    elseif sortBy == "Time Remaining" then
        local expiration = AuraNumber(aura.expirationTime, 0)
        return expiration > 0 and expiration - GetTime() or 1000000000
    end
    return aura.index
end

function module:UpdateAuras(frame, kind, configure)
    local settings = FrameSettings(frame.unit)
    local auraSettings = settings and settings.auras and settings.auras[kind]
    local holder = frame.auraHolders and frame.auraHolders[kind]
    if not auraSettings or not holder then return end
    if self:ApplyNativeAuras(frame, kind, auraSettings, configure) then
        for _, button in ipairs(holder.buttons) do button:Hide() end
        return
    end
    for _, button in ipairs(holder.buttons) do button:Hide() end
    if not auraSettings.enabled then return end

    local filter = kind == "buff" and "HELPFUL" or "HARMFUL"
    local auras = CollectAuras(frame.unit, filter)
    if auraSettings.mineOnly then
        local mine = {}
        for _, aura in ipairs(auras) do
            if IsPlayerAura(aura) then mine[#mine + 1] = aura end
        end
        auras = mine
    end
    if auraSettings.sortBy ~= "Index" then
        pcall(table.sort, auras, function(a, b)
            local av, bv = AuraSortValue(a, auraSettings.sortBy), AuraSortValue(b, auraSettings.sortBy)
            if av == bv then return a.index < b.index end
            if auraSettings.sortDirection == "Descending" then return av > bv end
            return av < bv
        end)
    elseif auraSettings.sortDirection == "Descending" then
        local reversed = {}
        for index = #auras, 1, -1 do reversed[#reversed + 1] = auras[index] end
        auras = reversed
    end

    local targets = { ["Frame"] = frame, ["Health Bar"] = frame.health, ["Power Bar"] = frame.power, ["Portrait"] = frame.portrait }
    local target = targets[auraSettings.attachTo] or frame
    local point = anchorPoints[auraSettings.point] or "BOTTOMLEFT"
    local relativePoint = anchorPoints[auraSettings.relativePoint] or "TOPLEFT"
    local size = auraSettings.size or 22
    local spacing = auraSettings.spacing or 2
    local perRow = math.max(1, auraSettings.perRow or 8)
    local maximum = math.max(1, auraSettings.rows or 1) * perRow
    local xDirection = auraSettings.growthX == "Left" and -1 or 1
    local yDirection = auraSettings.growthY == "Down" and -1 or 1
    for displayIndex = 1, math.min(#auras, maximum) do
        local aura = auras[displayIndex]
        local button = holder.buttons[displayIndex] or self:CreateAuraButton(frame, kind, displayIndex)
        local column = (displayIndex - 1) % perRow
        local row = math.floor((displayIndex - 1) / perRow)
        button:ClearAllPoints()
        button:SetPoint(point, target, relativePoint,
            (auraSettings.x or 0) + column * (size + spacing) * xDirection,
            (auraSettings.y or 0) + row * (size + spacing) * yDirection)
        button:SetSize(size, size)
        button:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = auraSettings.borderSize or 1 })
        local border = FUI.colors.border
        if kind == "debuff" and DebuffTypeColor then
            local dispelName = IsSecret(aura.dispelName) and "none" or aura.dispelName
            border = DebuffTypeColor[dispelName or "none"] or DebuffTypeColor.none or border
        end
        button:SetBackdropBorderColor(border.r or border[1], border.g or border[2], border.b or border[3], 1)
        button.icon:SetTexture(aura.icon)
        if button.icon.SetDesaturated then button.icon:SetDesaturated(auraSettings.desaturate == true) end
        button.auraIndex, button.auraFilter = aura.index, filter
        button.expirationTime = aura.expirationTime
        button.showDuration = auraSettings.showDuration
        button:EnableMouse(not auraSettings.clickThrough)
        button.durationText:SetFont(FUI:GetModuleFontPath("unitFrames"), auraSettings.durationSize or 9, FUI.db.global.fontOutline)
        button.stackText:SetFont(FUI:GetModuleFontPath("unitFrames"), auraSettings.stackSize or 10, FUI.db.global.fontOutline)
        ApplyAuraTextPosition(button.durationText, auraSettings.durationPosition)
        ApplyAuraTextPosition(button.stackText, auraSettings.stackPosition)
        local applications = AuraNumber(aura.applications, 0)
        button.stackText:SetText(auraSettings.showStacks and applications > 1 and applications or "")
        local duration, expiration = AuraNumber(aura.duration, 0), AuraNumber(aura.expirationTime, 0)
        if auraSettings.cooldown and duration > 0 and expiration > 0 then
            button.cooldown:Show()
            pcall(button.cooldown.SetCooldown, button.cooldown, expiration - duration, duration)
        else
            button.cooldown:Hide()
        end
        button:Show()
    end
end

function module:UpdateFrame(frame)
    local unit = frame.unit
    local settings = FrameSettings(unit)
    local exists = SafeCall(UnitExists, unit)
    if not settings or exists == false then return end
    local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
    local power, maxPower = UnitPower(unit), UnitPowerMax(unit)
    pcall(frame.health.SetMinMaxValues, frame.health, 0, maxHealth)
    pcall(frame.health.SetValue, frame.health, health)
    pcall(frame.power.SetMinMaxValues, frame.power, 0, maxPower)
    pcall(frame.power.SetValue, frame.power, power)
    SetHealthColor(frame, settings)
    SetPowerColor(frame, settings)
    SetUnitText(frame.leftText, settings.leftText, unit)
    SetUnitText(frame.rightText, settings.rightText, unit)
    SetUnitText(frame.centerText, settings.centerText, unit)
    SetUnitText(frame.extraText, settings.extraText, unit)
    SetUnitText(frame.powerText, settings.powerText, unit)
    local dead, connected = SafeCall(UnitIsDeadOrGhost, unit), SafeCall(UnitIsConnected, unit)
    if dead == true then frame.state:SetText("DEAD") frame.state:Show()
    elseif connected == false then frame.state:SetText("OFFLINE") frame.state:Show()
    else frame.state:Hide() end
    if frame.portrait:IsShown() then pcall(SetPortraitTexture, frame.portrait, unit) end
    self:UpdateCast(frame)
    self:UpdateIndicators(frame)
    self:UpdateHealPrediction(frame)
    self:UpdateVisibility(frame)
end

local function CreateText(frame, anchor, justify)
    local text = FUI:CreateFont(frame.health, 12)
    text:SetPoint(anchor, frame.health, anchor, anchor == "LEFT" and 7 or anchor == "RIGHT" and -7 or 0, 0)
    text:SetJustifyH(justify or anchor)
    return text
end

function module:CreateUnitFrame(unit, positionKey)
    local frame = CreateFrame("Button", "FlowdiUI_" .. unit:gsub("^%l", string.upper), UIParent, "SecureUnitButtonTemplate")
    frame:SetSize(181, 54)
    frame:SetAttribute("unit", unit)
    frame:SetAttribute("type1", "target")
    frame:SetAttribute("type2", "togglemenu")
    frame:RegisterForClicks("AnyUp")
    frame.unit, frame.positionKey = unit, positionKey
    if frame.SetClipsChildren then frame:SetClipsChildren(false) end
    RegisterUnitWatch(frame)
    frame.unitWatchEnabled = true
    FUI:RestorePosition(frame, positionKey)
    FUI:CreateBackdrop(frame, 1)
    FUI:MakeMovable(frame, positionKey)

    frame.portrait = frame:CreateTexture(nil, "ARTWORK")
    frame.portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.health = CreateFrame("StatusBar", nil, frame)
    frame.health:SetStatusBarTexture(FUI:GetStatusBarTexture(false))
    frame.healthBG = frame:CreateTexture(nil, "BACKGROUND")
    frame.healPredictionClip = CreateFrame("Frame", nil, frame)
    frame.healPredictionClip:SetFrameLevel(frame:GetFrameLevel() + 10)
    if frame.healPredictionClip.SetClipsChildren then frame.healPredictionClip:SetClipsChildren(true) end
    frame.healPredictionMine = CreateFrame("StatusBar", nil, frame.healPredictionClip)
    frame.healPredictionOther = CreateFrame("StatusBar", nil, frame.healPredictionClip)
    frame.healPredictionMine:SetStatusBarTexture(FUI:GetStatusBarTexture(false))
    frame.healPredictionOther:SetStatusBarTexture(FUI:GetStatusBarTexture(false))
    frame.healPredictionMine:SetFrameLevel(frame.healPredictionClip:GetFrameLevel() + 1)
    frame.healPredictionOther:SetFrameLevel(frame.healPredictionClip:GetFrameLevel() + 2)
    frame.healPredictionMine:Hide()
    frame.healPredictionOther:Hide()
    if CreateUnitHealPredictionCalculator then
        frame.healPredictionCalculator = CreateUnitHealPredictionCalculator()
        local incomingModes = Enum and Enum.UnitIncomingHealClampMode
        if frame.healPredictionCalculator.SetIncomingHealClampMode and incomingModes then
            frame.healPredictionCalculator:SetIncomingHealClampMode(incomingModes.MaximumHealth)
        end
        local absorbModes = Enum and Enum.UnitHealAbsorbClampMode
        if frame.healPredictionCalculator.SetHealAbsorbClampMode and absorbModes then
            frame.healPredictionCalculator:SetHealAbsorbClampMode(absorbModes.MaximumHealth)
        end
    end
    frame.power = CreateFrame("StatusBar", nil, frame)
    frame.power:SetStatusBarTexture(FUI:GetStatusBarTexture(true))
    frame.powerBG = frame.power:CreateTexture(nil, "BACKGROUND")
    frame.powerBG:SetAllPoints()

    frame.castbar = CreateFrame("StatusBar", nil, UIParent)
    frame.castbar.owner = frame
    frame.castbar.positionKey = unit .. "Castbar"
    FUI:RegisterMover(frame.castbar, frame.castbar.positionKey, (unitLabels[unit] or unit:gsub("^%l", string.upper)) .. " Cast Bar", function()
        local settings = FrameSettings(unit)
        if settings then settings.castDetached = true end
    end)
    frame.castbar:SetMovable(true)
    frame.castbar:SetClampedToScreen(true)
    frame.castbar:RegisterForDrag("LeftButton")
    frame.castbar:SetScript("OnDragStart", function(self)
        if FUI.db.locked or InCombatLockdown() then return end
        local settings = FrameSettings(self.owner.unit)
        if settings then settings.castDetached = true end
        local centerX, centerY = self:GetCenter()
        if centerX and centerY then
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
        end
        self:StartMoving()
    end)
    frame.castbar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        FUI:SavePosition(self, self.positionKey)
    end)
    frame.castbar:SetStatusBarTexture(FUI:GetStatusBarTexture(false))
    FUI:CreateBackdrop(frame.castbar, 1)
    frame.castbarBG = frame.castbar:CreateTexture(nil, "BACKGROUND")
    frame.castbarBG:SetAllPoints()
    frame.castbarBG:SetColorTexture(0.025, 0.03, 0.045, 0.96)
    frame.castIcon = frame.castbar:CreateTexture(nil, "ARTWORK")
    frame.castIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.castName = FUI:CreateFont(frame.castbar, 10)
    frame.castName:SetPoint("LEFT", 5, 0)
    frame.castName:SetPoint("RIGHT", -42, 0)
    frame.castName:SetJustifyH("LEFT")
    frame.castTime = FUI:CreateFont(frame.castbar, 9)
    frame.castTime:SetPoint("RIGHT", -4, 0)
    frame.castbar:SetScript("OnUpdate", function(self)
        if not self.startTime or not self.endTime then return end
        pcall(function()
            local now = GetTime() * 1000
            local value = self.channeling and math.max(self.startTime, self.endTime - (now - self.startTime)) or math.min(self.endTime, now)
            self:SetValue(value)
            local settings = FrameSettings(frame.unit)
            local duration = settings and settings.castTimeFormat == "Elapsed" and math.max(0, now - self.startTime) or math.max(0, self.endTime - now)
            frame.castTime:SetText(string.format("%.1f", duration / 1000))
            if now >= self.endTime then self:Hide() end
        end)
    end)

    frame.indicatorLayer = CreateFrame("Frame", nil, frame)
    frame.indicatorLayer:SetAllPoints(frame)
    frame.indicatorLayer:SetFrameLevel(frame:GetFrameLevel() + 20)
    if frame.indicatorLayer.SetClipsChildren then frame.indicatorLayer:SetClipsChildren(false) end
    frame.raidMarker = frame.indicatorLayer:CreateTexture(nil, "OVERLAY", nil, 7)
    frame.raidMarker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
    frame.leaderIndicator = frame.indicatorLayer:CreateTexture(nil, "OVERLAY", nil, 7)
    frame.leaderIndicator:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
    frame.combatIndicator = frame.indicatorLayer:CreateTexture(nil, "OVERLAY", nil, 7)
    frame.combatIndicator:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
    frame.combatIndicator:SetTexCoord(0.5, 1, 0, 0.49)
    frame.combatIndicator:SetVertexColor(1, 1, 1, 1)

    frame.auraHolders = {}
    for _, kind in ipairs({ "buff", "debuff" }) do
        local holder = CreateFrame("Frame", nil, frame)
        holder:SetAllPoints(frame)
        holder:SetFrameLevel(frame:GetFrameLevel() + 30)
        if holder.SetClipsChildren then holder:SetClipsChildren(false) end
        holder.buttons = {}
        frame.auraHolders[kind] = holder
    end
    if unit ~= "pet" then
        self:CreateNativeAuras(frame, "buff")
        self:CreateNativeAuras(frame, "debuff")
    end

    frame.leftText = CreateText(frame, "LEFT", "LEFT")
    frame.rightText = CreateText(frame, "RIGHT", "RIGHT")
    frame.centerText = CreateText(frame, "CENTER", "CENTER")
    frame.extraText = FUI:CreateFont(frame.health, 11)
    frame.extraText:SetPoint("TOP", frame.health, "TOP", 0, -3)
    frame.powerText = FUI:CreateFont(frame.power, 9)
    frame.powerText:SetPoint("CENTER", frame.power)
    frame.state = FUI:CreateFont(frame.health, 10)
    frame.state:SetPoint("CENTER", frame.health)
    frame.state:SetTextColor(1, 0.35, 0.35)

    frame:SetScript("OnEnter", function(self)
        local settings = FrameSettings(self.unit)
        if settings and settings.hoverBorder then self.FlowdiBackdrop:SetBackdropBorderColor(0.3, 0.7, 1, 1) end
        if settings and settings.showTooltip and GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            pcall(GameTooltip.SetUnit, GameTooltip, self.unit)
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function(self)
        self.FlowdiBackdrop:SetBackdropBorderColor(unpack(FUI.colors.border))
        if GameTooltip then GameTooltip:Hide() end
    end)

    for _, event in ipairs({ "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
        "UNIT_NAME_UPDATE", "UNIT_CONNECTION", "UNIT_PORTRAIT_UPDATE", "UNIT_MODEL_CHANGED", "PLAYER_TARGET_CHANGED",
        "PLAYER_FOCUS_CHANGED", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "UNIT_TARGET", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
        "RAID_TARGET_UPDATE", "UNIT_HEAL_PREDICTION", "UNIT_AURA", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
        "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_CHANNEL_STOP" }) do
        frame:RegisterEvent(event)
    end
    frame:SetScript("OnEvent", function(self, event, eventUnit)
        if not eventUnit or eventUnit == self.unit or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" or event == "UNIT_TARGET" then
            module:UpdateFrame(self)
            if event == "UNIT_AURA" or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" or event == "PLAYER_ENTERING_WORLD" or event == "UNIT_TARGET" then
                module:UpdateAuras(self, "buff")
                module:UpdateAuras(self, "debuff")
            end
        end
    end)
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.rangeElapsed = (self.rangeElapsed or 0) + elapsed
        if self.rangeElapsed < 0.20 then return end
        self.rangeElapsed = 0
        module:UpdateVisibility(self)
    end)
    self.frames[unit] = frame
    return frame
end

local function HideBlizzardFrame(frame)
    if not frame then return end
    frame:SetAlpha(0)
    if frame.EnableMouse then frame:EnableMouse(false) end
    if frame.HookScript and not frame.FlowdiHiddenHook then
        frame.FlowdiHiddenHook = true
        frame:HookScript("OnShow", function(self) self:SetAlpha(0) end)
    end
end

function module:HideDefaults()
    HideBlizzardFrame(PlayerFrame)
    HideBlizzardFrame(TargetFrame)
    HideBlizzardFrame(FocusFrame)
    HideBlizzardFrame(PetFrame)
end

function module:ApplyPlayerCastbarProvider()
    local settings = FrameSettings("player")
    local useBlizzard = settings and settings.castbarProvider ~= "FlowdiUI"
    if not self.hiddenCastbarParent then
        self.hiddenCastbarParent = CreateFrame("Frame", nil, UIParent)
        self.hiddenCastbarParent:Hide()
    end
    local hiddenParent = self.hiddenCastbarParent
    local seen = {}
    for _, frameName in ipairs({ "PlayerCastingBarFrame", "CastingBarFrame" }) do
        local castbar = _G[frameName]
        if castbar and not seen[castbar] then
            seen[castbar] = true
            castbar.FlowdiOriginalParent = castbar.FlowdiOriginalParent or castbar:GetParent() or UIParent
            if not InCombatLockdown() then
                castbar:SetParent(useBlizzard and castbar.FlowdiOriginalParent or hiddenParent)
                if not useBlizzard then castbar:Hide() end
            end
            castbar:SetAlpha(useBlizzard and 1 or 0)
            if castbar.EnableMouse then castbar:EnableMouse(useBlizzard) end
            if not castbar.FlowdiProviderHook then
                castbar.FlowdiProviderHook = true
                castbar:HookScript("OnShow", function(self)
                    local playerSettings = FrameSettings("player")
                    local native = playerSettings and playerSettings.castbarProvider ~= "FlowdiUI"
                    self:SetAlpha(native and 1 or 0)
                    if self.EnableMouse and not InCombatLockdown() then self:EnableMouse(native) end
                    if not native and not InCombatLockdown() then
                        self:SetParent(hiddenParent)
                        self:Hide()
                    end
                end)
                if hooksecurefunc and castbar.SetParent then
                    hooksecurefunc(castbar, "SetParent", function(self, parent)
                        local playerSettings = FrameSettings("player")
                        if playerSettings and playerSettings.castbarProvider == "FlowdiUI" and parent ~= hiddenParent and not InCombatLockdown() then
                            C_Timer.After(0, function()
                                local current = FrameSettings("player")
                                if current and current.castbarProvider == "FlowdiUI" and not InCombatLockdown() then
                                    self:SetParent(hiddenParent)
                                    self:SetAlpha(0)
                                    self:Hide()
                                end
                            end)
                        end
                    end)
                end
            end
        end
    end
end

function module:SetLocked(locked)
    for _, frame in pairs(self.frames) do
        if locked then frame.FlowdiBackdrop:SetBackdropBorderColor(unpack(FUI.colors.border))
        else frame.FlowdiBackdrop:SetBackdropBorderColor(1, 0.72, 0.12, 1) end
        if frame.castbar.FlowdiBackdrop then
            if locked then frame.castbar.FlowdiBackdrop:SetBackdropBorderColor(unpack(FUI.colors.border))
            else frame.castbar.FlowdiBackdrop:SetBackdropBorderColor(1, 0.72, 0.12, 1) end
        end
        frame.castbar:EnableMouse(not locked)
        self:UpdateCast(frame)
    end
end

local function TexturePath(settings)
    if settings.texture == "Global" then return FUI:GetStatusBarTexture(false) end
    return FUI.textures[settings.texture] or FUI:GetStatusBarTexture(false)
end

local function ApplyIndicatorLayout(frame, texture, settings, prefix)
    local targets = {
        ["Frame"] = frame,
        ["Health Bar"] = frame.health,
        ["Power Bar"] = frame.power,
        ["Portrait"] = frame.portrait,
    }
    local target = targets[settings[prefix .. "AttachTo"]] or frame
    local point = anchorPoints[settings[prefix .. "Point"]] or "CENTER"
    local relativePoint = anchorPoints[settings[prefix .. "RelativePoint"]] or "CENTER"
    texture:ClearAllPoints()
    texture:SetPoint(point, target, relativePoint, settings[prefix .. "X"] or 0, settings[prefix .. "Y"] or 0)
end

local function ApplyCastText(font, castbar, position, inset)
    font:ClearAllPoints()
    if position == "Hidden" then font:Hide() return end
    font:Show()
    local point = anchorPoints[position] or string.upper(position or "LEFT")
    if point ~= "LEFT" and point ~= "CENTER" and point ~= "RIGHT" then point = "LEFT" end
    font:SetPoint(point, castbar, point, point == "LEFT" and inset or point == "RIGHT" and -inset or 0, 0)
    font:SetJustifyH(point)
end

local function ApplyCastLayout(frame, settings)
    local castbar = frame.castbar
    castbar:SetParent(UIParent)
    castbar:ClearAllPoints()
    if settings.castDetached then
        FUI:RestorePosition(castbar, castbar.positionKey)
    else
        local targets = {
            ["Frame"] = frame,
            ["Health Bar"] = frame.health,
            ["Power Bar"] = frame.power,
            ["Portrait"] = frame.portrait,
        }
        local target = targets[settings.castAttachTo] or frame
        local point = anchorPoints[settings.castPoint] or "TOPLEFT"
        local relativePoint = anchorPoints[settings.castRelativePoint] or "BOTTOMLEFT"
        castbar:SetPoint(point, target, relativePoint, settings.castX or 0, settings.castY or -3)
    end
    castbar:SetSize(settings.castWidth or 220, settings.castHeight)
    castbar:SetScale((FUI.db.scale or 1) * (FUI.db.unitFrames.scale or 1))
    castbar:SetFrameStrata(settings.castFrameStrata or "MEDIUM")
    if castbar.SetReverseFill then castbar:SetReverseFill(settings.castReverseFill == true) end
    castbar:SetStatusBarTexture(settings.castTexture == "Global" and FUI:GetStatusBarTexture(false) or FUI.textures[settings.castTexture] or FUI:GetStatusBarTexture(false))
    castbar:SetStatusBarColor(settings.castColor[1], settings.castColor[2], settings.castColor[3], settings.castOpacity)
    local background = settings.castBackground or { 0.025, 0.03, 0.045, 1 }
    frame.castbarBG:SetColorTexture(background[1], background[2], background[3], settings.castBackgroundOpacity or background[4] or 0.8)
    frame.castIcon:SetShown(settings.showCastIcon)
    frame.castIcon:ClearAllPoints()
    local iconPosition = settings.castIconPosition or "Left"
    if iconPosition == "Right" then frame.castIcon:SetPoint("LEFT", castbar, "RIGHT", 2, 0)
    else frame.castIcon:SetPoint("RIGHT", castbar, "LEFT", -2, 0) end
    frame.castIcon:SetSize(settings.castHeight, settings.castHeight)
    ApplyCastText(frame.castName, castbar, settings.castNamePosition or "Left", 5)
    ApplyCastText(frame.castTime, castbar, settings.castTimePosition or "Right", 5)
    frame.castName:SetFont(FUI:GetModuleFontPath("unitFrames"), settings.castTextSize or 10, FUI.db.global.fontOutline)
    frame.castTime:SetFont(FUI:GetModuleFontPath("unitFrames"), settings.castTextSize or 10, FUI.db.global.fontOutline)
    if castbar.FlowdiBackdrop then
        castbar.FlowdiBackdrop:SetBackdropColor(background[1], background[2], background[3], settings.castBackgroundOpacity or 0.8)
        castbar.FlowdiBackdrop:SetBackdropBorderColor(unpack(FUI.colors.border))
    end
end

function module:ApplyFrame(frame, settings)
    if settings.enabled == false and frame.unitWatchEnabled then
        UnregisterUnitWatch(frame)
        frame.unitWatchEnabled = false
        frame:Hide()
    elseif settings.enabled ~= false and not frame.unitWatchEnabled then
        RegisterUnitWatch(frame)
        frame.unitWatchEnabled = true
    end
    local portraitShown = settings.showPortrait and settings.portraitMode ~= "None"
    local portraitSize = portraitShown and settings.portraitSize or 0
    local powerShown = settings.powerPosition ~= "Hidden" and settings.powerHeight > 0
    local powerHeight, gap = powerShown and settings.powerHeight or 0, powerShown and 2 or 0
    local totalHeight = settings.healthHeight + powerHeight + gap
    local totalWidth = settings.width + (portraitShown and portraitSize + 2 or 0)
    frame:SetSize(totalWidth, totalHeight)
    frame:SetScale((FUI.db.scale or 1) * (FUI.db.unitFrames.scale or 1))
    frame:SetFrameStrata(settings.frameStrata or "MEDIUM")

    frame.portrait:ClearAllPoints()
    frame.portrait:SetShown(portraitShown)
    if portraitShown then
        frame.portrait:SetSize(portraitSize, totalHeight)
        frame.portrait:SetPoint(settings.portraitPosition == "Right" and "RIGHT" or "LEFT", frame)
    end
    local leftInset = portraitShown and settings.portraitPosition == "Left" and portraitSize + 2 or 1
    local rightInset = portraitShown and settings.portraitPosition == "Right" and portraitSize + 2 or 1
    frame.health:ClearAllPoints()
    frame.power:ClearAllPoints()
    if settings.powerPosition == "Above Health Bar" and powerShown then
        frame.power:SetPoint("TOPLEFT", frame, "TOPLEFT", leftInset, -1)
        frame.power:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -rightInset, -1)
        frame.power:SetHeight(powerHeight)
        frame.health:SetPoint("TOPLEFT", frame.power, "BOTTOMLEFT", 0, -gap)
        frame.health:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -rightInset, 1)
    else
        frame.health:SetPoint("TOPLEFT", frame, "TOPLEFT", leftInset, -1)
        frame.health:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -rightInset, -1)
        frame.health:SetHeight(settings.healthHeight)
        if powerShown then
            frame.power:SetPoint("TOPLEFT", frame.health, "BOTTOMLEFT", 0, -gap)
            frame.power:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -rightInset, 1)
        end
    end
    frame.power:SetShown(powerShown)
    frame.health:SetStatusBarTexture(TexturePath(settings))
    frame.power:SetStatusBarTexture(FUI:GetStatusBarTexture(true))
    local hb, pb = settings.healthBackground, settings.powerBackground
    frame.healthBG:ClearAllPoints()
    frame.healthBG:SetAllPoints(frame.health)
    frame.healthBG:SetColorTexture(hb[1], hb[2], hb[3], hb[4] or 1)
    frame.powerBG:SetColorTexture(pb[1], pb[2], pb[3], pb[4] or 1)
    frame.healPredictionClip:ClearAllPoints()
    frame.healPredictionClip:SetAllPoints(frame.health)
    frame.healPredictionMine:SetStatusBarTexture(TexturePath(settings))
    frame.healPredictionOther:SetStatusBarTexture(TexturePath(settings))
    local healthFill = frame.health:GetStatusBarTexture()
    local mineFill = frame.healPredictionMine:GetStatusBarTexture()
    frame.healPredictionMine:ClearAllPoints()
    frame.healPredictionMine:SetPoint("TOPLEFT", healthFill, "TOPRIGHT", 0, 0)
    frame.healPredictionMine:SetPoint("BOTTOMLEFT", healthFill, "BOTTOMRIGHT", 0, 0)
    frame.healPredictionMine:SetSize(settings.width, settings.healthHeight)
    frame.healPredictionOther:ClearAllPoints()
    frame.healPredictionOther:SetPoint("TOPLEFT", mineFill, "TOPRIGHT", 0, 0)
    frame.healPredictionOther:SetPoint("BOTTOMLEFT", mineFill, "BOTTOMRIGHT", 0, 0)
    frame.healPredictionOther:SetSize(settings.width, settings.healthHeight)
    local mineColor, otherColor = settings.healPredictionMineColor, settings.healPredictionOtherColor
    frame.healPredictionMine:SetStatusBarColor(mineColor[1], mineColor[2], mineColor[3], settings.healPredictionOpacity)
    frame.healPredictionOther:SetStatusBarColor(otherColor[1], otherColor[2], otherColor[3], settings.healPredictionOpacity)
    ApplyCastLayout(frame, settings)
    frame.raidMarker:SetSize(settings.raidMarkerSize, settings.raidMarkerSize)
    frame.leaderIndicator:SetSize(settings.leaderIndicatorSize, settings.leaderIndicatorSize)
    frame.combatIndicator:SetSize(settings.combatIndicatorSize, settings.combatIndicatorSize)
    ApplyIndicatorLayout(frame, frame.raidMarker, settings, "raidMarker")
    ApplyIndicatorLayout(frame, frame.leaderIndicator, settings, "leaderIndicator")
    ApplyIndicatorLayout(frame, frame.combatIndicator, settings, "combatIndicator")
    frame.FlowdiBackdrop:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = settings.borderSize or 1 })
    frame.FlowdiBackdrop:SetBackdropColor(0.01, 0.015, 0.025, 0.95)
    frame.FlowdiBackdrop:SetBackdropBorderColor(unpack(FUI.colors.border))
    for _, text in ipairs({ frame.leftText, frame.rightText, frame.centerText, frame.extraText }) do
        text:SetFont(FUI:GetModuleFontPath("unitFrames"), settings.textSize, FUI.db.global.fontOutline)
    end
    frame.powerText:SetFont(FUI:GetModuleFontPath("unitFrames"), math.max(8, settings.textSize - 2), FUI.db.global.fontOutline)
    self:UpdateAuras(frame, "buff", true)
    self:UpdateAuras(frame, "debuff", true)
    self:UpdateFrame(frame)
end

function module:Apply()
    if InCombatLockdown() then return end
    self:ApplyPlayerCastbarProvider()
    for unit, frame in pairs(self.frames) do
        local settings = FrameSettings(unit)
        if settings then self:ApplyFrame(frame, settings) end
    end
end

function module:Initialize()
    self:CreateUnitFrame("player", "player")
    self:CreateUnitFrame("pet", "pet")
    self:CreateUnitFrame("target", "target")
    self:CreateUnitFrame("targettarget", "targettarget")
    self:CreateUnitFrame("targettargettarget", "targettargettarget")
    self:CreateUnitFrame("focus", "focus")
    self:HideDefaults()
    self:Apply()
end

local _, ns = ...
local FUI = ns.FUI

-- All aura displays use Blizzard's 12.1 AuraContainer provider. Aura values can
-- become secret in combat, so addon-side UNIT_AURA iteration is not a valid
-- rendering path for unit or group frames anymore.
local engine = { containers = setmetatable({}, { __mode = "k" }) }
FUI.AuraEngine = engine

local buildQueue, buildHead, buildTail = {}, 1, 0
local worker = CreateFrame("Frame")
worker:Hide()
worker:SetScript("OnUpdate", function(self)
    local job = buildQueue[buildHead]
    if not job then
        buildQueue, buildHead, buildTail = {}, 1, 0
        self:Hide()
        return
    end
    buildQueue[buildHead] = nil
    buildHead = buildHead + 1
    local ok, message = pcall(job)
    if not ok and not engine.queueError then
        engine.queueError = true
        FUI:Print("Aura build queue failed: " .. tostring(message))
    end
end)

function engine:QueueCreate(callback, ...)
    local arguments = { ... }
    buildTail = buildTail + 1
    buildQueue[buildTail] = function()
        callback(engine:Create(unpack(arguments)))
    end
    worker:Show()
end

local anchorPoints = {
    ["Top Left"] = "TOPLEFT", ["Top"] = "TOP", ["Top Right"] = "TOPRIGHT",
    ["Left"] = "LEFT", ["Center"] = "CENTER", ["Right"] = "RIGHT",
    ["Bottom Left"] = "BOTTOMLEFT", ["Bottom"] = "BOTTOM", ["Bottom Right"] = "BOTTOMRIGHT",
}

local function ReportOnce(key, message)
    engine.reported = engine.reported or {}
    if engine.reported[key] then return end
    engine.reported[key] = true
    FUI:Print(message)
end

local function EnsureProvider()
    if not C_AddOns then return false end
    if not C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then
        local ok, loaded = pcall(C_AddOns.LoadAddOn, "Blizzard_AuraContainer")
        if not ok or loaded == false then
            ReportOnce("provider", "Aura provider could not be loaded.")
            return false
        end
    end
    return true
end

local function Direction(name, fallback)
    local directions = AnchorUtil and AnchorUtil.FlowDirection
    return directions and directions[name] or fallback
end

local function ApplyTextPosition(text, position)
    local point = anchorPoints[position] or "CENTER"
    local x = point:find("LEFT", 1, true) and 1 or point:find("RIGHT", 1, true) and -1 or 0
    local y = point:find("TOP", 1, true) and -1 or point:find("BOTTOM", 1, true) and 1 or 0
    text:ClearAllPoints()
    text:SetPoint(point, x, y)
    text:SetJustifyH(point:find("LEFT", 1, true) and "LEFT" or point:find("RIGHT", 1, true) and "RIGHT" or "CENTER")
end

local function CreateInitializer(settings, fontModule, records)
    return function(button)
        -- Create and style every region before registering it. Every Set* call
        -- immediately asks the provider to populate the region.
        -- Group layout dimensions do not size the physical AuraButton.
        button:SetSize(math.max(1, settings.size or 16), math.max(1, settings.size or 16))

        local border = button:CreateTexture(nil, "BACKGROUND")
        border:SetAllPoints(button)
        border:SetColorTexture(0.01, 0.015, 0.025, 1)

        local icon = button:CreateTexture(nil, "ARTWORK")
        local borderSize = math.max(0, settings.borderSize or 1)
        icon:SetPoint("TOPLEFT", borderSize, -borderSize)
        icon:SetPoint("BOTTOMRIGHT", -borderSize, borderSize)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        if icon.SetDesaturated then icon:SetDesaturated(settings.desaturate == true) end

        local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        cooldown:SetAllPoints(icon)
        if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
        if cooldown.SetHideCountdownNumbers then cooldown:SetHideCountdownNumbers(true) end
        cooldown:SetShown(settings.cooldown ~= false)

        local carrier = CreateFrame("Frame", nil, button)
        carrier:SetAllPoints(button)
        carrier:SetFrameLevel(cooldown:GetFrameLevel() + 2)
        carrier:EnableMouse(false)

        local stacks = FUI:CreateFont(carrier, settings.stackSize or 10)
        stacks:SetFont(FUI:GetModuleFontPath(fontModule), settings.stackSize or 10, FUI.db.global.fontOutline)
        ApplyTextPosition(stacks, settings.stackPosition or "Top Right")
        stacks:SetAlpha(settings.showStacks == false and 0 or 1)

        local duration = FUI:CreateFont(carrier, settings.durationSize or 9)
        duration:SetFont(FUI:GetModuleFontPath(fontModule), settings.durationSize or 9, FUI.db.global.fontOutline)
        ApplyTextPosition(duration, settings.durationPosition or "Bottom")
        duration:SetAlpha(settings.showDuration == false and 0 or 1)

        if button.SetMouseClickEnabled then pcall(button.SetMouseClickEnabled, button, false) end
        button:SetIcon(icon)
        button:SetDurationCooldown(cooldown)
        button:SetApplicationCount(stacks, {})
        if button.SetDurationText then pcall(button.SetDurationText, button, duration, {}) end

        records[#records + 1] = {
            button = button, border = border, icon = icon, cooldown = cooldown,
            stacks = stacks, duration = duration,
        }
    end
end

function engine:Create(parent, unit, kind, settings, fontModule, frameLevel, anchorTarget, maximumOverride)
    if not EnsureProvider() or not parent or not settings then return nil end

    local ok, container = pcall(CreateFrame, "AuraContainer", nil, parent, "CustomAuraContainerTemplate")
    if not ok or not container or not container.AddAuraGroup then
        ReportOnce("shell", "Aura container creation failed: " .. tostring(container))
        return nil
    end

    local size = math.max(1, settings.size or 16)
    local spacing = math.max(0, settings.spacing or 1)
    local perRow = math.max(1, settings.perRow or 3)
    local rows = math.max(1, settings.rows or 1)
    local maximum = maximumOverride or (perRow * rows)
    local point = anchorPoints[settings.point] or (kind == "buff" and "TOPLEFT" or "TOPRIGHT")
    local relativePoint = anchorPoints[settings.relativePoint] or point

    container:SetPoint(point, anchorTarget or parent, relativePoint, settings.x or 0, settings.y or 0)
    container:SetSize(1, 1)
    if frameLevel then container:SetFrameLevel(frameLevel) end
    if container.SetClipsChildren then container:SetClipsChildren(false) end

    local setAnchor = container.SetFlowLayoutAnchorPoint or container.SetAuraLayoutAnchorPoint
    if setAnchor then setAnchor(container, point) end
    local setGrowth = container.SetFlowLayoutGrowthDirection or container.SetAuraLayoutGrowthDirection
    if setGrowth then
        setGrowth(container,
            Direction(settings.growthX or "Right", settings.growthX == "Left" and -1 or 1),
            Direction(settings.growthY or "Up", settings.growthY == "Down" and -1 or 1))
    end
    local setPadding = container.SetFlowLayoutPadding or container.SetAuraLayoutPadding
    if setPadding then setPadding(container, 0, 0, 0, 0) end
    local setLine = container.SetFlowLayoutMaximumLineSize or container.SetAuraLayoutRowWidth
    if setLine then setLine(container, perRow * size + math.max(0, perRow - 1) * spacing) end

    local records = {}
    local group = {
        maxFrameCount = maximum,
        candidateFilters = {},
        initializeFrame = CreateInitializer(settings, fontModule, records),
        layout = {
            elementWidth = size,
            elementHeight = size,
            elementSpacing = spacing,
            lineSpacing = spacing,
        },
    }
    local groupKey = kind == "buff" and "Buffs" or "Debuffs"
    local filter = kind == "buff" and "HELPFUL" or "HARMFUL"
    local added, addError = pcall(container.AddAuraGroup, container, groupKey, filter, group)
    if not added then
        container:Hide()
        ReportOnce("group-" .. kind, "Aura group creation failed: " .. tostring(addError))
        return nil
    end

    -- Unit assignment must be last. The provider registers UNIT_AURA only when
    -- content already exists on the container.
    unit = unit or ""
    container:SetUnit(unit)
    container:UpdateAllAuras()
    container:Show()
    self.containers[container] = { unit = unit, kind = kind, records = records }
    return container
end

function engine:SetUnit(container, unit, refresh)
    if not container then return end
    unit = unit or ""
    local data = self.containers[container]
    if not data or data.unit ~= unit then
        container:SetUnit(unit)
        if data then data.unit = unit end
        refresh = true
    end
    if refresh and container.UpdateAllAuras then container:UpdateAllAuras() end
end

function engine:RefreshUnit(unit)
    for container, data in pairs(self.containers) do
        if not unit or data.unit == unit then
            container:UpdateAllAuras()
        end
    end
end

function engine:PrintDiagnostics()
    local containers, buttons, enabled, shown, sized = 0, 0, 0, 0, 0
    for container, data in pairs(self.containers) do
        containers = containers + 1
        buttons = buttons + #(data.records or {})
        if not container.IsEnabled or container:IsEnabled() then enabled = enabled + 1 end
        for _, record in ipairs(data.records or {}) do
            local button = record.button
            local sizeOK, width, height = pcall(function() return button:GetWidth(), button:GetHeight() end)
            if sizeOK and width > 0 and height > 0 then sized = sized + 1 end
            local shownOK, isShown = pcall(button.IsShown, button)
            if shownOK and isShown then shown = shown + 1 end
        end
    end
    local queued = math.max(0, buildTail - buildHead + 1)
    FUI:Print(string.format("Aura diagnostics: provider=%s, containers=%d, enabled=%d, buttons=%d, sized=%d, shown=%d, queued=%d",
        C_AddOns and C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") and "loaded" or "missing",
        containers, enabled, buttons, sized, shown, queued))
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("GROUP_ROSTER_UPDATE")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("PLAYER_FOCUS_CHANGED")
events:RegisterEvent("UNIT_AURA")
events:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_AURA" then engine:RefreshUnit(unit) else engine:RefreshUnit() end
end)


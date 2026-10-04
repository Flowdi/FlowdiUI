local _, ns = ...
local FUI = ns.FUI

local pages = {
    { key = "general", label = "Global Settings", section = "CORE", icon = "Interface\\Icons\\INV_Misc_Gear_01" },
    { key = "actionBars", label = "Action Bars", section = "FRAMES & COMBAT", icon = "Interface\\Icons\\INV_Misc_Note_05" },
    { key = "unitFrames", label = "Unit Frames", section = "FRAMES & COMBAT", icon = "Interface\\Icons\\Spell_Holy_PowerWordShield" },
    { key = "groupFrames", label = "Party & Raid Frames", section = "FRAMES & COMBAT", icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02" },
    { key = "nameplates", label = "Nameplates", section = "FRAMES & COMBAT", icon = "Interface\\Icons\\Ability_Hunter_MarkedForDeath" },
    { key = "chat", label = "Chat", section = "INTERFACE", icon = "Interface\\Icons\\INV_Letter_15" },
    { key = "bags", label = "Bags", section = "INTERFACE", icon = "Interface\\Icons\\INV_Misc_Bag_08" },
    { key = "minimap", label = "Minimap", section = "INTERFACE", icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { key = "questing", label = "Questing", section = "INTERFACE", icon = "Interface\\Icons\\INV_Misc_Map02" },
    { key = "quickLoot", label = "Quick Loot", section = "INTERFACE", icon = "Interface\\Icons\\INV_Misc_Coin_02" },
    { key = "utilityFrames", label = "Utility & Tracker", section = "INTERFACE", icon = "Interface\\Icons\\INV_Misc_Tool_01" },
    { key = "dataPanels", label = "Data Panels", section = "INTERFACE", icon = "Interface\\Icons\\INV_Misc_Book_09" },
    { key = "darkMode", label = "Dark Mode & Skins", section = "SYSTEM", icon = "Interface\\Icons\\Spell_Shadow_DarkRitual" },
    { key = "profiles", label = "Profiles", section = "SYSTEM", icon = "Interface\\Icons\\INV_Misc_Note_01" },
}

local function AddTitle(parent, title, description)
    local breadcrumb = FUI:CreateFont(parent, 10)
    breadcrumb:SetPoint("TOPLEFT", 24, -10)
    breadcrumb:SetTextColor(0.48, 0.55, 0.65)
    breadcrumb:SetText((parent.settingsSection or "FLOWDIUI") .. "  /  " .. title)

    local heading = FUI:CreateFont(parent, 23)
    heading:SetPoint("TOPLEFT", 24, -25)
    heading:SetText(title)

    local text = FUI:CreateFont(parent, 12)
    text:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -7)
    text:SetPoint("RIGHT", parent, "RIGHT", -24, 0)
    text:SetJustifyH("LEFT")
    text:SetTextColor(0.58, 0.7, 0.88)
    text:SetText(description)

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0.16, 0.19, 0.24, 1)
    line:SetPoint("TOPLEFT", 24, -78)
    line:SetPoint("TOPRIGHT", -24, -78)
    line:SetHeight(1)
end

local function AddSection(parent, title, y)
    local text = FUI:CreateFont(parent, 11)
    text:SetPoint("TOPLEFT", 24, y)
    text:SetTextColor(0.78, 0.84, 0.92)
    text:SetText(title:upper())
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetColorTexture(0.14, 0.17, 0.21, 1)
    line:SetPoint("LEFT", text, "RIGHT", 10, 0)
    line:SetPoint("RIGHT", parent, "RIGHT", -24, 0)
    return text
end

local function AddCheckbox(parent, label, x, y, getter, setter, reloadRequired)
    local toggle = CreateFrame("Button", nil, parent)
    toggle:SetSize(194, 24)
    toggle:SetPoint("TOPLEFT", x, y)
    toggle.getter = getter

    local text = FUI:CreateFont(toggle, 12)
    text:SetPoint("LEFT", 0, 0)
    text:SetText(label)
    toggle:SetWidth(math.max(90, text:GetStringWidth() + 48))

    local track = CreateFrame("Frame", nil, toggle, "BackdropTemplate")
    track:SetSize(34, 17)
    track:SetPoint("LEFT", text, "RIGHT", 9, 0)
    track:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    local knob = track:CreateTexture(nil, "ARTWORK")
    knob:SetSize(13, 13)
    knob:SetColorTexture(0.95, 0.98, 1, 1)

    local function Refresh(self)
        local enabled = self.getter() and true or false
        track:SetBackdropColor(enabled and 0.04 or 0.20, enabled and 0.55 or 0.22, enabled and 0.9 or 0.26, 1)
        track:SetBackdropBorderColor(enabled and 0.18 or 0.33, enabled and 0.72 or 0.36, enabled and 1 or 0.42, 1)
        knob:ClearAllPoints()
        knob:SetPoint(enabled and "RIGHT" or "LEFT", track, enabled and "RIGHT" or "LEFT", enabled and -2 or 2, 0)
        text:SetTextColor(enabled and 0.92 or 0.68, enabled and 0.96 or 0.72, enabled and 1 or 0.78)
    end
    toggle:SetScript("OnShow", Refresh)
    toggle:SetScript("OnClick", function(self)
        setter(not (self.getter() and true or false))
        Refresh(self)
        if reloadRequired then
            FUI.settings.reloadNotice:Show()
        else
            FUI:ApplySettings()
        end
    end)
    toggle:SetScript("OnEnter", function() track:SetBackdropBorderColor(0.35, 0.78, 1, 1) end)
    toggle:SetScript("OnLeave", Refresh)
    parent.controls[#parent.controls + 1] = toggle
    return toggle
end

local function AddSlider(parent, label, x, y, width, minimum, maximum, step, getter, setter, formatter)
    local title = FUI:CreateFont(parent, 12)
    title:SetPoint("TOPLEFT", x, y)
    title:SetText(label)

    local valueBox = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    valueBox:SetSize(58, 24)
    valueBox:SetPoint("TOPLEFT", x + width - 58, y - 22)
    valueBox:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    valueBox:SetBackdropColor(0.025, 0.04, 0.075, 0.98)
    valueBox:SetBackdropBorderColor(0.12, 0.38, 0.72, 1)

    local valueInput = CreateFrame("EditBox", nil, valueBox)
    valueInput:SetPoint("TOPLEFT", 3, -2)
    valueInput:SetPoint("BOTTOMRIGHT", -3, 2)
    valueInput:SetAutoFocus(false)
    valueInput:SetJustifyH("CENTER")
    valueInput:SetFont(FUI:GetFontPath(FUI.db.global.font), 11, FUI.db.global.fontOutline or "OUTLINE")
    valueInput:SetTextColor(0.45, 0.78, 1)
    valueInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y - 24)
    slider:SetWidth(width - 70)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    if slider.Low then slider.Low:SetText("") end
    if slider.High then slider.High:SetText("") end
    if slider.Text then slider.Text:SetText("") end
    for _, region in ipairs({ slider:GetRegions() }) do
        if region.IsObjectType and region:IsObjectType("Texture") then region:SetTexture(nil) end
    end
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("LEFT", 0, 0)
    track:SetPoint("RIGHT", 0, 0)
    track:SetHeight(4)
    track:SetColorTexture(0.12, 0.15, 0.19, 1)
    local fill = slider:CreateTexture(nil, "BORDER")
    fill:SetPoint("LEFT", track, "LEFT", 0, 0)
    fill:SetHeight(4)
    fill:SetColorTexture(0.05, 0.55, 0.92, 1)
    slider:SetThumbTexture(FUI.textures.Flat)
    local thumb = slider:GetThumbTexture()
    if thumb then
        thumb:SetSize(9, 15)
        thumb:SetVertexColor(0.42, 0.78, 1, 1)
    end
    slider.getter = getter
    slider.refreshing = false
    local function UpdateFill(value)
        local ratio = maximum == minimum and 0 or (value - minimum) / (maximum - minimum)
        fill:SetWidth(math.max(1, (width - 70) * math.max(0, math.min(1, ratio))))
    end
    local function DisplayValue(value)
        UpdateFill(value)
        if valueInput:HasFocus() then
            valueInput:SetText(string.format(step < 1 and "%.2f" or "%d", value))
        else
            valueInput:SetText(formatter and formatter(value) or string.format("%.2f", value))
        end
    end
    valueInput:SetScript("OnEditFocusGained", function(self)
        self:SetText(string.format(step < 1 and "%.2f" or "%d", slider:GetValue()))
        self:HighlightText()
    end)
    local function CommitInput(self)
        local number = tonumber((self:GetText() or ""):match("[-+]?%d*%.?%d+"))
        if number then
            number = math.max(minimum, math.min(maximum, number))
            number = math.floor((number - minimum) / step + 0.5) * step + minimum
            slider:SetValue(number)
        end
        self:ClearFocus()
        DisplayValue(slider:GetValue())
    end
    valueInput:SetScript("OnEnterPressed", CommitInput)
    valueInput:SetScript("OnEditFocusLost", function(self) DisplayValue(slider:GetValue()) end)
    slider:SetScript("OnShow", function(self)
        self.refreshing = true
        self:SetValue(self.getter())
        self.refreshing = false
        DisplayValue(self:GetValue())
    end)
    slider:SetScript("OnValueChanged", function(self, value)
        DisplayValue(value)
        if not self.refreshing then
            setter(value)
            FUI:ApplySettings()
        end
    end)
    parent.controls[#parent.controls + 1] = slider
    return slider
end

local function AddButton(parent, label, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 150, 26)
    button:SetPoint("TOPLEFT", x, y)
    button:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    button:SetBackdropColor(0.025, 0.035, 0.05, 0.98)
    button:SetBackdropBorderColor(0.13, 0.32, 0.52, 1)
    button:SetNormalFontObject(GameFontNormal)
    button:SetText(label)
    button:GetFontString():SetFont(FUI:GetFontPath(FUI.db.global.font), 11, FUI.db.global.fontOutline or "OUTLINE")
    button:GetFontString():SetTextColor(0.8, 0.86, 0.94)
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.035, 0.12, 0.2, 1)
        self:SetBackdropBorderColor(0.2, 0.62, 0.95, 1)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.025, 0.035, 0.05, 0.98)
        self:SetBackdropBorderColor(0.13, 0.32, 0.52, 1)
    end)
    button:SetScript("OnClick", callback)
    return button
end

local function AddCycle(parent, label, x, y, width, values, getter, setter, previewType)
    local title = FUI:CreateFont(parent, 12)
    title:SetPoint("TOPLEFT", x, y)
    title:SetText(label)

    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, 26)
    button:SetPoint("TOPLEFT", x, y - 23)
    button:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    button:SetBackdropColor(0.025, 0.045, 0.08, 0.98)
    button:SetBackdropBorderColor(0.12, 0.38, 0.72, 1)
    button.getter = getter

    local preview = button:CreateTexture(nil, "BACKGROUND", nil, 1)
    preview:SetPoint("TOPLEFT", 3, -3)
    preview:SetPoint("BOTTOMRIGHT", -3, 3)
    preview:Hide()
    local selected = FUI:CreateFont(button, 12)
    selected:SetPoint("LEFT", 9, 0)
    selected:SetPoint("RIGHT", -28, 0)
    selected:SetJustifyH("LEFT")
    local arrow = FUI:CreateFont(button, 15)
    arrow:SetPoint("RIGHT", -8, 1)
    arrow:SetText("v")
    arrow:SetTextColor(0.35, 0.7, 1)

    local function StyleLabel(fontString, value)
        fontString:SetText(value or "None")
        if previewType == "font" then
            fontString:SetFont(FUI:GetFontPath(value), 13, FUI.db.global.fontOutline or "OUTLINE")
        else
            fontString:SetFont(FUI:GetFontPath(FUI.db.global.font), 12, FUI.db.global.fontOutline or "OUTLINE")
        end
    end
    local function Refresh()
        local value = getter() or "None"
        StyleLabel(selected, value)
        if previewType == "texture" and FUI.textures[value] then
            preview:SetTexture(FUI.textures[value])
            preview:SetVertexColor(0.65, 0.72, 0.82, 0.75)
            preview:Show()
            selected:SetTextColor(1, 1, 1)
        else
            preview:Hide()
        end
    end

    local menu = CreateFrame("Frame", nil, button, "BackdropTemplate")
    if y < -170 and #values > 8 then
        menu:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, 2)
    else
        menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
    end
    local visibleCount = math.min(#values, 12)
    local scrollOffset = 1
    menu:SetSize(width, visibleCount * 25 + 6)
    menu:SetFrameStrata("TOOLTIP")
    menu:SetFrameLevel(200)
    menu:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    menu:SetBackdropColor(0.01, 0.018, 0.035, 0.995)
    menu:SetBackdropBorderColor(0.15, 0.48, 0.9, 1)
    menu:EnableMouseWheel(true)
    menu:Hide()

    local rows = {}
    for index = 1, visibleCount do
        local rowIndex = index
        local option = CreateFrame("Button", nil, menu, "BackdropTemplate")
        option:SetPoint("TOPLEFT", 3, -3 - (index - 1) * 25)
        option:SetPoint("TOPRIGHT", -3, -3 - (index - 1) * 25)
        option:SetHeight(24)
        option:SetBackdrop({ bgFile = FUI.textures.Flat })
        option:SetBackdropColor(0.035, 0.055, 0.09, rowIndex % 2 == 0 and 0.92 or 0.78)
        local optionPreview = option:CreateTexture(nil, "BACKGROUND", nil, 1)
        optionPreview:SetPoint("TOPLEFT", 2, -2)
        optionPreview:SetPoint("BOTTOMRIGHT", -2, 2)
        local optionText = FUI:CreateFont(option, 12)
        optionText:SetPoint("LEFT", 8, 0)
        optionText:SetPoint("RIGHT", -8, 0)
        optionText:SetJustifyH("LEFT")
        option:SetScript("OnEnter", function(self) self:SetBackdropColor(0.08, 0.28, 0.55, 0.95) end)
        option:SetScript("OnLeave", function(self) self:SetBackdropColor(0.035, 0.055, 0.09, rowIndex % 2 == 0 and 0.92 or 0.78) end)
        option:SetScript("OnClick", function(self)
            setter(self.value)
            menu:Hide()
            Refresh()
            FUI:ApplySettings()
        end)
        option.preview = optionPreview
        option.label = optionText
        rows[index] = option
    end

    local function UpdateRows()
        for index, option in ipairs(rows) do
            local value = values[scrollOffset + index - 1]
            option.value = value
            option:SetShown(value ~= nil)
            if value then
                StyleLabel(option.label, value)
                if previewType == "texture" and FUI.textures[value] then
                    option.preview:SetTexture(FUI.textures[value])
                    option.preview:SetVertexColor(0.72, 0.78, 0.86, 0.82)
                    option.preview:Show()
                else
                    option.preview:Hide()
                end
            end
        end
    end
    menu:SetScript("OnMouseWheel", function(_, delta)
        local maximum = math.max(1, #values - visibleCount + 1)
        scrollOffset = math.max(1, math.min(maximum, scrollOffset - delta))
        UpdateRows()
    end)

    button:SetScript("OnShow", Refresh)
    button:SetScript("OnClick", function()
        if FUI.activeDropdown and FUI.activeDropdown ~= menu then FUI.activeDropdown:Hide() end
        local current = getter()
        for index, value in ipairs(values) do
            if value == current then
                scrollOffset = math.max(1, math.min(index, math.max(1, #values - visibleCount + 1)))
                break
            end
        end
        UpdateRows()
        menu:SetShown(not menu:IsShown())
        FUI.activeDropdown = menu:IsShown() and menu or nil
    end)
    parent.controls[#parent.controls + 1] = button
    return button
end

local function AddColor(parent, label, x, y, getter, setter)
    local title = FUI:CreateFont(parent, 12)
    title:SetPoint("TOPLEFT", x, y)
    title:SetText(label)

    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(44, 22)
    button:SetPoint("TOPLEFT", x + 190, y + 4)
    button:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    button:SetBackdropBorderColor(0.7, 0.8, 1, 1)
    button.getter = getter
    local function Refresh(self)
        local color = self.getter()
        self:SetBackdropColor(color[1], color[2], color[3], color[4] or 1)
    end
    button:SetScript("OnShow", Refresh)
    button:SetScript("OnClick", function(self)
        local color = getter()
        local function Changed()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            setter({ r, g, b, color[4] or 1 })
            Refresh(self)
            FUI:ApplySettings()
        end
        local function Cancelled(previous)
            local old = previous or { r = color[1], g = color[2], b = color[3] }
            setter({ old.r or color[1], old.g or color[2], old.b or color[3], color[4] or 1 })
            Refresh(self)
            FUI:ApplySettings()
        end
        local info = { r = color[1], g = color[2], b = color[3], swatchFunc = Changed, cancelFunc = Cancelled }
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow(info)
        else
            ColorPickerFrame.func = Changed
            ColorPickerFrame.cancelFunc = Cancelled
            ColorPickerFrame:SetColorRGB(color[1], color[2], color[3])
            ColorPickerFrame:Show()
        end
    end)
    parent.controls[#parent.controls + 1] = button
    return button
end

local function AddTextInput(parent, label, x, y, width, getter, setter)
    local title = FUI:CreateFont(parent, 11)
    title:SetPoint("TOPLEFT", x, y)
    title:SetText(label)

    local holder = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    holder:SetSize(width, 25)
    holder:SetPoint("TOPLEFT", x, y - 18)
    holder:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    holder:SetBackdropColor(0.025, 0.04, 0.075, 0.98)
    holder:SetBackdropBorderColor(0.12, 0.38, 0.72, 1)

    local input = CreateFrame("EditBox", nil, holder)
    input:SetPoint("TOPLEFT", 7, -2)
    input:SetPoint("BOTTOMRIGHT", -7, 2)
    input:SetAutoFocus(false)
    input:SetFont(FUI:GetFontPath(FUI.db.global.font), 10, FUI.db.global.fontOutline or "OUTLINE")
    input:SetTextColor(0.82, 0.9, 1)
    input:SetScript("OnShow", function(self) self:SetText(tostring(getter() or "")) end)
    input:SetScript("OnEscapePressed", function(self) self:SetText(tostring(getter() or "")) self:ClearFocus() end)
    local function Commit(self)
        local value = self:GetText() or ""
        if value ~= tostring(getter() or "") then setter(value) FUI:ApplySettings() end
        self:ClearFocus()
    end
    input:SetScript("OnEnterPressed", Commit)
    input:SetScript("OnEditFocusLost", function(self)
        local value = self:GetText() or ""
        if value ~= tostring(getter() or "") then setter(value) FUI:ApplySettings() end
    end)
    parent.controls[#parent.controls + 1] = input
    return input
end

local function AddModuleSwitch(page, moduleKey)
    local toggle = AddCheckbox(page, "Enable module", 24, -98,
        function() return FUI.db.modules[moduleKey] ~= false end,
        function(value) FUI.db.modules[moduleKey] = value end,
        true)
    toggle:ClearAllPoints()
    toggle:SetPoint("TOPRIGHT", page, "TOPRIGHT", -24, -27)
end

local function BuildGeneral(page)
    AddTitle(page, "Global Settings", "Shared appearance, media and quality-of-life options for every FlowdiUI module.")
    local tabNames = { "General", "Fonts", "Textures", "Colors", "Improvements" }
    local tabs, panels = {}, {}
    local function SelectTab(name)
        for key, panel in pairs(panels) do panel:SetShown(key == name) end
        for key, tab in pairs(tabs) do
            tab:GetFontString():SetTextColor(key == name and 0.35 or 0.75, key == name and 0.72 or 0.82, 1)
        end
    end
    for index, name in ipairs(tabNames) do
        local tab = AddButton(page, name, 18 + (index - 1) * 105, -88, 96, function() SelectTab(name) end)
        tabs[name] = tab
        local panel = CreateFrame("Frame", nil, page)
        panel:SetPoint("TOPLEFT", 18, -126)
        panel:SetPoint("BOTTOMRIGHT", -18, 8)
        panel.controls = {}
        panel:Hide()
        panels[name] = panel
    end

    local general = panels.General
    AddSection(general, "Display", -4)
    AddCheckbox(general, "Show login message", 6, -25, function() return FUI.db.global.loginMessage end, function(v) FUI.db.global.loginMessage = v end)
    AddSlider(general, "FlowdiUI scale", 6, -75, 270, 0.75, 1.25, 0.05, function() return FUI.db.scale end, function(v) FUI.db.scale = v end, function(v) return string.format("%d%%", v * 100) end)
    AddSlider(general, "Game menu scale", 330, -75, 270, 0.75, 1.35, 0.05, function() return FUI.db.global.gameMenuScale end, function(v) FUI.db.global.gameMenuScale = v end, function(v) return string.format("%d%%", v * 100) end)
    AddSection(general, "Combat & camera", -158)
    AddCheckbox(general, "Cast actions on key down", 6, -180, function() return FUI.db.global.castOnKeyDown end, function(v) FUI.db.global.castOnKeyDown = v end)
    AddSlider(general, "Maximum camera distance", 330, -177, 270, 1, 2.6, 0.1, function() return FUI.db.global.maxCameraDistance end, function(v) FUI.db.global.maxCameraDistance = v end, function(v) return string.format("%.1f", v) end)
    AddSection(general, "Automation", -260)
    AddCycle(general, "Auto repair", 6, -282, 180, { "None", "Player", "Guild" }, function() return FUI.db.global.autoRepair end, function(v) FUI.db.global.autoRepair = v end)
    AddCheckbox(general, "Auto track reputation", 270, -303, function() return FUI.db.global.autoTrackReputation end, function(v) FUI.db.global.autoTrackReputation = v end)
    AddButton(general, "Reset positions", 6, -370, 150, function() FUI:ResetPositions() end)
    AddButton(general, "Reset all settings", 168, -370, 170, function() FlowdiUIDB = nil ReloadUI() end)

    local fonts = panels.Fonts
    AddSection(fonts, "Global font", -4)
    local fontNames = FUI:GetFontNames()
    AddCycle(fonts, "Default font", 6, -26, 220, fontNames, function() return FUI.db.global.font end, function(v) FUI.db.global.font = v end, "font")
    AddCycle(fonts, "Font outline", 330, -26, 220, { "NONE", "OUTLINE", "THICKOUTLINE" }, function() return FUI.db.global.fontOutline end, function(v) FUI.db.global.fontOutline = v end)
    AddSlider(fonts, "Default font size", 6, -105, 270, 9, 24, 1, function() return FUI.db.global.fontSize end, function(v) FUI.db.global.fontSize = v end, function(v) return string.format("%d px", v) end)
    AddCheckbox(fonts, "Apply to Blizzard UI fonts", 330, -126, function() return FUI.db.global.applyFontToAll end, function(v) FUI.db.global.applyFontToAll = v end)
    AddSection(fonts, "Special fonts", -190)
    AddCycle(fonts, "Name font", 6, -214, 220, fontNames, function() return FUI.db.global.nameFont end, function(v) FUI.db.global.nameFont = v end, "font")
    AddCycle(fonts, "Combat font", 330, -214, 220, fontNames, function() return FUI.db.global.combatFont end, function(v) FUI.db.global.combatFont = v end, "font")
    AddSection(fonts, "Module font overrides", -278)
    local moduleFontNames = { "Global", "Name Font" }
    for _, fontName in ipairs(fontNames) do moduleFontNames[#moduleFontNames + 1] = fontName end
    local moduleFonts = FUI.db.global.moduleFonts
    AddCycle(fonts, "Action Bars", 6, -298, 190, moduleFontNames, function() return moduleFonts.actionBars end, function(v) moduleFonts.actionBars = v end, "font")
    AddCycle(fonts, "Nameplates", 216, -298, 190, moduleFontNames, function() return moduleFonts.nameplates end, function(v) moduleFonts.nameplates = v end, "font")
    AddCycle(fonts, "Unit Frames", 426, -298, 190, moduleFontNames, function() return moduleFonts.unitFrames end, function(v) moduleFonts.unitFrames = v end, "font")
    AddCycle(fonts, "Party / Raid", 6, -363, 190, moduleFontNames, function() return moduleFonts.groupFrames end, function(v) moduleFonts.groupFrames = v end, "font")
    AddCycle(fonts, "Chat", 216, -363, 190, moduleFontNames, function() return moduleFonts.chat end, function(v) moduleFonts.chat = v end, "font")
    AddCycle(fonts, "Data Panels", 426, -363, 190, moduleFontNames, function() return moduleFonts.dataPanels end, function(v) moduleFonts.dataPanels = v end, "font")

    local textures = panels.Textures
    AddSection(textures, "Global textures", -4)
    local textureNames = FUI:GetTextureNames()
    AddCycle(textures, "Primary status texture", 6, -28, 240, textureNames, function() return FUI.db.global.primaryTexture end, function(v) FUI.db.global.primaryTexture = v end, "texture")
    AddCycle(textures, "Secondary status texture", 330, -28, 240, textureNames, function() return FUI.db.global.secondaryTexture end, function(v) FUI.db.global.secondaryTexture = v end, "texture")
    local textureNote = FUI:CreateFont(textures, 12)
    textureNote:SetPoint("TOPLEFT", 6, -110)
    textureNote:SetWidth(590)
    textureNote:SetJustifyH("LEFT")
    textureNote:SetTextColor(0.58, 0.7, 0.88)
    textureNote:SetText("Primary textures are used by unit, party, raid and nameplate bars. Additional installed media is discovered automatically when available.")

    local colors = panels.Colors
    AddSection(colors, "Interface colors", -4)
    AddColor(colors, "Accent color", 6, -30, function() return FUI.db.global.accent end, function(v) FUI.db.global.accent = v end)
    AddColor(colors, "Background color", 330, -30, function() return FUI.db.global.background end, function(v) FUI.db.global.background = v end)
    AddColor(colors, "Health color", 6, -80, function() return FUI.db.global.health end, function(v) FUI.db.global.health = v end)
    AddColor(colors, "Power color", 330, -80, function() return FUI.db.global.power end, function(v) FUI.db.global.power = v end)
    AddSlider(colors, "Background opacity", 6, -145, 270, 0.35, 1, 0.05, function() return FUI.db.global.backgroundOpacity end, function(v) FUI.db.global.backgroundOpacity = v end, function(v) return string.format("%d%%", v * 100) end)
    AddSlider(colors, "Dark mode brightness", 330, -145, 270, 0.08, 0.38, 0.02, function() return FUI.db.darkMode.intensity end, function(v) FUI.db.darkMode.intensity = v end, function(v) return string.format("%d%%", v * 100) end)

    local improvements = panels.Improvements
    AddSection(improvements, "Interface behavior", -4)
    AddSlider(improvements, "Options window scale", 6, -28, 270, 0.75, 1.35, 0.05, function() return FUI.db.global.optionsScale end, function(v) FUI.db.global.optionsScale = v end, function(v) return string.format("%d%%", v * 100) end)
    AddSlider(improvements, "Lag tolerance", 330, -28, 270, 0, 400, 10, function() return FUI.db.global.lagTolerance end, function(v) FUI.db.global.lagTolerance = v end, function(v) return string.format("%d ms", v) end)
    AddSection(improvements, "Combat text", -112)
    AddSlider(improvements, "Combat text scale", 6, -136, 270, 0.5, 2.5, 0.1, function() return FUI.db.global.combatTextSize end, function(v) FUI.db.global.combatTextSize = v end, function(v) return string.format("%.1fx", v) end)
    AddCheckbox(improvements, "Show damage text", 330, -155, function() return FUI.db.global.showCombatDamage end, function(v) FUI.db.global.showCombatDamage = v end)
    AddCheckbox(improvements, "Show healing text", 500, -155, function() return FUI.db.global.showCombatHealing end, function(v) FUI.db.global.showCombatHealing = v end)
    AddSection(improvements, "Blizzard improvements", -225)
    AddCheckbox(improvements, "Disable tutorial popups", 6, -247, function() return FUI.db.global.disableTutorials end, function(v) FUI.db.global.disableTutorials = v end)
    AddCheckbox(improvements, "Automatically accept invites", 260, -247, function() return FUI.db.global.acceptInvites end, function(v) FUI.db.global.acceptInvites = v end)
    AddCheckbox(improvements, "Use thin borders", 6, -287, function() return FUI.db.global.thinBorders end, function(v) FUI.db.global.thinBorders = v end)
    AddCheckbox(improvements, "Crop icon borders", 260, -287, function() return FUI.db.global.cropIcons end, function(v) FUI.db.global.cropIcons = v end)
    AddCheckbox(improvements, "Dark game menu", 6, -327, function() return FUI.db.global.darkGameMenu end, function(v) FUI.db.global.darkGameMenu = v end)

    SelectTab("General")
end

local function BuildActionBars(page)
    AddTitle(page, "Action Bars", "Configure every Blizzard action bar independently while retaining secure combat behavior.")
    local outerPage = page
    local scroll = CreateFrame("ScrollFrame", nil, outerPage, "UIPanelScrollFrameTemplate")
    FUI:SkinScrollBar(scroll.ScrollBar)
    scroll:SetPoint("TOPLEFT", 8, -84)
    scroll:SetPoint("BOTTOMRIGHT", -32, 6)
    scroll:EnableMouseWheel(true)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(690, 875)
    content.controls = outerPage.controls
    scroll:SetScrollChild(content)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local maximum = math.max(0, content:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(maximum, self:GetVerticalScroll() - delta * 42)))
    end)
    page = content
    AddCheckbox(page, "Enable module", 24, -18,
        function() return FUI.db.modules.actionBars ~= false end,
        function(value) FUI.db.modules.actionBars = value end, true)
    local choices = {
        { "Action Bar 1 (Main)", "main" }, { "Action Bar 2", "bottomLeft" },
        { "Action Bar 3", "bottomRight" }, { "Action Bar 4", "right" },
        { "Action Bar 5", "left" }, { "Action Bar 6", "bar5" },
        { "Action Bar 7", "bar6" }, { "Action Bar 8", "bar7" },
        { "Pet Bar", "pet" }, { "Stance Bar", "stance" },
    }
    local labels, labelKeys = {}, {}
    for _, choice in ipairs(choices) do labels[#labels + 1] = choice[1] labelKeys[choice[1]] = choice[2] end
    local function Current()
        local db = FUI.db.actionBars
        db.selectedBar = db.selectedBar or "main"
        return db.bars[db.selectedBar]
    end
    local function CurrentLabel()
        for _, choice in ipairs(choices) do if choice[2] == FUI.db.actionBars.selectedBar then return choice[1] end end
        return labels[1]
    end
    local selector
    local function RefreshControls()
        C_Timer.After(0, function()
            for _, control in ipairs(page.controls) do
                if control ~= selector and control:IsShown() then control:Hide() control:Show() end
            end
        end)
    end
    selector = AddCycle(page, "Editing bar", 24, -118, 300, labels, CurrentLabel,
        function(value) FUI.db.actionBars.selectedBar = labelKeys[value] or "main" RefreshControls() end)
    AddSlider(page, "Global bar scale", 370, -118, 280, 0.70, 1.30, 0.05,
        function() return FUI.db.actionBars.scale end, function(value) FUI.db.actionBars.scale = value end,
        function(value) return string.format("%d%%", value * 100) end)

    AddSection(page, "Visibility & interaction", -205)
    AddCheckbox(page, "Enable selected bar", 24, -225, function() return Current().enabled end, function(v) Current().enabled = v end)
    AddCycle(page, "Visibility", 250, -218, 190, { "Always", "Mouseover" }, function() return Current().visibility end, function(v) Current().visibility = v end)
    AddSlider(page, "Bar opacity", 480, -218, 190, 0.05, 1, 0.05, function() return Current().alpha end, function(v) Current().alpha = v end, function(v) return string.format("%d%%", v * 100) end)
    AddCheckbox(page, "Click through", 24, -278, function() return Current().clickThrough end, function(v) Current().clickThrough = v end)
    AddCheckbox(page, "Always show empty buttons", 250, -278, function() return Current().showEmpty end, function(v) Current().showEmpty = v end)

    AddSection(page, "Layout", -327)
    AddSlider(page, "Icon size", 24, -348, 280, 20, 64, 1, function() return Current().iconSize end, function(v) Current().iconSize = v end, function(v) return string.format("%d px", v) end)
    AddSlider(page, "Number of icons", 370, -348, 280, 1, 12, 1, function() return Current().buttons end, function(v) Current().buttons = v Current().rows = math.min(Current().rows, v) end, function(v) return string.format("%d", v) end)
    AddSlider(page, "Rows", 24, -420, 280, 1, 12, 1, function() return Current().rows end, function(v) Current().rows = math.min(v, Current().buttons) end, function(v) return string.format("%d", v) end)
    AddSlider(page, "Button spacing", 370, -420, 280, -2, 20, 1, function() return Current().spacing end, function(v) Current().spacing = v end, function(v) return string.format("%d px", v) end)
    AddSlider(page, "Selected bar scale", 24, -492, 280, 0.50, 2, 0.05, function() return Current().scale end, function(v) Current().scale = v end, function(v) return string.format("%d%%", v * 100) end)
    AddCheckbox(page, "Vertical orientation", 370, -512, function() return Current().vertical end, function(v) Current().vertical = v end)

    AddSection(page, "Border", -565)
    AddSlider(page, "Border size", 24, -586, 280, 0, 5, 1, function() return Current().borderSize end, function(v) Current().borderSize = v end, function(v) return string.format("%d px", v) end)
    AddColor(page, "Border color", 370, -588, function() return Current().borderColor end, function(v) Current().borderColor = v end)
    AddColor(page, "Button background", 24, -635, function() return Current().backgroundColor end, function(v) Current().backgroundColor = v end)
    AddSlider(page, "Background opacity", 370, -630, 280, 0, 1, 0.05, function() return Current().backgroundOpacity end, function(v) Current().backgroundOpacity = v end, function(v) return string.format("%d%%", v * 100) end)

    AddSection(page, "Text", -715)
    AddCheckbox(page, "Show keybinds", 24, -735, function() return FUI.db.actionBars.showHotkeys end, function(v) FUI.db.actionBars.showHotkeys = v end)
    AddCheckbox(page, "Show macro names", 210, -735, function() return FUI.db.actionBars.showMacroText end, function(v) FUI.db.actionBars.showMacroText = v end)
    AddSlider(page, "Keybind size", 370, -722, 280, 7, 24, 1, function() return Current().hotkeySize end, function(v) Current().hotkeySize = v end, function(v) return string.format("%d px", v) end)
    AddSlider(page, "Macro text size", 24, -790, 280, 7, 24, 1, function() return Current().macroSize end, function(v) Current().macroSize = v end, function(v) return string.format("%d px", v) end)
    AddSlider(page, "Count text size", 370, -790, 280, 7, 24, 1, function() return Current().countSize end, function(v) Current().countSize = v end, function(v) return string.format("%d px", v) end)
end

local function BuildNameplates(page)
    AddTitle(page, "Nameplates", "Live-configurable health, cast, aura, target and threat presentation for world units.")
    AddModuleSwitch(page, "nameplates")
    local db = FUI.db.nameplates
    local tabs, panels = {}, {}
    local function SelectTab(name)
        for key, panel in pairs(panels) do panel:SetShown(key == name) end
        for key, tab in pairs(tabs) do tab:GetFontString():SetTextColor(key == name and 0.35 or 0.75, key == name and 0.72 or 0.82, 1) end
    end
    for index, name in ipairs({ "Display", "Colors", "General", "Text & Auras" }) do
        tabs[name] = AddButton(page, name, 24 + (index - 1) * 135, -88, 124, function() SelectTab(name) end)
        local panel = CreateFrame("Frame", nil, page)
        panel:SetPoint("TOPLEFT", 18, -230)
        panel:SetPoint("BOTTOMRIGHT", -18, 8)
        panel.controls = {}
        panel:Hide()
        panels[name] = panel
    end

    local preview = CreateFrame("Frame", nil, page)
    preview:SetSize(420, 105)
    preview:SetPoint("TOP", page, "TOP", 0, -125)
    preview.name = FUI:CreateFont(preview, db.fontSize)
    preview.name:SetPoint("BOTTOM", preview, "CENTER", 0, 19)
    preview.name:SetText("Enemy Name")
    preview.health = CreateFrame("StatusBar", nil, preview)
    preview.health:SetPoint("TOP", preview, "CENTER", 0, 12)
    preview.health:SetMinMaxValues(0, 100)
    preview.health.border = CreateFrame("Frame", nil, preview.health, "BackdropTemplate")
    preview.health.border:SetPoint("TOPLEFT", -1, 1)
    preview.health.border:SetPoint("BOTTOMRIGHT", 1, -1)
    preview.health.border:SetFrameLevel(0)
    preview.healthText = FUI:CreateFont(preview.health, 9)
    preview.healthText:SetPoint("RIGHT", -3, 0)
    preview.healthText:SetText("64%")
    preview.level = FUI:CreateFont(preview.health, 9)
    preview.level:SetPoint("LEFT", 3, 0)
    preview.level:SetText("18")
    preview.glow = CreateFrame("Frame", nil, preview.health, "BackdropTemplate")
    preview.glow:SetPoint("TOPLEFT", -3, 3)
    preview.glow:SetPoint("BOTTOMRIGHT", 3, -3)
    preview.glow:SetBackdrop({ edgeFile = FUI.textures.Flat, edgeSize = 2 })
    preview.glow:SetBackdropBorderColor(0.25, 0.7, 1, 1)
    preview.leftArrow = FUI:CreateFont(preview.health, 18)
    preview.leftArrow:SetPoint("RIGHT", preview.health, "LEFT", -5, 0)
    preview.leftArrow:SetText(">")
    preview.leftArrow:SetTextColor(0.35, 0.75, 1)
    preview.rightArrow = FUI:CreateFont(preview.health, 18)
    preview.rightArrow:SetPoint("LEFT", preview.health, "RIGHT", 5, 0)
    preview.rightArrow:SetText("<")
    preview.rightArrow:SetTextColor(0.35, 0.75, 1)
    preview.cast = CreateFrame("StatusBar", nil, preview)
    preview.cast:SetMinMaxValues(0, 100)
    preview.cast:SetValue(55)
    preview.cast.border = CreateFrame("Frame", nil, preview.cast, "BackdropTemplate")
    preview.cast.border:SetPoint("TOPLEFT", -1, 1)
    preview.cast.border:SetPoint("BOTTOMRIGHT", 1, -1)
    preview.cast.border:SetFrameLevel(0)
    preview.castName = FUI:CreateFont(preview.cast, 8)
    preview.castName:SetPoint("LEFT", 3, 0)
    preview.castName:SetText("Spell Name")
    preview.castTimer = FUI:CreateFont(preview.cast, 8)
    preview.castTimer:SetPoint("RIGHT", -3, 0)
    preview.castTimer:SetText("2.3")
    preview.castIcon = preview.cast:CreateTexture(nil, "ARTWORK")
    preview.castIcon:SetTexture("Interface\\Icons\\Spell_Fire_Fireball02")
    preview.castIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    preview.castIcon:SetPoint("RIGHT", preview.cast, "LEFT", -3, 0)
    preview.castIcon:SetSize(18, 18)
    preview.auras = {}
    for index, texture in ipairs({ "Spell_Shadow_ShadowWordPain", "Spell_Holy_PowerWordShield", "Ability_Rogue_KidneyShot", "Spell_Frost_FrostNova" }) do
        local aura = preview:CreateTexture(nil, "ARTWORK")
        aura:SetTexture("Interface\\Icons\\" .. texture)
        aura:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        aura:SetPoint("BOTTOMLEFT", preview.health, "TOPLEFT", (index - 1) * 25, 19)
        preview.auras[index] = aura
    end
    if FUI.modules.nameplates and FUI.modules.nameplates.RegisterPreview then FUI.modules.nameplates:RegisterPreview(preview) end

    local display = panels.Display
    AddSection(display, "Style and dimensions", -5)
    local textureNames = { "Global" }
    for _, textureName in ipairs(FUI:GetTextureNames()) do textureNames[#textureNames + 1] = textureName end
    AddCycle(display, "Health bar texture", 24, -32, 350, textureNames, function() return db.healthTexture end, function(v) db.healthTexture = v end, "texture")
    AddCycle(display, "Cast bar texture", 430, -32, 350, textureNames, function() return db.castTexture end, function(v) db.castTexture = v end, "texture")
    AddSlider(display, "Health bar width", 24, -92, 350, 80, 260, 5, function() return db.width end, function(v) db.width = v end, function(v) return string.format("%d px", v) end)
    AddSlider(display, "Health bar height", 430, -92, 350, 6, 30, 1, function() return db.height end, function(v) db.height = v end, function(v) return string.format("%d px", v) end)
    AddSlider(display, "Cast bar height", 24, -162, 350, 4, 26, 1, function() return db.castHeight end, function(v) db.castHeight = v end, function(v) return string.format("%d px", v) end)
    AddSlider(display, "Cast bar Y offset", 430, -162, 350, -20, 12, 1, function() return db.castOffsetY end, function(v) db.castOffsetY = v end, function(v) return string.format("%d px", v) end)
    AddSlider(display, "Border size", 24, -232, 350, 1, 4, 1, function() return db.borderSize end, function(v) db.borderSize = v end, function(v) return string.format("%d px", v) end)
    AddSlider(display, "Background opacity", 430, -232, 350, 0, 1, 0.05, function() return db.backgroundAlpha end, function(v) db.backgroundAlpha = v end, function(v) return string.format("%d%%", v * 100) end)
    AddSlider(display, "Name font size", 24, -302, 350, 8, 20, 1, function() return db.fontSize end, function(v) db.fontSize = v end, function(v) return string.format("%d px", v) end)
    AddSlider(display, "Aura icon size", 430, -302, 350, 14, 36, 1, function() return db.auraSize end, function(v) db.auraSize = v end, function(v) return string.format("%d px", v) end)
    AddCheckbox(display, "Health text", 24, -365, function() return (db.healthTextMode or "Percent") ~= "None" end, function(v) db.healthTextMode = v and "Percent" or "None"; db.healthText = v end)
    AddCheckbox(display, "Unit level", 240, -365, function() return db.levelText end, function(v) db.levelText = v end)
    AddCheckbox(display, "Cast icon", 430, -365, function() return db.castIcon end, function(v) db.castIcon = v end)
    AddCheckbox(display, "Cast timer", 620, -365, function() return db.castTimer end, function(v) db.castTimer = v end)

    local colors = panels.Colors
    AddSection(colors, "Unit colors", -5)
    AddColor(colors, "Hostile", 24, -35, function() return db.hostileColor end, function(v) db.hostileColor = v end)
    AddColor(colors, "Neutral", 430, -35, function() return db.neutralColor end, function(v) db.neutralColor = v end)
    AddColor(colors, "Friendly", 24, -85, function() return db.friendlyColor end, function(v) db.friendlyColor = v end)
    AddColor(colors, "Tapped", 430, -85, function() return db.tappedColor end, function(v) db.tappedColor = v end)
    AddCheckbox(colors, "Class-color players", 24, -130, function() return db.classColorPlayers end, function(v) db.classColorPlayers = v end)
    AddSection(colors, "Cast colors", -180)
    AddColor(colors, "Interruptible cast", 24, -210, function() return db.castColor end, function(v) db.castColor = v end)
    AddColor(colors, "Uninterruptible cast", 430, -210, function() return db.castUninterruptibleColor end, function(v) db.castUninterruptibleColor = v end)
    AddSection(colors, "Threat colors", -280)
    AddColor(colors, "Low threat", 24, -310, function() return db.threatLowColor end, function(v) db.threatLowColor = v end)
    AddColor(colors, "High threat", 430, -310, function() return db.threatHighColor end, function(v) db.threatHighColor = v end)
    AddColor(colors, "Aggro / tanking", 24, -360, function() return db.threatTankColor end, function(v) db.threatTankColor = v end)
    AddCheckbox(colors, "Enable threat colors", 430, -360, function() return db.threatColor end, function(v) db.threatColor = v end)
    AddCheckbox(colors, "Threat percentage", 640, -360, function() return db.threatPercent end, function(v) db.threatPercent = v end)

    local general = panels.General
    AddSection(general, "Friendly and enemy plates", -5)
    AddCheckbox(general, "Friendly player nameplates", 24, -35, function() return db.showFriendly end, function(v) db.showFriendly = v end)
    AddCheckbox(general, "Friendly NPC nameplates", 430, -35, function() return db.showFriendlyNPCs end, function(v) db.showFriendlyNPCs = v end)
    AddCheckbox(general, "Friendly names only", 24, -75, function() return db.friendlyNameOnly end, function(v) db.friendlyNameOnly = v end)
    AddCheckbox(general, "Enemy pet nameplates", 430, -75, function() return db.showEnemyPets end, function(v) db.showEnemyPets = v end)
    AddSection(general, "Target and focus effects", -130)
    AddCheckbox(general, "Target glow", 24, -160, function() return db.targetGlow end, function(v) db.targetGlow = v end)
    AddCheckbox(general, "Target arrows", 240, -160, function() return db.targetArrows end, function(v) db.targetArrows = v end)
    AddSlider(general, "Target scale", 24, -205, 350, 1, 1.5, 0.05, function() return db.targetScale end, function(v) db.targetScale = v end, function(v) return string.format("%d%%", v * 100) end)
    AddSlider(general, "Non-target opacity", 430, -205, 350, 0.2, 1, 0.05, function() return db.nonTargetAlpha end, function(v) db.nonTargetAlpha = v end, function(v) return string.format("%d%%", v * 100) end)
    AddSection(general, "Spacing and auras", -285)
    AddCheckbox(general, "Stacking nameplates", 24, -315, function() return db.stacking end, function(v) db.stacking = v end)
    AddSlider(general, "Stacked vertical spacing", 430, -300, 350, 0.5, 2.5, 0.05, function() return db.verticalSpacing end, function(v) db.verticalSpacing = v end, function(v) return string.format("%.2f", v) end)
    AddSlider(general, "Maximum debuffs", 24, -365, 350, 0, 8, 1, function() return db.maxDebuffs end, function(v) db.maxDebuffs = v end, function(v) return string.format("%d", v) end)

    local textAuras = panels["Text & Auras"]
    AddSection(textAuras, "Texts and indicators", -5)
    AddCycle(textAuras, "Name position", 24, -32, 350, { "Above", "Inside", "Hidden" }, function() return db.namePosition or "Above" end, function(v) db.namePosition = v end)
    AddCycle(textAuras, "Health text format", 430, -32, 350, { "None", "Percent", "Current", "Current / Max" }, function() return db.healthTextMode or "Percent" end, function(v) db.healthTextMode = v; db.healthText = v ~= "None" end)
    AddCheckbox(textAuras, "Cast name", 24, -92, function() return db.castText ~= false end, function(v) db.castText = v end)
    AddCheckbox(textAuras, "Raid marker", 210, -92, function() return db.raidMarker ~= false end, function(v) db.raidMarker = v end)
    AddCheckbox(textAuras, "Aura durations", 400, -92, function() return db.auraDuration ~= false end, function(v) db.auraDuration = v end)
    AddCheckbox(textAuras, "Aura stacks", 610, -92, function() return db.auraStacks ~= false end, function(v) db.auraStacks = v end)
    AddSection(textAuras, "Execute and visibility", -150)
    AddCheckbox(textAuras, "Execute border glow", 24, -180, function() return db.executeGlow ~= false end, function(v) db.executeGlow = v end)
    AddSlider(textAuras, "Execute threshold", 430, -165, 350, 0, 50, 1, function() return db.executeThreshold or 20 end, function(v) db.executeThreshold = v end, function(v) return string.format("%d%%", v) end)
    AddSlider(textAuras, "Maximum distance", 24, -235, 350, 20, 60, 1, function() return db.maxDistance or 41 end, function(v) db.maxDistance = v end, function(v) return string.format("%d yd", v) end)
    AddSection(textAuras, "Nameplate spacing", -315)
    AddSlider(textAuras, "Horizontal overlap", 24, -340, 350, 0.2, 2.5, 0.05, function() return db.horizontalSpacing or 0.8 end, function(v) db.horizontalSpacing = v end, function(v) return string.format("%.2f", v) end)
    SelectTab("Display")
end

local function BuildUnitFrames(page)
    AddTitle(page, "Unit Frames", "Build independent player, target and focus frames from shared visual primitives.")
    local unitDB = FUI.db.unitFrames
    local unitLabels = {
        player = "Player", pet = "Pet", target = "Target", targettarget = "Target of Target",
        targettargettarget = "Target of Target of Target", focus = "Focus",
    }
    local labelUnits = {
        Player = "player", Pet = "pet", Target = "target", ["Target of Target"] = "targettarget",
        ["Target of Target of Target"] = "targettargettarget", Focus = "focus",
    }
    local anchorValues = { "Top Left", "Top", "Top Right", "Left", "Center", "Right", "Bottom Left", "Bottom", "Bottom Right" }
    local tabs, panels, panelScrolls = {}, {}, {}
    local activeTab = "Display"
    local function Current()
        local unit = unitDB.selectedFrame or "player"
        return unitDB.frames[unit], unit
    end
    local function RefreshCurrentPanel()
        local panel = panels[activeTab]
        local scroll = panel and panel.scrollFrame
        if scroll and scroll:IsShown() then scroll:Hide() scroll:Show() end
    end
    local function SelectTab(name)
        activeTab = name
        for key, scroll in pairs(panelScrolls) do scroll:SetShown(key == name) end
        for key, tab in pairs(tabs) do tab:GetFontString():SetTextColor(key == name and 0.35 or 0.75, key == name and 0.72 or 0.82, 1) end
    end

    for index, name in ipairs({ "Display", "Health", "Power", "Texts", "Portrait", "Cast Bar", "Auras", "Healing", "Indicators" }) do
        tabs[name] = AddButton(page, name, 18 + (index - 1) * 78, -88, 74, function() SelectTab(name) end)
        local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
        FUI:SkinScrollBar(scroll.ScrollBar)
        scroll:SetPoint("TOPLEFT", 18, -190)
        scroll:SetPoint("BOTTOMRIGHT", -34, 8)
        scroll:EnableMouseWheel(true)
        local panel = CreateFrame("Frame", nil, scroll)
        panel:SetSize(670, 500)
        panel.controls = {}
        panel.scrollFrame = scroll
        scroll:SetScrollChild(panel)
        scroll:SetScript("OnMouseWheel", function(self, delta)
            local maximum = math.max(0, panel:GetHeight() - self:GetHeight())
            self:SetVerticalScroll(math.max(0, math.min(maximum, self:GetVerticalScroll() - delta * 42)))
        end)
        scroll:Hide()
        panels[name] = panel
        panelScrolls[name] = scroll
    end

    AddCycle(page, "Editing frame", 24, -128, 250, { "Player", "Pet", "Target", "Target of Target", "Target of Target of Target", "Focus" },
        function() return unitLabels[unitDB.selectedFrame or "player"] end,
        function(value) unitDB.selectedFrame = labelUnits[value] or "player" RefreshCurrentPanel() end)
    AddSlider(page, "Global frame scale", 350, -128, 270, 0.70, 1.35, 0.05,
        function() return unitDB.scale end, function(value) unitDB.scale = value end,
        function(value) return string.format("%d%%", value * 100) end)

    local display = panels.Display
    AddSection(display, "Frame behavior", -4)
    AddCheckbox(display, "Enable Unit Frames", 6, -25, function() return FUI.db.modules.unitFrames ~= false end, function(v) FUI.db.modules.unitFrames = v end, true)
    AddCheckbox(display, "Enable selected frame", 250, -25, function() return Current().enabled ~= false end, function(v) Current().enabled = v end)
    AddCycle(display, "Visibility", 6, -70, 230, { "Always", "Solo", "Party", "Raid", "In Combat" }, function() return Current().visibility end, function(v) Current().visibility = v end)
    AddCycle(display, "Frame strata", 330, -70, 230, { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG" }, function() return Current().frameStrata end, function(v) Current().frameStrata = v end)
    AddSlider(display, "Border size", 6, -150, 270, 1, 4, 1, function() return Current().borderSize end, function(v) Current().borderSize = v end, function(v) return string.format("%d px", v) end)
    AddCheckbox(display, "Hover border", 330, -171, function() return Current().hoverBorder end, function(v) Current().hoverBorder = v end)
    AddCheckbox(display, "Show unit tooltip", 500, -171, function() return Current().showTooltip end, function(v) Current().showTooltip = v end)
    local moverNote = FUI:CreateFont(display, 11)
    moverNote:SetPoint("TOPLEFT", 6, -245)
    moverNote:SetTextColor(0.58, 0.7, 0.88)
    moverNote:SetText("Use Unlock Mode in the left navigation to move every FlowdiUI frame.")

    local health = panels.Health
    AddSection(health, "Dimensions & texture", -4)
    AddSlider(health, "Health bar height", 6, -28, 270, 20, 90, 1, function() return Current().healthHeight end, function(v) Current().healthHeight = v end, function(v) return string.format("%d px", v) end)
    AddSlider(health, "Bar width", 330, -28, 270, 100, 420, 1, function() return Current().width end, function(v) Current().width = v end, function(v) return string.format("%d px", v) end)
    local textureNames = { "Global" }
    for _, name in ipairs(FUI:GetTextureNames()) do textureNames[#textureNames + 1] = name end
    AddCycle(health, "Bar texture", 6, -108, 240, textureNames, function() return Current().texture end, function(v) Current().texture = v end, "texture")
    AddSlider(health, "Fill opacity", 330, -108, 270, 0.10, 1, 0.05, function() return Current().healthOpacity end, function(v) Current().healthOpacity = v end, function(v) return string.format("%d%%", v * 100) end)
    AddSection(health, "Colors", -190)
    AddCycle(health, "Fill color mode", 6, -212, 240, { "Class", "Custom" }, function() return Current().healthColor end, function(v) Current().healthColor = v end)
    AddColor(health, "Custom fill color", 330, -212, function() return Current().customHealthColor end, function(v) Current().customHealthColor = v end)
    AddColor(health, "Bar background", 6, -278, function() return Current().healthBackground end, function(v) Current().healthBackground = v end)

    local power = panels.Power
    AddSection(power, "Power bar", -4)
    AddSlider(power, "Power bar height", 6, -28, 270, 0, 30, 1, function() return Current().powerHeight end, function(v) Current().powerHeight = v end, function(v) return string.format("%d px", v) end)
    AddCycle(power, "Bar position", 330, -28, 240, { "Below Health Bar", "Above Health Bar", "Hidden" }, function() return Current().powerPosition end, function(v) Current().powerPosition = v end)
    AddSlider(power, "Fill opacity", 6, -108, 270, 0.10, 1, 0.05, function() return Current().powerOpacity end, function(v) Current().powerOpacity = v end, function(v) return string.format("%d%%", v * 100) end)
    AddCycle(power, "Fill color mode", 330, -108, 240, { "Power Type", "Custom" }, function() return Current().powerColor end, function(v) Current().powerColor = v end)
    AddColor(power, "Custom fill color", 6, -190, function() return Current().customPowerColor end, function(v) Current().customPowerColor = v end)
    AddColor(power, "Bar background", 330, -190, function() return Current().powerBackground end, function(v) Current().powerBackground = v end)
    AddCycle(power, "Power text", 6, -260, 240, { "None", "Power", "Power %" }, function() return Current().powerText end, function(v) Current().powerText = v end)

    local texts = panels.Texts
    local textValues = { "None", "Name", "Level + Name", "Health %", "Health", "Health / Max", "Power %", "Power" }
    AddSection(texts, "Health text assignments", -4)
    AddCycle(texts, "Left text", 6, -28, 240, textValues, function() return Current().leftText end, function(v) Current().leftText = v end)
    AddCycle(texts, "Right text", 330, -28, 240, textValues, function() return Current().rightText end, function(v) Current().rightText = v end)
    AddCycle(texts, "Center text", 6, -108, 240, textValues, function() return Current().centerText end, function(v) Current().centerText = v end)
    AddCycle(texts, "Extra text", 330, -108, 240, textValues, function() return Current().extraText end, function(v) Current().extraText = v end)
    AddSlider(texts, "Text size", 6, -190, 270, 8, 24, 1, function() return Current().textSize end, function(v) Current().textSize = v end, function(v) return string.format("%d px", v) end)

    local portrait = panels.Portrait
    AddSection(portrait, "Portrait", -4)
    AddCheckbox(portrait, "Show portrait", 6, -25, function() return Current().showPortrait end, function(v) Current().showPortrait = v end)
    AddCycle(portrait, "Portrait mode", 6, -70, 240, { "2D Portrait", "None" }, function() return Current().portraitMode end, function(v) Current().portraitMode = v end)
    AddCycle(portrait, "Position", 330, -70, 240, { "Left", "Right" }, function() return Current().portraitPosition end, function(v) Current().portraitPosition = v end)
    AddSlider(portrait, "Portrait size", 6, -150, 270, 20, 100, 1, function() return Current().portraitSize end, function(v) Current().portraitSize = v end, function(v) return string.format("%d px", v) end)

    local cast = panels["Cast Bar"]
    local castTabs, castPanels = {}, {}
    local activeCastTab = "General"
    local function SelectCastTab(name)
        activeCastTab = name
        unitDB.selectedCastTab = name
        for key, panel in pairs(castPanels) do panel:SetShown(key == name) end
        for key, tab in pairs(castTabs) do tab:GetFontString():SetTextColor(key == name and 0.35 or 0.75, key == name and 0.72 or 0.82, 1) end
    end
    for index, name in ipairs({ "General", "Position", "Text" }) do
        castTabs[name] = AddButton(cast, name, 6 + (index - 1) * 138, -4, 128, function() SelectCastTab(name) end)
        local panel = CreateFrame("Frame", nil, cast)
        panel:SetPoint("TOPLEFT", 0, -42)
        panel:SetPoint("BOTTOMRIGHT", 0, 0)
        panel.controls = {}
        panel:Hide()
        castPanels[name] = panel
    end

    local castGeneral = castPanels.General
    AddCheckbox(castGeneral, "Show cast bar", 6, -8, function() return Current().showCastbar end, function(v) Current().showCastbar = v end)
    AddCheckbox(castGeneral, "Show spell icon", 210, -8, function() return Current().showCastIcon end, function(v) Current().showCastIcon = v end)
    AddCheckbox(castGeneral, "Reverse fill", 420, -8, function() return Current().castReverseFill end, function(v) Current().castReverseFill = v end)
    AddSlider(castGeneral, "Width", 6, -54, 270, 80, 600, 1, function() return Current().castWidth end, function(v) Current().castWidth = v end, function(v) return string.format("%d px", v) end)
    AddSlider(castGeneral, "Height", 330, -54, 270, 6, 60, 1, function() return Current().castHeight end, function(v) Current().castHeight = v end, function(v) return string.format("%d px", v) end)
    AddSlider(castGeneral, "Fill opacity", 6, -126, 270, 0.10, 1, 0.05, function() return Current().castOpacity end, function(v) Current().castOpacity = v end, function(v) return string.format("%d%%", v * 100) end)
    AddSlider(castGeneral, "Background opacity", 330, -126, 270, 0, 1, 0.05, function() return Current().castBackgroundOpacity end, function(v) Current().castBackgroundOpacity = v end, function(v) return string.format("%d%%", v * 100) end)
    AddCycle(castGeneral, "Bar texture", 6, -198, 240, textureNames, function() return Current().castTexture end, function(v) Current().castTexture = v end, "texture")
    AddColor(castGeneral, "Fill color", 330, -198, function() return Current().castColor end, function(v) Current().castColor = v end)
    AddColor(castGeneral, "Background color", 330, -246, function() return Current().castBackground end, function(v) Current().castBackground = v end)
    AddCycle(castGeneral, "Player only: cast bar provider", 6, -278, 240, { "Blizzard", "FlowdiUI" },
        function() return unitDB.frames.player.castbarProvider or "Blizzard" end,
        function(v)
            unitDB.frames.player.castbarProvider = v
            if v == "FlowdiUI" then unitDB.frames.player.showCastbar = true end
        end)

    local castPosition = castPanels.Position
    AddCheckbox(castPosition, "Detached and draggable", 6, -8, function() return Current().castDetached end, function(v) Current().castDetached = v end)
    AddCycle(castPosition, "Attach to", 6, -62, 240, { "Frame", "Health Bar", "Power Bar", "Portrait" }, function() return Current().castAttachTo end, function(v) Current().castAttachTo = v end)
    AddCycle(castPosition, "Frame strata", 330, -62, 240, { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "TOOLTIP" }, function() return Current().castFrameStrata end, function(v) Current().castFrameStrata = v end)
    AddCycle(castPosition, "Bar anchor", 6, -138, 240, anchorValues, function() return Current().castPoint end, function(v) Current().castPoint = v end)
    AddCycle(castPosition, "Attach point", 330, -138, 240, anchorValues, function() return Current().castRelativePoint end, function(v) Current().castRelativePoint = v end)
    AddSlider(castPosition, "X offset", 6, -214, 270, -400, 400, 1, function() return Current().castX end, function(v) Current().castX = v end, function(v) return string.format("%d px", v) end)
    AddSlider(castPosition, "Y offset", 330, -214, 270, -400, 400, 1, function() return Current().castY end, function(v) Current().castY = v end, function(v) return string.format("%d px", v) end)

    local castText = castPanels.Text
    AddCycle(castText, "Spell name", 6, -16, 240, { "Left", "Center", "Right", "Hidden" }, function() return Current().castNamePosition end, function(v) Current().castNamePosition = v end)
    AddCycle(castText, "Duration", 330, -16, 240, { "Left", "Center", "Right", "Hidden" }, function() return Current().castTimePosition end, function(v) Current().castTimePosition = v end)
    AddCycle(castText, "Icon position", 6, -92, 240, { "Left", "Right" }, function() return Current().castIconPosition end, function(v) Current().castIconPosition = v end)
    AddSlider(castText, "Text size", 330, -92, 270, 7, 24, 1, function() return Current().castTextSize end, function(v) Current().castTextSize = v end, function(v) return string.format("%d px", v) end)
    AddCycle(castText, "Time format", 6, -168, 240, { "Remaining", "Elapsed" }, function() return Current().castTimeFormat end, function(v) Current().castTimeFormat = v end)
    local castNote = FUI:CreateFont(castText, 11)
    castNote:SetPoint("TOPLEFT", 6, -246)
    castNote:SetWidth(590)
    castNote:SetJustifyH("LEFT")
    castNote:SetTextColor(0.58, 0.7, 0.88)
    castNote:SetText("Use the global Unlock Mode to drag cast bars. Moving one automatically enables detached placement.")
    SelectCastTab(unitDB.selectedCastTab or activeCastTab)

    local auras = panels.Auras
    local auraTypeButtons, auraTabs, auraPanels = {}, {}, {}
    local auraKinds = { Buffs = "buff", Debuffs = "debuff" }
    local activeAuraTab = unitDB.selectedAuraTab or "General"
    local function AuraSettings()
        local settings = Current()
        local kind = auraKinds[unitDB.selectedAura or "Buffs"] or "buff"
        return settings.auras[kind]
    end
    local function RefreshAuraPanel()
        local panel = auraPanels[activeAuraTab]
        if panel and panel:IsShown() then panel:Hide() panel:Show() end
    end
    local function SelectAuraType(name)
        unitDB.selectedAura = name
        for key, button in pairs(auraTypeButtons) do
            button:GetFontString():SetTextColor(key == name and 0.35 or 0.75, key == name and 0.72 or 0.82, 1)
        end
        RefreshAuraPanel()
    end
    local function SelectAuraTab(name)
        activeAuraTab = name
        unitDB.selectedAuraTab = name
        for key, panel in pairs(auraPanels) do panel:SetShown(key == name) end
        for key, button in pairs(auraTabs) do
            button:GetFontString():SetTextColor(key == name and 0.35 or 0.75, key == name and 0.72 or 0.82, 1)
        end
    end
    for index, name in ipairs({ "Buffs", "Debuffs" }) do
        auraTypeButtons[name] = AddButton(auras, name, 6 + (index - 1) * 138, -4, 128, function() SelectAuraType(name) end)
    end
    for index, name in ipairs({ "General", "Position", "Text", "Filters" }) do
        auraTabs[name] = AddButton(auras, name, 6 + (index - 1) * 138, -40, 128, function() SelectAuraTab(name) end)
        local panel = CreateFrame("Frame", nil, auras)
        panel:SetPoint("TOPLEFT", 0, -78)
        panel:SetPoint("BOTTOMRIGHT", 0, 0)
        panel.controls = {}
        panel:Hide()
        auraPanels[name] = panel
    end

    local auraGeneral = auraPanels.General
    AddCheckbox(auraGeneral, "Enabled", 6, -8, function() return AuraSettings().enabled end, function(v) AuraSettings().enabled = v end)
    AddCheckbox(auraGeneral, "Only my auras", 210, -8, function() return AuraSettings().mineOnly end, function(v) AuraSettings().mineOnly = v end)
    AddCheckbox(auraGeneral, "Tooltip", 420, -8, function() return AuraSettings().tooltip end, function(v) AuraSettings().tooltip = v end)
    AddCheckbox(auraGeneral, "Desaturate icons", 6, -46, function() return AuraSettings().desaturate end, function(v) AuraSettings().desaturate = v end)
    AddCheckbox(auraGeneral, "Click through", 210, -46, function() return AuraSettings().clickThrough end, function(v) AuraSettings().clickThrough = v end)
    AddCheckbox(auraGeneral, "Cooldown swipe", 420, -46, function() return AuraSettings().cooldown end, function(v) AuraSettings().cooldown = v end)
    AddSlider(auraGeneral, "Icon size", 6, -92, 270, 12, 64, 1, function() return AuraSettings().size end, function(v) AuraSettings().size = v end, function(v) return string.format("%d px", v) end)
    AddSlider(auraGeneral, "Icons per row", 330, -92, 270, 1, 20, 1, function() return AuraSettings().perRow end, function(v) AuraSettings().perRow = v end, function(v) return string.format("%d", v) end)
    AddSlider(auraGeneral, "Rows", 6, -168, 270, 1, 5, 1, function() return AuraSettings().rows end, function(v) AuraSettings().rows = v end, function(v) return string.format("%d", v) end)
    AddSlider(auraGeneral, "Spacing", 330, -168, 270, 0, 20, 1, function() return AuraSettings().spacing end, function(v) AuraSettings().spacing = v end, function(v) return string.format("%d px", v) end)
    AddSlider(auraGeneral, "Border size", 6, -244, 270, 1, 4, 1, function() return AuraSettings().borderSize end, function(v) AuraSettings().borderSize = v end, function(v) return string.format("%d px", v) end)

    local auraPosition = auraPanels.Position
    AddCycle(auraPosition, "Attach to", 6, -8, 190, { "Frame", "Health Bar", "Power Bar", "Portrait" }, function() return AuraSettings().attachTo end, function(v) AuraSettings().attachTo = v end)
    AddCycle(auraPosition, "Icon anchor", 220, -8, 190, anchorValues, function() return AuraSettings().point end, function(v) AuraSettings().point = v end)
    AddCycle(auraPosition, "Attach point", 434, -8, 190, anchorValues, function() return AuraSettings().relativePoint end, function(v) AuraSettings().relativePoint = v end)
    AddCycle(auraPosition, "Growth X", 6, -78, 190, { "Right", "Left" }, function() return AuraSettings().growthX end, function(v) AuraSettings().growthX = v end)
    AddCycle(auraPosition, "Growth Y", 220, -78, 190, { "Up", "Down" }, function() return AuraSettings().growthY end, function(v) AuraSettings().growthY = v end)
    AddCycle(auraPosition, "Sort by", 434, -78, 190, { "Index", "Time Remaining", "Duration", "Name" }, function() return AuraSettings().sortBy end, function(v) AuraSettings().sortBy = v end)
    AddCycle(auraPosition, "Sort direction", 6, -148, 190, { "Ascending", "Descending" }, function() return AuraSettings().sortDirection end, function(v) AuraSettings().sortDirection = v end)
    AddSlider(auraPosition, "X offset", 220, -148, 190, -200, 200, 1, function() return AuraSettings().x end, function(v) AuraSettings().x = v end, function(v) return string.format("%d px", v) end)
    AddSlider(auraPosition, "Y offset", 434, -148, 190, -200, 200, 1, function() return AuraSettings().y end, function(v) AuraSettings().y = v end, function(v) return string.format("%d px", v) end)

    local auraText = auraPanels.Text
    AddCheckbox(auraText, "Show duration", 6, -8, function() return AuraSettings().showDuration end, function(v) AuraSettings().showDuration = v end)
    AddCheckbox(auraText, "Show stack count", 330, -8, function() return AuraSettings().showStacks end, function(v) AuraSettings().showStacks = v end)
    AddSlider(auraText, "Duration text size", 6, -64, 270, 7, 24, 1, function() return AuraSettings().durationSize end, function(v) AuraSettings().durationSize = v end, function(v) return string.format("%d px", v) end)
    AddSlider(auraText, "Stack text size", 330, -64, 270, 7, 24, 1, function() return AuraSettings().stackSize end, function(v) AuraSettings().stackSize = v end, function(v) return string.format("%d px", v) end)
    AddCycle(auraText, "Duration position", 6, -142, 240, anchorValues, function() return AuraSettings().durationPosition end, function(v) AuraSettings().durationPosition = v end)
    AddCycle(auraText, "Stack position", 330, -142, 240, anchorValues, function() return AuraSettings().stackPosition end, function(v) AuraSettings().stackPosition = v end)

    local auraFilters = auraPanels.Filters
    AddTextInput(auraFilters, "Allow list (spell IDs)", 6, -8, 600,
        function() return AuraSettings().allowList or "" end,
        function(v) AuraSettings().allowList = v end)
    AddTextInput(auraFilters, "Block list (spell IDs)", 6, -78, 600,
        function() return AuraSettings().blockList or "" end,
        function(v) AuraSettings().blockList = v end)
    local auraFilterNote = FUI:CreateFont(auraFilters, 10)
    auraFilterNote:SetPoint("TOPLEFT", 6, -150)
    auraFilterNote:SetWidth(600)
    auraFilterNote:SetJustifyH("LEFT")
    auraFilterNote:SetTextColor(0.58, 0.7, 0.88)
    auraFilterNote:SetText("Allow list empty: all auras are eligible. When it contains spell IDs, only those auras are shown. Block list always removes matching auras. 'Only my auras' is applied by the protected aura provider.")
    SelectAuraType(unitDB.selectedAura or "Buffs")
    SelectAuraTab(activeAuraTab)

    local healing = panels.Healing
    AddSection(healing, "Incoming heal prediction", -4)
    AddCheckbox(healing, "Enable prediction bar", 6, -25, function() return Current().healPrediction end, function(v) Current().healPrediction = v end)
    AddCheckbox(healing, "Personal heals", 250, -25, function() return Current().healPredictionMine end, function(v) Current().healPredictionMine = v end)
    AddCheckbox(healing, "Other healers", 450, -25, function() return Current().healPredictionOthers end, function(v) Current().healPredictionOthers = v end)
    AddSlider(healing, "Prediction opacity", 6, -82, 270, 0.10, 1, 0.05, function() return Current().healPredictionOpacity end, function(v) Current().healPredictionOpacity = v end, function(v) return string.format("%d%%", v * 100) end)
    AddColor(healing, "Personal-heal color", 330, -82, function() return Current().healPredictionMineColor end, function(v) Current().healPredictionMineColor = v end)
    AddColor(healing, "Other-heal color", 330, -132, function() return Current().healPredictionOtherColor end, function(v) Current().healPredictionOtherColor = v end)
    local healingNote = FUI:CreateFont(healing, 11)
    healingNote:SetPoint("TOPLEFT", 6, -205)
    healingNote:SetWidth(590)
    healingNote:SetJustifyH("LEFT")
    healingNote:SetTextColor(0.58, 0.7, 0.88)
    healingNote:SetText("Incoming heals extend from the current health fill and are clipped at maximum health.")

    local indicators = panels.Indicators
    local indicatorPrefixes = { ["Raid Marker"] = "raidMarker", ["Leader"] = "leaderIndicator", ["Combat"] = "combatIndicator" }
    local function IndicatorPrefix() return indicatorPrefixes[unitDB.selectedIndicator or "Raid Marker"] or "raidMarker" end
    local function IndicatorValue(suffix, fallback)
        local value = Current()[IndicatorPrefix() .. suffix]
        if value == nil then return fallback end
        return value
    end
    local function SetIndicatorValue(suffix, value) Current()[IndicatorPrefix() .. suffix] = value end
    AddSection(indicators, "Indicator selection", -4)
    AddCycle(indicators, "Editing indicator", 6, -28, 240, { "Raid Marker", "Leader", "Combat" },
        function() return unitDB.selectedIndicator or "Raid Marker" end,
        function(v) unitDB.selectedIndicator = v RefreshCurrentPanel() end)
    AddCheckbox(indicators, "Enabled", 330, -48,
        function() return IndicatorValue("", true) end,
        function(v) SetIndicatorValue("", v) end)
    AddSection(indicators, "Attachment & alignment", -102)
    AddCycle(indicators, "Attach to", 6, -126, 240, { "Frame", "Health Bar", "Power Bar", "Portrait" },
        function() return IndicatorValue("AttachTo", "Frame") end,
        function(v) SetIndicatorValue("AttachTo", v) end)
    AddCycle(indicators, "Icon anchor", 330, -126, 240, anchorValues,
        function() return IndicatorValue("Point", "Center") end,
        function(v) SetIndicatorValue("Point", v) end)
    AddCycle(indicators, "Attach point", 6, -202, 240, anchorValues,
        function() return IndicatorValue("RelativePoint", "Top") end,
        function(v) SetIndicatorValue("RelativePoint", v) end)
    AddSlider(indicators, "Icon size", 330, -202, 270, 6, 64, 1,
        function() return IndicatorValue("Size", 20) end,
        function(v) SetIndicatorValue("Size", v) end,
        function(v) return string.format("%d px", v) end)
    AddSlider(indicators, "X offset", 6, -278, 270, -150, 150, 1,
        function() return IndicatorValue("X", 0) end,
        function(v) SetIndicatorValue("X", v) end,
        function(v) return string.format("%d px", v) end)
    AddSlider(indicators, "Y offset", 330, -278, 270, -150, 150, 1,
        function() return IndicatorValue("Y", 0) end,
        function(v) SetIndicatorValue("Y", v) end,
        function(v) return string.format("%d px", v) end)
    AddSection(indicators, "Range indicators", -350)
    AddCheckbox(indicators, "40 yd friendly heal range", 6, -374,
        function() return Current().rangeFriendly end,
        function(v) Current().rangeFriendly = v Current().rangeIndicator = v end)
    AddCheckbox(indicators, "30 yd hostile spell range", 330, -374,
        function() return Current().rangeHostile end,
        function(v) Current().rangeHostile = v end)
    AddSlider(indicators, "Out of range opacity", 6, -414, 270, 0.10, 1, 0.05,
        function() return Current().outOfRangeAlpha or 0.40 end,
        function(v) Current().outOfRangeAlpha = v end,
        function(v) return string.format("%d%%", v * 100) end)

    SelectTab("Display")
end

local function BuildGroupFrames(page)
    AddTitle(page, "Party & Raid Frames", "Configure independent group layouts with an always-current visual preview.")
    local db = FUI.db.groupFrames
    local profileKeys = { Party = "party", Raid = "raid" }
    local anchorValues = { "Top Left", "Top", "Top Right", "Left", "Center", "Right", "Bottom Left", "Bottom", "Bottom Right" }
    local function CurrentProfile() return db[profileKeys[db.selectedProfile or "Party"] or "party"] end
    local function CurrentAura(kind) return CurrentProfile().auras[kind] end

    local tabs, panels = {}, {}
    local activeTab = db.selectedTab or "General"
    local function SelectTab(name)
        activeTab, db.selectedTab = name, name
        for key, panel in pairs(panels) do panel:SetShown(key == name) end
        for key, tab in pairs(tabs) do tab:GetFontString():SetTextColor(key == name and 0.35 or 0.75, key == name and 0.72 or 0.82, 1) end
    end
    for index, name in ipairs({ "General", "Layout", "Health", "Text", "Buffs", "Debuffs", "Filters", "Indicators" }) do
        tabs[name] = AddButton(page, name, 18 + (index - 1) * 84, -88, 78, function() SelectTab(name) end)
        local panel = CreateFrame("Frame", nil, page)
        panel:SetPoint("TOPLEFT", 18, -266)
        panel:SetPoint("BOTTOMRIGHT", -18, 8)
        panel.controls = {}
        panel:Hide()
        panels[name] = panel
    end

    AddCycle(page, "Editing layout", 24, -128, 220, { "Party", "Raid" },
        function() return db.selectedProfile or "Party" end,
        function(value)
            db.selectedProfile = value
            local panel = panels[activeTab]
            if panel and panel:IsShown() then panel:Hide() panel:Show() end
        end)

    local preview = CreateFrame("Frame", nil, page, "BackdropTemplate")
    preview:SetPoint("TOPLEFT", 270, -112)
    preview:SetSize(430, 132)
    preview:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    preview:SetBackdropColor(0.008, 0.015, 0.028, 0.96)
    preview:SetBackdropBorderColor(0.12, 0.38, 0.72, 1)
    local previewTitle = FUI:CreateFont(preview, 10)
    previewTitle:SetPoint("TOPLEFT", 8, -6)
    previewTitle:SetTextColor(0.42, 0.72, 1)
    local samples, names = {}, { "Flowdi", "Kael", "Mira", "Thorn", "Nyx", "Ari", "Vale", "Rune", "Lumi", "Dusk" }
    local colors = { { .72, .62, .25 }, { .12, .58, .88 }, { .25, .72, .45 }, { .68, .28, .38 }, { .52, .42, .78 } }
    for index = 1, 10 do
        local sample = CreateFrame("Frame", nil, preview, "BackdropTemplate")
        sample:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
        sample.name = FUI:CreateFont(sample, 8)
        sample.name:SetPoint("TOPLEFT", 3, -2)
        sample.name:SetText(names[index])
        sample.healthText = FUI:CreateFont(sample, 7)
        sample.healthText:SetPoint("RIGHT", -3, 1)
        sample.power = sample:CreateTexture(nil, "ARTWORK")
        sample.power:SetPoint("BOTTOMLEFT", 1, 1)
        sample.power:SetPoint("BOTTOMRIGHT", -1, 1)
        sample.buff = sample:CreateTexture(nil, "OVERLAY")
        sample.buff:SetColorTexture(0.3, 0.85, 0.45, 1)
        sample.debuff = sample:CreateTexture(nil, "OVERLAY")
        sample.debuff:SetColorTexture(0.9, 0.25, 0.25, 1)
        sample.pet = CreateFrame("Frame", nil, preview, "BackdropTemplate")
        sample.pet:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
        sample.pet:SetBackdropColor(0.08, 0.20, 0.28, 0.92)
        sample.pet:SetBackdropBorderColor(unpack(FUI.colors.border))
        sample.petName = FUI:CreateFont(sample.pet, 7)
        sample.petName:SetPoint("LEFT", 3, 0)
        sample.petName:SetText("Pet")
        samples[index] = sample
    end
    local function UpdatePreview()
        local profile = CurrentProfile()
        local count = db.selectedProfile == "Party" and (db.party.showSelf and 5 or 4) or 10
        local perColumn
        if db.selectedProfile == "Party" and profile.orientation == "Horizontal" then perColumn = 1
        elseif db.selectedProfile == "Party" then perColumn = count
        else perColumn = math.max(1, math.min(profile.unitsPerColumn or 5, count)) end
        local columns, rows = math.ceil(count / perColumn), math.min(perColumn, count)
        local petExtra = profile.showPets and ((profile.petHeight or 14) + (profile.petSpacing or 1)) or 0
        local stackHeight = profile.height + petExtra
        local rawWidth = columns * profile.width + math.max(0, columns - 1) * ((profile.spacing or 0) + (profile.groupSpacing or 0))
        local rawHeight = rows * stackHeight + math.max(0, rows - 1) * (profile.spacing or 0)
        local scale = math.min(1, 410 / math.max(1, rawWidth), 102 / math.max(1, rawHeight))
        local frameWidth, frameHeight = profile.width * scale, profile.height * scale
        previewTitle:SetText((db.selectedProfile or "Party") .. " preview")
        for index, sample in ipairs(samples) do
            sample:SetShown(index <= count)
            sample.pet:SetShown(index <= count and profile.showPets)
            if index <= count then
                local column, row = math.floor((index - 1) / perColumn), (index - 1) % perColumn
                if profile.growthX == "Left" then column = columns - 1 - column end
                if profile.growthY == "Up" then row = rows - 1 - row end
                sample:ClearAllPoints()
                sample:SetPoint("TOPLEFT", preview, "TOPLEFT", 10 + column * (profile.width + (profile.spacing or 0) + (profile.groupSpacing or 0)) * scale, -22 - row * (stackHeight + (profile.spacing or 0)) * scale)
                sample:SetSize(frameWidth, frameHeight)
                sample:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = profile.borderSize or 1 })
                local color = profile.healthColor == "Class" and colors[(index - 1) % #colors + 1] or profile.customHealthColor
                sample:SetBackdropColor(color[1], color[2], color[3], profile.healthOpacity or 1)
                sample:SetBackdropBorderColor(unpack(FUI.colors.border))
                sample.name:SetFont(FUI:GetModuleFontPath("groupFrames"), math.max(7, math.min(12, profile.fontSize * scale)), FUI.db.global.fontOutline)
                sample.power:SetHeight(math.max(1, (profile.powerHeight or 0) * scale))
                sample.power:SetColorTexture(0.12, 0.38, 0.9, profile.powerOpacity or 1)
                sample.power:SetShown((profile.powerHeight or 0) > 0)
                sample.name:SetShown(profile.showName)
                sample.healthText:SetText(profile.showHealthPercent and (70 + index) .. "%" or "")
                local buffSize = math.max(3, math.min(frameHeight * .38, profile.auras.buff.size * scale))
                sample.buff:SetSize(buffSize, buffSize)
                sample.buff:SetPoint("TOPRIGHT", -2, -2)
                sample.buff:SetShown(profile.auras.buff.enabled)
                local debuffSize = math.max(3, math.min(frameHeight * .42, profile.auras.debuff.size * scale))
                sample.debuff:SetSize(debuffSize, debuffSize)
                sample.debuff:SetPoint("BOTTOMRIGHT", -2, 2)
                sample.debuff:SetShown(profile.auras.debuff.enabled)
                sample.pet:ClearAllPoints()
                sample.pet:SetPoint("TOPLEFT", sample, "BOTTOMLEFT", 0, -(profile.petSpacing or 1) * scale)
                sample.pet:SetSize(frameWidth, math.max(3, (profile.petHeight or 14) * scale))
                sample.petName:SetFont(FUI:GetModuleFontPath("groupFrames"), math.max(6, math.min(9, (profile.fontSize - 2) * scale)), FUI.db.global.fontOutline)
            end
        end
    end
    page:SetScript("OnUpdate", function(self, elapsed)
        self.previewElapsed = (self.previewElapsed or 0) + elapsed
        if self.previewElapsed >= 0.12 then self.previewElapsed = 0 UpdatePreview() end
    end)
    page:HookScript("OnShow", UpdatePreview)

    local general = panels.General
    AddCheckbox(general, "Enable module", 6, -8, function() return FUI.db.modules.groupFrames ~= false end, function(v) FUI.db.modules.groupFrames = v end, true)
    AddCheckbox(general, "Enable selected layout", 220, -8, function() return CurrentProfile().enabled end, function(v) CurrentProfile().enabled = v end)
    AddCheckbox(general, "Show party when solo", 450, -8, function() return db.party.showWhenSolo end, function(v) db.party.showWhenSolo = v end)
    AddCheckbox(general, "Include player in party", 6, -45, function() return db.party.showSelf end, function(v) db.party.showSelf = v end)
    AddSlider(general, "Scale", 6, -88, 270, 0.55, 1.50, 0.05, function() return CurrentProfile().scale end, function(v) CurrentProfile().scale = v end, function(v) return string.format("%d%%", v * 100) end)
    AddSlider(general, "Frame width", 330, -88, 270, 50, 320, 1, function() return CurrentProfile().width end, function(v) CurrentProfile().width = v end, function(v) return string.format("%d px", v) end)
    AddSlider(general, "Frame height", 6, -164, 270, 18, 90, 1, function() return CurrentProfile().height end, function(v) CurrentProfile().height = v end, function(v) return string.format("%d px", v) end)
    AddCheckbox(general, "Show pet frames", 330, -184, function() return CurrentProfile().showPets end, function(v) CurrentProfile().showPets = v end)

    local layout = panels.Layout
    AddSlider(layout, "Frame spacing", 6, -8, 270, -2, 20, 1, function() return CurrentProfile().spacing end, function(v) CurrentProfile().spacing = v end, function(v) return string.format("%d px", v) end)
    AddSlider(layout, "Group spacing", 330, -8, 270, 0, 30, 1, function() return CurrentProfile().groupSpacing end, function(v) CurrentProfile().groupSpacing = v end, function(v) return string.format("%d px", v) end)
    AddSlider(layout, "Units per column", 6, -84, 270, 1, 10, 1, function() return CurrentProfile().unitsPerColumn end, function(v) CurrentProfile().unitsPerColumn = v end, function(v) return string.format("%d", v) end)
    AddCycle(layout, "Column growth", 330, -84, 240, { "Right", "Left" }, function() return CurrentProfile().growthX end, function(v) CurrentProfile().growthX = v end)
    AddCycle(layout, "Unit growth", 6, -160, 240, { "Down", "Up" }, function() return CurrentProfile().growthY end, function(v) CurrentProfile().growthY = v end)
    AddCycle(layout, "Party orientation", 330, -160, 240, { "Vertical", "Horizontal" }, function() return db.party.orientation end, function(v) db.party.orientation = v end)
    AddSlider(layout, "Pet frame height", 6, -236, 270, 8, 40, 1, function() return CurrentProfile().petHeight end, function(v) CurrentProfile().petHeight = v end, function(v) return string.format("%d px", v) end)
    AddSlider(layout, "Pet spacing", 330, -236, 270, 0, 12, 1, function() return CurrentProfile().petSpacing end, function(v) CurrentProfile().petSpacing = v end, function(v) return string.format("%d px", v) end)

    local health = panels.Health
    AddCycle(health, "Health color", 6, -8, 240, { "Class", "Custom" }, function() return CurrentProfile().healthColor end, function(v) CurrentProfile().healthColor = v end)
    AddColor(health, "Custom health color", 330, -8, function() return CurrentProfile().customHealthColor end, function(v) CurrentProfile().customHealthColor = v end)
    AddColor(health, "Health background", 330, -52, function() return CurrentProfile().healthBackground end, function(v) CurrentProfile().healthBackground = v end)
    AddSlider(health, "Health opacity", 6, -84, 270, 0.1, 1, 0.05, function() return CurrentProfile().healthOpacity end, function(v) CurrentProfile().healthOpacity = v end, function(v) return string.format("%d%%", v * 100) end)
    AddSlider(health, "Power height", 330, -84, 270, 0, 20, 1, function() return CurrentProfile().powerHeight end, function(v) CurrentProfile().powerHeight = v end, function(v) return string.format("%d px", v) end)
    AddSlider(health, "Border size", 6, -160, 270, 1, 4, 1, function() return CurrentProfile().borderSize end, function(v) CurrentProfile().borderSize = v end, function(v) return string.format("%d px", v) end)
    AddCheckbox(health, "Hover border", 330, -180, function() return CurrentProfile().hoverBorder end, function(v) CurrentProfile().hoverBorder = v end)

    local text = panels.Text
    AddSlider(text, "Font size", 6, -8, 270, 7, 20, 1, function() return CurrentProfile().fontSize end, function(v) CurrentProfile().fontSize = v end, function(v) return string.format("%d px", v) end)
    AddCheckbox(text, "Show names", 330, -28, function() return CurrentProfile().showName end, function(v) CurrentProfile().showName = v end)
    AddCheckbox(text, "Show health percent", 480, -28, function() return CurrentProfile().showHealthPercent end, function(v) CurrentProfile().showHealthPercent = v end)

    local function BuildAuraPanel(panel, kind)
        AddCheckbox(panel, "Enabled", 6, -8, function() return CurrentAura(kind).enabled end, function(v) CurrentAura(kind).enabled = v end)
        AddCheckbox(panel, kind == "buff" and "Only my buffs" or "Only mine", 180, -8, function() return CurrentAura(kind).mineOnly end, function(v) CurrentAura(kind).mineOnly = v end)
        AddCheckbox(panel, "Tooltip", 340, -8, function() return CurrentAura(kind).tooltip end, function(v) CurrentAura(kind).tooltip = v end)
        AddCheckbox(panel, "Cooldown", 480, -8, function() return CurrentAura(kind).cooldown end, function(v) CurrentAura(kind).cooldown = v end)
        AddCheckbox(panel, "Click through", 6, -42, function() return CurrentAura(kind).clickThrough end, function(v) CurrentAura(kind).clickThrough = v end)
        AddCheckbox(panel, "Duration text", 180, -42, function() return CurrentAura(kind).showDuration end, function(v) CurrentAura(kind).showDuration = v end)
        AddCheckbox(panel, "Stack text", 340, -42, function() return CurrentAura(kind).showStacks end, function(v) CurrentAura(kind).showStacks = v end)
        AddCheckbox(panel, "Desaturate", 480, -42, function() return CurrentAura(kind).desaturate end, function(v) CurrentAura(kind).desaturate = v end)
        AddSlider(panel, "Icon size", 6, -80, 270, 8, 40, 1, function() return CurrentAura(kind).size end, function(v) CurrentAura(kind).size = v end, function(v) return string.format("%d px", v) end)
        AddSlider(panel, "Max icons", 330, -80, 270, 1, 10, 1, function() return CurrentAura(kind).perRow end, function(v) CurrentAura(kind).perRow = v CurrentAura(kind).rows = 1 end, function(v) return string.format("%d", v) end)
        AddSlider(panel, "Spacing", 6, -150, 270, 0, 12, 1, function() return CurrentAura(kind).spacing end, function(v) CurrentAura(kind).spacing = v end, function(v) return string.format("%d px", v) end)
        AddSlider(panel, "Max duration (0 = all)", 330, -150, 270, 0, 600, 10, function() return CurrentAura(kind).maxDuration or 0 end, function(v) CurrentAura(kind).maxDuration = v end, function(v) return string.format("%d s", v) end)
        AddCycle(panel, "Icon anchor", 6, -220, 190, anchorValues, function() return CurrentAura(kind).point end, function(v) CurrentAura(kind).point = v end)
        AddCycle(panel, "Attach point", 220, -220, 190, anchorValues, function() return CurrentAura(kind).relativePoint end, function(v) CurrentAura(kind).relativePoint = v end)
        AddCycle(panel, "Growth", 434, -220, 190, { "Right", "Left" }, function() return CurrentAura(kind).growthX end, function(v) CurrentAura(kind).growthX = v end)
    end
    BuildAuraPanel(panels.Buffs, "buff")
    BuildAuraPanel(panels.Debuffs, "debuff")

    local filters = panels.Filters
    AddCycle(filters, "Display mode", 6, -8, 220, { "Essential", "All" },
        function() return CurrentProfile().auraFilters.mode end,
        function(v) CurrentProfile().auraFilters.mode = v end)
    AddCheckbox(filters, "Dispellable debuffs at Right", 300, -28,
        function() return CurrentProfile().auraFilters.showDispellable end,
        function(v) CurrentProfile().auraFilters.showDispellable = v end)
    AddCheckbox(filters, "Crowd control at Bottom Right", 500, -28,
        function() return CurrentProfile().auraFilters.showCrowdControl ~= false end,
        function(v) CurrentProfile().auraFilters.showCrowdControl = v end)
    AddTextInput(filters, "Top Left buffs", 6, -72, 300,
        function() return CurrentProfile().auraFilters.topLeftBuffs end,
        function(v) CurrentProfile().auraFilters.topLeftBuffs = v end)
    AddTextInput(filters, "Top Right healing buffs", 330, -72, 300,
        function() return CurrentProfile().auraFilters.topRightBuffs end,
        function(v) CurrentProfile().auraFilters.topRightBuffs = v end)
    AddTextInput(filters, "Right buffs", 6, -136, 300,
        function() return CurrentProfile().auraFilters.rightBuffs or "" end,
        function(v) CurrentProfile().auraFilters.rightBuffs = v end)
    AddTextInput(filters, "Bottom Left debuffs", 330, -136, 300,
        function() return CurrentProfile().auraFilters.bottomLeftDebuffs end,
        function(v) CurrentProfile().auraFilters.bottomLeftDebuffs = v end)
    AddTextInput(filters, "Center raid debuffs", 6, -200, 300,
        function() return CurrentProfile().auraFilters.centerDebuffs end,
        function(v) CurrentProfile().auraFilters.centerDebuffs = v end)
    AddTextInput(filters, "Blocked buffs", 330, -200, 300,
        function() return CurrentAura("buff").blockList or "" end,
        function(v) CurrentAura("buff").blockList = v end)
    AddTextInput(filters, "Blocked debuffs", 6, -264, 300,
        function() return CurrentAura("debuff").blockList or "" end,
        function(v) CurrentAura("debuff").blockList = v end)
    AddSlider(filters, "Max icons per position", 330, -264, 270, 1, 16, 1,
        function() return CurrentProfile().auraFilters.maxIcons or 8 end,
        function(v) CurrentProfile().auraFilters.maxIcons = v end,
        function(v) return string.format("%d", v) end)
    local filterNote = FUI:CreateFont(filters, 10)
    filterNote:SetPoint("TOPLEFT", 6, -340)
    filterNote:SetWidth(624)
    filterNote:SetJustifyH("LEFT")
    filterNote:SetTextColor(0.58, 0.7, 0.88)
    filterNote:SetText("Use comma-separated spell IDs. Essential mode: maintenance/healing buffs use the upper and right positions, Weakened Soul-style debuffs use Bottom Left, crowd control uses Bottom Right, dispels use Right, and raid debuffs use Center. Block lists always win.")

    local indicators = panels.Indicators
    AddCheckbox(indicators, "Role indicator", 6, -8, function() return CurrentProfile().showRole end, function(v) CurrentProfile().showRole = v end)
    AddCheckbox(indicators, "Leader indicator", 220, -8, function() return CurrentProfile().showLeader end, function(v) CurrentProfile().showLeader = v end)
    AddCheckbox(indicators, "Raid marker", 430, -8, function() return CurrentProfile().showRaidMarker end, function(v) CurrentProfile().showRaidMarker = v end)
    AddCheckbox(indicators, "Ready check", 6, -48, function() return CurrentProfile().showReadyCheck end, function(v) CurrentProfile().showReadyCheck = v end)
    AddCheckbox(indicators, "40 yd friendly range", 220, -48, function() return CurrentProfile().rangeFriendly end, function(v) CurrentProfile().rangeFriendly = v CurrentProfile().rangeIndicator = v end)
    AddSlider(indicators, "Out of range opacity", 6, -92, 270, 0.10, 1, 0.05, function() return CurrentProfile().outOfRangeAlpha or 0.40 end, function(v) CurrentProfile().outOfRangeAlpha = v end, function(v) return string.format("%d%%", v * 100) end)
    SelectTab(activeTab)
end

local function BuildChat(page)
    AddTitle(page, "Chat", "Typography, fading and background for chat windows.")
    AddModuleSwitch(page, "chat")
    AddSlider(page, "Font size", 24, -155, 310, 9, 18, 1,
        function() return FUI.db.chat.fontSize end,
        function(value) FUI.db.chat.fontSize = value end,
        function(value) return string.format("%d px", value) end)
    AddSlider(page, "Background opacity", 24, -240, 310, 0, 1, 0.05,
        function() return FUI.db.chat.backgroundAlpha end,
        function(value) FUI.db.chat.backgroundAlpha = value end,
        function(value) return string.format("%d%%", value * 100) end)
    AddCheckbox(page, "Fade chat", 24, -320,
        function() return FUI.db.chat.fade end,
        function(value) FUI.db.chat.fade = value end)
    AddCheckbox(page, "Show timestamps", 250, -320,
        function() return FUI.db.chat.timestamps end,
        function(value) FUI.db.chat.timestamps = value end)
    AddCheckbox(page, "Show copy button", 480, -320,
        function() return FUI.db.chat.copyButton end,
        function(value) FUI.db.chat.copyButton = value end)
    AddCycle(page, "Chat input position", 390, -365, 220, { "Below", "Above" },
        function() return FUI.db.chat.editBoxPosition or "Below" end,
        function(value) FUI.db.chat.editBoxPosition = value end)
    AddSlider(page, "Visible for", 24, -375, 310, 15, 300, 15,
        function() return FUI.db.chat.timeVisible end,
        function(value) FUI.db.chat.timeVisible = value end,
        function(value) return string.format("%d seconds", value) end)
    AddSlider(page, "Chat width", 390, -450, 220, 260, 900, 10,
        function() return FUI.db.chat.width or 470 end,
        function(value) FUI.db.chat.width = value end,
        function(value) return string.format("%d px", value) end)
    AddSlider(page, "Chat height", 24, -450, 310, 120, 600, 10,
        function() return FUI.db.chat.height or 260 end,
        function(value) FUI.db.chat.height = value end,
        function(value) return string.format("%d px", value) end)
end

local function BuildBags(page)
    AddTitle(page, "Bags", "Dark styling and item information for Blizzard bags.")
    AddModuleSwitch(page, "bags")
    AddCheckbox(page, "Combined Bags", 24, -128,
        function() return FUI.db.bags.combined ~= false end,
        function(value) FUI.db.bags.combined = value end)
    AddSlider(page, "Darkness", 24, -205, 310, 0.35, 1, 0.05,
        function() return FUI.db.bags.darkness end,
        function(value) FUI.db.bags.darkness = value end,
        function(value) return string.format("%d%%", value * 100) end)
    AddCheckbox(page, "Show item level", 24, -285,
        function() return FUI.db.bags.itemLevel end,
        function(value) FUI.db.bags.itemLevel = value end)
    AddCheckbox(page, "Quality-colored borders", 300, -285,
        function() return FUI.db.bags.qualityBorders end,
        function(value) FUI.db.bags.qualityBorders = value end)
end

local function BuildDataPanels(page)
    AddTitle(page, "Data Panels", "Configure two movable information bars and an optional Minimap panel.")
    local tabNames = { "General", "Primary Panel", "Second Panel", "Minimap Panel" }
    local tabs, panels = {}, {}
    local function SelectTab(name)
        for key, panel in pairs(panels) do panel:SetShown(key == name) end
        for key, tab in pairs(tabs) do tab:GetFontString():SetTextColor(key == name and 0.35 or 0.75, key == name and 0.72 or 0.82, 1) end
    end
    for index, name in ipairs(tabNames) do
        local tab = AddButton(page, name, 24 + (index - 1) * 150, -88, 140, function() SelectTab(name) end)
        tabs[name] = tab
        local panel = CreateFrame("Frame", nil, page)
        panel:SetPoint("TOPLEFT", 18, -126)
        panel:SetPoint("BOTTOMRIGHT", -18, 8)
        panel.controls = {}
        panel:Hide()
        panels[name] = panel
    end

    local db = FUI.db.dataPanels
    local general = panels.General
    AddCheckbox(general, "Enable Data Panels", 6, -5, function() return FUI.db.modules.dataPanels ~= false end, function(v) FUI.db.modules.dataPanels = v end, true)
    AddSlider(general, "Global scale", 6, -60, 270, 0.70, 1.35, 0.05, function() return db.scale end, function(v) db.scale = v end, function(v) return string.format("%d%%", v * 100) end)
    AddSlider(general, "Opacity", 330, -60, 270, 0.25, 1, 0.05, function() return db.opacity end, function(v) db.opacity = v end, function(v) return string.format("%d%%", v * 100) end)
    AddSlider(general, "Font size", 6, -145, 270, 8, 16, 1, function() return db.fontSize end, function(v) db.fontSize = v end, function(v) return string.format("%d px", v) end)
    AddSection(general, "Panel appearance", -230)
    AddCheckbox(general, "Show backdrop", 6, -252, function() return db.backdrop end, function(v) db.backdrop = v end)
    AddCheckbox(general, "Show border", 210, -252, function() return db.border end, function(v) db.border = v end)
    AddCheckbox(general, "Transparent panels", 400, -252, function() return db.transparent end, function(v) db.transparent = v end)
    local info = FUI:CreateFont(general, 11)
    info:SetPoint("TOPLEFT", 6, -315)
    info:SetWidth(590)
    info:SetJustifyH("LEFT")
    info:SetTextColor(0.58, 0.7, 0.88)
    info:SetText("Use the global Unlock Mode to move both panels. The Minimap panel follows the Minimap automatically.")

    local providerNames = FUI.modules.dataPanels and FUI.modules.dataPanels:GetProviderNames() or { "None", "System", "Bags", "Gold", "Durability", "Time" }
    local counts = { 1, 2, 3, 4, 5 }
    local function AddPanelSlots(parent, values, countGetter, countSetter)
        AddCycle(parent, "Number of DataTexts", 6, -112, 190, counts, countGetter, countSetter)
        for index = 1, 5 do
            local slotIndex = index
            local column = (index - 1) % 3
            local row = math.floor((index - 1) / 3)
            AddCycle(parent, "DataText " .. index, 6 + column * 210, -185 - row * 76, 190, providerNames,
                function() return values[slotIndex] end,
                function(value) values[slotIndex] = value end)
        end
    end

    local primary = panels["Primary Panel"]
    AddSlider(primary, "Width", 6, -12, 270, 280, 1200, 20, function() return db.width end, function(v) db.width = v end, function(v) return string.format("%d px", v) end)
    AddSlider(primary, "Height", 330, -12, 270, 16, 42, 1, function() return db.height end, function(v) db.height = v end, function(v) return string.format("%d px", v) end)
    AddPanelSlots(primary, db.slots, function() return db.primaryCount end, function(v) db.primaryCount = v end)

    local secondary = panels["Second Panel"]
    AddCheckbox(secondary, "Enable second panel", 6, -5, function() return db.secondEnabled end, function(v) db.secondEnabled = v end)
    AddSlider(secondary, "Width", 6, -52, 270, 280, 1200, 20, function() return db.secondWidth end, function(v) db.secondWidth = v end, function(v) return string.format("%d px", v) end)
    AddSlider(secondary, "Height", 330, -52, 270, 16, 42, 1, function() return db.secondHeight end, function(v) db.secondHeight = v end, function(v) return string.format("%d px", v) end)
    AddPanelSlots(secondary, db.secondSlots, function() return db.secondCount end, function(v) db.secondCount = v end)

    local minimap = panels["Minimap Panel"]
    AddCheckbox(minimap, "Enable Minimap panel", 6, -5, function() return db.minimapEnabled end, function(v) db.minimapEnabled = v end)
    AddCycle(minimap, "Position", 6, -62, 190, { "TOP", "BOTTOM" }, function() return db.minimapPosition end, function(v) db.minimapPosition = v end)
    AddCycle(minimap, "Number of DataTexts", 330, -62, 190, { 1, 2 }, function() return db.minimapCount end, function(v) db.minimapCount = v end)
    AddSlider(minimap, "Panel height", 6, -145, 270, 16, 32, 1, function() return db.minimapHeight end, function(v) db.minimapHeight = v end, function(v) return string.format("%d px", v) end)
    AddCycle(minimap, "DataText 1", 6, -235, 250, providerNames, function() return db.minimapSlots[1] end, function(v) db.minimapSlots[1] = v end)
    AddCycle(minimap, "DataText 2", 330, -235, 250, providerNames, function() return db.minimapSlots[2] end, function(v) db.minimapSlots[2] = v end)
    SelectTab("General")
end

local function BuildMinimap(page)
    AddTitle(page, "Minimap", "A square FlowdiUI map with calendar, tracking, zoom controls, and a collected addon-button drawer.")
    AddModuleSwitch(page, "minimap")
    local db = FUI.db.minimap
    AddSlider(page, "Map size", 24, -165, 300, 140, 260, 2,
        function() return db.size end,
        function(value) db.size = value end,
        function(value) return string.format("%d px", value) end)
    AddSlider(page, "Control button size", 375, -165, 300, 20, 32, 1,
        function() return db.buttonSize end,
        function(value) db.buttonSize = value end,
        function(value) return string.format("%d px", value) end)
    AddSlider(page, "Addon button size", 24, -255, 300, 20, 40, 1,
        function() return db.addonButtonSize end,
        function(value) db.addonButtonSize = value end,
        function(value) return string.format("%d px", value) end)
    AddSlider(page, "Buttons per drawer row", 375, -255, 300, 1, 6, 1,
        function() return db.addonButtonColumns end,
        function(value) db.addonButtonColumns = value end,
        function(value) return tostring(value) end)
    AddCheckbox(page, "Mouse wheel zoom", 24, -345,
        function() return db.mouseWheelZoom end,
        function(value) db.mouseWheelZoom = value end)
    local info = FUI:CreateFont(page, 11)
    info:SetPoint("TOPLEFT", 24, -405)
    info:SetWidth(650)
    info:SetJustifyH("LEFT")
    info:SetTextColor(0.58, 0.7, 0.88)
    info:SetText("The Minimap stays in the upper-right corner. Its optional Data Panel is configured separately under Data Panels and attaches directly to the map edge.")
end

local function BuildUtilityFrames(page)
    AddTitle(page, "Utility & Tracker", "Style Blizzard utility frames and configure FlowdiUI's Forever layer tracking.")
    local tabNames = { "Micro Bar", "Bag Bar", "Objective Tracker", "Layer Tracker" }
    local tabs, panels = {}, {}
    local function SelectTab(name)
        for key, panel in pairs(panels) do panel:SetShown(key == name) end
        for key, tab in pairs(tabs) do
            tab:GetFontString():SetTextColor(key == name and 0.35 or 0.75, key == name and 0.72 or 0.82, 1)
        end
    end
    for index, name in ipairs(tabNames) do
        local tab = AddButton(page, name, 24 + (index - 1) * 158, -88, 145, function() SelectTab(name) end)
        tabs[name] = tab
        local panel = CreateFrame("Frame", nil, page)
        panel:SetPoint("TOPLEFT", 18, -126)
        panel:SetPoint("BOTTOMRIGHT", -18, 8)
        panel.controls = {}
        panel:Hide()
        panels[name] = panel
    end

    local db = FUI.db.utilityFrames
    local micro = panels["Micro Bar"]
    AddCheckbox(micro, "Enable FlowdiUI Micro Bar", 6, -5, function() return db.microBar.enabled end, function(v) db.microBar.enabled = v end)
    AddCycle(micro, "Visibility", 6, -65, 220, { "Always", "Mouseover" }, function() return db.microBar.visibility end, function(v) db.microBar.visibility = v end)
    AddSlider(micro, "Button size", 6, -155, 280, 20, 38, 1, function() return db.microBar.buttonSize end, function(v) db.microBar.buttonSize = v end, function(v) return string.format("%d px", v) end)
    AddSlider(micro, "Button spacing", 340, -155, 280, 0, 10, 1, function() return db.microBar.spacing end, function(v) db.microBar.spacing = v end, function(v) return string.format("%d px", v) end)

    local bags = panels["Bag Bar"]
    AddCheckbox(bags, "Enable FlowdiUI Bag Bar", 6, -5, function() return db.bagBar.enabled end, function(v) db.bagBar.enabled = v end)
    AddCycle(bags, "Visibility", 6, -65, 220, { "Always", "Mouseover" }, function() return db.bagBar.visibility end, function(v) db.bagBar.visibility = v end)
    AddSlider(bags, "Button size", 6, -155, 280, 22, 42, 1, function() return db.bagBar.buttonSize end, function(v) db.bagBar.buttonSize = v end, function(v) return string.format("%d px", v) end)
    AddSlider(bags, "Button spacing", 340, -155, 280, 0, 10, 1, function() return db.bagBar.spacing end, function(v) db.bagBar.spacing = v end, function(v) return string.format("%d px", v) end)

    local tracker = panels["Objective Tracker"]
    AddCheckbox(tracker, "Enable FlowdiUI Objective Tracker style", 6, -5, function() return db.objectiveTracker.enabled end, function(v) db.objectiveTracker.enabled = v end)
    AddSlider(tracker, "Width", 6, -65, 280, 220, 440, 10, function() return db.objectiveTracker.width end, function(v) db.objectiveTracker.width = v end, function(v) return string.format("%d px", v) end)
    AddSlider(tracker, "Height", 340, -65, 280, 260, 760, 10, function() return db.objectiveTracker.height end, function(v) db.objectiveTracker.height = v end, function(v) return string.format("%d px", v) end)
    AddColor(tracker, "Background color", 6, -155, function() return db.objectiveTracker.backgroundColor end, function(v) db.objectiveTracker.backgroundColor = v end)
    AddSlider(tracker, "Background opacity", 340, -150, 280, 0, 1, 0.05, function() return db.objectiveTracker.backgroundAlpha end, function(v) db.objectiveTracker.backgroundAlpha = v end, function(v) return string.format("%d%%", v * 100) end)
    AddSlider(tracker, "Header font size", 6, -245, 280, 10, 18, 1, function() return db.objectiveTracker.headerSize end, function(v) db.objectiveTracker.headerSize = v end, function(v) return string.format("%d px", v) end)
    AddSlider(tracker, "Objective font size", 340, -245, 280, 8, 16, 1, function() return db.objectiveTracker.textSize end, function(v) db.objectiveTracker.textSize = v end, function(v) return string.format("%d px", v) end)
    local info = FUI:CreateFont(tracker, 11)
    info:SetPoint("TOPLEFT", 6, -335)
    info:SetWidth(620)
    info:SetJustifyH("LEFT")
    info:SetTextColor(0.58, 0.7, 0.88)
    info:SetText("Blizzard continues to generate quest and scenario content. FlowdiUI keeps its configurable background behind the native text and owns the tracker's typography, border, and position.")

    local layer = panels["Layer Tracker"]
    local layerDB = db.layerTracker
    AddCheckbox(layer, "Enable Layer Tracker", 6, -5, function() return layerDB.enabled end, function(v) layerDB.enabled = v end)
    AddCheckbox(layer, "Share observations with FlowdiUI users", 340, -5, function() return layerDB.syncEnabled end, function(v) layerDB.syncEnabled = v end)
    AddCheckbox(layer, "Show current zone", 6, -65, function() return layerDB.showZone end, function(v) layerDB.showZone = v end)
    AddSlider(layer, "Frame width", 6, -155, 280, 150, 300, 5, function() return layerDB.width end, function(v) layerDB.width = v end, function(v) return string.format("%d px", v) end)
    AddSlider(layer, "Scale", 340, -155, 280, 0.6, 1.6, 0.05, function() return layerDB.scale end, function(v) layerDB.scale = v end, function(v) return string.format("%d%%", v * 100) end)
    AddSlider(layer, "Font size", 6, -245, 280, 9, 18, 1, function() return layerDB.fontSize end, function(v) layerDB.fontSize = v end, function(v) return string.format("%d px", v) end)
    AddSlider(layer, "Active observation window", 340, -245, 280, 15, 180, 15, function() return layerDB.retentionMinutes end, function(v) layerDB.retentionMinutes = v end, function(v) return string.format("%d min", v) end)
    local layerInfo = FUI:CreateFont(layer, 11)
    layerInfo:SetPoint("TOPLEFT", 6, -335)
    layerInfo:SetWidth(620)
    layerInfo:SetJustifyH("LEFT")
    layerInfo:SetTextColor(0.58, 0.7, 0.88)
    layerInfo:SetText("Layer data is inferred from visible outdoor NPC GUIDs. The active count contains recently observed layers in your current zone; it becomes more complete as FlowdiUI users exchange observations.")
    page.SelectUtilityTab = SelectTab
    SelectTab("Micro Bar")
end

local function BuildDarkMode(page)
    AddTitle(page, "Dark Mode & Skins", "Restyles actual Blizzard windows while preserving their native behavior.")
    AddModuleSwitch(page, "darkMode")
    AddSlider(page, "Brightness", 24, -155, 310, 0.08, 0.38, 0.02,
        function() return FUI.db.darkMode.intensity end,
        function(value) FUI.db.darkMode.intensity = value end,
        function(value) return string.format("%d%%", value * 100) end)
    AddButton(page, "Refresh open windows", 24, -235, 220, function()
        local darkMode = FUI.modules.darkMode
        if darkMode and darkMode.Scan then darkMode:Scan(true) end
    end)
    AddSection(page, "Window skins", -300)
    local skins = FUI.db.darkMode.skins
    AddCheckbox(page, "Character", 24, -322, function() return skins.character end, function(v) skins.character = v end, true)
    AddCheckbox(page, "Quest & Gossip", 220, -322, function() return skins.quest end, function(v) skins.quest = v end, true)
    AddCheckbox(page, "Bank & Bags", 430, -322, function() return skins.bankBags end, function(v) skins.bankBags = v end, true)
    AddCheckbox(page, "Merchant", 24, -362, function() return skins.merchant end, function(v) skins.merchant = v end, true)
    AddCheckbox(page, "Mail", 220, -362, function() return skins.mail end, function(v) skins.mail = v end, true)
    AddCheckbox(page, "World Map", 430, -362, function() return skins.worldMap end, function(v) skins.worldMap = v end, true)
end

local function BuildProfiles(page)
    AddTitle(page, "Profiles", "Save, name and share complete FlowdiUI configurations.")
    AddSection(page, "Planned profile management", -112)
    local activeLabel = FUI:CreateFont(page, 12)
    activeLabel:SetPoint("TOPLEFT", 24, -140)
    activeLabel:SetText("Active profile")
    local active = CreateFrame("Frame", nil, page, "BackdropTemplate")
    active:SetSize(300, 28)
    active:SetPoint("TOPLEFT", 24, -160)
    active:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    active:SetBackdropColor(0.025, 0.04, 0.075, 0.75)
    active:SetBackdropBorderColor(0.12, 0.38, 0.72, 0.7)
    local activeText = FUI:CreateFont(active, 12)
    activeText:SetPoint("LEFT", 9, 0)
    activeText:SetText("Default")
    activeText:SetTextColor(0.6, 0.68, 0.8)
    local actions = {
        { "New profile", 24 }, { "Rename", 180 }, { "Delete", 336 },
        { "Import", 24, -275 }, { "Export", 180, -275 }, { "Copy from", 336, -275 },
    }
    for index, info in ipairs(actions) do
        local y = info[3] or -215
        local button = AddButton(page, info[1], info[2], y, 140, function() end)
        button:Disable()
        button:GetFontString():SetTextColor(0.42, 0.48, 0.58)
    end
    local note = FUI:CreateFont(page, 12)
    note:SetPoint("TOPLEFT", 24, -345)
    note:SetWidth(620)
    note:SetJustifyH("LEFT")
    note:SetTextColor(0.58, 0.7, 0.88)
    note:SetText("The profile page is reserved now so the navigation and layout remain stable. Profile naming, character/spec assignment, copying, and import/export will be enabled when the profile backend is implemented.")
end

local function BuildQuesting(page)
    AddTitle(page, "Questing", "Quest locations and a FlowdiUI-hosted tracker powered by the installed Forever quest database.")
    local db = FUI.db.questing
    AddSection(page, "Integration", -105)
    AddCheckbox(page, "Enable quest integration", 24, -128, function() return db.enabled end, function(v) db.enabled = v end)
    AddCheckbox(page, "Attach tracker to FlowdiUI", 330, -128, function() return db.integrateTracker end, function(v) db.integrateTracker = v end)
    AddCheckbox(page, "Fit tracker height to quests", 24, -168, function() return db.autoTrackerHeight end, function(v) db.autoTrackerHeight = v end)
    AddSection(page, "Map pins", -215)
    AddCheckbox(page, "World map icons", 24, -238, function() return db.worldMapIcons end, function(v) db.worldMapIcons = v end)
    AddCheckbox(page, "Minimap icons", 330, -238, function() return db.minimapIcons end, function(v) db.minimapIcons = v end)
    AddCheckbox(page, "Kill and loot objectives", 24, -278, function() return db.showObjectives end, function(v) db.showObjectives = v end)
    AddCheckbox(page, "Available quest givers", 330, -278, function() return db.showQuestGivers end, function(v) db.showQuestGivers = v end)
    AddCheckbox(page, "Quest turn-ins", 24, -318, function() return db.showTurnIns end, function(v) db.showTurnIns = v end)
    AddSection(page, "Provider", -385)
    local provider = FUI:CreateFont(page, 12)
    provider:SetPoint("TOPLEFT", 24, -411)
    provider:SetWidth(760)
    provider:SetJustifyH("LEFT")
    provider:SetTextColor(0.58, 0.7, 0.88)
    local questModule = FUI.modules.questing
    local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Questie")) or (IsAddOnLoaded and IsAddOnLoaded("Questie"))
    local state = questModule and questModule.providerState
    provider:SetText(loaded and
        "Questie and QuestieDB are active. FlowdiUI hosts the tracker while Questie supplies objective, loot, kill, quest-giver, and turn-in locations." or
        (state == "reload" and "Questie and QuestieDB were installed but disabled. FlowdiUI enabled them; reload once to activate quest locations and map pins." or
        "Questie and QuestieDB are not active. Install their Forever/Camelot versions to supply quest coordinates and map pins."))
    local note = FUI:CreateFont(page, 11)
    note:SetPoint("TOPLEFT", provider, "BOTTOMLEFT", 0, -12)
    note:SetWidth(760)
    note:SetJustifyH("LEFT")
    note:SetTextColor(0.46, 0.52, 0.62)
    note:SetText("Tracker width, height, background and placement remain controlled under Utility & Tracker → Objective Tracker and Unlock Mode.")
end

local function BuildQuickLoot(page)
    AddTitle(page, "Quick Loot", "Loot immediately during auto-loot and show the result in a compact movable FlowdiUI feed.")
    local db = FUI.db.quickLoot
    AddSection(page, "Loot behavior", -105)
    AddCheckbox(page, "Enable Quick Loot", 24, -128, function() return db.enabled end, function(v) db.enabled = v end)
    AddCheckbox(page, "Hide Blizzard loot window", 330, -128, function() return db.hideLootWindow end, function(v) db.hideLootWindow = v end)
    AddSection(page, "Loot feed", -195)
    AddCheckbox(page, "Show loot feed", 24, -218, function() return db.feedEnabled end, function(v) db.feedEnabled = v end)
    AddSlider(page, "Visible entries", 24, -275, 280, 3, 10, 1, function() return db.feedRows end, function(v) db.feedRows = v end, function(v) return string.format("%d", v) end)
    AddSlider(page, "Display duration", 350, -275, 280, 1, 10, 0.5, function() return db.feedDuration end, function(v) db.feedDuration = v end, function(v) return string.format("%.1f s", v) end)
    AddSlider(page, "Icon size", 24, -365, 280, 16, 34, 1, function() return db.feedIconSize end, function(v) db.feedIconSize = v end, function(v) return string.format("%d px", v) end)
    local note = FUI:CreateFont(page, 11)
    note:SetPoint("TOPLEFT", 24, -455)
    note:SetWidth(760)
    note:SetJustifyH("LEFT")
    note:SetTextColor(0.58, 0.7, 0.88)
    note:SetText("Quick Loot only takes over when the game's auto-loot state is active. Holding the Auto Loot modifier keeps Blizzard's normal manual loot window. Move the feed through Unlock Mode.")
end

local builders = {
    general = BuildGeneral,
    actionBars = BuildActionBars,
    utilityFrames = BuildUtilityFrames,
    nameplates = BuildNameplates,
    unitFrames = BuildUnitFrames,
    groupFrames = BuildGroupFrames,
    chat = BuildChat,
    bags = BuildBags,
    minimap = BuildMinimap,
    questing = BuildQuesting,
    quickLoot = BuildQuickLoot,
    dataPanels = BuildDataPanels,
    darkMode = BuildDarkMode,
    profiles = BuildProfiles,
}

function FUI:SelectSettingsPage(key)
    if not self.settings then return end
    for pageKey, page in pairs(self.settings.pages) do
        page:SetShown(pageKey == key)
    end
    for buttonKey, button in pairs(self.settings.navButtons) do
        button.selected:SetShown(buttonKey == key)
        if buttonKey == key then
            button:GetFontString():SetTextColor(0.3, 0.68, 1)
            button.icon:SetVertexColor(0.35, 0.75, 1)
        else
            button:GetFontString():SetTextColor(0.7, 0.74, 0.8)
            button.icon:SetVertexColor(0.62, 0.66, 0.72)
        end
    end
    self.settings.selectedPage = key
end

function FUI:CreateSettings()
    if self.settings then return self.settings end
    self:DiscoverSharedMedia()

    local frame = CreateFrame("Frame", "FlowdiUISettings", UIParent, "BackdropTemplate")
    frame:SetSize(1080, 720)
    self:RestorePosition(frame, "settings")
    frame:SetScale(self.db.global.optionsScale or 1)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        FUI:SavePosition(self, "settings")
    end)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({ bgFile = self.textures.Flat, edgeFile = self.textures.Flat, edgeSize = 1 })
    frame:SetBackdropColor(0.018, 0.022, 0.028, 0.995)
    frame:SetBackdropBorderColor(unpack(self.colors.border))
    frame:Hide()
    tinsert(UISpecialFrames, frame:GetName())

    local topbar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    topbar:SetPoint("TOPLEFT", 1, -1)
    topbar:SetPoint("TOPRIGHT", -1, -1)
    topbar:SetHeight(40)
    topbar:SetBackdrop({ bgFile = self.textures.Flat, edgeFile = self.textures.Flat, edgeSize = 1 })
    topbar:SetBackdropColor(0.025, 0.03, 0.037, 1)
    topbar:SetBackdropBorderColor(0.13, 0.16, 0.2, 1)

    local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", topbar, "BOTTOMLEFT", 0, -1)
    sidebar:SetPoint("BOTTOMLEFT", 1, 1)
    sidebar:SetWidth(190)
    sidebar:SetBackdrop({ bgFile = self.textures.Flat, edgeFile = self.textures.Flat, edgeSize = 1 })
    sidebar:SetBackdropColor(0.023, 0.027, 0.033, 1)
    sidebar:SetBackdropBorderColor(0.12, 0.15, 0.19, 1)

    local logo = topbar:CreateTexture(nil, "ARTWORK")
    logo:SetTexture(self.media.logo)
    logo:SetSize(30, 30)
    logo:SetPoint("LEFT", 7, 0)

    local brand = self:CreateFont(topbar, 18)
    brand:SetPoint("LEFT", logo, "RIGHT", 7, 0)
    brand:SetText("Flowdi|cff39aaffUI|r")

    local version = self:CreateFont(sidebar, 10)
    version:SetPoint("BOTTOMLEFT", 10, 8)
    version:SetTextColor(0.42, 0.47, 0.54)
    version:SetText("v" .. self.version .. "  •  Forever")

    frame.pages = {}
    frame.navButtons = {}
    local unlock = AddButton(topbar, "Unlock Mode", 0, 0, 108, function() FUI:EnterUnlockMode() end)
    unlock:ClearAllPoints()
    unlock:SetPoint("RIGHT", topbar, "RIGHT", -39, 0)
    unlock:SetSize(108, 28)
    unlock:SetBackdropBorderColor(0.2, 0.62, 0.95, 1)
    unlock:SetScript("OnClick", function() FUI:EnterUnlockMode() end)
    frame.unlockButton = unlock

    local topClose = AddButton(topbar, "X", 0, 0, 28, function() frame:Hide() end)
    topClose:ClearAllPoints()
    topClose:SetPoint("RIGHT", topbar, "RIGHT", -6, 0)
    topClose:SetSize(28, 28)

    frame.navSections = {}
    local function EnsureSection(name)
        if frame.navSections[name] then return frame.navSections[name] end
        local header = self:CreateFont(sidebar, 9)
        header:SetText(name)
        header:SetTextColor(0.44, 0.49, 0.56)
        frame.navSections[name] = header
        return header
    end
    for index, definition in ipairs(pages) do
        local pageKey = definition.key
        local button = CreateFrame("Button", nil, sidebar)
        button:SetSize(178, 27)
        button:SetNormalFontObject(GameFontNormal)
        button:SetText(definition.label)
        button:GetFontString():SetFont(self.media.font, 11)
        button:GetFontString():ClearAllPoints()
        button:GetFontString():SetPoint("LEFT", 34, 0)
        button:GetFontString():SetJustifyH("LEFT")

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("LEFT", 10, 0)
        icon:SetTexture(definition.icon)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:SetDesaturated(true)
        button.icon = icon

        local hover = button:CreateTexture(nil, "HIGHLIGHT")
        hover:SetAllPoints()
        hover:SetColorTexture(0.08, 0.28, 0.58, 0.35)
        local selected = button:CreateTexture(nil, "BACKGROUND")
        selected:SetAllPoints()
        selected:SetColorTexture(0.025, 0.2, 0.3, 0.9)
        selected:Hide()
        button.selected = selected
        button:SetScript("OnClick", function() FUI:SelectSettingsPage(pageKey) end)
        frame.navButtons[pageKey] = button
        EnsureSection(definition.section)

        local page = CreateFrame("Frame", nil, frame)
        page:SetPoint("TOPLEFT", topbar, "BOTTOMLEFT", 191, -1)
        page:SetPoint("BOTTOMRIGHT", -1, 48)
        page.controls = {}
        page.settingsSection = definition.section
        builders[pageKey](page)
        page:Hide()
        frame.pages[pageKey] = page
    end


    local function LayoutNavigation(query)
        local y = -10
        local activeSection
        for _, header in pairs(frame.navSections) do header:Hide() end
        for _, definition in ipairs(pages) do
            local button = frame.navButtons[definition.key]
            local matches = not query or query == "" or definition.label:lower():find(query, 1, true)
            button:SetShown(matches)
            if matches then
                if activeSection ~= definition.section then
                    activeSection = definition.section
                    local header = frame.navSections[activeSection]
                    header:ClearAllPoints()
                    header:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 10, y)
                    header:Show()
                    y = y - 19
                end
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 6, y)
                y = y - 29
            end
        end
    end
    LayoutNavigation("")

    local search = CreateFrame("EditBox", nil, topbar, "InputBoxTemplate")
    search:SetPoint("LEFT", brand, "RIGHT", 20, 0)
    search:SetPoint("RIGHT", unlock, "LEFT", -18, 0)
    search:SetHeight(27)
    search:SetAutoFocus(false)
    search:SetFont(self.media.font, 11, "")
    search:SetTextInsets(8, 8, 0, 0)
    search.Instructions = self:CreateFont(search, 10)
    search.Instructions:SetPoint("LEFT", 8, 0)
    search.Instructions:SetTextColor(0.42, 0.52, 0.68)
    search.Instructions:SetText("Search settings...")
    self:SkinEditBox(search)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    search:SetScript("OnTextChanged", function(self)
        local query = self:GetText():lower()
        self.Instructions:SetShown(query == "")
        LayoutNavigation(query)
    end)
    frame.search = search

    local footer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    footer:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMRIGHT", 1, 1)
    footer:SetPoint("BOTTOMRIGHT", -1, 1)
    footer:SetHeight(47)
    footer:SetBackdrop({ bgFile = self.textures.Flat, edgeFile = self.textures.Flat, edgeSize = 1 })
    footer:SetBackdropColor(0.023, 0.027, 0.033, 1)
    footer:SetBackdropBorderColor(0.12, 0.15, 0.19, 1)

    local reloadNotice = self:CreateFont(footer, 11)
    reloadNotice:SetPoint("LEFT", 18, 0)
    reloadNotice:SetTextColor(1, 0.7, 0.2)
    reloadNotice:SetText("Module change requires a UI reload")
    reloadNotice:Hide()
    frame.reloadNotice = reloadNotice

    local reload = AddButton(footer, "Reload UI", 0, 0, 120, ReloadUI)
    reload:ClearAllPoints()
    reload:SetPoint("RIGHT", footer, "RIGHT", -112, 0)
    local close = AddButton(footer, "Close", 0, 0, 92, function() frame:Hide() end)
    close:ClearAllPoints()
    close:SetPoint("RIGHT", footer, "RIGHT", -10, 0)

    local function AddDragEdge(pointA, relativePointA, xA, yA, pointB, relativePointB, xB, yB)
        local handle = CreateFrame("Frame", nil, frame)
        handle:SetPoint(pointA, frame, relativePointA, xA, yA)
        handle:SetPoint(pointB, frame, relativePointB, xB, yB)
        handle:SetFrameLevel(frame:GetFrameLevel() + 50)
        handle:EnableMouse(true)
        handle:RegisterForDrag("LeftButton")
        handle:SetScript("OnDragStart", function()
            if not InCombatLockdown() then frame:StartMoving() end
        end)
        handle:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing()
            FUI:SavePosition(frame, "settings")
        end)
        return handle
    end
    local topEdge = AddDragEdge("TOPLEFT", "TOPLEFT", 0, 0, "BOTTOMRIGHT", "TOPRIGHT", 0, -8)
    local bottomEdge = AddDragEdge("BOTTOMLEFT", "BOTTOMLEFT", 0, 0, "TOPRIGHT", "BOTTOMRIGHT", 0, 8)
    local leftEdge = AddDragEdge("TOPLEFT", "TOPLEFT", 0, -8, "BOTTOMRIGHT", "BOTTOMLEFT", 8, 8)
    local rightEdge = AddDragEdge("TOPRIGHT", "TOPRIGHT", 0, -8, "BOTTOMLEFT", "BOTTOMRIGHT", -8, 8)
    frame.dragEdges = { topEdge, bottomEdge, leftEdge, rightEdge }

    frame:SetScript("OnShow", function(self)
        FUI:SelectSettingsPage(self.selectedPage or "general")
        for _, page in pairs(self.pages) do
            for _, control in ipairs(page.controls) do
                local onShow = control:GetScript("OnShow")
                if onShow then onShow(control) end
            end
        end
    end)

    self.settings = frame
    return frame
end

function FUI:OpenSettings()
    self:CreateSettings():Show()
end

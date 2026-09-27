local _, ns = ...
local FUI = ns.FUI

local pages = {
    { key = "general", label = "Global Settings" },
    { key = "actionBars", label = "Action Bars" },
    { key = "nameplates", label = "Nameplates" },
    { key = "unitFrames", label = "Unit Frames" },
    { key = "groupFrames", label = "Party & Raid Frames" },
    { key = "chat", label = "Chat" },
    { key = "bags", label = "Bags" },
    { key = "dataPanels", label = "Data Panels" },
    { key = "darkMode", label = "Dark Mode & Skins" },
}

local function AddTitle(parent, title, description)
    local heading = FUI:CreateFont(parent, 25)
    heading:SetPoint("TOPLEFT", 24, -22)
    heading:SetText(title)

    local text = FUI:CreateFont(parent, 12)
    text:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -7)
    text:SetPoint("RIGHT", parent, "RIGHT", -24, 0)
    text:SetJustifyH("LEFT")
    text:SetTextColor(0.58, 0.7, 0.88)
    text:SetText(description)

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(unpack(FUI.colors.accent))
    line:SetPoint("TOPLEFT", 24, -78)
    line:SetPoint("TOPRIGHT", -24, -78)
    line:SetHeight(1)
end

local function AddSection(parent, title, y)
    local text = FUI:CreateFont(parent, 11)
    text:SetPoint("TOPLEFT", 24, y)
    text:SetTextColor(0.35, 0.65, 1)
    text:SetText(title:upper())
    return text
end

local function AddCheckbox(parent, label, x, y, getter, setter, reloadRequired)
    local box = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    box:SetPoint("TOPLEFT", x, y)
    box.Text:SetText(label)
    box.Text:SetFont(FUI.media.font, 12)
    box.getter = getter
    box:SetScript("OnShow", function(self) self:SetChecked(self.getter()) end)
    box:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
        if reloadRequired then
            FUI.settings.reloadNotice:Show()
        else
            FUI:ApplySettings()
        end
    end)
    parent.controls[#parent.controls + 1] = box
    return box
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

    local valueText = FUI:CreateFont(valueBox, 11)
    valueText:SetPoint("CENTER")
    valueText:SetTextColor(0.45, 0.78, 1)

    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y - 24)
    slider:SetWidth(width - 70)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    if slider.Low then slider.Low:SetText("") end
    if slider.High then slider.High:SetText("") end
    if slider.Text then slider.Text:SetText("") end
    slider.getter = getter
    slider.refreshing = false
    slider:SetScript("OnShow", function(self)
        self.refreshing = true
        self:SetValue(self.getter())
        self.refreshing = false
        valueText:SetText(formatter and formatter(self:GetValue()) or string.format("%.2f", self:GetValue()))
    end)
    slider:SetScript("OnValueChanged", function(self, value)
        valueText:SetText(formatter and formatter(value) or string.format("%.2f", value))
        if not self.refreshing then
            setter(value)
            FUI:ApplySettings()
        end
    end)
    parent.controls[#parent.controls + 1] = slider
    return slider
end

local function AddButton(parent, label, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 150, 26)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(label)
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

local function AddModuleSwitch(page, moduleKey)
    AddCheckbox(page, "Enable module", 24, -98,
        function() return FUI.db.modules[moduleKey] ~= false end,
        function(value) FUI.db.modules[moduleKey] = value end,
        true)
end

local function BuildGeneral(page)
    AddTitle(page, "Global Settings", "Shared appearance, media and quality-of-life options for every FlowdiUI module.")
    local tabNames = { "General", "Style", "Fonts", "Textures", "Colors", "Improvements" }
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
    AddCheckbox(general, "Lock all movers", 280, -25, function() return FUI.db.locked end, function(v) FUI:SetLocked(v) end)
    AddSlider(general, "FlowdiUI scale", 6, -75, 270, 0.75, 1.25, 0.05, function() return FUI.db.scale end, function(v) FUI.db.scale = v end, function(v) return string.format("%d%%", v * 100) end)
    AddSlider(general, "Game menu scale", 330, -75, 270, 0.75, 1.35, 0.05, function() return FUI.db.global.gameMenuScale end, function(v) FUI.db.global.gameMenuScale = v end, function(v) return string.format("%d%%", v * 100) end)
    AddSection(general, "Combat & camera", -158)
    AddCheckbox(general, "Cast actions on key down", 6, -180, function() return FUI.db.global.castOnKeyDown end, function(v) FUI.db.global.castOnKeyDown = v end)
    AddSlider(general, "Maximum camera distance", 330, -177, 270, 1, 2.6, 0.1, function() return FUI.db.global.maxCameraDistance end, function(v) FUI.db.global.maxCameraDistance = v end, function(v) return string.format("%.1f", v) end)
    AddSection(general, "Automation", -260)
    AddCycle(general, "Auto repair", 6, -282, 180, { "None", "Player", "Guild" }, function() return FUI.db.global.autoRepair end, function(v) FUI.db.global.autoRepair = v end)
    AddCheckbox(general, "Auto track reputation", 270, -303, function() return FUI.db.global.autoTrackReputation end, function(v) FUI.db.global.autoTrackReputation = v end)
    AddButton(general, "Unlock movers", 6, -370, 150, function() FUI:SetLocked(false) end)
    AddButton(general, "Reset positions", 168, -370, 150, function() FUI:ResetPositions() end)
    AddButton(general, "Reset all settings", 330, -370, 170, function() FlowdiUIDB = nil ReloadUI() end)

    local style = panels.Style
    AddSection(style, "Style presets", -4)
    local function ApplyPreset(name)
        local db = FUI.db.global
        db.style = name
        if name == "FlowdiUI" then
            db.font = "Friz Quadrata"
            db.primaryTexture = "FlowdiUI"
            db.secondaryTexture = "FlowdiUI Blank"
            db.accent = { 0.18, 0.55, 1, 1 }
        elseif name == "Blizzard" then
            db.font = "Friz Quadrata"
            db.primaryTexture = "Blizzard"
            db.accent = { 0.95, 0.72, 0.18, 1 }
        else
            db.font = "Morpheus"
            db.primaryTexture = "Raid"
            db.accent = { 0.62, 0.45, 0.25, 1 }
        end
        FUI:ApplySettings()
    end
    AddButton(style, "FlowdiUI", 6, -32, 180, function() ApplyPreset("FlowdiUI") end)
    AddButton(style, "Blizzard", 210, -32, 180, function() ApplyPreset("Blizzard") end)
    AddButton(style, "Classic", 414, -32, 180, function() ApplyPreset("Classic") end)
    AddSection(style, "Current style", -92)
    AddCycle(style, "Base style", 6, -116, 220, { "FlowdiUI", "Blizzard", "Classic" }, function() return FUI.db.global.style end, ApplyPreset)
    local note = FUI:CreateFont(style, 12)
    note:SetPoint("TOPLEFT", 6, -190)
    note:SetWidth(590)
    note:SetJustifyH("LEFT")
    note:SetTextColor(0.58, 0.7, 0.88)
    note:SetText("Presets provide a coherent starting point. Fonts, textures and colors remain independently adjustable in the tabs above.")

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
    AddTitle(page, "Action Bars", "Scale and label the secure Blizzard action buttons.")
    AddModuleSwitch(page, "actionBars")
    AddSlider(page, "Button scale", 24, -155, 310, 0.70, 1.30, 0.05,
        function() return FUI.db.actionBars.scale end,
        function(value) FUI.db.actionBars.scale = value end,
        function(value) return string.format("%d%%", value * 100) end)
    AddCheckbox(page, "Show keybinds", 24, -230,
        function() return FUI.db.actionBars.showHotkeys end,
        function(value) FUI.db.actionBars.showHotkeys = value end)
    AddCheckbox(page, "Show macro names", 300, -230,
        function() return FUI.db.actionBars.showMacroText end,
        function(value) FUI.db.actionBars.showMacroText = value end)
end

local function BuildNameplates(page)
    AddTitle(page, "Nameplates", "Dimensions and typography for Blizzard nameplates.")
    AddModuleSwitch(page, "nameplates")
    AddSlider(page, "Width", 24, -155, 260, 70, 240, 5,
        function() return FUI.db.nameplates.width end,
        function(value) FUI.db.nameplates.width = value end,
        function(value) return string.format("%d px", value) end)
    AddSlider(page, "Health bar height", 330, -155, 260, 6, 20, 1,
        function() return FUI.db.nameplates.height end,
        function(value) FUI.db.nameplates.height = value end,
        function(value) return string.format("%d px", value) end)
    AddSlider(page, "Cast bar height", 24, -240, 260, 4, 16, 1,
        function() return FUI.db.nameplates.castHeight end,
        function(value) FUI.db.nameplates.castHeight = value end,
        function(value) return string.format("%d px", value) end)
    AddSlider(page, "Name font size", 330, -240, 260, 8, 16, 1,
        function() return FUI.db.nameplates.fontSize end,
        function(value) FUI.db.nameplates.fontSize = value end,
        function(value) return string.format("%d px", value) end)
end

local function BuildUnitFrames(page)
    AddTitle(page, "Unit Frames", "Configure and position player, target and focus frames.")
    AddModuleSwitch(page, "unitFrames")
    AddSlider(page, "Frame scale", 24, -155, 260, 0.70, 1.35, 0.05,
        function() return FUI.db.unitFrames.scale end,
        function(value) FUI.db.unitFrames.scale = value end,
        function(value) return string.format("%d%%", value * 100) end)
    AddSlider(page, "Player width", 330, -155, 260, 150, 360, 5,
        function() return FUI.db.unitFrames.playerWidth end,
        function(value) FUI.db.unitFrames.playerWidth = value end,
        function(value) return string.format("%d px", value) end)
    AddSlider(page, "Target width", 24, -240, 260, 150, 360, 5,
        function() return FUI.db.unitFrames.targetWidth end,
        function(value) FUI.db.unitFrames.targetWidth = value end,
        function(value) return string.format("%d px", value) end)
    AddSlider(page, "Focus width", 330, -240, 260, 120, 300, 5,
        function() return FUI.db.unitFrames.focusWidth end,
        function(value) FUI.db.unitFrames.focusWidth = value end,
        function(value) return string.format("%d px", value) end)
    AddSlider(page, "Frame height", 24, -325, 260, 30, 80, 1,
        function() return FUI.db.unitFrames.height end,
        function(value) FUI.db.unitFrames.height = value end,
        function(value) return string.format("%d px", value) end)
    AddSlider(page, "Power bar height", 330, -325, 260, 4, 18, 1,
        function() return FUI.db.unitFrames.powerHeight end,
        function(value) FUI.db.unitFrames.powerHeight = value end,
        function(value) return string.format("%d px", value) end)
    AddSlider(page, "Font size", 24, -410, 260, 8, 18, 1,
        function() return FUI.db.unitFrames.fontSize end,
        function(value) FUI.db.unitFrames.fontSize = value end,
        function(value) return string.format("%d px", value) end)
    AddButton(page, "Unlock frames", 330, -420, 170, function() FUI:SetLocked(false) end)
end

local function BuildGroupFrames(page)
    AddTitle(page, "Party & Raid Frames", "Separate sizing and scaling for party and raid frames.")
    AddModuleSwitch(page, "groupFrames")
    AddSlider(page, "Party scale", 24, -155, 260, 0.65, 1.35, 0.05,
        function() return FUI.db.groupFrames.partyScale end,
        function(value) FUI.db.groupFrames.partyScale = value end,
        function(value) return string.format("%d%%", value * 100) end)
    AddSlider(page, "Raid scale", 330, -155, 260, 0.60, 1.30, 0.05,
        function() return FUI.db.groupFrames.raidScale end,
        function(value) FUI.db.groupFrames.raidScale = value end,
        function(value) return string.format("%d%%", value * 100) end)
    AddSlider(page, "Party width", 24, -240, 260, 120, 300, 5,
        function() return FUI.db.groupFrames.partyWidth end,
        function(value) FUI.db.groupFrames.partyWidth = value end,
        function(value) return string.format("%d px", value) end)
    AddSlider(page, "Party height", 330, -240, 260, 24, 70, 1,
        function() return FUI.db.groupFrames.partyHeight end,
        function(value) FUI.db.groupFrames.partyHeight = value end,
        function(value) return string.format("%d px", value) end)
    AddSlider(page, "Raid width", 24, -325, 260, 50, 140, 2,
        function() return FUI.db.groupFrames.raidWidth end,
        function(value) FUI.db.groupFrames.raidWidth = value end,
        function(value) return string.format("%d px", value) end)
    AddSlider(page, "Raid height", 330, -325, 260, 18, 50, 1,
        function() return FUI.db.groupFrames.raidHeight end,
        function(value) FUI.db.groupFrames.raidHeight = value end,
        function(value) return string.format("%d px", value) end)
    AddSlider(page, "Font size", 24, -410, 260, 7, 16, 1,
        function() return FUI.db.groupFrames.fontSize end,
        function(value) FUI.db.groupFrames.fontSize = value end,
        function(value) return string.format("%d px", value) end)
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
    AddSlider(page, "Visible for", 24, -375, 310, 15, 300, 15,
        function() return FUI.db.chat.timeVisible end,
        function(value) FUI.db.chat.timeVisible = value end,
        function(value) return string.format("%d seconds", value) end)
end

local function BuildBags(page)
    AddTitle(page, "Bags", "Dark styling and item information for Blizzard bags.")
    AddModuleSwitch(page, "bags")
    AddSlider(page, "Darkness", 24, -155, 310, 0.35, 1, 0.05,
        function() return FUI.db.bags.darkness end,
        function(value) FUI.db.bags.darkness = value end,
        function(value) return string.format("%d%%", value * 100) end)
    AddCheckbox(page, "Show item level", 24, -235,
        function() return FUI.db.bags.itemLevel end,
        function(value) FUI.db.bags.itemLevel = value end)
    AddCheckbox(page, "Quality-colored borders", 300, -235,
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
    info:SetText("Unlock movers to drag the primary and second panels. The Minimap panel follows the Minimap automatically.")

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

local builders = {
    general = BuildGeneral,
    actionBars = BuildActionBars,
    nameplates = BuildNameplates,
    unitFrames = BuildUnitFrames,
    groupFrames = BuildGroupFrames,
    chat = BuildChat,
    bags = BuildBags,
    dataPanels = BuildDataPanels,
    darkMode = BuildDarkMode,
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
        else
            button:GetFontString():SetTextColor(0.78, 0.84, 1)
        end
    end
    self.settings.selectedPage = key
end

function FUI:CreateSettings()
    if self.settings then return self.settings end

    local frame = CreateFrame("Frame", "FlowdiUISettings", UIParent, "BackdropTemplate")
    frame:SetSize(960, 620)
    self:RestorePosition(frame, "settings")
    frame:SetScale(self.db.global.optionsScale or 1)
    frame:SetMovable(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({ bgFile = self.textures.Flat, edgeFile = self.textures.Flat, edgeSize = 1 })
    frame:SetBackdropColor(0.012, 0.02, 0.04, 0.985)
    frame:SetBackdropBorderColor(unpack(self.colors.border))
    frame:Hide()
    tinsert(UISpecialFrames, frame:GetName())

    local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", 1, -1)
    sidebar:SetPoint("BOTTOMLEFT", 1, 1)
    sidebar:SetWidth(220)
    sidebar:SetBackdrop({ bgFile = self.textures.Flat, edgeFile = self.textures.Flat, edgeSize = 1 })
    sidebar:SetBackdropColor(0.018, 0.03, 0.065, 1)
    sidebar:SetBackdropBorderColor(0.05, 0.18, 0.4, 1)

    local logo = sidebar:CreateTexture(nil, "ARTWORK")
    logo:SetTexture(self.media.logo)
    logo:SetSize(104, 104)
    logo:SetPoint("TOP", 0, -15)

    local brand = self:CreateFont(sidebar, 20)
    brand:SetPoint("TOP", logo, "BOTTOM", 0, -2)
    brand:SetText("FlowdiUI")

    local version = self:CreateFont(sidebar, 10)
    version:SetPoint("TOP", brand, "BOTTOM", 0, -3)
    version:SetTextColor(0.38, 0.65, 1)
    version:SetText("FOREVER  •  " .. self.version)

    frame.pages = {}
    frame.navButtons = {}
    for index, definition in ipairs(pages) do
        local pageKey = definition.key
        local button = CreateFrame("Button", nil, sidebar)
        button:SetSize(198, 34)
        button:SetPoint("TOPLEFT", 11, -195 - (index - 1) * 39)
        button:SetNormalFontObject(GameFontNormal)
        button:SetText(definition.label)
        button:GetFontString():SetFont(self.media.font, 12)
        button:GetFontString():ClearAllPoints()
        button:GetFontString():SetPoint("LEFT", 13, 0)
        button:GetFontString():SetJustifyH("LEFT")

        local hover = button:CreateTexture(nil, "HIGHLIGHT")
        hover:SetAllPoints()
        hover:SetColorTexture(0.08, 0.28, 0.58, 0.35)
        local selected = button:CreateTexture(nil, "BACKGROUND")
        selected:SetAllPoints()
        selected:SetColorTexture(0.05, 0.22, 0.48, 0.72)
        selected:Hide()
        button.selected = selected
        button:SetScript("OnClick", function() FUI:SelectSettingsPage(pageKey) end)
        frame.navButtons[pageKey] = button

        local page = CreateFrame("Frame", nil, frame)
        page:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 1, -1)
        page:SetPoint("BOTTOMRIGHT", -1, 48)
        page.controls = {}
        builders[pageKey](page)
        page:Hide()
        frame.pages[pageKey] = page
    end


    local search = CreateFrame("EditBox", nil, sidebar, "InputBoxTemplate")
    search:SetSize(190, 26)
    search:SetPoint("TOPLEFT", 15, -158)
    search:SetAutoFocus(false)
    search:SetFont(self.media.font, 11, "")
    search:SetTextInsets(8, 8, 0, 0)
    search.Instructions = self:CreateFont(search, 10)
    search.Instructions:SetPoint("LEFT", 8, 0)
    search.Instructions:SetTextColor(0.42, 0.52, 0.68)
    search.Instructions:SetText("Search features...")
    self:SkinEditBox(search)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    search:SetScript("OnTextChanged", function(self)
        local query = self:GetText():lower()
        self.Instructions:SetShown(query == "")
        local visibleIndex = 0
        for _, definition in ipairs(pages) do
            local button = frame.navButtons[definition.key]
            local matches = query == "" or definition.label:lower():find(query, 1, true)
            button:SetShown(matches)
            if matches then
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", 11, -195 - visibleIndex * 39)
                visibleIndex = visibleIndex + 1
            end
        end
    end)
    frame.search = search

    local footer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    footer:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMRIGHT", 1, 1)
    footer:SetPoint("BOTTOMRIGHT", -1, 1)
    footer:SetHeight(47)
    footer:SetBackdrop({ bgFile = self.textures.Flat, edgeFile = self.textures.Flat, edgeSize = 1 })
    footer:SetBackdropColor(0.018, 0.03, 0.055, 1)
    footer:SetBackdropBorderColor(0.05, 0.18, 0.4, 1)

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

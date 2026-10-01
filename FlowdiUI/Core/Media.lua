local _, ns = ...
local FUI = ns.FUI

FUI.media.logo = "Interface\\AddOns\\FlowdiUI\\Media\\Logo.tga"
FUI.media.statusbar = "Interface\\Buttons\\WHITE8X8"
FUI.media.font = "Fonts\\FRIZQT__.TTF"
FUI.media.fontBold = "Fonts\\FRIZQT__.TTF"

FUI.fonts = {
    ["2002"] = "Fonts\\2002.TTF",
    ["2002 Bold"] = "Fonts\\2002B.TTF",
    ["Continuum Medium"] = "Interface\\AddOns\\FlowdiUI\\Media\\Fonts\\ContinuumMedium.ttf",
    ["Expressway"] = "Interface\\AddOns\\FlowdiUI\\Media\\Fonts\\Expressway.ttf",
    ["Friz Quadrata"] = "Fonts\\FRIZQT__.TTF",
    ["Arial Narrow"] = "Fonts\\ARIALN.TTF",
    ["Morpheus"] = "Fonts\\MORPHEUS.TTF",
    ["Nimrod"] = "Fonts\\NIM_____.TTF",
    ["Skurri"] = "Fonts\\SKURRI.TTF",
}

FUI.textures = {
    ["Flat"] = "Interface\\Buttons\\WHITE8X8",
    ["Blizzard"] = "Interface\\TargetingFrame\\UI-StatusBar",
    ["Raid"] = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
    ["Minimalist"] = "Interface\\Buttons\\GREYSCALE-RAMP64",
    ["FlowdiUI"] = "Interface\\TargetingFrame\\UI-StatusBar",
    ["FlowdiUI Blank"] = "Interface\\Buttons\\WHITE8X8",
}

FUI.colors = {
    background = { 0.025, 0.035, 0.065, 0.96 },
    backgroundSoft = { 0.04, 0.06, 0.11, 0.92 },
    border = { 0.11, 0.46, 1, 0.9 },
    accent = { 0.18, 0.55, 1, 1 },
    health = { 0.10, 0.65, 0.32, 1 },
    power = { 0.12, 0.38, 0.90, 1 },
    text = { 0.92, 0.96, 1, 1 },
}
FUI.backdrops = FUI.backdrops or {}

function FUI:DiscoverSharedMedia()
    if not LibStub then return end
    local media = LibStub("LibSharedMedia-3.0", true)
    if not media then return end
    for name, path in pairs(self.fonts) do media:Register("font", name, path) end
    for name, path in pairs(self.textures) do media:Register("statusbar", name, path) end
    for kind, destination in pairs({ font = self.fonts, statusbar = self.textures }) do
        local catalog = media:HashTable(kind)
        if catalog then
            for name, path in pairs(catalog) do
                local cleanName = tostring(name):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                if cleanName ~= "" and type(path) == "string" then destination[cleanName] = path end
            end
        end
    end
end

local function SortedKeys(source)
    local names = {}
    for name in pairs(source) do names[#names + 1] = name end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

function FUI:GetFontNames()
    return SortedKeys(self.fonts)
end

function FUI:GetTextureNames()
    return SortedKeys(self.textures)
end

function FUI:GetFontPath(name)
    if name == "Global" and self.db and self.db.global then name = self.db.global.font end
    if name == "Name Font" and self.db and self.db.global then name = self.db.global.nameFont end
    return self.fonts[name] or self.fonts["Friz Quadrata"]
end

function FUI:GetModuleFontPath(moduleKey)
    local global = self.db and self.db.global
    local selections = global and global.moduleFonts
    local selected = selections and selections[moduleKey] or "Global"
    if selected == "Name Font" then selected = global and global.nameFont or "Global" end
    return self:GetFontPath(selected)
end

function FUI:GetStatusBarTexture(secondary)
    local global = self.db and self.db.global
    local name = global and (secondary and global.secondaryTexture or global.primaryTexture) or "Flat"
    return self.textures[name] or self.textures.Flat
end

function FUI:RefreshMedia()
    local global = self.db and self.db.global
    if not global then return end
    self.media.font = self:GetFontPath(global.font)
    self.media.fontBold = self.media.font
    self.media.statusbar = self:GetStatusBarTexture(false)
    local opacity = global.backgroundOpacity or 0.96
    self.colors.accent = { unpack(global.accent or self.colors.accent) }
    self.colors.border = { self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 0.9 }
    self.colors.background = { global.background[1], global.background[2], global.background[3], opacity }
    self.colors.backgroundSoft = { global.background[1], global.background[2], global.background[3], math.max(0.5, opacity - 0.04) }
    self.colors.health = { unpack(global.health or self.colors.health) }
    self.colors.power = { unpack(global.power or self.colors.power) }
    for backdrop in pairs(self.backdrops) do
        if backdrop and backdrop.SetBackdropColor then
            backdrop:SetBackdrop({
                bgFile = self.textures.Flat,
                edgeFile = self.textures.Flat,
                edgeSize = global.thinBorders and 1 or 2,
            })
            backdrop:SetBackdropColor(unpack(self.colors.background))
            backdrop:SetBackdropBorderColor(unpack(self.colors.border))
        end
    end
end

function FUI:CreateBackdrop(frame, inset)
    if frame.FlowdiBackdrop then return frame.FlowdiBackdrop end
    local backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    backdrop:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
    backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", -(inset or 2), inset or 2)
    backdrop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", inset or 2, -(inset or 2))
    backdrop:SetBackdrop({
        bgFile = self.textures.Flat,
        edgeFile = self.textures.Flat,
        edgeSize = self.db and self.db.global.thinBorders and 1 or 2,
    })
    backdrop:SetBackdropColor(unpack(self.colors.background))
    backdrop:SetBackdropBorderColor(unpack(self.colors.border))
    frame.FlowdiBackdrop = backdrop
    self.backdrops[backdrop] = true
    return backdrop
end

function FUI:CreateFont(parent, size, flags)
    local font = parent:CreateFontString(nil, "OVERLAY")
    local global = self.db and self.db.global
    font:SetFont(self:GetFontPath(global and global.font), size or (global and global.fontSize) or 12, flags or (global and global.fontOutline) or "OUTLINE")
    font:SetTextColor(unpack(self.colors.text))
    return font
end

function FUI:SkinButton(button)
    if not button then return end
    local icon = button.icon or button.Icon or _G[button:GetName() and (button:GetName() .. "Icon")]
    if icon then
        if self.db and self.db.global.cropIcons then
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        else
            icon:SetTexCoord(0, 1, 0, 1)
        end
        icon:SetDrawLayer("ARTWORK")
    end
    if button.FlowdiSkinned then return end
    button.FlowdiSkinned = true
    local normal = button.GetNormalTexture and button:GetNormalTexture()
    if normal then normal:SetAlpha(0) end
    self:CreateBackdrop(button, 1)
end

function FUI:DarkenFrame(frame)
    if not frame or frame.FlowdiDarkened then return end
    frame.FlowdiDarkened = true
    local shade = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    shade:SetColorTexture(unpack(self.colors.backgroundSoft))
    shade:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
    shade:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    frame.FlowdiShade = shade
end

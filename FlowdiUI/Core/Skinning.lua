local _, ns = ...
local FUI = ns.FUI

FUI.skinCallbacks = {}
FUI.appliedSkins = {}

local function IsLoaded(addonName)
    if not addonName then return true end
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(addonName)
    end
    return IsAddOnLoaded and IsAddOnLoaded(addonName)
end

function FUI:RegisterSkin(addonName, key, callback)
    self.skinCallbacks[#self.skinCallbacks + 1] = {
        addon = addonName,
        key = key,
        callback = callback,
    }
    if self.db and IsLoaded(addonName) then
        self:RunSkin(key, callback)
    end
end

function FUI:RunSkin(key, callback)
    if self.appliedSkins[key] or not self:IsModuleEnabled("darkMode") then return end
    local ok = self:SafeCall("Skin:" .. key, callback)
    if ok then self.appliedSkins[key] = true end
end

function FUI:RunAvailableSkins(addonName)
    for _, entry in ipairs(self.skinCallbacks) do
        if (not addonName or entry.addon == addonName) and IsLoaded(entry.addon) then
            self:RunSkin(entry.key, entry.callback)
        end
    end
end

function FUI:RefreshSkins()
    wipe(self.appliedSkins)
    self:RunAvailableSkins()
end

function FUI:StripTextures(frame, hide)
    if not frame or not frame.GetRegions then return end
    for _, region in ipairs({ frame:GetRegions() }) do
        if region and region.IsObjectType and region:IsObjectType("Texture") then
            if hide == false then
                region:SetDesaturated(true)
                region:SetVertexColor(0.12, 0.17, 0.28)
            else
                region:SetTexture(nil)
                region:Hide()
            end
        end
    end
end


function FUI:SkinWindow(frame, alpha)
    if not frame then return end
    self:StripTextures(frame)
    if frame.NineSlice then self:StripTextures(frame.NineSlice) end
    if frame.PortraitContainer and frame.PortraitContainer.portrait then
        frame.PortraitContainer.portrait:SetAlpha(0)
    end
    if frame.portrait then frame.portrait:SetAlpha(0) end

    if not frame.FlowdiWindowBackdrop then
        local backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        backdrop:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
        backdrop:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
        backdrop:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
        backdrop:SetBackdrop({ bgFile = self.textures.Flat, edgeFile = self.textures.Flat, edgeSize = 1 })
        frame.FlowdiWindowBackdrop = backdrop
    end
    local value = self.db.darkMode.intensity
    frame.FlowdiWindowBackdrop:SetBackdropColor(0.008, 0.014, 0.028, alpha or 0.96)
    frame.FlowdiWindowBackdrop:SetBackdropBorderColor(value * 0.75, value * 1.8, math.min(1, value * 4), 0.95)
end

function FUI:SkinInset(frame, alpha)
    if not frame then return end
    if frame.NineSlice then self:StripTextures(frame.NineSlice) end
    self:StripTextures(frame)
    if not frame.FlowdiInset then
        local backdrop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        backdrop:SetAllPoints()
        backdrop:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
        backdrop:SetBackdrop({ bgFile = self.textures.Flat, edgeFile = self.textures.Flat, edgeSize = 1 })
        frame.FlowdiInset = backdrop
    end
    frame.FlowdiInset:SetBackdropColor(0.012, 0.022, 0.045, alpha or 0.8)
    frame.FlowdiInset:SetBackdropBorderColor(0.06, 0.22, 0.48, 0.8)
end

function FUI:SkinCloseButton(button)
    if not button or button.FlowdiCloseSkinned then return end
    button.FlowdiCloseSkinned = true
    self:StripTextures(button)
    button:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    button:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    button:SetSize(26, 26)
end

function FUI:SkinEditBox(editBox)
    if not editBox then return end
    self:StripTextures(editBox)
    if editBox.Left then editBox.Left:Hide() end
    if editBox.Middle then editBox.Middle:Hide() end
    if editBox.Right then editBox.Right:Hide() end
    self:CreateBackdrop(editBox, 1)
end

function FUI:SkinScrollBar(scrollBar)
    if not scrollBar then return end
    self:StripTextures(scrollBar)
    if scrollBar.Track then self:StripTextures(scrollBar.Track) end
    if scrollBar.ScrollUpButton then self:SkinButton(scrollBar.ScrollUpButton) end
    if scrollBar.ScrollDownButton then self:SkinButton(scrollBar.ScrollDownButton) end
    local thumb = scrollBar.GetThumbTexture and scrollBar:GetThumbTexture()
    if thumb then
        thumb:SetColorTexture(unpack(self.colors.accent))
        thumb:SetWidth(6)
    end
end

function FUI:SkinTab(tab)
    if not tab or tab.FlowdiTabSkinned then return end
    tab.FlowdiTabSkinned = true
    self:StripTextures(tab)
    self:CreateBackdrop(tab, 1)
end

function FUI:SkinItemButton(button)
    if not button then return end
    local icon = button.icon or button.Icon or (button.GetName and button:GetName() and _G[button:GetName() .. "IconTexture"])
    if button.GetRegions then
        for _, region in ipairs({ button:GetRegions() }) do
            if region and region.IsObjectType and region:IsObjectType("Texture") and region ~= icon then
                region:SetTexture(nil)
                region:Hide()
            end
        end
    end
    self:SkinButton(button)
    local border = button.IconBorder or button.iconBorder
    if border then border:SetAlpha(0) end
end

function FUI:SkinStandardButton(button)
    if not button then return end
    self:StripTextures(button)
    self:CreateBackdrop(button, 1)
    local font = button.GetFontString and button:GetFontString()
    if font then font:SetTextColor(unpack(self.colors.text)) end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, addonName)
    if event == "PLAYER_LOGIN" then
        FUI:RunAvailableSkins()
    else
        FUI:RunAvailableSkins(addonName)
    end
end)

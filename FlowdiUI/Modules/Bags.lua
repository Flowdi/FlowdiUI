local _, ns = ...
local FUI = ns.FUI

local module = {}
FUI:RegisterModule("bags", module)

function module:ApplyCombinedBags()
    local enabled = FUI.db.bags.combined ~= false
    if SetCVar then pcall(SetCVar, "combinedBags", enabled and "1" or "0") end
    if not enabled and ContainerFrameCombinedBags and ContainerFrameCombinedBags:IsShown() then
        ContainerFrameCombinedBags:Hide()
    end
end

local function GetBagAndSlot(button)
    local bag
    if button.GetBagID then
        local ok, value = pcall(button.GetBagID, button)
        if ok then bag = value end
    end
    bag = bag or button.bagID or (button:GetParent() and button:GetParent():GetID())
    local slot = button.GetID and button:GetID() or button.slotID
    return bag, slot
end

function module:UpdateItem(button)
    if not button then return end
    local bag, slot = GetBagAndSlot(button)
    if bag == nil or not slot then return end
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if not info then
        if button.FlowdiItemLevel then button.FlowdiItemLevel:SetText("") end
        return
    end

    if not button.FlowdiItemLevel then
        local text = FUI:CreateFont(button, 9)
        text:SetPoint("BOTTOMRIGHT", -2, 2)
        text:SetTextColor(0.95, 0.95, 1)
        button.FlowdiItemLevel = text
    end
    if FUI.db.bags.itemLevel and info.hyperlink and C_Item and C_Item.GetDetailedItemLevelInfo then
        local level = C_Item.GetDetailedItemLevelInfo(info.hyperlink)
        button.FlowdiItemLevel:SetText(level and level > 1 and level or "")
    else
        button.FlowdiItemLevel:SetText("")
    end

    if button.FlowdiBackdrop then
        if FUI.db.bags.qualityBorders and info.quality and info.quality > 1 then
            local r, g, b = GetItemQualityColor(info.quality)
            button.FlowdiBackdrop:SetBackdropBorderColor(r or 0.1, g or 0.46, b or 1, 1)
        else
            button.FlowdiBackdrop:SetBackdropBorderColor(unpack(FUI.colors.border))
        end
    end
end

local function DarkenNineSlice(frame, value)
    if frame.NineSlice then
        for _, region in pairs({ frame.NineSlice:GetRegions() }) do
            if region and region.SetVertexColor then
                region:SetDesaturated(true)
                region:SetVertexColor(value, value * 1.25, value * 1.8)
            end
        end
    end
end

function module:StyleContainer(frame)
    if not frame then return end
    local brightness = math.max(0.05, 1 - FUI.db.bags.darkness)
    frame.FlowdiBagStyled = true
    DarkenNineSlice(frame, brightness)
    if not frame.FlowdiShade then FUI:DarkenFrame(frame) end
    if frame.FlowdiShade then frame.FlowdiShade:SetColorTexture(0.01, 0.02, 0.04, FUI.db.bags.darkness) end

    if frame.Items then
        for _, itemButton in ipairs(frame.Items) do
            FUI:SkinButton(itemButton)
            self:UpdateItem(itemButton)
        end
    end
    if frame.Bags then
        for _, bagButton in ipairs(frame.Bags) do
            FUI:SkinButton(bagButton)
        end
    end
end

function module:Apply()
    self:ApplyCombinedBags()
    self:StyleAll()
end

function module:StyleAll()
    self:StyleContainer(ContainerFrameCombinedBags)
    for index = 1, 13 do
        self:StyleContainer(_G["ContainerFrame" .. index])
    end

    if ContainerFrameCombinedBags then
        local children = { ContainerFrameCombinedBags:GetChildren() }
        for _, child in ipairs(children) do
            if child and child:IsObjectType("Button") then
                FUI:SkinButton(child)
                self:UpdateItem(child)
            end
        end
    end
end

function module:Initialize()
    self:Apply()
    local events = CreateFrame("Frame")
    events:RegisterEvent("BAG_UPDATE_DELAYED")
    events:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
    events:RegisterEvent("ADDON_LOADED")
    events:SetScript("OnEvent", function()
        module:StyleAll()
    end)

    if OpenAllBags then
        hooksecurefunc("OpenAllBags", function()
            module:ApplyCombinedBags()
            C_Timer.After(0, function() module:StyleAll() end)
        end)
    end
end

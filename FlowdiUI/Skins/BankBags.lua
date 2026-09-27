local _, ns = ...
local FUI = ns.FUI

local function SkinItemChildren(parent)
    if not parent or not parent.GetChildren then return end
    for _, child in ipairs({ parent:GetChildren() }) do
        if child and child.IsObjectType and child:IsObjectType("Button") then
            local icon = child.icon or child.Icon
            if icon then FUI:SkinItemButton(child) end
        end
    end
end

local function ApplyContainerSkin(container)
    if not container then return end
    FUI:SkinWindow(container)
    FUI:SkinCloseButton(container.CloseButton)
    FUI:SkinEditBox(container.SearchBox)
    SkinItemChildren(container)
    if container.Items then
        for _, item in ipairs(container.Items) do FUI:SkinItemButton(item) end
    end
    if container.Bags then
        for _, bag in ipairs(container.Bags) do FUI:SkinItemButton(bag) end
    end
end

local function ApplyBankBagSkin()
    ApplyContainerSkin(ContainerFrameCombinedBags)
    for index = 1, 13 do ApplyContainerSkin(_G["ContainerFrame" .. index]) end

    if BankFrame then
        FUI:SkinWindow(BankFrame)
        FUI:SkinCloseButton(BankFrame.CloseButton)
        FUI:SkinEditBox(BankItemSearchBox)
        if BankFrame.BankPanel then
            FUI:SkinInset(BankFrame.BankPanel)
            SkinItemChildren(BankFrame.BankPanel)
            FUI:SkinStandardButton(BankFrame.BankPanel.PurchaseButton)
            FUI:SkinStandardButton(BankFrame.BankPanel.AutoSortButton)
        end
        if BankFrame.TabSystem and BankFrame.TabSystem.tabs then
            for _, tab in ipairs(BankFrame.TabSystem.tabs) do FUI:SkinTab(tab) end
        end
    end

    FUI:SkinEditBox(BagItemSearchBox)
    FUI:SkinStandardButton(BagItemAutoSortButton)
end

FUI:RegisterSkin("Blizzard_UIPanels_Game", "BankAndBags", function()
    if not FUI.db.darkMode.skins.bankBags then return end
    ApplyBankBagSkin()
    local hookFrames = { ContainerFrameCombinedBags, BankFrame }
    for _, frame in pairs(hookFrames) do
        if frame and not frame.FlowdiShowHook then
            frame.FlowdiShowHook = true
            frame:HookScript("OnShow", ApplyBankBagSkin)
        end
    end
end)

local _, ns = ...
local FUI = ns.FUI

local function ApplyMerchantSkin()
    if not MerchantFrame then return end
    FUI:SkinWindow(MerchantFrame)
    FUI:SkinCloseButton(MerchantFrame.CloseButton or MerchantFrameCloseButtonButton)
    if MerchantFrame.FilterDropdown then FUI:SkinStandardButton(MerchantFrame.FilterDropdown) end
    for index = 1, 2 do FUI:SkinTab(_G["MerchantFrameTab" .. index]) end
    for index = 1, 12 do
        local item = _G["MerchantItem" .. index]
        if item then
            FUI:SkinInset(item)
            FUI:SkinItemButton(_G["MerchantItem" .. index .. "ItemButton"] or item.ItemButton)
        end
    end
    FUI:SkinItemButton(MerchantBuyBackItemItemButton)
    FUI:SkinButton(MerchantRepairItemButton)
    FUI:SkinButton(MerchantRepairAllButton)
    FUI:SkinButton(MerchantGuildBankRepairButton)
    FUI:SkinButton(MerchantSellAllJunkButton)
    FUI:SkinButton(MerchantPrevPageButton)
    FUI:SkinButton(MerchantNextPageButton)
end

FUI:RegisterSkin("Blizzard_UIPanels_Game", "Merchant", function()
    if not FUI.db.darkMode.skins.merchant then return end
    ApplyMerchantSkin()
    if MerchantFrame and not MerchantFrame.FlowdiShowHook then
        MerchantFrame.FlowdiShowHook = true
        MerchantFrame:HookScript("OnShow", ApplyMerchantSkin)
    end
end)

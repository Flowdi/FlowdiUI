local _, ns = ...
local FUI = ns.FUI

local function ApplyWorldMapSkin()
    if not WorldMapFrame then return end
    FUI:SkinWindow(WorldMapFrame, 0.93)
    if WorldMapFrame.BorderFrame then
        FUI:StripTextures(WorldMapFrame.BorderFrame)
        if WorldMapFrame.BorderFrame.NineSlice then FUI:StripTextures(WorldMapFrame.BorderFrame.NineSlice) end
        FUI:SkinCloseButton(WorldMapFrame.BorderFrame.CloseButton)
    end
    if WorldMapFrame.NavBar then
        FUI:SkinInset(WorldMapFrame.NavBar, 0.65)
        FUI:SkinStandardButton(WorldMapFrame.NavBar.HomeButton)
        FUI:SkinStandardButton(WorldMapFrame.NavBar.OverflowButton)
    end
    if QuestMapFrame then
        FUI:SkinInset(QuestMapFrame)
        local scroll = QuestMapFrame.QuestsFrame and QuestMapFrame.QuestsFrame.ScrollFrame
        if scroll then
            FUI:SkinEditBox(scroll.SearchBox)
            FUI:SkinScrollBar(scroll.ScrollBar)
        end
    end
end

FUI:RegisterSkin("Blizzard_WorldMap", "WorldMap", function()
    if not FUI.db.darkMode.skins.worldMap then return end
    ApplyWorldMapSkin()
    if WorldMapFrame and not WorldMapFrame.FlowdiShowHook then
        WorldMapFrame.FlowdiShowHook = true
        WorldMapFrame:HookScript("OnShow", ApplyWorldMapSkin)
    end
end)

local _, ns = ...
local FUI = ns.FUI

local module = {}
FUI:RegisterModule("nameplates", module)

local function AddPlateBorder(bar)
    if bar.FlowdiBorder then return end
    local border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetFrameLevel(math.max(0, bar:GetFrameLevel() - 1))
    border:SetBackdrop({ bgFile = FUI.textures.Flat, edgeFile = FUI.textures.Flat, edgeSize = 1 })
    border:SetBackdropColor(0.015, 0.02, 0.04, 0.9)
    border:SetBackdropBorderColor(0.08, 0.32, 0.75, 0.95)
    bar.FlowdiBorder = border
end

function module:StylePlate(unit)
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
    local frame = plate and plate.UnitFrame
    if not frame then return end

    local health = frame.healthBar or frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar
    if health then
        health:SetStatusBarTexture(FUI:GetStatusBarTexture(false))
        health:SetWidth(FUI.db.nameplates.width)
        health:SetHeight(FUI.db.nameplates.height)
        AddPlateBorder(health)
    end

    local cast = frame.castBar
    if cast then
        cast:SetStatusBarTexture(FUI:GetStatusBarTexture(true))
        cast:SetHeight(FUI.db.nameplates.castHeight)
        AddPlateBorder(cast)
    end

    local name = frame.name or frame.Name
    if name and name.SetFont then
        name:SetFont(FUI:GetModuleFontPath("nameplates"), FUI.db.nameplates.fontSize, FUI.db.global.fontOutline)
        name:SetShadowOffset(0, 0)
    end

    frame.FlowdiStyled = true
end

function module:Apply()
    self:StyleVisiblePlates()
end

function module:StyleVisiblePlates()
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        if plate.namePlateUnitToken then
            self:StylePlate(plate.namePlateUnitToken)
        end
    end
end

function module:Initialize()
    local events = CreateFrame("Frame")
    events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:SetScript("OnEvent", function(_, event, unit)
        if event == "NAME_PLATE_UNIT_ADDED" then
            module:StylePlate(unit)
        else
            module:StyleVisiblePlates()
        end
    end)
end

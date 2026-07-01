---@class DeathpoolMinimapControllerFrame: DeathpoolMainFrameShell
---@field IsShown fun(self: DeathpoolMinimapControllerFrame): boolean
---@field Show fun(self: DeathpoolMinimapControllerFrame)
---@field Hide fun(self: DeathpoolMinimapControllerFrame)
---@field Raise fun(self: DeathpoolMinimapControllerFrame)|nil

local DeathpoolUIMinimap = _G.DeathpoolUIMinimap or {}
local DeathpoolDatabase = _G.DeathpoolDatabase
local DeathpoolLogic = _G.DeathpoolLogic
local LibStub = _G.LibStub

DeathpoolUIMinimap.ENABLED = true
DeathpoolUIMinimap.ICON_PATH =  "Interface\\Icons\\INV_Misc_Bone_ElfSkull_01"

local MINIMAP_LAUNCHER_NAME = "Deathpool"
local LibDataBroker = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")
---@type MinimapLauncher|nil
local minimapLauncher = nil
local minimapButtonRegistered = false
---@type DeathpoolMinimapControllerFrame|nil
local activeFrame = nil
---@type DeathpoolCharacterState|nil
local activeDatabase = nil

---@param database DeathpoolCharacterState
---@return string
local function GetTooltipPredictionText(database)
    return DeathpoolLogic.FormatLockedPrediction(DeathpoolDatabase.GetLockedPrediction(database))
end

---@param database DeathpoolCharacterState
---@return string
local function GetTooltipScoreText(database)
    return DeathpoolLogic.FormatPoints(DeathpoolDatabase.GetTotalPoints(database))
end

---@return boolean
function DeathpoolUIMinimap.IsEnabled()
    return DeathpoolUIMinimap.ENABLED == true and LibDataBroker ~= nil and LibDBIcon ~= nil
end

---@param _ table|nil
---@param database DeathpoolCharacterState
---@return string|nil
function DeathpoolUIMinimap.RefreshLauncherText(_, database)
    if not DeathpoolUIMinimap.IsEnabled() or not minimapLauncher then
        return nil
    end

    minimapLauncher.text = GetTooltipScoreText(database)
    minimapLauncher.value = minimapLauncher.text
    minimapLauncher.suffix = ""
    return minimapLauncher.text
end

---@param _ table|nil
---@param database DeathpoolCharacterState
---@param hidden boolean
---@return boolean
function DeathpoolUIMinimap.SetHidden(_, database, hidden)
    DeathpoolDatabase.SetMinimapHidden(database, hidden)

    local libDBIcon = LibDBIcon
    if not DeathpoolUIMinimap.IsEnabled() or not libDBIcon then
        return DeathpoolDatabase.GetMinimapHidden(database)
    end

    if DeathpoolDatabase.GetMinimapHidden(database) then
        libDBIcon:Hide(MINIMAP_LAUNCHER_NAME)
    else
        libDBIcon:Show(MINIMAP_LAUNCHER_NAME)
    end

    return DeathpoolDatabase.GetMinimapHidden(database)
end

---@param frame DeathpoolMinimapControllerFrame|nil
---@param database DeathpoolCharacterState
---@return boolean
function DeathpoolUIMinimap.ToggleHidden(frame, database)
    return DeathpoolUIMinimap.SetHidden(frame, database, not DeathpoolDatabase.GetMinimapHidden(database))
end

---@param frame DeathpoolMinimapControllerFrame
local function RestoreOpenWindowState(frame)
    if frame.Raise then
        frame:Raise()
    end
end

---@param frame DeathpoolMinimapControllerFrame|nil
---@param database DeathpoolCharacterState
function DeathpoolUIMinimap.Toggle(frame, database)
    if not DeathpoolUIMinimap.IsEnabled() or not frame then
        return
    end

    if frame:IsShown() then
        DeathpoolDatabase.SetHidden(database, true)
        frame:Hide()
        return
    end

    DeathpoolDatabase.SetHidden(database, false)
    frame:Show()
    RestoreOpenWindowState(frame)
end

---@param frame DeathpoolMinimapControllerFrame|nil
---@param database DeathpoolCharacterState
function DeathpoolUIMinimap.Initialize(frame, database)
    local libDataBroker = LibDataBroker
    local libDBIcon = LibDBIcon
    if not DeathpoolUIMinimap.IsEnabled() or not frame or not libDataBroker or not libDBIcon then
        return
    end

    activeFrame = frame
    activeDatabase = database

    local minimapSettings = DeathpoolDatabase.GetMinimapSettings(database)

    if not minimapLauncher then
        minimapLauncher = libDataBroker:NewDataObject(MINIMAP_LAUNCHER_NAME, {
            type = "data source",
            label = MINIMAP_LAUNCHER_NAME,
            text = GetTooltipScoreText(database),
            value = GetTooltipScoreText(database),
            suffix = "",
            icon = DeathpoolUIMinimap.ICON_PATH,
            OnClick = function()
                DeathpoolUIMinimap.Toggle(activeFrame, activeDatabase)
            end,
            ---@param tooltip MinimapTooltip|nil
            OnTooltipShow = function(tooltip)
                if not tooltip then
                    return
                end

                tooltip:AddLine("Deathpool")
                tooltip:AddLine(GetTooltipPredictionText(activeDatabase), 1, 1, 1, true)
                tooltip:AddLine("Score: " .. GetTooltipScoreText(activeDatabase), 1, 0.82, 0)
            end,
        })
    end

    if minimapButtonRegistered then
        libDBIcon:Refresh(MINIMAP_LAUNCHER_NAME, minimapSettings)
    else
        libDBIcon:Register(MINIMAP_LAUNCHER_NAME, minimapLauncher, minimapSettings)
        minimapButtonRegistered = true
    end

    DeathpoolUIMinimap.RefreshLauncherText(frame, database)
    DeathpoolUIMinimap.SetHidden(frame, database, DeathpoolDatabase.GetMinimapHidden(database))
end

_G.DeathpoolUIMinimap = DeathpoolUIMinimap

return DeathpoolUIMinimap

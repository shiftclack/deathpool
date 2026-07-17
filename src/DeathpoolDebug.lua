---@alias DeathpoolDebugPrintMessage fun(message: string)
---@alias DeathpoolDebugDeathLike DeathpoolDeath|DeathpoolDeathEvent

---@class DeathpoolDebugDatabaseApi
---@field GetTotalPoints fun(database: DeathpoolCharacterState): integer
---@field GetCorrectPredictionStreak fun(database: DeathpoolCharacterState): integer
---@field GetLongestPredictionStreak fun(database: DeathpoolCharacterState): integer
---@field GetLockedPrediction fun(database: DeathpoolCharacterState): any
---@field GetRecentDeaths fun(database: DeathpoolCharacterState): DeathpoolDeath[]

---@class DeathpoolDebugFrame
---@field Show fun(self: DeathpoolDebugFrame)
---@field Hide fun(self: DeathpoolDebugFrame)
---@field RefreshLatestDeathDetails fun(self: DeathpoolDebugFrame, death: DeathpoolDebugDeathLike|nil, state: table)|nil

---@class DeathpoolDebugAddonFrame
---@field HandleBlizzardDeathMessage fun(self: DeathpoolDebugAddonFrame, message: string): boolean

local DeathpoolDebug = _G.DeathpoolDebug or {}
local DeathpoolDebugState = _G.DeathpoolDebugState or {}
---@type DeathpoolCharacterState|nil
local activeState = nil
---@type DeathpoolDebugDatabaseApi|nil
local activeDatabaseApi = nil
---@type DeathpoolDebugPrintMessage|nil
local activePrintMessage = nil
---@type DeathpoolDebugFrame|nil
local activeDebugFrame = nil
---@type DeathpoolDebugAddonFrame|nil
local activeAddonFrame = nil
local debugEnabled = false

_G.DeathpoolDebug = DeathpoolDebug
_G.DeathpoolDebugState = DeathpoolDebugState

local function Print(message)
    if activePrintMessage then
        activePrintMessage(message)
    end
end

---@param addonFrame DeathpoolDebugAddonFrame
---@param state DeathpoolCharacterState
---@param databaseApi DeathpoolDebugDatabaseApi
---@param debugFrame DeathpoolDebugFrame|nil
---@param printMessage DeathpoolDebugPrintMessage
function DeathpoolDebug.Initialize(addonFrame, state, databaseApi, debugFrame, printMessage)
    activeAddonFrame = addonFrame
    activeState = state
    activeDatabaseApi = databaseApi
    activeDebugFrame = debugFrame
    activePrintMessage = printMessage
    debugEnabled = false
end

---@return boolean
function DeathpoolDebugState.IsEnabled()
    return debugEnabled == true
end

---@param enabled boolean|nil
---@return boolean
function DeathpoolDebugState.SetEnabled(enabled)
    debugEnabled = enabled == true
    return debugEnabled
end

---@return boolean
function DeathpoolDebugState.Toggle()
    return DeathpoolDebugState.SetEnabled(not DeathpoolDebugState.IsEnabled())
end

---@param message any
function DeathpoolDebug.Print(message)
    if not DeathpoolDebugState.IsEnabled() then
        return
    end

    DeathpoolDebug.Log(message)
end

function DeathpoolDebug.Log(...)
    if not DeathpoolDebugState.IsEnabled() then
        return
    end

    if type(activePrintMessage) ~= "function" then
        return
    end

    local parts = {}
    for index = 1, select("#", ...) do
        parts[#parts + 1] = tostring(select(index, ...))
    end

    activePrintMessage(table.concat(parts, " "))
end

---@param death DeathpoolDebugDeathLike|nil
function DeathpoolDebug.DebugDeathData(death)
    if not death then
        DeathpoolDebug.Print("death was nil")
        return
    end

    local message = string.format(
        "Death debug: timestamp=%s, name=%s, level=%s, "
            .. "causeType=%s, sourceName=%s, zone=%s, server=%s, sourceMessage=%s, ",
        tostring(death.timestamp or "-"),
        tostring(death.name or "-"),
        tostring(death.level or "-"),
        tostring(death.causeType or "-"),
        tostring(death.sourceName or "-"),
        tostring(death.zone or "-"),
        tostring(death.server or "-"),
        tostring(death.sourceMessage or "-")
    )

    DeathpoolDebug.Print(message)
end

---@param death DeathpoolDebugDeathLike|nil
function DeathpoolDebug.RefreshLatestDeathDetails(death)
    local DeathpoolDatabase = activeDatabaseApi
    local state = activeState
    local debugFrame = activeDebugFrame
    if type(DeathpoolDatabase) ~= "table" or type(state) ~= "table" then
        return
    end

    if debugFrame and debugFrame.RefreshLatestDeathDetails then
        debugFrame:RefreshLatestDeathDetails(death, {
            totalPoints = DeathpoolDatabase.GetTotalPoints(state),
            currentPredictionStreak = DeathpoolDatabase.GetCorrectPredictionStreak(state),
            longestPredictionStreak = DeathpoolDatabase.GetLongestPredictionStreak(state),
            lockedPrediction = DeathpoolDatabase.GetLockedPrediction(state),
        })
    end
end

function DeathpoolDebug.RefreshFromRecentDeaths()
    local DeathpoolDatabase = activeDatabaseApi
    local state = activeState
    if type(DeathpoolDatabase) ~= "table" or type(state) ~= "table" then
        return
    end

    local recentDeaths = DeathpoolDatabase.GetRecentDeaths(state)
    DeathpoolDebug.RefreshLatestDeathDetails(recentDeaths and recentDeaths[#recentDeaths])
end

function DeathpoolDebug.ApplyWindowVisibility()
    local debugFrame = activeDebugFrame
    if not debugFrame then
        return
    end

    if DeathpoolDebugState.IsEnabled() then
        debugFrame:Show()
        return
    end

    debugFrame:Hide()
end

function DeathpoolDebug.HandleDeathAdded()
    DeathpoolDebug.RefreshFromRecentDeaths()
end

function DeathpoolDebug.OnAddonLoaded()
    DeathpoolDebug.RefreshFromRecentDeaths()
end

function DeathpoolDebug.ToggleDebugCommand()
    local isEnabled = DeathpoolDebugState.Toggle()

    if isEnabled then
        DeathpoolDebug.RefreshFromRecentDeaths()
        DeathpoolDebug.ApplyWindowVisibility()
        Print("Debug mode enabled.")
        return
    end

    DeathpoolDebug.ApplyWindowVisibility()
    Print("Debug mode disabled.")
end

function DeathpoolDebug.AddTestDeath()
    local addonFrame = activeAddonFrame
    if not addonFrame or not addonFrame.HandleBlizzardDeathMessage then
        return
    end

    local rawMessage = "[Testdeath] has been slain by a Kobold Geomancer in Elwynn Forest! They were level 60"
    addonFrame:HandleBlizzardDeathMessage(rawMessage)
end

---@param message string|nil
function DeathpoolDebug.HandleDebugDeathCommand(message)
    local addonFrame = activeAddonFrame
    local rawMessage = string.match(message or "", "^%S+%s+(.+)$")

    if not rawMessage or rawMessage == "" then
        Print("Usage: /deathpool debugdeath <Blizzard death message>")
        return
    end

    if not addonFrame or not addonFrame.HandleBlizzardDeathMessage then
        return
    end

    if not addonFrame:HandleBlizzardDeathMessage(rawMessage) then
        Print("No Blizzard death pattern matched that message.")
    end
end

---@param command string|nil
---@return boolean
function DeathpoolDebug.IsDebugDeathCommand(command)
    return string.sub(command or "", 1, 10) == "debugdeath"
end

return DeathpoolDebug

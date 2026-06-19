-- This module reads the current UI/model facts and derives
-- how the main window should behave during the next refresh.
local DeathpoolUIMode = {}
local DeathpoolConstants = _G.DeathpoolConstants
local DeathpoolDatabase = _G.DeathpoolDatabase

local WAITING_FOR_FIRST_DEATH_MIN_DURATION_SECONDS = DeathpoolConstants.DEMO.waitingForFirstDeathMinDurationSeconds
local WAITING_FOR_FIRST_DEATH_HELP_TEXT_DELAY_SECONDS =
    DeathpoolConstants.DEMO.waitingForFirstDeathHelpTextDelaySeconds

---@class DeathpoolUIModeState
---@field mode "setup"|"demo"|"collapsed"|"normal"
---@field prompt string|nil
---@field inputsLocked boolean
---@field mainBlocked boolean
---@field showRecentDeathRows boolean
---@field showWaitingHelp boolean

---@param frame table
---@return boolean
local function IsSetupVisible(frame)
    return frame.setupFrame ~= nil and frame.setupFrame:IsShown() == true
end

---@param frame table
---@return boolean
local function IsIntroDemoActive(frame)
    local introDemoController = frame.introDemoController
    return introDemoController ~= nil and introDemoController:IsActive() == true
end

---@param frame table
---@param displayState DeathpoolDisplayState
---@return boolean
local function ShouldShowWaitingForFirstDeathPrompt(frame, displayState)
    if #displayState.deaths <= 0 then
        return true
    end

    return frame.isWaitingForFirstDeathPromptShown == true
        and frame.waitingPromptDisplayDuration < WAITING_FOR_FIRST_DEATH_MIN_DURATION_SECONDS
end

---@param frame table
---@param displayState DeathpoolDisplayState
---@return boolean
local function ShouldShowWaitingForFirstDeathHelp(frame, displayState)
    return #displayState.deaths <= 0
        and frame.waitingPromptDisplayDuration >= WAITING_FOR_FIRST_DEATH_HELP_TEXT_DELAY_SECONDS
end

---@param frame table
---@param displayState DeathpoolDisplayState
---@param database DeathpoolCharacterState
---@return DeathpoolUIModeState
function DeathpoolUIMode.Resolve(frame, displayState, database)
    if IsSetupVisible(frame) then
        return {
            mode = "setup",
            prompt = nil,
            inputsLocked = true,
            mainBlocked = true,
            showRecentDeathRows = true,
            showWaitingHelp = false,
        }
    end

    if IsIntroDemoActive(frame) then
        return {
            mode = "demo",
            prompt = nil,
            inputsLocked = true,
            mainBlocked = false,
            showRecentDeathRows = true,
            showWaitingHelp = false,
        }
    end

    if frame.isCollapsed == true then
        return {
            mode = "collapsed",
            prompt = nil,
            inputsLocked = displayState.lockedPrediction ~= nil,
            mainBlocked = false,
            showRecentDeathRows = true,
            showWaitingHelp = false,
        }
    end

    local prompt
    if displayState.lockedPrediction == nil and not DeathpoolDatabase.GetHasSeenFirstRun(database) then
        prompt = "firstRun"
    elseif ShouldShowWaitingForFirstDeathPrompt(frame, displayState) then
        prompt = "waiting"
    end

    return {
        mode = "normal",
        prompt = prompt,
        inputsLocked = displayState.lockedPrediction ~= nil,
        mainBlocked = false,
        showRecentDeathRows = prompt == nil,
        showWaitingHelp = prompt == "waiting" and ShouldShowWaitingForFirstDeathHelp(frame, displayState),
    }
end

_G.DeathpoolUIMode = DeathpoolUIMode

return DeathpoolUIMode

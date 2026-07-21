-- This module reads the current UI/model facts and derives
-- how the main window should behave during the next refresh.
local _, ns = ...
---@cast ns DeathpoolNamespace

local DeathpoolUIMode = {}
local DeathpoolConstants = ns.DeathpoolConstants
local DeathpoolDatabase = ns.DeathpoolDatabase
ns.DeathpoolUIMode = DeathpoolUIMode

local WAITING_FOR_FIRST_DEATH_MIN_DURATION_SECONDS = DeathpoolConstants.DEMO.waitingForFirstDeathMinDurationSeconds
local WAITING_FOR_FIRST_DEATH_HELP_TEXT_DELAY_SECONDS =
    DeathpoolConstants.DEMO.waitingForFirstDeathHelpTextDelaySeconds

---@class DeathpoolUIModeState
---@field mode "demo"|"collapsed"|"normal"
---@field modal "setup"|"help"|nil
---@field prompt string|nil
---@field inputsLocked boolean
---@field mainBlocked boolean
---@field showRecentDeathRows boolean
---@field showWaitingHelp boolean

---@param uiMode DeathpoolUIModeState
---@return boolean
function DeathpoolUIMode.IsDemoMode(uiMode)
    return uiMode.mode == "demo"
end

---@param uiMode DeathpoolUIModeState
---@return boolean
function DeathpoolUIMode.IsCollapsedMode(uiMode)
    return uiMode.mode == "collapsed"
end

---@param uiMode DeathpoolUIModeState
---@return boolean
function DeathpoolUIMode.IsNormalMode(uiMode)
    return uiMode.mode == "normal"
end

---@param uiMode DeathpoolUIModeState
---@return boolean
function DeathpoolUIMode.HasModal(uiMode)
    return uiMode.modal ~= nil
end

---@param uiMode DeathpoolUIModeState
---@return boolean
function DeathpoolUIMode.IsSetupModal(uiMode)
    return uiMode.modal == "setup"
end

---@param uiMode DeathpoolUIModeState
---@return boolean
function DeathpoolUIMode.IsHelpModal(uiMode)
    return uiMode.modal == "help"
end

---@param frame table
---@return boolean
local function IsSetupVisible(frame)
    return frame.setupFrame ~= nil and frame.setupFrame:IsShown() == true
end

---@param frame table
---@return boolean
local function IsHelpWindowVisible(frame)
    return frame.helpFrame ~= nil and frame.helpFrame:IsShown() == true
end

---@param frame table
---@return boolean
local function IsGitHubLinkDialogVisible(frame)
    return frame.githubLinkFrame ~= nil and frame.githubLinkFrame:IsShown() == true
end

---@param frame table
---@return boolean
local function IsHelpModalVisible(frame)
    return IsHelpWindowVisible(frame) or IsGitHubLinkDialogVisible(frame)
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
---@return "setup"|"help"|nil
local function ResolveModal(frame)
    if IsSetupVisible(frame) then
        return "setup"
    end

    if IsHelpModalVisible(frame) then
        return "help"
    end

    return nil
end

---@param frame table
---@return "demo"|"collapsed"|"normal"
local function ResolveMode(frame)
    if IsIntroDemoActive(frame) then
        return "demo"
    end

    if frame.isCollapsed == true then
        return "collapsed"
    end

    return "normal"
end

---@param frame table
---@param displayState DeathpoolDisplayState
---@param database DeathpoolCharacterState
---@return DeathpoolUIModeState
function DeathpoolUIMode.Resolve(frame, displayState, database)
    local modal = ResolveModal(frame)
    local mode = ResolveMode(frame)

    if modal ~= nil or mode == "demo" then
        return {
            mode = mode,
            modal = modal,
            prompt = nil,
            inputsLocked = true,
            mainBlocked = modal ~= nil,
            showRecentDeathRows = true,
            showWaitingHelp = false,
        }
    end

    if mode == "collapsed" then
        return {
            mode = mode,
            modal = nil,
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
        mode = mode,
        modal = nil,
        prompt = prompt,
        inputsLocked = displayState.lockedPrediction ~= nil,
        mainBlocked = false,
        showRecentDeathRows = prompt == nil,
        showWaitingHelp = prompt == "waiting" and ShouldShowWaitingForFirstDeathHelp(frame, displayState),
    }
end

return DeathpoolUIMode

local DeathpoolDemo = _G.DeathpoolDemo or {}
local DeathpoolConstants = _G.DeathpoolConstants
local DeathpoolDatabase = _G.DeathpoolDatabase
local DeathpoolLogic = _G.DeathpoolLogic
local DeathpoolUI = _G.DeathpoolUI

local STORAGE_RULES = DeathpoolConstants.STORAGE
local DEMO_CONFIG = DeathpoolConstants.DEMO

local function GetNextDemoAdvanceDelaySeconds()
    return math.random(DEMO_CONFIG.minDelaySeconds, DEMO_CONFIG.maxDelaySeconds)
end

local function BuildDemoPlayback()
    return {
        currentDeathIndex = 0,
        elapsedSeconds = 0,
        nextAdvanceDelaySeconds = DEMO_CONFIG.minDelaySeconds,
        recentDeathKeys = {},
        scriptDeaths = DeathpoolUI.GetIntroDemoScriptDeaths(),
    }
end

---@param death DeathpoolDeathEvent
local function BuildDemoAddDeathOptions(death)
    return {
        now = death.timestamp,
        dedupeWindowSeconds = STORAGE_RULES.dedupeWindowSeconds,
        maxRecentDeaths = STORAGE_RULES.maxRecentDeaths,
        maxDeathHistory = STORAGE_RULES.maxDeathHistory,
        maxSuccessfullyPredictedDeaths = STORAGE_RULES.maxSuccessfullyPredictedDeaths,
    }
end

---@param demoState DeathpoolCharacterState
local function ResetDemoState(demoState)
    DeathpoolDatabase.ResetGameplayState(demoState)
    DeathpoolLogic.ApplyLockedPrediction(demoState, DeathpoolUI.GetIntroDemoPrediction())
end

---@param database DeathpoolCharacterState
---@param refreshMainFrame fun()
function DeathpoolDemo.Initialize(database, refreshMainFrame)
    local controller = {
        database = database,
        mainFrame = nil,
        refreshMainFrame = refreshMainFrame,
        demoState = nil,
        playback = nil,
    }

    local function RefreshMainFrame()
        if controller.refreshMainFrame then
            controller.refreshMainFrame()
        end
    end

    local function RefreshIntroDemoVisibility()
        if controller.mainFrame and controller.mainFrame.RefreshIntroDemoVisibility then
            controller.mainFrame:RefreshIntroDemoVisibility()
        end
    end

    local function EnsureSession()
        if controller.demoState == nil then
            controller.demoState = DeathpoolDatabase.Init()
        end
        if controller.playback == nil then
            controller.playback = BuildDemoPlayback()
        end
    end

    function controller:IsActive()
        return self.demoState ~= nil
    end

    function controller:GetDisplayedState(logic)
        if not self.demoState or not logic or not logic.GetDisplayState then
            return nil
        end

        return logic.GetDisplayState(self.demoState)
    end

    function controller:AttachFrame(frame)
        self.mainFrame = frame
        if not frame then
            return
        end
        frame.introDemoController = self
    end

    function controller:Reset()
        EnsureSession()
        ResetDemoState(self.demoState)
        self.playback.currentDeathIndex = 0
        self.playback.elapsedSeconds = 0
        self.playback.nextAdvanceDelaySeconds = DEMO_CONFIG.minDelaySeconds
        self.playback.recentDeathKeys = {}
    end

    function controller:Show()
        if self.mainFrame and self.mainFrame.setupFrame and self.mainFrame.setupFrame:IsShown() then
            self.mainFrame.setupFrame:Hide()
        end

        self:Reset()
        RefreshIntroDemoVisibility()

        if not self:Advance() then
            RefreshMainFrame()
        end
    end

    function controller:Dismiss()
        DeathpoolDatabase.SetHasSeenIntroDemo(self.database, true)
        self.demoState = nil
        self.playback = nil
        RefreshIntroDemoVisibility()
        RefreshMainFrame()
    end

    function controller:Advance()
        if not self.demoState or not self.playback then
            return false
        end

        local scriptDeaths = self.playback.scriptDeaths or {}
        local currentDeathIndex = tonumber(self.playback.currentDeathIndex) or 0
        local nextDeath

        if #scriptDeaths <= 0 then
            return false
        end

        if currentDeathIndex >= #scriptDeaths then
            self:Reset()
            scriptDeaths = self.playback.scriptDeaths or {}
            currentDeathIndex = 0
        end

        nextDeath = scriptDeaths[currentDeathIndex + 1]
        if not nextDeath then
            return false
        end

        self.playback.currentDeathIndex = currentDeathIndex + 1
        self.playback.elapsedSeconds = 0
        self.playback.nextAdvanceDelaySeconds = GetNextDemoAdvanceDelaySeconds()

        if not DeathpoolLogic.AddDeathToDatabase(
            self.demoState,
            nextDeath,
            self.playback.recentDeathKeys,
            BuildDemoAddDeathOptions(nextDeath)
        ) then
            return false
        end

        RefreshMainFrame()
        return true
    end

    function controller:Tick(elapsed)
        if not self.demoState or not self.playback then
            return false
        end

        if not self.mainFrame or not self.mainFrame:IsShown() or self.mainFrame.isCollapsed == true then
            return false
        end

        self.playback.elapsedSeconds = (tonumber(self.playback.elapsedSeconds) or 0) + (tonumber(elapsed) or 0)
        if self.playback.elapsedSeconds < (tonumber(self.playback.nextAdvanceDelaySeconds) or DEMO_CONFIG.minDelaySeconds) then
            return false
        end

        return self:Advance()
    end

    return controller
end

_G.DeathpoolDemo = DeathpoolDemo

return DeathpoolDemo

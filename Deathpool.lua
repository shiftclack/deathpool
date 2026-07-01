local ADDON_NAME = ...
local DeathpoolConstants = _G.DeathpoolConstants
local DeathpoolDatabase = _G.DeathpoolDatabase
local DeathpoolDebug = _G.DeathpoolDebug
local DeathpoolParser = _G.DeathpoolParser
local DeathpoolLogic = _G.DeathpoolLogic
local DeathpoolAnnouncements = _G.DeathpoolAnnouncements
local DeathpoolCommands = _G.DeathpoolCommands
local DeathpoolSettings = _G.DeathpoolSettings
local DeathpoolUI = _G.DeathpoolUI
local DeathpoolUIMinimap = _G.DeathpoolUIMinimap
local DeathpoolUISetup = _G.DeathpoolUISetup
local DeathpoolUISettings = _G.DeathpoolUISettings
local DeathpoolDemo = _G.DeathpoolDemo

local STORAGE_RULES = DeathpoolConstants.STORAGE
local HARDCORE_DEATHS_CHANNEL_NAME = "HardcoreDeaths"
local STARTUP_EVENTS = {
    "PLAYER_LOGIN",
    "PLAYER_LOGOUT",
    "PLAYER_DEAD",
    "PLAYER_LEVEL_UP",
    "PLAYER_REGEN_DISABLED",
    "CHAT_MSG_CHANNEL",
}

local Deathpool = CreateFrame("Frame", "DeathpoolAddonFrame")

---@param message string|number
local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffcc3333[Deathpool]|r " .. tostring(message))
end

---@return DeathpoolCharacterState
local function GetState()
    return Deathpool.state
end

local function RegisterStartupEvents(frame)
    for _, eventName in ipairs(STARTUP_EVENTS) do
        frame:RegisterEvent(eventName)
    end
end

---@param frame table
---@param state DeathpoolCharacterState
local function ShouldAutoStartIntroDemo(frame, state)
    return not DeathpoolDatabase.GetHasSeenIntroDemo(state)
        and not frame.introDemoController:IsActive()
end

local function AttachMainFrameScripts(frame, addonFrame)
    local existingOnHide = frame:GetScript("OnHide")

    frame:SetScript("OnShow", function(self)
        local state = addonFrame.state
        local didShowSetup = false

        DeathpoolDatabase.SetHidden(state, false)
        DeathpoolUI.ApplyDesiredLogWindowState(self, state)

        if self.setupFrame then
            didShowSetup = DeathpoolUISetup.ShowOnMainWindowOpen(self.setupFrame, self)
        end

        if not didShowSetup and ShouldAutoStartIntroDemo(self, state) then
            self.introDemoController:Show()
        end
    end)

    frame:SetScript("OnHide", function(self)
        if existingOnHide then
            existingOnHide(self)
        end

        if not addonFrame.isShuttingDown then
            DeathpoolDatabase.SetHidden(addonFrame.state, true)
        end

        if self.setupFrame and self.setupFrame:IsShown() then
            self.setupFrame:Hide()
        end

        if self.introDemoController and self.introDemoController:IsActive() then
            addonFrame:DismissIntroDemo()
        end

        if self.logFrame then
            self.logFrame:Hide()
        end

        if self.helpFrame then
            self.helpFrame:Hide()
        end
    end)
end

function Deathpool:RefreshMainFrame()
    if not self.mainFrame then
        return
    end

    self.mainFrame:RefreshDeaths()
    self.mainFrame:RefreshLockedPrediction()
    self.mainFrame:RefreshCollapsedSummary()
end

function Deathpool:DismissIntroDemo()
    if self.demoController then
        self.demoController:Dismiss()
    end
end

function Deathpool:ADDON_LOADED(addonName)
    if addonName ~= ADDON_NAME then
        return
    end

    DeathpoolCharacterState = DeathpoolDatabase.Init(DeathpoolCharacterState)
    self.state = DeathpoolCharacterState
    self.isShuttingDown = false
    self.recentDeathKeys = {}

    self.mainFrame, self.debugFrame, self.logFrame = DeathpoolUI.Initialize(
        self.state,
        DeathpoolLogic,
        STORAGE_RULES.maxRecentDeaths
    )

    DeathpoolParser.Initialize()

    DeathpoolSettings.Initialize(
        self.state,
        DeathpoolDatabase
    )

    DeathpoolUISettings.Initialize(
        DeathpoolSettings
    )

    self.demoController = DeathpoolDemo.Initialize(
        self.state,
        function() self:RefreshMainFrame() end
    )
    self.demoController:AttachFrame(self.mainFrame)

    DeathpoolUIMinimap.Initialize(
        self.mainFrame,
        self.state
    )

    DeathpoolCommands.Initialize(
        self,
        Print
    )

    DeathpoolDebug.Initialize(
        self,
        self.state,
        DeathpoolDatabase,
        self.debugFrame,
        Print
    )
    DeathpoolDebug.OnAddonLoaded()

    AttachMainFrameScripts(self.mainFrame, self)
    RegisterStartupEvents(self)
    DeathpoolUI.SetWindowCollapsed(self.mainFrame, self.state, DeathpoolDatabase.GetCollapsed(self.state))
    self:RefreshMainFrame()
    self.logFrame:RefreshHistory()
end

Deathpool:SetScript("OnEvent", function(self, event, ...)
    if self[event] then
        self[event](self, ...)
    end
end)

Deathpool:RegisterEvent("ADDON_LOADED")

---@param death DeathpoolDeathEvent
function Deathpool:AddDeath(death)
    local mainFrame = self.mainFrame
    local state = GetState()

    local addDeathOptions = {
        dedupeWindowSeconds = STORAGE_RULES.dedupeWindowSeconds,
        maxRecentDeaths = STORAGE_RULES.maxRecentDeaths,
        maxDeathHistory = STORAGE_RULES.maxDeathHistory,
        maxSuccessfullyPredictedDeaths = STORAGE_RULES.maxSuccessfullyPredictedDeaths,
        playerZone = GetZoneText()
    }

    local added = DeathpoolLogic.AddDeathToDatabase(
        state,
        death,
        self.recentDeathKeys,
        addDeathOptions
    )

    if not added then
        return
    end

    if mainFrame then
        self:RefreshMainFrame()
    end

    DeathpoolDebug.HandleDeathAdded()
end

---@param message string
function Deathpool:HandleBlizzardDeathMessage(message)
    local parsedDeath = DeathpoolParser.ParseBlizzardDeathMessage(message)
    if parsedDeath then
        local normalizedDeath = DeathpoolLogic.NormalizeDeathEvent(parsedDeath)
        DeathpoolDebug.DebugDeathData(normalizedDeath)
        self:AddDeath(normalizedDeath)
        return true
    end

    return false
end

---@param message string
---@param _sender string
---@param _languageName string
---@param _channelName string
---@param _target string
---@param _flags string
---@param _zoneChannelID number
---@param _channelIndex number
---@param channelBaseName string
function Deathpool:CHAT_MSG_CHANNEL(
    message,
    _sender,
    _languageName,
    _channelName,
    _target,
    _flags,
    _zoneChannelID,
    _channelIndex,
    channelBaseName
)
    if channelBaseName ~= HARDCORE_DEATHS_CHANNEL_NAME then
        return
    end

    if not message or message == "" then
        return
    end

    self:HandleBlizzardDeathMessage(message)
end

function Deathpool:PLAYER_LOGIN()
    local mainFrame = self.mainFrame

    if mainFrame and not DeathpoolDatabase.GetHidden(self.state) then
        mainFrame:Show()
    end
end

function Deathpool:PLAYER_LOGOUT()
    self.isShuttingDown = true
end

-- luacheck: ignore self
function Deathpool:PLAYER_DEAD()
    DeathpoolAnnouncements.AnnouncePlayerDeath(GetState(), Print)
end

-- luacheck: ignore self
---@param level integer
function Deathpool:PLAYER_LEVEL_UP(level)
    DeathpoolAnnouncements.AnnouncePlayerLevelUp(GetState(), level)
end

-- automatically minimize the main ui in combat
function Deathpool:PLAYER_REGEN_DISABLED()
    local mainFrame = self.mainFrame

    if not mainFrame then
        return
    end

    if mainFrame.isCollapsed then
        return
    end

    if not mainFrame:IsShown() then
        return
    end

    if DeathpoolDatabase.GetShowInCombat(GetState()) then
        return
    end

    DeathpoolUI.SetWindowCollapsed(mainFrame, GetState(), true)
end

---@param message string
function Deathpool:HandleSlashCommand(message)
    local _ = self
    DeathpoolCommands.HandleSlashCommand(message)
end

local _, ns = ...
---@cast ns DeathpoolNamespace

local DeathpoolSetup = {}
ns.DeathpoolSetup = DeathpoolSetup

local HARDCORE_DEATH_CHAT_TYPE_CVAR = "hardcoreDeathChatType"
local HARDCORE_DEATHS_CHANNEL_NAME = "HardcoreDeaths"

---@class DeathpoolSetupState
---@field hasEnabledDeathAnnouncements boolean
---@field hasJoinedHardcoreDeathsChannel boolean
---@field isComplete boolean

local sessionState = {
    hasEnabledDeathAnnouncements = false,
    hasJoinedHardcoreDeathsChannel = false,
}

---@return boolean
local function HasEnabledGameDeathAnnouncements()
    if sessionState.hasEnabledDeathAnnouncements then
        return true
    end

    return tonumber(GetCVar(HARDCORE_DEATH_CHAT_TYPE_CVAR)) ~= 0
end

---@return boolean
local function IsInHardcoreDeathsChannel()
    local channelId = GetChannelName(HARDCORE_DEATHS_CHANNEL_NAME)
    return tonumber(channelId) ~= nil and tonumber(channelId) > 0
end

---@return boolean
local function HasJoinedHardcoreDeathsChannel()
    return sessionState.hasJoinedHardcoreDeathsChannel == true or IsInHardcoreDeathsChannel()
end

---@return DeathpoolSetupState
function DeathpoolSetup.GetState()
    local hasEnabledDeathAnnouncements = HasEnabledGameDeathAnnouncements()
    local hasJoinedHardcoreDeathsChannel = HasJoinedHardcoreDeathsChannel()

    return {
        hasEnabledDeathAnnouncements = hasEnabledDeathAnnouncements,
        hasJoinedHardcoreDeathsChannel = hasJoinedHardcoreDeathsChannel,
        isComplete = hasEnabledDeathAnnouncements and hasJoinedHardcoreDeathsChannel,
    }
end

---@return boolean
function DeathpoolSetup.IsComplete()
    return DeathpoolSetup.GetState().isComplete
end

---@return boolean
function DeathpoolSetup.ShouldShowOnMainWindowOpen()
    return not DeathpoolSetup.IsComplete()
end

function DeathpoolSetup.EnableDeathAnnouncements()
    SetCVar(HARDCORE_DEATH_CHAT_TYPE_CVAR, "1")
    sessionState.hasEnabledDeathAnnouncements = true
end

function DeathpoolSetup.JoinHardcoreDeathsChannel()
    JoinPermanentChannel(HARDCORE_DEATHS_CHANNEL_NAME)
    sessionState.hasJoinedHardcoreDeathsChannel = true
end

return DeathpoolSetup

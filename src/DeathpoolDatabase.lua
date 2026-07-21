---@class DeathpoolFrameAnchor
---@field point string
---@field relativePoint string
---@field x number
---@field y number

---@class DeathpoolMinimapSettings
---@field hide boolean

---@class DeathpoolAnnouncementSettings
---@field enabled boolean
---@field announceScoreOnDeath boolean
---@field announceScoreOnLevelUp boolean

---@class DeathpoolPredictionElements
---@field levelRange string|nil
---@field source string|nil
---@field zone string|nil

---@class DeathpoolPrediction
---@field elements DeathpoolPredictionElements
---@field lockedAt integer|nil

---@class DeathpoolDeath
---@field timestamp integer
---@field name string
---@field level integer
---@field causeType string|nil
---@field sourceName string|nil
---@field zone string|nil
---@field server string|nil
---@field sourceMessage string|nil
---@field prediction DeathpoolPrediction|nil
---@field matchedPrediction boolean|nil
---@field points integer|nil
---@field multiplierValue integer|nil
---@field streakMultiplier integer|nil
---@field awardedPoints integer|nil
---@field predictionStreak integer|nil
---@field sameZoneBonusApplied boolean|nil

---@class DeathpoolCharacterState
---@field hidden boolean
---@field hasSeenIntroDemo boolean
---@field hasSeenFirstRun boolean
---@field logWindowShown boolean
---@field historySuccessfulOnly boolean
---@field announcements DeathpoolAnnouncementSettings
---@field showInCombat boolean
---@field collapsed boolean
---@field collapsedWindowHeight integer|nil
---@field recentDeaths DeathpoolDeath[]
---@field deathHistory DeathpoolDeath[]
---@field successfullyPredictedDeaths DeathpoolDeath[]
---@field lockedPrediction DeathpoolPrediction|nil
---@field draftPrediction DeathpoolPrediction|nil
---@field lastPrediction DeathpoolPrediction|nil
---@field totalPoints integer
---@field correctPredictionStreak integer
---@field longestPredictionStreak integer
---@field minimap DeathpoolMinimapSettings
---@field windowPosition DeathpoolFrameAnchor|nil
---@field collapsedWindowPosition DeathpoolFrameAnchor|nil

local _, ns = ...
---@cast ns DeathpoolNamespace

local DeathpoolDatabase = ns.DeathpoolDatabase or {}
ns.DeathpoolDatabase = DeathpoolDatabase
DeathpoolDatabase.DEFAULTS = {
    hidden = true,
    hasSeenIntroDemo = false,
    hasSeenFirstRun = false,
    logWindowShown = false,
    historySuccessfulOnly = true,
    announcements = {
        enabled = false,
        announceScoreOnDeath = true,
        announceScoreOnLevelUp = false,
    },
    showInCombat = false,
    collapsed = false,
    recentDeaths = {},
    deathHistory = {},
    successfullyPredictedDeaths = {},
    draftPrediction = nil,
    totalPoints = 0,
    correctPredictionStreak = 0,
    longestPredictionStreak = 0,
}

---@param database table
---@param key string
---@return table
local function EnsureTableField(database, key)
    if type(database[key]) ~= "table" then
        database[key] = {}
    end

    return database[key]
end

---@param value any
---@return any
local function CloneValue(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = CloneValue(nestedValue)
    end

    return copy
end

---@param database table
---@return DeathpoolAnnouncementSettings
local function EnsureAnnouncements(database)
    local announcements = EnsureTableField(database, "announcements")

    if announcements.enabled == nil then
        announcements.enabled = DeathpoolDatabase.DEFAULTS.announcements.enabled
    else
        announcements.enabled = announcements.enabled == true
    end
    announcements.announceScoreOnDeath = announcements.announceScoreOnDeath ~= false
    announcements.announceScoreOnLevelUp = announcements.announceScoreOnLevelUp ~= false
    announcements.levelUpFrequency = nil

    return announcements
end

--- if database is nil one will be returned with default values
--- also try to fix any corrupt or missing fields
--- any state initialization that needs to happen before migrations should go here
---@param database DeathpoolCharacterState|table|nil
---@return DeathpoolCharacterState
local function EnsureDatabase(database)
    if type(database) ~= "table" then
        ---@diagnostic disable-next-line: missing-fields
        database = {}
    end

    -- This mutates the provided table in place and preserves identity.
    for fieldName, defaultValue in pairs(DeathpoolDatabase.DEFAULTS) do
        if database[fieldName] == nil then
            database[fieldName] = CloneValue(defaultValue)
        end
    end

    EnsureTableField(database, "recentDeaths")
    EnsureTableField(database, "deathHistory")
    EnsureTableField(database, "successfullyPredictedDeaths")
    EnsureTableField(database, "minimap")
    EnsureAnnouncements(database)

    -- Debug mode is session-only and should not remain in SavedVariables.
    database.debugEnabled = nil

    database.totalPoints = tonumber(database.totalPoints) or 0
    database.correctPredictionStreak = tonumber(database.correctPredictionStreak) or 0
    database.longestPredictionStreak = tonumber(database.longestPredictionStreak) or 0

    return database
end

---@param database DeathpoolCharacterState|nil
---@return DeathpoolCharacterState
function DeathpoolDatabase.Init(database)
    local migration = ns.DeathpoolMigration
    database = EnsureDatabase(database)
    database = migration.Apply(database)
    return database
end

---@param database DeathpoolCharacterState
---@return boolean
function DeathpoolDatabase.GetHidden(database)
    return database.hidden == true
end

---@param database DeathpoolCharacterState
---@param hidden boolean
---@return boolean
function DeathpoolDatabase.SetHidden(database, hidden)
    database.hidden = hidden == true
    return database.hidden
end

---@param database DeathpoolCharacterState
---@return boolean
function DeathpoolDatabase.GetHasSeenIntroDemo(database)
    return database.hasSeenIntroDemo == true
end

---@param database DeathpoolCharacterState
---@param seen boolean
---@return boolean
function DeathpoolDatabase.SetHasSeenIntroDemo(database, seen)
    database.hasSeenIntroDemo = seen == true
    return database.hasSeenIntroDemo
end

---@param database DeathpoolCharacterState
---@return boolean
function DeathpoolDatabase.GetHasSeenFirstRun(database)
    return database.hasSeenFirstRun == true
end

---@param database DeathpoolCharacterState
---@param seen boolean
---@return boolean
function DeathpoolDatabase.SetHasSeenFirstRun(database, seen)
    database.hasSeenFirstRun = seen == true
    return database.hasSeenFirstRun
end

---@param database DeathpoolCharacterState
---@return boolean
function DeathpoolDatabase.GetLogWindowShown(database)
    return database.logWindowShown == true
end

---@param database DeathpoolCharacterState
---@param shown boolean
---@return boolean
function DeathpoolDatabase.SetLogWindowShown(database, shown)
    database.logWindowShown = shown == true
    return database.logWindowShown
end

---@param database DeathpoolCharacterState
---@return boolean
function DeathpoolDatabase.GetHistorySuccessfulOnly(database)
    return database.historySuccessfulOnly ~= false
end

---@param database DeathpoolCharacterState
---@param successfulOnly boolean
---@return boolean
function DeathpoolDatabase.SetHistorySuccessfulOnly(database, successfulOnly)
    database.historySuccessfulOnly = successfulOnly == true
    return database.historySuccessfulOnly
end

---@param database DeathpoolCharacterState
---@return boolean
function DeathpoolDatabase.GetAnnounceDeathToGuild(database)
    return database.announcements.announceScoreOnDeath == true
end

---@param database DeathpoolCharacterState
---@param enabled boolean
---@return boolean
function DeathpoolDatabase.SetAnnounceDeathToGuild(database, enabled)
    database.announcements.announceScoreOnDeath = enabled == true
    return database.announcements.announceScoreOnDeath
end

---@param database DeathpoolCharacterState
---@return boolean
function DeathpoolDatabase.GetAnnounceScoreOnLevelUp(database)
    return database.announcements.announceScoreOnLevelUp == true
end

---@param database DeathpoolCharacterState
---@param enabled boolean
---@return boolean
function DeathpoolDatabase.SetAnnounceScoreOnLevelUp(database, enabled)
    database.announcements.announceScoreOnLevelUp = enabled == true
    return database.announcements.announceScoreOnLevelUp
end

---@param database DeathpoolCharacterState
---@return boolean
function DeathpoolDatabase.GetGuildAnnouncementsEnabled(database)
    return database.announcements.enabled == true
end

---@param database DeathpoolCharacterState
---@param enabled boolean
---@return boolean
function DeathpoolDatabase.SetGuildAnnouncementsEnabled(database, enabled)
    database.announcements.enabled = enabled == true
    return database.announcements.enabled
end

---@param database DeathpoolCharacterState
---@return boolean
function DeathpoolDatabase.GetShowInCombat(database)
    return database.showInCombat == true
end

---@param database DeathpoolCharacterState
---@param enabled boolean
---@return boolean
function DeathpoolDatabase.SetShowInCombat(database, enabled)
    database.showInCombat = enabled == true
    return database.showInCombat
end

---@param database DeathpoolCharacterState
---@return boolean
function DeathpoolDatabase.GetCollapsed(database)
    return database.collapsed == true
end

---@param database DeathpoolCharacterState
---@param collapsed boolean
---@return boolean
function DeathpoolDatabase.SetCollapsed(database, collapsed)
    database.collapsed = collapsed == true
    return database.collapsed
end

---@param database DeathpoolCharacterState
---@return integer|nil
function DeathpoolDatabase.GetCollapsedWindowHeight(database)
    local height = tonumber(database.collapsedWindowHeight)
    if height == nil or height <= 0 then
        return nil
    end

    return height
end

---@param database DeathpoolCharacterState
---@param height integer
---@return integer
function DeathpoolDatabase.SetCollapsedWindowHeight(database, height)
    database.collapsedWindowHeight = tonumber(height)
    return database.collapsedWindowHeight
end

---@param database DeathpoolCharacterState
---@return DeathpoolPrediction|nil
function DeathpoolDatabase.GetLockedPrediction(database)
    return database.lockedPrediction
end

---@param database DeathpoolCharacterState
---@param prediction DeathpoolPrediction|nil
---@return DeathpoolPrediction|nil
function DeathpoolDatabase.SetLockedPrediction(database, prediction)
    database.lockedPrediction = prediction
    return database.lockedPrediction
end

---@param database DeathpoolCharacterState
---@return DeathpoolPrediction|nil
function DeathpoolDatabase.GetLastPrediction(database)
    return database.lastPrediction
end

---@param database DeathpoolCharacterState
---@param prediction DeathpoolPrediction|nil
---@return DeathpoolPrediction|nil
function DeathpoolDatabase.SetLastPrediction(database, prediction)
    database.lastPrediction = prediction
    return database.lastPrediction
end

---@param database DeathpoolCharacterState
---@return DeathpoolPrediction|nil
function DeathpoolDatabase.GetDraftPrediction(database)
    return database.draftPrediction
end

---@param database DeathpoolCharacterState
---@param prediction DeathpoolPrediction|nil
---@return DeathpoolPrediction|nil
function DeathpoolDatabase.SetDraftPrediction(database, prediction)
    database.draftPrediction = prediction
    return database.draftPrediction
end

---@param database DeathpoolCharacterState
---@return DeathpoolDeath[]
function DeathpoolDatabase.GetRecentDeaths(database)
    return EnsureTableField(database, "recentDeaths")
end

---@param database DeathpoolCharacterState
---@return DeathpoolDeath[]
function DeathpoolDatabase.GetDeathHistory(database)
    return EnsureTableField(database, "deathHistory")
end

---@param database DeathpoolCharacterState
---@param fieldName string
---@return string[]
local function GetUniqueDeathHistoryValues(database, fieldName)
    local values = {}
    local seenValues = {}

    for _, death in ipairs(DeathpoolDatabase.GetDeathHistory(database)) do
        if type(death) == "table" and type(death[fieldName]) == "string" then
            local value = death[fieldName]
            if not seenValues[value] then
                seenValues[value] = true
                values[#values + 1] = value
            end
        end
    end

    table.sort(values)

    return values
end

---@param database DeathpoolCharacterState
---@return string[]
function DeathpoolDatabase.GetDeathHistorySourceNames(database)
    return GetUniqueDeathHistoryValues(database, "sourceName")
end

---@param database DeathpoolCharacterState
---@return string[]
function DeathpoolDatabase.GetDeathHistoryZones(database)
    return GetUniqueDeathHistoryValues(database, "zone")
end

---@param database DeathpoolCharacterState
---@return DeathpoolDeath[]
function DeathpoolDatabase.GetSuccessfullyPredictedDeaths(database)
    return EnsureTableField(database, "successfullyPredictedDeaths")
end

---@param database DeathpoolCharacterState
---@return DeathpoolCharacterState
function DeathpoolDatabase.ResetGameplayState(database)
    database.correctPredictionStreak = 0
    database.draftPrediction = nil
    database.lastPrediction = nil
    database.lockedPrediction = nil
    database.longestPredictionStreak = 0
    database.totalPoints = 0
    wipe(EnsureTableField(database, "recentDeaths"))
    wipe(EnsureTableField(database, "deathHistory"))
    wipe(EnsureTableField(database, "successfullyPredictedDeaths"))
    return database
end

---@param database DeathpoolCharacterState
---@return DeathpoolCharacterState
function DeathpoolDatabase.ResetAllState(database)
    wipe(database)
    EnsureDatabase(database)
    return database
end

---@param database DeathpoolCharacterState
---@return integer
function DeathpoolDatabase.GetTotalPoints(database)
    return tonumber(database.totalPoints) or 0
end

---@param database DeathpoolCharacterState
---@param points number
---@return integer
function DeathpoolDatabase.SetTotalPoints(database, points)
    database.totalPoints = tonumber(points) or 0
    return database.totalPoints
end

---@param database DeathpoolCharacterState
---@return integer
function DeathpoolDatabase.GetCorrectPredictionStreak(database)
    return tonumber(database.correctPredictionStreak) or 0
end

---@param database DeathpoolCharacterState
---@param streak number
---@return integer
function DeathpoolDatabase.SetCorrectPredictionStreak(database, streak)
    database.correctPredictionStreak = tonumber(streak) or 0
    return database.correctPredictionStreak
end

---@param database DeathpoolCharacterState
---@return integer
function DeathpoolDatabase.GetLongestPredictionStreak(database)
    return tonumber(database.longestPredictionStreak) or 0
end

---@param database DeathpoolCharacterState
---@param streak number
---@return integer
function DeathpoolDatabase.SetLongestPredictionStreak(database, streak)
    database.longestPredictionStreak = tonumber(streak) or 0
    return database.longestPredictionStreak
end

---@param database DeathpoolCharacterState
---@return DeathpoolMinimapSettings
function DeathpoolDatabase.GetMinimapSettings(database)
    local minimap = EnsureTableField(database, "minimap")
    if minimap.hide == nil then
        minimap.hide = false
    end

    return minimap
end

---@param database DeathpoolCharacterState
---@return boolean
function DeathpoolDatabase.GetMinimapHidden(database)
    return DeathpoolDatabase.GetMinimapSettings(database).hide == true
end

---@param database DeathpoolCharacterState
---@param hidden boolean
---@return boolean
function DeathpoolDatabase.SetMinimapHidden(database, hidden)
    local minimap = DeathpoolDatabase.GetMinimapSettings(database)
    minimap.hide = hidden == true
    return minimap.hide
end

---@param database DeathpoolCharacterState
---@param collapsed boolean|nil
---@return DeathpoolFrameAnchor|nil
function DeathpoolDatabase.GetWindowPosition(database, collapsed)
    if collapsed == true then
        return database.collapsedWindowPosition
    end

    return database.windowPosition
end

---@param database DeathpoolCharacterState
---@param collapsed boolean|nil
---@param anchor DeathpoolFrameAnchor|nil
---@return DeathpoolFrameAnchor|nil
function DeathpoolDatabase.SetWindowPosition(database, collapsed, anchor)
    if collapsed == true then
        database.collapsedWindowPosition = anchor
    else
        database.windowPosition = anchor
    end

    return anchor
end

return DeathpoolDatabase

---@class DeathpoolSettingsDatabaseApi
---@field GetShowInCombat fun(database: DeathpoolCharacterState): boolean
---@field SetShowInCombat fun(database: DeathpoolCharacterState, enabled: boolean): boolean
---@field GetDisableBlizzardDeathAlerts fun(database: DeathpoolCharacterState): boolean
---@field SetDisableBlizzardDeathAlerts fun(database: DeathpoolCharacterState, enabled: boolean): boolean
---@field GetAnnounceDeathToGuild fun(database: DeathpoolCharacterState): boolean
---@field SetAnnounceDeathToGuild fun(database: DeathpoolCharacterState, enabled: boolean): boolean

local DeathpoolSettings = _G.DeathpoolSettings or {}

---@type DeathpoolCharacterState|nil
local activeDatabase = nil

---@type DeathpoolSettingsDatabaseApi|nil
local activeDatabaseApi = nil

---@return DeathpoolCharacterState
local function GetDatabase()
    local database = activeDatabase
    ---@cast database DeathpoolCharacterState
    return database
end

---@return DeathpoolSettingsDatabaseApi
local function GetDatabaseApi()
    local databaseApi = activeDatabaseApi
    ---@cast databaseApi DeathpoolSettingsDatabaseApi
    return databaseApi
end

---@return boolean
function DeathpoolSettings.GetShowInCombat()
    return GetDatabaseApi().GetShowInCombat(GetDatabase())
end

---@return boolean
function DeathpoolSettings.GetDeathAnnouncementToGuild()
    return GetDatabaseApi().GetAnnounceDeathToGuild(GetDatabase())
end

---@return boolean
function DeathpoolSettings.GetBlizzardDeathAlertsSuppressed()
    return GetDatabaseApi().GetDisableBlizzardDeathAlerts(GetDatabase())
end

-- this function is fragile if blizz makes changes
---@param suppressed boolean
---@return boolean
local function ApplyBlizzardDeathAlertsSuppressed(suppressed)
    local raidWarningFrame = _G.RaidWarningFrame
    local methodName = suppressed and "UnregisterEvent" or "RegisterEvent"
    local method = raidWarningFrame and raidWarningFrame[methodName] or nil

    if not raidWarningFrame then
        return false
    end

    if type(method) ~= "function" then
        return false
    end

    return pcall(method, raidWarningFrame, "HARDCORE_DEATHS")
end

---@param database DeathpoolCharacterState
---@param databaseApi DeathpoolSettingsDatabaseApi
function DeathpoolSettings.Initialize(database, databaseApi)
    activeDatabase = database
    activeDatabaseApi = databaseApi
end

---@param enabled boolean
---@return boolean
function DeathpoolSettings.SetShowInCombat(enabled)
    return GetDatabaseApi().SetShowInCombat(GetDatabase(), enabled)
end

---@param enabled boolean
---@return boolean
function DeathpoolSettings.SetDeathAnnouncementToGuild(enabled)
    return GetDatabaseApi().SetAnnounceDeathToGuild(GetDatabase(), enabled)
end

---@return boolean
function DeathpoolSettings.ToggleShowInCombat()
    return DeathpoolSettings.SetShowInCombat(not DeathpoolSettings.GetShowInCombat())
end

---@param suppressed boolean
---@return boolean
function DeathpoolSettings.SetBlizzardDeathAlertsSuppressed(suppressed)
    GetDatabaseApi().SetDisableBlizzardDeathAlerts(GetDatabase(), suppressed)
    return ApplyBlizzardDeathAlertsSuppressed(suppressed)
end

---@return boolean
function DeathpoolSettings.EnableBlizzardDeathAlertSuppression()
    return DeathpoolSettings.SetBlizzardDeathAlertsSuppressed(true)
end

_G.DeathpoolSettings = DeathpoolSettings

return DeathpoolSettings

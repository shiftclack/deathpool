---@class DeathpoolSettingsDatabaseApi
---@field GetShowInCombat fun(database: DeathpoolCharacterState): boolean
---@field SetShowInCombat fun(database: DeathpoolCharacterState, enabled: boolean): boolean
---@field GetAnnounceDeathToGuild fun(database: DeathpoolCharacterState): boolean
---@field SetAnnounceDeathToGuild fun(database: DeathpoolCharacterState, enabled: boolean): boolean
---@field GetMinimapHidden fun(database: DeathpoolCharacterState): boolean

local DeathpoolSettings = _G.DeathpoolSettings or {}
local DeathpoolUIMinimap = _G.DeathpoolUIMinimap

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
function DeathpoolSettings.GetDisableMinimapIcon()
    return GetDatabaseApi().GetMinimapHidden(GetDatabase())
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

---@param disabled boolean
---@return boolean
function DeathpoolSettings.SetDisableMinimapIcon(disabled)
    return DeathpoolUIMinimap.SetHidden(nil, GetDatabase(), disabled)
end

---@return boolean
function DeathpoolSettings.ToggleShowInCombat()
    return DeathpoolSettings.SetShowInCombat(not DeathpoolSettings.GetShowInCombat())
end

_G.DeathpoolSettings = DeathpoolSettings

return DeathpoolSettings

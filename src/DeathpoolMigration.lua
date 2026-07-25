---@diagnostic disable: inject-field
local _, ns = ...
---@cast ns DeathpoolNamespace

local DeathpoolMigration = ns.DeathpoolMigration or {}
ns.DeathpoolMigration = DeathpoolMigration

DeathpoolMigration.CURRENT_VERSION = 1

---@type table<integer, fun(database: DeathpoolCharacterState)>
local migrations = {
    [1] = function(_)
    end,
}

---@param database table
---@param targetVersion integer
---@param versionMigrations table<integer, fun(database: table)>
---@return table
function DeathpoolMigration.ApplyVersions(database, targetVersion, versionMigrations)
    local version = database.databaseVersion

    while version < targetVersion do
        local nextVersion = version + 1
        versionMigrations[nextVersion](database)
        database.databaseVersion = nextVersion
        version = nextVersion
    end

    return database
end

---@param database DeathpoolCharacterState
---@return DeathpoolCharacterState
function DeathpoolMigration.Apply(database)
    DeathpoolMigration.ApplyVersions(database, DeathpoolMigration.CURRENT_VERSION, migrations)
    return database
end

return DeathpoolMigration

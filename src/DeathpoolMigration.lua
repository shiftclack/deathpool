---@diagnostic disable: inject-field
local _, ns = ...
---@cast ns DeathpoolNamespace

local DeathpoolMigration = ns.DeathpoolMigration or {}
ns.DeathpoolMigration = DeathpoolMigration

---@param database DeathpoolCharacterState
---@return DeathpoolCharacterState
function DeathpoolMigration.Apply(database)
    return database
end

return DeathpoolMigration

---@diagnostic disable: inject-field
local DeathpoolMigration = _G.DeathpoolMigration or {}

---@param database DeathpoolCharacterState
---@return DeathpoolCharacterState
function DeathpoolMigration.Apply(database)
    return database
end

_G.DeathpoolMigration = DeathpoolMigration

return DeathpoolMigration

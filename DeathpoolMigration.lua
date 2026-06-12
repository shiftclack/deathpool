local DeathpoolMigration = _G.DeathpoolMigration or {}

---@param database DeathpoolCharacterState
---@return DeathpoolCharacterState
function DeathpoolMigration.Apply(database)
    -- nothing here yet
    return database
end

_G.DeathpoolMigration = DeathpoolMigration

return DeathpoolMigration

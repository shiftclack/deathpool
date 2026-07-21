package.path = table.concat({
    "./src/?.lua",
    "./?.lua",
    "./?/init.lua",
    package.path,
}, ";")

local AddonLoader = require("tests.support_addon_loader")
local DeathpoolMigration = AddonLoader.Create():Load("DeathpoolMigration")
local TestHelpers = require("tests.support_helpers")
local suite = TestHelpers.CreateSuite()
local assertEquals = function(actual, expected, message)
    suite:assertEquals(actual, expected, message)
end
local assertTruthy = function(value, message)
    suite:assertTruthy(value, message)
end

local function testApplyReturnsNewDatabaseTableWhenMissing()
    local database = {}
    local returnedDatabase = DeathpoolMigration.Apply(database)

    assertTruthy(type(returnedDatabase) == "table", "migration should still return a database table")
    assertEquals(returnedDatabase, database, "migration should preserve table identity")
end

local function testApplyLeavesExistingDatabaseUntouched()
    local database = {
        hidden = true,
        totalPoints = 42,
        recentDeaths = {
            {
                name = "Existing",
                multiplier = "x4",
            },
        },
    }

    local returnedDatabase = DeathpoolMigration.Apply(database)

    assertEquals(returnedDatabase, database, "migration should return the existing database table")
    assertEquals(database.hidden, true, "migration should not rewrite existing fields")
    assertEquals(database.totalPoints, 42, "migration should not change stored values")
    assertEquals(database.recentDeaths[1].multiplier, "x4", "migration should not mutate existing rows")
    assertEquals(database.deathHistory, nil, "migration should not backfill history while migrations are disabled")
end

testApplyReturnsNewDatabaseTableWhenMissing()
testApplyLeavesExistingDatabaseUntouched()

suite:finish()

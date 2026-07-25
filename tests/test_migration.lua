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
local assertContains = function(text, needle, message)
    suite:assertContains(text, needle, message)
end

local function testApplyUsesProductionMigrations()
    local database = {
        databaseVersion = 0,
    }
    local returnedDatabase = DeathpoolMigration.Apply(database)

    assertTruthy(type(returnedDatabase) == "table", "migration should still return a database table")
    assertEquals(returnedDatabase, database, "migration should preserve table identity")
    assertEquals(
        database.databaseVersion,
        DeathpoolMigration.CURRENT_VERSION,
        "production migration should stamp a version zero database with the current version"
    )
end

local function testApplyVersionsRunsPendingMigrationsInOrder()
    local database = {
        databaseVersion = 0,
        applied = {},
    }
    local testMigrations = {
        [1] = function(state)
            table.insert(state.applied, "one")
            state.firstValue = "ready"
        end,
        [2] = function(state)
            table.insert(state.applied, "two")
            state.sawFirstValue = state.firstValue
        end,
        [3] = function(state)
            table.insert(state.applied, "three")
        end,
    }

    local returnedDatabase = DeathpoolMigration.ApplyVersions(database, 3, testMigrations)

    assertEquals(returnedDatabase, database, "migration should return the existing database table")
    assertEquals(table.concat(database.applied, ","), "one,two,three", "migrations should run in version order")
    assertEquals(database.sawFirstValue, "ready", "each migration should see changes from earlier migrations")
    assertEquals(database.databaseVersion, 3, "migration should advance the database to the target version")
end

local function testApplyVersionsSkipsCompletedMigrations()
    local database = {
        databaseVersion = 1,
        applied = {},
    }
    local testMigrations = {
        [1] = function()
            error("completed migration should not run")
        end,
        [2] = function(state)
            table.insert(state.applied, "two")
        end,
        [3] = function(state)
            table.insert(state.applied, "three")
        end,
    }

    DeathpoolMigration.ApplyVersions(database, 3, testMigrations)

    assertEquals(table.concat(database.applied, ","), "two,three", "migration should skip completed versions")
    assertEquals(database.databaseVersion, 3, "migration should apply every remaining version")
end

local function testApplyVersionsDoesNothingAtTargetVersion()
    local database = {
        databaseVersion = 2,
        marker = "unchanged",
    }
    local testMigrations = {
        [1] = function()
            error("completed migration should not run")
        end,
        [2] = function()
            error("current migration should not rerun")
        end,
    }

    local returnedDatabase = DeathpoolMigration.ApplyVersions(database, 2, testMigrations)

    assertEquals(returnedDatabase, database, "current database migration should preserve table identity")
    assertEquals(database.databaseVersion, 2, "current database migration should preserve its version")
    assertEquals(database.marker, "unchanged", "current database migration should not change stored data")
end

local function testApplyVersionsDoesNotDowngradeNewerDatabase()
    local database = {
        databaseVersion = 3,
        marker = "unchanged",
    }

    local returnedDatabase = DeathpoolMigration.ApplyVersions(database, 2, {})

    assertEquals(returnedDatabase, database, "migration should preserve a newer database table")
    assertEquals(database.databaseVersion, 3, "migration should not downgrade a newer database")
    assertEquals(database.marker, "unchanged", "migration should not rewrite data from a newer database")
end

local function testApplyVersionsRecordsOnlySuccessfulMigrations()
    local database = {
        databaseVersion = 0,
    }
    local testMigrations = {
        [1] = function(state)
            state.firstMigrationRan = true
        end,
        [2] = function(state)
            state.failedMigrationStarted = true
            error("expected migration failure")
        end,
    }

    local succeeded, migrationError = pcall(function()
        DeathpoolMigration.ApplyVersions(database, 2, testMigrations)
    end)

    assertEquals(succeeded, false, "migration errors should propagate to the caller")
    assertContains(migrationError, "expected migration failure", "migration should preserve the original error")
    assertEquals(database.firstMigrationRan, true, "successful migrations should remain applied")
    assertEquals(database.databaseVersion, 1, "migration should record only completed versions")
    assertEquals(database.failedMigrationStarted, true, "failed migrations should not roll back partial changes")
end

testApplyUsesProductionMigrations()
testApplyVersionsRunsPendingMigrationsInOrder()
testApplyVersionsSkipsCompletedMigrations()
testApplyVersionsDoesNothingAtTargetVersion()
testApplyVersionsDoesNotDowngradeNewerDatabase()
testApplyVersionsRecordsOnlySuccessfulMigrations()

suite:finish()

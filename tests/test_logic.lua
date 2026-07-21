local loadedLogic = require("tests.support_logic_loader")
local DeathpoolLogic = loadedLogic.DeathpoolLogic
local Fixtures = require("tests.support_fixtures")
local TestHelpers = require("tests.support_helpers")
local suite = TestHelpers.CreateSuite()

local context = {
    DeathpoolLogic = DeathpoolLogic,
    DeathpoolDatabase = loadedLogic.DeathpoolDatabase,
    Fixtures = Fixtures,
    suite = suite,
    SCORE_RULES = loadedLogic.DeathpoolConstants.SCORING,
    STORAGE_RULES = loadedLogic.DeathpoolConstants.STORAGE,
    Helpers = require("tests.support_logic_helpers"),
}

require("tests.test_logic_prediction")(context)
require("tests.test_logic_scoring")(context)
require("tests.test_logic_deaths")(context)
require("tests.test_logic_database")(context)

suite:finish()

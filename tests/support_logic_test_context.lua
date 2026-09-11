local LogicContext = require("tests.support_logic_context")
local FixtureFactory = require("tests.support_fixtures")
local LogicHelpers = require("tests.support_logic_helpers")

local LogicTestContext = {}

---@return table
function LogicTestContext.Create()
    local loaded = LogicContext.Create()
    local fixtures = FixtureFactory.Create(loaded.DeathpoolConstants, loaded.DeathpoolDatabase)
    loaded.Fixtures = fixtures
    loaded.SCORE_RULES = loaded.DeathpoolConstants.SCORING
    loaded.STORAGE_RULES = loaded.DeathpoolConstants.STORAGE
    loaded.Helpers = LogicHelpers.Create(loaded.SCORE_RULES, fixtures)
    return loaded
end

return LogicTestContext

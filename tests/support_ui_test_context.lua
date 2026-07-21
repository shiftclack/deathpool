package.path = table.concat({
    "./src/?.lua",
    "./?.lua",
    "./?/init.lua",
    package.path,
}, ";")

local AddonLoader = require("tests.support_addon_loader")
local loader = AddonLoader.GetDefault()
loader:Load("DeathpoolConstants")
loader:Load("DeathpoolMigration")
loader:Load("DeathpoolDatabase")
loader:Load("DeathpoolDebug")
rawset(_G, "GetZoneText", function()
    return "Test UI Zone"
end)
loader:Load("DeathpoolLogic")
loader:Load("DeathpoolLogicPrediction")
loader:Load("DeathpoolLogicScoring")
loader:Load("DeathpoolLogicDeaths")
loader:Load("DeathpoolLogicState")
local DeathpoolLogic = loader.ns.DeathpoolLogic
local TestHelpers = require("tests.support_helpers")
local UIHarness = require("tests.support_ui_harness")
local Fixtures = require("tests.support_fixtures")
local SCORE_RULES = loader.ns.DeathpoolConstants.SCORING

local function buildLevelPointsSummary()
    local visibleRanges = {}

    for index = 1, #SCORE_RULES.levelRanges - 1 do
        visibleRanges[#visibleRanges + 1] = tostring(SCORE_RULES.levelRanges[index])
    end

    return "Level ranges can be locked as "
        .. table.concat(visibleRanges, ", ")
        .. ", and "
        .. tostring(SCORE_RULES.levelRanges[#SCORE_RULES.levelRanges])
        .. "."
end

local function formatPredictionPreview(prediction)
    local basePoints = DeathpoolLogic.GetBasePointsForPrediction(prediction)
    local elements = DeathpoolLogic.GetPredictionElements(prediction) or {}
    local combinationCount = DeathpoolLogic.ScorePreview(
        elements,
        DeathpoolLogic.GetPreviewStreak()
    ).combinationCount
    local awardedPoints = DeathpoolLogic.GetPreviewAwardedPointsForPrediction(prediction)

    return string.format("%d base / %d combos = %d total", basePoints, combinationCount, awardedPoints)
end

local function formatStoredDeathScore(death)
    local basePoints = DeathpoolLogic.GetStoredDeathBasePoints(death)
    local sameZoneBonusPoints = DeathpoolLogic.GetStoredDeathSameZoneBonusPoints(death)
    local comboMultiplier = DeathpoolLogic.GetStoredDeathComboMultiplierValue(death)
    local streakMultiplier = DeathpoolLogic.GetStoredDeathStreakMultiplierValue(death)
    local comboSum = DeathpoolLogic.GetStoredDeathMultiplierValue(death)
    local awardedPoints = DeathpoolLogic.GetStoredDeathAwardedPoints(death)
    return {
        basePoints = tostring(basePoints),
        comboMultiplier = "x" .. tostring(comboMultiplier),
        streakMultiplier = "x" .. tostring(streakMultiplier),
        comboSum = "x" .. tostring(comboSum),
        sameZoneBonusPoints = tostring(sameZoneBonusPoints),
        awardedPoints = tostring(awardedPoints),
        formula = string.format("%d x%d = %d", basePoints + sameZoneBonusPoints, comboSum, awardedPoints),
    }
end

local function createUIContext(state, options)
    -- Each UI test gets a fresh harness so frame state, globals, and printed messages cannot bleed across cases.
    local ui = UIHarness.Create({
        state = state,
        faction = options and options.faction or nil,
        hardcoreDeathChatType = options and options.hardcoreDeathChatType or nil,
        hardcoreDeathsJoined = options and options.hardcoreDeathsJoined,
    })

    return {
        ns = ui.ns,
        DeathpoolUI = ui.DeathpoolUI,
        DeathpoolConstants = ui.DeathpoolConstants,
        DeathpoolDatabase = ui.DeathpoolDatabase,
        DeathpoolLogic = ui.DeathpoolLogic,
        Deathpool = ui.Deathpool,
        DeathpoolDebug = ui.DeathpoolDebug,
        DeathpoolLog = ui.DeathpoolLog,
        printedMessages = ui.printedMessages,
        cvars = ui.cvars,
        setCVarCalls = ui.setCVarCalls,
        joinedChannels = ui.joinedChannels,
        joinedChannelNames = ui.joinedChannelNames,
        pressEscape = ui.pressEscape,
        findRegionText = ui.findRegionText,
        findDropdownButtonByText = ui.findDropdownButtonByText,
    }
end

local function Create()
    local suite = TestHelpers.CreateSuite()

    return {
        Fixtures = Fixtures,
        suite = suite,
        ns = loader.ns,
        DeathpoolConstants = loader.ns.DeathpoolConstants,
        DeathpoolDatabase = loader.ns.DeathpoolDatabase,
        DeathpoolLogic = DeathpoolLogic,
        createUIContext = createUIContext,
        buildLevelPointsSummary = buildLevelPointsSummary,
        formatPredictionPreview = formatPredictionPreview,
        formatStoredDeathScore = formatStoredDeathScore,
        assertEquals = function(actual, expected, message)
            suite:assertEquals(actual, expected, message)
        end,
        assertTruthy = function(value, message)
            suite:assertTruthy(value, message)
        end,
        assertContains = function(text, needle, message)
            suite:assertContains(text, needle, message)
        end,
        assertTableLength = function(tbl, expected, message)
            suite:assertTableLength(tbl, expected, message)
        end,
    }
end

return {
    Create = Create,
}

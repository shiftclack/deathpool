return function(context)
    local DeathpoolLogic = context.DeathpoolLogic
    local Fixtures = context.Fixtures
    local SCORE_RULES = context.SCORE_RULES
    local Helpers = context.Helpers
    local suite = context.suite
    local assertEquals = function(actual, expected, message)
        suite:assertEquals(actual, expected, message)
    end
    local assertTruthy = function(value, message)
        suite:assertTruthy(value, message)
    end

    local function testLevelRanges()
        assertTruthy(DeathpoolLogic.IsLevelInRange(10, "10-19"), "10 should fall in the 10-19 range")
        assertEquals(DeathpoolLogic.IsLevelInRange(20, "10-19"), false, "20 should not fall in the 10-19 range")
        assertTruthy(DeathpoolLogic.IsLevelInRange(60, "60"), "60 should match the capped 60 range")
    end

    local function testLevelPointTiers()
        local cases = {
            { level = 9, points = 0, label = "levels below 10 should not award level points" },
        }

        for _, levelRange in ipairs(SCORE_RULES.levelRanges) do
            local level = Helpers.getRepresentativeLevelForRange(levelRange)
            cases[#cases + 1] = {
                level = level,
                points = SCORE_RULES.levelPointMode == "fixedRange"
                    and (tonumber(SCORE_RULES.fixedLevelRangePoints[levelRange]) or 0)
                    or level,
                label = levelRange .. " should award the configured level points for a matched death",
            }
        end

        for _, case in ipairs(cases) do
            assertEquals(DeathpoolLogic.GetLevelPointsForLevel(case.level), case.points, case.label)
        end
    end

    local function testLevelRangePointTiers()
        local cases = {
            { levelRange = nil, points = 0, label = "missing level ranges should award zero preview points" },
        }

        for _, levelRange in ipairs(SCORE_RULES.levelRanges) do
            local expectedPoints

            if SCORE_RULES.levelPointMode == "fixedRange" then
                expectedPoints = tonumber(SCORE_RULES.fixedLevelRangePoints[levelRange]) or 0
            elseif levelRange == "60" then
                expectedPoints = 60
            else
                expectedPoints = tonumber(string.match(levelRange, "^(%d+)%-%d+$")) or 0
            end

            cases[#cases + 1] = {
                levelRange = levelRange,
                points = expectedPoints,
                label = levelRange .. " should preview the configured base points for that range",
            }
        end

        for _, case in ipairs(cases) do
            assertEquals(DeathpoolLogic.GetLevelPointsForRange(case.levelRange), case.points, case.label)
        end
    end

    local function testFixedRangeLevelPointMode()
        local originalMode = SCORE_RULES.levelPointMode
        local originalPoints = SCORE_RULES.fixedLevelRangePoints["50-59"]

        SCORE_RULES.levelPointMode = "fixedRange"
        SCORE_RULES.fixedLevelRangePoints["50-59"] = 77

        assertEquals(
            DeathpoolLogic.GetLevelPointsForLevel(58),
            77,
            "fixed-range mode should use the configured bucket points for matched deaths"
        )
        assertEquals(
            DeathpoolLogic.GetLevelPointsForRange("50-59"),
            77,
            "fixed-range mode should use the configured bucket points for previews"
        )

        SCORE_RULES.levelPointMode = originalMode
        SCORE_RULES.fixedLevelRangePoints["50-59"] = originalPoints
    end

    local function testPredictionFormatting()
        assertEquals(
            DeathpoolLogic.FormatLockedPrediction(nil),
            "Prediction not locked in yet.",
            "empty prediction should have the placeholder summary"
        )

        assertEquals(
            DeathpoolLogic.FormatLockedPrediction(Fixtures.prediction({
                levelRange = "20-29",
            })),
            "Level 20-29, source Hogger, zone Elwynn Forest.",
            "locked prediction should render labels directly"
        )

        assertEquals(
            DeathpoolLogic.FormatLockedPrediction(Fixtures.prediction({
                levelRange = false,
                source = false,
                zone = false,
            })),
            "Level none, source none, zone none.",
            "locked prediction should show that level can be intentionally unset"
        )
    end

    local function testPredictionNormalizationHelpers()
        assertEquals(
            DeathpoolLogic.NormalizePredictionValue("Hogger", "No Source Prediction"),
            "hogger",
            "prediction normalization should lowercase real values"
        )
        assertEquals(
            DeathpoolLogic.NormalizePredictionValue("No Source Prediction", "No Source Prediction"),
            nil,
            "prediction normalization should treat the placeholder as unset"
        )
        assertEquals(
            DeathpoolLogic.ToDisplayText("elwynn forest"),
            "Elwynn Forest",
            "display text should title-case lowercase values"
        )
    end

    local function testPredictionHelperUtilities()
        assertEquals(
            DeathpoolLogic.GetSelectedPredictionCount(Fixtures.prediction()),
            3,
            "selected prediction helper should count all chosen fields"
        )
        assertEquals(
            DeathpoolLogic.GetSelectedPredictionCount(Fixtures.prediction({
                levelRange = false,
                zone = false,
                zoneLabel = false,
            })),
            1,
            "selected prediction helper should ignore omitted fields"
        )
        assertEquals(
            DeathpoolLogic.GetMatchedPredictionCount({
                levelMatched = true,
                sourceMatched = true,
                zoneMatched = false,
            }),
            2,
            "matched prediction helper should count only matched fields"
        )
        assertEquals(
            DeathpoolLogic.GetMatchedPredictionCount(nil),
            0,
            "matched prediction helper should default nil evaluations to zero"
        )
        assertTruthy(
            DeathpoolLogic.ArePredictionsEquivalent(
                Fixtures.prediction(),
                Fixtures.prediction()
            ),
            "prediction equivalence should treat identical normalized predictions as equal"
        )
        assertEquals(
            DeathpoolLogic.ArePredictionsEquivalent(
                Fixtures.prediction(),
                Fixtures.prediction({ source = "defias", sourceLabel = "Defias" })
            ),
            false,
            "prediction equivalence should detect changed prediction fields"
        )
    end

    testLevelRanges()
    testLevelPointTiers()
    testLevelRangePointTiers()
    testFixedRangeLevelPointMode()
    testPredictionFormatting()
    testPredictionNormalizationHelpers()
    testPredictionHelperUtilities()
end

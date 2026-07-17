package.path = table.concat({
    "./src/?.lua",
    "./?.lua",
    "./?/init.lua",
    package.path,
}, ";")

local Fixtures = require("tests.support_fixtures")
local SCORE_RULES = _G.DeathpoolConstants.SCORING

local Helpers = {}

local function isLevelMatched(options)
    if options.levelMatched ~= nil then
        return options.levelMatched == true
    end

    if options.levelRange == nil or options.level == nil then
        return false
    end

    local numericLevel = tonumber(options.level)
    if not numericLevel then
        return false
    end

    if options.levelRange == "60" then
        return numericLevel == 60
    end

    local minLevel, maxLevel = string.match(options.levelRange, "^(%d+)%-(%d+)$")
    minLevel = tonumber(minLevel)
    maxLevel = tonumber(maxLevel)

    return minLevel ~= nil and maxLevel ~= nil and numericLevel >= minLevel and numericLevel <= maxLevel
end

function Helpers.createDeathForInsert(overrides)
    -- AddDeathToDatabase mutates the death row, so each insert should get a fresh fixture object.
    return Fixtures.death(overrides)
end

function Helpers.getRepresentativeLevelForRange(levelRange)
    local representativeLevels = {
        ["10-19"] = 10,
        ["20-29"] = 24,
        ["30-39"] = 37,
        ["40-49"] = 42,
        ["50-59"] = 58,
        ["60"] = 60,
    }

    return representativeLevels[levelRange]
end

function Helpers.getExpectedBasePoints(options)
    options = options or {}
    local basePoints = 0
    local levelMatched = isLevelMatched(options)

    if options.levelRange ~= nil and levelMatched then
        if SCORE_RULES.levelPointMode == "fixedRange" then
            basePoints = basePoints + (tonumber(SCORE_RULES.fixedLevelRangePoints[options.levelRange]) or 0)
        else
            basePoints = basePoints + (tonumber(options.level) or Helpers.getRepresentativeLevelForRange(options.levelRange) or 0)
        end
    end

    if options.source == true then
        basePoints = basePoints + SCORE_RULES.fixedElementPoints.source
    end

    if options.zone == true then
        basePoints = basePoints + SCORE_RULES.fixedElementPoints.zone
    end

    return basePoints
end

function Helpers.getCombinationCount(matchCount)
    if not matchCount or matchCount <= 0 then
        return 0
    end

    return 1
end

function Helpers.getDisplayMultiplier(matchCount, streak)
    if not matchCount or matchCount <= 0 then
        return 0
    end

    local streakBonus = math.min(
        math.max((tonumber(streak) or 0) - 1, 0) * (tonumber(SCORE_RULES.streakBonusStep) or 1),
        SCORE_RULES.maxStreakBonus
    )

    local comboTotal = SCORE_RULES.predictionElementBonusByCount[matchCount] or 0

    return math.max(comboTotal + streakBonus, 1)
end

return Helpers

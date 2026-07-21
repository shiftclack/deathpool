local _, ns = ...
---@cast ns DeathpoolNamespace

local DeathpoolLogic = ns.DeathpoolLogic or {}
local DeathpoolConstants = ns.DeathpoolConstants
ns.DeathpoolLogic = DeathpoolLogic
local SCORE_RULES = DeathpoolConstants.SCORING

---@param ... boolean
---@return integer
local function CountTruthyValues(...)
    local count = 0
    for index = 1, select("#", ...) do
        if select(index, ...) then
            count = count + 1
        end
    end

    return count
end

---@param value string|number
---@return string|nil
local function NormalizeComparableText(value)
    if value == nil then
        return nil
    end

    local normalizedValue = tostring(value):gsub("^%s+", ""):gsub("%s+$", "")
    if normalizedValue == "" then
        return nil
    end

    return string.lower(normalizedValue)
end

---@param elements DeathpoolPredictionElements
---@param death DeathpoolDeath|DeathpoolDeathEvent
---@return DeathpoolPredictionMatchState
local function GetPredictionMatchState(elements, death)
    local hasLevelPrediction = elements.levelRange ~= nil
    local hasSourcePrediction = elements.source ~= nil
    local hasZonePrediction = elements.zone ~= nil

    return {
        levelMatched = hasLevelPrediction and DeathpoolLogic.IsLevelInRange(death.level, elements.levelRange),
        sourceMatched = hasSourcePrediction
            and NormalizeComparableText(death.sourceName) == NormalizeComparableText(elements.source),
        zoneMatched = hasZonePrediction
            and NormalizeComparableText(death.zone) == NormalizeComparableText(elements.zone),
        hasLevelPrediction = hasLevelPrediction,
        hasSourcePrediction = hasSourcePrediction,
        hasZonePrediction = hasZonePrediction,
    }
end

---@param matchState DeathpoolPredictionMatchState
---@return boolean
local function IsPredictionMatched(matchState)
    local selectedPredictionCount = CountTruthyValues(
        matchState.hasLevelPrediction,
        matchState.hasSourcePrediction,
        matchState.hasZonePrediction
    )

    return selectedPredictionCount > 0
        and (not matchState.hasLevelPrediction or matchState.levelMatched)
        and (not matchState.hasSourcePrediction or matchState.sourceMatched)
        and (not matchState.hasZonePrediction or matchState.zoneMatched)
end

---@param level integer|string
---@param selectedRange string
---@return boolean
function DeathpoolLogic.IsLevelInRange(level, selectedRange)
    local numericLevel = tonumber(level)
    if not numericLevel or not selectedRange or selectedRange == "" then
        return false
    end

    if selectedRange == "60" then
        return numericLevel == 60
    end

    local minLevel, maxLevel = string.match(selectedRange, "^(%d+)%-(%d+)$")
    minLevel = tonumber(minLevel)
    maxLevel = tonumber(maxLevel)
    return minLevel ~= nil and maxLevel ~= nil and numericLevel >= minLevel and numericLevel <= maxLevel
end

---@param level integer|string
---@return string|nil
local function GetLevelRangeForLevel(level)
    for _, levelRange in ipairs(SCORE_RULES.levelRanges) do
        if DeathpoolLogic.IsLevelInRange(level, levelRange) then
            return levelRange
        end
    end
    return nil
end

---@param level integer|string
---@return integer
function DeathpoolLogic.GetLevelPointsForLevel(level)
    local numericLevel = tonumber(level)
    if not numericLevel then
        return 0
    end

    local levelRange = GetLevelRangeForLevel(numericLevel)
    if not levelRange then
        return 0
    end

    if SCORE_RULES.levelPointMode == "fixedRange" then
        return tonumber(SCORE_RULES.fixedLevelRangePoints[levelRange]) or 0
    end

    return numericLevel
end

---@param selectedRange string
---@return integer
function DeathpoolLogic.GetLevelPointsForRange(selectedRange)
    if not selectedRange or selectedRange == "" then
        return 0
    end

    if SCORE_RULES.levelPointMode == "fixedRange" then
        return tonumber(SCORE_RULES.fixedLevelRangePoints[selectedRange]) or 0
    end

    if selectedRange == "60" then
        return 60
    end

    local minLevel = string.match(selectedRange, "^(%d+)%-%d+$")
    return tonumber(minLevel) or 0
end

---@param value string|number|nil
---@param anyValue string|number|nil
---@return string|nil
function DeathpoolLogic.NormalizePredictionValue(value, anyValue)
    -- normalize so comparisons stay simple
    if value == nil or value == "" or value == anyValue then
        return nil
    end

    return string.lower(tostring(value))
end

---@param value string|number|nil
---@return string|nil
function DeathpoolLogic.ToDisplayText(value)
    -- Turn normalized lowercase values back into readable UI text.
    if value == nil or value == "" then
        return nil
    end

    local displayText = tostring(value):gsub("(%a)([%w]*)", function(first, rest)
        return string.upper(first) .. string.lower(rest)
    end)
    return displayText
end

---@param prediction DeathpoolPrediction|DeathpoolPredictionElements|nil
---@return DeathpoolPredictionElements|nil
function DeathpoolLogic.GetPredictionElements(prediction)
    if not prediction then
        return nil
    end

    if prediction.elements ~= nil then
        return prediction.elements
    end

    ---@cast prediction DeathpoolPredictionElements
    return prediction
end

---@param prediction DeathpoolPrediction|DeathpoolPredictionElements|nil
---@return DeathpoolPrediction|nil
function DeathpoolLogic.NormalizePrediction(prediction)
    if not prediction then
        return nil
    end

    local elements = DeathpoolLogic.GetPredictionElements(prediction)
    ---@cast elements DeathpoolPredictionElements

    return {
        elements = {
            levelRange = elements.levelRange,
            source = DeathpoolLogic.NormalizePredictionValue(elements.source),
            zone = DeathpoolLogic.NormalizePredictionValue(elements.zone),
        },
        lockedAt = prediction.lockedAt,
    }
end

---@param prediction DeathpoolPrediction|DeathpoolPredictionElements|nil
---@return string
function DeathpoolLogic.FormatLockedPrediction(prediction)
    if not prediction then
        return "Prediction not locked in yet."
    end

    local elements = DeathpoolLogic.GetPredictionElements(prediction)
    ---@cast elements DeathpoolPredictionElements
    -- fields can be omitted, so the summary should have fallback text
    local levelRange = elements.levelRange or "none"
    local source = DeathpoolLogic.ToDisplayText(elements.source) or "none"
    local zone = DeathpoolLogic.ToDisplayText(elements.zone) or "none"

    return string.format(
        "Level %s, source %s, or zone %s.",
        tostring(levelRange),
        tostring(source),
        tostring(zone)
    )
end

---@param evaluation DeathpoolScoreResult|nil
---@return integer
function DeathpoolLogic.GetMatchedPredictionCount(evaluation)
    if not evaluation then
        return 0
    end

    if evaluation.matchedElementCount ~= nil then
        return tonumber(evaluation.matchedElementCount) or 0
    end

    return CountTruthyValues(
        evaluation.levelMatched,
        evaluation.sourceMatched,
        evaluation.zoneMatched
    )
end

---@param prediction DeathpoolPrediction|DeathpoolPredictionElements|nil
---@return integer
function DeathpoolLogic.GetSelectedPredictionCount(prediction)
    if not prediction then
        return 0
    end

    local elements = DeathpoolLogic.GetPredictionElements(prediction)
    ---@cast elements DeathpoolPredictionElements
    local count = 0
    if elements.levelRange ~= nil then
        count = count + 1
    end
    if elements.source ~= nil then
        count = count + 1
    end
    if elements.zone ~= nil then
        count = count + 1
    end

    return count
end

---@param left DeathpoolPrediction|DeathpoolPredictionElements|nil
---@param right DeathpoolPrediction|DeathpoolPredictionElements|nil
---@return boolean
function DeathpoolLogic.ArePredictionsEquivalent(left, right)
    if left == nil and right == nil then
        return true
    end

    if left == nil or right == nil then
        return false
    end

    local leftElements = DeathpoolLogic.GetPredictionElements(left)
    local rightElements = DeathpoolLogic.GetPredictionElements(right)
    ---@cast leftElements DeathpoolPredictionElements
    ---@cast rightElements DeathpoolPredictionElements

    -- only the actual prediction choices matter for streak reset decisions
    return leftElements.levelRange == rightElements.levelRange
        and leftElements.source == rightElements.source
        and leftElements.zone == rightElements.zone
end

DeathpoolLogic._GetPredictionMatchState = GetPredictionMatchState
DeathpoolLogic._IsPredictionMatched = IsPredictionMatched
DeathpoolLogic._NormalizeComparableText = NormalizeComparableText

return DeathpoolLogic

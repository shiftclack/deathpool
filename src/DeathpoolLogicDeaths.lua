local DeathpoolLogic = _G.DeathpoolLogic or {}

---@class DeathpoolDeathEvent
---@field timestamp integer
---@field name string
---@field level integer
---@field causeType string
---@field sourceName string
---@field zone string
---@field server string
---@field sourceMessage string
---@field isBlizzardVerified boolean

---@param death DeathpoolDeath
---@return DeathpoolScoreResult
local function GetStoredDeathScore(death)
    local elements = DeathpoolLogic.GetPredictionElements(death.prediction) or {}
    return DeathpoolLogic.ScoreStoredDeath(elements, death, tonumber(death.predictionStreak) or 0)
end

---@param death DeathpoolDeathEvent
---@param prediction DeathpoolPrediction|DeathpoolPredictionElements|nil
---@param score DeathpoolScoreResult
---@param predictionStreak integer
---@param includeComputedScores boolean
---@param sameZoneBonusApplied boolean
---@return DeathpoolDeath
local function CreateStoredDeathEntry(death, prediction, score, predictionStreak, includeComputedScores, sameZoneBonusApplied)
    local entry = {
        timestamp = death.timestamp,
        name = death.name,
        level = death.level,
        causeType = death.causeType,
        sourceName = death.sourceName,
        zone = death.zone,
        server = death.server,
        sourceMessage = death.sourceMessage,
        matchedPrediction = score.matched,
        predictionStreak = predictionStreak,
        streakMultiplier = score.streakBonus,
        sameZoneBonusApplied = sameZoneBonusApplied == true,
        prediction = DeathpoolLogic.NormalizePrediction(prediction),
    }

    if includeComputedScores then
        entry.points = score.basePoints
        entry.awardedPoints = score.awardedPoints
    end

    return entry
end

---@param parsedDeath DeathpoolParsedDeathEvent
---@return DeathpoolDeathEvent
function DeathpoolLogic.NormalizeDeathEvent(parsedDeath)
    return {
        timestamp = time(),
        name = parsedDeath.name,
        level = parsedDeath.level,
        causeType = parsedDeath.causeType,
        sourceName = parsedDeath.sourceName,
        zone = parsedDeath.zone,
        server = parsedDeath.server or GetRealmName(),
        sourceMessage = parsedDeath.sourceMessage,
        isBlizzardVerified = true,
    }
end

---@param death DeathpoolDeath
---@return integer
function DeathpoolLogic.GetStoredDeathBasePoints(death)
    if not death then
        return 0
    end

    local score = GetStoredDeathScore(death)
    return score.basePoints
end

---@param death DeathpoolDeath
---@return integer
function DeathpoolLogic.GetStoredDeathMultiplierValue(death)
    if not death then
        return 0
    end

    local score = GetStoredDeathScore(death)
    return score.totalMultiplier
end

---@param death DeathpoolDeath
---@return integer
function DeathpoolLogic.GetStoredDeathComboMultiplierValue(death)
    if not death then
        return 0
    end

    local score = GetStoredDeathScore(death)
    return score.comboBonus
end

---@param death DeathpoolDeath
---@return integer
function DeathpoolLogic.GetStoredDeathStreakMultiplierValue(death)
    if not death then
        return 0
    end

    local score = GetStoredDeathScore(death)
    return score.streakBonus
end

---@param death DeathpoolDeath
---@return integer
function DeathpoolLogic.GetStoredDeathAwardedPoints(death)
    if not death then
        return 0
    end

    local score = GetStoredDeathScore(death)
    return score.awardedPoints
end

---@param death DeathpoolDeath
---@return integer
function DeathpoolLogic.GetStoredDeathSameZoneBonusPoints(death)
    if not death then
        return 0
    end

    local score = GetStoredDeathScore(death)
    return score.sameZoneBonusPoints
end

---@param death DeathpoolDeath
function DeathpoolLogic.GetStoredDeathComboDetails(death)
    if not death then
        return DeathpoolLogic.GetComboDetails(nil, nil, 0)
    end

    return DeathpoolLogic.GetComboDetails(
        death.prediction,
        death,
        tonumber(death.predictionStreak) or 0
    )
end

---@param deaths DeathpoolDeath[]
---@return integer
function DeathpoolLogic.GetStoredDeathTotalPoints(deaths)
    local totalPoints = 0

    for _, death in ipairs(deaths or {}) do
        totalPoints = totalPoints + DeathpoolLogic.GetStoredDeathAwardedPoints(death)
    end

    return totalPoints
end

DeathpoolLogic._CreateStoredDeathEntry = CreateStoredDeathEntry

_G.DeathpoolLogic = DeathpoolLogic

return DeathpoolLogic

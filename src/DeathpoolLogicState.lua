local _, ns = ...
---@cast ns DeathpoolNamespace

local DeathpoolLogic = ns.DeathpoolLogic or {}
local DeathpoolConstants = ns.DeathpoolConstants
local DeathpoolDatabase = ns.DeathpoolDatabase
ns.DeathpoolLogic = DeathpoolLogic
local SCORE_RULES = DeathpoolConstants.SCORING
local STORAGE_RULES = DeathpoolConstants.STORAGE

---@class DeathpoolAddDeathOptions: DeathpoolScoreOptions
---@field maxRecentDeaths integer
---@field maxDeathHistory integer
---@field maxSuccessfullyPredictedDeaths integer
---@field playerZone string

---@class DeathpoolScoreResult
---@field levelMatched boolean
---@field sourceMatched boolean
---@field zoneMatched boolean
---@field matched boolean
---@field perfectMatch boolean
---@field basePoints integer
---@field selectedElementCount integer
---@field matchedElementCount integer
---@field combinationCount integer
---@field selectedElements table[]
---@field matchedElements table[]
---@field levelBonus integer
---@field sameZoneBonusPoints integer
---@field comboBonus integer
---@field streakBonus integer
---@field totalMultiplier integer
---@field awardedPoints integer
---@field sameZoneBonusApplied boolean
---@field winningEntries table[]

---@class DeathpoolDisplayState
---@field deaths DeathpoolDeath[]
---@field totalPoints integer
---@field currentPredictionStreak integer
---@field longestPredictionStreak integer
---@field lockedPrediction DeathpoolPrediction|nil
---@field draftPrediction DeathpoolPrediction|nil
---@field lastPrediction DeathpoolPrediction|nil

---@param database DeathpoolCharacterState
---@param evaluation DeathpoolScoreResult
---@return integer
local function ApplyPredictionStreak(database, evaluation)
    if evaluation.matched then
        local nextStreak = DeathpoolDatabase.GetCorrectPredictionStreak(database) + 1
        DeathpoolDatabase.SetCorrectPredictionStreak(database, nextStreak)
        if nextStreak > DeathpoolDatabase.GetLongestPredictionStreak(database) then
            DeathpoolDatabase.SetLongestPredictionStreak(database, nextStreak)
        end
        return nextStreak
    end

    DeathpoolDatabase.SetCorrectPredictionStreak(database, 0)
    return 0
end

---@param deaths DeathpoolDeath[]
---@param limit integer
local function TrimDeathsToLimit(deaths, limit)
    while #deaths > limit do
        table.remove(deaths, 1)
    end
end

---@param death DeathpoolDeath
---@return integer
local function GetSuccessfulPredictionRetentionPoints(death)
    local elements = DeathpoolLogic.GetPredictionElements(death.prediction)
    return DeathpoolLogic.ScoreStoredDeath(elements, death, SCORE_RULES.previewStreak).awardedPoints
end

---@param deaths DeathpoolDeath[]
---@param limit integer
local function TrimSuccessfulPredictedDeathsToLimit(deaths, limit)
    while #deaths > limit do
        local lowestIndex = 1
        local lowestRetentionPoints = GetSuccessfulPredictionRetentionPoints(deaths[lowestIndex])
        local lowestTimestamp = tonumber(deaths[lowestIndex].timestamp) or 0

        for index = 2, #deaths do
            local death = deaths[index]
            local retentionPoints = GetSuccessfulPredictionRetentionPoints(death)
            local timestamp = tonumber(death.timestamp) or 0

            -- Successful-prediction retention is based on the strength of the
            -- matched prediction itself at the baseline preview streak, not the
            -- final awarded total. That keeps streak inflation from pushing out
            -- stronger predictions that happened to occur earlier in a run.
            if retentionPoints < lowestRetentionPoints
                or (retentionPoints == lowestRetentionPoints and timestamp < lowestTimestamp) then
                lowestIndex = index
                lowestRetentionPoints = retentionPoints
                lowestTimestamp = timestamp
            end
        end

        table.remove(deaths, lowestIndex)
    end
end

---@param database DeathpoolCharacterState
local function ResetPredictionStreak(database)
    DeathpoolDatabase.SetCorrectPredictionStreak(database, 0)
end

---@param database DeathpoolCharacterState
---@param prediction DeathpoolPrediction|DeathpoolPredictionElements|nil
---@return DeathpoolPrediction|nil
function DeathpoolLogic.ApplyLockedPrediction(database, prediction)
    if database == nil then
        print("database table is required")
        return nil
    end

    if prediction == nil then
        return nil
    end

    prediction = DeathpoolLogic.NormalizePrediction(prediction)

    local previousPrediction = DeathpoolDatabase.GetLockedPrediction(database) or DeathpoolDatabase.GetLastPrediction(database)
    if previousPrediction and not DeathpoolLogic.ArePredictionsEquivalent(previousPrediction, prediction) then
        ResetPredictionStreak(database)
    end

    DeathpoolDatabase.SetLockedPrediction(database, prediction)
    DeathpoolDatabase.SetLastPrediction(database, prediction)
    DeathpoolDatabase.SetDraftPrediction(database, prediction)

    return prediction
end

---@param database DeathpoolCharacterState
function DeathpoolLogic.ClearLockedPrediction(database)
    if not database then
        print("database table is required")
        return
    end

    DeathpoolDatabase.SetLastPrediction(
        database,
        DeathpoolDatabase.GetLockedPrediction(database) or DeathpoolDatabase.GetLastPrediction(database)
    )
    DeathpoolDatabase.SetDraftPrediction(
        database,
        DeathpoolDatabase.GetLockedPrediction(database) or DeathpoolDatabase.GetDraftPrediction(database)
    )
    DeathpoolDatabase.SetLockedPrediction(database, nil)
end

---@param database DeathpoolCharacterState
---@param prediction DeathpoolPrediction|DeathpoolPredictionElements|nil
---@return DeathpoolPrediction|nil
function DeathpoolLogic.UpdateDraftPrediction(database, prediction)
    if not database then
        print("database table is required")
        return nil
    end

    if prediction == nil then
        return nil
    end

    prediction = DeathpoolLogic.NormalizePrediction(prediction)

    if DeathpoolLogic.GetSelectedPredictionCount(prediction) <= 0 then
        DeathpoolDatabase.SetDraftPrediction(database, nil)
        return nil
    end

    DeathpoolDatabase.SetDraftPrediction(database, prediction)
    return prediction
end

---@param database DeathpoolCharacterState
---@return DeathpoolDisplayState
function DeathpoolLogic.GetDisplayState(database)
    return {
        deaths = DeathpoolDatabase.GetRecentDeaths(database),
        totalPoints = DeathpoolDatabase.GetTotalPoints(database),
        currentPredictionStreak = DeathpoolDatabase.GetCorrectPredictionStreak(database),
        longestPredictionStreak = DeathpoolDatabase.GetLongestPredictionStreak(database),
        lockedPrediction = DeathpoolDatabase.GetLockedPrediction(database),
        draftPrediction = DeathpoolDatabase.GetDraftPrediction(database),
        lastPrediction = DeathpoolDatabase.GetLastPrediction(database),
    }
end

---@param database DeathpoolCharacterState
---@param death DeathpoolDeathEvent
---@param options DeathpoolAddDeathOptions|nil
---@return boolean added
---@return DeathpoolScoreResult|nil score
function DeathpoolLogic.AddDeathToDatabase(database, death, options)
    if database == nil then
        print("database table is required")
        return false, nil
    end

    options = options or {}
    local recentDeaths = DeathpoolDatabase.GetRecentDeaths(database)
    local deathHistory = DeathpoolDatabase.GetDeathHistory(database)
    local successfulDeaths = DeathpoolDatabase.GetSuccessfullyPredictedDeaths(database)
    local lockedPrediction = DeathpoolDatabase.GetLockedPrediction(database)

    local maxRecentDeaths = options.maxRecentDeaths or STORAGE_RULES.maxRecentDeaths
    local maxDeathHistory = options.maxDeathHistory or STORAGE_RULES.maxDeathHistory
    local maxSuccessfullyPredictedDeaths = options.maxSuccessfullyPredictedDeaths or STORAGE_RULES.maxSuccessfullyPredictedDeaths

    -- First score the prediction with the preview streak so we can decide
    -- whether this death extends or breaks the live streak.
    local evaluation = DeathpoolLogic.EvaluatePrediction(lockedPrediction, death)
    local predictionStreak = ApplyPredictionStreak(database, evaluation)
    local elements = DeathpoolLogic.GetPredictionElements(lockedPrediction)
    local score = DeathpoolLogic.ScoreDeathEvent(elements, death, predictionStreak, options)
    local sameZoneBonusApplied = score.sameZoneBonusApplied == true

    local recentDeath = DeathpoolLogic._CreateStoredDeathEntry(
        death,
        lockedPrediction,
        score,
        predictionStreak,
        true,
        sameZoneBonusApplied
    )
    local historyDeath = DeathpoolLogic._CreateStoredDeathEntry(
        death,
        lockedPrediction,
        score,
        predictionStreak,
        false,
        sameZoneBonusApplied
    )

    -- Recent deaths drives the main window; deathHistory feeds the scrollable log.
    table.insert(recentDeaths, recentDeath)
    table.insert(deathHistory, historyDeath)
    if score.matched == true then
        table.insert(successfulDeaths, historyDeath)
    end
    DeathpoolDatabase.SetTotalPoints(
        database,
        DeathpoolDatabase.GetTotalPoints(database) + DeathpoolLogic.GetStoredDeathAwardedPoints(recentDeath)
    )

    -- Trim oldest entries so SavedVariables stay bounded.
    TrimDeathsToLimit(recentDeaths, maxRecentDeaths)
    TrimDeathsToLimit(deathHistory, maxDeathHistory)
    TrimSuccessfulPredictedDeathsToLimit(successfulDeaths, maxSuccessfullyPredictedDeaths)

    return true, score
end

return DeathpoolLogic

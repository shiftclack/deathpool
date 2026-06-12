return function(context)
    local DeathpoolLogic = context.DeathpoolLogic
    local Fixtures = context.Fixtures
    local SCORE_RULES = context.SCORE_RULES
    local STORAGE_RULES = context.STORAGE_RULES
    local Helpers = context.Helpers
    local suite = context.suite
    local assertEquals = function(actual, expected, message)
        suite:assertEquals(actual, expected, message)
    end
    local assertTruthy = function(value, message)
        suite:assertTruthy(value, message)
    end

    local function testDedupeAndRetention()
        local database = Fixtures.database({
            lockedPrediction = Fixtures.prediction({
                levelRange = false,
                source = "hogger",
                zone = false,
            }),
        })
        local recentDeathKeys = {}

        local added = DeathpoolLogic.AddDeathToDatabase(database, Helpers.createDeathForInsert({
            name = "Drakedog",
            sourceName = "Hogger",
        }), recentDeathKeys, Fixtures.addDeathOptions({
            now = 100,
            dedupeWindowSeconds = 5,
            maxRecentDeaths = 2,
        }))
        assertTruthy(added, "first death should be accepted")
        assertEquals(
            database.totalPoints,
            Helpers.getExpectedBasePoints({ source = true }) * Helpers.getDisplayMultiplier(1, 1),
            "first matching source should add multiplied points"
        )
        assertEquals(database.correctPredictionStreak, 1, "first match should start a streak")
        assertEquals(database.longestPredictionStreak, 1, "first match should initialize the longest streak")
        assertEquals(database.recentDeaths[1].matchedPrediction, true, "matching source should mark the death as matched")
        assertEquals(database.recentDeaths[1].points, Helpers.getExpectedBasePoints({ source = true }), "matching source should store base points on the death row")
        assertEquals(database.recentDeaths[1].time, nil, "stored deaths should not persist formatted time strings")
        assertEquals(database.recentDeaths[1].isBlizzardVerified, nil, "stored deaths should not persist constant verification flags")
        assertEquals(database.recentDeaths[1].server, "Defias Pillager", "stored deaths should persist the server they were parsed on")
        assertEquals(
            DeathpoolLogic.GetStoredDeathMultiplierValue(database.recentDeaths[1]),
            Helpers.getDisplayMultiplier(1, 1),
            "first match should use the configured one-field multiplier"
        )
        assertEquals(database.recentDeaths[1].multiplier, nil, "first match should not persist formatted multiplier text")
        assertEquals(
            DeathpoolLogic.GetStoredDeathAwardedPoints(database.recentDeaths[1]),
            Helpers.getExpectedBasePoints({ source = true }) * Helpers.getDisplayMultiplier(1, 1),
            "first match should store awarded multiplied points"
        )
        assertEquals(
            database.recentDeaths[1].awardedPoints,
            Helpers.getExpectedBasePoints({ source = true }) * Helpers.getDisplayMultiplier(1, 1),
            "recent death rows should persist awarded totals for UI rendering"
        )
        assertEquals(database.recentDeaths[1].predictionStreak, 1, "stored deaths should persist the resolved streak count")
        assertEquals(database.recentDeaths[1].streakMultiplier, 0, "recent death rows should persist the streak multiplier contribution")
        assertEquals(
            database.recentDeaths[1].prediction and database.recentDeaths[1].prediction.lockedAt,
            12345,
            "per-death prediction snapshots should persist the full prediction timestamp"
        )

        local duplicateAdded = DeathpoolLogic.AddDeathToDatabase(database, Helpers.createDeathForInsert({
            name = "Drakedog",
            sourceName = "Defias",
        }), recentDeathKeys, Fixtures.addDeathOptions({
            now = 103,
            dedupeWindowSeconds = 5,
            maxRecentDeaths = 2,
        }))
        assertEquals(duplicateAdded, false, "duplicate death inside the dedupe window should be rejected")
        assertEquals(#database.recentDeaths, 1, "duplicate death should not be inserted")

        DeathpoolLogic.AddDeathToDatabase(database, Helpers.createDeathForInsert({
            name = "Alamo",
            sourceName = "Hogger",
        }), recentDeathKeys, Fixtures.addDeathOptions({
            now = 110,
            dedupeWindowSeconds = 5,
            maxRecentDeaths = 2,
        }))
        assertEquals(
            database.totalPoints,
            Helpers.getExpectedBasePoints({ source = true }) * (Helpers.getDisplayMultiplier(1, 1) + Helpers.getDisplayMultiplier(1, 2)),
            "second consecutive match should apply the streak bonus"
        )
        assertEquals(database.correctPredictionStreak, 2, "second match should increase the streak")
        assertEquals(database.longestPredictionStreak, 2, "second match should raise the longest streak")
        assertEquals(
            DeathpoolLogic.GetStoredDeathMultiplierValue(database.recentDeaths[2]),
            Helpers.getDisplayMultiplier(1, 2),
            "second match should combine the configured one-field bonus with the streak bonus"
        )
        assertEquals(
            DeathpoolLogic.GetStoredDeathAwardedPoints(database.recentDeaths[2]),
            Helpers.getExpectedBasePoints({ source = true }) * Helpers.getDisplayMultiplier(1, 2),
            "second match should award the combined multiplier"
        )

        DeathpoolLogic.AddDeathToDatabase(database, Helpers.createDeathForInsert({
            name = "Drakedog",
            sourceName = "Murloc",
        }), recentDeathKeys, Fixtures.addDeathOptions({
            now = 120,
            dedupeWindowSeconds = 5,
            maxRecentDeaths = 2,
        }))

        assertEquals(#database.recentDeaths, 2, "history should retain only the configured number of recent deaths")
        assertEquals(#database.deathHistory, 3, "historical log should keep every accepted death")
        assertEquals(database.recentDeaths[1].name, "Alamo", "oldest retained death should roll forward after trimming")
        assertEquals(database.recentDeaths[2].name, "Drakedog", "newest death should be appended after trimming")
        assertEquals(database.deathHistory[1].name, "Drakedog", "historical log should keep the oldest accepted death")
        assertEquals(database.deathHistory[3].name, "Drakedog", "historical log should append the newest accepted death")
        assertEquals(database.deathHistory[1].server, "Defias Pillager", "historical log should also persist the parsed server")
        assertEquals(database.deathHistory[1].awardedPoints, nil, "historical log rows should keep awarded points computed-on-read for compatibility")
        assertEquals(database.deathHistory[1].predictionStreak, 1, "historical log rows should keep streak context for dynamic scoring")
        assertEquals(#database.successfullyPredictedDeaths, 2, "successful predicted deaths should record only matched deaths")
        assertEquals(database.successfullyPredictedDeaths[1].name, "Drakedog", "successful predicted deaths should store full death rows")
        assertEquals(database.correctPredictionStreak, 0, "a miss should reset the streak")
        assertEquals(database.longestPredictionStreak, 2, "a miss should not wipe the longest streak")
        assertEquals(DeathpoolLogic.GetStoredDeathMultiplierValue(database.recentDeaths[2]), 0, "a miss should display the default x0 multiplier")
        assertEquals(DeathpoolLogic.GetStoredDeathAwardedPoints(database.recentDeaths[2]), 0, "a miss should award no points")
    end

    -- TODO: not great tests

    local function testHistoricalLogRetentionCap()
        local database = Fixtures.database({
            lockedPrediction = Fixtures.prediction({
                levelRange = false,
                source = "hogger",
                zone = false,
            }),
        })
        local recentDeathKeys = {}
        local maxDeathHistory = 100
        local sourceOnlyBasePoints = Helpers.getExpectedBasePoints({ source = true })
        local runningTotal = 0

        for index = 1, maxDeathHistory + 5 do
            local expectedAward = sourceOnlyBasePoints * Helpers.getDisplayMultiplier(1, index)
            local added = DeathpoolLogic.AddDeathToDatabase(database, Helpers.createDeathForInsert({
                name = "History" .. tostring(index),
                sourceName = "Hogger",
            }), recentDeathKeys, Fixtures.addDeathOptions({
                now = 1000 + index,
                maxRecentDeaths = STORAGE_RULES.maxRecentDeaths,
                maxDeathHistory = maxDeathHistory,
            }))

            assertTruthy(added, "history cap test death " .. tostring(index) .. " should be inserted")
            runningTotal = runningTotal + expectedAward
        end

        assertEquals(#database.deathHistory, maxDeathHistory, "historical log should retain at most the configured number of deaths")
        assertEquals(database.deathHistory[1].name, "History6", "historical log should trim the oldest deaths first")
        assertEquals(database.deathHistory[maxDeathHistory].name, "History" .. tostring(maxDeathHistory + 5), "historical log should keep the newest death")
        assertEquals(database.totalPoints, runningTotal, "running score should keep cumulative points after history trimming")
        assertEquals(
            DeathpoolLogic.GetDisplayState(database).totalPoints,
            runningTotal,
            "display state should keep using the persisted cumulative score after history trimming"
        )
    end

    local function testSuccessfullyPredictedDeathRetentionCap()
        local database = Fixtures.database({
            lockedPrediction = Fixtures.prediction({
                levelRange = false,
                source = "hogger",
                zone = false,
            }),
        })
        local recentDeathKeys = {}

        local maxSuccessfullyPredictedDeaths = STORAGE_RULES.maxSuccessfullyPredictedDeaths

        for index = 1, maxSuccessfullyPredictedDeaths + 5 do
            local added = DeathpoolLogic.AddDeathToDatabase(database, Helpers.createDeathForInsert({
                name = "Success" .. tostring(index),
                sourceName = "Hogger",
            }), recentDeathKeys, Fixtures.addDeathOptions({
                now = 1200 + index,
                maxRecentDeaths = maxSuccessfullyPredictedDeaths + 5,
                maxSuccessfullyPredictedDeaths = maxSuccessfullyPredictedDeaths,
            }))

            assertTruthy(added, "successful prediction retention test death " .. tostring(index) .. " should be inserted")
        end

        assertEquals(
            #database.successfullyPredictedDeaths,
            maxSuccessfullyPredictedDeaths,
            "successful predicted deaths should retain at most the configured number of entries"
        )
        assertEquals(
            database.successfullyPredictedDeaths[1].name,
            "Success6",
            "successful predicted deaths should keep higher-scoring plateau entries after trimming"
        )
        assertEquals(
            database.successfullyPredictedDeaths[maxSuccessfullyPredictedDeaths].name,
            "Success" .. tostring(maxSuccessfullyPredictedDeaths + 5),
            "successful predicted deaths should keep the newest retained entries"
        )
    end

    local function testSuccessfullyPredictedDeathRetentionPrefersHighestScores()
        local database = Fixtures.database()
        local recentDeathKeys = {}

        local function addSuccessfulDeath(options)
            database.lockedPrediction = options.prediction
            database.correctPredictionStreak = options.streakBefore or 0
            database.longestPredictionStreak = math.max(database.longestPredictionStreak or 0, database.correctPredictionStreak)

            local added = DeathpoolLogic.AddDeathToDatabase(database, Helpers.createDeathForInsert({
                name = options.name,
                level = options.level or 12,
                sourceName = options.sourceName or "Hogger",
                zone = options.zone or "Elwynn Forest",
            }), recentDeathKeys, Fixtures.addDeathOptions({
                now = options.now,
                maxRecentDeaths = 10,
                maxSuccessfullyPredictedDeaths = 3,
            }))

            assertTruthy(added, options.name .. " should be inserted")
        end

        local candidates = {
            {
                name = "HighOne",
                now = 1301,
                streakBefore = 4,
                prediction = Fixtures.prediction(),
            },
            {
                name = "HighTwo",
                now = 1302,
                streakBefore = 3,
                prediction = Fixtures.prediction(),
            },
            {
                name = "MidThree",
                now = 1303,
                streakBefore = 0,
                prediction = Fixtures.prediction({
                    levelRange = false,
                    source = "hogger",
                    zone = false,
                }),
            },
            {
                name = "LowFour",
                now = 1304,
                streakBefore = 0,
                prediction = Fixtures.prediction({
                    levelRange = "10-19",
                    source = false,
                    zone = false,
                }),
            },
        }

        local function getRetentionPoints(candidate)
            local death = Helpers.createDeathForInsert({
                name = candidate.name,
                level = candidate.level or 12,
                sourceName = candidate.sourceName or "Hogger",
                zone = candidate.zone or "Elwynn Forest",
            })
            local elements = DeathpoolLogic.GetPredictionElements(candidate.prediction) or {}
            local score = DeathpoolLogic.ScoreDeathEvent(elements, death, SCORE_RULES.previewStreak)
            return score.awardedPoints or 0
        end

        for _, candidate in ipairs(candidates) do
            addSuccessfulDeath(candidate)
        end

        assertEquals(#database.successfullyPredictedDeaths, 3, "successful predicted deaths should still honor the configured cap")

        local expectedDroppedCandidate = candidates[1]
        local expectedDroppedPoints = getRetentionPoints(expectedDroppedCandidate)

        for index = 2, #candidates do
            local candidate = candidates[index]
            local candidatePoints = getRetentionPoints(candidate)

            if candidatePoints < expectedDroppedPoints
                or (candidatePoints == expectedDroppedPoints and candidate.now < expectedDroppedCandidate.now) then
                expectedDroppedCandidate = candidate
                expectedDroppedPoints = candidatePoints
            end
        end

        local retainedNames = {}
        for index, death in ipairs(database.successfullyPredictedDeaths) do
            retainedNames[index] = death.name
        end

        local retainedNameList = table.concat(retainedNames, ",")
        assertEquals(
            string.find(retainedNameList, expectedDroppedCandidate.name, 1, true),
            nil,
            "successful predicted deaths should discard the weakest baseline-scoring entry when the cap is exceeded"
        )

        for _, candidate in ipairs(candidates) do
            if candidate.name ~= expectedDroppedCandidate.name then
                assertTruthy(
                    string.find(retainedNameList, candidate.name, 1, true) ~= nil,
                    "successful predicted deaths should keep every stronger baseline-scoring entry within the cap"
                )
            end
        end
    end

    local function testHighestMultiplierTier()
        local database = Fixtures.database({
            lockedPrediction = Fixtures.prediction({
                levelRange = false,
                source = "hogger",
                zone = false,
                zoneLabel = false,
            }),
        })
        local recentDeathKeys = {}

        for index = 1, 11 do
            DeathpoolLogic.AddDeathToDatabase(database, Helpers.createDeathForInsert({
                name = "Match" .. tostring(index),
                sourceName = "Hogger",
            }), recentDeathKeys, Fixtures.addDeathOptions({
                now = 200 + index,
                maxRecentDeaths = 11,
            }))
        end

        local expectedTotalPoints = 0
        local sourceOnlyBasePoints = Helpers.getExpectedBasePoints({ source = true })

        for index = 1, 11 do
            expectedTotalPoints = expectedTotalPoints + (sourceOnlyBasePoints * Helpers.getDisplayMultiplier(1, index))
        end

        assertEquals(database.correctPredictionStreak, 11, "streak should keep counting after the highest tier is reached")
        assertEquals(database.longestPredictionStreak, 11, "longest streak should track uncapped consecutive wins")
        assertEquals(
            DeathpoolLogic.GetStoredDeathMultiplierValue(database.recentDeaths[10]),
            Helpers.getDisplayMultiplier(1, 10),
            "tenth consecutive match should combine the configured one-field bonus with the capped streak bonus"
        )
        assertEquals(
            DeathpoolLogic.GetStoredDeathMultiplierValue(database.recentDeaths[11]),
            Helpers.getDisplayMultiplier(1, 11),
            "later matches should keep the capped combined multiplier for single-field hits"
        )
        assertEquals(database.totalPoints, expectedTotalPoints, "total points should include the combined match and streak multipliers")
    end

    testDedupeAndRetention()
    testHistoricalLogRetentionCap()
    testSuccessfullyPredictedDeathRetentionCap()
    testSuccessfullyPredictedDeathRetentionPrefersHighestScores()
    testHighestMultiplierTier()
end

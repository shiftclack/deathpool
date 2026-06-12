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
    local assertTableLength = function(tbl, expected, message)
        suite:assertTableLength(tbl, expected, message)
    end

    local function testDatabaseInitPreservesIdentity()
        local database = {}
        local returnedDatabase = _G.DeathpoolDatabase.Init(database)

        assertEquals(returnedDatabase, database, "database init should return the same table instance")
        assertTruthy(type(database.recentDeaths) == "table", "database init should populate default recent death storage")
        assertTruthy(type(database.minimap) == "table", "database init should populate minimap settings")
    end

    local function testDatabaseInitRepairsCorruptTopLevelValue()
        local returnedDatabase = _G.DeathpoolDatabase.Init(nil)

        assertTruthy(type(returnedDatabase) == "table", "database init should repair a corrupt top-level savedvariables value")
        assertTruthy(type(returnedDatabase.recentDeaths) == "table", "database init should still populate default recent death storage after repair")
        assertTruthy(type(returnedDatabase.minimap) == "table", "database init should still populate minimap settings after repair")
    end

    local function testDatabaseInitNormalizesStoredState()
        local database = {
            recentDeaths = false,
            deathHistory = false,
            successfullyPredictedDeaths = false,
            totalPoints = "17",
            correctPredictionStreak = "4",
            longestPredictionStreak = "2",
        }

        _G.DeathpoolDatabase.Init(database)

        assertTruthy(type(database.recentDeaths) == "table", "database init should repair recent death storage")
        assertTruthy(type(database.deathHistory) == "table", "database init should repair death history storage")
        assertTruthy(
            type(database.successfullyPredictedDeaths) == "table",
            "database init should repair successful prediction storage"
        )
        assertEquals(database.totalPoints, 17, "database init should normalize total points to a number")
        assertEquals(
            database.correctPredictionStreak,
            4,
            "database init should normalize the current prediction streak to a number"
        )
        assertEquals(
            database.longestPredictionStreak,
            4,
            "database init should keep the longest streak at least as large as the current streak"
        )
    end

    local function testDatabaseInitDefaultsFirstRunFlag()
        local database = {}

        _G.DeathpoolDatabase.Init(database)

        assertEquals(database.hasSeenFirstRun, false, "database init should default the first-run flag to false")
        assertEquals(
            _G.DeathpoolDatabase.GetHasSeenFirstRun(database),
            false,
            "database getter should report unseen first-run state by default"
        )
        assertEquals(
            _G.DeathpoolDatabase.SetHasSeenFirstRun(database, true),
            true,
            "database setter should persist a seen first-run state"
        )
        assertEquals(
            _G.DeathpoolDatabase.GetHasSeenFirstRun(database),
            true,
            "database getter should report the persisted first-run state"
        )
    end

    local function testDatabaseResetGameplayState()
        local database = Fixtures.database({
            lockedPrediction = Fixtures.prediction(),
            lastPrediction = Fixtures.prediction({
                source = "defias",
                sourceLabel = "Defias",
            }),
            draftPrediction = Fixtures.prediction({
                zone = "westfall",
                zoneLabel = "Westfall",
            }),
            recentDeaths = {
                Fixtures.storedDeath({
                    timestamp = 1001,
                }),
            },
            deathHistory = {
                Fixtures.storedDeath({
                    timestamp = 1002,
                }),
            },
            successfullyPredictedDeaths = {
                Fixtures.storedDeath({
                    timestamp = 1003,
                }),
            },
            totalPoints = 17,
            correctPredictionStreak = 3,
            longestPredictionStreak = 5,
            learnedZones = {
                "Westfall",
            },
            hidden = false,
        })
        local recentDeaths = database.recentDeaths
        local deathHistory = database.deathHistory
        local successfulDeaths = database.successfullyPredictedDeaths

        _G.DeathpoolDatabase.ResetGameplayState(database)

        assertEquals(database.lockedPrediction, nil, "reset gameplay state should clear the locked prediction")
        assertEquals(database.lastPrediction, nil, "reset gameplay state should clear the last prediction")
        assertEquals(database.draftPrediction, nil, "reset gameplay state should clear the draft prediction")
        assertEquals(database.totalPoints, 0, "reset gameplay state should zero total points")
        assertEquals(database.correctPredictionStreak, 0, "reset gameplay state should zero the current streak")
        assertEquals(database.longestPredictionStreak, 0, "reset gameplay state should zero the longest streak")
        assertEquals(database.recentDeaths, recentDeaths, "reset gameplay state should preserve recent death table identity")
        assertEquals(database.deathHistory, deathHistory, "reset gameplay state should preserve death history table identity")
        assertEquals(
            database.successfullyPredictedDeaths,
            successfulDeaths,
            "reset gameplay state should preserve successful prediction table identity"
        )
        assertTableLength(database.recentDeaths, 0, "reset gameplay state should clear recent deaths")
        assertTableLength(database.deathHistory, 0, "reset gameplay state should clear death history")
        assertTableLength(
            database.successfullyPredictedDeaths,
            0,
            "reset gameplay state should clear successful prediction history"
        )
        assertTableLength(database.learnedZones, 1, "reset gameplay state should keep unrelated learned zones")
        assertEquals(database.hidden, false, "reset gameplay state should keep unrelated window state")
    end

    local function testLockedPredictionStateTransitions()
        local samePredictionDatabase = Fixtures.database({
            lockedPrediction = Fixtures.prediction(),
            lastPrediction = Fixtures.prediction(),
            correctPredictionStreak = 4,
            longestPredictionStreak = 6,
        })
        local samePrediction = Fixtures.prediction({
            lockedAt = 99999,
        })

        DeathpoolLogic.ApplyLockedPrediction(samePredictionDatabase, samePrediction)
        assertEquals(
            samePredictionDatabase.correctPredictionStreak,
            4,
            "re-locking the same prediction should preserve the current streak"
        )
        assertEquals(
            DeathpoolLogic.GetPredictionElements(samePredictionDatabase.lockedPrediction).source,
            "hogger",
            "apply locked prediction should store the normalized prediction elements"
        )
        assertEquals(
            samePredictionDatabase.lockedPrediction.lockedAt,
            99999,
            "apply locked prediction should preserve the prediction timestamp"
        )
        assertEquals(
            samePredictionDatabase.lastPrediction.lockedAt,
            99999,
            "apply locked prediction should refresh the last prediction snapshot"
        )

        local changedPredictionDatabase = Fixtures.database({
            lockedPrediction = Fixtures.prediction(),
            lastPrediction = Fixtures.prediction(),
            correctPredictionStreak = 4,
            longestPredictionStreak = 6,
        })
        local changedPrediction = Fixtures.prediction({
            source = "defias",
            sourceLabel = "Defias",
        })

        DeathpoolLogic.ApplyLockedPrediction(changedPredictionDatabase, changedPrediction)
        assertEquals(
            changedPredictionDatabase.correctPredictionStreak,
            0,
            "locking in a different prediction should reset the active streak"
        )
        assertEquals(
            changedPredictionDatabase.longestPredictionStreak,
            6,
            "locking in a different prediction should not erase the longest streak"
        )

        local clearedDatabase = Fixtures.database({
            lockedPrediction = Fixtures.prediction(),
            lastPrediction = Fixtures.prediction({
                source = "defias",
                sourceLabel = "Defias",
            }),
        })

        DeathpoolLogic.ClearLockedPrediction(clearedDatabase)
        assertEquals(clearedDatabase.lockedPrediction, nil, "clearing the locked prediction should unlock the database state")
        assertTruthy(clearedDatabase.lastPrediction ~= nil, "clearing the locked prediction should preserve a draft prediction")
        assertEquals(
            DeathpoolLogic.GetPredictionElements(clearedDatabase.lastPrediction).source,
            "hogger",
            "clearing the locked prediction should keep the most recent locked prediction as the draft"
        )
    end

    local function testDraftPredictionStateTransitions()
        local lockedPrediction = Fixtures.prediction()
        local database = Fixtures.database({
            lockedPrediction = lockedPrediction,
        })

        local updatedDraft = DeathpoolLogic.UpdateDraftPrediction(database, {
            elements = {
                source = "Defias Pillager",
                zone = "Westfall",
            },
        })

        assertTruthy(updatedDraft ~= nil, "updating a draft prediction should return the normalized draft")
        assertEquals(
            DeathpoolLogic.GetPredictionElements(database.draftPrediction).source,
            "defias pillager",
            "updating a draft prediction should normalize the stored source"
        )
        assertEquals(
            DeathpoolLogic.GetPredictionElements(database.draftPrediction).zone,
            "westfall",
            "updating a draft prediction should normalize the stored zone"
        )
        assertEquals(
            database.lockedPrediction,
            lockedPrediction,
            "updating a draft prediction should not disturb the locked prediction"
        )

        local clearedDraft = DeathpoolLogic.UpdateDraftPrediction(database, {
            elements = {},
        })

        assertEquals(clearedDraft, nil, "clearing every draft element should return nil")
        assertEquals(database.draftPrediction, nil, "clearing every draft element should remove the stored draft")
    end

    local function testMultiplierSequenceProgression()
        local database = Fixtures.database({
            lockedPrediction = Fixtures.prediction({
                levelRange = false,
                source = "hogger",
                zone = false,
                zoneLabel = false,
            }),
        })
        local recentDeathKeys = {}
        local sourcePoints = Helpers.getExpectedBasePoints({ source = true })
        local expectedTotals = {}
        local expectedMultipliers = {}
        local runningTotal = 0

        for index = 1, 6 do
            local expectedMultiplier = Helpers.getDisplayMultiplier(1, index)
            expectedMultipliers[index] = expectedMultiplier
            runningTotal = runningTotal + (sourcePoints * expectedMultiplier)
            expectedTotals[index] = runningTotal
        end

        for index, expectedMultiplier in ipairs(expectedMultipliers) do
            local added, evaluation = DeathpoolLogic.AddDeathToDatabase(database, Helpers.createDeathForInsert({
                name = "Streak" .. tostring(index),
                sourceName = "Hogger",
            }), recentDeathKeys, Fixtures.addDeathOptions({
                now = 300 + index,
                maxRecentDeaths = 10,
            }))

            assertTruthy(added, "streak match " .. tostring(index) .. " should be inserted")
            assertTruthy(evaluation.matched, "streak match " .. tostring(index) .. " should evaluate as matched")
            assertEquals(
                evaluation.basePoints,
                sourcePoints,
                "streak match " .. tostring(index) .. " should keep the same base points"
            )
            assertEquals(
                database.correctPredictionStreak,
                index,
                "streak match " .. tostring(index) .. " should update the stored streak"
            )
            assertEquals(
                database.longestPredictionStreak,
                index,
                "streak match " .. tostring(index) .. " should update the stored longest streak"
            )
            assertEquals(
                DeathpoolLogic.GetStoredDeathMultiplierValue(database.recentDeaths[index]),
                expectedMultiplier,
                "streak match " .. tostring(index) .. " should use the right multiplier"
            )
            assertEquals(
                database.recentDeaths[index].multiplier,
                nil,
                "streak match " .. tostring(index) .. " should not persist a formatted multiplier string"
            )
            assertEquals(
                DeathpoolLogic.GetStoredDeathAwardedPoints(database.recentDeaths[index]),
                sourcePoints * expectedMultiplier,
                "streak match " .. tostring(index) .. " should award multiplied points"
            )
            assertEquals(database.totalPoints, expectedTotals[index], "streak match " .. tostring(index) .. " should roll into the running total")
        end
    end

    local function testFullPointFormula()
        local database = Fixtures.database({
            lockedPrediction = Fixtures.prediction(),
        })
        local recentDeathKeys = {}
        local fullMatchBasePoints = Helpers.getExpectedBasePoints({
            levelRange = "10-19",
            level = 12,
            source = true,
            zone = true,
        })
        local runningTotal = 0

        for index = 1, 10 do
            local added, evaluation = DeathpoolLogic.AddDeathToDatabase(database, Helpers.createDeathForInsert({
                name = "Formula" .. tostring(index),
            }), recentDeathKeys, Fixtures.addDeathOptions({
                now = 600 + index,
                maxRecentDeaths = STORAGE_RULES.maxRecentDeaths + 7,
            }))

            local expectedMultiplier = Helpers.getDisplayMultiplier(3, index)
            local expectedAward = fullMatchBasePoints * expectedMultiplier

            runningTotal = runningTotal + expectedAward

            assertTruthy(added, "formula test death " .. tostring(index) .. " should be inserted")
            assertEquals(evaluation.basePoints, fullMatchBasePoints, "full formula should use the configured full-match base points")
            assertEquals(
                DeathpoolLogic.GetStoredDeathMultiplierValue(database.recentDeaths[index]),
                expectedMultiplier,
                "full formula should use the summed display multiplier for streak " .. tostring(index)
            )
            assertEquals(
                DeathpoolLogic.GetStoredDeathAwardedPoints(database.recentDeaths[index]),
                expectedAward,
                "full formula should award the correct total for streak " .. tostring(index)
            )
            assertEquals(
                database.totalPoints,
                runningTotal,
                "full formula should roll each awarded total into the running score"
            )
        end
    end

    local function testMultiplierResetAfterMiss()
        local database = Fixtures.database({
            lockedPrediction = Fixtures.prediction({
                levelRange = false,
                source = "hogger",
                zone = false,
                zoneLabel = false,
            }),
        })
        local recentDeathKeys = {}

        DeathpoolLogic.AddDeathToDatabase(database, Helpers.createDeathForInsert({
            name = "HitOne",
            sourceName = "Hogger",
        }), recentDeathKeys, Fixtures.addDeathOptions({
            now = 400,
            maxRecentDeaths = 10,
        }))
        DeathpoolLogic.AddDeathToDatabase(database, Helpers.createDeathForInsert({
            name = "HitTwo",
            sourceName = "Hogger",
        }), recentDeathKeys, Fixtures.addDeathOptions({
            now = 401,
            maxRecentDeaths = 10,
        }))

        local missedAdded = DeathpoolLogic.AddDeathToDatabase(database, Helpers.createDeathForInsert({
            name = "Missed",
            sourceName = "Defias",
        }), recentDeathKeys, Fixtures.addDeathOptions({
            now = 402,
            maxRecentDeaths = 10,
        }))
        assertTruthy(missedAdded, "a missed prediction should still create a death row")
        assertEquals(
            database.correctPredictionStreak,
            0,
            "a missed prediction should reset the streak to zero"
        )
        assertEquals(database.longestPredictionStreak, 2, "a missed prediction should preserve the best streak reached")
        assertEquals(DeathpoolLogic.GetStoredDeathMultiplierValue(database.recentDeaths[3]), 0, "a missed prediction should display x0")
        assertEquals(DeathpoolLogic.GetStoredDeathAwardedPoints(database.recentDeaths[3]), 0, "a missed prediction should award zero points")

        local resetAdded = DeathpoolLogic.AddDeathToDatabase(database, Helpers.createDeathForInsert({
            name = "HitAfterMiss",
            sourceName = "Hogger",
        }), recentDeathKeys, Fixtures.addDeathOptions({
            now = 403,
            maxRecentDeaths = 10,
        }))
        assertTruthy(resetAdded, "a new correct prediction after a miss should still be inserted")
        assertEquals(database.correctPredictionStreak, 1, "the first hit after a miss should restart at streak one")
        assertEquals(database.longestPredictionStreak, 2, "the first hit after a miss should not reduce the longest streak")
        assertEquals(
            DeathpoolLogic.GetStoredDeathMultiplierValue(database.recentDeaths[4]),
            Helpers.getDisplayMultiplier(1, 1),
            "the first hit after a miss should restart at the configured one-field multiplier"
        )
        assertEquals(
            DeathpoolLogic.GetStoredDeathAwardedPoints(database.recentDeaths[4]),
            Helpers.getExpectedBasePoints({ source = true }) * Helpers.getDisplayMultiplier(1, 1),
            "the first hit after a miss should award the configured one-field multiplier"
        )
        assertEquals(
            database.totalPoints,
            Helpers.getExpectedBasePoints({ source = true }) * (
                Helpers.getDisplayMultiplier(1, 1)
                + Helpers.getDisplayMultiplier(1, 2)
                + Helpers.getDisplayMultiplier(1, 1)
            ),
            "the running total should only include the actual awarded values"
        )
    end

    local function testPartialMultiFieldMissResetsStreak()
        local database = Fixtures.database({
            lockedPrediction = Fixtures.prediction(),
            correctPredictionStreak = 2,
        })
        local recentDeathKeys = {}

        local added, evaluation = DeathpoolLogic.AddDeathToDatabase(database, Helpers.createDeathForInsert({
            name = "AlmostRight",
            zone = "Westfall",
        }), recentDeathKeys, Fixtures.addDeathOptions({
            now = 700,
            maxRecentDeaths = 10,
        }))

        assertTruthy(added, "partial multi-field misses should still be recorded")
        assertEquals(evaluation.levelMatched, true, "partial multi-field misses should keep per-field match data")
        assertEquals(evaluation.sourceMatched, true, "partial multi-field misses should keep per-field source data")
        assertEquals(evaluation.zoneMatched, false, "partial multi-field misses should mark the missed field")
        assertTruthy(evaluation.matched, "partial multi-field misses should now count as partial wins")
        assertEquals(database.correctPredictionStreak, 3, "partial multi-field wins should advance the streak")
        assertEquals(
            database.recentDeaths[1].points,
            Helpers.getExpectedBasePoints({ levelRange = "10-19", level = 12, source = true }),
            "partial multi-field wins should award the matched base points"
        )
        assertEquals(
            DeathpoolLogic.GetStoredDeathMultiplierValue(database.recentDeaths[1]),
            Helpers.getDisplayMultiplier(2, 3),
            "partial multi-field wins should show the summed matched-combination multiplier"
        )
        assertEquals(
            DeathpoolLogic.GetStoredDeathAwardedPoints(database.recentDeaths[1]),
            Helpers.getExpectedBasePoints({ levelRange = "10-19", level = 12, source = true })
                * Helpers.getDisplayMultiplier(2, 3),
            "partial multi-field wins should apply the combo sum to the matched base points"
        )
    end

    local function testSameZoneBonusPersistsOnStoredDeaths()
        local database = Fixtures.database({
            lockedPrediction = Fixtures.prediction({
                levelRange = "10-19",
                source = "hogger",
                zone = "elwynn forest",
            }),
        })
        local recentDeathKeys = {}
        local added, evaluation = DeathpoolLogic.AddDeathToDatabase(database, Helpers.createDeathForInsert({
            name = "SameZone",
            sourceName = "Hogger",
            zone = "Elwynn Forest",
        }), recentDeathKeys, Fixtures.addDeathOptions({
            now = 901,
            maxRecentDeaths = 10,
            playerZone = "Elwynn Forest",
        }))
        local expectedBasePoints = Helpers.getExpectedBasePoints({
            levelRange = "10-19",
            level = 12,
            source = true,
            zone = true,
        })
        local expectedMultiplier = Helpers.getDisplayMultiplier(3, 1)
        local expectedAwardedPoints = (expectedBasePoints + SCORE_RULES.sameZoneFixedBonusPoints) * expectedMultiplier

        assertTruthy(added, "same-zone bonus deaths should still be inserted")
        assertEquals(
            evaluation.sameZoneBonusPoints,
            SCORE_RULES.sameZoneFixedBonusPoints,
            "same-zone bonus should be included in the live score result"
        )
        assertEquals(
            database.recentDeaths[1].sameZoneBonusApplied,
            true,
            "same-zone bonus flag should persist on recent deaths"
        )
        assertEquals(
            database.deathHistory[1].sameZoneBonusApplied,
            true,
            "same-zone bonus flag should persist on history deaths"
        )
        assertEquals(
            DeathpoolLogic.GetStoredDeathAwardedPoints(database.recentDeaths[1]),
            expectedAwardedPoints,
            "same-zone bonus should roll into stored awarded points"
        )
        assertEquals(
            database.totalPoints,
            expectedAwardedPoints,
            "same-zone bonus should roll into the running total"
        )

        local noZoneDatabase = Fixtures.database({
            lockedPrediction = Fixtures.prediction({
                levelRange = false,
                source = "hogger",
                zone = false,
                zoneLabel = false,
            }),
        })
        local noZoneRecentDeathKeys = {}
        local noZoneAdded, noZoneEvaluation = DeathpoolLogic.AddDeathToDatabase(
            noZoneDatabase,
            Helpers.createDeathForInsert({
                name = "SameZoneNoPrediction",
                sourceName = "Hogger",
                zone = "Elwynn Forest",
            }),
            noZoneRecentDeathKeys,
            Fixtures.addDeathOptions({
                now = 902,
                maxRecentDeaths = 10,
                playerZone = "Elwynn Forest",
            })
        )
        local expectedNoZoneBasePoints = Helpers.getExpectedBasePoints({
            source = true,
        })
        local expectedNoZoneMultiplier = Helpers.getDisplayMultiplier(1, 1)
        local expectedNoZoneAwardedPoints = (expectedNoZoneBasePoints + SCORE_RULES.sameZoneFixedBonusPoints)
            * expectedNoZoneMultiplier

        assertTruthy(noZoneAdded, "same-zone bonus deaths without a zone prediction should still be inserted")
        assertEquals(
            noZoneEvaluation.sameZoneBonusPoints,
            SCORE_RULES.sameZoneFixedBonusPoints,
            "same-zone bonus should still apply when the scoring match came from another field"
        )
        assertEquals(
            noZoneEvaluation.matchedElementCount,
            1,
            "same-zone bonus should not increase the matched prediction count when zone was not selected"
        )
        assertEquals(
            DeathpoolLogic.GetStoredDeathAwardedPoints(noZoneDatabase.recentDeaths[1]),
            expectedNoZoneAwardedPoints,
            "same-zone bonus should still roll into stored awarded points without a zone prediction"
        )
    end

    local function testNoPredictionUsesDefaultMultiplierWithoutPoints()
        local database = Fixtures.database({
            correctPredictionStreak = 3,
            longestPredictionStreak = 3,
        })
        local recentDeathKeys = {}

        local added, evaluation = DeathpoolLogic.AddDeathToDatabase(database, Helpers.createDeathForInsert({
            name = "Unpredicted",
            sourceName = "Hogger",
        }), recentDeathKeys, Fixtures.addDeathOptions({
            now = 500,
            maxRecentDeaths = 10,
        }))

        assertTruthy(added, "a death with no locked prediction should still be inserted")
        assertEquals(evaluation.basePoints, 0, "a missing prediction should evaluate to zero base points")
        assertEquals(
            database.correctPredictionStreak,
            0,
            "a missing prediction should reset any existing streak"
        )
        assertEquals(database.longestPredictionStreak, 3, "a missing prediction should preserve the existing longest streak")
        assertTableLength(database.recentDeaths, 1, "a death with no locked prediction should be recorded once")
        assertTableLength(database.deathHistory, 1, "historical log should still record deaths with no prediction")
        assertTableLength(database.successfullyPredictedDeaths, 0, "a death with no locked prediction should not add a successful predicted death")
        assertEquals(
            DeathpoolLogic.GetStoredDeathMultiplierValue(database.recentDeaths[1]),
            0,
            "a death with no locked prediction should display x0"
        )
        assertEquals(
            DeathpoolLogic.GetStoredDeathAwardedPoints(database.recentDeaths[1]),
            0,
            "a death with no locked prediction should award zero points"
        )
        assertEquals(database.totalPoints, 0, "a death with no locked prediction should not change the total")
    end

    local function testAddDeathInitializesHistoryByDefault()
        local database = Fixtures.database({
            deathHistory = false,
        })
        local recentDeathKeys = {}

        local added = DeathpoolLogic.AddDeathToDatabase(database, Helpers.createDeathForInsert({
            name = "HistoryInit",
            sourceName = "Defias",
        }), recentDeathKeys, Fixtures.addDeathOptions({
            now = 900,
            maxRecentDeaths = 5,
        }))

        assertTruthy(added, "add death should succeed when deathHistory is missing")
        assertTableLength(database.deathHistory, 1, "add death should initialize missing historical log state")
        assertTableLength(database.successfullyPredictedDeaths, 0, "add death should initialize missing successful predicted death state")
    end

    local function testGetDisplayStateBuildsRefreshData()
        local recentDeath = Fixtures.storedDeath({
            timestamp = 200,
            name = "Displaydeath",
        })
        local historyDeath = Fixtures.storedDeath({
            timestamp = 180,
            points = 999,
            multiplierValue = 9,
            awardedPoints = 8991,
        })
        local database = Fixtures.database({
            recentDeaths = { recentDeath },
            deathHistory = { historyDeath },
            totalPoints = 12345,
            correctPredictionStreak = 4,
            longestPredictionStreak = 7,
            lockedPrediction = Fixtures.prediction(),
            draftPrediction = Fixtures.prediction({
                source = "gnoll",
            }),
            lastPrediction = Fixtures.prediction({
                source = "defias",
                sourceLabel = "Defias",
            }),
        })

        local state = DeathpoolLogic.GetDisplayState(database)

        assertEquals(state.deaths, database.recentDeaths, "display state should expose the stored recent deaths")
        assertEquals(
            state.totalPoints,
            12345,
            "display state should expose the persisted total points"
        )
        assertEquals(state.currentPredictionStreak, 4, "display state should expose the current streak")
        assertEquals(state.longestPredictionStreak, 7, "display state should expose the longest streak")
        assertEquals(state.lockedPrediction, database.lockedPrediction, "display state should expose the locked prediction")
        assertEquals(state.draftPrediction, database.draftPrediction, "display state should expose the live draft prediction")
        assertEquals(state.lastPrediction, database.lastPrediction, "display state should expose the last prediction draft")
    end

    testDatabaseInitPreservesIdentity()
    testDatabaseInitRepairsCorruptTopLevelValue()
    testDatabaseInitNormalizesStoredState()
    testDatabaseInitDefaultsFirstRunFlag()
    testDatabaseResetGameplayState()
    testLockedPredictionStateTransitions()
    testDraftPredictionStateTransitions()
    testMultiplierSequenceProgression()
    testFullPointFormula()
    testMultiplierResetAfterMiss()
    testPartialMultiFieldMissResetsStreak()
    testSameZoneBonusPersistsOnStoredDeaths()
    testNoPredictionUsesDefaultMultiplierWithoutPoints()
    testAddDeathInitializesHistoryByDefault()
    testGetDisplayStateBuildsRefreshData()
end

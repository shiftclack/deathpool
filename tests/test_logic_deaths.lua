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

    local function testNormalizeDeathEvent()
        local originalTime = time
        local death

        time = function()
            return 12345
        end

        death = DeathpoolLogic.NormalizeDeathEvent(Fixtures.death({
            name = "Drakedog",
            level = 10,
            causeType = "HARDCORE_CAUSEOFDEATH_CREATURE",
            sourceName = "Kobold Miner",
            zone = "Elwynn Forest",
            sourceMessage = "raw",
        }))

        time = originalTime

        assertEquals(death.timestamp, 12345, "normalized death should use the global time function")
        assertEquals(death.server, "Defias Pillager", "normalized death should preserve the parsed server when present")
        assertTruthy(death.isBlizzardVerified, "normalized death should mark Blizzard verification")
    end

    local function testStoredDeathHelpers()
        assertEquals(
            DeathpoolLogic.GetStoredDeathStreakMultiplierValue(Fixtures.storedDeath({
                predictionStreak = 4,
            })),
            math.min(3 * SCORE_RULES.streakBonusStep, SCORE_RULES.maxStreakBonus),
            "stored death streak display value should use the raw streak bonus step"
        )

        local fullMatchBasePoints = Helpers.getExpectedBasePoints({
            levelRange = "10-19",
            level = 12,
            source = true,
            zone = true,
        })
        local fullMatchMultiplier = Helpers.getDisplayMultiplier(3, 1)
        local death = Fixtures.storedDeath({
            points = 999,
            multiplierValue = 9,
            awardedPoints = 8991,
            streakMultiplier = 99,
            predictionStreak = 1,
            prediction = Fixtures.prediction({
                lockedAt = 54321,
            }),
        })

        assertEquals(DeathpoolLogic.GetStoredDeathBasePoints(death), fullMatchBasePoints, "stored death base points should be recalculated from the saved prediction")
        assertEquals(DeathpoolLogic.GetStoredDeathMultiplierValue(death), fullMatchMultiplier, "stored death multiplier should be recalculated from prediction data and streak")
        assertEquals(DeathpoolLogic.GetStoredDeathAwardedPoints(death), fullMatchBasePoints * fullMatchMultiplier, "stored death awarded points should ignore stale persisted totals")
        assertEquals(
            DeathpoolLogic.GetStoredDeathStreakMultiplierValue(death),
            0,
            "stored death streak contribution should ignore stale persisted values"
        )
        local missedDeath = Fixtures.storedDeath({
            awardedPoints = 0,
            predictionStreak = 0,
            prediction = false,
            matchedPrediction = false,
            points = 0,
            multiplierValue = 0,
        })
        assertEquals(
            DeathpoolLogic.GetStoredDeathTotalPoints({ death, missedDeath }),
            fullMatchBasePoints * fullMatchMultiplier,
            "stored death total points should sum recalculated entry totals"
        )

        local sameZoneDeath = Fixtures.storedDeath({
            sameZoneBonusApplied = true,
            points = 1,
            awardedPoints = 1,
        })
        assertEquals(
            DeathpoolLogic.GetStoredDeathSameZoneBonusPoints(sameZoneDeath),
            SCORE_RULES.sameZoneFixedBonusPoints,
            "stored death same-zone bonus should be recomputed from the persisted flag"
        )
        assertEquals(
            DeathpoolLogic.GetStoredDeathAwardedPoints(sameZoneDeath),
            (fullMatchBasePoints + SCORE_RULES.sameZoneFixedBonusPoints) * fullMatchMultiplier,
            "stored death awarded points should include the recomputed same-zone bonus"
        )

        local missingSameZoneFlagDeath = Fixtures.storedDeath({
            sameZoneBonusApplied = nil,
            points = 1,
            awardedPoints = 1,
        })
        assertEquals(
            DeathpoolLogic.GetStoredDeathSameZoneBonusPoints(missingSameZoneFlagDeath),
            0,
            "stored deaths without the persisted same-zone flag should not infer a bonus during recomputation"
        )
    end

    local function testStoredDeathTimestampFallbacks()
        local timestampOnlyDeath = Fixtures.storedDeath({
            timestamp = 12345,
        })
        assertEquals(
            DeathpoolLogic.GetStoredDeathTime(timestampOnlyDeath),
            date("%H:%M", 12345),
            "stored death time should be derived from the timestamp"
        )

        local missingTimestampDeath = Fixtures.storedDeath({
            timestamp = false,
        })
        assertEquals(
            DeathpoolLogic.GetStoredDeathTime(missingTimestampDeath),
            date("%H:%M", 0),
            "stored death time should display the epoch fallback when the timestamp is missing"
        )
    end

    local function testStoredDeathPersistedAndComputedContributions()
        local persistedContributionDeath = Fixtures.storedDeath({
            streakMultiplier = 7,
            predictionStreak = 99,
        })
        assertEquals(
            DeathpoolLogic.GetStoredDeathStreakMultiplierValue(persistedContributionDeath),
            SCORE_RULES.maxStreakBonus,
            "stored death streak contribution should be recomputed from score data even when stale values were persisted"
        )

        local partialMatchDeath = Fixtures.storedDeath({
            predictionStreak = 3,
            prediction = Fixtures.prediction({
                zone = false,
            }),
            zone = "Westfall",
        })
        assertEquals(
            DeathpoolLogic.GetStoredDeathComboMultiplierValue(partialMatchDeath),
            SCORE_RULES.predictionElementBonusByCount[2] or 0,
            "stored death combo multiplier should isolate the non-streak portion for partial wins"
        )
        assertEquals(
            DeathpoolLogic.GetStoredDeathStreakMultiplierValue(partialMatchDeath),
            (3 - 1) * SCORE_RULES.streakBonusStep,
            "stored death streak contribution should be recomputed when no persisted value exists"
        )

        local comboDetails = DeathpoolLogic.GetStoredDeathComboDetails(partialMatchDeath)
        assertTruthy(comboDetails.matched, "stored death combo details should reuse the stored death prediction and death row")
        assertEquals(
            comboDetails.awardedPoints,
            DeathpoolLogic.GetStoredDeathAwardedPoints(partialMatchDeath),
            "stored death combo details should match the computed awarded points"
        )

        local sameZonePartialDeath = Fixtures.storedDeath({
            predictionStreak = 3,
            sameZoneBonusApplied = true,
            prediction = Fixtures.prediction(),
        })
        local partialBasePoints = Helpers.getExpectedBasePoints({
            levelRange = "10-19",
            level = 12,
            source = true,
            zone = true,
        })
        local partialMultiplier = (SCORE_RULES.predictionElementBonusByCount[3] or 0)
            + ((3 - 1) * SCORE_RULES.streakBonusStep)
        assertEquals(
            DeathpoolLogic.GetStoredDeathAwardedPoints(sameZonePartialDeath),
            (partialBasePoints + SCORE_RULES.sameZoneFixedBonusPoints) * partialMultiplier,
            "stored death awarded points should include same-zone bonus when the zone prediction matched"
        )
    end

    testNormalizeDeathEvent()
    testStoredDeathHelpers()
    testStoredDeathTimestampFallbacks()
    testStoredDeathPersistedAndComputedContributions()
end

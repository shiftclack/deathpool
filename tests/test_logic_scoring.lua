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
    local assertTableLength = function(tbl, expected, message)
        suite:assertTableLength(tbl, expected, message)
    end

    local function testPredictionEvaluation()
        local evaluation = DeathpoolLogic.EvaluatePrediction(
            Fixtures.prediction(),
            Fixtures.death()
        )

        assertTruthy(evaluation.levelMatched, "evaluation should match level")
        assertTruthy(evaluation.sourceMatched, "evaluation should match source")
        assertTruthy(evaluation.zoneMatched, "evaluation should match zone")
        assertTruthy(evaluation.matched, "evaluation should mark overall match")
        assertEquals(evaluation.matchedElementCount, 3, "evaluation should still count all three matched elements")
        assertEquals(
            evaluation.comboBonus,
            SCORE_RULES.predictionElementBonusByCount[3] or 0,
            "evaluation should expose the combo bonus under one canonical field name"
        )
        assertEquals(evaluation.matchBonus, nil, "evaluation should not keep a duplicate combo bonus alias")
        assertEquals(
            evaluation.basePoints,
            Helpers.getExpectedBasePoints({ levelRange = "10-19", level = 12, source = true, zone = true }),
            "evaluation should award the matched level, source, and zone base points together"
        )

        local partialEvaluation = DeathpoolLogic.EvaluatePrediction(
            Fixtures.prediction({
                zone = false,
            }),
            Fixtures.death({
                sourceName = "Defias",
            })
        )

        assertTruthy(partialEvaluation.levelMatched, "partial evaluation should still track which fields matched")
        assertEquals(partialEvaluation.sourceMatched, false, "partial evaluation should track the missed field")
        assertTruthy(partialEvaluation.matched, "partial evaluation should now count any matched element as a win")
        assertEquals(
            partialEvaluation.basePoints,
            DeathpoolLogic.GetLevelPointsForLevel(12),
            "partial evaluation should give level-only matches the configured level points"
        )

        local levelMissSourceHitEvaluation = DeathpoolLogic.EvaluatePrediction(
            Fixtures.prediction({
                levelRange = "20-29",
                source = "hogger",
                zone = false,
            }),
            Fixtures.death({
                level = 12,
            })
        )

        assertEquals(levelMissSourceHitEvaluation.levelMatched, false, "a missed level prediction should stay marked as missed")
        assertTruthy(levelMissSourceHitEvaluation.sourceMatched, "a matched source should still be tracked when level misses")
        assertEquals(
            levelMissSourceHitEvaluation.basePoints,
            Helpers.getExpectedBasePoints({ levelRange = "20-29", level = 12, levelMatched = false, source = true }),
            "source points should still be awarded when the selected level prediction misses"
        )

        local singleFieldEvaluation = DeathpoolLogic.EvaluatePrediction(
            Fixtures.prediction({
                levelRange = false,
                source = "hogger",
                zone = false,
            }),
            Fixtures.death({
                level = 7,
                zone = "Durotar",
            })
        )

        assertTruthy(singleFieldEvaluation.matched, "single selected fields should still win when that field matches")
        assertEquals(
            singleFieldEvaluation.basePoints,
            Helpers.getExpectedBasePoints({ source = true }),
            "single selected field wins should award that field's points"
        )

        local emptyPredictionEvaluation = DeathpoolLogic.EvaluatePrediction({}, Fixtures.death())

        assertEquals(emptyPredictionEvaluation.matched, false, "empty predictions should not count as wins")
        assertEquals(emptyPredictionEvaluation.basePoints, 0, "empty predictions should award no points")

        local highLevelEvaluation = DeathpoolLogic.EvaluatePrediction(
            Fixtures.prediction({
                source = false,
                zone = false,
                levelRange = "50-59",
            }),
            Fixtures.death({
                level = 58,
            })
        )

        assertTruthy(highLevelEvaluation.matched, "high-level range predictions should still match normally")
        assertEquals(
            highLevelEvaluation.basePoints,
            DeathpoolLogic.GetLevelPointsForLevel(58),
            "high-level range wins should award the configured matched level points"
        )

        local missedHighValueEvaluation = DeathpoolLogic.EvaluatePrediction(
            Fixtures.prediction({
                levelRange = "60",
                source = "hogger",
                zone = "elwynn forest",
            }),
            Fixtures.death({
                level = 42,
                sourceName = "Defias Pillager",
                zone = "Westfall",
            })
        )

        assertEquals(missedHighValueEvaluation.matched, false, "full misses should not count as matched")
        assertEquals(missedHighValueEvaluation.basePoints, 0, "full misses should not use prediction points from selected elements")
        assertEquals(missedHighValueEvaluation.combinationCount, 0, "full misses should not build any scoring combinations")

        local zoneCombinationEvaluation = DeathpoolLogic.EvaluatePrediction(
            Fixtures.prediction({
                levelRange = false,
                source = "defias pillager",
                zone = "westfall",
            }),
            Fixtures.death({
                sourceName = "  Defias Pillager  ",
                zone = "  WESTFALL  ",
            })
        )

        assertTruthy(zoneCombinationEvaluation.sourceMatched, "zone combination evaluation should still match source text after trimming")
        assertTruthy(zoneCombinationEvaluation.zoneMatched, "zone combination evaluation should match zone text after trimming")
        assertTruthy(zoneCombinationEvaluation.matched, "zone combination evaluation should count source plus zone as a win")
        assertEquals(
            zoneCombinationEvaluation.basePoints,
            Helpers.getExpectedBasePoints({ source = true, zone = true }),
            "zone combination evaluation should include the zone points in the combined base total"
        )
        assertEquals(
            zoneCombinationEvaluation.combinationCount,
            Helpers.getCombinationCount(2),
            "zone combination evaluation should include the zone-based subsets"
        )
    end

    local function testSameZoneBonusPoints()
        local matchedEvaluation = DeathpoolLogic.ScoreDeathEvent(
            DeathpoolLogic.GetPredictionElements(Fixtures.prediction()),
            Fixtures.death(),
            2,
            { playerZone = "Elwynn Forest" }
        )
        local basePoints = Helpers.getExpectedBasePoints({
            levelRange = "10-19",
            level = 12,
            source = true,
            zone = true,
        })
        local totalMultiplier = Helpers.getDisplayMultiplier(3, 2)

        assertEquals(
            matchedEvaluation.sameZoneBonusPoints,
            SCORE_RULES.sameZoneFixedBonusPoints,
            "same-zone bonus should add the configured fixed points on matched deaths"
        )
        assertEquals(
            matchedEvaluation.awardedPoints,
            (basePoints + SCORE_RULES.sameZoneFixedBonusPoints) * totalMultiplier,
            "same-zone bonus should contribute to awarded points before multiplier math"
        )
        assertEquals(
            matchedEvaluation.comboBonus,
            SCORE_RULES.predictionElementBonusByCount[3] or 0,
            "same-zone bonus should not change combo bonus"
        )
        assertEquals(
            matchedEvaluation.streakBonus,
            SCORE_RULES.streakBonusStep,
            "same-zone bonus should not change streak bonus"
        )
        assertEquals(
            matchedEvaluation.matchedElementCount,
            3,
            "same-zone bonus should not change the matched element count when zone was predicted"
        )

        local noZonePredictionEvaluation = DeathpoolLogic.ScoreDeathEvent(
            DeathpoolLogic.GetPredictionElements(Fixtures.prediction({
                zone = false,
            })),
            Fixtures.death(),
            2,
            { playerZone = "Elwynn Forest" }
        )
        local noZoneBasePoints = Helpers.getExpectedBasePoints({
            levelRange = "10-19",
            level = 12,
            source = true,
        })
        local noZoneMultiplier = Helpers.getDisplayMultiplier(2, 2)

        assertEquals(
            noZonePredictionEvaluation.sameZoneBonusPoints,
            SCORE_RULES.sameZoneFixedBonusPoints,
            "same-zone bonus should still apply when another predicted field matched in the same zone"
        )
        assertEquals(
            noZonePredictionEvaluation.matchedElementCount,
            2,
            "same-zone bonus should not count as a matched prediction element when zone was not predicted"
        )
        assertEquals(
            noZonePredictionEvaluation.awardedPoints,
            (noZoneBasePoints + SCORE_RULES.sameZoneFixedBonusPoints) * noZoneMultiplier,
            "same-zone bonus should add into the total even when zone was not predicted"
        )

        local nonBonusEvaluation = DeathpoolLogic.ScoreDeathEvent(
            DeathpoolLogic.GetPredictionElements(Fixtures.prediction()),
            Fixtures.death(),
            2,
            { playerZone = "Westfall" }
        )
        assertEquals(nonBonusEvaluation.sameZoneBonusPoints, 0, "same-zone bonus should stay zero when the flag is off")

        local previewEvaluation = DeathpoolLogic.ScorePreview(
            DeathpoolLogic.GetPredictionElements(Fixtures.prediction()),
            2
        )
        assertEquals(
            previewEvaluation.sameZoneBonusPoints,
            0,
            "preview scoring should not apply the live same-zone bonus"
        )

        local missedEvaluation = DeathpoolLogic.ScoreDeathEvent(
            DeathpoolLogic.GetPredictionElements(Fixtures.prediction({
                levelRange = "60",
                source = "defias pillager",
                zone = "westfall",
            })),
            Fixtures.death(),
            2,
            { playerZone = "Elwynn Forest" }
        )
        assertEquals(missedEvaluation.matched, false, "full misses should still count as misses with same-zone bonus enabled")
        assertEquals(missedEvaluation.sameZoneBonusPoints, 0, "same-zone bonus should not apply on full misses")
        assertEquals(missedEvaluation.awardedPoints, 0, "full misses should still award zero points")
    end

    local function testComboDetails()
        local details = DeathpoolLogic.GetComboDetails(
            Fixtures.prediction({
                levelRange = false,
                source = "benny blaanco",
                zone = "elwynn forest",
            }),
            Fixtures.death({
                sourceName = "Benny Blaanco",
                zone = "Elwynn Forest",
            }),
            2
        )

        assertTruthy(details.matched, "combo details should report when the prediction scored")
        local expectedBasePoints = Helpers.getExpectedBasePoints({ source = true, zone = true })
        local expectedComboSum = Helpers.getDisplayMultiplier(2, 2)
        assertEquals(details.basePoints, expectedBasePoints, "combo details should use the matched base points")
        assertEquals(details.comboSum, expectedComboSum, "combo details should use the best successful combination multiplier")
        assertEquals(details.displayComboSum, "x" .. tostring(expectedComboSum), "combo details should provide a formatted combo sum")
        assertEquals(details.awardedPoints, expectedBasePoints * expectedComboSum, "combo details should include the awarded total")
        assertTableLength(details.combos, Helpers.getCombinationCount(2), "combo details should include only the best successful combination")
        assertEquals(details.combos[1].label, "Benny Blaanco + Elwynn Forest", "combo details should label the best combination with the prediction values")
        assertEquals(
            details.combos[1].displayMultiplier,
            "x" .. tostring(SCORE_RULES.predictionElementBonusByCount[2] or 0),
            "combo details should format the best combo bonus without repeating the streak"
        )

        local missedDetails = DeathpoolLogic.GetComboDetails(
            Fixtures.prediction({
                levelRange = false,
                source = "benny blaanco",
                zone = "elwynn forest",
            }),
            Fixtures.death({
                sourceName = "Defias Pillager",
                zone = "Westfall",
            }),
            2
        )

        assertEquals(missedDetails.matched, false, "combo details should mark a full miss")
        assertEquals(missedDetails.basePoints, 0, "combo details should not carry prediction points into misses")
        assertEquals(missedDetails.comboSum, 0, "combo details should use x0 for misses")
        assertTableLength(missedDetails.combos, 0, "combo details should not emit successful combination rows for misses")
    end

    local function testMultiplierHelpers()
        local streakCases = {
            { streak = nil, bonus = 0, label = "nil streak should default to no streak bonus" },
            { streak = 0, bonus = 0, label = "zero streak should use no streak bonus" },
            { streak = 1, bonus = 0, label = "the first correct prediction should apply no streak bonus" },
            { streak = 2, bonus = 1 * SCORE_RULES.streakBonusStep, label = "the second correct prediction should apply one streak step" },
            { streak = 3, bonus = 2 * SCORE_RULES.streakBonusStep, label = "the third correct prediction should apply two streak steps" },
            {
                streak = 4,
                bonus = math.min(3 * SCORE_RULES.streakBonusStep, SCORE_RULES.maxStreakBonus),
                label = "the fourth correct prediction should apply three streak steps until the configured cap",
            },
            {
                streak = 5,
                bonus = math.min(4 * SCORE_RULES.streakBonusStep, SCORE_RULES.maxStreakBonus),
                label = "the fifth correct prediction should keep stepping until the cap",
            },
            {
                streak = 9,
                bonus = math.min(8 * SCORE_RULES.streakBonusStep, SCORE_RULES.maxStreakBonus),
                label = "later correct predictions should continue using the configured streak step offset by one",
            },
            {
                streak = SCORE_RULES.maxStreakBonus,
                bonus = math.min(
                    (SCORE_RULES.maxStreakBonus - 1) * SCORE_RULES.streakBonusStep,
                    SCORE_RULES.maxStreakBonus
                ),
                label = "the configured max streak should still respect the first-hit offset",
            },
            { streak = SCORE_RULES.maxStreakBonus + 1, bonus = SCORE_RULES.maxStreakBonus, label = "streaks beyond the configured cap should stay capped" },
        }

        local matchedEvaluation = DeathpoolLogic.EvaluatePrediction(
            Fixtures.prediction({
                source = false,
            }),
            Fixtures.death({
                sourceName = "Benny Blaanco",
            })
        )

        for _, case in ipairs(streakCases) do
            local actual = DeathpoolLogic.GetStreakMultiplierContribution(case.streak, matchedEvaluation)
            assertEquals(actual, case.bonus, case.label)
        end

        local multiplierCases = {
            {
                streak = 1,
                evaluation = DeathpoolLogic.EvaluatePrediction(
                    Fixtures.prediction({
                        source = false,
                        zone = false,
                        levelRange = "10-19",
                    }),
                    Fixtures.death({
                        level = 12,
                    })
                ),
                multiplier = SCORE_RULES.predictionElementBonusByCount[1] or 0,
                label = "a matched level prediction should use the one-field combo bonus on the first hit",
            },
            {
                streak = 1,
                evaluation = DeathpoolLogic.EvaluatePrediction(
                    Fixtures.prediction({
                        zone = false,
                        levelRange = "10-19",
                        source = "hogger",
                    }),
                    Fixtures.death({
                        level = 12,
                        sourceName = "Hogger",
                    })
                ),
                multiplier = SCORE_RULES.predictionElementBonusByCount[2] or 0,
                label = "level plus one matched field should use the two-field combo bonus before any streak bonus",
            },
            {
                streak = 1,
                evaluation = DeathpoolLogic.EvaluatePrediction(
                    Fixtures.prediction(),
                    Fixtures.death()
                ),
                multiplier = SCORE_RULES.predictionElementBonusByCount[3] or 0,
                label = "three matched fields on the first hit should use the three-field combo bonus",
            },
            {
                streak = 2,
                evaluation = { sourceMatched = true, matched = true },
                multiplier = (SCORE_RULES.predictionElementBonusByCount[1] or 0) + SCORE_RULES.streakBonusStep,
                label = "one-field winning predictions on the second hit should include the first streak step",
            },
            {
                streak = 3,
                evaluation = DeathpoolLogic.EvaluatePrediction(
                    Fixtures.prediction(),
                    Fixtures.death()
                ),
                multiplier = (SCORE_RULES.predictionElementBonusByCount[3] or 0)
                    + (2 * SCORE_RULES.streakBonusStep),
                label = "three matched fields on the third hit should combine the combo bonus with the second streak step",
            },
            { streak = 1, evaluation = { matched = false }, multiplier = 0, label = "an unmatched death should now display x0" },
        }

        for _, case in ipairs(multiplierCases) do
            local actual = DeathpoolLogic.GetMultiplierForStreak(case.streak, case.evaluation)
            assertEquals(actual, case.multiplier, case.label)
            assertEquals(
                DeathpoolLogic.FormatMultiplier(actual),
                "x" .. tostring(case.multiplier or case.bonus),
                case.label .. " when formatted"
            )
        end

        local partialEvaluation = DeathpoolLogic.EvaluatePrediction(
            Fixtures.prediction({
                levelRange = "10-19",
                source = "benny blaanco",
                zone = "elwynn forest",
            }),
            Fixtures.death({
                level = 12,
                sourceName = "Benny Blaanco",
                zone = "Elwynn Forest",
            })
        )
        assertEquals(
            DeathpoolLogic.GetComboMultiplierContribution(2, partialEvaluation),
            SCORE_RULES.predictionElementBonusByCount[3] or 0,
            "combo contribution should isolate the best non-streak multiplier portion"
        )
        assertEquals(
            DeathpoolLogic.GetStreakMultiplierContribution(2, partialEvaluation),
            SCORE_RULES.streakBonusStep,
            "streak contribution should apply only one raw streak bonus to the death total"
        )
    end

    local function testPredictionPreviewHelpers()
        assertEquals(
            DeathpoolLogic.GetBaseMultiplierForPrediction(Fixtures.prediction({
                levelRange = false,
                source = false,
                sourceLabel = false,
                zone = false,
                zoneLabel = false,
            })),
            0,
            "base multiplier helper should return x0 when nothing is selected"
        )
        assertEquals(
            DeathpoolLogic.GetBaseMultiplierForPrediction(Fixtures.prediction({
                levelRange = false,
                zone = false,
                zoneLabel = false,
            })),
            Helpers.getDisplayMultiplier(1, SCORE_RULES.previewStreak),
            "base multiplier helper should use the configured one-field preview multiplier"
        )
        assertEquals(
            DeathpoolLogic.GetBaseMultiplierForPrediction(Fixtures.prediction({
                zone = false,
                zoneLabel = false,
            })),
            Helpers.getDisplayMultiplier(2, SCORE_RULES.previewStreak),
            "base multiplier helper should use the preview combo bonus for two selected fields"
        )
        assertEquals(
            DeathpoolLogic.GetBaseMultiplierForPrediction(Fixtures.prediction()),
            Helpers.getDisplayMultiplier(3, SCORE_RULES.previewStreak),
            "base multiplier helper should use the preview combo bonus for three selected fields"
        )
        assertEquals(
            DeathpoolLogic.GetBasePointsForPrediction(Fixtures.prediction({
                levelRange = false,
                source = false,
                sourceLabel = false,
                zone = false,
                zoneLabel = false,
            })),
            0,
            "base points helper should return 0 when nothing is selected"
        )
        assertEquals(
            DeathpoolLogic.GetBasePointsForPrediction(Fixtures.prediction({
                source = false,
                sourceLabel = false,
                zone = false,
                zoneLabel = false,
                levelRange = "50-59",
            })),
            DeathpoolLogic.GetLevelPointsForRange("50-59"),
            "base points helper should preview level-only predictions using the configured range points"
        )
        assertEquals(
            DeathpoolLogic.GetBasePointsForPrediction(Fixtures.prediction({
                levelRange = "20-29",
                zone = false,
                zoneLabel = false,
            })),
            Helpers.getExpectedBasePoints({ levelRange = "20-29", level = 20, source = true }),
            "base points helper should include source points when the preview level prediction also hits"
        )
        assertEquals(
            DeathpoolLogic.GetPreviewAwardedPointsForPrediction(Fixtures.prediction({
                levelRange = false,
                source = false,
                sourceLabel = false,
                zone = false,
                zoneLabel = false,
            })),
            0,
            "preview awarded points helper should return 0 when nothing is selected"
        )
        assertEquals(
            DeathpoolLogic.GetPreviewAwardedPointsForPrediction(Fixtures.prediction({
                source = false,
                sourceLabel = false,
                zone = false,
                zoneLabel = false,
                levelRange = "50-59",
            })),
            DeathpoolLogic.GetLevelPointsForRange("50-59") * Helpers.getDisplayMultiplier(1, SCORE_RULES.previewStreak),
            "preview awarded points helper should use the configured preview range points for level-only predictions"
        )
        assertEquals(
            DeathpoolLogic.GetPreviewAwardedPointsForPrediction(Fixtures.prediction({
                levelRange = "20-29",
                source = "hogger",
                sourceLabel = "Hogger",
                zone = false,
                zoneLabel = false,
            })),
            Helpers.getExpectedBasePoints({ levelRange = "20-29", level = 20, source = true })
                * Helpers.getDisplayMultiplier(2, SCORE_RULES.previewStreak),
            "preview awarded points helper should apply the combo bonus after including fixed points on a matched level prediction"
        )
    end

    local function testPredictionPayoutPreviewRows()
        local function getPayoutRowPoints(prediction)
            return DeathpoolLogic.ScorePreview(
                DeathpoolLogic.GetPredictionElements(prediction) or {},
                0
            ).awardedPoints or 0
        end

        local emptyRows = DeathpoolLogic.GetPredictionPayoutPreviewRows(Fixtures.prediction({
            levelRange = false,
            source = false,
            zone = false,
        }))
        assertTableLength(emptyRows, 0, "payout preview rows should omit impossible rows when nothing is selected")

        local oneFieldRows = DeathpoolLogic.GetPredictionPayoutPreviewRows(Fixtures.prediction({
            source = false,
            zone = false,
            levelRange = "50-59",
        }))
        local oneFieldPrediction = Fixtures.prediction({
            source = false,
            zone = false,
            levelRange = "50-59",
        })
        local oneFieldPoints = getPayoutRowPoints(oneFieldPrediction)
        assertTableLength(oneFieldRows, 1, "payout preview rows should include one row for one selected field")
        assertEquals(oneFieldRows[1].label, "Level", "level-only payout preview should label the single selected field")
        assertEquals(oneFieldRows[1].awardedPoints, oneFieldPoints, "level-only payout preview should use the actual no-streak payout")
        assertEquals(oneFieldRows[1].text, "1 match: Level = " .. tostring(oneFieldPoints) .. " points", "level-only payout preview should format the payout row")

        local twoFieldPrediction = Fixtures.prediction({
            zone = false,
            levelRange = "20-29",
            source = "hogger",
        })
        local twoFieldRows = DeathpoolLogic.GetPredictionPayoutPreviewRows(twoFieldPrediction)
        local twoFieldLevelOnlyPoints = getPayoutRowPoints(Fixtures.prediction({
            zone = false,
            levelRange = "20-29",
            source = false,
        }))
        local twoFieldSourceOnlyPoints = getPayoutRowPoints(Fixtures.prediction({
            levelRange = false,
            source = "hogger",
            zone = false,
        }))
        local twoFieldCombinedPoints = getPayoutRowPoints(twoFieldPrediction)
        assertTableLength(twoFieldRows, 3, "payout preview rows should include singles plus one pair for two selected fields")
        assertEquals(twoFieldRows[1].text, "1 match: Level = " .. tostring(twoFieldLevelOnlyPoints) .. " points", "two-field payout preview should show the level-only win")
        assertEquals(twoFieldRows[2].text, "1 match: Source = " .. tostring(twoFieldSourceOnlyPoints) .. " points", "two-field payout preview should show the source-only win")
        assertEquals(twoFieldRows[3].text, "2 match: Level + Source = " .. tostring(twoFieldCombinedPoints) .. " points", "two-field payout preview should show the combined win")

        local threeFieldPrediction = Fixtures.prediction({
            levelRange = "10-19",
            source = "benny",
            zone = "westfall",
        })
        local threeFieldRows = DeathpoolLogic.GetPredictionPayoutPreviewRows(threeFieldPrediction)
        local threeFieldLevelOnlyPoints = getPayoutRowPoints(Fixtures.prediction({
            levelRange = "10-19",
            source = false,
            zone = false,
        }))
        local threeFieldSourceOnlyPoints = getPayoutRowPoints(Fixtures.prediction({
            levelRange = false,
            source = "benny",
            zone = false,
        }))
        local threeFieldZoneOnlyPoints = getPayoutRowPoints(Fixtures.prediction({
            levelRange = false,
            source = false,
            zone = "westfall",
        }))
        local threeFieldLevelSourcePoints = getPayoutRowPoints(Fixtures.prediction({
            levelRange = "10-19",
            source = "benny",
            zone = false,
        }))
        local threeFieldLevelZonePoints = getPayoutRowPoints(Fixtures.prediction({
            levelRange = "10-19",
            source = false,
            zone = "westfall",
        }))
        local threeFieldSourceZonePoints = getPayoutRowPoints(Fixtures.prediction({
            levelRange = false,
            source = "benny",
            zone = "westfall",
        }))
        local threeFieldCombinedPoints = getPayoutRowPoints(threeFieldPrediction)
        assertTableLength(threeFieldRows, 7, "payout preview rows should include singles, pairs, and the triple for three selected fields")
        assertEquals(
            threeFieldRows[1].text,
            "1 match: Level = " .. tostring(threeFieldLevelOnlyPoints) .. " points",
            "three-field payout preview should show the level-only win"
        )
        assertEquals(
            threeFieldRows[2].text,
            "1 match: Source = " .. tostring(threeFieldSourceOnlyPoints) .. " points",
            "three-field payout preview should show the source-only win"
        )
        assertEquals(
            threeFieldRows[3].text,
            "1 match: Zone = " .. tostring(threeFieldZoneOnlyPoints) .. " points",
            "three-field payout preview should show the zone-only win"
        )
        assertEquals(
            threeFieldRows[4].text,
            "2 match: Level + Source = " .. tostring(threeFieldLevelSourcePoints) .. " points",
            "three-field payout preview should show the level-plus-source win"
        )
        assertEquals(
            threeFieldRows[5].text,
            "2 match: Level + Zone = " .. tostring(threeFieldLevelZonePoints) .. " points",
            "three-field payout preview should show the level-plus-zone win"
        )
        assertEquals(
            threeFieldRows[6].text,
            "2 match: Source + Zone = " .. tostring(threeFieldSourceZonePoints) .. " points",
            "three-field payout preview should list the distinct source-plus-zone win"
        )
        assertEquals(
            threeFieldRows[7].text,
            "3 match: Level + Source + Zone = " .. tostring(threeFieldCombinedPoints) .. " points",
            "three-field payout preview should show the full-match win"
        )
    end

    local function testPointColorQuality()
        local epicCarryoverPoints = SCORE_RULES.pointColorThresholds.rare
            + math.max(
                1,
                tonumber(SCORE_RULES.fixedLevelRangePoints["10-19"]) or 0,
                tonumber(SCORE_RULES.fixedElementPoints.source) or 0,
                tonumber(SCORE_RULES.fixedElementPoints.zone) or 0
            )
        local cases = {
            { points = 0, quality = 0, label = "zero points should map to poor gray quality" },
            { points = 1, quality = 1, label = "one point should map to common white quality" },
            { points = SCORE_RULES.pointColorThresholds.common, quality = 1, label = "the common threshold should stay in white quality" },
            { points = SCORE_RULES.pointColorThresholds.common + 1, quality = 2, label = "just above the common threshold should map to uncommon green quality" },
            { points = SCORE_RULES.pointColorThresholds.uncommon, quality = 2, label = "the uncommon threshold should stay in uncommon green quality" },
            { points = SCORE_RULES.pointColorThresholds.uncommon + 1, quality = 3, label = "just above the uncommon threshold should map to rare blue quality" },
            { points = SCORE_RULES.pointColorThresholds.rare, quality = 3, label = "the rare threshold should stay in rare blue quality" },
            { points = SCORE_RULES.pointColorThresholds.rare + 1, quality = 4, label = "just above the rare threshold should map to epic purple quality" },
            { points = epicCarryoverPoints, quality = 4, label = "large point totals should stay in epic purple quality" },
        }

        if SCORE_RULES.pointColorThresholds.common + 1 < SCORE_RULES.pointColorThresholds.uncommon then
            cases[#cases + 1] = {
                points = SCORE_RULES.pointColorThresholds.uncommon - 1,
                quality = 2,
                label = "points inside the uncommon band should stay in uncommon green quality",
            }
        end

        for _, case in ipairs(cases) do
            assertEquals(DeathpoolLogic.GetPointColorQuality(case.points), case.quality, case.label)
        end
    end

    testPredictionEvaluation()
    testSameZoneBonusPoints()
    testComboDetails()
    testMultiplierHelpers()
    testPredictionPreviewHelpers()
    testPredictionPayoutPreviewRows()
    testPointColorQuality()
end

return function(context)
    local DeathpoolStats = context.DeathpoolStats
    local DeathpoolDatabase = context.DeathpoolDatabase
    local Fixtures = context.Fixtures
    local suite = context.suite

    ---@param deaths DeathpoolDeath[]
    ---@return DeathpoolCharacterState
    local function createDatabaseWithHistory(deaths)
        return DeathpoolDatabase.Init({
            deathHistory = deaths,
        })
    end

    ---@param timestamp integer
    ---@param sourceName string|nil|false
    ---@param zone string|nil|false
    ---@param level integer|nil|false
    ---@return DeathpoolDeath
    local function death(timestamp, sourceName, zone, level)
        return Fixtures.storedDeath({
            timestamp = timestamp,
            sourceName = sourceName,
            zone = zone,
            level = level,
        })
    end

    local function testStatsApiReturnsNilForEmptyHistory()
        local database = DeathpoolDatabase.Init({})
        local summary = DeathpoolStats.GetDeathSummary(database)

        suite:assertEquals(DeathpoolStats.GetDeadliestSource(database), nil, "empty history should have no deadliest source")
        suite:assertEquals(
            DeathpoolStats.GetDeadliestLevelBracket(database),
            nil,
            "empty history should have no deadliest level bracket"
        )
        suite:assertEquals(DeathpoolStats.GetDeadliestLocation(database), nil, "empty history should have no deadliest location")
        suite:assertTableLength(DeathpoolStats.GetTopSources(database), 0, "empty history should return no top sources")
        suite:assertEquals(summary.sampleSize, 0, "empty summary should report zero samples")
        suite:assertEquals(summary.deadliestSource, nil, "empty summary should have no deadliest source")
    end

    local function testBaseStatsUseRetainedDeathHistory()
        local database = createDatabaseWithHistory({
            death(100, "Hogger", "Elwynn Forest", 12),
            death(200, "Murloc Forager", "Elwynn Forest", 22),
            death(300, "Hogger", "Westfall", 18),
            death(400, "Murloc Forager", "Elwynn Forest", 27),
        })

        suite:assertEquals(
            DeathpoolStats.GetDeadliestSource(database),
            "Murloc Forager",
            "deadliest source should use count, then latest death as a tie-breaker"
        )
        suite:assertEquals(
            DeathpoolStats.GetDeadliestLevelBracket(database),
            "20-29",
            "deadliest level bracket should use the configured prediction ranges"
        )
        suite:assertEquals(
            DeathpoolStats.GetDeadliestLocation(database),
            "Elwynn Forest",
            "deadliest location should return the most common retained zone"
        )
    end

    local function testTopStatsIncludeCountsPercentsAndLimits()
        local database = createDatabaseWithHistory({
            death(100, "Hogger", "Elwynn Forest", 12),
            death(200, "Murloc Forager", "Elwynn Forest", 22),
            death(300, "Hogger", "Westfall", 18),
            death(400, "Murloc Forager", "Elwynn Forest", 27),
            death(500, "Defias Pillager", "Westfall", 31),
        })
        local sources = DeathpoolStats.GetTopSources(database, 2)
        local brackets = DeathpoolStats.GetTopLevelBrackets(database)

        suite:assertTableLength(sources, 2, "top source limit should cap returned rows")
        suite:assertEquals(sources[1].label, "Murloc Forager", "top source should honor latest tie-breaks")
        suite:assertEquals(sources[1].count, 2, "top source should include its count")
        suite:assertEquals(sources[1].percent, 40, "top source should include its share of counted deaths")
        suite:assertEquals(sources[1].latestTimestamp, 400, "top source should expose latest timestamp")
        suite:assertEquals(brackets[1].label, "20-29", "top brackets should be ranked")
        suite:assertEquals(brackets[1].count, 2, "top bracket should include its count")
    end

    local function testStatsIgnoreMissingValues()
        local database = createDatabaseWithHistory({
            death(100, "Hogger", "Elwynn Forest", 12),
            death(200, false, "Westfall", 18),
            death(300, false, false, 22),
            death(400, "Murloc Forager", "Darkshore", 7),
        })
        local sources = DeathpoolStats.GetTopSources(database)
        local locations = DeathpoolStats.GetTopLocations(database)
        local brackets = DeathpoolStats.GetTopLevelBrackets(database)

        suite:assertTableLength(sources, 2, "source stats should ignore missing sources")
        suite:assertTableLength(locations, 3, "location stats should ignore only missing locations")
        suite:assertTableLength(brackets, 2, "level bracket stats should ignore levels outside configured brackets")
    end

    local function testSourceLocationPairsRequireBothValues()
        local database = createDatabaseWithHistory({
            death(100, "Hogger", "Elwynn Forest", 12),
            death(200, "Hogger", "Elwynn Forest", 18),
            death(300, "Hogger", false, 18),
            death(400, false, "Elwynn Forest", 18),
            death(500, "Murloc Forager", "Darkshore", 22),
        })
        local pairs = DeathpoolStats.GetTopSourceLocationPairs(database)

        suite:assertTableLength(pairs, 2, "source-location pairs should require both source and location")
        suite:assertEquals(pairs[1].label, "Hogger in Elwynn Forest", "top pair should combine source and location")
        suite:assertEquals(pairs[1].source, "Hogger", "top pair should expose the source")
        suite:assertEquals(pairs[1].location, "Elwynn Forest", "top pair should expose the location")
        suite:assertEquals(pairs[1].count, 2, "top pair should count matching source-location deaths")
    end

    local function testRecentTrendsCompareRecentWindowToOlderHistory()
        local database = createDatabaseWithHistory({
            death(100, "Hogger", "Elwynn Forest", 12),
            death(200, "Hogger", "Elwynn Forest", 14),
            death(300, "Hogger", "Elwynn Forest", 18),
            death(400, "Hogger", "Elwynn Forest", 18),
            death(500, "Murloc Forager", "Darkshore", 22),
            death(600, "Murloc Forager", "Darkshore", 24),
            death(700, "Murloc Forager", "Darkshore", 27),
            death(800, "Hogger", "Elwynn Forest", 32),
        })
        local sourceTrends = DeathpoolStats.GetRecentSourceTrends(database, 4)
        local locationTrends = DeathpoolStats.GetRecentLocationTrends(database, 4)
        local bracketTrends = DeathpoolStats.GetRecentLevelBracketTrends(database, 4)

        suite:assertEquals(sourceTrends[1].label, "Murloc Forager", "new recent source should lead recent trends")
        suite:assertEquals(sourceTrends[1].trend, "new", "source absent from older history should be marked new")
        suite:assertEquals(sourceTrends[1].recentCount, 3, "source trend should include recent count")
        suite:assertEquals(sourceTrends[1].historicalCount, 0, "source trend should include historical count")
        suite:assertEquals(sourceTrends[1].deltaPercent, 75, "source trend should include recent minus historical share")
        suite:assertEquals(sourceTrends[2].label, "Hogger", "older dominant source can still appear as cooling")
        suite:assertEquals(sourceTrends[2].trend, "cooling", "source with lower recent share should be marked cooling")
        suite:assertEquals(locationTrends[1].label, "Darkshore", "recent location trends should use zones")
        suite:assertEquals(bracketTrends[1].label, "20-29", "recent bracket trends should use level brackets")
        suite:assertEquals(bracketTrends[1].trend, "new", "new recent bracket should be marked new")
    end

    local function testRecentRepeatsAndClustersUseRecentWindow()
        local database = createDatabaseWithHistory({
            death(100, "Hogger", "Elwynn Forest", 12),
            death(200, "Defias Pillager", "Westfall", 18),
            death(300, "Murloc Forager", "Darkshore", 22),
            death(400, "Murloc Forager", "Darkshore", 24),
            death(500, "Murloc Raider", "Darkshore", 27),
        })
        local repeatSource = DeathpoolStats.GetRecentRepeatSource(database, 3)
        local repeatLocation = DeathpoolStats.GetRecentRepeatLocation(database, 3)
        local repeatBracket = DeathpoolStats.GetRecentRepeatLevelBracket(database, 3)
        local cluster = DeathpoolStats.GetRecentCluster(database, 3)

        suite:assertEquals(repeatSource.label, "Murloc Forager", "recent repeat source should find repeated recent source")
        suite:assertEquals(repeatSource.count, 2, "recent repeat source should require more than one hit")
        suite:assertEquals(repeatLocation.label, "Darkshore", "recent repeat location should find repeated recent location")
        suite:assertEquals(repeatLocation.count, 3, "recent repeat location should count the recent window")
        suite:assertEquals(repeatBracket.label, "20-29", "recent repeat bracket should find repeated recent bracket")
        suite:assertEquals(cluster.kind, "location", "recent cluster should return the strongest repeated pattern")
        suite:assertEquals(cluster.label, "Darkshore", "recent cluster should expose the clustered label")
    end

    local function testDeathSummaryCombinesStats()
        local database = createDatabaseWithHistory({
            death(100, "Hogger", "Elwynn Forest", 12),
            death(200, "Hogger", "Elwynn Forest", 18),
            death(300, "Murloc Forager", "Darkshore", 22),
            death(400, "Murloc Forager", "Darkshore", 24),
            death(500, "Murloc Raider", "Darkshore", 27),
        })
        local summary = DeathpoolStats.GetDeathSummary(database, {
            topLimit = 2,
            trendLimit = 1,
            recentWindowSize = 3,
        })

        suite:assertEquals(summary.sampleSize, 5, "summary should include retained history sample size")
        suite:assertEquals(summary.recentSampleSize, 3, "summary should include recent sample size")
        suite:assertEquals(summary.deadliestLocation.label, "Darkshore", "summary should include deadliest location entry")
        suite:assertTableLength(summary.topSources, 2, "summary should apply the top stat limit")
        suite:assertTableLength(summary.sourceTrends, 1, "summary should apply the trend limit")
        suite:assertEquals(summary.recentRepeat.kind, "location", "summary should include strongest recent repeat pattern")
    end

    local function testDeathSummaryKeepsMostNotableTrendOutsideTrendLimit()
        local database = createDatabaseWithHistory({
            death(100, "Source A", "Elwynn Forest", 22),
            death(200, "Source A", "Elwynn Forest", 22),
            death(300, "Source A", "Elwynn Forest", 22),
            death(400, "Source A", "Elwynn Forest", 22),
            death(500, "Source A", "Elwynn Forest", 22),
            death(600, "Source A", "Elwynn Forest", 22),
            death(700, "Source A", "Elwynn Forest", 22),
            death(800, "Source A", "Elwynn Forest", 22),
            death(900, "Source A", "Elwynn Forest", 22),
            death(1000, "Source B", "Elwynn Forest", 22),
            death(1100, "Source A", "Elwynn Forest", 22),
            death(1200, "Source B", "Elwynn Forest", 22),
            death(1300, "Source B", "Elwynn Forest", 22),
            death(1400, "Source C", "Elwynn Forest", 22),
            death(1500, "Source C", "Elwynn Forest", 22),
        })
        local summary = DeathpoolStats.GetDeathSummary(database, {
            trendLimit = 1,
            recentWindowSize = 5,
        })

        suite:assertEquals(summary.sourceTrends[1].label, "Source C", "limited source trends should still keep top positive movement")
        suite:assertEquals(summary.sourceTrends[1].trend, "new", "limited source trends should preserve existing ranking behavior")
        suite:assertEquals(summary.recentTrend.label, "Source A", "summary should keep the largest movement for the compact trend line")
        suite:assertEquals(summary.recentTrend.trend, "cooling", "summary should allow a cooling trend to surface")
    end

    testStatsApiReturnsNilForEmptyHistory()
    testBaseStatsUseRetainedDeathHistory()
    testTopStatsIncludeCountsPercentsAndLimits()
    testStatsIgnoreMissingValues()
    testSourceLocationPairsRequireBothValues()
    testRecentTrendsCompareRecentWindowToOlderHistory()
    testRecentRepeatsAndClustersUseRecentWindow()
    testDeathSummaryCombinesStats()
    testDeathSummaryKeepsMostNotableTrendOutsideTrendLimit()
end

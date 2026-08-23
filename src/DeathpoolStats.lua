local _, ns = ...
---@cast ns DeathpoolNamespace

local DeathpoolDatabase = ns.DeathpoolDatabase
local DeathpoolLogic = ns.DeathpoolLogic

---@class DeathpoolStats
local DeathpoolStats = ns.DeathpoolStats or {}
ns.DeathpoolStats = DeathpoolStats

---@class DeathpoolStatEntry
---@field key string
---@field label string
---@field count integer
---@field percent number
---@field latestTimestamp integer
---@field source string|nil
---@field location string|nil

---@alias DeathpoolTrendKind "steady"|"new"|"hot"|"cooling"
---@alias DeathpoolRecentClusterKind "source"|"location"|"levelBracket"

---@class DeathpoolTrendEntry: DeathpoolStatEntry
---@field recentCount integer
---@field recentPercent number
---@field historicalCount integer
---@field historicalPercent number
---@field deltaPercent number
---@field trend DeathpoolTrendKind

---@class DeathpoolRecentCluster
---@field kind DeathpoolRecentClusterKind
---@field key string
---@field label string
---@field count integer
---@field percent number
---@field latestTimestamp integer

---@class DeathpoolSummaryOptions
---@field topLimit integer|nil
---@field trendLimit integer|nil
---@field recentWindowSize integer|nil

---@class DeathpoolDeathSummary
---@field sampleSize integer
---@field recentSampleSize integer
---@field deadliestSource DeathpoolStatEntry|nil
---@field deadliestLocation DeathpoolStatEntry|nil
---@field deadliestLevelBracket DeathpoolStatEntry|nil
---@field topSources DeathpoolStatEntry[]
---@field topLocations DeathpoolStatEntry[]
---@field topLevelBrackets DeathpoolStatEntry[]
---@field topSourceLocationPairs DeathpoolStatEntry[]
---@field sourceTrends DeathpoolTrendEntry[]
---@field locationTrends DeathpoolTrendEntry[]
---@field levelBracketTrends DeathpoolTrendEntry[]
---@field recentTrend DeathpoolTrendEntry|nil
---@field recentRepeat DeathpoolRecentCluster|nil

---@param value number
---@return number
local function RoundPercent(value)
    return math.floor((value * 10) + 0.5) / 10
end

---@param deaths DeathpoolDeath[]
---@param startIndex integer
---@param endIndex integer
---@return DeathpoolDeath[]
local function CopyDeathRange(deaths, startIndex, endIndex)
    local selectedDeaths = {}

    if startIndex < 1 then
        startIndex = 1
    end

    if endIndex > #deaths then
        endIndex = #deaths
    end

    for index = startIndex, endIndex do
        selectedDeaths[#selectedDeaths + 1] = deaths[index]
    end

    return selectedDeaths
end

---@param deaths DeathpoolDeath[]
---@param windowSize integer
---@return DeathpoolDeath[]
local function GetRecentDeathWindow(deaths, windowSize)
    if windowSize <= 0 then
        return {}
    end

    return CopyDeathRange(deaths, #deaths - windowSize + 1, #deaths)
end

---@param deaths DeathpoolDeath[]
---@param windowSize integer
---@return DeathpoolDeath[]
local function GetHistoricalComparisonWindow(deaths, windowSize)
    if windowSize <= 0 or #deaths <= windowSize then
        return {}
    end

    return CopyDeathRange(deaths, 1, #deaths - windowSize)
end

---@class DeathpoolDeathWindows
---@field all DeathpoolDeath[]
---@field recent DeathpoolDeath[]
---@field historical DeathpoolDeath[]

---@param deaths DeathpoolDeath[]
---@param windowSize integer
---@return DeathpoolDeathWindows
local function GetDeathWindows(deaths, windowSize)
    return {
        all = deaths,
        recent = GetRecentDeathWindow(deaths, windowSize),
        historical = GetHistoricalComparisonWindow(deaths, windowSize),
    }
end

---@param counts table<string, DeathpoolStatEntry>
---@param key string
---@param label string
---@param timestamp integer
---@return DeathpoolStatEntry
local function AddCount(counts, key, label, timestamp)
    local entry = counts[key]
    if not entry then
        entry = {
            key = key,
            label = label,
            count = 0,
            percent = 0,
            latestTimestamp = 0,
        }
        counts[key] = entry
    end

    entry.count = entry.count + 1
    if timestamp > entry.latestTimestamp then
        entry.latestTimestamp = timestamp
    end

    return entry
end

---@param entry DeathpoolStatEntry
---@param other DeathpoolStatEntry
---@return boolean
local function IsRankedBefore(entry, other)
    if entry.count ~= other.count then
        return entry.count > other.count
    end

    if entry.latestTimestamp ~= other.latestTimestamp then
        return entry.latestTimestamp > other.latestTimestamp
    end

    return entry.key < other.key
end

---@param entries DeathpoolStatEntry[]
---@param limit integer
---@return DeathpoolStatEntry[]
local function ApplyLimit(entries, limit)
    local limitedEntries = {}

    if limit <= 0 then
        return limitedEntries
    end

    for index = 1, math.min(limit, #entries) do
        limitedEntries[#limitedEntries + 1] = entries[index]
    end

    return limitedEntries
end

---@param counts table<string, DeathpoolStatEntry>
---@param countedDeaths integer
---@param limit integer
---@return DeathpoolStatEntry[]
local function RankCounts(counts, countedDeaths, limit)
    local entries = {}

    for _, entry in pairs(counts) do
        entry.percent = countedDeaths > 0 and RoundPercent((entry.count / countedDeaths) * 100) or 0
        entries[#entries + 1] = entry
    end

    table.sort(entries, IsRankedBefore)

    return ApplyLimit(entries, limit)
end

---@param deaths DeathpoolDeath[]
---@param selector fun(death: DeathpoolDeath): string|nil
---@param limit integer
---@return DeathpoolStatEntry[]
local function GetTopValuesFromDeaths(deaths, selector, limit)
    local counts = {}
    local countedDeaths = 0

    for _, death in ipairs(deaths) do
        local label = selector(death)
        if label then
            countedDeaths = countedDeaths + 1
            AddCount(counts, string.lower(label), label, death.timestamp)
        end
    end

    return RankCounts(counts, countedDeaths, limit)
end

---@param deaths DeathpoolDeath[]
---@param limit integer
---@return DeathpoolStatEntry[]
local function GetTopSourceLocationPairsFromDeaths(deaths, limit)
    local counts = {}
    local countedDeaths = 0

    for _, death in ipairs(deaths) do
        local source = death.sourceName
        local location = death.zone

        if source and location then
            local key = string.lower(source) .. "\001" .. string.lower(location)
            local entry = AddCount(counts, key, source .. " in " .. location, death.timestamp)
            entry.source = source
            entry.location = location
            countedDeaths = countedDeaths + 1
        end
    end

    return RankCounts(counts, countedDeaths, limit)
end

---@param trend DeathpoolTrendEntry
---@param other DeathpoolTrendEntry
---@return boolean
local function IsTrendRankedBefore(trend, other)
    if trend.deltaPercent ~= other.deltaPercent then
        return trend.deltaPercent > other.deltaPercent
    end

    return IsRankedBefore(trend, other)
end

---@param recentEntries DeathpoolStatEntry[]
---@param historicalEntries DeathpoolStatEntry[]
---@param limit integer
---@return DeathpoolTrendEntry[]
local function BuildTrendEntries(recentEntries, historicalEntries, limit)
    local historicalByKey = {}
    local trendEntries = {}

    for _, entry in ipairs(historicalEntries) do
        historicalByKey[entry.key] = entry
    end

    for _, recentEntry in ipairs(recentEntries) do
        local historicalEntry = historicalByKey[recentEntry.key]
        local historicalCount = historicalEntry and historicalEntry.count or 0
        local historicalPercent = historicalEntry and historicalEntry.percent or 0
        local deltaPercent = RoundPercent(recentEntry.percent - historicalPercent)
        ---@type DeathpoolTrendKind
        local trend = "steady"

        if historicalCount == 0 then
            trend = "new"
        elseif deltaPercent >= 15 or recentEntry.percent >= historicalPercent * 1.5 then
            trend = "hot"
        elseif deltaPercent <= -15 or recentEntry.percent <= historicalPercent * 0.5 then
            trend = "cooling"
        end

        trendEntries[#trendEntries + 1] = {
            key = recentEntry.key,
            label = recentEntry.label,
            count = recentEntry.count,
            percent = recentEntry.percent,
            latestTimestamp = recentEntry.latestTimestamp,
            recentCount = recentEntry.count,
            recentPercent = recentEntry.percent,
            historicalCount = historicalCount,
            historicalPercent = historicalPercent,
            deltaPercent = deltaPercent,
            trend = trend,
            source = recentEntry.source,
            location = recentEntry.location,
        }
    end

    table.sort(trendEntries, IsTrendRankedBefore)

    return ApplyLimit(trendEntries, limit)
end

---@param windows DeathpoolDeathWindows
---@param limit integer
---@param selector fun(death: DeathpoolDeath): string|nil
---@return DeathpoolTrendEntry[]
local function GetRecentTrendsFromWindows(windows, limit, selector)
    local recentEntries = GetTopValuesFromDeaths(windows.recent, selector, #windows.recent)
    local historicalEntries = GetTopValuesFromDeaths(windows.historical, selector, #windows.historical)

    return BuildTrendEntries(recentEntries, historicalEntries, limit)
end

---@param recentDeaths DeathpoolDeath[]
---@param selector fun(death: DeathpoolDeath): string|nil
---@return DeathpoolStatEntry|nil
local function GetRecentRepeatFromWindow(recentDeaths, selector)
    local entries = GetTopValuesFromDeaths(recentDeaths, selector, 1)
    local entry = entries[1]

    if entry and entry.count > 1 then
        return entry
    end

    return nil
end

---@param trend DeathpoolTrendEntry
---@return number
local function GetTrendMagnitude(trend)
    return math.abs(trend.deltaPercent)
end

---@param trend DeathpoolTrendEntry
---@param other DeathpoolTrendEntry
---@return boolean
local function IsTrendMoreNotable(trend, other)
    if GetTrendMagnitude(trend) ~= GetTrendMagnitude(other) then
        return GetTrendMagnitude(trend) > GetTrendMagnitude(other)
    end

    return IsTrendRankedBefore(trend, other)
end

---@param trendGroups DeathpoolTrendEntry[][]
---@return DeathpoolTrendEntry|nil
local function GetMostNotableTrend(trendGroups)
    local notableTrend = nil

    for _, trends in ipairs(trendGroups) do
        for _, trend in ipairs(trends) do
            if not notableTrend or IsTrendMoreNotable(trend, notableTrend) then
                notableTrend = trend
            end
        end
    end

    return notableTrend
end

---@param kind DeathpoolRecentClusterKind
---@param entry DeathpoolStatEntry|nil
---@return DeathpoolRecentCluster|nil
local function CreateCluster(kind, entry)
    if not entry or entry.count <= 1 then
        return nil
    end

    return {
        kind = kind,
        key = entry.key,
        label = entry.label,
        count = entry.count,
        percent = entry.percent,
        latestTimestamp = entry.latestTimestamp,
    }
end

---@param cluster DeathpoolRecentCluster
---@return integer
local function GetClusterKindPriority(cluster)
    if cluster.kind == "location" then
        return 1
    end

    if cluster.kind == "source" then
        return 2
    end

    return 3
end

---@param cluster DeathpoolRecentCluster
---@param other DeathpoolRecentCluster
---@return boolean
local function IsClusterRankedBefore(cluster, other)
    if cluster.count ~= other.count then
        return cluster.count > other.count
    end

    if cluster.percent ~= other.percent then
        return cluster.percent > other.percent
    end

    if cluster.latestTimestamp ~= other.latestTimestamp then
        return cluster.latestTimestamp > other.latestTimestamp
    end

    return GetClusterKindPriority(cluster) < GetClusterKindPriority(other)
end

---@param sourceEntry DeathpoolStatEntry|nil
---@param locationEntry DeathpoolStatEntry|nil
---@param levelEntry DeathpoolStatEntry|nil
---@return DeathpoolRecentCluster|nil
local function GetMostNotableCluster(sourceEntry, locationEntry, levelEntry)
    local clusters = {}
    local sourceCluster = CreateCluster("source", sourceEntry)
    local locationCluster = CreateCluster("location", locationEntry)
    local levelCluster = CreateCluster("levelBracket", levelEntry)

    if sourceCluster then
        clusters[#clusters + 1] = sourceCluster
    end
    if locationCluster then
        clusters[#clusters + 1] = locationCluster
    end
    if levelCluster then
        clusters[#clusters + 1] = levelCluster
    end

    table.sort(clusters, IsClusterRankedBefore)

    return clusters[1]
end

---@param database DeathpoolCharacterState
---@return string|nil
function DeathpoolStats.GetDeadliestSource(database)
    local entries = DeathpoolStats.GetTopSources(database, 1)
    return entries[1] and entries[1].label or nil
end

---@param database DeathpoolCharacterState
---@return string|nil
function DeathpoolStats.GetDeadliestLevelBracket(database)
    local entries = DeathpoolStats.GetTopLevelBrackets(database, 1)
    return entries[1] and entries[1].label or nil
end

---@param database DeathpoolCharacterState
---@return string|nil
function DeathpoolStats.GetDeadliestLocation(database)
    local entries = DeathpoolStats.GetTopLocations(database, 1)
    return entries[1] and entries[1].label or nil
end

---@param database DeathpoolCharacterState
---@param limit integer|nil
---@return DeathpoolStatEntry[]
function DeathpoolStats.GetTopSources(database, limit)
    local deaths = DeathpoolDatabase.GetDeathHistory(database)
    return GetTopValuesFromDeaths(deaths, function(death)
        return death.sourceName
    end, limit or #deaths)
end

---@param database DeathpoolCharacterState
---@param limit integer|nil
---@return DeathpoolStatEntry[]
function DeathpoolStats.GetTopLocations(database, limit)
    local deaths = DeathpoolDatabase.GetDeathHistory(database)
    return GetTopValuesFromDeaths(deaths, function(death)
        return death.zone
    end, limit or #deaths)
end

---@param database DeathpoolCharacterState
---@param limit integer|nil
---@return DeathpoolStatEntry[]
function DeathpoolStats.GetTopLevelBrackets(database, limit)
    local deaths = DeathpoolDatabase.GetDeathHistory(database)
    return GetTopValuesFromDeaths(deaths, function(death)
        return DeathpoolLogic.GetLevelRangeForLevel(death.level)
    end, limit or #deaths)
end

---@param database DeathpoolCharacterState
---@param limit integer|nil
---@return DeathpoolStatEntry[]
function DeathpoolStats.GetTopSourceLocationPairs(database, limit)
    local deaths = DeathpoolDatabase.GetDeathHistory(database)
    return GetTopSourceLocationPairsFromDeaths(deaths, limit or #deaths)
end

---@param database DeathpoolCharacterState
---@param windowSize integer|nil
---@param limit integer|nil
---@return DeathpoolTrendEntry[]
function DeathpoolStats.GetRecentSourceTrends(database, windowSize, limit)
    local deaths = DeathpoolDatabase.GetDeathHistory(database)
    return GetRecentTrendsFromWindows(
        GetDeathWindows(deaths, windowSize or 10),
        limit or #deaths,
        function(death)
            return death.sourceName
        end
    )
end

---@param database DeathpoolCharacterState
---@param windowSize integer|nil
---@param limit integer|nil
---@return DeathpoolTrendEntry[]
function DeathpoolStats.GetRecentLocationTrends(database, windowSize, limit)
    local deaths = DeathpoolDatabase.GetDeathHistory(database)
    return GetRecentTrendsFromWindows(
        GetDeathWindows(deaths, windowSize or 10),
        limit or #deaths,
        function(death)
            return death.zone
        end
    )
end

---@param database DeathpoolCharacterState
---@param windowSize integer|nil
---@param limit integer|nil
---@return DeathpoolTrendEntry[]
function DeathpoolStats.GetRecentLevelBracketTrends(database, windowSize, limit)
    local deaths = DeathpoolDatabase.GetDeathHistory(database)
    return GetRecentTrendsFromWindows(
        GetDeathWindows(deaths, windowSize or 10),
        limit or #deaths,
        function(death)
            return DeathpoolLogic.GetLevelRangeForLevel(death.level)
        end
    )
end

---@param database DeathpoolCharacterState
---@param windowSize integer|nil
---@return DeathpoolStatEntry|nil
function DeathpoolStats.GetRecentRepeatSource(database, windowSize)
    local deaths = DeathpoolDatabase.GetDeathHistory(database)
    local windows = GetDeathWindows(deaths, windowSize or 5)
    return GetRecentRepeatFromWindow(
        windows.recent,
        function(death)
            return death.sourceName
        end
    )
end

---@param database DeathpoolCharacterState
---@param windowSize integer|nil
---@return DeathpoolStatEntry|nil
function DeathpoolStats.GetRecentRepeatLocation(database, windowSize)
    local deaths = DeathpoolDatabase.GetDeathHistory(database)
    local windows = GetDeathWindows(deaths, windowSize or 5)
    return GetRecentRepeatFromWindow(
        windows.recent,
        function(death)
            return death.zone
        end
    )
end

---@param database DeathpoolCharacterState
---@param windowSize integer|nil
---@return DeathpoolStatEntry|nil
function DeathpoolStats.GetRecentRepeatLevelBracket(database, windowSize)
    local deaths = DeathpoolDatabase.GetDeathHistory(database)
    local windows = GetDeathWindows(deaths, windowSize or 5)
    return GetRecentRepeatFromWindow(
        windows.recent,
        function(death)
            return DeathpoolLogic.GetLevelRangeForLevel(death.level)
        end
    )
end

---@param database DeathpoolCharacterState
---@param windowSize integer|nil
---@return DeathpoolRecentCluster|nil
function DeathpoolStats.GetRecentCluster(database, windowSize)
    local deaths = DeathpoolDatabase.GetDeathHistory(database)
    local windows = GetDeathWindows(deaths, windowSize or 5)
    local sourceRepeat = GetRecentRepeatFromWindow(windows.recent, function(death)
        return death.sourceName
    end)
    local locationRepeat = GetRecentRepeatFromWindow(windows.recent, function(death)
        return death.zone
    end)
    local levelRepeat = GetRecentRepeatFromWindow(windows.recent, function(death)
        return DeathpoolLogic.GetLevelRangeForLevel(death.level)
    end)

    return GetMostNotableCluster(sourceRepeat, locationRepeat, levelRepeat)
end

---@param database DeathpoolCharacterState
---@param options DeathpoolSummaryOptions|nil
---@return DeathpoolDeathSummary
function DeathpoolStats.GetDeathSummary(database, options)
    options = options or {}

    local topLimit = options.topLimit or 3
    local trendLimit = options.trendLimit or 3
    local recentWindowSize = options.recentWindowSize or 10
    local deaths = DeathpoolDatabase.GetDeathHistory(database)
    local windows = GetDeathWindows(deaths, recentWindowSize)
    local topSources = GetTopValuesFromDeaths(deaths, function(death)
        return death.sourceName
    end, topLimit)
    local topLocations = GetTopValuesFromDeaths(deaths, function(death)
        return death.zone
    end, topLimit)
    local topLevelBrackets = GetTopValuesFromDeaths(deaths, function(death)
        return DeathpoolLogic.GetLevelRangeForLevel(death.level)
    end, topLimit)
    local sourceTrends = GetRecentTrendsFromWindows(windows, #windows.recent, function(death)
        return death.sourceName
    end)
    local locationTrends = GetRecentTrendsFromWindows(windows, #windows.recent, function(death)
        return death.zone
    end)
    local levelBracketTrends = GetRecentTrendsFromWindows(windows, #windows.recent, function(death)
        return DeathpoolLogic.GetLevelRangeForLevel(death.level)
    end)
    local sourceRepeat = GetRecentRepeatFromWindow(windows.recent, function(death)
        return death.sourceName
    end)
    local locationRepeat = GetRecentRepeatFromWindow(windows.recent, function(death)
        return death.zone
    end)
    local levelRepeat = GetRecentRepeatFromWindow(windows.recent, function(death)
        return DeathpoolLogic.GetLevelRangeForLevel(death.level)
    end)

    return {
        sampleSize = #deaths,
        recentSampleSize = #windows.recent,
        deadliestSource = topSources[1],
        deadliestLocation = topLocations[1],
        deadliestLevelBracket = topLevelBrackets[1],
        topSources = topSources,
        topLocations = topLocations,
        topLevelBrackets = topLevelBrackets,
        topSourceLocationPairs = GetTopSourceLocationPairsFromDeaths(deaths, topLimit),
        sourceTrends = ApplyLimit(sourceTrends, trendLimit),
        locationTrends = ApplyLimit(locationTrends, trendLimit),
        levelBracketTrends = ApplyLimit(levelBracketTrends, trendLimit),
        recentTrend = GetMostNotableTrend({ sourceTrends, locationTrends, levelBracketTrends }),
        recentRepeat = GetMostNotableCluster(sourceRepeat, locationRepeat, levelRepeat),
    }
end

return DeathpoolStats

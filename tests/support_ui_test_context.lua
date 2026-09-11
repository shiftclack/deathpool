local LogicContext = require("tests.support_logic_context")
local UIHarness = require("tests.support_ui_harness")
local FixtureFactory = require("tests.support_fixtures")

---@return table
local function Create()
    local loadedLogic = LogicContext.Create({ zoneText = "Test UI Zone" })
    local DeathpoolLogic = loadedLogic.DeathpoolLogic
    local Fixtures = FixtureFactory.Create(loadedLogic.DeathpoolConstants, loadedLogic.DeathpoolDatabase)
    local SCORE_RULES = loadedLogic.DeathpoolConstants.SCORING

    ---@return string
    local function buildLevelPointsSummary()
        local visibleRanges = {}

        for index = 1, #SCORE_RULES.levelRanges - 1 do
            visibleRanges[#visibleRanges + 1] = tostring(SCORE_RULES.levelRanges[index])
        end

        return "Level ranges can be locked as "
            .. table.concat(visibleRanges, ", ")
            .. ", and "
            .. tostring(SCORE_RULES.levelRanges[#SCORE_RULES.levelRanges])
            .. "."
    end

    ---@param prediction DeathpoolPrediction
    ---@return string
    local function formatPredictionPreview(prediction)
        local elements = DeathpoolLogic.GetPredictionElements(prediction) or {}
        local score = DeathpoolLogic.ScorePreview(
            elements,
            DeathpoolLogic.GetPreviewStreak()
        )

        return string.format(
            "%d base / %d combos = %d total",
            score.basePoints,
            score.combinationCount,
            score.awardedPoints
        )
    end

    ---@param death DeathpoolDeath
    ---@return table<string, string>
    local function formatStoredDeathScore(death)
        local basePoints = DeathpoolLogic.GetStoredDeathBasePoints(death)
        local sameZoneBonusPoints = DeathpoolLogic.GetStoredDeathSameZoneBonusPoints(death)
        local comboMultiplier = DeathpoolLogic.GetStoredDeathComboMultiplierValue(death)
        local streakMultiplier = DeathpoolLogic.GetStoredDeathStreakMultiplierValue(death)
        local comboSum = DeathpoolLogic.GetStoredDeathMultiplierValue(death)
        local awardedPoints = DeathpoolLogic.GetStoredDeathAwardedPoints(death)
        return {
            basePoints = tostring(basePoints),
            comboMultiplier = "x" .. tostring(comboMultiplier),
            streakMultiplier = "x" .. tostring(streakMultiplier),
            comboSum = "x" .. tostring(comboSum),
            sameZoneBonusPoints = tostring(sameZoneBonusPoints),
            awardedPoints = tostring(awardedPoints),
            formula = string.format("%d x%d = %d", basePoints + sameZoneBonusPoints, comboSum, awardedPoints),
        }
    end

    ---@param state table|nil
    ---@param options table|nil
    ---@return table
    local function createUIContext(state, options)
        -- Each UI test gets a fresh harness so frame state, globals, and printed messages cannot bleed across cases.
        local ui = UIHarness.Create({
            state = state,
            faction = options and options.faction or nil,
            hardcoreDeathChatType = options and options.hardcoreDeathChatType or nil,
            hardcoreDeathsJoined = options and options.hardcoreDeathsJoined,
            formatLargeNumber = options and options.formatLargeNumber or nil,
        })

        return {
            env = ui.env,
            ns = ui.ns,
            DeathpoolUI = ui.DeathpoolUI,
            DeathpoolUIAutocomplete = ui.DeathpoolUIAutocomplete,
            DeathpoolUIDeathLogList = ui.DeathpoolUIDeathLogList,
            DeathpoolUIDebug = ui.DeathpoolUIDebug,
            DeathpoolUIDemo = ui.DeathpoolUIDemo,
            DeathpoolUIHelp = ui.DeathpoolUIHelp,
            DeathpoolUILog = ui.DeathpoolUILog,
            DeathpoolUIMain = ui.DeathpoolUIMain,
            DeathpoolUIMainCollapsed = ui.DeathpoolUIMainCollapsed,
            DeathpoolUIMainPrediction = ui.DeathpoolUIMainPrediction,
            DeathpoolUIMainRecentDeaths = ui.DeathpoolUIMainRecentDeaths,
            DeathpoolUIRefresh = ui.DeathpoolUIRefresh,
            DeathpoolUITooltip = ui.DeathpoolUITooltip,
            DeathpoolConstants = ui.DeathpoolConstants,
            DeathpoolDatabase = ui.DeathpoolDatabase,
            DeathpoolLogic = ui.DeathpoolLogic,
            Deathpool = ui.Deathpool,
            DeathpoolDebug = ui.DeathpoolDebug,
            DeathpoolLog = ui.DeathpoolLog,
            printedMessages = ui.printedMessages,
            sendChatMessage = ui.sendChatMessage,
            cvars = ui.cvars,
            libDBIcon = ui.libDBIcon,
            setCVar = ui.setCVar,
            joinedChannels = ui.joinedChannels,
            joinPermanentChannel = ui.joinPermanentChannel,
            pressEscape = ui.pressEscape,
            findRegionText = ui.findRegionText,
            findDropdownButtonByText = ui.findDropdownButtonByText,
        }
    end

    return {
        Fixtures = Fixtures,
        ns = loadedLogic.ns,
        DeathpoolConstants = loadedLogic.DeathpoolConstants,
        DeathpoolDatabase = loadedLogic.DeathpoolDatabase,
        DeathpoolLogic = DeathpoolLogic,
        createUIContext = createUIContext,
        buildLevelPointsSummary = buildLevelPointsSummary,
        formatPredictionPreview = formatPredictionPreview,
        formatStoredDeathScore = formatStoredDeathScore,
    }
end

return { Create = Create }

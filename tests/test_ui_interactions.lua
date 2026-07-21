local UITestContext = require("tests.support_ui_test_context")
local testContext = UITestContext.Create()
local DeathpoolLogic = testContext.DeathpoolLogic
local suite = testContext.suite
local Fixtures = testContext.Fixtures
local createUIContext = testContext.createUIContext
local formatStoredDeathScore = testContext.formatStoredDeathScore
local assertEquals = testContext.assertEquals
local assertTruthy = testContext.assertTruthy
local assertContains = testContext.assertContains
local assertTableLength = testContext.assertTableLength
local TOOLTIP_WHITE = { 1, 1, 1 }
local TOOLTIP_GREEN = { 0.12, 1.0, 0.0 }
local TOOLTIP_YELLOW = { 1, 0.82, 0 }
local DeathpoolConstants = testContext.DeathpoolConstants
local SCORE_RULES = DeathpoolConstants.SCORING
local WAITING_FOR_FIRST_DEATH_MIN_DURATION_SECONDS = DeathpoolConstants.DEMO.waitingForFirstDeathMinDurationSeconds
local WAITING_FOR_FIRST_DEATH_HELP_TEXT_DELAY_SECONDS =
    DeathpoolConstants.DEMO.waitingForFirstDeathHelpTextDelaySeconds

local function showSetupWindow(Deathpool)
    Deathpool.__testNs.DeathpoolUISetup.Show(Deathpool.setupFrame, Deathpool)
end

local function findTooltipLineIndex(label)
    for index, line in ipairs(GameTooltip.lines or {}) do
        if line.left == label then
            return index
        end
    end

    return nil
end

local function assertTooltipLineExists(label, message)
    assertTruthy(findTooltipLineIndex(label) ~= nil, message)
end

local function assertTooltipLineOrder(firstLabel, secondLabel, message)
    local firstIndex = findTooltipLineIndex(firstLabel)
    local secondIndex = findTooltipLineIndex(secondLabel)
    assertTruthy(firstIndex ~= nil, message .. " (missing " .. firstLabel .. ")")
    assertTruthy(secondIndex ~= nil, message .. " (missing " .. secondLabel .. ")")
    if firstIndex ~= nil and secondIndex ~= nil then
        assertTruthy(firstIndex < secondIndex, message)
    end
end

local function assertTooltipLineColor(line, expectedColor, message)
    assertTruthy(line ~= nil, message .. " (missing line)")
    assertTruthy(line.leftColor ~= nil, message .. " (missing left color)")
    assertTruthy(line.rightColor ~= nil, message .. " (missing right color)")
    if line and line.leftColor and line.rightColor and expectedColor then
        assertEquals(line.leftColor[1], expectedColor[1], message .. " (left red)")
        assertEquals(line.leftColor[2], expectedColor[2], message .. " (left green)")
        assertEquals(line.leftColor[3], expectedColor[3], message .. " (left blue)")
        assertEquals(line.rightColor[1], expectedColor[1], message .. " (right red)")
        assertEquals(line.rightColor[2], expectedColor[2], message .. " (right green)")
        assertEquals(line.rightColor[3], expectedColor[3], message .. " (right blue)")
    end
end

local function hoverDeathLogCell(row, columnKey)
    local target = row and row.tooltipTargets and row.tooltipTargets[columnKey]
    assertTruthy(target ~= nil, "expected tooltip target for column " .. tostring(columnKey))
    local onEnter = target and target:GetScript("OnEnter")
    assertTruthy(type(onEnter) == "function", "expected OnEnter handler for column " .. tostring(columnKey))
    onEnter(target)
end

local function leaveDeathLogCell(row, columnKey)
    local target = row and row.tooltipTargets and row.tooltipTargets[columnKey]
    assertTruthy(target ~= nil, "expected tooltip target for column " .. tostring(columnKey))
    local onLeave = target and target:GetScript("OnLeave")
    assertTruthy(type(onLeave) == "function", "expected OnLeave handler for column " .. tostring(columnKey))
    onLeave(target)
end

local function assertNoDeathLogCellTooltipTarget(row, columnKey, message)
    local target = row and row.tooltipTargets and row.tooltipTargets[columnKey] or nil
    assertEquals(target, nil, message)
end

local function hoverRegion(region)
    assertTruthy(region ~= nil, "expected hover region")
    local onEnter = region:GetScript("OnEnter")
    assertTruthy(type(onEnter) == "function", "expected OnEnter handler")
    onEnter(region)
end

local function leaveRegion(region)
    assertTruthy(region ~= nil, "expected hover region")
    local onLeave = region:GetScript("OnLeave")
    assertTruthy(type(onLeave) == "function", "expected OnLeave handler")
    onLeave(region)
end

local function waitForGameInfoCallout(frame)
    local onUpdate = frame and frame:GetScript("OnUpdate")
    local attempts = 0

    while frame and frame.gameInfoCallout and frame.gameInfoCallout:IsShown() ~= true and attempts < 10 do
        if type(onUpdate) ~= "function" then
            break
        end

        onUpdate(frame, 0.02)
        attempts = attempts + 1
    end
end

local function hoverRegionAndWaitForGameInfoCallout(frame, region)
    hoverRegion(region)
    waitForGameInfoCallout(frame)
    assertEquals(frame.gameInfoCallout:IsShown(), true, "hovering should show the game info callout")
    assertTruthy(
        frame.gameInfoCallout.lines
            and frame.gameInfoCallout.lines[1]
            and type(frame.gameInfoCallout.lines[1].left) == "string"
            and frame.gameInfoCallout.lines[1].left ~= "",
        "game info callout should render a non-empty first line"
    )
    return frame.gameInfoCallout.lines[1].left
end

local function getAutocompleteTargetValue(list)
    assert(type(list) == "table" and #list > 0, "autocomplete list must not be empty")
    return list[1], string.lower(list[1])
end

local function testRefreshMethods()
    local fullPredictionDeath = Fixtures.storedDeath({
        timestamp = 100,
        points = 999,
        multiplierValue = 9,
        awardedPoints = 8991,
        sameZoneBonusApplied = true,
    })
    local fullPredictionScore = formatStoredDeathScore(fullPredictionDeath)
    local context = createUIContext(Fixtures.uiDatabase({
        totalPoints = 1234,
        recentDeaths = {
            fullPredictionDeath,
        },
        deathHistory = {
            Fixtures.storedDeath({
                timestamp = 90,
                name = "Alamo",
                level = 11,
                sourceName = "Defias",
                zone = "Westfall",
                matchedPrediction = false,
                prediction = false,
                predictionStreak = false,
                points = 0,
                multiplierValue = 0,
                awardedPoints = 0,
            }),
            fullPredictionDeath,
        },
        successfullyPredictedDeaths = {
            Fixtures.storedDeath({
                timestamp = 99,
                name = "Leeroy",
                sourceName = "Drowning",
                points = 2,
                multiplierValue = 1,
                awardedPoints = 2,
                prediction = {
                    elements = {
                        levelRange = "10-19",
                    },
                    lockedAt = 98,
                },
            }),
            fullPredictionDeath,
        },
    }))
    local Deathpool = context.Deathpool
    local DeathpoolDebug = context.DeathpoolDebug
    local DeathpoolLog = context.DeathpoolLog
    local historySourceWidth = context.DeathpoolUI.HISTORY_LOG_COLUMNS[2].width

    Deathpool:RefreshDeaths()
    Deathpool:RefreshLockedPrediction()
    Deathpool:RefreshCollapsedSummary(DeathpoolCharacterState.recentDeaths[1])
    DeathpoolDebug:RefreshLatestDeathDetails(
        DeathpoolCharacterState.recentDeaths[1],
        DeathpoolLogic.GetDisplayState(DeathpoolCharacterState)
    )
    DeathpoolLog:RefreshHistory()

    assertEquals(Deathpool.deathRows[1].name, nil, "recent death rows should not create the removed name column")
    assertEquals(Deathpool.deathRows[1].level:GetText(), "12", "recent death rows should display the latest death level")
    assertEquals(Deathpool.deathRows[1].sourceName:GetText(), "Hogger", "recent death rows should display the latest death source")
    assertEquals(Deathpool.deathRows[1].zone:GetText(), "Elwynn Forest", "recent death rows should display the latest death location")
    assertEquals(Deathpool.deathRows[1].pointsTooltipTarget, nil, "recent death rows should not create the removed base points hover target")
    assertEquals(Deathpool.deathRows[1].multiplier, nil, "recent death rows should not create the removed combo column")
    assertEquals(Deathpool.deathRows[1].streakMultiplier, nil, "recent death rows should not create the removed streak column")
    assertEquals(Deathpool.deathRows[1].awardedPoints:GetText(), fullPredictionScore.awardedPoints, "recent death rows should display total points in the points column")
    assertEquals(Deathpool.totalPointsValue:GetText(), "1,234", "main window should show the running score with comma separators")
    assertEquals(Deathpool.currentStreakValue:GetText(), "2", "main window should show the current streak")
    assertEquals(Deathpool.longestStreakValue:GetText(), "5", "main window should show the longest streak")
    assertContains(
        Deathpool.lockedPredictionValue:GetText(),
        "Level 20-29, source Hogger, or zone Elwynn Forest",
        "locked prediction summary should reflect the stored prediction"
    )
    assertEquals(Deathpool.collapsedLogFrame.rows[1].name, nil, "collapsed death log should not create the removed name column")
    assertEquals(Deathpool.collapsedLogFrame.rows[1].time:GetText(), context.DeathpoolUI.GetStoredDeathTime(fullPredictionDeath), "collapsed death log should show the latest time")
    assertEquals(Deathpool.collapsedLogFrame.rows[1].sourceName:GetText(), "Hogger", "collapsed death log should show the latest source")
    assertEquals(Deathpool.collapsedLogFrame.rows[1].level:GetText(), "12", "collapsed death log should show the latest level")
    assertEquals(Deathpool.collapsedLogFrame.rows[1].zone:GetText(), "Elwynn Forest", "collapsed death log should show the latest zone")
    assertEquals(Deathpool.collapsedLogFrame.rows[1].awardedPoints:GetText(), fullPredictionScore.awardedPoints, "collapsed death log should show the latest points")
    assertEquals(Deathpool.collapsedPointsValue:GetText(), "1,234", "collapsed score should show the running total with comma separators")
    assertEquals(Deathpool.deathRows[1]:GetScript("OnEnter"), nil, "recent death rows should not show tooltips from whole-row hover")
    hoverDeathLogCell(Deathpool.deathRows[1], "awardedPoints")
    assertTableLength(GameTooltip.lines, 4, "hovering a recent death score cell should show the compact scoring tooltip")
    assertEquals(GameTooltip.lines[1].left, "Base points:", "recent death row tooltip should start with base points in compact mode")
    assertTooltipLineColor(GameTooltip.lines[1], TOOLTIP_WHITE, "recent death row tooltip should keep base points white")
    assertEquals(GameTooltip.lines[2].left, "Same zone:", "recent death row tooltip should include the same-zone row")
    assertEquals(GameTooltip.lines[2].right, fullPredictionScore.sameZoneBonusPoints, "recent death row tooltip should show the applied same-zone bonus")
    assertTooltipLineColor(GameTooltip.lines[2], TOOLTIP_GREEN, "recent death row tooltip should keep the same-zone row green")
    assertTruthy(findTooltipLineIndex("Name:") == nil, "recent death row tooltip should omit identity rows in compact mode")
    assertTruthy(findTooltipLineIndex("Location:") == nil, "recent death row tooltip should omit location rows in compact mode")
    assertTruthy(findTooltipLineIndex("---------") == nil, "recent death row tooltip should omit the divider in compact mode")
    assertTruthy(findTooltipLineIndex("Level 10-19, source Hogger, or zone Elwynn Forest.") == nil, "recent death row tooltip should omit the prediction text in compact mode")
    assertTruthy(findTooltipLineIndex("Streak:") == nil, "recent death row tooltip should omit the streak row when the streak bonus is zero")
    assertEquals(GameTooltip.lines[3].left, "Level 10-19 + Hogger + Elwynn Forest:", "recent death row tooltip should include only the best combo row")
    assertTooltipLineColor(GameTooltip.lines[3], TOOLTIP_GREEN, "recent death row tooltip should keep successful combos green")
    assertTruthy(findTooltipLineIndex("Total:") == nil, "recent death row tooltip should omit the total multiplier row in compact mode")
    assertEquals(GameTooltip.lines[4].left, "Score:", "recent death row tooltip should include the final score row")
    assertEquals(GameTooltip.lines[4].right, fullPredictionScore.formula, "recent death row tooltip should show base plus same-zone points in the score formula")
    assertTooltipLineColor(GameTooltip.lines[4], TOOLTIP_YELLOW, "recent death row tooltip should keep the score row yellow")
    leaveDeathLogCell(Deathpool.deathRows[1], "awardedPoints")
    assertEquals(GameTooltip.visible, false, "leaving a recent death score cell should hide the tooltip")
    assertEquals(Deathpool.collapsedLogFrame.rows[1]:GetScript("OnEnter"), nil, "collapsed death log rows should not show tooltips from whole-row hover")
    assertNoDeathLogCellTooltipTarget(Deathpool.collapsedLogFrame.rows[1], "time", "collapsed death log should not create a time-column tooltip target")
    assertNoDeathLogCellTooltipTarget(Deathpool.collapsedLogFrame.rows[1], "level", "collapsed death log should not create a level-column tooltip target")
    assertNoDeathLogCellTooltipTarget(Deathpool.collapsedLogFrame.rows[1], "name", "collapsed death log should not create a name-column tooltip target")
    assertNoDeathLogCellTooltipTarget(Deathpool.collapsedLogFrame.rows[1], "sourceName", "collapsed death log should not create a source-column tooltip target")
    assertNoDeathLogCellTooltipTarget(Deathpool.collapsedLogFrame.rows[1], "zone", "collapsed death log should not create a location-column tooltip target")
    hoverDeathLogCell(Deathpool.collapsedLogFrame.rows[1], "awardedPoints")
    assertEquals(GameTooltip.lines[1].left, "Base points:", "collapsed death log points hover should start with scoring in compact mode")
    assertTruthy(findTooltipLineIndex("Name:") == nil, "collapsed death log points hover should omit identity rows in compact mode")
    assertTruthy(findTooltipLineIndex("Location:") == nil, "collapsed death log points hover should omit location rows in compact mode")
    assertTruthy(findTooltipLineIndex("Level 10-19, source Hogger, or zone Elwynn Forest.") == nil, "collapsed death log points hover should omit the prediction text in compact mode")
    assertTooltipLineOrder("Base points:", "Same zone:", "collapsed death log points hover should place same-zone bonus after base points")
    leaveDeathLogCell(Deathpool.collapsedLogFrame.rows[1], "awardedPoints")
    assertEquals(GameTooltip.visible, false, "leaving a collapsed death log points cell should hide the tooltip")
    assertEquals(Deathpool.sourceEditBox:GetText(), "Hogger", "refresh should populate the source edit box from locked prediction")
    assertEquals(Deathpool.zoneEditBox:GetText(), "Elwynn Forest", "refresh should populate the zone edit box from locked prediction")
    assertEquals(DeathpoolDebug.detailValues.name:GetText(), "Drakedog", "debug window should show the latest name")
    assertEquals(DeathpoolDebug.detailValues.totalPoints:GetText(), tostring(DeathpoolCharacterState.totalPoints), "debug window should show the latest total points")
    assertEquals(DeathpoolDebug.detailValues.currentPredictionStreak:GetText(), tostring(DeathpoolCharacterState.correctPredictionStreak), "debug window should show the latest current streak")
    assertEquals(DeathpoolDebug.detailValues.longestPredictionStreak:GetText(), tostring(DeathpoolCharacterState.longestPredictionStreak), "debug window should show the latest longest streak")
    assertContains(DeathpoolDebug.detailValues.lockedPrediction:GetText(), "Level 20-29, source Hogger, or zone Elwynn Forest", "debug window should show the latest locked prediction")
    assertEquals(DeathpoolDebug.detailValues.predictionStreak:GetText(), "1", "debug window should show the streak used for the latest death score")
    assertEquals(DeathpoolDebug.detailValues.basePoints:GetText(), fullPredictionScore.basePoints, "debug window should show the latest base points")
    assertEquals(DeathpoolDebug.detailValues.comboMultiplier:GetText(), fullPredictionScore.comboMultiplier, "debug window should show the latest combo bonus")
    assertEquals(DeathpoolDebug.detailValues.streakMultiplier:GetText(), fullPredictionScore.streakMultiplier, "debug window should show the latest streak bonus")
    assertEquals(DeathpoolDebug.detailValues.multiplier:GetText(), fullPredictionScore.comboSum, "debug window should show the formatted combo total")
    assertEquals(DeathpoolDebug.detailValues.pointFormula:GetText(), fullPredictionScore.formula, "debug window should show the latest score formula")
    assertContains(
        DeathpoolDebug.detailValues.comboDetails:GetText(),
        "Level 10-19 + Hogger + Elwynn Forest",
        "debug window should show the winning combo label"
    )
    assertEquals(
        DeathpoolDebug.detailValues.sourceMessage:GetText(),
        fullPredictionDeath.sourceMessage,
        "debug window should show the latest raw message in the copyable edit box"
    )
    assertEquals(DeathpoolDebug.detailValues.awardedPoints:GetText(), fullPredictionScore.awardedPoints, "debug window should show awarded points")
    assertEquals(DeathpoolDebug.detailValues.timestamp, nil, "debug window should remove the old timestamp field")
    assertEquals(DeathpoolDebug.detailValues.causeType, nil, "debug window should remove the old cause type field")
    assertEquals(DeathpoolLog.columnHeaders.sourceName:GetText(), "Source", "successful history should show the source column label")
    assertEquals(DeathpoolLog.columnHeaders.level, nil, "successful history should omit the level column header")
    assertEquals(DeathpoolLog.rows[1].sourceName:GetWidth(), historySourceWidth, "successful history should give the source column the scrollbar-aware width")
    assertEquals(DeathpoolLog.rows[1].sourceName:GetText(), "Hogger", "successful history should show the death source")
    assertEquals(DeathpoolLog.rows[1].level, nil, "successful history should not create death level cells")
    assertEquals(DeathpoolLog.rows[1].awardedPoints:GetText(), fullPredictionScore.awardedPoints, "history log should recalculate stale persisted totals from the saved prediction")
    assertEquals(DeathpoolLog.rows[1]:GetScript("OnEnter"), nil, "history log rows should not show tooltips from whole-row hover")
    assertNoDeathLogCellTooltipTarget(DeathpoolLog.rows[1], "time", "history log should not create a time-column tooltip target")
    assertNoDeathLogCellTooltipTarget(DeathpoolLog.rows[1], "sourceName", "history log should not create a source-column tooltip target")
    assertNoDeathLogCellTooltipTarget(DeathpoolLog.rows[1], "level", "history log should not create a level-column tooltip target")
    hoverDeathLogCell(DeathpoolLog.rows[1], "awardedPoints")
    assertEquals(GameTooltip.lines[1].left, "Level 10-19, source Hogger, or zone Elwynn Forest.", "history log points hover should start with the prediction text")
    assertEquals(GameTooltip.lines[1].right, "", "history log points hover prediction text should keep the right column blank")
    assertTruthy(findTooltipLineIndex("Name:") == nil, "history log points hover should omit the dead player name")
    assertTruthy(findTooltipLineIndex("---------") == nil, "history log points hover should omit the old prediction divider")
    assertEquals(GameTooltip.lines[2].left, "Level:", "history log points hover should show identity rows when requested")
    assertEquals(GameTooltip.lines[3].left, "Date:", "history log points hover should show the death date below level")
    assertEquals(GameTooltip.lines[3].right, "January 01, 1970 10:05", "history log points hover should show the full death date and time")
    assertTooltipLineOrder("Level:", "Date:", "history log points hover should place the death date below level")
    assertTooltipLineOrder("Date:", "Source:", "history log points hover should place the source below the death date")
    assertTooltipLineExists("Base points:", "history log points hover should show the base points after the identity rows")
    assertTooltipLineOrder("Location:", "Base points:", "history log points hover should place base points after the identity rows")
    assertTooltipLineExists("Same zone:", "history log points hover should include the same-zone row for real deaths")
    assertTooltipLineOrder("Base points:", "Same zone:", "history log points hover should place same-zone bonus after base points")
    do
        local basePointsIndex = findTooltipLineIndex("Base points:")
        assertTruthy(basePointsIndex ~= nil, "history log points hover should include the base points row")
        if basePointsIndex ~= nil then
            assertTooltipLineColor(
                GameTooltip.lines[basePointsIndex],
                TOOLTIP_WHITE,
                "history log points hover should keep base points white"
            )
        end
    end
    do
        local comboIndex = findTooltipLineIndex("Level 10-19 + Hogger + Elwynn Forest:")
        assertTruthy(comboIndex ~= nil, "history log points hover should include the best successful combo row")
        if comboIndex ~= nil then
            assertTooltipLineColor(
                GameTooltip.lines[comboIndex],
                TOOLTIP_GREEN,
                "history log points hover should keep successful combos green"
            )
        end
    end
    assertTruthy(findTooltipLineIndex("Combos:") == nil, "history log points hover should omit the combos section label")
    assertTruthy(findTooltipLineIndex("Total:") == nil, "history log points hover should omit the total multiplier row")
    assertTruthy(findTooltipLineIndex("Streak:") == nil, "history log points hover should omit the streak row when the streak bonus is zero")
    do
        local sameZoneIndex = findTooltipLineIndex("Same zone:")
        assertTruthy(sameZoneIndex ~= nil, "history log points hover should include the same-zone row")
        if sameZoneIndex ~= nil then
            assertEquals(
                GameTooltip.lines[sameZoneIndex].right,
                fullPredictionScore.sameZoneBonusPoints,
                "history log points hover should show the applied same-zone bonus"
            )
            assertTooltipLineColor(
                GameTooltip.lines[sameZoneIndex],
                TOOLTIP_GREEN,
                "history log points hover should keep the same-zone row green"
            )
        end
    end
    assertTooltipLineOrder("Same zone:", "Level 10-19 + Hogger + Elwynn Forest:", "history log points hover should place the best combo after same-zone bonus when streak is omitted")
    assertTooltipLineExists("Score:", "history log points hover should show the final score row at the bottom")
    assertTooltipLineOrder("Level 10-19 + Hogger + Elwynn Forest:", "Score:", "history log points hover should show the final score row after the combo row")
    do
        local totalIndex = findTooltipLineIndex("Total:")
        local scoreIndex = findTooltipLineIndex("Score:")
        assertTruthy(totalIndex == nil, "history log points hover should omit the total row")
        assertTruthy(scoreIndex ~= nil, "history log points hover should include the score row")
        if scoreIndex ~= nil then
            assertEquals(
                GameTooltip.lines[scoreIndex].right,
                fullPredictionScore.formula,
                "history log points hover should show base plus same-zone points in the score formula"
            )
            assertTooltipLineColor(
                GameTooltip.lines[scoreIndex],
                TOOLTIP_YELLOW,
                "history log points hover should keep the score row yellow"
            )
        end
    end
    leaveDeathLogCell(DeathpoolLog.rows[1], "awardedPoints")
    assertEquals(GameTooltip.visible, false, "leaving a history log points cell should hide the tooltip")
    assertEquals(DeathpoolLog.rows[2].sourceName:GetText(), "Drowning", "history log should default to the successful prediction source list")
    assertEquals(DeathpoolLog.filterButton:GetText(), "SHOW ALL", "history log should default the filter button to the alternate view action")

    DeathpoolLog.filterButton:GetScript("OnClick")()

    assertEquals(DeathpoolCharacterState.historySuccessfulOnly, false, "history filter should persist all-history mode when toggled off")
    assertEquals(DeathpoolLog.logSubtitle:GetText(), "All Predictions", "history filter should restore the all-deaths subtitle")
    assertEquals(DeathpoolLog.filterButton:GetText(), "SHOW SUCCESS ONLY", "history filter should offer the success-only action while unfiltered")
    assertEquals(DeathpoolLog.columnHeaders.time:GetText(), "Time", "all-history mode should restore the time column label")
    assertEquals(DeathpoolLog.columnHeaders.sourceName:GetText(), "Source", "all-history mode should use the source column label")
    assertEquals(DeathpoolLog.columnHeaders.level, nil, "all-history mode should omit the level column header")
    assertEquals(DeathpoolLog.rows[1].sourceName:GetWidth(), historySourceWidth, "all-history mode should keep the scrollbar-aware source column width")
    assertEquals(DeathpoolLog.rows[1].sourceName:GetText(), "Hogger", "all-history mode should show the newest history source first")
    assertEquals(DeathpoolLog.rows[1].level, nil, "all-history mode should not create level cells")
    assertEquals(DeathpoolLog.rows[2].sourceName:GetText(), "Defias", "all-history mode should include older sources underneath")

    DeathpoolLog.filterButton:GetScript("OnClick")()

    assertEquals(DeathpoolCharacterState.historySuccessfulOnly, true, "history filter should persist success-only mode when toggled back on")
    assertEquals(DeathpoolLog.logSubtitle:GetText(), "Successful Predictions", "history filter should relabel the window for success-only mode")
    assertEquals(DeathpoolLog.filterButton:GetText(), "SHOW ALL", "history filter should restore the all-deaths action while filtered")
    assertEquals(DeathpoolLog.columnHeaders.time:GetText(), "Rank", "success-only history should relabel the time column as rank")
    assertEquals(DeathpoolLog.columnHeaders.sourceName:GetText(), "Source", "success-only history should show the source column label")
    assertEquals(DeathpoolLog.columnHeaders.level, nil, "success-only history should omit the level column label")
    assertEquals(DeathpoolLog.rows[1].sourceName:GetWidth(), historySourceWidth, "success-only history should use the scrollbar-aware source column after toggling back")
    assertEquals(DeathpoolLog.rows[1].time:GetText(), "#1", "success-only history should show the highest-scoring death as rank one")
    assertEquals(DeathpoolLog.rows[2].time:GetText(), "#2", "success-only history should show lower-scoring deaths with later ranks")
    assertEquals(DeathpoolLog.rows[1].sourceName:GetText(), "Hogger", "success-only history should show the highest-scoring death source")
    assertEquals(DeathpoolLog.rows[1].level, nil, "success-only history should not create level cells")
    assertEquals(DeathpoolLog.rows[2].sourceName:GetText(), "Drowning", "success-only history should sort lower-scoring death sources underneath higher-scoring ones")
end

local function testTooltipUsesGreenForPositiveStreakRow()
    local streakDeath = Fixtures.storedDeath({
        timestamp = 100,
        predictionStreak = 2,
        sameZoneBonusApplied = true,
    })
    local context = createUIContext(Fixtures.uiDatabase({
        recentDeaths = {
            streakDeath,
        },
        deathHistory = {
            streakDeath,
        },
        successfullyPredictedDeaths = {
            streakDeath,
        },
    }))
    local Deathpool = context.Deathpool

    Deathpool:RefreshDeaths()
    hoverDeathLogCell(Deathpool.deathRows[1], "awardedPoints")

    do
        local streakIndex = findTooltipLineIndex("Streak:")
        assertTruthy(streakIndex ~= nil, "positive-streak tooltip should include the streak row")
        if streakIndex ~= nil then
            assertTooltipLineColor(
                GameTooltip.lines[streakIndex],
                TOOLTIP_GREEN,
                "positive-streak tooltip should keep the streak row green"
            )
        end
    end

    leaveDeathLogCell(Deathpool.deathRows[1], "awardedPoints")
end

local function testPredictionOnlyTooltipUsesPreviewStreakByDefault()
    local context = createUIContext()
    local DeathpoolUI = context.DeathpoolUI
    local anchor = CreateFrame("Frame", nil, UIParent)
    local prediction = Fixtures.prediction({
        levelRange = "10-19",
    })
    local previewSummary = DeathpoolLogic.GetComboDetails(prediction, nil, DeathpoolLogic.GetPreviewStreak())

    DeathpoolUI.ShowStandardizedTooltip(anchor, {
        prediction = prediction,
    }, false, false, false)

    do
        local streakIndex = findTooltipLineIndex("Streak:")
        assertTruthy(streakIndex ~= nil, "prediction-only tooltip should include the preview streak row by default")
        if streakIndex ~= nil then
            assertEquals(
                GameTooltip.lines[streakIndex].right,
                DeathpoolUI.GetMultiplierDisplay(previewSummary.streakMultiplier),
                "prediction-only tooltip should use the configured preview streak value"
            )
            assertTooltipLineColor(
                GameTooltip.lines[streakIndex],
                TOOLTIP_GREEN,
                "prediction-only tooltip should keep the preview streak row green"
            )
        end
    end

    GameTooltip:Hide()
end

local function testTooltipHidesLowValueMultiplierRows()
    local context = createUIContext()
    local DeathpoolUI = context.DeathpoolUI
    local anchor = CreateFrame("Frame", nil, UIParent)
    local prediction = Fixtures.prediction({
        levelRange = false,
        source = "hogger",
        zone = false,
        zoneLabel = false,
    })
    local death = Fixtures.death({
        sourceName = "Hogger",
        zone = "Westfall",
    })

    DeathpoolUI.ShowStandardizedTooltip(anchor, {
        prediction = prediction,
        death = death,
        streak = 1,
    }, false, false, true)

    assertTruthy(findTooltipLineIndex("Streak:") == nil, "tooltips should hide a streak row when the multiplier is x0 or x1")
    assertTruthy(findTooltipLineIndex("Hogger:") == nil, "tooltips should hide combo rows when the multiplier is x0 or x1")
    assertTruthy(findTooltipLineIndex("Total:") == nil, "tooltips should omit the total multiplier row")
    assertTooltipLineExists("Score:", "tooltips should still show the score row")

    GameTooltip:Hide()
end

local function testRefreshLockedPredictionRestoresReloadedPaneState()
    local context = createUIContext(Fixtures.uiDatabase({
        lockedPrediction = Fixtures.prediction({
            levelRange = "20-29",
        }),
        lastPrediction = Fixtures.prediction({
            levelRange = "30-39",
            source = "defias",
            zone = "westfall",
        }),
    }))
    local Deathpool = context.Deathpool

    Deathpool:RefreshLockedPrediction()

    assertEquals(Deathpool.selectedLevelRange, "20-29", "refresh should restore the locked level range selection after reload")
    assertEquals(Deathpool.sourceEditBox:GetText(), "Hogger", "refresh should restore the locked source text after reload")
    assertEquals(Deathpool.zoneEditBox:GetText(), "Elwynn Forest", "refresh should restore the locked zone text after reload")
    assertEquals(Deathpool.lockButton:GetText(), "LOCKED IN", "refresh should restore the locked button label after reload")
    assertEquals(Deathpool.lockButton:IsEnabled(), false, "refresh should keep the lock button disabled while a prediction is locked")
    assertEquals(Deathpool.sourceEditBox:IsEnabled(), false, "refresh should keep the source input locked after reload")
    assertEquals(Deathpool.zoneEditBox:IsEnabled(), false, "refresh should keep the zone input locked after reload")
    assertTruthy(Deathpool.levelRangeButtons[3]:IsEnabled(), "refresh should keep the selected level range visually active after reload")
    assertEquals(Deathpool.levelRangeButtons[2]:IsEnabled(), false, "refresh should keep other level ranges disabled while locked")
    assertTruthy(Deathpool.pauseButton:IsEnabled(), "refresh should keep pause enabled while a prediction is locked")
    DeathpoolCharacterState.lockedPrediction = nil
    Deathpool:RefreshLockedPrediction()

    assertEquals(Deathpool.selectedLevelRange, "30-39", "refresh should restore the last unlocked level range when no prediction is locked")
    assertEquals(Deathpool.sourceEditBox:GetText(), "Defias", "refresh should restore the last unlocked source text")
    assertEquals(Deathpool.zoneEditBox:GetText(), "Westfall", "refresh should restore the last unlocked zone text")
    assertEquals(Deathpool.lockedPredictionValue:GetText(), "Prediction not locked in yet.", "refresh should keep the summary tied to the currently locked prediction")
    assertEquals(Deathpool.lockButton:GetText(), "LOCK IN", "refresh should restore the unlocked button label")
    assertTruthy(Deathpool.lockButton:IsEnabled(), "refresh should re-enable locking when a draft prediction was restored")
    assertTruthy(Deathpool.sourceEditBox:IsEnabled(), "refresh should unlock the source input when nothing is locked")
    assertTruthy(Deathpool.zoneEditBox:IsEnabled(), "refresh should unlock the zone input when nothing is locked")
    assertEquals(Deathpool.levelRangeButtons[4]:IsEnabled(), false, "refresh should keep the restored draft level range selected")
    assertTruthy(Deathpool.levelRangeButtons[3]:IsEnabled(), "refresh should re-enable other level ranges when unlocked")
    assertEquals(Deathpool.pauseButton:IsEnabled(), false, "refresh should disable pause when nothing is locked")
end

local function testRefreshMethodsPreferIntroDemoStateOverLiveDatabase()
    local demoDeath = Fixtures.storedDeath({
        timestamp = 500,
        name = "Demohunter",
        level = 34,
        sourceName = "Burning Blade Cultist",
        zone = "Desolace",
        prediction = Fixtures.prediction({
            levelRange = "30-39",
            source = "burning blade cultist",
            zone = "desolace",
        }),
        predictionStreak = 3,
    })
    local demoPrediction = Fixtures.prediction({
        levelRange = "30-39",
        source = "burning blade cultist",
        zone = "desolace",
    })

    local context = createUIContext(Fixtures.uiDatabase({
        totalPoints = 999,
        correctPredictionStreak = 8,
        longestPredictionStreak = 12,
        lockedPrediction = Fixtures.prediction({
            levelRange = "60",
            source = "hogger",
            zone = "elwynn forest",
        }),
        recentDeaths = {
            Fixtures.storedDeath({
                timestamp = 400,
                name = "Livedeath",
                level = 60,
                sourceName = "Hogger",
                zone = "Elwynn Forest",
            }),
        },
        deathHistory = {
            Fixtures.storedDeath({
                timestamp = 400,
                name = "Livedeath",
                level = 60,
                sourceName = "Hogger",
                zone = "Elwynn Forest",
            }),
        },
    }))
    local Deathpool = context.Deathpool

    Deathpool.introDemoController:Show()
    Deathpool.introDemoController.demoState = Fixtures.introDemoState({
        recentDeaths = { demoDeath },
        totalPoints = 44,
        correctPredictionStreak = 3,
        longestPredictionStreak = 6,
        lockedPrediction = demoPrediction,
        draftPrediction = demoPrediction,
        lastPrediction = demoPrediction,
        deathHistory = {},
        successfullyPredictedDeaths = {},
    })

    Deathpool:RefreshDeaths()
    Deathpool:RefreshLockedPrediction()
    Deathpool:RefreshCollapsedSummary()

    assertEquals(Deathpool.deathRows[1].name, nil, "demo refresh should not create the removed name column")
    assertEquals(Deathpool.deathRows[1].level:GetText(), "34", "demo refresh should prefer the demo death level")
    assertEquals(Deathpool.deathRows[1].sourceName:GetText(), "Burning Blade Cultist", "demo refresh should prefer the demo death source")
    assertEquals(Deathpool.deathRows[1].zone:GetText(), "Desolace", "demo refresh should prefer the demo death zone")
    assertEquals(Deathpool.totalPointsValue:GetText(), "44", "demo refresh should prefer the demo total points")
    assertEquals(Deathpool.currentStreakValue:GetText(), "3", "demo refresh should prefer the demo current streak")
    assertEquals(Deathpool.longestStreakValue:GetText(), "6", "demo refresh should prefer the demo longest streak")
    assertContains(
        Deathpool.lockedPredictionValue:GetText(),
        "Level 30-39, source Burning Blade Cultist, or zone Desolace",
        "demo refresh should prefer the demo locked prediction"
    )
    assertEquals(Deathpool.collapsedLogFrame.rows[1].sourceName:GetText(), "Burning Blade Cultist", "demo refresh should prefer the demo collapsed death log")
    assertEquals(Deathpool.collapsedPointsValue:GetText(), "44", "demo refresh should prefer the demo collapsed score")
end

local function testRefreshLockedPredictionRestoresInputsAndPauseButtonState()
    local context = createUIContext(Fixtures.uiDatabase({
        lockedPrediction = Fixtures.prediction({
            levelRange = "30-39",
            source = "burning blade cultist",
            zone = "desolace",
        }),
        lastPrediction = Fixtures.prediction({
            levelRange = "20-29",
            source = "defias pillager",
            zone = "westfall",
        }),
    }))
    local Deathpool = context.Deathpool

    Deathpool:RefreshLockedPrediction()

    assertEquals(Deathpool.selectedLevelRange, "30-39", "refresh should restore the locked level range")
    assertEquals(Deathpool.sourceEditBox:GetText(), "Burning Blade Cultist", "refresh should populate the source input from the locked prediction")
    assertEquals(Deathpool.zoneEditBox:GetText(), "Desolace", "refresh should populate the zone input from the locked prediction")
    assertTruthy(Deathpool.levelRangeButtons[4]:IsEnabled(), "refresh should keep the locked level range visually active")
    assertEquals(Deathpool.levelRangeButtons[3]:IsEnabled(), false, "refresh should keep other level ranges disabled while locked")
    assertEquals(Deathpool.lockButton:GetText(), "LOCKED IN", "refresh should keep the locked button label")
    assertEquals(Deathpool.lockButton:IsEnabled(), false, "refresh should disable lock while a prediction is locked")
    assertEquals(Deathpool.sourceEditBox:IsEnabled(), false, "refresh should disable the source input while locked")
    assertEquals(Deathpool.zoneEditBox:IsEnabled(), false, "refresh should disable the zone input while locked")
    assertTruthy(Deathpool.pauseButton:IsEnabled(), "refresh should enable pause while a prediction is locked")

    DeathpoolCharacterState.lockedPrediction = nil
    Deathpool:RefreshLockedPrediction()

    assertEquals(Deathpool.selectedLevelRange, "20-29", "refresh should restore the last level range when nothing is locked")
    assertEquals(Deathpool.sourceEditBox:GetText(), "Defias Pillager", "refresh should populate the source input from the last draft prediction")
    assertEquals(Deathpool.zoneEditBox:GetText(), "Westfall", "refresh should populate the zone input from the last draft prediction")
    assertEquals(Deathpool.levelRangeButtons[3]:IsEnabled(), false, "refresh should keep the restored level range selected")
    assertTruthy(Deathpool.levelRangeButtons[4]:IsEnabled(), "refresh should re-enable other level ranges once unlocked")
    assertEquals(Deathpool.lockButton:GetText(), "LOCK IN", "refresh should restore the unlocked button label")
    assertTruthy(Deathpool.lockButton:IsEnabled(), "refresh should enable lock when a restorable prediction exists")
    assertTruthy(Deathpool.sourceEditBox:IsEnabled(), "refresh should re-enable the source input when unlocked")
    assertTruthy(Deathpool.zoneEditBox:IsEnabled(), "refresh should re-enable the zone input when unlocked")
    assertEquals(Deathpool.pauseButton:IsEnabled(), false, "refresh should disable pause when no prediction is locked")
end

local function testRefreshLockedPredictionHandlesEmptyState()
    local context = createUIContext(Fixtures.uiDatabase({
        lockedPrediction = false,
        lastPrediction = false,
    }))
    local Deathpool = context.Deathpool

    Deathpool:RefreshLockedPrediction()

    assertEquals(Deathpool.lockedPredictionValue:GetText(), "Prediction not locked in yet.", "empty refresh should keep the unlocked prediction summary")
    assertEquals(Deathpool.sourceEditBox:GetText(), "", "empty refresh should clear the source input")
    assertEquals(Deathpool.zoneEditBox:GetText(), "", "empty refresh should clear the zone input")
    assertEquals(Deathpool.lockButton:GetText(), "LOCK IN", "empty refresh should keep the lock button label unlocked")
    assertEquals(Deathpool.pauseButton:IsEnabled(), false, "empty refresh should disable the pause button")
end

local function testEmptyPredictionPromptReplacesMainDeathLogUntilPredictionSelected()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenFirstRun = false,
        lockedPrediction = false,
        draftPrediction = false,
        lastPrediction = false,
        recentDeaths = {
            Fixtures.storedDeath({
                timestamp = 100,
                name = "Promptcheck",
                level = 12,
                sourceName = "Hogger",
                zone = "Elwynn Forest",
            }),
        },
    }))
    local Deathpool = context.Deathpool

    Deathpool:RefreshDeaths()
    Deathpool:RefreshLockedPrediction()

    assertEquals(Deathpool.emptyPredictionPrompt:IsShown(), true, "main window should show the empty-prediction prompt when nothing is selected")
    assertEquals(Deathpool.deathRows[1]:IsShown(), false, "main window should hide recent death rows until a prediction exists")
    assertEquals(Deathpool.deathRows[1].sourceName:GetText(), "Hogger", "hidden prompt rows should retain current death source")

    Deathpool.levelRangeButtons[2]:GetScript("OnClick")(Deathpool.levelRangeButtons[2])

    assertEquals(Deathpool.emptyPredictionPrompt:IsShown(), true, "selecting a prediction should keep the empty-prediction prompt visible before lock-in")
    assertEquals(Deathpool.deathRows[1]:IsShown(), false, "selecting a prediction should keep recent death rows hidden before lock-in")
    assertEquals(Deathpool.deathRows[1].sourceName:GetText(), "Hogger", "selecting a prediction should not clear hidden death rows")

    Deathpool.lockButton:GetScript("OnClick")()

    assertEquals(Deathpool.emptyPredictionPrompt:IsShown(), false, "locking in a prediction should hide the empty-prediction prompt")
    assertEquals(Deathpool.deathRows[1]:IsShown(), true, "locking in a prediction should show recent death rows again")
    assertEquals(DeathpoolCharacterState.hasSeenFirstRun, true, "locking in a prediction should persist the first-run flag")
    assertEquals(Deathpool.deathRows[1].sourceName:GetText(), "Hogger", "recent deaths should return once a prediction is selected")
end

local function testSetupWindowShowsBothIncompleteSetupItems()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenFirstRun = false,
        lockedPrediction = false,
        draftPrediction = false,
        lastPrediction = false,
    }), {
        hardcoreDeathChatType = "0",
        hardcoreDeathsJoined = false,
    })
    local Deathpool = context.Deathpool

    Deathpool:RefreshDeaths()
    Deathpool:RefreshLockedPrediction()

    assertEquals(Deathpool.configPromptFrame, nil, "incomplete setup should not create an inline setup prompt")
    assertEquals(Deathpool.setupFrame:IsShown(), false, "incomplete setup should not show from refresh alone")

    showSetupWindow(Deathpool)

    assertEquals(Deathpool.setupFrame:IsShown(), true, "incomplete setup should show the setup window")
    assertEquals(Deathpool.setupFrame.backdropOverlay:IsShown(), true, "incomplete setup should obscure the main window")
    assertEquals(Deathpool.setupFrame.title:GetText(), "SETUP", "setup window should use the setup title")
    assertEquals(Deathpool.setupFrame.enableDeathAnnouncementsButton:IsShown(), true, "incomplete setup should show the enable button")
    assertEquals(Deathpool.setupFrame.enableDeathAnnouncementsButton:IsEnabled(), true, "disabled death announcements should leave enable clickable")
    assertEquals(Deathpool.setupFrame.joinHardcoreDeathsButton:IsShown(), true, "incomplete setup should show the join button")
    assertEquals(Deathpool.setupFrame.joinHardcoreDeathsButton:IsEnabled(), true, "missing hardcore deaths channel should leave join clickable")
    assertEquals(Deathpool.emptyPredictionPrompt:IsShown(), false, "setup window should hide the first-run prompt")
    assertEquals(Deathpool.lockButton:IsEnabled(), false, "setup window should disable locking predictions")
    assertEquals(Deathpool.levelRangeButtons[2]:IsEnabled(), false, "setup window should disable level buttons")
    assertEquals(Deathpool.sourceEditBox:IsEnabled(), false, "setup window should disable source input")
    assertEquals(Deathpool.zoneEditBox:IsEnabled(), false, "setup window should disable zone input")
end

local function testSetupCloseButtonBlocksNewCharacters()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenIntroDemo = false,
        hasSeenFirstRun = false,
        lockedPrediction = false,
        draftPrediction = false,
        lastPrediction = false,
    }), {
        hardcoreDeathChatType = "0",
        hardcoreDeathsJoined = false,
    })
    local Deathpool = context.Deathpool

    showSetupWindow(Deathpool)

    assertTruthy(Deathpool.setupFrame.CloseButton ~= nil, "setup window should expose the template close button")
    assertEquals(Deathpool.setupFrame.CloseButton:IsEnabled(), false, "new characters should not be able to close setup with X")

    Deathpool.setupFrame.CloseButton:Click()

    assertEquals(Deathpool.setupFrame:IsShown(), true, "setup X should keep setup visible before Deathpool has started")
    assertEquals(Deathpool.setupFrame.backdropOverlay:IsShown(), true, "blocked setup X should keep the setup backdrop visible")
end

local function testSetupCloseButtonBlocksBeforeFirstPrediction()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenIntroDemo = true,
        hasSeenFirstRun = false,
        lockedPrediction = false,
        draftPrediction = false,
        lastPrediction = false,
    }), {
        hardcoreDeathChatType = "1",
        hardcoreDeathsJoined = true,
    })
    local Deathpool = context.Deathpool

    showSetupWindow(Deathpool)

    assertEquals(Deathpool.setupFrame.CloseButton:IsEnabled(), false, "setup X should stay disabled until the first prediction is made")

    Deathpool.setupFrame.CloseButton:Click()

    assertEquals(Deathpool.setupFrame:IsShown(), true, "setup X should not close setup after demo but before first prediction")
    assertEquals(Deathpool.setupFrame.backdropOverlay:IsShown(), true, "blocked setup X after demo should keep the backdrop visible")
end

local function testSetupCloseButtonClosesForDeathpoolPlayers()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenIntroDemo = true,
        hasSeenFirstRun = true,
    }), {
        hardcoreDeathChatType = "0",
        hardcoreDeathsJoined = false,
    })
    local Deathpool = context.Deathpool

    showSetupWindow(Deathpool)

    assertEquals(Deathpool.setupFrame.CloseButton:IsEnabled(), true, "Deathpool players should be able to close setup with X")

    Deathpool.setupFrame.CloseButton:Click()

    assertEquals(Deathpool.setupFrame:IsShown(), false, "setup X should close setup once Deathpool has started")
    assertEquals(Deathpool.setupFrame.backdropOverlay:IsShown(), false, "setup X should clear the backdrop when setup closes")
end

local function testSetupWindowEnableChecksOnlyDeathAnnouncementItem()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenFirstRun = false,
        lockedPrediction = false,
        draftPrediction = false,
        lastPrediction = false,
    }), {
        hardcoreDeathChatType = "0",
        hardcoreDeathsJoined = false,
    })
    local Deathpool = context.Deathpool

    showSetupWindow(Deathpool)
    Deathpool.setupFrame.enableDeathAnnouncementsButton:Click()

    assertEquals(#context.setCVarCalls, 1, "clicking enable should set the death announcement CVar once")
    assertEquals(context.setCVarCalls[1].name, "hardcoreDeathChatType", "clicking enable should set the death announcement CVar")
    assertEquals(context.setCVarCalls[1].value, "1", "clicking enable should enable game death announcements")
    assertEquals(Deathpool.setupFrame:IsShown(), true, "remaining channel setup should keep the setup window visible")
    assertEquals(Deathpool.setupFrame.enableDeathAnnouncementsButton:IsEnabled(), false, "completed death announcements should disable enable")
    assertEquals(Deathpool.setupFrame.enableDeathAnnouncementsButton:GetText(), "ENABLED", "completed death announcements should show the completed label")
    assertEquals(Deathpool.setupFrame.joinHardcoreDeathsButton:IsEnabled(), true, "missing channel should keep join clickable")
    assertEquals(Deathpool.setupFrame.joinHardcoreDeathsButton:GetText(), "JOIN", "missing channel should keep the join action label")
    assertEquals(Deathpool.emptyPredictionPrompt:IsShown(), false, "partially complete setup should not advance to first-run prompt")
    assertEquals(Deathpool.lockButton:IsEnabled(), false, "partially complete setup should keep prediction locking disabled")
end

local function testSetupWindowJoinChecksOnlyChannelItem()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenFirstRun = false,
        lockedPrediction = false,
        draftPrediction = false,
        lastPrediction = false,
    }), {
        hardcoreDeathChatType = "0",
        hardcoreDeathsJoined = false,
    })
    local Deathpool = context.Deathpool

    showSetupWindow(Deathpool)
    Deathpool.setupFrame.joinHardcoreDeathsButton:Click()

    assertEquals(#context.joinedChannelNames, 1, "clicking join should permanently join one channel")
    assertEquals(context.joinedChannelNames[1], "HardcoreDeaths", "clicking join should permanently join the HardcoreDeaths channel")
    assertEquals(Deathpool.setupFrame:IsShown(), true, "remaining death announcement setup should keep the setup window visible")
    assertEquals(Deathpool.setupFrame.enableDeathAnnouncementsButton:IsEnabled(), true, "disabled death announcements should keep enable clickable")
    assertEquals(Deathpool.setupFrame.enableDeathAnnouncementsButton:GetText(), "ENABLE", "disabled death announcements should keep the enable action label")
    assertEquals(Deathpool.setupFrame.joinHardcoreDeathsButton:IsEnabled(), false, "completed channel setup should disable join")
    assertEquals(Deathpool.setupFrame.joinHardcoreDeathsButton:GetText(), "JOINED", "completed channel setup should show the completed label")
    assertEquals(Deathpool.emptyPredictionPrompt:IsShown(), false, "partially complete setup should not advance to first-run prompt")
    assertEquals(Deathpool.lockButton:IsEnabled(), false, "partially complete setup should keep prediction locking disabled")
end

local function testSetupWindowShowsPrecompletedDeathAnnouncements()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenFirstRun = false,
        lockedPrediction = false,
        draftPrediction = false,
        lastPrediction = false,
    }), {
        hardcoreDeathChatType = "1",
        hardcoreDeathsJoined = false,
    })
    local Deathpool = context.Deathpool

    showSetupWindow(Deathpool)

    assertEquals(Deathpool.setupFrame:IsShown(), true, "one incomplete item should keep the setup window visible")
    assertEquals(Deathpool.setupFrame.enableDeathAnnouncementsButton:IsEnabled(), false, "enabled death announcements should disable enable")
    assertEquals(Deathpool.setupFrame.enableDeathAnnouncementsButton:GetText(), "ENABLED", "enabled death announcements should show the completed label")
    assertEquals(Deathpool.setupFrame.joinHardcoreDeathsButton:IsEnabled(), true, "missing channel should keep join clickable")
    assertEquals(Deathpool.setupFrame.joinHardcoreDeathsButton:GetText(), "JOIN", "missing channel should keep the join action label")
    assertEquals(Deathpool.emptyPredictionPrompt:IsShown(), false, "one incomplete item should hide first-run prompt")
end

local function testSetupWindowCompletedSetupAdvancesToPrediction()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenFirstRun = false,
        lockedPrediction = false,
        draftPrediction = false,
        lastPrediction = false,
    }), {
        hardcoreDeathChatType = "1",
        hardcoreDeathsJoined = true,
    })
    local Deathpool = context.Deathpool

    Deathpool:RefreshDeaths()
    Deathpool:RefreshLockedPrediction()

    assertEquals(Deathpool.setupFrame:IsShown(), false, "completed setup should hide the setup window")
    assertEquals(Deathpool.setupFrame.backdropOverlay:IsShown(), false, "completed setup should hide the main-window backdrop")
    assertEquals(Deathpool.emptyPredictionPrompt:IsShown(), true, "completed setup should advance to the first-run prompt")
    assertEquals(Deathpool.levelRangeButtons[2]:IsEnabled(), true, "completed setup should unlock level buttons")
    assertEquals(Deathpool.sourceEditBox:IsEnabled(), true, "completed setup should unlock source input")
    assertEquals(Deathpool.zoneEditBox:IsEnabled(), true, "completed setup should unlock zone input")
end

local function testReturningPlayersDoNotSeeFirstRunPrompt()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenFirstRun = true,
        lockedPrediction = false,
        draftPrediction = false,
        lastPrediction = false,
        recentDeaths = {
            Fixtures.storedDeath({
                timestamp = 100,
                name = "Veterancheck",
                level = 12,
                sourceName = "Hogger",
                zone = "Elwynn Forest",
            }),
        },
    }))
    local Deathpool = context.Deathpool

    Deathpool:RefreshDeaths()
    Deathpool:RefreshLockedPrediction()

    assertEquals(Deathpool.emptyPredictionPrompt:IsShown(), false, "returning players should not see the first-run prompt")
    assertEquals(Deathpool.deathRows[1]:IsShown(), true, "returning players should keep the recent death log visible")
    assertEquals(Deathpool.deathRows[1].sourceName:GetText(), "Hogger", "returning players should still see recent deaths")
end

local function testWaitingForFirstDeathNotificationUsesSharedPromptPane()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenFirstRun = true,
        lockedPrediction = false,
        draftPrediction = false,
        lastPrediction = false,
        recentDeaths = {},
    }))
    local Deathpool = context.Deathpool

    Deathpool:RefreshDeaths()
    Deathpool:RefreshLockedPrediction()

    assertEquals(Deathpool.emptyPredictionPrompt:IsShown(), false, "empty recent deaths should hide the centered prompt while dots animate separately")
    assertEquals(Deathpool.waitingPromptText:IsShown(), true, "empty recent deaths should show the waiting prompt base text")
    assertEquals(Deathpool.waitingPromptDots:IsShown(), true, "empty recent deaths should show the waiting prompt dots")
    assertEquals(Deathpool.waitingPromptHelpText:IsShown(), false, "empty recent deaths should hide the help hint before the timer completes")
    assertEquals(
        Deathpool.waitingPromptText:GetText(),
        "Waiting for first death",
        "empty recent deaths should show the waiting message base text"
    )
    assertEquals(
        Deathpool.waitingPromptDots:GetText(),
        "",
        "empty recent deaths should start the waiting message with no dots"
    )
    assertEquals(Deathpool.deathRows[1]:IsShown(), false, "empty recent deaths should keep the main death log hidden")

---@diagnostic disable-next-line: need-check-nil
    Deathpool:GetScript("OnUpdate")(Deathpool, 1)
    assertEquals(
        Deathpool.waitingPromptDots:GetText(),
        ".",
        "waiting message should add the first dot after one second"
    )

---@diagnostic disable-next-line: need-check-nil
    Deathpool:GetScript("OnUpdate")(Deathpool, 1)
    assertEquals(
        Deathpool.waitingPromptDots:GetText(),
        "..",
        "waiting message should add a second dot after two seconds"
    )

---@diagnostic disable-next-line: need-check-nil
    Deathpool:GetScript("OnUpdate")(Deathpool, 1)
    assertEquals(
        Deathpool.waitingPromptDots:GetText(),
        "...",
        "waiting message should add a third dot after three seconds"
    )

---@diagnostic disable-next-line: need-check-nil
    Deathpool:GetScript("OnUpdate")(Deathpool, 1)
    assertEquals(
        Deathpool.waitingPromptDots:GetText(),
        "",
        "waiting message should loop back to no dots after four seconds"
    )

---@diagnostic disable-next-line: need-check-nil
    Deathpool:GetScript("OnUpdate")(Deathpool, WAITING_FOR_FIRST_DEATH_HELP_TEXT_DELAY_SECONDS - 4)
    assertEquals(
        Deathpool.waitingPromptText:GetText(),
        "Waiting for first death",
        "waiting message should keep the base text in place when the help hint appears"
    )
    assertEquals(Deathpool.waitingPromptText:IsShown(), true, "waiting message should keep showing the base text when the help hint appears")
    assertEquals(Deathpool.waitingPromptDots:IsShown(), true, "waiting message should keep the animated dots visible when the help hint appears")
    assertEquals(
        Deathpool.waitingPromptDots:GetText(),
        string.rep(".", WAITING_FOR_FIRST_DEATH_HELP_TEXT_DELAY_SECONDS % 4),
        "waiting message should keep the dots aligned when the help hint appears"
    )
    assertEquals(
        Deathpool.waitingPromptHelpText:GetText(),
        "Click HELP if you are missing deaths",
        "waiting message should add the help hint after the minimum duration"
    )
    assertEquals(Deathpool.waitingPromptHelpText:IsShown(), true, "waiting message should show the separate help hint after the minimum duration")

---@diagnostic disable-next-line: need-check-nil
    Deathpool:GetScript("OnUpdate")(Deathpool, 1)
    assertEquals(
        Deathpool.waitingPromptDots:GetText(),
        string.rep(".", (WAITING_FOR_FIRST_DEATH_HELP_TEXT_DELAY_SECONDS + 1) % 4),
        "waiting message should keep animating the dots after the help hint appears"
    )
    assertEquals(Deathpool.waitingPromptHelpText:IsShown(), true, "waiting message should keep the help hint visible while the dots continue")
end

local function testWaitingForFirstDeathNotificationRestoresAfterMinimize()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenFirstRun = true,
        lockedPrediction = false,
        draftPrediction = false,
        lastPrediction = false,
        recentDeaths = {},
    }))
    local DeathpoolUI = context.DeathpoolUI
    local Deathpool = context.Deathpool

    Deathpool:RefreshDeaths()
    assertEquals(Deathpool.waitingPromptText:IsShown(), true, "waiting prompt should start visible before minimizing")

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)

---@diagnostic disable-next-line: need-check-nil
    Deathpool:GetScript("OnUpdate")(Deathpool, 1)
    assertEquals(Deathpool.waitingPromptText:IsShown(), false, "collapsed refresh should hide the expanded waiting prompt")

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, false)

    assertEquals(Deathpool.waitingPromptText:IsShown(), true, "expanding should restore the waiting prompt base text")
    assertEquals(Deathpool.waitingPromptDots:IsShown(), true, "expanding should restore the waiting prompt dots")
    assertEquals(Deathpool.deathRows[1]:IsShown(), false, "expanding should keep empty death rows hidden while waiting")
end

local function testWaitingForFirstDeathNotificationStaysVisibleForMinimumDuration()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenFirstRun = true,
        lockedPrediction = false,
        draftPrediction = false,
        lastPrediction = false,
        recentDeaths = {},
    }))
    local Deathpool = context.Deathpool
    local incomingDeath = Fixtures.storedDeath({
        timestamp = 100,
        name = "Soonenough",
        level = 14,
        sourceName = "Defias Trapper",
        zone = "Westfall",
    })

    Deathpool:RefreshDeaths()
    Deathpool:RefreshLockedPrediction()

---@diagnostic disable-next-line: need-check-nil
    Deathpool:GetScript("OnUpdate")(Deathpool, 2)
    DeathpoolCharacterState.recentDeaths = { incomingDeath }
    Deathpool:RefreshDeaths()

    assertEquals(Deathpool.waitingPromptText:IsShown(), true, "incoming deaths should keep the waiting prompt visible until the minimum duration completes")
    assertEquals(Deathpool.waitingPromptDots:GetText(), "..", "incoming deaths should preserve the current waiting animation state")
    assertEquals(Deathpool.deathRows[1]:IsShown(), false, "incoming deaths should stay hidden while the waiting prompt minimum duration is still active")
    assertEquals(Deathpool.deathRows[1].sourceName:GetText(), "Defias Trapper", "incoming deaths should populate hidden rows while waiting")

---@diagnostic disable-next-line: need-check-nil
    Deathpool:GetScript("OnUpdate")(Deathpool, WAITING_FOR_FIRST_DEATH_MIN_DURATION_SECONDS - 3)
    assertEquals(Deathpool.waitingPromptText:IsShown(), true, "incoming deaths should still wait until the minimum duration before revealing the log")
    assertEquals(Deathpool.deathRows[1]:IsShown(), false, "incoming deaths should remain hidden before the minimum duration completes")
    assertEquals(Deathpool.deathRows[1].sourceName:GetText(), "Defias Trapper", "waiting rows should keep populated death data before reveal")
    assertEquals(Deathpool.waitingPromptHelpText:IsShown(), false, "incoming deaths should not show the no-deaths help prompt while a death is already ready")

---@diagnostic disable-next-line: need-check-nil
    Deathpool:GetScript("OnUpdate")(Deathpool, 1)
    assertEquals(Deathpool.waitingPromptText:IsShown(), false, "incoming deaths should stop the waiting prompt after the minimum duration")
    assertEquals(Deathpool.waitingPromptDots:IsShown(), false, "incoming deaths should hide the animated dots after the minimum duration")
    assertEquals(Deathpool.waitingPromptHelpText:IsShown(), false, "incoming deaths should keep the no-deaths help prompt hidden once the death log appears")
    assertEquals(Deathpool.deathRows[1]:IsShown(), true, "incoming deaths should appear once the waiting prompt minimum duration completes")
    assertEquals(Deathpool.deathRows[1].sourceName:GetText(), "Defias Trapper", "incoming deaths should render after the waiting prompt minimum duration completes")
end

local function testSuccessOnlyHistoryUsesTimestampTieBreakerForEqualScores()
    local context = createUIContext(Fixtures.uiDatabase({
        deathHistory = {},
        successfullyPredictedDeaths = {
            Fixtures.storedDeath({
                timestamp = 300,
                name = "Laterdeath",
                level = 12,
                sourceName = "Later Source",
                zone = "Elwynn Forest",
                prediction = {
                    elements = {
                        levelRange = "10-19",
                    },
                    lockedAt = 200,
                },
                predictionStreak = 1,
            }),
            Fixtures.storedDeath({
                timestamp = 100,
                name = "Earlierdeath",
                level = 12,
                sourceName = "Earlier Source",
                zone = "Elwynn Forest",
                prediction = {
                    elements = {
                        levelRange = "10-19",
                    },
                    lockedAt = 50,
                },
                predictionStreak = 1,
            }),
        },
    }))
    local DeathpoolLog = context.DeathpoolLog

    DeathpoolLog.showSuccessfulOnly = true
    DeathpoolLog:RefreshHistory()

    assertEquals(DeathpoolLog.logSubtitle:GetText(), "Successful Predictions", "success-only refresh should keep the success subtitle")
    assertEquals(DeathpoolLog.filterButton:GetText(), "SHOW ALL", "success-only refresh should offer the all-history action")
    assertEquals(DeathpoolLog.columnHeaders.time:GetText(), "Rank", "success-only refresh should relabel the first column as rank")
    assertEquals(DeathpoolLog.columnHeaders.level, nil, "success-only refresh should omit the level column")
    assertEquals(DeathpoolLog.rows[1].time:GetText(), "#1", "success-only refresh should show the first visible row as rank one")
    assertEquals(DeathpoolLog.rows[2].time:GetText(), "#2", "success-only refresh should show the second visible row as rank two")
    assertEquals(DeathpoolLog.rows[1].sourceName:GetText(), "Later Source", "success-only refresh should show the later equal-score death source first after reverse rendering")
    assertEquals(DeathpoolLog.rows[1].level, nil, "success-only refresh should not create level cells")
    assertEquals(DeathpoolLog.rows[2].sourceName:GetText(), "Earlier Source", "success-only refresh should place the earlier equal-score death source underneath after reverse rendering")
end

local function testPredictionButtons()
    local context = createUIContext({})
    local Deathpool = context.Deathpool
    local DeathpoolUI = context.DeathpoolUI
    local findDropdownButtonByText = context.findDropdownButtonByText
    local targetZone, targetZoneInput = getAutocompleteTargetValue(DeathpoolUI.ZoneList)

    assertEquals(Deathpool.lockButton:IsEnabled(), false, "lock button should start disabled with no prediction")
    Deathpool.levelRangeButtons[2]:GetScript("OnClick")(Deathpool.levelRangeButtons[2])
    assertTruthy(Deathpool.lockButton:IsEnabled(), "selecting a level range should enable the lock button")

    Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
    Deathpool.sourceEditBox:SetText("hog")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
    assertTruthy(Deathpool.dropdown:IsShown(), "typing in source should show the suggestion dropdown")
    assertEquals(Deathpool.dropdown.buttons[1].text:GetText(), "Hogger", "source dropdown should show the matching source")
    Deathpool.dropdown.buttons[1]:GetScript("OnClick")()
    assertEquals(Deathpool.sourceEditBox:GetText(), "Hogger", "clicking a source suggestion should fill the source edit box")
    assertEquals(Deathpool.dropdown:IsShown(), false, "clicking a source suggestion should hide the dropdown")
    Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
    Deathpool.sourceEditBox:SetText("a")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
    assertTruthy(Deathpool.dropdown:IsShown(), "broad source input should still show suggestions")
    Deathpool.sourceEditBox:SetText("def")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
    local defiasButton = findDropdownButtonByText(Deathpool.dropdown, "Defias Trapper")
    assertTruthy(defiasButton, "Defias Trapper suggestion should be present in the source dropdown")
---@diagnostic disable-next-line: need-check-nil
    defiasButton:GetScript("OnClick")()
    assertEquals(Deathpool.sourceEditBox:GetText(), "Defias Trapper", "clicking a source suggestion should still fill the source edit box")

    Deathpool.zoneEditBox:GetScript("OnEditFocusGained")(Deathpool.zoneEditBox)
    Deathpool.zoneEditBox:SetText(targetZoneInput)
    Deathpool.zoneEditBox:GetScript("OnTextChanged")(Deathpool.zoneEditBox, true)
    assertTruthy(Deathpool.dropdown:IsShown(), "typing in zone should show the suggestion dropdown")
    local zoneButton = findDropdownButtonByText(Deathpool.dropdown, targetZone)
    assertTruthy(zoneButton, "zone dropdown should include the matching zone")
---@diagnostic disable-next-line: need-check-nil
    zoneButton:GetScript("OnClick")()
    assertEquals(Deathpool.zoneEditBox:GetText(), targetZone, "clicking a zone suggestion should fill the zone edit box")
    Deathpool.lockButton:GetScript("OnClick")()
    assertTruthy(DeathpoolCharacterState.lockedPrediction, "locking in should save the prediction")
    assertEquals(DeathpoolCharacterState.lockedPrediction.elements.levelRange, "10-19", "locking in should store the selected level range")
    assertEquals(DeathpoolCharacterState.lockedPrediction.elements.source, "defias trapper", "locking in should store the normalized source")
    assertEquals(DeathpoolCharacterState.lockedPrediction.elements.zone, targetZoneInput, "locking in should store the normalized zone")
    assertEquals(DeathpoolCharacterState.lockedPrediction.lockedAt, 24680, "locking in should use the current timestamp")
    assertEquals(Deathpool.lockButton:IsEnabled(), false, "locking in should gray out the lock button")
    assertEquals(Deathpool.lockButton:GetText(), "LOCKED IN", "locking in should rename the lock button")
    assertEquals(Deathpool.bottomLogButton:IsEnabled(), true, "locking in should enable the log button after first run completes")
    assertEquals(Deathpool.sourceEditBox:IsEnabled(), false, "locking in should make the source edit box uneditable")
    assertEquals(Deathpool.zoneEditBox:IsEnabled(), false, "locking in should make the zone edit box uneditable")
    assertEquals(
        Deathpool.sourceEditBox.textColor[1],
        DeathpoolUI.COLORS.predictionInputLocked[1],
        "locking in should gray out the source text"
    )
    assertEquals(
        Deathpool.sourceEditBox.textColor[2],
        DeathpoolUI.COLORS.predictionInputLocked[2],
        "locking in should gray out the source text color channels"
    )
    assertEquals(
        Deathpool.zoneEditBox.textColor[1],
        DeathpoolUI.COLORS.predictionInputLocked[1],
        "locking in should gray out the location text"
    )
    assertEquals(
        Deathpool.zoneEditBox.textColor[2],
        DeathpoolUI.COLORS.predictionInputLocked[2],
        "locking in should gray out the location text color channels"
    )
    assertTruthy(Deathpool.levelRangeButtons[2]:IsEnabled(), "locking in should keep the selected level range visually active")
    assertEquals(Deathpool.levelRangeButtons[3]:IsEnabled(), false, "locking in should make other level range buttons unchangeable")
    assertTruthy(Deathpool.pauseButton:IsEnabled(), "pause button should enable after locking in")

    Deathpool.pauseButton:GetScript("OnClick")()
    assertEquals(DeathpoolCharacterState.lockedPrediction, nil, "pause should clear the locked prediction")
    assertEquals(Deathpool.sourceEditBox:GetText(), "Defias Trapper", "pause should preserve the source edit box value")
    assertEquals(Deathpool.zoneEditBox:GetText(), targetZone, "pause should preserve the zone edit box value")
    assertTruthy(Deathpool.sourceEditBox:IsEnabled(), "pause should make the source edit box editable again")
    assertTruthy(Deathpool.zoneEditBox:IsEnabled(), "pause should make the zone edit box editable again")
    assertEquals(
        Deathpool.sourceEditBox.textColor[1],
        DeathpoolUI.COLORS.predictionInputActive[1],
        "pause should restore the source text color"
    )
    assertEquals(
        Deathpool.sourceEditBox.textColor[2],
        DeathpoolUI.COLORS.predictionInputActive[2],
        "pause should restore the source text color channels"
    )
    assertEquals(
        Deathpool.zoneEditBox.textColor[1],
        DeathpoolUI.COLORS.predictionInputActive[1],
        "pause should restore the location text color"
    )
    assertEquals(
        Deathpool.zoneEditBox.textColor[2],
        DeathpoolUI.COLORS.predictionInputActive[2],
        "pause should restore the location text color channels"
    )
    assertEquals(Deathpool.levelRangeButtons[2]:IsEnabled(), false, "pause should keep the selected level button as the current selection")
    assertTruthy(Deathpool.levelRangeButtons[3]:IsEnabled(), "pause should make other level range buttons usable again")
    assertEquals(Deathpool.pauseButton:IsEnabled(), false, "pause button should disable after clearing the prediction")
    assertEquals(Deathpool.lockButton:GetText(), "LOCK IN", "pause should restore the lock button label")
    DeathpoolCharacterState.correctPredictionStreak = 4
    Deathpool.sourceEditBox:SetText("Hogger")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
    Deathpool.lockButton:GetScript("OnClick")()
    assertEquals(DeathpoolCharacterState.correctPredictionStreak, 0, "locking in a different prediction should reset the streak")
end

local function testGameInfoCalloutShowsExpectedTextForPredictionControls()
    local context = createUIContext()
    local Deathpool = context.Deathpool
    local noneLevelPointsText = "0 points"
    local levelPointsText = tostring(DeathpoolLogic.GetLevelPointsForRange("10-19")) .. " points"
    local sourcePointsText = tostring(SCORE_RULES.fixedElementPoints.source) .. " points"
    local zonePointsText = tostring(SCORE_RULES.fixedElementPoints.zone) .. " points"
    Deathpool:Show()

    assertEquals(
        hoverRegionAndWaitForGameInfoCallout(Deathpool, Deathpool.levelRangeButtons[1]),
        noneLevelPointsText,
        "hovering the none level range should show zero points"
    )
    leaveRegion(Deathpool.levelRangeButtons[1])
    assertEquals(Deathpool.gameInfoCallout:IsShown(), false, "leaving the none level range button should hide the game info callout")

    assertEquals(
        hoverRegionAndWaitForGameInfoCallout(Deathpool, Deathpool.levelRangeButtons[2]),
        levelPointsText,
        "hovering the first level range should show its points"
    )
    leaveRegion(Deathpool.levelRangeButtons[2])
    assertEquals(Deathpool.gameInfoCallout:IsShown(), false, "leaving a level range button should hide the game info callout")

    assertEquals(
        hoverRegionAndWaitForGameInfoCallout(Deathpool, Deathpool.sourceEditBox),
        sourcePointsText,
        "hovering the source input should show source points"
    )
    leaveRegion(Deathpool.sourceEditBox)

    assertEquals(
        hoverRegionAndWaitForGameInfoCallout(Deathpool, Deathpool.sourceLabel),
        sourcePointsText,
        "hovering the source label should show source points"
    )
    leaveRegion(Deathpool.sourceLabel)

    assertEquals(
        hoverRegionAndWaitForGameInfoCallout(Deathpool, Deathpool.zoneEditBox),
        zonePointsText,
        "hovering the zone input should show zone points"
    )
    leaveRegion(Deathpool.zoneEditBox)

    assertEquals(
        hoverRegionAndWaitForGameInfoCallout(Deathpool, Deathpool.zoneLabel),
        zonePointsText,
        "hovering the zone label should show zone points"
    )
    leaveRegion(Deathpool.zoneLabel)
end

local function testCurrentPredictionSummaryAnchorsBelowLocation()
    local context = createUIContext()
    local Deathpool = context.Deathpool
    local layout = context.DeathpoolUI.LAYOUT

    local titlePoint, titleRelativeTo, titleRelativePoint, titleXOffset, titleYOffset = Deathpool.currentPredictionLabel:GetPoint(1)
    assertEquals(titlePoint, "TOPLEFT", "current prediction label should anchor from its top left")
    assertEquals(titleRelativeTo, Deathpool, "current prediction label should anchor to the main frame")
    assertEquals(titleRelativePoint, "TOPLEFT", "current prediction label should use the main frame origin")
    assertEquals(titleXOffset, layout.predictionLabelX, "current prediction label should keep the label column alignment")
    assertEquals(
        titleYOffset,
        layout.predictionZoneRowY + (layout.predictionZoneRowY - layout.predictionSourceRowY),
        "current prediction label should keep the same absolute row position"
    )

    local valuePoint, valueRelativeTo, valueRelativePoint, valueXOffset, valueYOffset = Deathpool.lockedPredictionValue:GetPoint(1)
    assertEquals(valuePoint, "TOPLEFT", "current prediction text should anchor from its top left")
    assertEquals(valueRelativeTo, Deathpool.currentPredictionLabel, "current prediction text should anchor below its label")
    assertEquals(valueRelativePoint, "BOTTOMLEFT", "current prediction text should align to the label's bottom left")
    assertEquals(valueXOffset, 0, "current prediction text should stay left aligned with its label")
    assertEquals(valueYOffset, -6, "current prediction text should preserve the existing label-to-text spacing")
end

local function testGameInfoCalloutShowsExpectedTextForLabelsAndBottomButtons()
    local context = createUIContext()
    local Deathpool = context.Deathpool
    Deathpool:Show()

    local helpText = hoverRegionAndWaitForGameInfoCallout(Deathpool, Deathpool.helpButton)
    assertContains(helpText, "information", "hovering help should show help-oriented callout text")
    leaveRegion(Deathpool.helpButton)

    local logText = hoverRegionAndWaitForGameInfoCallout(Deathpool, Deathpool.bottomLogButton)
    assertContains(logText, "log", "hovering log should show log-oriented callout text")
    leaveRegion(Deathpool.bottomLogButton)

    local pauseText = hoverRegionAndWaitForGameInfoCallout(Deathpool, Deathpool.pauseButton)
    assertContains(pauseText, "Pause", "hovering pause should show pause-oriented callout text")
    leaveRegion(Deathpool.pauseButton)

    local lockText = hoverRegionAndWaitForGameInfoCallout(Deathpool, Deathpool.lockButton)
    assertContains(lockText, "game", "hovering lock in should show lock-action callout text")
    leaveRegion(Deathpool.lockButton)

    local currentPredictionLabelText = hoverRegionAndWaitForGameInfoCallout(Deathpool, Deathpool.currentPredictionLabel)
    assertContains(
        currentPredictionLabelText,
        "Bonus Multipliers",
        "hovering the current prediction label should show the bonus multipliers callout"
    )
    assertTableLength(Deathpool.gameInfoCallout.lines, 1, "empty current prediction hover should only show the title line")
    leaveRegion(Deathpool.currentPredictionLabel)

    local currentPredictionValueText = hoverRegionAndWaitForGameInfoCallout(Deathpool, Deathpool.lockedPredictionValue)
    assertContains(
        currentPredictionValueText,
        "Bonus Multipliers",
        "hovering the current prediction text should show the bonus multipliers callout"
    )
    assertTableLength(Deathpool.gameInfoCallout.lines, 1, "empty current prediction text hover should only show the title line")
    leaveRegion(Deathpool.lockedPredictionValue)
end

local function testCurrentPredictionHoverPayoutPreviewUsesDraftAndLockedPrediction()
    local context = createUIContext(Fixtures.uiDatabase({
        lockedPrediction = false,
        draftPrediction = false,
        lastPrediction = false,
    }))
    local Deathpool = context.Deathpool
    Deathpool:Show()

    Deathpool.levelRangeButtons[2]:GetScript("OnClick")(Deathpool.levelRangeButtons[2])
    Deathpool.sourceEditBox:SetText("Benny")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
    Deathpool.zoneEditBox:SetText("Westfall")
    Deathpool.zoneEditBox:GetScript("OnTextChanged")(Deathpool.zoneEditBox, true)
    local expectedDraftRows = DeathpoolLogic.GetPredictionPayoutPreviewRows(Fixtures.prediction({
        levelRange = "10-19",
        source = "benny",
        zone = "westfall",
    }))

    hoverRegionAndWaitForGameInfoCallout(Deathpool, Deathpool.currentPredictionLabel)
    assertTableLength(Deathpool.gameInfoCallout.lines, 8, "draft prediction hover should show the title plus every possible payout row")
    assertEquals(Deathpool.gameInfoCallout.lines[2].left, expectedDraftRows[1].text, "draft hover should show the level-only payout")
    assertEquals(Deathpool.gameInfoCallout.lines[3].left, expectedDraftRows[2].text, "draft hover should show the source-only payout")
    assertEquals(Deathpool.gameInfoCallout.lines[4].left, expectedDraftRows[3].text, "draft hover should show the zone-only payout")
    assertEquals(Deathpool.gameInfoCallout.lines[5].left, expectedDraftRows[4].text, "draft hover should show the level-plus-source payout")
    assertEquals(Deathpool.gameInfoCallout.lines[6].left, expectedDraftRows[5].text, "draft hover should show the level-plus-zone payout")
    assertEquals(Deathpool.gameInfoCallout.lines[7].left, expectedDraftRows[6].text, "draft hover should show the source-plus-zone payout")
    assertEquals(Deathpool.gameInfoCallout.lines[8].left, expectedDraftRows[7].text, "draft hover should show the full-match payout")
    leaveRegion(Deathpool.currentPredictionLabel)

    DeathpoolCharacterState.lockedPrediction = Fixtures.prediction({
        levelRange = "20-29",
        source = false,
        zone = false,
    })
    DeathpoolCharacterState.draftPrediction = Fixtures.prediction({
        levelRange = false,
        source = "benny",
        zone = "westfall",
    })
    local expectedLockedRows = DeathpoolLogic.GetPredictionPayoutPreviewRows(DeathpoolCharacterState.lockedPrediction)
    Deathpool:RefreshLockedPrediction()

    hoverRegionAndWaitForGameInfoCallout(Deathpool, Deathpool.lockedPredictionValue)
    assertTableLength(Deathpool.gameInfoCallout.lines, 2, "locked prediction hover should override the draft and show only its possible payout rows")
    assertEquals(Deathpool.gameInfoCallout.lines[2].left, expectedLockedRows[1].text, "locked prediction hover should use the locked payout preview")
    leaveRegion(Deathpool.lockedPredictionValue)
end

local function testGameInfoCalloutSupportsIntroDemoAndHidesWhenWindowDoes()
    local context = createUIContext()
    local DeathpoolUI = context.DeathpoolUI
    local Deathpool = context.Deathpool
    local sourcePointsText = tostring(SCORE_RULES.fixedElementPoints.source) .. " points"

    Deathpool:Show()
    Deathpool.introDemoController:Show()

    assertEquals(
        hoverRegionAndWaitForGameInfoCallout(Deathpool, Deathpool.sourceEditBox),
        sourcePointsText,
        "intro demo hover should keep the same source points text"
    )

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    assertEquals(Deathpool.gameInfoCallout:IsShown(), false, "collapsing the window should hide the game info callout")

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, false)
    hoverRegionAndWaitForGameInfoCallout(Deathpool, Deathpool.lockButton)

    Deathpool:Hide()
    assertEquals(Deathpool.gameInfoCallout:IsShown(), false, "hiding the main window should hide the game info callout")
end

local function testUnlockedDraftPredictionPersistsAcrossRefreshes()
    local context = createUIContext(Fixtures.uiDatabase({
        lockedPrediction = false,
        draftPrediction = false,
        lastPrediction = false,
    }))
    local Deathpool = context.Deathpool

    Deathpool.levelRangeButtons[4]:GetScript("OnClick")(Deathpool.levelRangeButtons[4])
    Deathpool.sourceEditBox:SetText("defias")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
    Deathpool.zoneEditBox:SetText("westfall")
    Deathpool.zoneEditBox:GetScript("OnTextChanged")(Deathpool.zoneEditBox, true)

    assertEquals(DeathpoolCharacterState.draftPrediction.elements.levelRange, "30-39", "editing a draft should store the selected level range")
    assertEquals(DeathpoolCharacterState.draftPrediction.elements.source, "defias", "editing a draft should store the normalized source")
    assertEquals(DeathpoolCharacterState.draftPrediction.elements.zone, "westfall", "editing a draft should store the normalized zone")

    Deathpool:RefreshLockedPrediction()

    assertEquals(Deathpool.selectedLevelRange, "30-39", "refresh should keep the live draft level range")
    assertEquals(Deathpool.sourceEditBox:GetText(), "Defias", "refresh should keep the live draft source text")
    assertEquals(Deathpool.zoneEditBox:GetText(), "Westfall", "refresh should keep the live draft zone text")

    Deathpool.levelRangeButtons[1]:GetScript("OnClick")(Deathpool.levelRangeButtons[1])
    Deathpool.sourceEditBox:SetText("")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
    Deathpool.zoneEditBox:SetText("")
    Deathpool.zoneEditBox:GetScript("OnTextChanged")(Deathpool.zoneEditBox, true)

    assertEquals(DeathpoolCharacterState.draftPrediction, nil, "clearing every draft input should clear the stored draft")

    Deathpool:RefreshLockedPrediction()

    assertEquals(Deathpool.selectedLevelRange, "None", "refresh should keep the cleared level range")
    assertEquals(Deathpool.sourceEditBox:GetText(), "", "refresh should keep the cleared source text")
    assertEquals(Deathpool.zoneEditBox:GetText(), "", "refresh should keep the cleared zone text")
    assertEquals(Deathpool.lockButton:IsEnabled(), false, "refresh should keep locking disabled when the draft is empty")
end

local function testZeroScoreDeathDisplaysOnlyTotalPointsInMainWindow()
    local context = createUIContext(Fixtures.uiDatabase({
        totalPoints = 0,
        recentDeaths = {
            Fixtures.storedDeath({
                points = 0,
                multiplierValue = 0,
                awardedPoints = 0,
                matchedPrediction = false,
                prediction = false,
                predictionStreak = false,
            }),
        },
        deathHistory = {},
    }))
    local Deathpool = context.Deathpool

    Deathpool:RefreshDeaths()
    Deathpool:RefreshCollapsedSummary(DeathpoolCharacterState.recentDeaths[1])

    assertEquals(Deathpool.deathRows[1].pointsTooltipTarget, nil, "recent death rows should omit the removed base points hover target")
    assertEquals(Deathpool.deathRows[1].multiplier, nil, "recent death rows should omit the removed combo column")
    assertEquals(Deathpool.deathRows[1].streakMultiplier, nil, "recent death rows should omit the removed streak column")
    assertEquals(Deathpool.deathRows[1].awardedPoints:GetText(), "0", "recent death rows should show zero total points in the points column")
    assertEquals(Deathpool.collapsedLogFrame.rows[1].sourceName:GetText(), "Hogger", "collapsed death log should still render zero-score deaths")
    assertEquals(Deathpool.collapsedPointsValue:GetText(), "0", "collapsed score should still show zero totals")

    assertEquals(Deathpool.deathRows[1]:GetScript("OnEnter"), nil, "zero-score recent death rows should still avoid whole-row tooltips")
    hoverDeathLogCell(Deathpool.deathRows[1], "awardedPoints")
    do
        local streakIndex = findTooltipLineIndex("Streak:")
        local sameZoneIndex = findTooltipLineIndex("Same zone:")
        local totalIndex = findTooltipLineIndex("Total:")
        local scoreIndex = findTooltipLineIndex("Score:")
        assertTruthy(sameZoneIndex == nil, "zero-score tooltip should omit the same-zone row when there is no bonus")
        assertTruthy(streakIndex == nil, "zero-score tooltip should omit the streak row when there is no streak bonus")
        assertTruthy(totalIndex == nil, "zero-score tooltip should omit the total row")
        assertTruthy(scoreIndex ~= nil, "zero-score tooltip should include the score row")
        if scoreIndex ~= nil then
            assertEquals(GameTooltip.lines[scoreIndex].right, "0", "zero-score tooltip should collapse the score formula to the awarded points when the multiplier is zero")
        end
    end
    leaveDeathLogCell(Deathpool.deathRows[1], "awardedPoints")
end

local function testCollapsedDeathLogShowsNewestRecentDeathsAtBottom()
    local context = createUIContext(Fixtures.uiDatabase({
        recentDeaths = {
            Fixtures.storedDeath({
                timestamp = 90,
                name = "Alamo",
                level = 11,
                sourceName = "Defias",
                zone = "Westfall",
                matchedPrediction = false,
                prediction = false,
                predictionStreak = false,
                points = 0,
                multiplierValue = 0,
                awardedPoints = 0,
            }),
            Fixtures.storedDeath({
                timestamp = 100,
                name = "Drakedog",
                level = 12,
                sourceName = "Hogger",
                zone = "Elwynn Forest",
            }),
        },
        deathHistory = {},
    }))
    local Deathpool = context.Deathpool

    Deathpool:RefreshDeaths()
    Deathpool:RefreshCollapsedSummary()

    assertEquals(Deathpool.collapsedLogFrame.rows[1].sourceName:GetText(), "Defias", "collapsed death log should keep older recent deaths above newer ones")
    assertEquals(Deathpool.collapsedLogFrame.rows[2].sourceName:GetText(), "Hogger", "collapsed death log should keep the newest stored recent death at the bottom")
end

local function testFlexibleDeathLogListSupportsCustomColumns()
    local context = createUIContext()
    local DeathpoolUI = context.DeathpoolUI

    local flexibleLog = CreateFrame("Frame", nil, UIParent)
    local customColumns = {
        { key = "name", label = "Name", x = 8, width = 80 },
        { key = "awardedPoints", label = "Total", x = 96, width = 40 },
    }
    local newestDeath = Fixtures.storedDeath({
        timestamp = 200,
        name = "Greymist",
        awardedPoints = 7,
        points = 7,
        multiplierValue = 1,
    })
    local olderDeath = Fixtures.storedDeath({
        timestamp = 150,
        name = "Alamo",
        awardedPoints = 0,
        points = 0,
        multiplierValue = 0,
        matchedPrediction = false,
        prediction = false,
        predictionStreak = false,
    })

    DeathpoolUI.CreateDeathLogList(flexibleLog, {
        columns = customColumns,
        rowCount = 2,
        rowHeight = 18,
        rowLeft = 0,
        rowTop = 0,
        rowRight = 0,
        tooltipOptions = {
            showPredictionString = true,
            showIdentity = true,
            showFullCombos = true,
        },
    })
    DeathpoolUI.RefreshDeathLogRows(flexibleLog, {
        olderDeath,
        newestDeath,
    }, {
        columns = customColumns,
        reverseOrder = true,
    })

    assertTableLength(flexibleLog.rows, 2, "flexible death log should create the requested number of rows")
    assertEquals(flexibleLog.rows[1].name:GetText(), "Greymist", "flexible death log should render the newest row first when requested")
    assertEquals(
        flexibleLog.rows[1].awardedPoints:GetText(),
        tostring(DeathpoolLogic.GetStoredDeathAwardedPoints(newestDeath)),
        "flexible death log should render computed column values"
    )
    assertEquals(flexibleLog.rows[2].name:GetText(), "Alamo", "flexible death log should continue rendering older rows underneath")

    flexibleLog.rows[1]:GetScript("OnEnter")(flexibleLog.rows[1])
    assertEquals(GameTooltip.lines[1].left, "Level 10-19, source Hogger, or zone Elwynn Forest.", "flexible death log should reuse the history tooltip behavior")
    assertTruthy(findTooltipLineIndex("Name:") == nil, "flexible death log should omit the dead player name from the tooltip")
    assertEquals(GameTooltip.lines[2].left, "Level:", "flexible death log should reuse identity rows in the tooltip")
    flexibleLog.rows[1]:GetScript("OnLeave")()
    assertEquals(GameTooltip.visible, false, "leaving a flexible death log row should hide the tooltip")
end

local function testDeathLogListSupportsForwardOrderingAndClearsUnusedRows()
    local context = createUIContext()
    local DeathpoolUI = context.DeathpoolUI

    local flexibleLog = CreateFrame("Frame", nil, UIParent)
    local customColumns = {
        { key = "name", label = "Name", x = 0, width = 80 },
        { key = "level", label = "Level", x = 84, width = 24 },
    }

    DeathpoolUI.CreateDeathLogList(flexibleLog, {
        columns = customColumns,
        rowCount = 3,
        rowHeight = 18,
        rowLeft = 0,
        rowTop = 0,
        rowRight = 0,
        tooltipOptions = DeathpoolUI.MAIN_LOG_TOOLTIP_OPTIONS,
    })

    local deaths = {
        Fixtures.storedDeath({
            timestamp = 10,
            name = "Firstdeath",
            level = 10,
        }),
        Fixtures.storedDeath({
            timestamp = 20,
            name = "Seconddeath",
            level = 20,
        }),
        Fixtures.storedDeath({
            timestamp = 30,
            name = "Thirddeath",
            level = 30,
        }),
    }

    DeathpoolUI.RefreshDeathLogRows(flexibleLog, deaths, {
        columns = customColumns,
        offset = 1,
        reverseOrder = false,
    })

    assertEquals(flexibleLog.rows[1].name:GetText(), "Seconddeath", "forward-ordered log should honor the provided offset")
    assertEquals(flexibleLog.rows[2].name:GetText(), "Thirddeath", "forward-ordered log should continue into later rows")
    assertEquals(flexibleLog.rows[3]:IsShown(), false, "forward-ordered log should hide rows with no matching death")
    assertEquals(flexibleLog.rows[3].name:GetText(), "", "forward-ordered log should clear text from unused rows")
end

local function testDeathLogListTooltipOptionsCanSwitchContexts()
    local context = createUIContext()
    local DeathpoolUI = context.DeathpoolUI

    local customColumns = {
        { key = "name", label = "Name", x = 0, width = 80 },
        { key = "sourceName", label = "Source", x = 84, width = 80 },
        { key = "awardedPoints", label = "Total", x = 168, width = 36 },
    }
    local death = Fixtures.storedDeath()

    local mainLog = CreateFrame("Frame", nil, UIParent)
    DeathpoolUI.CreateDeathLogList(mainLog, {
        columns = customColumns,
        rowCount = 1,
        rowHeight = 18,
        rowLeft = 0,
        rowTop = 0,
        rowRight = 0,
        tooltipOptions = DeathpoolUI.MAIN_LOG_TOOLTIP_OPTIONS,
    })
    DeathpoolUI.RefreshDeathLogRows(mainLog, {
        death,
    }, {
        columns = customColumns,
        reverseOrder = false,
    })

    assertEquals(mainLog.rows[1]:GetScript("OnEnter"), nil, "main log tooltip options should disable whole-row hover when metric-only targets are enabled")
    hoverDeathLogCell(mainLog.rows[1], "awardedPoints")
    assertEquals(GameTooltip.lines[1].left, "Base points:", "main log tooltip options should start with scoring rows in compact mode")
    assertTruthy(findTooltipLineIndex("Name:") == nil, "main log tooltip options should omit identity rows in compact mode")
    assertTruthy(findTooltipLineIndex("Level 10-19, source Hogger, or zone Elwynn Forest.") == nil, "main log tooltip options should omit prediction text in compact mode")
    leaveDeathLogCell(mainLog.rows[1], "awardedPoints")

    local logWindowLog = CreateFrame("Frame", nil, UIParent)
    DeathpoolUI.CreateDeathLogList(logWindowLog, {
        columns = customColumns,
        rowCount = 1,
        rowHeight = 18,
        rowLeft = 0,
        rowTop = 0,
        rowRight = 0,
        tooltipOptions = DeathpoolUI.LOG_WINDOW_TOOLTIP_OPTIONS,
    })
    DeathpoolUI.RefreshDeathLogRows(logWindowLog, {
        death,
    }, {
        columns = customColumns,
        reverseOrder = false,
    })

    assertEquals(logWindowLog.rows[1]:GetScript("OnEnter"), nil, "log window tooltip options should disable whole-row hover when points-only targets are enabled")
    assertNoDeathLogCellTooltipTarget(logWindowLog.rows[1], "name", "log window tooltip options should not create a name-column tooltip target")
    hoverDeathLogCell(logWindowLog.rows[1], "awardedPoints")
    assertEquals(GameTooltip.lines[1].left, "Level 10-19, source Hogger, or zone Elwynn Forest.", "log window tooltip options should start with the prediction text")
    assertTruthy(findTooltipLineIndex("Name:") == nil, "log window tooltip options should omit the dead player name")
    assertEquals(GameTooltip.lines[2].left, "Level:", "log window tooltip options should include level before base points")
    leaveDeathLogCell(logWindowLog.rows[1], "awardedPoints")

    local collapsedStyleLog = CreateFrame("Frame", nil, UIParent)
    DeathpoolUI.CreateDeathLogList(collapsedStyleLog, {
        columns = customColumns,
        rowCount = 1,
        rowHeight = 18,
        rowLeft = 0,
        rowTop = 0,
        rowRight = 0,
        tooltipOptions = DeathpoolUI.COLLAPSED_LOG_TOOLTIP_OPTIONS,
    })
    DeathpoolUI.RefreshDeathLogRows(collapsedStyleLog, {
        death,
    }, {
        columns = customColumns,
        reverseOrder = false,
    })

    assertEquals(collapsedStyleLog.rows[1]:GetScript("OnEnter"), nil, "collapsed log tooltip options should disable whole-row hover when points-only targets are enabled")
    assertNoDeathLogCellTooltipTarget(collapsedStyleLog.rows[1], "name", "collapsed log tooltip options should not create a name-column tooltip target")
    assertNoDeathLogCellTooltipTarget(collapsedStyleLog.rows[1], "sourceName", "collapsed log tooltip options should not create a source-column tooltip target")
    hoverDeathLogCell(collapsedStyleLog.rows[1], "awardedPoints")
    assertEquals(GameTooltip.lines[1].left, "Base points:", "collapsed log tooltip options should start with scoring rows in compact mode")
    assertTruthy(findTooltipLineIndex("Name:") == nil, "collapsed log tooltip options should omit identity rows in compact mode")
    assertTruthy(findTooltipLineIndex("Level 10-19, source Hogger, or zone Elwynn Forest.") == nil, "collapsed log tooltip options should omit prediction text in compact mode")
    leaveDeathLogCell(collapsedStyleLog.rows[1], "awardedPoints")

    local historyStyleLog = CreateFrame("Frame", nil, UIParent)
    DeathpoolUI.CreateDeathLogList(historyStyleLog, {
        columns = customColumns,
        rowCount = 1,
        rowHeight = 18,
        rowLeft = 0,
        rowTop = 0,
        rowRight = 0,
        tooltipOptions = {
            showPredictionString = true,
            showIdentity = true,
            showFullCombos = true,
        },
    })
    DeathpoolUI.RefreshDeathLogRows(historyStyleLog, {
        death,
    }, {
        columns = customColumns,
        reverseOrder = false,
    })

    assertTruthy(type(historyStyleLog.rows[1]:GetScript("OnEnter")) == "function", "history tooltip options should keep whole-row hover enabled")
    assertNoDeathLogCellTooltipTarget(historyStyleLog.rows[1], "awardedPoints", "history tooltip options should not create a points-column tooltip target")
    historyStyleLog.rows[1]:GetScript("OnEnter")(historyStyleLog.rows[1])
    assertEquals(GameTooltip.lines[1].left, "Level 10-19, source Hogger, or zone Elwynn Forest.", "history tooltip options should start with the prediction text")
    assertTruthy(findTooltipLineIndex("Name:") == nil, "history tooltip options should omit the dead player name")
    assertEquals(GameTooltip.lines[2].left, "Level:", "history tooltip options should still include level before base points")
    historyStyleLog.rows[1]:GetScript("OnLeave")()
end

local function testRepeatedRefreshesReuseLogDisplayCaches()
    local recentOlder = Fixtures.storedDeath({
        timestamp = 100,
        name = "Recentolder",
    })
    local recentNewer = Fixtures.storedDeath({
        timestamp = 200,
        name = "Recentnewer",
    })
    local historyOnly = Fixtures.storedDeath({
        timestamp = 90,
        name = "Historyonly",
        matchedPrediction = false,
        prediction = false,
        predictionStreak = false,
        points = 0,
        awardedPoints = 0,
    })
    local sharedSuccess = Fixtures.storedDeath({
        timestamp = 300,
        name = "Sharedsuccess",
    })
    local context = createUIContext(Fixtures.uiDatabase({
        recentDeaths = {
            recentOlder,
            recentNewer,
        },
        deathHistory = {
            historyOnly,
            sharedSuccess,
        },
        successfullyPredictedDeaths = {
            sharedSuccess,
        },
    }))
    local Deathpool = context.Deathpool
    local DeathpoolLog = context.DeathpoolLog
    local displayCache = Deathpool.displayCache

    Deathpool:RefreshDeaths()
    Deathpool:RefreshCollapsedSummary()
    DeathpoolLog.showSuccessfulOnly = false
    DeathpoolLog:RefreshHistory()
    DeathpoolLog.showSuccessfulOnly = true
    DeathpoolLog:RefreshHistory()

    local recentViewEntries = displayCache.recentView.orderedEntries
    local historyViewEntries = displayCache.historyView.orderedEntries
    local successfulViewEntries = displayCache.successfulView.orderedEntries
    local recentOlderEntry = displayCache.entriesByDeath[recentOlder]
    local sharedSuccessEntry = displayCache.entriesByDeath[sharedSuccess]
    local historyOnlyEntry = displayCache.entriesByDeath[historyOnly]

    Deathpool:RefreshDeaths()
    Deathpool:RefreshCollapsedSummary()
    DeathpoolLog.showSuccessfulOnly = false
    DeathpoolLog:RefreshHistory()
    DeathpoolLog.showSuccessfulOnly = true
    DeathpoolLog:RefreshHistory()

    assertEquals(displayCache.recentView.orderedEntries, recentViewEntries, "recent log should reuse the cached ordered entries on repeated refresh")
    assertEquals(displayCache.historyView.orderedEntries, historyViewEntries, "all-history log should reuse the cached ordered entries on repeated refresh")
    assertEquals(displayCache.successfulView.orderedEntries, successfulViewEntries, "success-only log should reuse the cached ordered entries on repeated refresh")
    assertEquals(displayCache.entriesByDeath[recentOlder], recentOlderEntry, "recent log should reuse the cached shared entry for existing deaths")
    assertEquals(displayCache.entriesByDeath[sharedSuccess], sharedSuccessEntry, "success-only log should reuse the cached shared entry for existing deaths")
    assertEquals(displayCache.entriesByDeath[historyOnly], historyOnlyEntry, "all-history log should reuse the cached shared entry for existing deaths")
end

local function testLogDisplayCacheKeepsSharedEntriesForSession()
    local recentRemoved = Fixtures.storedDeath({
        timestamp = 100,
        name = "Recentremoved",
    })
    local recentKept = Fixtures.storedDeath({
        timestamp = 200,
        name = "Recentkept",
    })
    local recentNewest = Fixtures.storedDeath({
        timestamp = 300,
        name = "Recentnewest",
    })
    local historyOnly = Fixtures.storedDeath({
        timestamp = 90,
        name = "Historyonly",
        matchedPrediction = false,
        prediction = false,
        predictionStreak = false,
        points = 0,
        awardedPoints = 0,
    })
    local sharedSuccess = Fixtures.storedDeath({
        timestamp = 400,
        name = "Sharedsuccess",
    })
    local context = createUIContext(Fixtures.uiDatabase({
        recentDeaths = {
            recentRemoved,
            recentKept,
        },
        deathHistory = {
            historyOnly,
            sharedSuccess,
        },
        successfullyPredictedDeaths = {
            sharedSuccess,
        },
    }))
    local Deathpool = context.Deathpool
    local DeathpoolLog = context.DeathpoolLog
    local displayCache = Deathpool.displayCache

    Deathpool:RefreshDeaths()
    DeathpoolLog.showSuccessfulOnly = false
    DeathpoolLog:RefreshHistory()
    DeathpoolLog.showSuccessfulOnly = true
    DeathpoolLog:RefreshHistory()

    assertTruthy(displayCache.entriesByDeath[recentRemoved] ~= nil, "recent cache should create an entry for the oldest recent death before trimming")
    assertTruthy(displayCache.entriesByDeath[historyOnly] ~= nil, "history cache should create an entry for all-history-only deaths")
    assertTruthy(displayCache.entriesByDeath[sharedSuccess] ~= nil, "history and success views should share the same cached death entry")

    DeathpoolCharacterState.recentDeaths = {
        recentKept,
        recentNewest,
    }
    Deathpool:RefreshDeaths()

    assertTruthy(displayCache.entriesByDeath[recentRemoved] ~= nil, "recent cache should keep trimmed entries in the shared session cache")
    assertTruthy(displayCache.entriesByDeath[recentKept] ~= nil, "recent cache should keep entries still visible in the recent log")
    assertTruthy(displayCache.entriesByDeath[recentNewest] ~= nil, "recent cache should add entries appended to the recent log")

    DeathpoolCharacterState.deathHistory = {
        sharedSuccess,
    }
    DeathpoolLog.showSuccessfulOnly = false
    DeathpoolLog:RefreshHistory()

    assertTruthy(displayCache.entriesByDeath[historyOnly] ~= nil, "all-history cache should keep removed entries in the shared session cache")
    assertTruthy(displayCache.entriesByDeath[sharedSuccess] ~= nil, "shared success entries should remain cached while the success view still references them")

    DeathpoolCharacterState.deathHistory = {}
    DeathpoolLog.showSuccessfulOnly = false
    DeathpoolLog:RefreshHistory()
    assertTruthy(displayCache.entriesByDeath[sharedSuccess] ~= nil, "shared success entries should stay cached even after leaving all-history when success-only still references them")

    DeathpoolCharacterState.successfullyPredictedDeaths = {}
    DeathpoolLog.showSuccessfulOnly = true
    DeathpoolLog:RefreshHistory()

    assertTruthy(displayCache.entriesByDeath[sharedSuccess] ~= nil, "shared success entries should stay cached for the rest of the session")
    assertEquals(displayCache.historyView.orderedEntries[1], nil, "all-history view should rebuild from the current source list after removals")
    assertEquals(displayCache.successfulView.orderedEntries[1], nil, "success-only view should rebuild from the current source list after removals")
end

testRefreshMethods()
testTooltipUsesGreenForPositiveStreakRow()
testPredictionOnlyTooltipUsesPreviewStreakByDefault()
testTooltipHidesLowValueMultiplierRows()
testRefreshLockedPredictionRestoresReloadedPaneState()
testRefreshMethodsPreferIntroDemoStateOverLiveDatabase()
testRefreshLockedPredictionRestoresInputsAndPauseButtonState()
testRefreshLockedPredictionHandlesEmptyState()
testEmptyPredictionPromptReplacesMainDeathLogUntilPredictionSelected()
testSetupWindowShowsBothIncompleteSetupItems()
testSetupCloseButtonBlocksNewCharacters()
testSetupCloseButtonBlocksBeforeFirstPrediction()
testSetupCloseButtonClosesForDeathpoolPlayers()
testSetupWindowEnableChecksOnlyDeathAnnouncementItem()
testSetupWindowJoinChecksOnlyChannelItem()
testSetupWindowShowsPrecompletedDeathAnnouncements()
testSetupWindowCompletedSetupAdvancesToPrediction()
testReturningPlayersDoNotSeeFirstRunPrompt()
testWaitingForFirstDeathNotificationUsesSharedPromptPane()
testWaitingForFirstDeathNotificationRestoresAfterMinimize()
testWaitingForFirstDeathNotificationStaysVisibleForMinimumDuration()
testSuccessOnlyHistoryUsesTimestampTieBreakerForEqualScores()
testPredictionButtons()
testGameInfoCalloutShowsExpectedTextForPredictionControls()
testCurrentPredictionSummaryAnchorsBelowLocation()
testGameInfoCalloutShowsExpectedTextForLabelsAndBottomButtons()
testCurrentPredictionHoverPayoutPreviewUsesDraftAndLockedPrediction()
testGameInfoCalloutSupportsIntroDemoAndHidesWhenWindowDoes()
testUnlockedDraftPredictionPersistsAcrossRefreshes()
testZeroScoreDeathDisplaysOnlyTotalPointsInMainWindow()
testCollapsedDeathLogShowsNewestRecentDeathsAtBottom()
testFlexibleDeathLogListSupportsCustomColumns()
testDeathLogListSupportsForwardOrderingAndClearsUnusedRows()
testDeathLogListTooltipOptionsCanSwitchContexts()
testRepeatedRefreshesReuseLogDisplayCaches()
testLogDisplayCacheKeepsSharedEntriesForSession()

suite:finish()

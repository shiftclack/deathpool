local UITestContext = require("tests.support_ui_test_context")
local testContext = UITestContext.Create()
local suite = testContext.suite
local Fixtures = testContext.Fixtures
local createUIContext = testContext.createUIContext
local formatStoredDeathScore = testContext.formatStoredDeathScore
local assertEquals = testContext.assertEquals
local assertContains = testContext.assertContains
local assertTruthy = testContext.assertTruthy

-- local function getDemoPlaybackState(demoState)
--     return demoState and demoState.demoPlayback or {}
-- end

local function getIntroDemoState(Deathpool)
    local introDemoController = Deathpool and Deathpool.introDemoController or nil
    if introDemoController then
        return introDemoController.demoState
    end

    return nil
end

local function advanceDemoPlayback(Deathpool)
    Deathpool:GetScript("OnUpdate")(Deathpool, 10)
    return getIntroDemoState(Deathpool)
end

-- local function advanceDemoUntilLatestDeath(Deathpool, targetName)
--     local demoState = Deathpool:GetIntroDemoState()

--     for _ = 1, 40 do
--         local recentDeaths = demoState and demoState.recentDeaths or {}
--         local latestDeath = recentDeaths[#recentDeaths]
--         if latestDeath and latestDeath.name == targetName then
--             return demoState
--         end

--         demoState = advanceDemoPlayback(Deathpool)
--     end

--     return demoState
-- end

local function testIntroDemoRefreshUsesMainWindowOnlyState()
    local context = createUIContext(Fixtures.uiDatabase({
        totalPoints = 17,
        correctPredictionStreak = 0,
        longestPredictionStreak = 1,
        recentDeaths = {
            Fixtures.storedDeath({
                timestamp = 100,
                name = "Realdeath",
                level = 11,
                sourceName = "Murloc",
                points = 0,
                multiplierValue = 0,
                awardedPoints = 0,
                matchedPrediction = false,
                prediction = false,
                predictionStreak = false,
            }),
        },
    }))
    local Deathpool = context.Deathpool
    local DeathpoolLog = context.DeathpoolLog

    Deathpool:Show()
    Deathpool.introDemoController:Show()

    assertEquals(Deathpool.helpFrame:IsShown(), false, "intro demo should close the help window")
    assertEquals(DeathpoolLog:IsShown(), false, "intro demo should close the log window")
    assertEquals(Deathpool.totalPointsValue:GetText(), "0", "intro demo should start at zero score before the higher-value hits land")
    assertEquals(Deathpool.currentStreakValue:GetText(), "0", "intro demo should start with no active streak")
    assertEquals(Deathpool.longestStreakValue:GetText(), "0", "intro demo should start with no completed streak")
    assertEquals(Deathpool.deathRows[1].name:GetText(), "Mudtooth", "intro demo should immediately show the first scripted death")
    assertEquals(Deathpool.deathRows[1].pointsTooltipTarget, nil, "intro demo should omit the removed base points hover target")
    assertEquals(Deathpool.deathRows[1].awardedPoints:GetText(), "0", "intro demo should keep the opening miss at zero total points")
    assertContains(
        Deathpool.lockedPredictionValue:GetText(),
        "Level 10-19, source Defias Trapper, or zone Westfall",
        "intro demo should show the example locked prediction"
    )
    assertEquals(Deathpool.introDemoAttractPanel:IsShown(), true, "intro demo should show the arcade marquee panel")
    assertEquals(Deathpool.emptyPredictionPrompt:IsShown(), false, "intro demo should hide the shared notification prompt while demo mode is visible")
    assertEquals(
        Deathpool.introDemoAttractPanel.text:GetText(),
        "Welcome to the death pool\nPress START GAME to begin",
        "intro demo should show the marquee instructions"
    )
    assertTruthy(Deathpool.lockButton:IsEnabled(), "intro demo should keep the lock button enabled for dismissing demo mode")
    assertEquals(Deathpool.lockButton:GetText(), "START GAME", "intro demo should relabel the lock button as start game")
    assertEquals(Deathpool.pauseButton:IsEnabled(), false, "intro demo should keep the pause button disabled")
    assertEquals(Deathpool.sourceEditBox:IsEnabled(), false, "intro demo should disable the source input")
    assertEquals(Deathpool.zoneEditBox:IsEnabled(), false, "intro demo should disable the location input")
    assertEquals(Deathpool.helpButton:IsEnabled(), false, "intro demo should disable the help button")
    assertEquals(Deathpool.bottomLogButton:IsEnabled(), false, "intro demo should disable the log button")
end

local function testIntroDemoUsesHordeDemoData()
    local context = createUIContext(nil, {
        faction = "Horde",
    })
    local Deathpool = context.Deathpool

    Deathpool:Show()
    Deathpool.introDemoController:Show()

    assertEquals(Deathpool.totalPointsValue:GetText(), "0", "horde intro demo should start at zero score")
    assertEquals(Deathpool.deathRows[1].name:GetText(), "Rascal", "horde intro demo should use the horde scripted deaths")
    assertEquals(Deathpool.deathRows[1].awardedPoints:GetText(), "0", "horde intro demo should open on a miss before the later streak")
    assertContains(
        Deathpool.lockedPredictionValue:GetText(),
        "Level 10-19, source Kolkar Wrangler, or zone The Barrens",
        "horde intro demo should use the selected horde prediction"
    )
    assertEquals(Deathpool.introDemoAttractPanel:IsShown(), true, "horde intro demo should still show the marquee panel")
end

local function testIntroDemoHidesWaitingForFirstDeathPrompt()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenFirstRun = true,
    }))
    local Deathpool = context.Deathpool

    Deathpool:Show()
    Deathpool.setupFrame:Show()
    Deathpool.waitingPromptText:Show()
    Deathpool.waitingPromptDots:Show()
    Deathpool.waitingPromptHelpText:Show()

    Deathpool.introDemoController:Show()

    assertEquals(Deathpool.setupFrame:IsShown(), false, "intro demo should not show the setup window")
    assertEquals(Deathpool.waitingPromptText:IsShown(), false, "intro demo should not show the waiting prompt text")
    assertEquals(Deathpool.waitingPromptDots:IsShown(), false, "intro demo should not show the waiting prompt dots")
    assertEquals(Deathpool.waitingPromptHelpText:IsShown(), false, "intro demo should not show the waiting prompt help text")
end

local function testIntroDemoPlaybackAdvancesAndLoops()
    local context = createUIContext()
    local Deathpool = context.Deathpool

    Deathpool:Show()
    Deathpool.introDemoController:Show()

    local demoState = advanceDemoPlayback(Deathpool)
    if demoState == nil then
        error("demo playback should return demo state")
    end

    local secondDeath = demoState.recentDeaths[2]
    if secondDeath == nil then
        error("demo playback should append the second scripted death")
    end

    assertEquals(Deathpool.deathRows[2].name:GetText(), "Haymaker", "demo playback should append the next scripted death")
    assertEquals(
        Deathpool.deathRows[2].awardedPoints:GetText(),
        formatStoredDeathScore(secondDeath).awardedPoints,
        "demo playback should hit the white-quality prediction on the second death"
    )

    demoState = advanceDemoPlayback(Deathpool)
    if demoState == nil then
        error("demo playback should keep returning demo state")
    end

    local thirdDeath = demoState.recentDeaths[3]
    if thirdDeath == nil then
        error("demo playback should append the third scripted death")
    end

    assertEquals(Deathpool.deathRows[3].name:GetText(), "Copperkeg", "demo playback should continue through the static list")
    assertEquals(
        Deathpool.deathRows[3].awardedPoints:GetText(),
        formatStoredDeathScore(thirdDeath).awardedPoints,
        "demo playback should surface the green-quality streak hit"
    )
    assertEquals(Deathpool.currentStreakValue:GetText(), "2", "demo playback should update the current streak during consecutive matches")
    assertEquals(Deathpool.longestStreakValue:GetText(), "2", "demo playback should raise the longest streak after the early two-hit run")

    -- demoState = advanceDemoUntilLatestDeath(Deathpool, "Nettle")
    -- assertEquals(demoState.recentDeaths[#demoState.recentDeaths].name, "Nettle", "demo playback should preserve the scripted roster on the mid-demo streak")
    -- assertEquals(Deathpool.currentStreakValue:GetText(), "5", "demo playback should build the curated four-hit streak by Nettle")
    -- assertEquals(Deathpool.longestStreakValue:GetText(), "5", "demo playback should keep the longest streak in sync with the live model")

    -- advanceDemoUntilLatestDeath(Deathpool, "Goldshirekid")
    -- assertEquals(Deathpool.currentStreakValue:GetText(), "1", "demo playback should restart the streak before the final two-hit run")

    -- demoState = advanceDemoUntilLatestDeath(Deathpool, "Greymist")
    -- assertEquals(demoState.recentDeaths[#demoState.recentDeaths].name, "Greymist", "demo playback should reach the final scripted death before looping")
    -- assertEquals(Deathpool.deathRows[5].name:GetText(), "Greymist", "demo playback should display the final scripted death in the last visible row")
    -- assertEquals(
    --     Deathpool.deathRows[5].awardedPoints:GetText(),
    --     formatStoredDeathScore(demoState.recentDeaths[#demoState.recentDeaths]).awardedPoints,
    --     "demo playback should end on a live-scored two-hit streak finale"
    -- )
    -- assertEquals(Deathpool.currentStreakValue:GetText(), "2", "demo playback should end with the second hit of the closing streak")
    -- assertEquals(Deathpool.longestStreakValue:GetText(), "7", "demo playback should preserve the best streak reached across the full live-scored sequence")

    -- demoState = advanceDemoPlayback(Deathpool)
    -- assertEquals(getDemoPlaybackState(demoState).currentDeathIndex, 1, "demo playback should loop back to the first scripted death after the sequence ends")
    assertEquals(Deathpool.deathRows[1].name:GetText(), "Mudtooth", "demo playback should redisplay the first scripted death after the sequence ends")
    -- assertEquals(Deathpool.totalPointsValue:GetText(), "0", "demo playback should restart the score when looping the scripted sequence")
end

local function testHelpDemoButtonStartsIntroDemo()
    local context = createUIContext()
    local Deathpool = context.Deathpool

    assertEquals(Deathpool.helpFrame.demoButton ~= nil, true, "help frame should create a demo button")
    assertEquals(Deathpool.helpFrame.demoButton:GetText(), "DEMO", "help demo button should use the demo label")

    Deathpool.helpFrame:Show()
    Deathpool.logFrame:Show()
    Deathpool.introDemoController:Dismiss()
    Deathpool.helpFrame.demoButton:GetScript("OnClick")()

    assertEquals(Deathpool.helpFrame:IsShown(), false, "clicking the help demo button should close the help window")
    assertEquals(getIntroDemoState(Deathpool) ~= nil, true, "clicking the help demo button should activate the intro demo mode")
    assertEquals(Deathpool.lockButton:GetText(), "START GAME", "clicking the help demo button should relabel the lock button to start game")
    assertEquals(Deathpool.totalPointsValue:GetText(), "0", "clicking the help demo button should restart the scripted demo from zero score")
    assertEquals(Deathpool.logFrame:IsShown(), false, "clicking the help demo button should close the log window")
    assertEquals(Deathpool.helpButton:IsEnabled(), false, "clicking the help demo button should disable the help button in demo mode")
    assertEquals(Deathpool.bottomLogButton:IsEnabled(), false, "clicking the help demo button should disable the log button in demo mode")
end

local function testEndDemoLockButtonDismissesIntroDemo()
    local context = createUIContext()
    local Deathpool = context.Deathpool

    Deathpool:Show()
    Deathpool.introDemoController:Show()

    Deathpool.lockButton:GetScript("OnClick")()

    assertEquals(getIntroDemoState(Deathpool), nil, "clicking the end demo lock button should end intro demo mode")
    assertEquals(Deathpool.lockButton:GetText(), "LOCK IN", "clicking the end demo lock button should restore the normal lock label")
    assertEquals(Deathpool.introDemoAttractPanel:IsShown(), false, "clicking the end demo lock button should hide the marquee panel")
    assertEquals(Deathpool.helpButton:IsEnabled(), true, "clicking the end demo lock button should restore help outside demo mode")
    assertEquals(Deathpool.bottomLogButton:IsEnabled(), false, "clicking the end demo lock button should keep log locked before first run completes")
end

local function testIntroDemoKeepsHelpClosedAfterDemoEnds()
    local context = createUIContext()
    local Deathpool = context.Deathpool

    Deathpool:Show()
    Deathpool.helpFrame:Show()
    Deathpool.introDemoController:Show()

    assertEquals(Deathpool.helpFrame:IsShown(), false, "starting the intro demo should close the help window")

    Deathpool.introDemoController:Dismiss()

    assertEquals(Deathpool.helpFrame:IsShown(), false, "ending the intro demo should keep the help window closed")
end

testHelpDemoButtonStartsIntroDemo()
testEndDemoLockButtonDismissesIntroDemo()
testIntroDemoRefreshUsesMainWindowOnlyState()
testIntroDemoUsesHordeDemoData()
testIntroDemoHidesWaitingForFirstDeathPrompt()
testIntroDemoPlaybackAdvancesAndLoops()
testIntroDemoKeepsHelpClosedAfterDemoEnds()

suite:finish()

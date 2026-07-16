local UITestContext = require("tests.support_ui_test_context")
local testContext = UITestContext.Create()
local suite = testContext.suite
local Fixtures = testContext.Fixtures
local createUIContext = testContext.createUIContext
local assertEquals = testContext.assertEquals
local assertTruthy = testContext.assertTruthy

local function testModuleSurface()
    local context = createUIContext()
    local DeathpoolUI = context.DeathpoolUI
    local DeathpoolSetup = _G.DeathpoolSetup
    local DeathpoolUISetup = _G.DeathpoolUISetup
    local DeathpoolUIMode = _G.DeathpoolUIMode

    assertTruthy(DeathpoolUI.Initialize, "UI module should expose Initialize")
    assertTruthy(DeathpoolUI.SetWindowCollapsed, "UI module should expose SetWindowCollapsed")
    assertTruthy(DeathpoolUI.CreateDeathLogList, "UI module should expose the flexible death log list builder")
    assertTruthy(DeathpoolUI.RefreshDeathLogRows, "UI module should expose the flexible death log list refresher")
    assertTruthy(DeathpoolUI.GetStoredDeathTime, "UI module should expose stored death time formatting")
    assertTruthy(DeathpoolUI.GetStoredDeathDate, "UI module should expose stored death date formatting")
    assertTruthy(DeathpoolUI.GetStoredDeathDateTime, "UI module should expose stored death date/time formatting")
    assertTruthy(DeathpoolSetup.GetState, "setup controller should expose GetState")
    assertTruthy(DeathpoolSetup.ShouldShowOnMainWindowOpen, "setup controller should expose first-open eligibility")
    assertTruthy(DeathpoolSetup.EnableDeathAnnouncements, "setup controller should expose death announcement action")
    assertTruthy(DeathpoolSetup.JoinHardcoreDeathsChannel, "setup controller should expose channel join action")
    assertTruthy(DeathpoolUISetup.ShowOnMainWindowOpen, "setup UI should expose first-open show behavior")
    assertTruthy(DeathpoolUISetup.Show, "setup UI should expose manual show behavior")
    assertTruthy(DeathpoolUISetup.Refresh, "setup UI should expose refresh behavior")
    assertTruthy(DeathpoolUISetup.CreateWindow, "setup UI should expose setup window creation")
    assertTruthy(DeathpoolUIMode.Resolve, "UI mode resolver should expose Resolve")
    assertTruthy(DeathpoolUIMode.IsDemoMode, "UI mode resolver should expose demo mode predicate")
    assertTruthy(DeathpoolUIMode.IsCollapsedMode, "UI mode resolver should expose collapsed mode predicate")
    assertTruthy(DeathpoolUIMode.IsNormalMode, "UI mode resolver should expose normal mode predicate")
    assertTruthy(DeathpoolUIMode.HasModal, "UI mode resolver should expose modal predicate")
    assertTruthy(DeathpoolUIMode.IsSetupModal, "UI mode resolver should expose setup modal predicate")
    assertTruthy(DeathpoolUIMode.IsHelpModal, "UI mode resolver should expose help modal predicate")
end

local function testStoredDeathTimestampFormatting()
    local context = createUIContext()
    local DeathpoolUI = context.DeathpoolUI
    local timestampOnlyDeath = Fixtures.storedDeath({
        timestamp = 12345,
    })

    assertEquals(
        DeathpoolUI.GetStoredDeathTime(timestampOnlyDeath),
        date("%H:%M", 12345),
        "stored death time should be derived from the timestamp"
    )
    assertEquals(
        DeathpoolUI.GetStoredDeathDate(timestampOnlyDeath),
        date("%B %d, %Y", 12345),
        "stored death date should be derived from the timestamp"
    )
    assertEquals(
        DeathpoolUI.GetStoredDeathDateTime(timestampOnlyDeath),
        date("%B %d, %Y", 12345) .. " " .. date("%H:%M", 12345),
        "stored death date time should be derived from the timestamp"
    )

    local missingTimestampDeath = Fixtures.storedDeath({
        timestamp = false,
    })
    assertEquals(
        DeathpoolUI.GetStoredDeathTime(missingTimestampDeath),
        date("%H:%M", 0),
        "stored death time should display the epoch fallback when the timestamp is missing"
    )
    assertEquals(
        DeathpoolUI.GetStoredDeathDate(missingTimestampDeath),
        date("%B %d, %Y", 0),
        "stored death date should display the epoch fallback when the timestamp is missing"
    )
    assertEquals(
        DeathpoolUI.GetStoredDeathDateTime(missingTimestampDeath),
        date("%B %d, %Y", 0) .. " " .. date("%H:%M", 0),
        "stored death date time should display the epoch fallback when the timestamp is missing"
    )
end

local function buildModeDisplayState(options)
    options = options or {}
    return {
        deaths = options.deaths or {},
        lockedPrediction = options.lockedPrediction,
    }
end

local function setFakeIntroDemoActive(frame)
    frame.introDemoController = {
        IsActive = function()
            return true
        end,
    }
end

local function testUIModeResolverPrioritizesSetup()
    local context = createUIContext()
    local Deathpool = context.Deathpool
    local DeathpoolUIMode = _G.DeathpoolUIMode

    Deathpool.helpFrame:Show()
    Deathpool.setupFrame:Show()
    setFakeIntroDemoActive(Deathpool)

    local mode = DeathpoolUIMode.Resolve(Deathpool, buildModeDisplayState(), DeathpoolCharacterState)

    assertEquals(mode.mode, "demo", "setup should preserve the underlying intro demo mode")
    assertEquals(mode.modal, "setup", "setup should take modal priority over help")
    assertEquals(DeathpoolUIMode.IsDemoMode(mode), true, "setup over demo should report demo mode through predicate")
    assertEquals(DeathpoolUIMode.HasModal(mode), true, "setup should report modal state through predicate")
    assertEquals(DeathpoolUIMode.IsSetupModal(mode), true, "setup should report setup modal through predicate")
    assertEquals(DeathpoolUIMode.IsHelpModal(mode), false, "setup should not report help modal through predicate")
    assertEquals(mode.prompt, nil, "setup mode should suppress normal prompts")
    assertEquals(mode.inputsLocked, true, "setup mode should lock prediction inputs")
    assertEquals(mode.mainBlocked, true, "setup mode should block the main window")
    assertEquals(mode.showRecentDeathRows, true, "setup mode should keep expanded death row data visible-ready")
    assertEquals(mode.showWaitingHelp, false, "setup mode should hide waiting help")
end

local function testUIModeResolverPrioritizesIntroDemoBeforeCollapsedAndPrompts()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenFirstRun = false,
    }))
    local Deathpool = context.Deathpool
    local DeathpoolUI = context.DeathpoolUI
    local DeathpoolUIMode = _G.DeathpoolUIMode

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    setFakeIntroDemoActive(Deathpool)

    local mode = DeathpoolUIMode.Resolve(Deathpool, buildModeDisplayState(), DeathpoolCharacterState)

    assertEquals(mode.mode, "demo", "intro demo should take priority over collapsed and first-run prompt state")
    assertEquals(mode.modal, nil, "intro demo without overlay should not report a modal")
    assertEquals(DeathpoolUIMode.IsDemoMode(mode), true, "intro demo should report demo mode through predicate")
    assertEquals(DeathpoolUIMode.HasModal(mode), false, "intro demo should not report modal state through predicate")
    assertEquals(mode.prompt, nil, "intro demo should suppress normal prompts")
    assertEquals(mode.inputsLocked, true, "intro demo should lock prediction inputs")
    assertEquals(mode.mainBlocked, false, "intro demo should keep the main window available for ending the demo")
    assertEquals(mode.showRecentDeathRows, true, "intro demo should show demo death rows")
    assertEquals(mode.showWaitingHelp, false, "intro demo should hide waiting help")
end

local function testUIModeResolverHandlesCollapsedMode()
    local context = createUIContext()
    local Deathpool = context.Deathpool
    local DeathpoolUI = context.DeathpoolUI
    local DeathpoolUIMode = _G.DeathpoolUIMode

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)

    local mode = DeathpoolUIMode.Resolve(Deathpool, buildModeDisplayState(), DeathpoolCharacterState)

    assertEquals(mode.mode, "collapsed", "collapsed mode should suppress expanded prompt behavior")
    assertEquals(mode.modal, nil, "collapsed mode should not report a modal")
    assertEquals(DeathpoolUIMode.IsCollapsedMode(mode), true, "collapsed mode should report through predicate")
    assertEquals(DeathpoolUIMode.HasModal(mode), false, "collapsed mode should not report modal state through predicate")
    assertEquals(mode.prompt, nil, "collapsed mode should not show expanded prompts")
    assertEquals(mode.inputsLocked, false, "collapsed mode should inherit unlocked prediction inputs")
    assertEquals(mode.mainBlocked, false, "collapsed mode should not block the main window")
    assertEquals(mode.showRecentDeathRows, true, "collapsed mode should keep expanded death row data visible-ready")
    assertEquals(mode.showWaitingHelp, false, "collapsed mode should hide waiting help")
end

local function testUIModeResolverHandlesNormalPromptsAndLocks()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenFirstRun = false,
    }))
    local Deathpool = context.Deathpool
    local DeathpoolUIMode = _G.DeathpoolUIMode

    local firstRunMode = DeathpoolUIMode.Resolve(Deathpool, buildModeDisplayState(), DeathpoolCharacterState)
    assertEquals(firstRunMode.mode, "normal", "first-run prompt should stay in normal mode")
    assertEquals(firstRunMode.modal, nil, "first-run prompt should not report a modal")
    assertEquals(DeathpoolUIMode.IsNormalMode(firstRunMode), true, "first-run prompt should report normal mode through predicate")
    assertEquals(DeathpoolUIMode.HasModal(firstRunMode), false, "first-run prompt should not report modal state through predicate")
    assertEquals(firstRunMode.prompt, "firstRun", "normal mode should surface the first-run prompt")
    assertEquals(firstRunMode.inputsLocked, false, "first-run prompt should leave prediction inputs unlocked")
    assertEquals(firstRunMode.mainBlocked, false, "first-run prompt should not block the main window")
    assertEquals(firstRunMode.showRecentDeathRows, false, "first-run prompt should hide expanded death rows")
    assertEquals(firstRunMode.showWaitingHelp, false, "first-run prompt should hide waiting help")

    DeathpoolCharacterState.hasSeenFirstRun = true
    local waitingMode = DeathpoolUIMode.Resolve(Deathpool, buildModeDisplayState(), DeathpoolCharacterState)
    assertEquals(waitingMode.mode, "normal", "waiting prompt should stay in normal mode")
    assertEquals(waitingMode.modal, nil, "waiting prompt should not report a modal")
    assertEquals(waitingMode.prompt, "waiting", "normal mode should surface waiting prompt with no deaths")
    assertEquals(waitingMode.inputsLocked, false, "waiting prompt should leave prediction inputs unlocked")
    assertEquals(waitingMode.mainBlocked, false, "waiting prompt should not block the main window")
    assertEquals(waitingMode.showRecentDeathRows, false, "waiting prompt should hide expanded death rows")
    assertEquals(waitingMode.showWaitingHelp, false, "waiting help should wait for the configured delay")

    Deathpool.waitingPromptDisplayDuration = _G.DeathpoolConstants.DEMO.waitingForFirstDeathHelpTextDelaySeconds
    local waitingHelpMode = DeathpoolUIMode.Resolve(Deathpool, buildModeDisplayState(), DeathpoolCharacterState)
    assertEquals(waitingHelpMode.showRecentDeathRows, false, "waiting help should keep expanded death rows hidden")
    assertEquals(waitingHelpMode.showWaitingHelp, true, "waiting help should show after the configured delay")

    local lockedMode = DeathpoolUIMode.Resolve(
        Deathpool,
        buildModeDisplayState({
            deaths = {
                Fixtures.storedDeath(),
            },
            lockedPrediction = Fixtures.prediction(),
        }),
        DeathpoolCharacterState
    )
    assertEquals(lockedMode.mode, "normal", "locked prediction should stay in normal mode")
    assertEquals(lockedMode.modal, nil, "locked prediction should not report a modal")
    assertEquals(lockedMode.prompt, nil, "locked prediction should suppress prompts")
    assertEquals(lockedMode.inputsLocked, true, "locked prediction should lock inputs")
    assertEquals(lockedMode.mainBlocked, false, "locked prediction should not block the main window")
    assertEquals(lockedMode.showRecentDeathRows, true, "normal locked mode should show death rows")
    assertEquals(lockedMode.showWaitingHelp, false, "locked prediction should hide waiting help")
end

local function testUIModeResolverHandlesHelpModal()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenFirstRun = false,
    }))
    local Deathpool = context.Deathpool
    local DeathpoolUIMode = _G.DeathpoolUIMode

    Deathpool.helpFrame:Show()

    local mode = DeathpoolUIMode.Resolve(Deathpool, buildModeDisplayState(), DeathpoolCharacterState)

    assertEquals(mode.mode, "normal", "help should preserve the underlying normal mode")
    assertEquals(mode.modal, "help", "help should report the help modal")
    assertEquals(DeathpoolUIMode.IsNormalMode(mode), true, "help should report normal mode through predicate")
    assertEquals(DeathpoolUIMode.HasModal(mode), true, "help should report modal state through predicate")
    assertEquals(DeathpoolUIMode.IsHelpModal(mode), true, "help should report help modal through predicate")
    assertEquals(DeathpoolUIMode.IsSetupModal(mode), false, "help should not report setup modal through predicate")
    assertEquals(mode.prompt, nil, "help modal should suppress normal prompts")
    assertEquals(mode.inputsLocked, true, "help modal should lock prediction inputs")
    assertEquals(mode.mainBlocked, true, "help modal should block the main window")
    assertEquals(mode.showRecentDeathRows, true, "help modal should keep expanded death row data visible-ready")
    assertEquals(mode.showWaitingHelp, false, "help modal should hide waiting help")

    Deathpool.helpFrame.downloadLink:GetScript("OnClick")()

    local githubMode = DeathpoolUIMode.Resolve(Deathpool, buildModeDisplayState(), DeathpoolCharacterState)

    assertEquals(Deathpool.helpFrame:IsShown(), false, "GitHub link dialog should replace help while it is open")
    assertEquals(githubMode.mode, "normal", "GitHub link dialog should preserve the underlying normal mode")
    assertEquals(githubMode.modal, "help", "GitHub link dialog should reuse the help modal state")
    assertEquals(
        DeathpoolUIMode.IsHelpModal(githubMode),
        true,
        "GitHub link dialog should report through the help modal predicate"
    )
    assertEquals(githubMode.inputsLocked, true, "GitHub link dialog should lock prediction inputs")
    assertEquals(githubMode.mainBlocked, true, "GitHub link dialog should block the main window")
end

local function testInitializeReturnsFrames()
    local context = createUIContext()
    local Deathpool = context.Deathpool
    local DeathpoolDebug = context.DeathpoolDebug
    local DeathpoolLog = context.DeathpoolLog
    local layout = context.DeathpoolUI.LAYOUT

    assertTruthy(Deathpool, "Initialize should return the main frame")
    assertTruthy(DeathpoolDebug, "Initialize should return the debug frame")
    assertTruthy(DeathpoolLog, "Initialize should return the history log frame")
    assertEquals(Deathpool:GetWidth(), layout.expandedWindowWidth, "main frame should use the compact expanded width")
    assertEquals(Deathpool:GetHeight(), layout.mainWindowHeight, "main frame should use the reduced expanded height")
    assertEquals(DeathpoolLog:GetWidth(), layout.logWindowWidth, "history log should use the compact log width")
    assertEquals(DeathpoolLog:GetHeight(), layout.logWindowHeight, "history log should use the reduced expanded height")
    assertEquals(DeathpoolLog:IsShown(), false, "history log should start hidden by default")
    assertTruthy(DeathpoolLog.dragHandle, "history log should create a titlebar drag handle")
    assertEquals(
        select(4, DeathpoolLog.dragHandle:GetPoint(1)),
        layout.titlebarDragLeftInset,
        "history log titlebar should use the shared left drag inset"
    )
    assertEquals(
        select(4, DeathpoolLog.dragHandle:GetPoint(2)),
        -layout.titlebarDragRightInset,
        "history log titlebar should use the shared right drag inset"
    )
    assertEquals(
        DeathpoolLog.dragHandle:GetHeight(),
        layout.titlebarDragHeight,
        "history log titlebar should use the shared drag height"
    )
    assertTruthy(#Deathpool.deathRows > 0, "main frame should create recent death rows")
    assertTruthy(#DeathpoolLog.rows > 0, "log frame should create history rows")
    assertEquals(DeathpoolLog.logRowHeight, layout.deathLogRowHeight, "history log should use compact record spacing")
    assertEquals(DeathpoolLog.rows[1]:GetHeight(), layout.deathLogRowHeight, "history log rows should use compact record spacing")
    assertTruthy(DeathpoolLog.filterButton, "log frame should create a history filter button")
    assertEquals(DeathpoolLog.filterButton:GetText(), "SHOW ALL", "history filter button should default to the all-history action")
    assertEquals(
        DeathpoolLog.filterButton:GetHeight(),
        layout.compactButtonHeight,
        "history filter should use the compact button height"
    )
    assertEquals(
        select(4, DeathpoolLog.scrollFrame:GetPoint(2)),
        -(layout.outsideGutter + layout.scrollbarInset),
        "history scrollbar should clear the window inlay"
    )
    assertEquals(
        layout.logVerticalSpacing,
        layout.deathLogHeaderY - layout.deathLogFrameY,
        "history log should share the main log vertical spacing"
    )
    assertEquals(
        select(5, DeathpoolLog.logSubtitle:GetPoint(1)),
        layout.historySubtitleY,
        "history subtitle should use the shared subtitle position"
    )
    assertEquals(
        select(5, DeathpoolLog.columnHeaders.time:GetPoint(1)),
        layout.historyLogHeaderY,
        "history column headers should leave room beneath the subtitle"
    )
    assertEquals(
        select(5, DeathpoolLog.logSubtitle:GetPoint(1)) - select(5, DeathpoolLog.columnHeaders.time:GetPoint(1)),
        layout.historySubtitleHeaderSpacing,
        "history subtitle-to-header spacing should include extra breathing room"
    )
    assertEquals(
        select(5, DeathpoolLog.columnHeaders.time:GetPoint(1)) - select(5, DeathpoolLog.rows[1]:GetPoint(1)),
        layout.logVerticalSpacing,
        "history header-to-row spacing should match the main log spacing"
    )
    assertEquals(DeathpoolLog.columnHeaders.awardedPoints.justifyH, "RIGHT", "history log should right justify the points header")
    assertEquals(DeathpoolLog.rows[1].awardedPoints.justifyH, "RIGHT", "history log should right justify points cells")
    assertEquals(
        select(4, DeathpoolLog.columnHeaders.awardedPoints:GetPoint(1)),
        select(4, DeathpoolLog.rows[1]:GetPoint(1)) + select(4, DeathpoolLog.rows[1].awardedPoints:GetPoint(1)),
        "history log points header should align with the points column"
    )
    assertEquals(
        select(4, DeathpoolLog.columnHeaders.awardedPoints:GetPoint(1))
            + DeathpoolLog.columnHeaders.awardedPoints:GetWidth(),
        layout.logWindowWidth - layout.outsideGutter - layout.historyScrollbarGap - layout.scrollbarInset,
        "history log points header should leave reduced room for the scrollbar"
    )
    assertEquals(
        select(4, DeathpoolLog.rows[1]:GetPoint(1))
            + select(4, DeathpoolLog.rows[1].awardedPoints:GetPoint(1))
            + DeathpoolLog.rows[1].awardedPoints:GetWidth(),
        layout.logWindowWidth - layout.outsideGutter - layout.historyScrollbarGap - layout.scrollbarInset,
        "history log points cells should leave reduced room for the scrollbar"
    )
    assertTruthy(Deathpool.helpFrame, "main frame should keep a reference to the help frame")
    assertTruthy(Deathpool.githubLinkFrame, "main frame should keep a reference to the GitHub link dialog")
    assertTruthy(Deathpool.helpButton, "main frame should keep a reference to the help button")
    assertTruthy(Deathpool.helpFrame.backdropOverlay, "help window should create a main-window backdrop overlay")
    assertTruthy(Deathpool.helpFrame.titlebarDragHandle, "help window should create a titlebar drag handle")
    assertTruthy(Deathpool.githubLinkFrame.backdropOverlay, "GitHub link dialog should create a main-window backdrop overlay")
    assertTruthy(Deathpool.githubLinkFrame.titlebarDragHandle, "GitHub link dialog should create a titlebar drag handle")
    assertEquals(
        select(4, Deathpool.helpFrame.titlebarDragHandle:GetPoint(1)),
        layout.titlebarDragLeftInset,
        "help titlebar should use the shared left drag inset"
    )
    assertEquals(
        Deathpool.helpFrame.titlebarDragHandle:GetHeight(),
        layout.titlebarDragHeight,
        "help titlebar should use the shared drag height"
    )
    assertTruthy(Deathpool.introDemoController, "main frame should keep a reference to the intro demo controller")
    assertTruthy(Deathpool.lockButton, "main frame should keep a reference to the lock button")
    assertTruthy(Deathpool.pauseButton, "main frame should keep a reference to the pause button")
    assertTruthy(Deathpool.bottomLogButton, "main frame should keep a reference to the bottom log button")
    assertTruthy(Deathpool.gameInfoCallout, "main frame should keep a reference to the game info callout")
    assertEquals(Deathpool.gameInfoCallout:IsShown(), false, "game info callout should start hidden")
    assertTruthy(Deathpool.recentDeathsFrame, "main frame should create the reusable recent deaths frame")
    assertEquals(Deathpool.recentDeathsFrame.logRowHeight, DeathpoolLog.logRowHeight, "main log should use the history log record spacing")
    assertEquals(Deathpool.deathRows[1]:GetHeight(), DeathpoolLog.rows[1]:GetHeight(), "main log rows should match history log row height")
    assertEquals(select(4, Deathpool.recentDeathsFrame:GetPoint(1)), layout.outsideGutter, "main log should use the outside gutter")
    assertEquals(select(5, Deathpool.recentDeathsFrame:GetPoint(1)), layout.deathLogFrameY, "main log should sit close beneath the column headers")
    assertEquals(
        Deathpool.recentDeathsFrame:GetHeight(),
        5 * layout.deathLogRowHeight,
        "main log frame should fit exactly five compact rows"
    )
    assertTruthy(Deathpool.deathRows[1].time, "main frame should create the recent death time cell")
    assertTruthy(Deathpool.deathRows[1].sourceName, "main frame should create the recent death source cell")
    assertTruthy(Deathpool.deathRows[1].level, "main frame should create the recent death level cell")
    assertTruthy(Deathpool.deathRows[1].zone, "main frame should create the recent death location cell")
    assertTruthy(Deathpool.deathRows[1].awardedPoints, "main frame should create the total points cell in recent death rows")
    assertEquals(Deathpool.deathRows[1].awardedPoints.justifyH, "RIGHT", "main frame should right justify recent death points")
    assertEquals(select(4, Deathpool.deathRows[1].time:GetPoint(1)), 0, "main frame should keep recent death time at the content edge")
    assertEquals(select(4, Deathpool.deathRows[1].sourceName:GetPoint(1)), 58, "main frame should compact the recent death source column")
    assertEquals(select(4, Deathpool.deathRows[1].level:GetPoint(1)), 278, "main frame should compact the recent death level column")
    assertEquals(select(4, Deathpool.deathRows[1].zone:GetPoint(1)), 328, "main frame should compact the recent death location column")
    assertEquals(select(4, Deathpool.deathRows[1].awardedPoints:GetPoint(1)), 530, "main frame should compact the recent death points column")
    assertEquals(Deathpool.deathRows[1].sourceName:GetWidth(), 290, "main frame should preserve the recent death source width")
    assertEquals(Deathpool.deathRows[1].level:GetWidth(), 40, "main frame should preserve the recent death level width")
    assertEquals(Deathpool.deathRows[1].zone:GetWidth(), 400, "main frame should preserve the recent death location width")
    assertEquals(Deathpool.deathRows[1].awardedPoints:GetWidth(), 46, "main frame should preserve the recent death points width")
    assertEquals(
        select(4, Deathpool.deathRows[1].awardedPoints:GetPoint(1)) + Deathpool.deathRows[1].awardedPoints:GetWidth(),
        layout.expandedWindowWidth - (layout.outsideGutter * 2),
        "main frame should keep recent death points inside the compact right gutter"
    )
    assertTruthy(
        select(4, Deathpool.deathRows[1].time:GetPoint(1))
            < select(4, Deathpool.deathRows[1].sourceName:GetPoint(1)),
        "main frame should place source after time"
    )
    assertTruthy(
        select(4, Deathpool.deathRows[1].sourceName:GetPoint(1))
            < select(4, Deathpool.deathRows[1].level:GetPoint(1)),
        "main frame should place level after source"
    )
    assertTruthy(
        select(4, Deathpool.deathRows[1].level:GetPoint(1))
            < select(4, Deathpool.deathRows[1].zone:GetPoint(1)),
        "main frame should place location after level"
    )
    assertTruthy(
        select(4, Deathpool.deathRows[1].zone:GetPoint(1))
            < select(4, Deathpool.deathRows[1].awardedPoints:GetPoint(1)),
        "main frame should place points after location"
    )
    assertEquals(Deathpool.deathRows[1].pointsTooltipTarget, nil, "main frame should omit the base points hover target from recent death rows")
    assertEquals(Deathpool.deathRows[1].multiplier, nil, "main frame should omit the combo cell from recent death rows")
    assertEquals(Deathpool.deathRows[1].streakMultiplier, nil, "main frame should omit the streak cell from recent death rows")
    assertTruthy(Deathpool.collapsedLogFrame, "main frame should create the collapsed death log frame")
    assertTruthy(#Deathpool.collapsedLogFrame.rows > 0, "main frame should create collapsed death log rows")
    assertEquals(Deathpool.collapsedLogFrame.logRowHeight, DeathpoolLog.logRowHeight, "mini log should use the history log record spacing")
    assertEquals(Deathpool.collapsedLogFrame.rows[1]:GetHeight(), DeathpoolLog.rows[1]:GetHeight(), "mini log rows should match history log row height")
    assertTruthy(Deathpool.collapsedLogFrame.rows[1].time, "main frame should create collapsed death time cells")
    assertTruthy(Deathpool.collapsedLogFrame.rows[1].awardedPoints, "main frame should create collapsed death points cells")
    assertEquals(Deathpool.collapsedLogFrame.rows[1].awardedPoints.justifyH, "RIGHT", "main frame should right justify collapsed death points")
    assertTruthy(#(Deathpool.collapsedLogHeaders or {}) > 0, "main frame should create collapsed death log headers")
    assertEquals(
        select(5, Deathpool.collapsedLogHeaders[1]:GetPoint(1)),
        layout.collapsedLogHeaderY,
        "mini log headers should use the shared collapsed header position"
    )
    assertEquals(
        select(5, Deathpool.collapsedLogFrame:GetPoint(1)),
        layout.collapsedLogFrameY,
        "mini log rows should use the shared collapsed row position"
    )
    assertEquals(
        select(5, Deathpool.collapsedLogHeaders[1]:GetPoint(1)) - select(5, Deathpool.collapsedLogFrame:GetPoint(1)),
        layout.deathLogHeaderY - layout.deathLogFrameY,
        "mini log header-to-row spacing should match the main log"
    )
    assertTruthy(Deathpool.collapsedScoreDivider, "main frame should create the collapsed score divider")
    assertEquals(
        select(5, Deathpool.collapsedPointsValue:GetPoint(1)),
        layout.footerGutter,
        "collapsed score should use the footer gutter"
    )
    assertTruthy(Deathpool.collapsedResizeHandle, "main frame should create the collapsed resize handle")
    assertEquals(
        Deathpool.collapsedResizeHandle:GetNormalTexture(),
        "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up",
        "main frame should use Blizzard chat resize art for the collapsed resize handle"
    )
    assertEquals(Deathpool.minimizeButton.template, nil, "main frame should use a plain button for Classic-compatible collapse art")
    assertEquals(Deathpool.minimizeButton:GetText(), nil, "main frame collapse button should rely on Blizzard textures instead of text")
    assertEquals(Deathpool.bottomLogButton:GetText(), "LOG", "bottom log button should use the log label")
    assertEquals(Deathpool.bottomLogButton:IsEnabled(), false, "bottom log button should start disabled before the first locked prediction")
    assertEquals(Deathpool.levelRangeButtons[1]:GetWidth(), 64, "level range buttons should preserve their width")
    assertEquals(Deathpool.levelRangeButtons[1]:GetHeight(), layout.compactButtonHeight, "level range buttons should preserve their height")
    assertEquals(select(4, Deathpool.levelRangeButtons[1]:GetPoint(1)), layout.predictionControlX, "level range buttons should start closer to their label")
    assertEquals(
        select(5, Deathpool.levelRangeLabel:GetPoint(1)),
        select(5, Deathpool.levelRangeButtons[1]:GetPoint(1)),
        "level range label should align with the level button row"
    )
    assertEquals(Deathpool.levelRangeLabel:GetHeight(), layout.compactButtonHeight, "level range label should match the button row height")
    assertEquals(Deathpool.levelRangeLabel.justifyV, "MIDDLE", "level range label should be vertically centered")
    assertEquals(
        select(4, Deathpool.levelRangeButtons[2]:GetPoint(1)) - select(4, Deathpool.levelRangeButtons[1]:GetPoint(1)),
        68,
        "level range buttons should use compact horizontal spacing"
    )
    assertEquals(Deathpool.sourceEditBox:GetWidth(), 180, "source edit box should preserve its width")
    assertEquals(Deathpool.sourceEditBox:GetHeight(), layout.compactButtonHeight, "source edit box should preserve its height")
    assertEquals(
        select(4, Deathpool.sourceEditBox:GetPoint(1)) - select(4, Deathpool.levelRangeButtons[1]:GetPoint(1)),
        7,
        "source edit box should account for its template border when aligning with buttons"
    )
    assertEquals(
        select(4, Deathpool.zoneEditBox:GetPoint(1)) - select(4, Deathpool.levelRangeButtons[1]:GetPoint(1)),
        7,
        "location edit box should account for its template border when aligning with buttons"
    )
    assertEquals(
        select(5, Deathpool.sourceLabel:GetPoint(1)),
        select(5, Deathpool.sourceEditBox:GetPoint(1)),
        "source label should align with the source edit box row"
    )
    assertEquals(
        select(5, Deathpool.zoneLabel:GetPoint(1)),
        select(5, Deathpool.zoneEditBox:GetPoint(1)),
        "location label should align with the location edit box row"
    )
    assertEquals(Deathpool.sourceLabel:GetHeight(), layout.compactButtonHeight, "source label should match the edit box row height")
    assertEquals(Deathpool.zoneLabel:GetHeight(), layout.compactButtonHeight, "location label should match the edit box row height")
    assertEquals(Deathpool.sourceLabel.justifyV, "MIDDLE", "source label should be vertically centered")
    assertEquals(Deathpool.zoneLabel.justifyV, "MIDDLE", "location label should be vertically centered")
    assertEquals(Deathpool.helpButton:GetWidth(), layout.standardButtonWidth, "help button should preserve its width")
    assertEquals(Deathpool.helpButton:GetHeight(), layout.standardButtonHeight, "help button should preserve its height")
    assertEquals(Deathpool.bottomLogButton:GetWidth(), 100, "log button should preserve its width")
    assertEquals(Deathpool.bottomLogButton:GetHeight(), layout.standardButtonHeight, "log button should preserve its height")
    assertEquals(Deathpool.pauseButton:GetWidth(), layout.standardButtonWidth, "pause button should preserve its width")
    assertEquals(Deathpool.lockButton:GetWidth(), layout.standardButtonWidth, "lock button should preserve its width")
    assertEquals(select(1, Deathpool.helpButton:GetPoint(1)), "BOTTOMLEFT", "bottom buttons should be anchored from the left edge")
    assertEquals(select(4, Deathpool.helpButton:GetPoint(1)), layout.predictionControlX, "bottom buttons should start farther left")
    assertEquals(select(5, Deathpool.helpButton:GetPoint(1)), layout.footerGutter, "bottom buttons should use the footer gutter")
    assertEquals(select(2, Deathpool.bottomLogButton:GetPoint(1)), Deathpool.helpButton, "log button should chain to help")
    assertEquals(select(4, Deathpool.bottomLogButton:GetPoint(1)), layout.actionButtonGap, "log button should preserve the button gap")
    assertEquals(select(2, Deathpool.pauseButton:GetPoint(1)), Deathpool.bottomLogButton, "pause button should chain to log")
    assertEquals(select(4, Deathpool.pauseButton:GetPoint(1)), layout.actionButtonGap, "pause button should preserve the button gap")
    assertEquals(select(2, Deathpool.lockButton:GetPoint(1)), Deathpool.pauseButton, "lock button should chain to pause")
    assertEquals(select(4, Deathpool.lockButton:GetPoint(1)), layout.actionButtonGap, "lock button should preserve the button gap")
    assertEquals(
        select(4, Deathpool.helpButton:GetPoint(1))
            + Deathpool.helpButton:GetWidth()
            + layout.actionButtonGap
            + Deathpool.bottomLogButton:GetWidth()
            + layout.actionButtonGap
            + Deathpool.pauseButton:GetWidth()
            + layout.actionButtonGap
            + Deathpool.lockButton:GetWidth(),
        604,
        "bottom buttons should fit within the compact expanded width"
    )
    assertEquals(select(5, DeathpoolLog.filterButton:GetPoint(1)), layout.footerGutter, "history filter should use the footer gutter")
    assertTruthy(Deathpool.sourceEditBox, "main frame should create the source edit box")
    assertTruthy(Deathpool.zoneEditBox, "main frame should create the zone edit box")
    assertTruthy(DeathpoolDebug.detailLabels, "debug frame should keep references to detail labels")
    assertEquals(DeathpoolDebug.detailValues.sourceMessage.kind, "EditBox", "debug frame should use an edit box for the raw message")
    assertEquals(
        DeathpoolDebug.detailValues.sourceMessage:GetWidth(),
        DeathpoolDebug:GetWidth() - (layout.outsideGutter * 2),
        "debug raw message should keep a gutter on both sides"
    )
    assertEquals(DeathpoolDebug.detailValues.sourceMessage:GetHeight(), 36, "debug raw message should be tall enough for two lines")
    assertEquals(DeathpoolDebug.detailValues.sourceMessage.multiLine, true, "debug raw message should wrap across multiple lines")
    assertEquals(DeathpoolDebug.detailValues.sourceMessage.autoFocus, false, "debug raw message should not steal focus on create")
    assertEquals(
        select(5, DeathpoolDebug.detailLabels.comboDetails:GetPoint(1)),
        select(5, DeathpoolDebug.detailLabels.pointFormula:GetPoint(1)),
        "debug winning combo should move to the formula row"
    )
    assertTruthy(
        select(4, DeathpoolDebug.detailLabels.comboDetails:GetPoint(1))
            > select(4, DeathpoolDebug.detailLabels.pointFormula:GetPoint(1)),
        "debug winning combo should sit to the right of the formula row"
    )
    assertEquals(
        select(4, DeathpoolDebug.detailLabels.sourceMessage:GetPoint(1)),
        select(4, DeathpoolDebug.detailValues.sourceMessage:GetPoint(1)),
        "debug raw message label should align with the frame gutter"
    )
    assertEquals(
        select(5, DeathpoolDebug.detailLabels.sourceMessage:GetPoint(1)),
        select(5, DeathpoolDebug.detailValues.sourceMessage:GetPoint(1)) + 15,
        "debug raw message label should sit above the edit box"
    )
    assertTruthy(Deathpool.introDemoAttractPanel, "main frame should create the intro demo marquee panel")
    assertTruthy(Deathpool.emptyPredictionPrompt, "main frame should create the empty-prediction prompt")
    assertTruthy(Deathpool.setupFrame, "main frame should create the standalone setup window")
    assertTruthy(Deathpool.setupFrame.enableDeathAnnouncementsButton, "setup window should create the death announcement enable button")
    assertTruthy(Deathpool.setupFrame.enableDeathAnnouncementsText, "setup window should create the death announcement enable text")
    assertTruthy(Deathpool.setupFrame.joinHardcoreDeathsButton, "setup window should create the hardcore deaths channel join button")
    assertTruthy(Deathpool.setupFrame.joinHardcoreDeathsText, "setup window should create the hardcore deaths channel join text")
    assertTruthy(Deathpool.setupFrame.backdropOverlay, "setup window should create a main-window backdrop overlay")
    assertTruthy(Deathpool.setupFrame.titlebarDragHandle, "setup window should create a titlebar drag handle")
    assertTruthy(Deathpool.waitingPromptText, "main frame should create the waiting prompt base text")
    assertTruthy(Deathpool.waitingPromptDots, "main frame should create the waiting prompt dots")
    assertTruthy(Deathpool.waitingPromptHelpText, "main frame should create the waiting prompt help text")
    assertEquals(Deathpool.emptyPredictionPrompt:IsShown(), false, "empty-prediction prompt should start hidden")
    assertEquals(Deathpool.setupFrame:IsShown(), false, "setup window should start hidden")
    assertEquals(Deathpool.setupFrame.backdropOverlay:IsShown(), false, "setup backdrop should start hidden")
    assertEquals(Deathpool.setupFrame.backdropOverlay.allPoints, true, "setup backdrop should cover the main window")
    assertEquals(Deathpool.setupFrame.backdropOverlay.mouseEnabled, true, "setup backdrop should block main window clicks")
    assertEquals(Deathpool.setupFrame.backdropOverlay.dragButton, "LeftButton", "setup backdrop should preserve main-window dragging")
    assertTruthy(Deathpool.setupFrame.backdropOverlay:GetScript("OnDragStart"), "setup backdrop should start main-window dragging")
    assertTruthy(Deathpool.setupFrame.backdropOverlay:GetScript("OnDragStop"), "setup backdrop should stop main-window dragging")
    assertEquals(Deathpool.setupFrame.titlebarDragHandle.dragButton, "LeftButton", "setup titlebar should preserve main-window dragging")
    assertTruthy(Deathpool.setupFrame.titlebarDragHandle:GetScript("OnDragStart"), "setup titlebar should start main-window dragging")
    assertTruthy(Deathpool.setupFrame.titlebarDragHandle:GetScript("OnDragStop"), "setup titlebar should stop main-window dragging")
    assertEquals(
        Deathpool.setupFrame.backdropOverlay:GetFrameLevel() > Deathpool:GetFrameLevel(),
        true,
        "setup backdrop should sit above main window contents"
    )
    assertEquals(Deathpool.setupFrame.backdropOverlay.texture.colorTexture[4], 0.58, "setup backdrop should obscure the main window")
    assertEquals(Deathpool.helpFrame:GetHeight(), 369, "help window should use the shorter modal height")
    assertEquals(select(2, Deathpool.helpFrame:GetPoint(1)), Deathpool, "help window should be centered on the main window")
    assertEquals(select(4, Deathpool.helpFrame:GetPoint(1)), 0, "help window should not offset horizontally from the main window")
    assertEquals(select(5, Deathpool.helpFrame:GetPoint(1)), 0, "help window should not offset vertically from the main window")
    assertEquals(Deathpool.helpFrame.movable, false, "help window should not be movable")
    assertEquals(Deathpool.helpFrame.dragButton, nil, "help window should not register itself for dragging")
    assertEquals(Deathpool.helpFrame.backdropOverlay:IsShown(), false, "help backdrop should start hidden")
    assertEquals(Deathpool.helpFrame.backdropOverlay.allPoints, true, "help backdrop should cover the main window")
    assertEquals(Deathpool.helpFrame.backdropOverlay.mouseEnabled, true, "help backdrop should block main window clicks")
    assertEquals(Deathpool.helpFrame.backdropOverlay.dragButton, "LeftButton", "help backdrop should preserve main-window dragging")
    assertTruthy(Deathpool.helpFrame.backdropOverlay:GetScript("OnDragStart"), "help backdrop should start main-window dragging")
    assertTruthy(Deathpool.helpFrame.backdropOverlay:GetScript("OnDragStop"), "help backdrop should stop main-window dragging")
    assertEquals(Deathpool.helpFrame.titlebarDragHandle.dragButton, "LeftButton", "help titlebar should preserve main-window dragging")
    assertTruthy(Deathpool.helpFrame.titlebarDragHandle:GetScript("OnDragStart"), "help titlebar should start main-window dragging")
    assertTruthy(Deathpool.helpFrame.titlebarDragHandle:GetScript("OnDragStop"), "help titlebar should stop main-window dragging")
    assertEquals(
        Deathpool.helpFrame.backdropOverlay:GetFrameLevel() > Deathpool:GetFrameLevel(),
        true,
        "help backdrop should sit above main window contents"
    )
    assertEquals(Deathpool.helpFrame.backdropOverlay.texture.colorTexture[4], 0.58, "help backdrop should obscure the main window")
    assertEquals(Deathpool.githubLinkFrame:GetWidth(), 430, "GitHub link dialog should use the setup-style modal width")
    assertEquals(Deathpool.githubLinkFrame:GetHeight(), 112, "GitHub link dialog should be compact")
    assertEquals(Deathpool.githubLinkFrame.title:GetText(), "GitHub Link", "GitHub link dialog should use the requested title")
    assertEquals(
        select(2, Deathpool.githubLinkFrame:GetPoint(1)),
        Deathpool,
        "GitHub link dialog should be centered on the main window"
    )
    assertEquals(select(4, Deathpool.githubLinkFrame:GetPoint(1)), 0, "GitHub link dialog should not offset horizontally")
    assertEquals(select(5, Deathpool.githubLinkFrame:GetPoint(1)), 0, "GitHub link dialog should not offset vertically")
    assertEquals(Deathpool.githubLinkFrame.movable, false, "GitHub link dialog should not be movable")
    assertEquals(Deathpool.githubLinkFrame.dragButton, nil, "GitHub link dialog should not register itself for dragging")
    assertEquals(Deathpool.githubLinkFrame.backdropOverlay:IsShown(), false, "GitHub link backdrop should start hidden")
    assertEquals(Deathpool.githubLinkFrame.backdropOverlay.allPoints, true, "GitHub link backdrop should cover the main window")
    assertEquals(Deathpool.githubLinkFrame.backdropOverlay.mouseEnabled, true, "GitHub link backdrop should block main window clicks")
    assertEquals(
        Deathpool.githubLinkFrame.backdropOverlay.dragButton,
        "LeftButton",
        "GitHub link backdrop should preserve main-window dragging"
    )
    assertTruthy(
        Deathpool.githubLinkFrame.backdropOverlay:GetScript("OnDragStart"),
        "GitHub link backdrop should start main-window dragging"
    )
    assertTruthy(
        Deathpool.githubLinkFrame.backdropOverlay:GetScript("OnDragStop"),
        "GitHub link backdrop should stop main-window dragging"
    )
    assertEquals(
        Deathpool.githubLinkFrame.titlebarDragHandle.dragButton,
        "LeftButton",
        "GitHub link titlebar should preserve main-window dragging"
    )
    assertTruthy(
        Deathpool.githubLinkFrame.titlebarDragHandle:GetScript("OnDragStart"),
        "GitHub link titlebar should start main-window dragging"
    )
    assertTruthy(
        Deathpool.githubLinkFrame.titlebarDragHandle:GetScript("OnDragStop"),
        "GitHub link titlebar should stop main-window dragging"
    )
    assertEquals(
        Deathpool.githubLinkFrame.backdropOverlay:GetFrameLevel() > Deathpool:GetFrameLevel(),
        true,
        "GitHub link backdrop should sit above main window contents"
    )
    assertEquals(
        Deathpool.githubLinkFrame.backdropOverlay.texture.colorTexture[4],
        0.58,
        "GitHub link backdrop should obscure the main window"
    )
    assertEquals(Deathpool.setupFrame.title:GetText(), "SETUP", "setup window should use the setup title")
    assertEquals(Deathpool.setupFrame.subtitle:GetText(), "Let's make sure you're set up!", "setup window should introduce setup")
    assertEquals(Deathpool.setupFrame.subtitle.template, "GameFontNormal", "setup subtitle should match row text size")
    assertEquals(select(2, Deathpool.setupFrame:GetPoint(1)), Deathpool, "setup window should be centered on the main window")
    assertEquals(select(4, Deathpool.setupFrame:GetPoint(1)), 0, "setup window should not offset horizontally from the main window")
    assertEquals(select(5, Deathpool.setupFrame:GetPoint(1)), 0, "setup window should not offset vertically from the main window")
    assertEquals(Deathpool.setupFrame.movable, false, "setup window should not be movable")
    assertEquals(Deathpool.setupFrame.dragButton, nil, "setup window should not register for dragging")
    assertEquals(Deathpool.configPromptFrame, nil, "main frame should not create an inline setup prompt")
    assertEquals(Deathpool.configPromptTitle, nil, "main frame should not create an inline setup title")
    assertEquals(Deathpool.deathAnnouncementsCheckbox, nil, "config walkthrough should not create a death announcement checkbox")
    assertEquals(Deathpool.hardcoreDeathsChannelCheckbox, nil, "config walkthrough should not create a channel checkbox")
    assertEquals(Deathpool.setupFrame.enableDeathAnnouncementsButton.template, "GameMenuButtonTemplate", "death announcement action should use a real button template")
    assertEquals(Deathpool.setupFrame.enableDeathAnnouncementsButton:GetText(), "ENABLE", "death announcement button should use the enable label")
    assertEquals(Deathpool.setupFrame.enableDeathAnnouncementsText:GetText(), "Hardcore death announcements", "death announcement text should explain the action")
    assertEquals(Deathpool.setupFrame.joinHardcoreDeathsButton.template, "GameMenuButtonTemplate", "channel action should use a real button template")
    assertEquals(Deathpool.setupFrame.joinHardcoreDeathsButton:GetText(), "JOIN", "channel button should use the join label")
    assertEquals(Deathpool.setupFrame.joinHardcoreDeathsText:GetText(), "The HardcoreDeaths channel", "channel text should explain the action")
    assertEquals(
        Deathpool.emptyPredictionPrompt:GetText(),
        "Make your prediction",
        "empty-prediction prompt should guide the player to choose a prediction"
    )
    assertEquals(Deathpool.introDemoAttractPanel:IsShown(), false, "intro demo marquee should start hidden outside demo mode")
    assertEquals(select(4, Deathpool.introDemoAttractPanel:GetPoint(1)), 284, "intro demo marquee should fit the compact expanded width")
    assertEquals(Deathpool.introDemoAttractPanel:GetWidth(), 314, "intro demo marquee should preserve its width")
    assertEquals(
        Deathpool.introDemoAttractPanel.text:GetText(),
        "Welcome to the death pool\nPress START GAME to begin",
        "intro demo marquee should use the arcade attract text"
    )
    assertEquals(select(1, Deathpool.waitingPromptText:GetPoint(1)), "CENTER", "waiting prompt text should anchor from the center")
    assertEquals(select(3, Deathpool.waitingPromptText:GetPoint(1)), "CENTER", "waiting prompt text should stay centered in the pane")
    assertEquals(select(1, Deathpool.waitingPromptDots:GetPoint(1)), "LEFT", "waiting prompt dots should anchor from the left")
    assertEquals(select(3, Deathpool.waitingPromptDots:GetPoint(1)), "RIGHT", "waiting prompt dots should attach to the text's right edge")
    assertEquals(select(1, Deathpool.waitingPromptHelpText:GetPoint(1)), "TOP", "waiting prompt help text should anchor from the top")
    assertEquals(select(3, Deathpool.waitingPromptHelpText:GetPoint(1)), "BOTTOM", "waiting prompt help text should attach below the waiting text")
    assertEquals(
        layout.scoreSummaryY,
        layout.deathLogDividerY - (layout.outsideGutter - layout.footerGutter),
        "expanded score summary should use the tighter footer spacing from the mini log"
    )
    assertEquals(
        select(5, Deathpool.totalPointsValue:GetPoint(1)),
        layout.scoreSummaryY,
        "expanded score summary should sit close beneath the death log divider"
    )
    assertTruthy(Deathpool.currentStreakValue, "main frame should create the current streak value")
    assertTruthy(Deathpool.dropdown, "main frame should create the shared suggestion dropdown")
    assertEquals(Deathpool.collapsedLogFrame.clipsChildren, true, "collapsed death log should clip child rows during resize")
    assertEquals(Deathpool.collapsedLogFrame.rows[1].clipsChildren, true, "collapsed death log rows should clip cell text to the row bounds")
    assertEquals(_G.UISpecialFrames[1], "DeathpoolFrame", "main frame should register with the WoW escape-close list")
end

local function testInitializeRestoresSavedHistoryFilterMode()
    local context = createUIContext(Fixtures.uiDatabase({
        historySuccessfulOnly = false,
    }))
    local DeathpoolLog = context.DeathpoolLog

    assertEquals(DeathpoolLog.showSuccessfulOnly, false, "history log should restore the saved all-history mode")
    assertEquals(DeathpoolLog.logSubtitle:GetText(), "All Predictions", "history log should restore the saved subtitle")
    assertEquals(DeathpoolLog.filterButton:GetText(), "SHOW SUCCESS ONLY", "history log should restore the saved filter action")
    assertEquals(DeathpoolLog.columnHeaders.time:GetText(), "Time", "history log should restore the time column label for all-history mode")
    assertEquals(DeathpoolLog.columnHeaders.sourceName:GetText(), "Source", "history log should use the source column label for all-history mode")
    assertEquals(DeathpoolLog.columnHeaders.level, nil, "history log should omit the level column for all-history mode")
end

local function testEscapeClosesMainWindow()
    local context = createUIContext({})
    local DeathpoolUI = context.DeathpoolUI
    local Deathpool = context.Deathpool
    local pressEscape = context.pressEscape
    Deathpool:Show()

    assertTruthy(pressEscape(), "escape should report that it closed a special frame")
    assertEquals(Deathpool:IsShown(), false, "escape should close the main window")

    Deathpool:Show()
    Deathpool.introDemoController:Show()
    assertTruthy(pressEscape(), "escape should still close the main window when the demo is visible")
    assertEquals(Deathpool:IsShown(), false, "escape should close the main window when the demo is visible")

    Deathpool:Show()
    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    assertEquals(_G.UISpecialFrames[1], nil, "collapsed main window should be removed from the WoW escape-close list")
    assertEquals(pressEscape(), false, "escape should not close the collapsed main window")
    assertTruthy(Deathpool:IsShown(), "collapsed main window should remain visible after escape")
end

local function testHelpWindowText()
    local context = createUIContext()
    local DeathpoolUI = context.DeathpoolUI
    local Deathpool = context.Deathpool
    local findRegionText = context.findRegionText
    local layout = DeathpoolUI.LAYOUT

    local helpText = findRegionText(Deathpool.helpFrame, "Hardcore Death Pool is a")
    assertTruthy(helpText, "help frame should contain the main help text")
    assertEquals(
        select(4, Deathpool.helpFrame.scrollFrame:GetPoint(2)),
        -(layout.outsideGutter + layout.scrollbarInset),
        "help scrollbar should clear the window inlay"
    )
    assertEquals(
        Deathpool.helpFrame.helpText:GetWidth(),
        Deathpool.helpFrame:GetWidth()
            - (layout.outsideGutter * 2)
            - layout.scrollbarWidth
            - layout.scrollbarInset,
        "help text should leave room for the scrollbar"
    )
    assertEquals(
        Deathpool.helpFrame.scrollContent:GetWidth(),
        Deathpool.helpFrame.helpText:GetWidth(),
        "help scroll content should match the scrollbar-aware text width"
    )
    assertEquals(Deathpool.githubLinkFrame:IsShown(), false, "GitHub link dialog should start hidden")
    assertEquals(
        Deathpool.githubLinkFrame.urlBox.template,
        "InputBoxTemplate",
        "GitHub link dialog should use the WoW input box template"
    )
    assertEquals(
        Deathpool.githubLinkFrame.urlBox:GetText(),
        DeathpoolUI.GetDownloadUrl(),
        "GitHub link field should contain the releases URL"
    )
    assertEquals(Deathpool.githubLinkFrame.okButton:GetText(), "OK", "GitHub link dialog should have an OK button")
    Deathpool.helpFrame:Show()
    Deathpool.helpFrame.downloadLink:GetScript("OnClick")()
    assertEquals(Deathpool.helpFrame:IsShown(), false, "clicking the download link should replace the help window")
    assertTruthy(Deathpool.githubLinkFrame:IsShown(), "clicking the download link should open the GitHub link dialog")
    assertTruthy(
        Deathpool.githubLinkFrame.backdropOverlay:IsShown(),
        "GitHub link dialog should show the main-window backdrop"
    )
    assertTruthy(Deathpool.githubLinkFrame.urlBox.hasFocus, "clicking the download link should focus the URL field")
    assertTruthy(Deathpool.githubLinkFrame.urlBox.highlightRange, "clicking the download link should select the URL text")

    Deathpool.githubLinkFrame.urlBox:SetText("temporary user edit")
    assertEquals(Deathpool.githubLinkFrame.urlBox:GetText(), "temporary user edit", "GitHub link field should allow user edits")
    Deathpool.githubLinkFrame.okButton:GetScript("OnClick")()
    assertEquals(Deathpool.githubLinkFrame:IsShown(), false, "OK should close the GitHub link dialog")
    assertEquals(Deathpool.githubLinkFrame.backdropOverlay:IsShown(), false, "OK should hide the GitHub link backdrop")
    assertEquals(Deathpool.helpFrame:IsShown(), false, "OK should leave the help window closed")

    Deathpool.helpFrame:Show()
    Deathpool.helpFrame.downloadLink:GetScript("OnClick")()
    assertEquals(
        Deathpool.githubLinkFrame.urlBox:GetText(),
        DeathpoolUI.GetDownloadUrl(),
        "GitHub link field should reset to the canonical URL each open"
    )
    Deathpool.githubLinkFrame.CloseButton:GetScript("OnClick")()
    assertEquals(Deathpool.helpFrame:IsShown(), false, "titlebar close should leave the help window closed")
end

local function testHelpModalBehavior()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenFirstRun = true,
        logWindowShown = true,
        lockedPrediction = false,
        draftPrediction = false,
        lastPrediction = false,
    }))
    local DeathpoolUI = context.DeathpoolUI
    local Deathpool = context.Deathpool
    local DeathpoolLog = context.DeathpoolLog

    Deathpool:Show()
    DeathpoolLog:Show()
    Deathpool:RefreshLockedPrediction()
    assertEquals(Deathpool.sourceEditBox:IsEnabled(), true, "test should start with editable prediction input")

    Deathpool.helpFrame:Show()

    assertEquals(Deathpool.helpFrame.backdropOverlay:IsShown(), true, "help backdrop should show when help is shown")
    assertEquals(DeathpoolLog:IsShown(), true, "help should allow the log window to remain open")
    assertEquals(DeathpoolCharacterState.logWindowShown, true, "help should not change the saved log preference")
    assertEquals(Deathpool.lockButton:IsEnabled(), false, "help modal should disable locking predictions")
    assertEquals(Deathpool.sourceEditBox:IsEnabled(), false, "help modal should disable source input")

    Deathpool.helpFrame:Hide()
    assertEquals(Deathpool.helpFrame.backdropOverlay:IsShown(), false, "help backdrop should hide when help is hidden")
    assertEquals(Deathpool.sourceEditBox:IsEnabled(), true, "closing help should restore source input")

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    assertEquals(Deathpool.isCollapsed, true, "test should start help from the mini-log state")
    assertEquals(DeathpoolLog:IsShown(), false, "collapsing should hide the expanded log before help opens")

    Deathpool.helpFrame:Show()

    assertEquals(Deathpool.isCollapsed, false, "showing help from the mini-log should expand the main window")
    assertEquals(DeathpoolCharacterState.collapsed, false, "showing help should persist the expanded main window")
    assertEquals(Deathpool.helpFrame:IsShown(), true, "showing help from the mini-log should keep help visible")
    assertEquals(Deathpool.helpFrame.backdropOverlay:IsShown(), true, "expanded help should show the backdrop")
    assertEquals(DeathpoolLog:IsShown(), true, "expanding for help should restore the desired log window")
    assertEquals(DeathpoolCharacterState.logWindowShown, true, "expanding for help should keep the saved log preference")

    local lockedContext = createUIContext(Fixtures.uiDatabase({
        hasSeenFirstRun = true,
        lockedPrediction = Fixtures.prediction(),
    }))
    local LockedDeathpool = lockedContext.Deathpool

    LockedDeathpool:RefreshLockedPrediction()
    assertEquals(LockedDeathpool.pauseButton:IsEnabled(), true, "test should start with an enabled pause action")

    LockedDeathpool.helpFrame:Show()
    assertEquals(LockedDeathpool.pauseButton:IsEnabled(), false, "help modal should disable the pause action")

    LockedDeathpool.helpFrame:Hide()
    assertEquals(LockedDeathpool.pauseButton:IsEnabled(), true, "closing help should restore pause action state")
end

local function testCollapseBehavior()
    local context = createUIContext({
        hasSeenFirstRun = true,
    })
    local DeathpoolUI = context.DeathpoolUI
    local Deathpool = context.Deathpool
    local DeathpoolDebug = context.DeathpoolDebug
    local DeathpoolLog = context.DeathpoolLog
    Deathpool.helpFrame:Show()
    DeathpoolLog:Show()
    DeathpoolDebug:Show()
    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    assertEquals(DeathpoolCharacterState.collapsed, true, "collapsed mode should persist state to SavedVariables")
    assertEquals(Deathpool.minimizeButton:GetNormalTexture(), "Interface\\Buttons\\UI-PlusButton-UP", "collapsed mode should flip the titlebar button art")
    assertEquals(Deathpool.minimizeButton:GetHighlightTexture(), "Interface\\Buttons\\UI-PlusButton-Hilight", "collapsed mode should use Blizzard highlight art")
    assertTruthy(Deathpool.collapsedLogHeaders[1]:IsShown(), "collapsed log headers should show in collapsed mode")
    assertTruthy(Deathpool.collapsedScoreDivider:IsShown(), "collapsed score divider should show in collapsed mode")
    assertTruthy(Deathpool.collapsedPointsValue:IsShown(), "collapsed score should show in collapsed mode")
    assertEquals(Deathpool.lockButton:IsShown(), false, "prediction controls should hide in collapsed mode")
    assertEquals(Deathpool.helpFrame:IsShown(), false, "collapsed mode should close the help window")
    assertEquals(DeathpoolLog:IsShown(), false, "collapsed mode should close the log window")
    assertTruthy(DeathpoolDebug:IsShown(), "collapsed mode should keep the debug window open")

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, false)
    assertEquals(DeathpoolCharacterState.collapsed, false, "expanded mode should persist state to SavedVariables")
    assertEquals(Deathpool.minimizeButton:GetNormalTexture(), "Interface\\Buttons\\UI-MinusButton-UP", "expanded mode should restore the titlebar button art")
    assertEquals(Deathpool.minimizeButton:GetHighlightTexture(), "Interface\\Buttons\\UI-MinusButton-Hilight", "expanded mode should restore Blizzard highlight art")
    assertTruthy(Deathpool.lockButton:IsShown(), "prediction controls should return in expanded mode")
    assertEquals(Deathpool.collapsedLogFrame:IsShown(), false, "expanded mode should hide the collapsed death log frame")
    assertEquals(Deathpool.collapsedScoreDivider:IsShown(), false, "expanded mode should hide the collapsed score divider")
    assertEquals(Deathpool.introDemoAttractPanel:IsShown(), false, "expanded mode should keep the intro marquee hidden outside demo mode")
    assertTruthy(Deathpool.helpFrame:IsShown(), "expanded mode should reopen the help window if it was open before collapsing")
    assertTruthy(DeathpoolLog:IsShown(), "expanded mode should reopen the log window if it was open before collapsing")
    assertEquals(Deathpool.lockButton:GetText(), "LOCKED IN", "restored help modal should keep prediction inputs locked")
    Deathpool.helpFrame:Hide()
    assertEquals(Deathpool.lockButton:GetText(), "LOCK IN", "closing restored help should restore the normal lock button label")

    DeathpoolLog:Hide()
    Deathpool.helpFrame:Show()
    Deathpool.helpFrame.downloadLink:GetScript("OnClick")()
    assertTruthy(Deathpool.githubLinkFrame:IsShown(), "test should start with the GitHub link dialog open")
    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    assertEquals(Deathpool.githubLinkFrame:IsShown(), false, "collapsed mode should close the GitHub link dialog")
    assertEquals(
        Deathpool.helpFrame:IsShown(),
        false,
        "collapsed mode should leave help closed after closing the GitHub link dialog"
    )
    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, false)
    assertEquals(
        Deathpool.helpFrame:IsShown(),
        false,
        "expanded mode should not reopen help after collapsing from the GitHub link dialog"
    )

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, false)
    assertEquals(
        Deathpool.helpFrame:IsShown(),
        false,
        "expanded mode should keep the help window closed if it was closed before collapsing"
    )
    assertEquals(
        DeathpoolLog:IsShown(),
        false,
        "expanded mode should keep the log window closed if it was closed before collapsing"
    )

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    Deathpool:GetScript("OnMouseUp")(Deathpool, "LeftButton")
    assertEquals(Deathpool.isCollapsed, false, "clicking the collapsed main window should expand it")
    assertEquals(DeathpoolCharacterState.collapsed, false, "clicking the collapsed main window should persist the expanded state")
end

local function testCollapsedDeathLogRowClickExpandsMainWindow()
    local context = createUIContext(Fixtures.uiDatabase({
        recentDeaths = {
            Fixtures.storedDeath(),
        },
    }))
    local DeathpoolUI = context.DeathpoolUI
    local Deathpool = context.Deathpool

    Deathpool:RefreshDeaths()
    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    Deathpool.collapsedLogFrame.rows[1]:GetScript("OnMouseUp")(Deathpool.collapsedLogFrame.rows[1], "LeftButton")

    assertEquals(Deathpool.isCollapsed, false, "clicking a collapsed death log row should expand the main window")
    assertEquals(DeathpoolCharacterState.collapsed, false, "clicking a collapsed death log row should persist the expanded state")
end

local function testBottomLogButtonBehavior()
    local context = createUIContext({
        hasSeenFirstRun = true,
    })
    local DeathpoolUI = context.DeathpoolUI
    local Deathpool = context.Deathpool
    local DeathpoolLog = context.DeathpoolLog
    local onClick = Deathpool.bottomLogButton:GetScript("OnClick")

    assertEquals(Deathpool.bottomLogButton:GetText(), "LOG", "bottom log button should start with the log label")

    onClick()
    assertTruthy(DeathpoolLog:IsShown(), "bottom log button should show the log window while expanded")

    onClick()
    assertEquals(DeathpoolLog:IsShown(), false, "bottom log button should hide the log window while expanded")

    DeathpoolLog:Show()
    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    assertEquals(DeathpoolLog:IsShown(), false, "collapsed mode should still hide the log window initially")

    onClick()
    assertTruthy(DeathpoolLog:IsShown(), "bottom log button should show the log window while collapsed")
    assertEquals(
        Deathpool.collapsedWindowStates.logFrame,
        true,
        "bottom log button should remember the log window state while collapsed"
    )

    onClick()
    assertEquals(DeathpoolLog:IsShown(), false, "bottom log button should hide the log window while collapsed")
    assertEquals(
        Deathpool.collapsedWindowStates.logFrame,
        false,
        "bottom log button should clear the remembered log window state while collapsed"
    )
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

local function testMinimizeButtonUsesGameInfoCallout()
    local context = createUIContext({})
    local Deathpool = context.Deathpool

    Deathpool:Show()
    Deathpool.minimizeButton:GetScript("OnEnter")(Deathpool.minimizeButton)
    waitForGameInfoCallout(Deathpool)

    assertEquals(Deathpool.gameInfoCallout:IsShown(), true, "hovering the minimize button should show the game info callout")
    assertEquals(
        Deathpool.gameInfoCallout.lines[1].left,
        "Show the mini log",
        "minimize button should use the mini-log game info callout text"
    )

    Deathpool.minimizeButton:GetScript("OnLeave")()
    assertEquals(Deathpool.gameInfoCallout:IsShown(), false, "leaving the minimize button should hide the game info callout")
end

local function testDesiredLogWindowStateReopensWhenMainWindowShowsOrExpands()
    local context = createUIContext(Fixtures.uiDatabase({
        logWindowShown = true,
    }))
    local DeathpoolUI = context.DeathpoolUI
    local Deathpool = context.Deathpool
    local DeathpoolLog = context.DeathpoolLog

    Deathpool:Hide()
    DeathpoolUI.ApplyDesiredLogWindowState(Deathpool, DeathpoolCharacterState)
    assertEquals(DeathpoolLog:IsShown(), false, "desired log state should stay hidden while the main window is hidden")

    Deathpool:Show()
    DeathpoolUI.ApplyDesiredLogWindowState(Deathpool, DeathpoolCharacterState)
    assertTruthy(DeathpoolLog:IsShown(), "desired log state should open the log when the main window opens")

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    assertEquals(DeathpoolLog:IsShown(), false, "collapsing should still hide the log window")

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, false)
    assertTruthy(DeathpoolLog:IsShown(), "expanding should reopen the log when the desired state is open")

    DeathpoolUI.SetLogWindowShown(Deathpool, DeathpoolCharacterState, false)
    assertEquals(DeathpoolCharacterState.logWindowShown, false, "changing the log toggle should persist the desired closed state")

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, false)
    assertEquals(DeathpoolLog:IsShown(), false, "expanding should keep the log hidden when the desired state is closed")
end

local function testAuxiliaryWindowRefreshUsesResolvedDemoMode()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenFirstRun = true,
        logWindowShown = true,
    }))
    local Deathpool = context.Deathpool
    local DeathpoolLog = context.DeathpoolLog

    Deathpool:Show()
    DeathpoolLog:Show()
    Deathpool.helpFrame:Show()
    Deathpool.helpFrame.downloadLink:GetScript("OnClick")()

    Deathpool.introDemoController:Show()
    Deathpool:RefreshAuxiliaryWindowState()

    assertEquals(Deathpool.bottomLogButton:IsEnabled(), false, "demo mode should disable the log button through auxiliary refresh")
    assertEquals(Deathpool.helpButton:IsEnabled(), false, "demo mode should disable the help button through auxiliary refresh")
    assertEquals(DeathpoolLog:IsShown(), false, "demo mode should close the log window through auxiliary refresh")
    assertEquals(Deathpool.helpFrame:IsShown(), false, "demo mode should close the help window through auxiliary refresh")
    assertEquals(Deathpool.githubLinkFrame:IsShown(), false, "demo mode should close the GitHub link dialog")
    assertEquals(Deathpool.collapsedWindowStates.logFrame, false, "demo mode should clear remembered log state")
    assertEquals(Deathpool.collapsedWindowStates.helpFrame, false, "demo mode should clear remembered help state")

    Deathpool.introDemoController:Dismiss()
    Deathpool:RefreshAuxiliaryWindowState()

    assertEquals(Deathpool.bottomLogButton:IsEnabled(), true, "normal mode should re-enable the log button after demo")
    assertEquals(Deathpool.helpButton:IsEnabled(), true, "normal mode should re-enable the help button after demo")
    assertEquals(DeathpoolLog:IsShown(), true, "normal mode should restore the desired log window state")
end

local function testCollapsedWindowPositionIsRemembered()
    local context = createUIContext({})
    local DeathpoolUI = context.DeathpoolUI
    local Deathpool = context.Deathpool

    Deathpool:ClearAllPoints()
    Deathpool:SetPoint("CENTER", UIParent, "CENTER", 120, -60)
    DeathpoolUI.SaveWindowPosition(Deathpool, DeathpoolCharacterState, false)

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    assertTruthy(Deathpool.points[1] ~= nil, "collapsing without a saved minimized anchor should keep a window anchor")

    Deathpool:ClearAllPoints()
    Deathpool:SetPoint("CENTER", UIParent, "CENTER", -240, 90)
    Deathpool:GetScript("OnDragStop")(Deathpool)
    assertTruthy(DeathpoolCharacterState.collapsedWindowPosition ~= nil, "dragging while minimized should save the minimized position")

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, false)
    assertTruthy(Deathpool.points[1] ~= nil, "expanding should restore an expanded window anchor")

    Deathpool:ClearAllPoints()
    Deathpool:SetPoint("CENTER", UIParent, "CENTER", 360, -180)
    Deathpool:GetScript("OnDragStop")(Deathpool)
    assertTruthy(DeathpoolCharacterState.windowPosition ~= nil, "dragging while expanded should update the expanded position")

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    assertTruthy(Deathpool.points[1] ~= nil, "collapsing again should restore a minimized window anchor")
end

local function testCollapsedWindowHeightCanBeResizedAndRestored()
    local recentDeaths = {
        Fixtures.storedDeath({
            timestamp = 100,
            name = "One",
            sourceName = "Source One",
        }),
        Fixtures.storedDeath({
            timestamp = 101,
            name = "Two",
            sourceName = "Source Two",
        }),
        Fixtures.storedDeath({
            timestamp = 102,
            name = "Three",
            sourceName = "Source Three",
        }),
        Fixtures.storedDeath({
            timestamp = 103,
            name = "Four",
            sourceName = "Source Four",
        }),
        Fixtures.storedDeath({
            timestamp = 104,
            name = "Five",
            sourceName = "Source Five",
        }),
    }

    local context = createUIContext({
        recentDeaths = recentDeaths,
        deathHistory = recentDeaths,
    })
    local DeathpoolUI = context.DeathpoolUI
    local Deathpool = context.Deathpool

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    assertEquals(Deathpool:GetWidth(), 350, "collapsed mode should keep the fixed collapsed width before resizing")
    assertEquals(Deathpool:GetHeight(), 165, "collapsed mode should start with the default collapsed height")
    assertEquals(Deathpool.collapsedResizeHandle:IsShown(), true, "collapsed mode should show the resize handle")
    assertTruthy(Deathpool.collapsedLogFrame.rows[5]:IsShown(), "default collapsed height should show five visible rows")
    assertEquals(Deathpool.collapsedLogFrame.rows[1].sourceName:GetText(), "Source One", "default collapsed height should keep the oldest visible row at the top")
    assertEquals(Deathpool.collapsedLogFrame.rows[5].sourceName:GetText(), "Source Five", "default collapsed height should keep the newest visible row at the bottom")

    Deathpool:SetSize(410, 98)

    assertEquals(Deathpool:GetWidth(), 350, "collapsed resize should keep the width fixed")
    assertEquals(Deathpool:GetHeight(), 100, "collapsed resize should allow shrinking to the one-row height")
    assertEquals(DeathpoolCharacterState.collapsedWindowHeight, 100, "collapsed resize should persist the new height")
    assertTruthy(Deathpool.collapsedLogFrame.rows[1]:IsShown(), "collapsed resize should keep the newest row visible")
    assertEquals(Deathpool.collapsedLogFrame.rows[1].sourceName:GetText(), "Source Five", "collapsed resize should keep the newest death in the visible row")
    assertEquals(Deathpool.collapsedLogFrame.rows[2]:IsShown(), false, "collapsed resize should hide rows beyond the one-row limit")

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, false)
    assertEquals(Deathpool.collapsedResizeHandle:IsShown(), false, "expanded mode should hide the resize handle")

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    assertEquals(Deathpool:GetHeight(), 100, "re-collapsing should restore the persisted collapsed height")
    assertEquals(Deathpool.collapsedLogFrame.rows[2]:IsShown(), false, "restored one-row height should still limit the collapsed list")
end

local function testLogTitlebarDragMovesMainWindow()
    local context = createUIContext({})
    local DeathpoolUI = context.DeathpoolUI
    local Deathpool = context.Deathpool
    local DeathpoolLog = context.DeathpoolLog

    DeathpoolLog.dragHandle:GetScript("OnDragStart")()
    assertTruthy(Deathpool.startedMoving, "dragging the log titlebar should start moving the main window")

    Deathpool:ClearAllPoints()
    Deathpool:SetPoint("CENTER", UIParent, "CENTER", 210, -110)
    DeathpoolLog.dragHandle:GetScript("OnDragStop")()
    assertTruthy(Deathpool.stoppedMoving, "releasing the log titlebar should stop moving the main window")
    assertTruthy(DeathpoolCharacterState.windowPosition ~= nil, "dragging from the log titlebar should save the main window position")

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    Deathpool:ClearAllPoints()
    Deathpool:SetPoint("CENTER", UIParent, "CENTER", -150, 55)
    DeathpoolLog.dragHandle:GetScript("OnDragStop")()
    assertTruthy(DeathpoolCharacterState.collapsedWindowPosition ~= nil, "dragging from the log titlebar while minimized should save the minimized position")
end

local function testSetupTitlebarDragMovesMainWindow()
    local context = createUIContext({})
    local DeathpoolUI = context.DeathpoolUI
    local Deathpool = context.Deathpool
    local setupTitlebar = Deathpool.setupFrame.titlebarDragHandle

    setupTitlebar:GetScript("OnDragStart")()
    assertTruthy(Deathpool.startedMoving, "dragging the setup titlebar should start moving the main window")

    Deathpool:ClearAllPoints()
    Deathpool:SetPoint("CENTER", UIParent, "CENTER", 180, -95)
    setupTitlebar:GetScript("OnDragStop")()
    assertTruthy(Deathpool.stoppedMoving, "releasing the setup titlebar should stop moving the main window")
    assertTruthy(DeathpoolCharacterState.windowPosition ~= nil, "dragging from the setup titlebar should save the main window position")

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    Deathpool:ClearAllPoints()
    Deathpool:SetPoint("CENTER", UIParent, "CENTER", -120, 40)
    setupTitlebar:GetScript("OnDragStop")()
    assertTruthy(
        DeathpoolCharacterState.collapsedWindowPosition ~= nil,
        "dragging from the setup titlebar while minimized should save the minimized position"
    )
end

local function testHelpModalDragMovesMainWindow()
    local context = createUIContext({})
    local DeathpoolUI = context.DeathpoolUI
    local Deathpool = context.Deathpool
    local helpTitlebar = Deathpool.helpFrame.titlebarDragHandle
    local helpBackdrop = Deathpool.helpFrame.backdropOverlay

    helpTitlebar:GetScript("OnDragStart")()
    assertTruthy(Deathpool.startedMoving, "dragging the help titlebar should start moving the main window")

    Deathpool:ClearAllPoints()
    Deathpool:SetPoint("CENTER", UIParent, "CENTER", 160, -80)
    helpTitlebar:GetScript("OnDragStop")()
    assertTruthy(Deathpool.stoppedMoving, "releasing the help titlebar should stop moving the main window")
    assertTruthy(DeathpoolCharacterState.windowPosition ~= nil, "dragging from the help titlebar should save the main window position")

    Deathpool.startedMoving = false
    Deathpool.stoppedMoving = false
    helpBackdrop:GetScript("OnDragStart")()
    assertTruthy(Deathpool.startedMoving, "dragging the help backdrop should start moving the main window")

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    Deathpool:ClearAllPoints()
    Deathpool:SetPoint("CENTER", UIParent, "CENTER", -90, 35)
    helpBackdrop:GetScript("OnDragStop")()
    assertTruthy(Deathpool.stoppedMoving, "releasing the help backdrop should stop moving the main window")
    assertTruthy(
        DeathpoolCharacterState.collapsedWindowPosition ~= nil,
        "dragging from the help backdrop while minimized should save the minimized position"
    )
end

local function testGitHubLinkDialogClosesWithMainWindow()
    local context = createUIContext(Fixtures.uiDatabase({
        hasSeenFirstRun = true,
    }))
    local Deathpool = context.Deathpool

    Deathpool:Show()
    Deathpool.helpFrame:Show()
    Deathpool.helpFrame.downloadLink:GetScript("OnClick")()

    assertTruthy(Deathpool.githubLinkFrame:IsShown(), "test should start with the GitHub link dialog open")

    Deathpool:Hide()

    assertEquals(Deathpool.githubLinkFrame:IsShown(), false, "hiding the main window should close the GitHub link dialog")
    assertEquals(Deathpool.helpFrame:IsShown(), false, "hiding the main window should leave help closed")
end

local function testSetupTintFollowsSetupWindowVisibility()
    local context = createUIContext({})
    local Deathpool = context.Deathpool

    Deathpool.setupFrame:Show()
    assertEquals(
        Deathpool.setupFrame.backdropOverlay:IsShown(),
        true,
        "setup backdrop should show when the setup window is shown directly"
    )

    Deathpool.setupFrame:Hide()
    assertEquals(
        Deathpool.setupFrame.backdropOverlay:IsShown(),
        false,
        "setup backdrop should hide when the setup window is hidden directly"
    )
    assertEquals(Deathpool.setupActive, false, "hiding setup should restore main window interaction state")
end

testModuleSurface()
testStoredDeathTimestampFormatting()
testUIModeResolverPrioritizesSetup()
testUIModeResolverPrioritizesIntroDemoBeforeCollapsedAndPrompts()
testUIModeResolverHandlesCollapsedMode()
testUIModeResolverHandlesNormalPromptsAndLocks()
testUIModeResolverHandlesHelpModal()
testInitializeReturnsFrames()
testInitializeRestoresSavedHistoryFilterMode()
testEscapeClosesMainWindow()
testHelpWindowText()
testHelpModalBehavior()
testCollapseBehavior()
testCollapsedDeathLogRowClickExpandsMainWindow()
testBottomLogButtonBehavior()
testMinimizeButtonUsesGameInfoCallout()
testDesiredLogWindowStateReopensWhenMainWindowShowsOrExpands()
testAuxiliaryWindowRefreshUsesResolvedDemoMode()
testCollapsedWindowPositionIsRemembered()
testLogTitlebarDragMovesMainWindow()
testSetupTitlebarDragMovesMainWindow()
testHelpModalDragMovesMainWindow()
testGitHubLinkDialogClosesWithMainWindow()
testSetupTintFollowsSetupWindowVisibility()
testCollapsedWindowHeightCanBeResizedAndRestored()

suite:finish()

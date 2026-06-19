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
end

local function testInitializeReturnsFrames()
    local context = createUIContext()
    local Deathpool = context.Deathpool
    local DeathpoolDebug = context.DeathpoolDebug
    local DeathpoolLog = context.DeathpoolLog

    assertTruthy(Deathpool, "Initialize should return the main frame")
    assertTruthy(DeathpoolDebug, "Initialize should return the debug frame")
    assertTruthy(DeathpoolLog, "Initialize should return the history log frame")
    assertEquals(Deathpool:GetWidth(), 650, "main frame should use the narrowed expanded width")
    assertEquals(Deathpool:GetHeight(), 424, "main frame should use the reduced expanded height")
    assertEquals(DeathpoolLog:GetHeight(), 424, "history log should use the reduced expanded height")
    assertEquals(DeathpoolLog:IsShown(), false, "history log should start hidden by default")
    assertTruthy(DeathpoolLog.dragHandle, "history log should create a titlebar drag handle")
    assertTruthy(#Deathpool.deathRows > 0, "main frame should create recent death rows")
    assertTruthy(#DeathpoolLog.rows > 0, "log frame should create history rows")
    assertTruthy(DeathpoolLog.filterButton, "log frame should create a history filter button")
    assertEquals(DeathpoolLog.filterButton:GetText(), "SHOW ALL", "history filter button should default to the all-history action")
    assertEquals(DeathpoolLog.columnHeaders.awardedPoints.justifyH, "RIGHT", "history log should right justify the points header")
    assertEquals(DeathpoolLog.rows[1].awardedPoints.justifyH, "RIGHT", "history log should right justify points cells")
    assertEquals(
        select(4, DeathpoolLog.columnHeaders.awardedPoints:GetPoint(1)),
        select(4, DeathpoolLog.rows[1]:GetPoint(1)) + select(4, DeathpoolLog.rows[1].awardedPoints:GetPoint(1)),
        "history log points header should align with the points column"
    )
    assertTruthy(Deathpool.helpFrame, "main frame should keep a reference to the help frame")
    assertTruthy(Deathpool.helpButton, "main frame should keep a reference to the help button")
    assertTruthy(Deathpool.helpFrame.backdropOverlay, "help window should create a main-window backdrop overlay")
    assertTruthy(Deathpool.helpFrame.titlebarDragHandle, "help window should create a titlebar drag handle")
    assertTruthy(Deathpool.introDemoController, "main frame should keep a reference to the intro demo controller")
    assertTruthy(Deathpool.lockButton, "main frame should keep a reference to the lock button")
    assertTruthy(Deathpool.pauseButton, "main frame should keep a reference to the pause button")
    assertTruthy(Deathpool.bottomLogButton, "main frame should keep a reference to the bottom log button")
    assertTruthy(Deathpool.gameInfoCallout, "main frame should keep a reference to the game info callout")
    assertEquals(Deathpool.gameInfoCallout:IsShown(), false, "game info callout should start hidden")
    assertTruthy(Deathpool.recentDeathsFrame, "main frame should create the reusable recent deaths frame")
    assertTruthy(Deathpool.deathRows[1].awardedPoints, "main frame should create the total points cell in recent death rows")
    assertEquals(Deathpool.deathRows[1].awardedPoints.justifyH, "RIGHT", "main frame should right justify recent death points")
    assertEquals(Deathpool.deathRows[1].pointsTooltipTarget, nil, "main frame should omit the base points hover target from recent death rows")
    assertEquals(Deathpool.deathRows[1].multiplier, nil, "main frame should omit the combo cell from recent death rows")
    assertEquals(Deathpool.deathRows[1].streakMultiplier, nil, "main frame should omit the streak cell from recent death rows")
    assertTruthy(Deathpool.collapsedLogFrame, "main frame should create the collapsed death log frame")
    assertTruthy(#Deathpool.collapsedLogFrame.rows > 0, "main frame should create collapsed death log rows")
    assertTruthy(#(Deathpool.collapsedLogHeaders or {}) > 0, "main frame should create collapsed death log headers")
    assertTruthy(Deathpool.collapsedScoreDivider, "main frame should create the collapsed score divider")
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
    assertEquals(select(5, Deathpool.lockButton:GetPoint(1)), 22, "lock button should preserve its bottom gutter")
    assertEquals(select(5, DeathpoolLog.filterButton:GetPoint(1)), 15, "history filter should preserve its bottom gutter")
    assertTruthy(Deathpool.sourceEditBox, "main frame should create the source edit box")
    assertTruthy(Deathpool.zoneEditBox, "main frame should create the zone edit box")
    assertTruthy(DeathpoolDebug.detailLabels, "debug frame should keep references to detail labels")
    assertEquals(DeathpoolDebug.detailValues.sourceMessage.kind, "EditBox", "debug frame should use an edit box for the raw message")
    assertEquals(DeathpoolDebug.detailValues.sourceMessage:GetWidth(), 516, "debug raw message should keep a gutter on both sides")
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
    local Deathpool = context.Deathpool
    local findRegionText = context.findRegionText

    local helpText = findRegionText(Deathpool.helpFrame, "Hardcore Deathpool is a")
    assertTruthy(helpText, "help frame should contain the main help text")
    assertEquals(Deathpool.helpFrame.downloadUrlBox:IsShown(), false, "download url box should start hidden")
    Deathpool.helpFrame.downloadLink:GetScript("OnClick")()
    assertTruthy(Deathpool.helpFrame.downloadUrlBox:IsShown(), "clicking the download link should reveal the copy box")
    assertTruthy(Deathpool.helpFrame.downloadUrlBox.hasFocus, "clicking the download link should focus the copy box")
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

    Deathpool.introDemoController:Show()
    Deathpool:RefreshAuxiliaryWindowState()

    assertEquals(Deathpool.bottomLogButton:IsEnabled(), false, "demo mode should disable the log button through auxiliary refresh")
    assertEquals(Deathpool.helpButton:IsEnabled(), false, "demo mode should disable the help button through auxiliary refresh")
    assertEquals(DeathpoolLog:IsShown(), false, "demo mode should close the log window through auxiliary refresh")
    assertEquals(Deathpool.helpFrame:IsShown(), false, "demo mode should close the help window through auxiliary refresh")
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
        }),
        Fixtures.storedDeath({
            timestamp = 101,
            name = "Two",
        }),
        Fixtures.storedDeath({
            timestamp = 102,
            name = "Three",
        }),
        Fixtures.storedDeath({
            timestamp = 103,
            name = "Four",
        }),
        Fixtures.storedDeath({
            timestamp = 104,
            name = "Five",
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
    assertEquals(Deathpool:GetHeight(), 176, "collapsed mode should start with the default collapsed height")
    assertEquals(Deathpool.collapsedResizeHandle:IsShown(), true, "collapsed mode should show the resize handle")
    assertTruthy(Deathpool.collapsedLogFrame.rows[5]:IsShown(), "default collapsed height should show five visible rows")
    assertEquals(Deathpool.collapsedLogFrame.rows[1].name:GetText(), "One", "default collapsed height should keep the oldest visible row at the top")
    assertEquals(Deathpool.collapsedLogFrame.rows[5].name:GetText(), "Five", "default collapsed height should keep the newest visible row at the bottom")

    Deathpool:SetSize(410, 98)

    assertEquals(Deathpool:GetWidth(), 350, "collapsed resize should keep the width fixed")
    assertEquals(Deathpool:GetHeight(), 98, "collapsed resize should allow shrinking to the one-row height")
    assertEquals(DeathpoolCharacterState.collapsedWindowHeight, 98, "collapsed resize should persist the new height")
    assertTruthy(Deathpool.collapsedLogFrame.rows[1]:IsShown(), "collapsed resize should keep the newest row visible")
    assertEquals(Deathpool.collapsedLogFrame.rows[1].name:GetText(), "Five", "collapsed resize should keep the newest death in the visible row")
    assertEquals(Deathpool.collapsedLogFrame.rows[2]:IsShown(), false, "collapsed resize should hide rows beyond the one-row limit")

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, false)
    assertEquals(Deathpool.collapsedResizeHandle:IsShown(), false, "expanded mode should hide the resize handle")

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    assertEquals(Deathpool:GetHeight(), 98, "re-collapsing should restore the persisted collapsed height")
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
testSetupTintFollowsSetupWindowVisibility()
testCollapsedWindowHeightCanBeResizedAndRestored()

suite:finish()

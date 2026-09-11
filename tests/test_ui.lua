local assert = require("luassert")
describe("UI state and modes", function()
    local UITestContext = require("tests.support_ui_test_context")
    local testContext
    local Fixtures
    local createUIContext
    local env

    before_each(function()
        testContext = UITestContext.Create()
        Fixtures = testContext.Fixtures
        env = nil
        createUIContext = function(...)
            local context = testContext.createUIContext(...)
            env = context.env
            return context
        end
    end)

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

    describe("module surface and formatting", function()
        it("exposes core UI modules", function()
            local context = createUIContext()
            local DeathpoolUI = context.DeathpoolUI

            assert.is_function(context.DeathpoolUIAutocomplete.GetSourceSuggestions, "autocomplete UI should expose source suggestions")
            assert.is_function(context.DeathpoolUIAutocomplete.CreateSuggestionDropdown, "autocomplete UI should expose dropdown creation")
            assert.is_function(DeathpoolUI.SetWindowCollapsed, "UI module should expose SetWindowCollapsed")
            assert.is_function(context.DeathpoolUIDeathLogList.CreateDeathLogList, "death log list UI should expose the flexible list builder")
            assert.is_function(context.DeathpoolUIDeathLogList.RefreshDeathLogRows, "death log list UI should expose the flexible list refresher")
            assert.is_function(context.DeathpoolUIDebug.CreateDebugWindow, "debug UI should expose debug window creation")
            assert.is_function(context.DeathpoolUIDemo.GetIntroDemoPrediction, "demo UI should expose intro prediction data")
            assert.is_function(context.DeathpoolUIHelp.CreateHelpWindow, "help UI should expose help window creation")
            assert.is_function(context.DeathpoolUILog.CreateHistoryWindow, "history UI should expose history window creation")
            assert.is_function(context.DeathpoolUIMain.Initialize, "main UI should expose Initialize")
            assert.is_function(context.DeathpoolUIMainCollapsed.CreateMainCollapsedSection, "collapsed main UI should expose section creation")
            assert.is_function(context.DeathpoolUIMainPrediction.CreateMainPredictionSection, "prediction main UI should expose section creation")
            assert.is_function(context.DeathpoolUIMainRecentDeaths.CreateMainRecentDeathsSection, "recent deaths main UI should expose section creation")
            assert.is_function(context.DeathpoolUIRefresh.AttachRefreshMethods, "refresh UI should expose refresh attachment")
            assert.is_function(context.DeathpoolUITooltip.ShowStandardizedTooltip, "tooltip UI should expose standardized tooltip display")
        end)

        it("exposes stored-death formatting APIs", function()
            local context = createUIContext()
            local DeathpoolUI = context.DeathpoolUI

            assert.is_function(DeathpoolUI.GetStoredDeathTime, "UI module should expose stored death time formatting")
            assert.is_function(DeathpoolUI.GetStoredDeathDate, "UI module should expose stored death date formatting")
            assert.is_function(DeathpoolUI.GetStoredDeathDateTime, "UI module should expose stored death date/time formatting")
        end)

        it("exposes setup APIs", function()
            local context = createUIContext()
            local DeathpoolSetup = context.ns.DeathpoolSetup
            local DeathpoolUISetup = context.ns.DeathpoolUISetup

            assert.is_function(DeathpoolSetup.GetState, "setup controller should expose GetState")
            assert.is_function(DeathpoolSetup.ShouldShowOnMainWindowOpen, "setup controller should expose first-open eligibility")
            assert.is_function(DeathpoolSetup.EnableDeathAnnouncements, "setup controller should expose death announcement action")
            assert.is_function(DeathpoolSetup.JoinHardcoreDeathsChannel, "setup controller should expose channel join action")
            assert.is_function(DeathpoolUISetup.ShowOnMainWindowOpen, "setup UI should expose first-open show behavior")
            assert.is_function(DeathpoolUISetup.Show, "setup UI should expose manual show behavior")
            assert.is_function(DeathpoolUISetup.Refresh, "setup UI should expose refresh behavior")
            assert.is_function(DeathpoolUISetup.CreateWindow, "setup UI should expose setup window creation")
        end)

        it("exposes mode-resolution APIs", function()
            local context = createUIContext()
            local DeathpoolUIMode = context.ns.DeathpoolUIMode

            assert.is_function(DeathpoolUIMode.Resolve, "UI mode resolver should expose Resolve")
            assert.is_function(DeathpoolUIMode.IsDemoMode, "UI mode resolver should expose demo mode predicate")
            assert.is_function(DeathpoolUIMode.IsCollapsedMode, "UI mode resolver should expose collapsed mode predicate")
            assert.is_function(DeathpoolUIMode.IsNormalMode, "UI mode resolver should expose normal mode predicate")
            assert.is_function(DeathpoolUIMode.HasModal, "UI mode resolver should expose modal predicate")
            assert.is_function(DeathpoolUIMode.IsSetupModal, "UI mode resolver should expose setup modal predicate")
            assert.is_function(DeathpoolUIMode.IsHelpModal, "UI mode resolver should expose help modal predicate")
        end)

        it("formats stored death timestamps", function()
            local context = createUIContext()
            local DeathpoolUI = context.DeathpoolUI
            local timestampOnlyDeath = Fixtures.storedDeath({
                timestamp = 12345,
            })

            assert.equals(
                env.date("%H:%M", 12345),
                DeathpoolUI.GetStoredDeathTime(timestampOnlyDeath),
                "stored death time should be derived from the timestamp"
            )
            assert.equals(
                env.date("%B %d, %Y", 12345),
                DeathpoolUI.GetStoredDeathDate(timestampOnlyDeath),
                "stored death date should be derived from the timestamp"
            )
            assert.equals(
                env.date("%B %d, %Y", 12345) .. " " .. env.date("%H:%M", 12345),
                DeathpoolUI.GetStoredDeathDateTime(timestampOnlyDeath),
                "stored death date time should be derived from the timestamp"
            )

            local missingTimestampDeath = Fixtures.storedDeath({
                timestamp = false,
            })
            assert.equals(
                env.date("%H:%M", 0),
                DeathpoolUI.GetStoredDeathTime(missingTimestampDeath),
                "stored death time should display the epoch fallback when the timestamp is missing"
            )
            assert.equals(
                env.date("%B %d, %Y", 0),
                DeathpoolUI.GetStoredDeathDate(missingTimestampDeath),
                "stored death date should display the epoch fallback when the timestamp is missing"
            )
            assert.equals(
                env.date("%B %d, %Y", 0) .. " " .. env.date("%H:%M", 0),
                DeathpoolUI.GetStoredDeathDateTime(missingTimestampDeath),
                "stored death date time should display the epoch fallback when the timestamp is missing"
            )
        end)
    end)

    describe("mode resolution", function()
        it("prioritizes setup", function()
            local context = createUIContext()
            local Deathpool = context.Deathpool
            local DeathpoolUIMode = context.ns.DeathpoolUIMode

            Deathpool.helpFrame:Show()
            Deathpool.setupFrame:Show()
            setFakeIntroDemoActive(Deathpool)

            local mode = DeathpoolUIMode.Resolve(Deathpool, buildModeDisplayState(), env.DeathpoolCharacterState)

            assert.equals("demo", mode.mode, "setup should preserve the underlying intro demo mode")
            assert.equals("setup", mode.modal, "setup should take modal priority over help")
            assert.equals(true, DeathpoolUIMode.IsDemoMode(mode), "setup over demo should report demo mode through predicate")
            assert.equals(true, DeathpoolUIMode.HasModal(mode), "setup should report modal state through predicate")
            assert.equals(true, DeathpoolUIMode.IsSetupModal(mode), "setup should report setup modal through predicate")
            assert.equals(false, DeathpoolUIMode.IsHelpModal(mode), "setup should not report help modal through predicate")
            assert.equals(nil, mode.prompt, "setup mode should suppress normal prompts")
            assert.equals(true, mode.inputsLocked, "setup mode should lock prediction inputs")
            assert.equals(true, mode.mainBlocked, "setup mode should block the main window")
            assert.equals(true, mode.showRecentDeathRows, "setup mode should keep expanded death row data visible-ready")
            assert.equals(false, mode.showWaitingHelp, "setup mode should hide waiting help")
        end)

        it("prioritizes intro demo before collapsed state and prompts", function()
            local context = createUIContext(Fixtures.uiDatabase({
                hasSeenFirstRun = false,
            }))
            local Deathpool = context.Deathpool
            local DeathpoolUI = context.DeathpoolUI
            local DeathpoolUIMode = context.ns.DeathpoolUIMode

            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)
            setFakeIntroDemoActive(Deathpool)

            local mode = DeathpoolUIMode.Resolve(Deathpool, buildModeDisplayState(), env.DeathpoolCharacterState)

            assert.equals("demo", mode.mode, "intro demo should take priority over collapsed and first-run prompt state")
            assert.equals(nil, mode.modal, "intro demo without overlay should not report a modal")
            assert.equals(true, DeathpoolUIMode.IsDemoMode(mode), "intro demo should report demo mode through predicate")
            assert.equals(false, DeathpoolUIMode.HasModal(mode), "intro demo should not report modal state through predicate")
            assert.equals(nil, mode.prompt, "intro demo should suppress normal prompts")
            assert.equals(true, mode.inputsLocked, "intro demo should lock prediction inputs")
            assert.equals(false, mode.mainBlocked, "intro demo should keep the main window available for ending the demo")
            assert.equals(true, mode.showRecentDeathRows, "intro demo should show demo death rows")
            assert.equals(false, mode.showWaitingHelp, "intro demo should hide waiting help")
        end)

        it("handles collapsed mode", function()
            local context = createUIContext()
            local Deathpool = context.Deathpool
            local DeathpoolUI = context.DeathpoolUI
            local DeathpoolUIMode = context.ns.DeathpoolUIMode

            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)

            local mode = DeathpoolUIMode.Resolve(Deathpool, buildModeDisplayState(), env.DeathpoolCharacterState)

            assert.equals("collapsed", mode.mode, "collapsed mode should suppress expanded prompt behavior")
            assert.equals(nil, mode.modal, "collapsed mode should not report a modal")
            assert.equals(true, DeathpoolUIMode.IsCollapsedMode(mode), "collapsed mode should report through predicate")
            assert.equals(false, DeathpoolUIMode.HasModal(mode), "collapsed mode should not report modal state through predicate")
            assert.equals(nil, mode.prompt, "collapsed mode should not show expanded prompts")
            assert.equals(false, mode.inputsLocked, "collapsed mode should inherit unlocked prediction inputs")
            assert.equals(false, mode.mainBlocked, "collapsed mode should not block the main window")
            assert.equals(true, mode.showRecentDeathRows, "collapsed mode should keep expanded death row data visible-ready")
            assert.equals(false, mode.showWaitingHelp, "collapsed mode should hide waiting help")
        end)

        it("resolves the first-run prompt", function()
            local context = createUIContext(Fixtures.uiDatabase({
                hasSeenFirstRun = false,
            }))
            local Deathpool = context.Deathpool
            local DeathpoolUIMode = context.ns.DeathpoolUIMode

            local firstRunMode = DeathpoolUIMode.Resolve(Deathpool, buildModeDisplayState(), env.DeathpoolCharacterState)
            assert.equals("normal", firstRunMode.mode, "first-run prompt should stay in normal mode")
            assert.equals(nil, firstRunMode.modal, "first-run prompt should not report a modal")
            assert.equals(true, DeathpoolUIMode.IsNormalMode(firstRunMode), "first-run prompt should report normal mode through predicate")
            assert.equals(false, DeathpoolUIMode.HasModal(firstRunMode), "first-run prompt should not report modal state through predicate")
            assert.equals("firstRun", firstRunMode.prompt, "normal mode should surface the first-run prompt")
            assert.equals(false, firstRunMode.inputsLocked, "first-run prompt should leave prediction inputs unlocked")
            assert.equals(false, firstRunMode.mainBlocked, "first-run prompt should not block the main window")
            assert.equals(false, firstRunMode.showRecentDeathRows, "first-run prompt should hide expanded death rows")
            assert.equals(false, firstRunMode.showWaitingHelp, "first-run prompt should hide waiting help")
        end)

        it("delays waiting help until its threshold", function()
            local context = createUIContext(Fixtures.uiDatabase({
                hasSeenFirstRun = true,
            }))
            local Deathpool = context.Deathpool
            local DeathpoolUIMode = context.ns.DeathpoolUIMode
            local waitingMode = DeathpoolUIMode.Resolve(Deathpool, buildModeDisplayState(), env.DeathpoolCharacterState)
            assert.equals("normal", waitingMode.mode, "waiting prompt should stay in normal mode")
            assert.equals(nil, waitingMode.modal, "waiting prompt should not report a modal")
            assert.equals("waiting", waitingMode.prompt, "normal mode should surface waiting prompt with no deaths")
            assert.equals(false, waitingMode.inputsLocked, "waiting prompt should leave prediction inputs unlocked")
            assert.equals(false, waitingMode.mainBlocked, "waiting prompt should not block the main window")
            assert.equals(false, waitingMode.showRecentDeathRows, "waiting prompt should hide expanded death rows")
            assert.equals(false, waitingMode.showWaitingHelp, "waiting help should wait for the configured delay")

            Deathpool.waitingPromptDisplayDuration = context.DeathpoolConstants.DEMO.waitingForFirstDeathHelpTextDelaySeconds
            local waitingHelpMode = DeathpoolUIMode.Resolve(Deathpool, buildModeDisplayState(), env.DeathpoolCharacterState)
            assert.equals(false, waitingHelpMode.showRecentDeathRows, "waiting help should keep expanded death rows hidden")
            assert.equals(true, waitingHelpMode.showWaitingHelp, "waiting help should show after the configured delay")
        end)

        it("locks inputs and shows rows for a locked prediction", function()
            local context = createUIContext(Fixtures.uiDatabase({
                hasSeenFirstRun = true,
            }))
            local Deathpool = context.Deathpool
            local DeathpoolUIMode = context.ns.DeathpoolUIMode

            local lockedMode = DeathpoolUIMode.Resolve(
                Deathpool,
                buildModeDisplayState({
                    deaths = {
                        Fixtures.storedDeath(),
                    },
                    lockedPrediction = Fixtures.prediction(),
                }),
                env.DeathpoolCharacterState
            )
            assert.equals("normal", lockedMode.mode, "locked prediction should stay in normal mode")
            assert.equals(nil, lockedMode.modal, "locked prediction should not report a modal")
            assert.equals(nil, lockedMode.prompt, "locked prediction should suppress prompts")
            assert.equals(true, lockedMode.inputsLocked, "locked prediction should lock inputs")
            assert.equals(false, lockedMode.mainBlocked, "locked prediction should not block the main window")
            assert.equals(true, lockedMode.showRecentDeathRows, "normal locked mode should show death rows")
            assert.equals(false, lockedMode.showWaitingHelp, "locked prediction should hide waiting help")
        end)

        it("handles the help modal", function()
            local context = createUIContext(Fixtures.uiDatabase({
                hasSeenFirstRun = false,
            }))
            local Deathpool = context.Deathpool
            local DeathpoolUIMode = context.ns.DeathpoolUIMode

            Deathpool.helpFrame:Show()

            local mode = DeathpoolUIMode.Resolve(Deathpool, buildModeDisplayState(), env.DeathpoolCharacterState)

            assert.equals("normal", mode.mode, "help should preserve the underlying normal mode")
            assert.equals("help", mode.modal, "help should report the help modal")
            assert.equals(true, DeathpoolUIMode.IsNormalMode(mode), "help should report normal mode through predicate")
            assert.equals(true, DeathpoolUIMode.HasModal(mode), "help should report modal state through predicate")
            assert.equals(true, DeathpoolUIMode.IsHelpModal(mode), "help should report help modal through predicate")
            assert.equals(false, DeathpoolUIMode.IsSetupModal(mode), "help should not report setup modal through predicate")
            assert.equals(nil, mode.prompt, "help modal should suppress normal prompts")
            assert.equals(true, mode.inputsLocked, "help modal should lock prediction inputs")
            assert.equals(true, mode.mainBlocked, "help modal should block the main window")
            assert.equals(true, mode.showRecentDeathRows, "help modal should keep expanded death row data visible-ready")
            assert.equals(false, mode.showWaitingHelp, "help modal should hide waiting help")

            Deathpool.helpFrame.downloadLink:GetScript("OnClick")()

            local githubMode = DeathpoolUIMode.Resolve(Deathpool, buildModeDisplayState(), env.DeathpoolCharacterState)

            assert.equals(false, Deathpool.helpFrame:IsShown(), "GitHub link dialog should replace help while it is open")
            assert.equals("normal", githubMode.mode, "GitHub link dialog should preserve the underlying normal mode")
            assert.equals("help", githubMode.modal, "GitHub link dialog should reuse the help modal state")
            assert.equals(
                true,
                DeathpoolUIMode.IsHelpModal(githubMode),
                "GitHub link dialog should report through the help modal predicate"
            )
            assert.equals(true, githubMode.inputsLocked, "GitHub link dialog should lock prediction inputs")
            assert.equals(true, githubMode.mainBlocked, "GitHub link dialog should block the main window")
        end)
    end)

    describe("initialization and restoration", function()
        describe("initialized frame structure", function()
            local context
            local Deathpool
            local DeathpoolDebug
            local DeathpoolLog
            local layout

            before_each(function()
                context = createUIContext()
                Deathpool = context.Deathpool
                DeathpoolDebug = context.DeathpoolDebug
                DeathpoolLog = context.DeathpoolLog
                layout = context.DeathpoolUI.LAYOUT
            end)

            it("returns and sizes top-level frames", function()
                assert.is_truthy(Deathpool, "Initialize should return the main frame")
                assert.is_truthy(DeathpoolDebug, "Initialize should return the debug frame")
                assert.is_truthy(DeathpoolLog, "Initialize should return the history log frame")
                assert.equals(layout.expandedWindowWidth, Deathpool:GetWidth(), "main frame should use the compact expanded width")
                assert.equals(layout.mainWindowHeight, Deathpool:GetHeight(), "main frame should use the reduced expanded height")
                assert.equals(layout.logWindowWidth, DeathpoolLog:GetWidth(), "history log should use the compact log width")
                assert.equals(layout.logWindowHeight, DeathpoolLog:GetHeight(), "history log should use the reduced expanded height")
                assert.equals(Deathpool.frameStrata, DeathpoolLog.frameStrata, "history log should share the main frame strata")
                assert.equals(Deathpool:GetFrameLevel(), DeathpoolLog:GetFrameLevel(), "history log should share the main frame level")
                assert.equals(false, DeathpoolLog.toplevel, "history log should not use special top-level z ordering")
                assert.equals(false, DeathpoolLog:IsShown(), "history log should start hidden by default")
            end)

            it("configures history-window dragging and visibility", function()
                assert.is_truthy(DeathpoolLog.dragHandle, "history log should create a titlebar drag handle")
                assert.equals(
                    layout.titlebarDragLeftInset,
                    select(4, DeathpoolLog.dragHandle:GetPoint(1)),
                    "history log titlebar should use the shared left drag inset"
                )
                assert.equals(
                    -layout.titlebarDragRightInset,
                    select(4, DeathpoolLog.dragHandle:GetPoint(2)),
                    "history log titlebar should use the shared right drag inset"
                )
                assert.equals(
                    layout.titlebarDragHeight,
                    DeathpoolLog.dragHandle:GetHeight(),
                    "history log titlebar should use the shared drag height"
                )
                assert.is_truthy(#Deathpool.deathRows > 0, "main frame should create recent death rows")
                assert.is_truthy(#DeathpoolLog.rows > 0, "log frame should create history rows")
                assert.equals(layout.deathLogRowHeight, DeathpoolLog.logRowHeight, "history log should use compact record spacing")
                assert.equals(layout.deathLogRowHeight, DeathpoolLog.rows[1]:GetHeight(), "history log rows should use compact record spacing")
                assert.is_truthy(DeathpoolLog.filterButton, "log frame should create a history filter button")
                assert.equals("SHOW ALL", DeathpoolLog.filterButton:GetText(), "history filter button should default to the all-history action")
                assert.equals(
                    layout.compactButtonHeight,
                    DeathpoolLog.filterButton:GetHeight(),
                    "history filter should use the compact button height"
                )
                assert.equals(
                    -(layout.outsideGutter + layout.scrollbarInset),
                    select(4, DeathpoolLog.scrollFrame:GetPoint(2)),
                    "history scrollbar should clear the window inlay"
                )
                assert.equals(
                    layout.deathLogHeaderY - layout.deathLogFrameY,
                    layout.logVerticalSpacing,
                    "history log should share the main log vertical spacing"
                )
                assert.equals(
                    layout.historySubtitleY,
                    select(5, DeathpoolLog.logSubtitle:GetPoint(1)),
                    "history subtitle should use the shared subtitle position"
                )
                assert.equals(
                    layout.historyLogHeaderY,
                    select(5, DeathpoolLog.columnHeaders.time:GetPoint(1)),
                    "history column headers should leave room beneath the subtitle"
                )
                assert.equals(
                    layout.historySubtitleHeaderSpacing,
                    select(5, DeathpoolLog.logSubtitle:GetPoint(1)) - select(5, DeathpoolLog.columnHeaders.time:GetPoint(1)),
                    "history subtitle-to-header spacing should include extra breathing room"
                )
                assert.equals(
                    layout.logVerticalSpacing,
                    select(5, DeathpoolLog.columnHeaders.time:GetPoint(1)) - select(5, DeathpoolLog.rows[1]:GetPoint(1)),
                    "history header-to-row spacing should match the main log spacing"
                )
            end)

            it("lays out history rows, headers, and scrollbar", function()
                assert.equals("RIGHT", DeathpoolLog.columnHeaders.awardedPoints.justifyH, "history log should right justify the points header")
                assert.equals("RIGHT", DeathpoolLog.rows[1].awardedPoints.justifyH, "history log should right justify points cells")
                assert.equals(
                    select(4, DeathpoolLog.rows[1]:GetPoint(1)) + select(4, DeathpoolLog.rows[1].awardedPoints:GetPoint(1)),
                    select(4, DeathpoolLog.columnHeaders.awardedPoints:GetPoint(1)),
                    "history log points header should align with the points column"
                )
                assert.equals(
                    layout.logWindowWidth - layout.outsideGutter - layout.historyScrollbarGap - layout.scrollbarInset - 1,
                    select(4, DeathpoolLog.columnHeaders.awardedPoints:GetPoint(1))
                        + DeathpoolLog.columnHeaders.awardedPoints:GetWidth(),
                    "history log points header should leave reduced room for the scrollbar"
                )
                assert.equals(
                    layout.logWindowWidth - layout.outsideGutter - layout.historyScrollbarGap - layout.scrollbarInset - 1,
                    select(4, DeathpoolLog.rows[1]:GetPoint(1))
                        + select(4, DeathpoolLog.rows[1].awardedPoints:GetPoint(1))
                        + DeathpoolLog.rows[1].awardedPoints:GetWidth(),
                    "history log points cells should leave reduced room for the scrollbar"
                )
            end)

            it("exposes main-window child controllers and actions", function()
                assert.is_truthy(Deathpool.helpFrame, "main frame should keep a reference to the help frame")
                assert.is_truthy(Deathpool.githubLinkFrame, "main frame should keep a reference to the GitHub link dialog")
                assert.is_truthy(Deathpool.helpButton, "main frame should keep a reference to the help button")
                assert.is_truthy(Deathpool.helpFrame.backdropOverlay, "help window should create a main-window backdrop overlay")
                assert.is_truthy(Deathpool.helpFrame.titlebarDragHandle, "help window should create a titlebar drag handle")
                assert.is_truthy(Deathpool.githubLinkFrame.backdropOverlay, "GitHub link dialog should create a main-window backdrop overlay")
                assert.is_truthy(Deathpool.githubLinkFrame.titlebarDragHandle, "GitHub link dialog should create a titlebar drag handle")
                assert.equals(
                    layout.titlebarDragLeftInset,
                    select(4, Deathpool.helpFrame.titlebarDragHandle:GetPoint(1)),
                    "help titlebar should use the shared left drag inset"
                )
                assert.equals(
                    layout.titlebarDragHeight,
                    Deathpool.helpFrame.titlebarDragHandle:GetHeight(),
                    "help titlebar should use the shared drag height"
                )
                assert.is_truthy(Deathpool.introDemoController, "main frame should keep a reference to the intro demo controller")
                assert.is_truthy(Deathpool.lockButton, "main frame should keep a reference to the lock button")
                assert.is_truthy(Deathpool.pauseButton, "main frame should keep a reference to the pause button")
                assert.is_truthy(Deathpool.bottomLogButton, "main frame should keep a reference to the bottom log button")
                assert.is_truthy(Deathpool.gameInfoCallout, "main frame should keep a reference to the game info callout")
                assert.equals(false, Deathpool.gameInfoCallout:IsShown(), "game info callout should start hidden")
            end)

            it("creates recent-death rows and cells", function()
                assert.is_truthy(Deathpool.recentDeathsFrame, "main frame should create the reusable recent deaths frame")
                assert.equals(DeathpoolLog.logRowHeight, Deathpool.recentDeathsFrame.logRowHeight, "main log should use the history log record spacing")
                assert.equals(DeathpoolLog.rows[1]:GetHeight(), Deathpool.deathRows[1]:GetHeight(), "main log rows should match history log row height")
                assert.equals(layout.outsideGutter, select(4, Deathpool.recentDeathsFrame:GetPoint(1)), "main log should use the outside gutter")
                assert.equals(layout.deathLogFrameY, select(5, Deathpool.recentDeathsFrame:GetPoint(1)), "main log should sit close beneath the column headers")
                assert.equals(
                    5 * layout.deathLogRowHeight,
                    Deathpool.recentDeathsFrame:GetHeight(),
                    "main log frame should fit exactly five compact rows"
                )
                assert.is_truthy(Deathpool.deathRows[1].time, "main frame should create the recent death time cell")
                assert.is_truthy(Deathpool.deathRows[1].sourceName, "main frame should create the recent death source cell")
                assert.is_truthy(Deathpool.deathRows[1].level, "main frame should create the recent death level cell")
                assert.is_truthy(Deathpool.deathRows[1].zone, "main frame should create the recent death location cell")
                assert.is_truthy(Deathpool.deathRows[1].awardedPoints, "main frame should create the total points cell in recent death rows")
                assert.equals("RIGHT", Deathpool.deathRows[1].awardedPoints.justifyH, "main frame should right justify recent death points")
            end)

            it("configures recent-death column dimensions and alignment", function()
                assert.equals(0, select(4, Deathpool.deathRows[1].time:GetPoint(1)), "main frame should keep recent death time at the content edge")
                assert.equals(58, select(4, Deathpool.deathRows[1].sourceName:GetPoint(1)), "main frame should compact the recent death source column")
                assert.equals(278, select(4, Deathpool.deathRows[1].level:GetPoint(1)), "main frame should compact the recent death level column")
                assert.equals(328, select(4, Deathpool.deathRows[1].zone:GetPoint(1)), "main frame should compact the recent death location column")
                assert.equals(530, select(4, Deathpool.deathRows[1].awardedPoints:GetPoint(1)), "main frame should compact the recent death points column")
                assert.equals(290, Deathpool.deathRows[1].sourceName:GetWidth(), "main frame should preserve the recent death source width")
                assert.equals(40, Deathpool.deathRows[1].level:GetWidth(), "main frame should preserve the recent death level width")
                assert.equals(400, Deathpool.deathRows[1].zone:GetWidth(), "main frame should preserve the recent death location width")
                assert.equals(46, Deathpool.deathRows[1].awardedPoints:GetWidth(), "main frame should preserve the recent death points width")
                assert.equals(
                    layout.expandedWindowWidth - (layout.outsideGutter * 2),
                    select(4, Deathpool.deathRows[1].awardedPoints:GetPoint(1)) + Deathpool.deathRows[1].awardedPoints:GetWidth(),
                    "main frame should keep recent death points inside the compact right gutter"
                )
            end)

            it("preserves recent-death column order and omits unused cells", function()
                assert.is_truthy(
                    select(4, Deathpool.deathRows[1].time:GetPoint(1))
                        < select(4, Deathpool.deathRows[1].sourceName:GetPoint(1)),
                    "main frame should place source after time"
                )
                assert.is_truthy(
                    select(4, Deathpool.deathRows[1].sourceName:GetPoint(1))
                        < select(4, Deathpool.deathRows[1].level:GetPoint(1)),
                    "main frame should place level after source"
                )
                assert.is_truthy(
                    select(4, Deathpool.deathRows[1].level:GetPoint(1))
                        < select(4, Deathpool.deathRows[1].zone:GetPoint(1)),
                    "main frame should place location after level"
                )
                assert.is_truthy(
                    select(4, Deathpool.deathRows[1].zone:GetPoint(1))
                        < select(4, Deathpool.deathRows[1].awardedPoints:GetPoint(1)),
                    "main frame should place points after location"
                )
                assert.equals(nil, Deathpool.deathRows[1].pointsTooltipTarget, "main frame should omit the base points hover target from recent death rows")
                assert.equals(nil, Deathpool.deathRows[1].multiplier, "main frame should omit the combo cell from recent death rows")
                assert.equals(nil, Deathpool.deathRows[1].streakMultiplier, "main frame should omit the streak cell from recent death rows")
            end)

            it("builds the collapsed log and resize controls", function()
                assert.is_truthy(Deathpool.collapsedLogFrame, "main frame should create the collapsed death log frame")
                assert.is_truthy(#Deathpool.collapsedLogFrame.rows > 0, "main frame should create collapsed death log rows")
                assert.equals(DeathpoolLog.logRowHeight, Deathpool.collapsedLogFrame.logRowHeight, "mini log should use the history log record spacing")
                assert.equals(DeathpoolLog.rows[1]:GetHeight(), Deathpool.collapsedLogFrame.rows[1]:GetHeight(), "mini log rows should match history log row height")
                assert.is_truthy(Deathpool.collapsedLogFrame.rows[1].time, "main frame should create collapsed death time cells")
                assert.is_truthy(Deathpool.collapsedLogFrame.rows[1].awardedPoints, "main frame should create collapsed death points cells")
                assert.equals(45, Deathpool.collapsedLogFrame.rows[1].time:GetWidth(), "mini log should give the time column enough width for scaled fonts")
                assert.equals("RIGHT", Deathpool.collapsedLogFrame.rows[1].awardedPoints.justifyH, "main frame should right justify collapsed death points")
                assert.is_truthy(#(Deathpool.collapsedLogHeaders or {}) > 0, "main frame should create collapsed death log headers")
                assert.equals("Time", Deathpool.collapsedLogHeaders[1]:GetText(), "mini log should show the time column header")
                assert.equals(45, Deathpool.collapsedLogHeaders[1]:GetWidth(), "mini log should give the time header enough width for scaled fonts")
                assert.equals(
                    layout.collapsedLogHeaderY,
                    select(5, Deathpool.collapsedLogHeaders[1]:GetPoint(1)),
                    "mini log headers should use the shared collapsed header position"
                )
                assert.equals(
                    layout.collapsedLogFrameY,
                    select(5, Deathpool.collapsedLogFrame:GetPoint(1)),
                    "mini log rows should use the shared collapsed row position"
                )
                assert.equals(
                    layout.deathLogHeaderY - layout.deathLogFrameY,
                    select(5, Deathpool.collapsedLogHeaders[1]:GetPoint(1)) - select(5, Deathpool.collapsedLogFrame:GetPoint(1)),
                    "mini log header-to-row spacing should match the main log"
                )
                assert.is_truthy(Deathpool.collapsedScoreDivider, "main frame should create the collapsed score divider")
                assert.equals(
                    layout.footerGutter,
                    select(5, Deathpool.collapsedPointsValue:GetPoint(1)),
                    "collapsed score should use the footer gutter"
                )
                assert.is_truthy(Deathpool.collapsedResizeHandle, "main frame should create the collapsed resize handle")
                assert.equals(
                    "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up",
                    Deathpool.collapsedResizeHandle:GetNormalTexture(),
                    "main frame should use Blizzard chat resize art for the collapsed resize handle"
                )
            end)

            it("configures titlebar and log controls", function()
                assert.equals(nil, Deathpool.minimizeButton.template, "main frame should use a plain button for Classic-compatible collapse art")
                assert.equals(nil, Deathpool.minimizeButton:GetText(), "main frame collapse button should rely on Blizzard textures instead of text")
                assert.equals("LOG", Deathpool.bottomLogButton:GetText(), "bottom log button should use the log label")
                assert.equals(false, Deathpool.bottomLogButton:IsEnabled(), "bottom log button should start disabled before the first locked prediction")
            end)

            it("lays out level controls", function()
                assert.equals(64, Deathpool.levelRangeButtons[1]:GetWidth(), "level range buttons should preserve their width")
                assert.equals(layout.compactButtonHeight, Deathpool.levelRangeButtons[1]:GetHeight(), "level range buttons should preserve their height")
                assert.equals(layout.predictionControlX, select(4, Deathpool.levelRangeButtons[1]:GetPoint(1)), "level range buttons should start closer to their label")
                assert.equals(
                    select(5, Deathpool.levelRangeButtons[1]:GetPoint(1)),
                    select(5, Deathpool.levelRangeLabel:GetPoint(1)),
                    "level range label should align with the level button row"
                )
                assert.equals(layout.compactButtonHeight, Deathpool.levelRangeLabel:GetHeight(), "level range label should match the button row height")
                assert.equals("MIDDLE", Deathpool.levelRangeLabel.justifyV, "level range label should be vertically centered")
                assert.equals(
                    68,
                    select(4, Deathpool.levelRangeButtons[2]:GetPoint(1)) - select(4, Deathpool.levelRangeButtons[1]:GetPoint(1)),
                    "level range buttons should use compact horizontal spacing"
                )
            end)

            it("lays out source and location inputs", function()
                assert.equals(180, Deathpool.sourceEditBox:GetWidth(), "source edit box should preserve its width")
                assert.equals(layout.compactButtonHeight, Deathpool.sourceEditBox:GetHeight(), "source edit box should preserve its height")
                assert.equals(
                    7,
                    select(4, Deathpool.sourceEditBox:GetPoint(1)) - select(4, Deathpool.levelRangeButtons[1]:GetPoint(1)),
                    "source edit box should account for its template border when aligning with buttons"
                )
                assert.equals(
                    7,
                    select(4, Deathpool.zoneEditBox:GetPoint(1)) - select(4, Deathpool.levelRangeButtons[1]:GetPoint(1)),
                    "location edit box should account for its template border when aligning with buttons"
                )
                assert.equals(
                    select(5, Deathpool.sourceEditBox:GetPoint(1)),
                    select(5, Deathpool.sourceLabel:GetPoint(1)),
                    "source label should align with the source edit box row"
                )
                assert.equals(
                    select(5, Deathpool.zoneEditBox:GetPoint(1)),
                    select(5, Deathpool.zoneLabel:GetPoint(1)),
                    "location label should align with the location edit box row"
                )
                assert.equals(layout.compactButtonHeight, Deathpool.sourceLabel:GetHeight(), "source label should match the edit box row height")
                assert.equals(layout.compactButtonHeight, Deathpool.zoneLabel:GetHeight(), "location label should match the edit box row height")
                assert.equals("MIDDLE", Deathpool.sourceLabel.justifyV, "source label should be vertically centered")
                assert.equals("MIDDLE", Deathpool.zoneLabel.justifyV, "location label should be vertically centered")
            end)

            it("lays out footer actions and score summary", function()
                assert.equals(layout.standardButtonWidth, Deathpool.helpButton:GetWidth(), "help button should preserve its width")
                assert.equals(layout.standardButtonHeight, Deathpool.helpButton:GetHeight(), "help button should preserve its height")
                assert.equals(100, Deathpool.bottomLogButton:GetWidth(), "log button should preserve its width")
                assert.equals(layout.standardButtonHeight, Deathpool.bottomLogButton:GetHeight(), "log button should preserve its height")
                assert.equals(layout.standardButtonWidth, Deathpool.pauseButton:GetWidth(), "pause button should preserve its width")
                assert.equals(layout.standardButtonWidth, Deathpool.lockButton:GetWidth(), "lock button should preserve its width")
                assert.equals("BOTTOMLEFT", select(1, Deathpool.helpButton:GetPoint(1)), "bottom buttons should be anchored from the left edge")
                assert.equals(layout.predictionControlX, select(4, Deathpool.helpButton:GetPoint(1)), "bottom buttons should start farther left")
                assert.equals(layout.footerGutter, select(5, Deathpool.helpButton:GetPoint(1)), "bottom buttons should use the footer gutter")
                assert.equals(Deathpool.helpButton, select(2, Deathpool.bottomLogButton:GetPoint(1)), "log button should chain to help")
                assert.equals(layout.actionButtonGap, select(4, Deathpool.bottomLogButton:GetPoint(1)), "log button should preserve the button gap")
                assert.equals(Deathpool.bottomLogButton, select(2, Deathpool.pauseButton:GetPoint(1)), "pause button should chain to log")
                assert.equals(layout.actionButtonGap, select(4, Deathpool.pauseButton:GetPoint(1)), "pause button should preserve the button gap")
                assert.equals(Deathpool.pauseButton, select(2, Deathpool.lockButton:GetPoint(1)), "lock button should chain to pause")
                assert.equals(layout.actionButtonGap, select(4, Deathpool.lockButton:GetPoint(1)), "lock button should preserve the button gap")
                assert.equals(
                    604,
                    select(4, Deathpool.helpButton:GetPoint(1))
                        + Deathpool.helpButton:GetWidth()
                        + layout.actionButtonGap
                        + Deathpool.bottomLogButton:GetWidth()
                        + layout.actionButtonGap
                        + Deathpool.pauseButton:GetWidth()
                        + layout.actionButtonGap
                        + Deathpool.lockButton:GetWidth(),
                    "bottom buttons should fit within the compact expanded width"
                )
                assert.equals(layout.footerGutter, select(5, DeathpoolLog.filterButton:GetPoint(1)), "history filter should use the footer gutter")
                assert.is_truthy(Deathpool.sourceEditBox, "main frame should create the source edit box")
                assert.is_truthy(Deathpool.zoneEditBox, "main frame should create the zone edit box")
            end)

            it("configures debug detail fields", function()
                assert.is_truthy(DeathpoolDebug.detailLabels, "debug frame should keep references to detail labels")
                assert.equals("EditBox", DeathpoolDebug.detailValues.sourceMessage.kind, "debug frame should use an edit box for the raw message")
                assert.equals(
                    DeathpoolDebug:GetWidth() - (layout.outsideGutter * 2),
                    DeathpoolDebug.detailValues.sourceMessage:GetWidth(),
                    "debug raw message should keep a gutter on both sides"
                )
                assert.equals(36, DeathpoolDebug.detailValues.sourceMessage:GetHeight(), "debug raw message should be tall enough for two lines")
                assert.equals(true, DeathpoolDebug.detailValues.sourceMessage.multiLine, "debug raw message should wrap across multiple lines")
                assert.equals(false, DeathpoolDebug.detailValues.sourceMessage.autoFocus, "debug raw message should not steal focus on create")
                assert.equals(
                    select(5, DeathpoolDebug.detailLabels.pointFormula:GetPoint(1)),
                    select(5, DeathpoolDebug.detailLabels.comboDetails:GetPoint(1)),
                    "debug winning combo should move to the formula row"
                )
                assert.is_truthy(
                    select(4, DeathpoolDebug.detailLabels.comboDetails:GetPoint(1))
                        > select(4, DeathpoolDebug.detailLabels.pointFormula:GetPoint(1)),
                    "debug winning combo should sit to the right of the formula row"
                )
                assert.equals(
                    select(4, DeathpoolDebug.detailValues.sourceMessage:GetPoint(1)),
                    select(4, DeathpoolDebug.detailLabels.sourceMessage:GetPoint(1)),
                    "debug raw message label should align with the frame gutter"
                )
                assert.equals(
                    select(5, DeathpoolDebug.detailValues.sourceMessage:GetPoint(1)) + 15,
                    select(5, DeathpoolDebug.detailLabels.sourceMessage:GetPoint(1)),
                    "debug raw message label should sit above the edit box"
                )
            end)

            it("creates intro and waiting controls with their defaults", function()
                assert.is_truthy(Deathpool.introDemoAttractPanel, "main frame should create the intro demo marquee panel")
                assert.is_truthy(Deathpool.emptyPredictionPrompt, "main frame should create the empty-prediction prompt")
                assert.is_truthy(Deathpool.waitingPromptText, "main frame should create the waiting prompt base text")
                assert.is_truthy(Deathpool.waitingPromptDots, "main frame should create the waiting prompt dots")
                assert.is_truthy(Deathpool.waitingPromptHelpText, "main frame should create the waiting prompt help text")
                assert.equals(false, Deathpool.emptyPredictionPrompt:IsShown(), "empty-prediction prompt should start hidden")
            end)

            it("creates setup controls and their overlay", function()
                assert.is_truthy(Deathpool.setupFrame, "main frame should create the standalone setup window")
                assert.is_truthy(Deathpool.setupFrame.enableDeathAnnouncementsButton, "setup window should create the death announcement enable button")
                assert.is_truthy(Deathpool.setupFrame.enableDeathAnnouncementsText, "setup window should create the death announcement enable text")
                assert.is_truthy(Deathpool.setupFrame.joinHardcoreDeathsButton, "setup window should create the hardcore deaths channel join button")
                assert.is_truthy(Deathpool.setupFrame.joinHardcoreDeathsText, "setup window should create the hardcore deaths channel join text")
                assert.is_truthy(Deathpool.setupFrame.backdropOverlay, "setup window should create a main-window backdrop overlay")
                assert.is_truthy(Deathpool.setupFrame.titlebarDragHandle, "setup window should create a titlebar drag handle")
                assert.equals(false, Deathpool.setupFrame:IsShown(), "setup window should start hidden")
                assert.equals(false, Deathpool.setupFrame.backdropOverlay:IsShown(), "setup backdrop should start hidden")
                assert.equals(true, Deathpool.setupFrame.backdropOverlay.allPoints, "setup backdrop should cover the main window")
                assert.equals(true, Deathpool.setupFrame.backdropOverlay.mouseEnabled, "setup backdrop should block main window clicks")
                assert.equals("LeftButton", Deathpool.setupFrame.backdropOverlay.dragButton, "setup backdrop should preserve main-window dragging")
                assert.is_truthy(Deathpool.setupFrame.backdropOverlay:GetScript("OnDragStart"), "setup backdrop should start main-window dragging")
                assert.is_truthy(Deathpool.setupFrame.backdropOverlay:GetScript("OnDragStop"), "setup backdrop should stop main-window dragging")
                assert.equals("LeftButton", Deathpool.setupFrame.titlebarDragHandle.dragButton, "setup titlebar should preserve main-window dragging")
                assert.is_truthy(Deathpool.setupFrame.titlebarDragHandle:GetScript("OnDragStart"), "setup titlebar should start main-window dragging")
                assert.is_truthy(Deathpool.setupFrame.titlebarDragHandle:GetScript("OnDragStop"), "setup titlebar should stop main-window dragging")
                assert.equals(
                    true,
                    Deathpool.setupFrame.backdropOverlay:GetFrameLevel() > Deathpool:GetFrameLevel(),
                    "setup backdrop should sit above main window contents"
                )
                assert.equals(0.58, Deathpool.setupFrame.backdropOverlay.texture.colorTexture[4], "setup backdrop should obscure the main window")
            end)

            it("configures the help modal overlay", function()
                assert.equals(369, Deathpool.helpFrame:GetHeight(), "help window should use the shorter modal height")
                assert.equals(Deathpool, select(2, Deathpool.helpFrame:GetPoint(1)), "help window should be centered on the main window")
                assert.equals(0, select(4, Deathpool.helpFrame:GetPoint(1)), "help window should not offset horizontally from the main window")
                assert.equals(0, select(5, Deathpool.helpFrame:GetPoint(1)), "help window should not offset vertically from the main window")
                assert.equals(false, Deathpool.helpFrame.movable, "help window should not be movable")
                assert.equals(nil, Deathpool.helpFrame.dragButton, "help window should not register itself for dragging")
                assert.equals(false, Deathpool.helpFrame.backdropOverlay:IsShown(), "help backdrop should start hidden")
                assert.equals(true, Deathpool.helpFrame.backdropOverlay.allPoints, "help backdrop should cover the main window")
                assert.equals(true, Deathpool.helpFrame.backdropOverlay.mouseEnabled, "help backdrop should block main window clicks")
                assert.equals("LeftButton", Deathpool.helpFrame.backdropOverlay.dragButton, "help backdrop should preserve main-window dragging")
                assert.is_truthy(Deathpool.helpFrame.backdropOverlay:GetScript("OnDragStart"), "help backdrop should start main-window dragging")
                assert.is_truthy(Deathpool.helpFrame.backdropOverlay:GetScript("OnDragStop"), "help backdrop should stop main-window dragging")
                assert.equals("LeftButton", Deathpool.helpFrame.titlebarDragHandle.dragButton, "help titlebar should preserve main-window dragging")
                assert.is_truthy(Deathpool.helpFrame.titlebarDragHandle:GetScript("OnDragStart"), "help titlebar should start main-window dragging")
                assert.is_truthy(Deathpool.helpFrame.titlebarDragHandle:GetScript("OnDragStop"), "help titlebar should stop main-window dragging")
                assert.equals(
                    true,
                    Deathpool.helpFrame.backdropOverlay:GetFrameLevel() > Deathpool:GetFrameLevel(),
                    "help backdrop should sit above main window contents"
                )
                assert.equals(0.58, Deathpool.helpFrame.backdropOverlay.texture.colorTexture[4], "help backdrop should obscure the main window")
            end)

            it("configures the GitHub link modal overlay", function()
                assert.equals(430, Deathpool.githubLinkFrame:GetWidth(), "GitHub link dialog should use the setup-style modal width")
                assert.equals(112, Deathpool.githubLinkFrame:GetHeight(), "GitHub link dialog should be compact")
                assert.equals("GitHub Link", Deathpool.githubLinkFrame.title:GetText(), "GitHub link dialog should use the requested title")
                assert.equals(
                    Deathpool,
                    select(2, Deathpool.githubLinkFrame:GetPoint(1)),
                    "GitHub link dialog should be centered on the main window"
                )
                assert.equals(0, select(4, Deathpool.githubLinkFrame:GetPoint(1)), "GitHub link dialog should not offset horizontally")
                assert.equals(0, select(5, Deathpool.githubLinkFrame:GetPoint(1)), "GitHub link dialog should not offset vertically")
                assert.equals(false, Deathpool.githubLinkFrame.movable, "GitHub link dialog should not be movable")
                assert.equals(nil, Deathpool.githubLinkFrame.dragButton, "GitHub link dialog should not register itself for dragging")
                assert.equals(false, Deathpool.githubLinkFrame.backdropOverlay:IsShown(), "GitHub link backdrop should start hidden")
                assert.equals(true, Deathpool.githubLinkFrame.backdropOverlay.allPoints, "GitHub link backdrop should cover the main window")
                assert.equals(true, Deathpool.githubLinkFrame.backdropOverlay.mouseEnabled, "GitHub link backdrop should block main window clicks")
                assert.equals(
                    "LeftButton",
                    Deathpool.githubLinkFrame.backdropOverlay.dragButton,
                    "GitHub link backdrop should preserve main-window dragging"
                )
                assert.is_truthy(
                    Deathpool.githubLinkFrame.backdropOverlay:GetScript("OnDragStart"),
                    "GitHub link backdrop should start main-window dragging"
                )
                assert.is_truthy(
                    Deathpool.githubLinkFrame.backdropOverlay:GetScript("OnDragStop"),
                    "GitHub link backdrop should stop main-window dragging"
                )
                assert.equals(
                    "LeftButton",
                    Deathpool.githubLinkFrame.titlebarDragHandle.dragButton,
                    "GitHub link titlebar should preserve main-window dragging"
                )
                assert.is_truthy(
                    Deathpool.githubLinkFrame.titlebarDragHandle:GetScript("OnDragStart"),
                    "GitHub link titlebar should start main-window dragging"
                )
                assert.is_truthy(
                    Deathpool.githubLinkFrame.titlebarDragHandle:GetScript("OnDragStop"),
                    "GitHub link titlebar should stop main-window dragging"
                )
                assert.equals(
                    true,
                    Deathpool.githubLinkFrame.backdropOverlay:GetFrameLevel() > Deathpool:GetFrameLevel(),
                    "GitHub link backdrop should sit above main window contents"
                )
                assert.equals(
                    0.58,
                    Deathpool.githubLinkFrame.backdropOverlay.texture.colorTexture[4],
                    "GitHub link backdrop should obscure the main window"
                )
            end)

            it("configures the setup window", function()
                assert.equals("SETUP", Deathpool.setupFrame.title:GetText(), "setup window should use the setup title")
                assert.equals("Let's make sure you're set up!", Deathpool.setupFrame.subtitle:GetText(), "setup window should introduce setup")
                assert.equals("GameFontNormal", Deathpool.setupFrame.subtitle.template, "setup subtitle should match row text size")
                assert.equals(Deathpool, select(2, Deathpool.setupFrame:GetPoint(1)), "setup window should be centered on the main window")
                assert.equals(0, select(4, Deathpool.setupFrame:GetPoint(1)), "setup window should not offset horizontally from the main window")
                assert.equals(0, select(5, Deathpool.setupFrame:GetPoint(1)), "setup window should not offset vertically from the main window")
                assert.equals(false, Deathpool.setupFrame.movable, "setup window should not be movable")
                assert.equals(nil, Deathpool.setupFrame.dragButton, "setup window should not register for dragging")
            end)

            it("configures setup actions and removes obsolete controls", function()
                assert.equals(nil, Deathpool.configPromptFrame, "main frame should not create an inline setup prompt")
                assert.equals(nil, Deathpool.configPromptTitle, "main frame should not create an inline setup title")
                assert.equals(nil, Deathpool.deathAnnouncementsCheckbox, "config walkthrough should not create a death announcement checkbox")
                assert.equals(nil, Deathpool.hardcoreDeathsChannelCheckbox, "config walkthrough should not create a channel checkbox")
                assert.equals("GameMenuButtonTemplate", Deathpool.setupFrame.enableDeathAnnouncementsButton.template, "death announcement action should use a real button template")
                assert.equals("ENABLE", Deathpool.setupFrame.enableDeathAnnouncementsButton:GetText(), "death announcement button should use the enable label")
                assert.equals("Hardcore death announcements", Deathpool.setupFrame.enableDeathAnnouncementsText:GetText(), "death announcement text should explain the action")
                assert.equals("GameMenuButtonTemplate", Deathpool.setupFrame.joinHardcoreDeathsButton.template, "channel action should use a real button template")
                assert.equals("JOIN", Deathpool.setupFrame.joinHardcoreDeathsButton:GetText(), "channel button should use the join label")
                assert.equals("The HardcoreDeaths channel", Deathpool.setupFrame.joinHardcoreDeathsText:GetText(), "channel text should explain the action")
            end)

            it("lays out intro, waiting, and score prompts", function()
                assert.equals(
                    "Make your prediction",
                    Deathpool.emptyPredictionPrompt:GetText(),
                    "empty-prediction prompt should guide the player to choose a prediction"
                )
                assert.equals(false, Deathpool.introDemoAttractPanel:IsShown(), "intro demo marquee should start hidden outside demo mode")
                assert.equals(284, select(4, Deathpool.introDemoAttractPanel:GetPoint(1)), "intro demo marquee should fit the compact expanded width")
                assert.equals(314, Deathpool.introDemoAttractPanel:GetWidth(), "intro demo marquee should preserve its width")
                assert.equals(
                    "Welcome to the death pool\nPress START GAME to begin",
                    Deathpool.introDemoAttractPanel.text:GetText(),
                    "intro demo marquee should use the arcade attract text"
                )
                assert.equals("CENTER", select(1, Deathpool.waitingPromptText:GetPoint(1)), "waiting prompt text should anchor from the center")
                assert.equals("CENTER", select(3, Deathpool.waitingPromptText:GetPoint(1)), "waiting prompt text should stay centered in the pane")
                assert.equals("LEFT", select(1, Deathpool.waitingPromptDots:GetPoint(1)), "waiting prompt dots should anchor from the left")
                assert.equals("RIGHT", select(3, Deathpool.waitingPromptDots:GetPoint(1)), "waiting prompt dots should attach to the text's right edge")
                assert.equals("TOP", select(1, Deathpool.waitingPromptHelpText:GetPoint(1)), "waiting prompt help text should anchor from the top")
                assert.equals("BOTTOM", select(3, Deathpool.waitingPromptHelpText:GetPoint(1)), "waiting prompt help text should attach below the waiting text")
                assert.equals(
                    layout.deathLogDividerY - (layout.outsideGutter - layout.footerGutter),
                    layout.scoreSummaryY,
                    "expanded score summary should use the tighter footer spacing from the mini log"
                )
                assert.equals(
                    layout.scoreSummaryY,
                    select(5, Deathpool.totalPointsValue:GetPoint(1)),
                    "expanded score summary should sit close beneath the death log divider"
                )
                assert.is_truthy(Deathpool.currentStreakValue, "main frame should create the current streak value")
                assert.is_truthy(Deathpool.dropdown, "main frame should create the shared suggestion dropdown")
            end)

            it("registers clipping and escape-close behavior", function()
                assert.equals(true, Deathpool.collapsedLogFrame.clipsChildren, "collapsed death log should clip child rows during resize")
                assert.equals(true, Deathpool.collapsedLogFrame.rows[1].clipsChildren, "collapsed death log rows should clip cell text to the row bounds")
                assert.equals("DeathpoolFrame", env.UISpecialFrames[1], "main frame should register with the WoW escape-close list")
            end)
        end)

        it("uses an independent environment for each context", function()
            local firstContext = createUIContext()
            rawset(firstContext.env.Settings, "transientValue", "first context")

            local secondContext = createUIContext()

            assert.equals(false, firstContext.env == secondContext.env, "each UI context should receive its own environment")
            assert.equals(
                nil,
                rawget(secondContext.env.Settings, "transientValue"),
                "a later UI context should receive pristine mutable WoW globals"
            )
            assert.equals(
                false,
                firstContext.Deathpool == secondContext.Deathpool,
                "a later UI context should receive newly loaded addon modules"
            )
        end)

        it("restores the saved history filter", function()
            local context = createUIContext(Fixtures.uiDatabase({
                historySuccessfulOnly = false,
            }))
            local DeathpoolLog = context.DeathpoolLog

            assert.equals(false, DeathpoolLog.showSuccessfulOnly, "history log should restore the saved all-history mode")
            assert.equals("All Predictions", DeathpoolLog.logSubtitle:GetText(), "history log should restore the saved subtitle")
            assert.equals("SHOW SUCCESS ONLY", DeathpoolLog.filterButton:GetText(), "history log should restore the saved filter action")
            assert.equals("Time", DeathpoolLog.columnHeaders.time:GetText(), "history log should restore the time column label for all-history mode")
            assert.equals("Source", DeathpoolLog.columnHeaders.sourceName:GetText(), "history log should use the source column label for all-history mode")
            assert.equals(nil, DeathpoolLog.columnHeaders.level, "history log should omit the level column for all-history mode")
        end)
    end)

    describe("window and modal behavior", function()
        it("closes the main window on escape", function()
            local context = createUIContext({})
            local DeathpoolUI = context.DeathpoolUI
            local Deathpool = context.Deathpool
            local pressEscape = context.pressEscape
            Deathpool:Show()

            assert.is_truthy(pressEscape(), "escape should report that it closed a special frame")
            assert.equals(false, Deathpool:IsShown(), "escape should close the main window")

            Deathpool:Show()
            Deathpool.introDemoController:Show()
            assert.is_truthy(pressEscape(), "escape should still close the main window when the demo is visible")
            assert.equals(false, Deathpool:IsShown(), "escape should close the main window when the demo is visible")

            Deathpool:Show()
            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)
            assert.equals(nil, env.UISpecialFrames[1], "collapsed main window should be removed from the WoW escape-close list")
            assert.equals(false, pressEscape(), "escape should not close the collapsed main window")
            assert.is_truthy(Deathpool:IsShown(), "collapsed main window should remain visible after escape")
        end)

        it("renders help text", function()
            local context = createUIContext()
            local DeathpoolUI = context.DeathpoolUI
            local Deathpool = context.Deathpool
            local findRegionText = context.findRegionText
            local layout = DeathpoolUI.LAYOUT

            local helpText = findRegionText(Deathpool.helpFrame, "Hardcore Death Pool is a")
            assert.is_truthy(helpText, "help frame should contain the main help text")
            assert.equals(
                -(layout.outsideGutter + layout.scrollbarInset),
                select(4, Deathpool.helpFrame.scrollFrame:GetPoint(2)),
                "help scrollbar should clear the window inlay"
            )
            assert.equals(
                Deathpool.helpFrame:GetWidth()
                    - (layout.outsideGutter * 2)
                    - layout.scrollbarWidth
                    - layout.scrollbarInset,
                Deathpool.helpFrame.helpText:GetWidth(),
                "help text should leave room for the scrollbar"
            )
            assert.equals(
                Deathpool.helpFrame.helpText:GetWidth(),
                Deathpool.helpFrame.scrollContent:GetWidth(),
                "help scroll content should match the scrollbar-aware text width"
            )
            assert.equals(false, Deathpool.githubLinkFrame:IsShown(), "GitHub link dialog should start hidden")
            assert.equals(
                "InputBoxTemplate",
                Deathpool.githubLinkFrame.urlBox.template,
                "GitHub link dialog should use the WoW input box template"
            )
            assert.equals(
                context.DeathpoolUIHelp.GetDownloadUrl(),
                Deathpool.githubLinkFrame.urlBox:GetText(),
                "GitHub link field should contain the releases URL"
            )
            assert.equals("OK", Deathpool.githubLinkFrame.okButton:GetText(), "GitHub link dialog should have an OK button")
            Deathpool.helpFrame:Show()
            Deathpool.helpFrame.downloadLink:GetScript("OnClick")()
            assert.equals(false, Deathpool.helpFrame:IsShown(), "clicking the download link should replace the help window")
            assert.is_truthy(Deathpool.githubLinkFrame:IsShown(), "clicking the download link should open the GitHub link dialog")
            assert.is_truthy(
                Deathpool.githubLinkFrame.backdropOverlay:IsShown(),
                "GitHub link dialog should show the main-window backdrop"
            )
            assert.is_truthy(Deathpool.githubLinkFrame.urlBox.hasFocus, "clicking the download link should focus the URL field")
            assert.is_truthy(Deathpool.githubLinkFrame.urlBox.highlightRange, "clicking the download link should select the URL text")

            Deathpool.githubLinkFrame.urlBox:SetText("temporary user edit")
            assert.equals("temporary user edit", Deathpool.githubLinkFrame.urlBox:GetText(), "GitHub link field should allow user edits")
            Deathpool.githubLinkFrame.okButton:GetScript("OnClick")()
            assert.equals(false, Deathpool.githubLinkFrame:IsShown(), "OK should close the GitHub link dialog")
            assert.equals(false, Deathpool.githubLinkFrame.backdropOverlay:IsShown(), "OK should hide the GitHub link backdrop")
            assert.equals(false, Deathpool.helpFrame:IsShown(), "OK should leave the help window closed")

            Deathpool.helpFrame:Show()
            Deathpool.helpFrame.downloadLink:GetScript("OnClick")()
            assert.equals(
                context.DeathpoolUIHelp.GetDownloadUrl(),
                Deathpool.githubLinkFrame.urlBox:GetText(),
                "GitHub link field should reset to the canonical URL each open"
            )
            Deathpool.githubLinkFrame.CloseButton:GetScript("OnClick")()
            assert.equals(false, Deathpool.helpFrame:IsShown(), "titlebar close should leave the help window closed")
        end)

        it("handles help modal behavior", function()
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
            assert.equals(true, Deathpool.sourceEditBox:IsEnabled(), "test should start with editable prediction input")

            Deathpool.helpFrame:Show()

            assert.equals(true, Deathpool.helpFrame.backdropOverlay:IsShown(), "help backdrop should show when help is shown")
            assert.equals(true, DeathpoolLog:IsShown(), "help should allow the log window to remain open")
            assert.equals(true, env.DeathpoolCharacterState.logWindowShown, "help should not change the saved log preference")
            assert.equals(false, Deathpool.lockButton:IsEnabled(), "help modal should disable locking predictions")
            assert.equals(false, Deathpool.sourceEditBox:IsEnabled(), "help modal should disable source input")

            Deathpool.helpFrame:Hide()
            assert.equals(false, Deathpool.helpFrame.backdropOverlay:IsShown(), "help backdrop should hide when help is hidden")
            assert.equals(true, Deathpool.sourceEditBox:IsEnabled(), "closing help should restore source input")

            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)
            assert.equals(true, Deathpool.isCollapsed, "test should start help from the mini-log state")
            assert.equals(false, DeathpoolLog:IsShown(), "collapsing should hide the expanded log before help opens")

            Deathpool.helpFrame:Show()

            assert.equals(false, Deathpool.isCollapsed, "showing help from the mini-log should expand the main window")
            assert.equals(false, env.DeathpoolCharacterState.collapsed, "showing help should persist the expanded main window")
            assert.equals(true, Deathpool.helpFrame:IsShown(), "showing help from the mini-log should keep help visible")
            assert.equals(true, Deathpool.helpFrame.backdropOverlay:IsShown(), "expanded help should show the backdrop")
            assert.equals(true, DeathpoolLog:IsShown(), "expanding for help should restore the desired log window")
            assert.equals(true, env.DeathpoolCharacterState.logWindowShown, "expanding for help should keep the saved log preference")

            local lockedContext = createUIContext(Fixtures.uiDatabase({
                hasSeenFirstRun = true,
                lockedPrediction = Fixtures.prediction(),
            }))
            local LockedDeathpool = lockedContext.Deathpool

            LockedDeathpool:RefreshLockedPrediction()
            assert.equals(true, LockedDeathpool.pauseButton:IsEnabled(), "test should start with an enabled pause action")

            LockedDeathpool.helpFrame:Show()
            assert.equals(false, LockedDeathpool.pauseButton:IsEnabled(), "help modal should disable the pause action")

            LockedDeathpool.helpFrame:Hide()
            assert.equals(true, LockedDeathpool.pauseButton:IsEnabled(), "closing help should restore pause action state")
        end)

        it("collapses the main window", function()
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
            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)
            assert.equals(true, env.DeathpoolCharacterState.collapsed, "collapsed mode should persist state to SavedVariables")
            assert.equals("Interface\\Buttons\\UI-PlusButton-UP", Deathpool.minimizeButton:GetNormalTexture(), "collapsed mode should flip the titlebar button art")
            assert.equals("Interface\\Buttons\\UI-PlusButton-Hilight", Deathpool.minimizeButton:GetHighlightTexture(), "collapsed mode should use Blizzard highlight art")
            assert.is_truthy(Deathpool.collapsedLogHeaders[1]:IsShown(), "collapsed log headers should show in collapsed mode")
            assert.is_truthy(Deathpool.collapsedScoreDivider:IsShown(), "collapsed score divider should show in collapsed mode")
            assert.is_truthy(Deathpool.collapsedPointsValue:IsShown(), "collapsed score should show in collapsed mode")
            assert.equals(false, Deathpool.lockButton:IsShown(), "prediction controls should hide in collapsed mode")
            assert.equals(false, Deathpool.helpFrame:IsShown(), "collapsed mode should close the help window")
            assert.equals(false, DeathpoolLog:IsShown(), "collapsed mode should close the log window")
            assert.is_truthy(DeathpoolDebug:IsShown(), "collapsed mode should keep the debug window open")

            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, false)
            assert.equals(false, env.DeathpoolCharacterState.collapsed, "expanded mode should persist state to SavedVariables")
            assert.equals("Interface\\Buttons\\UI-MinusButton-UP", Deathpool.minimizeButton:GetNormalTexture(), "expanded mode should restore the titlebar button art")
            assert.equals("Interface\\Buttons\\UI-MinusButton-Hilight", Deathpool.minimizeButton:GetHighlightTexture(), "expanded mode should restore Blizzard highlight art")
            assert.is_truthy(Deathpool.lockButton:IsShown(), "prediction controls should return in expanded mode")
            assert.equals(false, Deathpool.collapsedLogFrame:IsShown(), "expanded mode should hide the collapsed death log frame")
            assert.equals(false, Deathpool.collapsedScoreDivider:IsShown(), "expanded mode should hide the collapsed score divider")
            assert.equals(false, Deathpool.introDemoAttractPanel:IsShown(), "expanded mode should keep the intro marquee hidden outside demo mode")
            assert.is_truthy(Deathpool.helpFrame:IsShown(), "expanded mode should reopen the help window if it was open before collapsing")
            assert.is_truthy(DeathpoolLog:IsShown(), "expanded mode should reopen the log window if it was open before collapsing")
            assert.equals("LOCKED IN", Deathpool.lockButton:GetText(), "restored help modal should keep prediction inputs locked")
            Deathpool.helpFrame:Hide()
            assert.equals("LOCK IN", Deathpool.lockButton:GetText(), "closing restored help should restore the normal lock button label")

            DeathpoolLog:Hide()
            Deathpool.helpFrame:Show()
            Deathpool.helpFrame.downloadLink:GetScript("OnClick")()
            assert.is_truthy(Deathpool.githubLinkFrame:IsShown(), "test should start with the GitHub link dialog open")
            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)
            assert.equals(false, Deathpool.githubLinkFrame:IsShown(), "collapsed mode should close the GitHub link dialog")
            assert.equals(
                false,
                Deathpool.helpFrame:IsShown(),
                "collapsed mode should leave help closed after closing the GitHub link dialog"
            )
            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, false)
            assert.equals(
                false,
                Deathpool.helpFrame:IsShown(),
                "expanded mode should not reopen help after collapsing from the GitHub link dialog"
            )

            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)
            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, false)
            assert.equals(
                false,
                Deathpool.helpFrame:IsShown(),
                "expanded mode should keep the help window closed if it was closed before collapsing"
            )
            assert.equals(
                false,
                DeathpoolLog:IsShown(),
                "expanded mode should keep the log window closed if it was closed before collapsing"
            )

            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)
            Deathpool:GetScript("OnMouseUp")(Deathpool, "LeftButton")
            assert.equals(false, Deathpool.isCollapsed, "clicking the collapsed main window should expand it")
            assert.equals(false, env.DeathpoolCharacterState.collapsed, "clicking the collapsed main window should persist the expanded state")
        end)

        it("expands the main window when a collapsed death row is clicked", function()
            local context = createUIContext(Fixtures.uiDatabase({
                recentDeaths = {
                    Fixtures.storedDeath(),
                },
            }))
            local DeathpoolUI = context.DeathpoolUI
            local Deathpool = context.Deathpool

            Deathpool:RefreshDeaths()
            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)
            Deathpool.collapsedLogFrame.rows[1]:GetScript("OnMouseUp")(Deathpool.collapsedLogFrame.rows[1], "LeftButton")

            assert.equals(false, Deathpool.isCollapsed, "clicking a collapsed death log row should expand the main window")
            assert.equals(false, env.DeathpoolCharacterState.collapsed, "clicking a collapsed death log row should persist the expanded state")
        end)

        it("handles the bottom log button", function()
            local context = createUIContext({
                hasSeenFirstRun = true,
            })
            local DeathpoolUI = context.DeathpoolUI
            local Deathpool = context.Deathpool
            local DeathpoolLog = context.DeathpoolLog
            local onClick = Deathpool.bottomLogButton:GetScript("OnClick")

            assert.equals("LOG", Deathpool.bottomLogButton:GetText(), "bottom log button should start with the log label")

            onClick()
            assert.is_truthy(DeathpoolLog:IsShown(), "bottom log button should show the log window while expanded")

            onClick()
            assert.equals(false, DeathpoolLog:IsShown(), "bottom log button should hide the log window while expanded")

            DeathpoolLog:Show()
            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)
            assert.equals(false, DeathpoolLog:IsShown(), "collapsed mode should still hide the log window initially")

            onClick()
            assert.is_truthy(DeathpoolLog:IsShown(), "bottom log button should show the log window while collapsed")
            assert.equals(
                true,
                Deathpool.collapsedWindowStates.logFrame,
                "bottom log button should remember the log window state while collapsed"
            )

            onClick()
            assert.equals(false, DeathpoolLog:IsShown(), "bottom log button should hide the log window while collapsed")
            assert.equals(
                false,
                Deathpool.collapsedWindowStates.logFrame,
                "bottom log button should clear the remembered log window state while collapsed"
            )
        end)

        it("uses the game-info callout for the minimize button", function()
            local context = createUIContext({})
            local Deathpool = context.Deathpool

            Deathpool:Show()
            Deathpool.minimizeButton:GetScript("OnEnter")(Deathpool.minimizeButton)
            waitForGameInfoCallout(Deathpool)

            assert.equals(true, Deathpool.gameInfoCallout:IsShown(), "hovering the minimize button should show the game info callout")
            assert.equals(
                "Show the mini log",
                Deathpool.gameInfoCallout.lines[1].left,
                "minimize button should use the mini-log game info callout text"
            )

            Deathpool.minimizeButton:GetScript("OnLeave")()
            assert.equals(false, Deathpool.gameInfoCallout:IsShown(), "leaving the minimize button should hide the game info callout")
        end)

        it("reopens the desired log window when the main window shows or expands", function()
            local context = createUIContext(Fixtures.uiDatabase({
                logWindowShown = true,
            }))
            local DeathpoolUI = context.DeathpoolUI
            local Deathpool = context.Deathpool
            local DeathpoolLog = context.DeathpoolLog

            Deathpool:Hide()
            DeathpoolUI.ApplyDesiredLogWindowState(Deathpool, env.DeathpoolCharacterState)
            assert.equals(false, DeathpoolLog:IsShown(), "desired log state should stay hidden while the main window is hidden")

            Deathpool:Show()
            DeathpoolUI.ApplyDesiredLogWindowState(Deathpool, env.DeathpoolCharacterState)
            assert.is_truthy(DeathpoolLog:IsShown(), "desired log state should open the log when the main window opens")

            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)
            assert.equals(false, DeathpoolLog:IsShown(), "collapsing should still hide the log window")

            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, false)
            assert.is_truthy(DeathpoolLog:IsShown(), "expanding should reopen the log when the desired state is open")

            DeathpoolUI.SetLogWindowShown(Deathpool, env.DeathpoolCharacterState, false)
            assert.equals(false, env.DeathpoolCharacterState.logWindowShown, "changing the log toggle should persist the desired closed state")

            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)
            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, false)
            assert.equals(false, DeathpoolLog:IsShown(), "expanding should keep the log hidden when the desired state is closed")
        end)

        it("uses resolved demo mode for auxiliary window refresh", function()
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

            assert.equals(false, Deathpool.bottomLogButton:IsEnabled(), "demo mode should disable the log button through auxiliary refresh")
            assert.equals(false, Deathpool.helpButton:IsEnabled(), "demo mode should disable the help button through auxiliary refresh")
            assert.equals(false, DeathpoolLog:IsShown(), "demo mode should close the log window through auxiliary refresh")
            assert.equals(false, Deathpool.helpFrame:IsShown(), "demo mode should close the help window through auxiliary refresh")
            assert.equals(false, Deathpool.githubLinkFrame:IsShown(), "demo mode should close the GitHub link dialog")
            assert.equals(false, Deathpool.collapsedWindowStates.logFrame, "demo mode should clear remembered log state")
            assert.equals(false, Deathpool.collapsedWindowStates.helpFrame, "demo mode should clear remembered help state")

            Deathpool.introDemoController:Dismiss()
            Deathpool:RefreshAuxiliaryWindowState()

            assert.equals(true, Deathpool.bottomLogButton:IsEnabled(), "normal mode should re-enable the log button after demo")
            assert.equals(true, Deathpool.helpButton:IsEnabled(), "normal mode should re-enable the help button after demo")
            assert.equals(true, DeathpoolLog:IsShown(), "normal mode should restore the desired log window state")
        end)

        it("closes the GitHub link dialog with the main window", function()
            local context = createUIContext(Fixtures.uiDatabase({
                hasSeenFirstRun = true,
            }))
            local Deathpool = context.Deathpool

            Deathpool:Show()
            Deathpool.helpFrame:Show()
            Deathpool.helpFrame.downloadLink:GetScript("OnClick")()

            assert.is_truthy(Deathpool.githubLinkFrame:IsShown(), "test should start with the GitHub link dialog open")

            Deathpool:Hide()

            assert.equals(false, Deathpool.githubLinkFrame:IsShown(), "hiding the main window should close the GitHub link dialog")
            assert.equals(false, Deathpool.helpFrame:IsShown(), "hiding the main window should leave help closed")
        end)

        it("follows setup-window visibility for the setup tint", function()
            local context = createUIContext({})
            local Deathpool = context.Deathpool

            Deathpool.setupFrame:Show()
            assert.equals(
                true,
                Deathpool.setupFrame.backdropOverlay:IsShown(),
                "setup backdrop should show when the setup window is shown directly"
            )

            Deathpool.setupFrame:Hide()
            assert.equals(
                false,
                Deathpool.setupFrame.backdropOverlay:IsShown(),
                "setup backdrop should hide when the setup window is hidden directly"
            )
            assert.equals(false, Deathpool.setupActive, "hiding setup should restore main window interaction state")
        end)
    end)

    describe("positioning and layout", function()
        it("remembers the collapsed window position", function()
            local context = createUIContext({})
            local DeathpoolUI = context.DeathpoolUI
            local Deathpool = context.Deathpool

            Deathpool:ClearAllPoints()
            Deathpool:SetPoint("CENTER", env.UIParent, "CENTER", 120, -60)
            DeathpoolUI.SaveWindowPosition(Deathpool, env.DeathpoolCharacterState, false)

            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)
            assert.is_not_nil(Deathpool.points[1], "collapsing without a saved minimized anchor should keep a window anchor")

            Deathpool:ClearAllPoints()
            Deathpool:SetPoint("CENTER", env.UIParent, "CENTER", -240, 90)
            Deathpool:GetScript("OnDragStop")(Deathpool)
            assert.is_not_nil(env.DeathpoolCharacterState.collapsedWindowPosition, "dragging while minimized should save the minimized position")

            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, false)
            assert.is_not_nil(Deathpool.points[1], "expanding should restore an expanded window anchor")

            Deathpool:ClearAllPoints()
            Deathpool:SetPoint("CENTER", env.UIParent, "CENTER", 360, -180)
            Deathpool:GetScript("OnDragStop")(Deathpool)
            assert.is_not_nil(env.DeathpoolCharacterState.windowPosition, "dragging while expanded should update the expanded position")

            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)
            assert.is_not_nil(Deathpool.points[1], "collapsing again should restore a minimized window anchor")
        end)

        it("moves the main window from the log titlebar", function()
            local context = createUIContext({})
            local DeathpoolUI = context.DeathpoolUI
            local Deathpool = context.Deathpool
            local DeathpoolLog = context.DeathpoolLog

            DeathpoolLog.dragHandle:GetScript("OnDragStart")()
            assert.is_truthy(Deathpool.startedMoving, "dragging the log titlebar should start moving the main window")

            Deathpool:ClearAllPoints()
            Deathpool:SetPoint("CENTER", env.UIParent, "CENTER", 210, -110)
            DeathpoolLog.dragHandle:GetScript("OnDragStop")()
            assert.is_truthy(Deathpool.stoppedMoving, "releasing the log titlebar should stop moving the main window")
            assert.is_not_nil(env.DeathpoolCharacterState.windowPosition, "dragging from the log titlebar should save the main window position")

            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)
            Deathpool:ClearAllPoints()
            Deathpool:SetPoint("CENTER", env.UIParent, "CENTER", -150, 55)
            DeathpoolLog.dragHandle:GetScript("OnDragStop")()
            assert.is_not_nil(env.DeathpoolCharacterState.collapsedWindowPosition, "dragging from the log titlebar while minimized should save the minimized position")
        end)

        it("moves the main window from the setup titlebar", function()
            local context = createUIContext({})
            local DeathpoolUI = context.DeathpoolUI
            local Deathpool = context.Deathpool
            local setupTitlebar = Deathpool.setupFrame.titlebarDragHandle

            setupTitlebar:GetScript("OnDragStart")()
            assert.is_truthy(Deathpool.startedMoving, "dragging the setup titlebar should start moving the main window")

            Deathpool:ClearAllPoints()
            Deathpool:SetPoint("CENTER", env.UIParent, "CENTER", 180, -95)
            setupTitlebar:GetScript("OnDragStop")()
            assert.is_truthy(Deathpool.stoppedMoving, "releasing the setup titlebar should stop moving the main window")
            assert.is_not_nil(env.DeathpoolCharacterState.windowPosition, "dragging from the setup titlebar should save the main window position")

            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)
            Deathpool:ClearAllPoints()
            Deathpool:SetPoint("CENTER", env.UIParent, "CENTER", -120, 40)
            setupTitlebar:GetScript("OnDragStop")()
            assert.is_not_nil(
                env.DeathpoolCharacterState.collapsedWindowPosition,
                "dragging from the setup titlebar while minimized should save the minimized position"
            )
        end)

        it("moves the main window from the help modal", function()
            local context = createUIContext({})
            local DeathpoolUI = context.DeathpoolUI
            local Deathpool = context.Deathpool
            local helpTitlebar = Deathpool.helpFrame.titlebarDragHandle
            local helpBackdrop = Deathpool.helpFrame.backdropOverlay

            helpTitlebar:GetScript("OnDragStart")()
            assert.is_truthy(Deathpool.startedMoving, "dragging the help titlebar should start moving the main window")

            Deathpool:ClearAllPoints()
            Deathpool:SetPoint("CENTER", env.UIParent, "CENTER", 160, -80)
            helpTitlebar:GetScript("OnDragStop")()
            assert.is_truthy(Deathpool.stoppedMoving, "releasing the help titlebar should stop moving the main window")
            assert.is_not_nil(env.DeathpoolCharacterState.windowPosition, "dragging from the help titlebar should save the main window position")

            Deathpool.startedMoving = false
            Deathpool.stoppedMoving = false
            helpBackdrop:GetScript("OnDragStart")()
            assert.is_truthy(Deathpool.startedMoving, "dragging the help backdrop should start moving the main window")

            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)
            Deathpool:ClearAllPoints()
            Deathpool:SetPoint("CENTER", env.UIParent, "CENTER", -90, 35)
            helpBackdrop:GetScript("OnDragStop")()
            assert.is_truthy(Deathpool.stoppedMoving, "releasing the help backdrop should stop moving the main window")
            assert.is_not_nil(
                env.DeathpoolCharacterState.collapsedWindowPosition,
                "dragging from the help backdrop while minimized should save the minimized position"
            )
        end)

        it("resizes and restores the collapsed window height", function()
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

            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)
            assert.equals(350, Deathpool:GetWidth(), "collapsed mode should keep the fixed collapsed width before resizing")
            assert.equals(165, Deathpool:GetHeight(), "collapsed mode should start with the default collapsed height")
            assert.equals(true, Deathpool.collapsedResizeHandle:IsShown(), "collapsed mode should show the resize handle")
            assert.is_truthy(Deathpool.collapsedLogFrame.rows[5]:IsShown(), "default collapsed height should show five visible rows")
            assert.equals("Source One", Deathpool.collapsedLogFrame.rows[1].sourceName:GetText(), "default collapsed height should keep the oldest visible row at the top")
            assert.equals("Source Five", Deathpool.collapsedLogFrame.rows[5].sourceName:GetText(), "default collapsed height should keep the newest visible row at the bottom")

            Deathpool:SetSize(410, 98)

            assert.equals(350, Deathpool:GetWidth(), "collapsed resize should keep the width fixed")
            assert.equals(100, Deathpool:GetHeight(), "collapsed resize should allow shrinking to the one-row height")
            assert.equals(100, env.DeathpoolCharacterState.collapsedWindowHeight, "collapsed resize should persist the new height")
            assert.is_truthy(Deathpool.collapsedLogFrame.rows[1]:IsShown(), "collapsed resize should keep the newest row visible")
            assert.equals("Source Five", Deathpool.collapsedLogFrame.rows[1].sourceName:GetText(), "collapsed resize should keep the newest death in the visible row")
            assert.equals(false, Deathpool.collapsedLogFrame.rows[2]:IsShown(), "collapsed resize should hide rows beyond the one-row limit")

            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, false)
            assert.equals(false, Deathpool.collapsedResizeHandle:IsShown(), "expanded mode should hide the resize handle")

            DeathpoolUI.SetWindowCollapsed(Deathpool, env.DeathpoolCharacterState, true)
            assert.equals(100, Deathpool:GetHeight(), "re-collapsing should restore the persisted collapsed height")
            assert.equals(false, Deathpool.collapsedLogFrame.rows[2]:IsShown(), "restored one-row height should still limit the collapsed list")
        end)
    end)
end)

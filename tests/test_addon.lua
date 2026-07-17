package.path = table.concat({
    "./src/?.lua",
    "./?.lua",
    "./?/init.lua",
    package.path,
}, ";")

local TestHelpers = require("tests.support_helpers")
local Fixtures = require("tests.support_fixtures")
local UIHarness = require("tests.support_ui_harness")
require("DeathpoolMigration")
local DeathpoolDatabase = require("DeathpoolDatabase")
local DeathpoolConstants = require("DeathpoolConstants")
local LogicHelpers = require("tests.support_logic_helpers")
local suite = TestHelpers.CreateSuite()
local DATABASE_DEFAULTS = DeathpoolDatabase.DEFAULTS or {}
local DEMO_RULES = DeathpoolConstants.DEMO or {}
local assertEquals = function(actual, expected, message)
    suite:assertEquals(actual, expected, message)
end
local assertTruthy = function(value, message)
    suite:assertTruthy(value, message)
end
local assertContains = function(text, needle, message)
    suite:assertContains(text, needle, message)
end

local function getDefault(key)
    return DATABASE_DEFAULTS[key]
end

local function getIntroDemoState(frame)
    local introDemoController = frame and frame.introDemoController or nil
    if introDemoController then
        return introDemoController.demoState
    end

    return nil
end

local function refreshUiFrames(context)
    context.Deathpool = context.getMainFrame()
    context.DeathpoolDebug = context.getDebugFrame()
    context.DeathpoolLog = context.getLogFrame()
    context.runSlash = function(message)
        return context.controller:HandleSlashCommand(message)
    end
    return context
end

local function createLoadedAddonContext(options)
    options = options or {}

    local context = UIHarness.CreateAddon({
        state = options.state,
        hardcoreDeathChatType = options.hardcoreDeathChatType,
        hardcoreDeathsJoined = options.hardcoreDeathsJoined,
        inGuild = options.inGuild,
    })
    local controller = context.controller
    local dispatchEvent = context.dispatchEvent

    if options.load ~= false then
        dispatchEvent(controller, "ADDON_LOADED", "Deathpool")
        refreshUiFrames(context)
    end

    if options.login == true then
        dispatchEvent(controller, "PLAYER_LOGIN")
        refreshUiFrames(context)
    end

    return context
end

local function testAddonDefersUiCreationUntilAddonLoaded()
    local context = UIHarness.CreateAddon()

    assertTruthy(context.controller ~= nil, "addon bootstrap should create the controller frame immediately")
    assertEquals(context.getMainFrame(), nil, "main ui frame should not exist before ADDON_LOADED")
    assertEquals(context.getDebugFrame(), nil, "debug frame should not exist before ADDON_LOADED")
    assertEquals(context.getLogFrame(), nil, "log frame should not exist before ADDON_LOADED")
end

local function testMainWindowVisibilityPersistsThroughStartup()
    local context = createLoadedAddonContext()
    local Deathpool = context.Deathpool
    local DeathpoolDebug = context.DeathpoolDebug
    local dispatchEvent = context.dispatchEvent
    local controller = context.controller

    assertTruthy(DeathpoolCharacterState ~= nil, "addon load should initialize SavedVariables")
    assertEquals(DeathpoolCharacterState.hidden, getDefault("hidden"), "addon load should honor the configured hidden default")
    assertEquals(DeathpoolCharacterState.debugEnabled, nil, "addon load should not persist debug mode to SavedVariables")
    assertEquals(_G.DeathpoolDebugState.IsEnabled(), false, "addon load should start with debug mode disabled for the session")
    assertEquals(DeathpoolCharacterState.logWindowShown, getDefault("logWindowShown"), "addon load should honor the configured log window default")
    assertEquals(DeathpoolDebug:IsShown(), false, "addon load should keep the debug window hidden by default")

    assertEquals(dispatchEvent(controller, "PLAYER_LOGIN"), true, "dispatcher should fire registered login events")
    refreshUiFrames(context)
    assertEquals(Deathpool:IsShown(), DeathpoolCharacterState.hidden ~= true, "player login should apply the configured hidden default")
    assertEquals(context.DeathpoolLog:IsShown(), false, "player login should keep the log window hidden during the intro demo")
    assertEquals(
        getIntroDemoState(Deathpool) ~= nil,
        Deathpool:IsShown() and DeathpoolCharacterState.hasSeenIntroDemo ~= true,
        "player login should only start intro demo mode when the main window opens and the intro is still unseen"
    )
    assertEquals(
        Deathpool.lockButton:GetText(),
        Deathpool:IsShown() and DeathpoolCharacterState.hasSeenIntroDemo ~= true and "START GAME" or "LOCK IN",
        "player login should only relabel the lock button when the intro is still unseen"
    )
    assertEquals(
        Deathpool.lockButton:IsEnabled(),
        Deathpool:IsShown() and DeathpoolCharacterState.hasSeenIntroDemo ~= true,
        "player login should only enable the lock button as a dismiss action when the intro is still unseen"
    )
    assertEquals(DeathpoolDebug:IsShown(), false, "player login should keep the debug window hidden while debug mode is off")

    Deathpool:Show()
    assertEquals(DeathpoolCharacterState.hidden, false, "showing the main window should persist it as visible")

    Deathpool:Hide()
    assertEquals(DeathpoolCharacterState.hidden, true, "hiding the main window should persist it as hidden")

    assertEquals(dispatchEvent(controller, "PLAYER_LOGIN"), true, "dispatcher should keep firing registered events after state changes")
    refreshUiFrames(context)
    assertEquals(Deathpool:IsShown(), false, "player login should respect a previously hidden main window")
end

local function testIncompleteSetupReopensUntilComplete()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = true,
            collapsed = true,
            hasSeenIntroDemo = true,
        }),
        hardcoreDeathChatType = "0",
        hardcoreDeathsJoined = false,
    })
    local Deathpool = context.Deathpool

    assertEquals(Deathpool:IsShown(), false, "incomplete setup should not force open a saved-hidden main window")
    assertEquals(Deathpool.setupFrame:IsShown(), false, "incomplete setup should not show before the main window opens")

    context.runSlash("show")
    assertTruthy(Deathpool:IsShown(), "show command should open the main window")
    assertEquals(Deathpool.isCollapsed, false, "first-open setup should expand the main window before showing setup")
    assertTruthy(Deathpool.setupFrame:IsShown(), "first main-window open should show incomplete setup")
    assertEquals(DeathpoolCharacterState.hidden, false, "opening the main window should persist it as visible")
    assertEquals(DeathpoolCharacterState.collapsed, false, "first-open setup should persist the expanded main window")

    Deathpool.setupFrame:Hide()
    Deathpool:Hide()
    context.runSlash("show")
    assertTruthy(Deathpool:IsShown(), "show command should reopen the main window")
    assertTruthy(Deathpool.setupFrame:IsShown(), "incomplete setup should show again when the main window reopens")
end

local function testStartGameOpensSetupBeforeNormalGameplay()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = true,
            collapsed = false,
            hasSeenIntroDemo = false,
        }),
        hardcoreDeathChatType = "0",
        hardcoreDeathsJoined = false,
    })
    local Deathpool = context.Deathpool

    context.runSlash("show")
    assertEquals(Deathpool.setupFrame:IsShown(), false, "first main-window open should keep setup hidden during intro demo")
    assertEquals(getIntroDemoState(Deathpool) ~= nil, true, "first main-window open should start intro demo before setup")
    assertEquals(Deathpool.lockButton:GetText(), "START GAME", "intro demo should relabel the lock button")

    Deathpool.lockButton:GetScript("OnClick")()
    assertEquals(DeathpoolCharacterState.hasSeenIntroDemo, true, "starting the game should persist intro demo completion")
    assertEquals(getIntroDemoState(Deathpool), nil, "starting the game should end intro demo mode")
    assertTruthy(Deathpool.setupFrame:IsShown(), "starting the game should show incomplete setup")

    Deathpool.setupFrame.enableDeathAnnouncementsButton:Click()
    assertTruthy(Deathpool.setupFrame:IsShown(), "partially complete setup should stay visible")
    assertEquals(getIntroDemoState(Deathpool), nil, "partially complete setup should not restart the intro demo")

    Deathpool.setupFrame.joinHardcoreDeathsButton:Click()
    assertEquals(Deathpool.setupFrame:IsShown(), false, "completed setup should hide the setup window")
    assertEquals(getIntroDemoState(Deathpool), nil, "completed setup should reveal normal gameplay without restarting the demo")
    assertEquals(Deathpool.lockButton:GetText(), "LOCK IN", "completed setup should leave the normal lock action visible")
end

local function testHidingIntroDemoResumesBeforeIncompleteSetup()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = true,
            collapsed = false,
            hasSeenIntroDemo = false,
        }),
        hardcoreDeathChatType = "0",
        hardcoreDeathsJoined = false,
    })
    local Deathpool = context.Deathpool

    context.runSlash("show")
    assertEquals(Deathpool.setupFrame:IsShown(), false, "intro demo should keep setup hidden before hiding")
    assertEquals(getIntroDemoState(Deathpool) ~= nil, true, "first main-window open should start intro demo before hiding")
    local demoState = getIntroDemoState(Deathpool)

    Deathpool:Hide()
    assertEquals(Deathpool:IsShown(), false, "hiding the main window should hide the main frame")
    assertEquals(Deathpool.setupFrame:IsShown(), false, "hiding the main window should not open setup")
    assertEquals(Deathpool.setupFrame.backdropOverlay:IsShown(), false, "hiding the main window should keep the setup backdrop hidden")
    assertEquals(getIntroDemoState(Deathpool), demoState, "hiding the main window should suspend the active intro demo")
    assertEquals(DeathpoolCharacterState.hasSeenIntroDemo, false, "hiding during intro demo should not mark it as seen")

    context.runSlash("show")
    assertEquals(Deathpool.setupFrame:IsShown(), false, "incomplete setup should remain hidden while the resumed demo is active")
    assertEquals(getIntroDemoState(Deathpool), demoState, "reopening the main window should resume the same intro demo")
    assertEquals(Deathpool.introDemoAttractPanel:IsShown(), true, "reopening the main window should restore the demo callout")
end

local function testAddonLoadRebindsUiToSavedVariablesTable()
    local savedDatabase = Fixtures.addonDatabase({
        hasSeenIntroDemo = true,
        lockedPrediction = Fixtures.prediction({
            levelRange = "10-19",
        }),
        recentDeaths = {
            Fixtures.storedDeath({
                timestamp = 100,
                name = "Saveddeath",
                sourceName = "Savedsource",
            }),
        },
        deathHistory = {
            Fixtures.storedDeath({
                timestamp = 100,
                name = "Saveddeath",
                sourceName = "Savedsource",
                awardedPoints = 7,
                points = 7,
                predictionStreak = 1,
            }),
        },
        successfullyPredictedDeaths = {
            Fixtures.storedDeath({
                timestamp = 100,
                name = "Saveddeath",
                sourceName = "Savedsource",
                awardedPoints = 7,
                points = 7,
                predictionStreak = 1,
            }),
        },
    })

    local context = UIHarness.CreateAddon()
    local controller = context.controller

    DeathpoolCharacterState = savedDatabase
    context.dispatchEvent(controller, "ADDON_LOADED", "Deathpool")
    refreshUiFrames(context)

    local Deathpool = context.Deathpool

    assertEquals(Deathpool.state, savedDatabase, "addon load should rebind the UI to the loaded SavedVariables table")
    assertEquals(Deathpool.deathRows[1].name, nil, "addon load should not create the removed main-window name column")
    assertEquals(Deathpool.deathRows[1].sourceName:GetText(), "Savedsource", "addon load should populate recent deaths from the loaded SavedVariables table")
    assertEquals(context.DeathpoolLog.rows[1].sourceName:GetText(), "Savedsource", "addon load should populate successful history rows with death sources from the loaded SavedVariables table")
end

local function testReloadDoesNotPersistVisibleMainWindowAsHidden()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
        }),
        login = true,
    })
    local Deathpool = context.Deathpool
    local dispatchEvent = context.dispatchEvent
    local controller = context.controller

    assertTruthy(Deathpool:IsShown(), "startup should show the main window before the reload simulation")
    assertEquals(dispatchEvent(controller, "PLAYER_LOGOUT"), true, "logout should dispatch before the reload simulation")

    Deathpool:Hide()
    assertEquals(
        DeathpoolCharacterState.hidden,
        false,
        "shutdown-time hides should not persist the main window as hidden during reload"
    )

    local reloadedContext = createLoadedAddonContext({
        state = DeathpoolCharacterState,
        login = true,
    })

    assertTruthy(
        reloadedContext.Deathpool:IsShown(),
        "reload should restore the main window when it was visible before shutdown"
    )
end

local function testDebugLogOnlyPrintsWhileDebugModeIsEnabled()
    local context = createLoadedAddonContext()
    local chatMessages = context.chatMessages
    local debugApi = _G.DeathpoolDebug

    assertEquals(#chatMessages, 0, "addon load should not print chat announcements")

    debugApi.Log("hidden debug message")
    assertEquals(#chatMessages, 0, "debug log should stay silent while debug mode is disabled")

    assertTruthy(type(SlashCmdList.DEATHPOOL) == "function", "slash command should register the global handler")
    SlashCmdList.DEATHPOOL("debug")
    local messageCountAfterEnable = #chatMessages

    debugApi.Log("visible debug message")
    assertContains(chatMessages[#chatMessages], "visible debug message", "debug log should print once debug mode is enabled")
    assertEquals(#chatMessages, messageCountAfterEnable + 1, "debug log should add one message while enabled")
end

local function testDebugToggleControlsWindowAndPrinting()
    local context = createLoadedAddonContext()
    local DeathpoolDebug = context.DeathpoolDebug
    local chatMessages = context.chatMessages

    SlashCmdList.DEATHPOOL("debug")
    assertEquals(_G.DeathpoolDebugState.IsEnabled(), true, "debug command should enable shared debug mode")
    assertEquals(DeathpoolCharacterState.debugEnabled, nil, "debug command should not write debug mode to SavedVariables")
    assertEquals(DeathpoolDebug:IsShown(), true, "debug command should show the debug window while enabled")
    assertTruthy(string.find(chatMessages[#chatMessages], "enabled", 1, true), "debug command should print enable message")


    SlashCmdList.DEATHPOOL("debug")
    assertEquals(_G.DeathpoolDebugState.IsEnabled(), false, "debug command should disable shared debug mode")
    assertEquals(DeathpoolCharacterState.debugEnabled, nil, "debug command should keep SavedVariables free of debug mode state")
    assertEquals(DeathpoolDebug:IsShown(), false, "debug command should hide the debug window while disabled")
    --assertEquals(chatMessages[#chatMessages], "|cffcc3333Deathpool|r: Debug mode disabled.", "debug command should announce disablement")
    assertTruthy(string.find(chatMessages[#chatMessages], "disabled", 1, true), "debug command should announce disablement")

--     local messageCountBeforeDisabledDebugDeath = #chatMessages
--     SlashCmdList.DEATHPOOL("debugdeath [Alamo] has been slain by a Defias Bandit in Westfall! They were level 12")
--     assertEquals(
--         #chatMessages,
--         messageCountBeforeDisabledDebugDeath,
--         "debugdeath should not print parsed death details while debug mode is disabled"
--     )
end

local function testReloadClearsLegacySavedDebugFlagAndSessionDebugMode()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            debugEnabled = true,
            hasSeenIntroDemo = true,
        }),
        login = true,
    })

    assertEquals(DeathpoolCharacterState.debugEnabled, nil, "addon load should clear the legacy saved debug flag")
    assertEquals(_G.DeathpoolDebugState.IsEnabled(), false, "legacy saved debug mode should not re-enable debug for the session")

    context.runSlash("debug")
    assertEquals(_G.DeathpoolDebugState.IsEnabled(), true, "debug command should still enable runtime debug mode")

    local reloadedContext = createLoadedAddonContext({
        state = DeathpoolCharacterState,
        login = true,
    })

    assertEquals(reloadedContext.getDebugFrame():IsShown(), false, "reload should bring the debug window back hidden")
    assertEquals(_G.DeathpoolDebugState.IsEnabled(), false, "reload should reset debug mode for the new session")
    assertEquals(DeathpoolCharacterState.debugEnabled, nil, "reload should keep SavedVariables free of the debug flag")
end

local function testFirstShowStartsAndDismissesIntroDemo()
    local context = createLoadedAddonContext()
    local Deathpool = context.Deathpool

    assertEquals(DeathpoolCharacterState.hasSeenIntroDemo, getDefault("hasSeenIntroDemo"), "addon load should honor the configured intro demo default")
    assertEquals(getIntroDemoState(Deathpool), nil, "addon load should not enter intro demo mode before the main window opens")

    Deathpool:Show()
    assertEquals(getIntroDemoState(Deathpool) ~= nil, true, "first show should activate the intro demo")
    assertEquals(Deathpool.lockButton:GetText(), "START GAME", "first show should relabel the lock button to start game")
    assertEquals(Deathpool.totalPointsValue:GetText(), "0", "first show should begin the scripted demo at zero score")

    Deathpool.lockButton:GetScript("OnClick")()
    assertEquals(DeathpoolCharacterState.hasSeenIntroDemo, true, "dismissing the intro demo should persist completion")
    assertEquals(getIntroDemoState(Deathpool), nil, "dismissing the intro demo should restore live data")
    assertEquals(Deathpool.setupFrame:IsShown(), false, "starting the game should skip setup when it is already complete")
    assertEquals(Deathpool.lockButton:GetText(), "LOCK IN", "dismissing the intro demo should restore the lock button label")
    assertEquals(context.DeathpoolLog:IsShown(), false, "dismissing the intro demo should keep the default hidden log window closed")
    assertEquals(Deathpool.totalPointsValue:GetText(), "0", "dismissing the intro demo should return to the empty live score")
end

local function testDemoCommandReopensIntroPreview()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = true,
            hasSeenIntroDemo = true,
        }),
    })
    local Deathpool = context.Deathpool

    Deathpool.introDemoController:Dismiss()
    Deathpool:Hide()

    context.runSlash("demo")
    assertEquals(Deathpool:IsShown(), true, "demo command should show the main window")
    assertEquals(DeathpoolCharacterState.hidden, false, "demo command should persist the main window as visible")
    assertEquals(getIntroDemoState(Deathpool) ~= nil, true, "demo command should restore the intro preview state")
    assertEquals(Deathpool.lockButton:GetText(), "START GAME", "demo command should relabel the lock button to start game")
    assertEquals(Deathpool.totalPointsValue:GetText(), "0", "demo command should restart the scripted demo from zero score")
    assertEquals(DeathpoolCharacterState.hasSeenIntroDemo, true, "demo command should not reset the completion flag")
end

local function testReplayedDemoStartGameOpensIncompleteSetup()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = true,
            hasSeenIntroDemo = true,
        }),
        hardcoreDeathChatType = "0",
        hardcoreDeathsJoined = false,
    })
    local Deathpool = context.Deathpool

    context.runSlash("demo")
    assertEquals(getIntroDemoState(Deathpool) ~= nil, true, "demo command should start the replayed intro demo")
    assertEquals(Deathpool.setupFrame:IsShown(), false, "replayed demo should hide incomplete setup while active")

    Deathpool.lockButton:GetScript("OnClick")()
    assertEquals(getIntroDemoState(Deathpool), nil, "starting the game should end the replayed demo")
    assertTruthy(Deathpool.setupFrame:IsShown(), "starting the game from a replayed demo should show incomplete setup")
end

local function testDemoCommandPrintsErrorWhileCollapsed()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = true,
            hasSeenIntroDemo = true,
            collapsed = true,
        }),
    })
    local Deathpool = context.Deathpool
    local chatMessages = context.chatMessages

    Deathpool.introDemoController:Dismiss()
    Deathpool:Hide()

    context.runSlash("demo")
    assertEquals(Deathpool.isCollapsed, true, "demo command should leave the main window collapsed")
    assertEquals(Deathpool:IsShown(), false, "demo command should not show the main window while collapsed")
    assertEquals(getIntroDemoState(Deathpool), nil, "demo command should not start the intro preview while collapsed")
    assertContains(
        chatMessages[#chatMessages],
        "Expand the main window",
        "demo command should explain that the window must be expanded first"
    )
end

local function testIntroCommandResetsIntroductionFlagsAndPrintsMessage()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = true,
            hasSeenIntroDemo = true,
            hasSeenFirstRun = true,
        }),
    })
    local chatMessages = context.chatMessages

    context.runSlash("resetintro")
    assertContains(
        chatMessages[#chatMessages],
        "requires debug mode",
        "resetintro command should require debug mode before it will run"
    )

    context.runSlash("debug")
    context.runSlash("resetintro")
    assertEquals(DeathpoolCharacterState.hasSeenIntroDemo, false, "resetintro command should re-enable the intro demo")
    assertEquals(DeathpoolCharacterState.hasSeenFirstRun, false, "resetintro command should re-enable the first-run prompt")
    assertContains(
        chatMessages[#chatMessages],
        "Introduction enabled",
        "resetintro command should confirm that the introduction was enabled"
    )
end

local function testResetCommandRequiresDebugModeAndReinitializesDefaults()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
            hasSeenFirstRun = true,
            logWindowShown = true,
            showInCombat = true,
            collapsed = true,
            totalPoints = 88,
            recentDeaths = {
                Fixtures.storedDeath({
                    timestamp = 100,
                    name = "Saveddeath",
                }),
            },
        }),
        login = true,
    })
    local chatMessages = context.chatMessages

    context.runSlash("reset")
    assertContains(
        chatMessages[#chatMessages],
        "requires debug mode",
        "reset command should require debug mode before it will run"
    )

    context.runSlash("debug")
    context.runSlash("reset")
    assertEquals(DeathpoolCharacterState.hidden, true, "reset command should hide the main window when it runs")
end

local function testHidingMainWindowClosesLogWindow()
    local context = createLoadedAddonContext()
    local Deathpool = context.Deathpool
    local DeathpoolLog = context.DeathpoolLog

    Deathpool.collapsedWindowStates = {
        logFrame = true,
    }
    DeathpoolLog:Show()
    Deathpool:Show()

    Deathpool:Hide()

    assertEquals(DeathpoolLog:IsShown(), false, "hiding the main window should close the log window")
    assertEquals(
        DeathpoolCharacterState.logWindowShown,
        false,
        "hiding the main window should preserve the desired hidden log window state"
    )
end

local function testSetupWindowClosesLogWindowWithoutRememberingLogState()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
            logWindowShown = false,
        }),
        login = true,
    })
    local Deathpool = context.Deathpool
    local DeathpoolLog = context.DeathpoolLog

    context.runSlash("log")
    assertTruthy(DeathpoolLog:IsShown(), "log command should show the log before setup opens")
    assertEquals(DeathpoolCharacterState.logWindowShown, true, "log command should persist the desired open state")

    context.runSlash("setup")

    assertTruthy(Deathpool.setupFrame:IsShown(), "setup command should show setup")
    assertEquals(DeathpoolLog:IsShown(), false, "setup should close the log window")
    assertEquals(
        DeathpoolCharacterState.logWindowShown,
        true,
        "setup should not persist a closed desired log state"
    )

    DeathpoolUI.SetLogWindowShown(Deathpool, DeathpoolCharacterState, false)
    context.runSlash("log")

    assertEquals(DeathpoolCharacterState.logWindowShown, true, "log command should still update desired log state")
    assertEquals(DeathpoolLog:IsShown(), false, "setup should keep the log hidden when log is toggled open")
end

local function testHidingMainWindowDoesNotCompleteIntroDemo()
    local context = createLoadedAddonContext()
    local Deathpool = context.Deathpool

    Deathpool:Show()
    Deathpool.introDemoController:Show()

    Deathpool:Hide()

    assertEquals(Deathpool.lockButton:GetText(), "START GAME", "hiding the main window should preserve the demo action")
    assertEquals(getIntroDemoState(Deathpool) ~= nil, true, "hiding the main window should preserve the intro demo")
    assertEquals(DeathpoolCharacterState.hasSeenIntroDemo, false, "hiding the main window should not mark the intro demo as seen")
end

local function testAddonRestoresOpenLogWindowAfterReload()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
            collapsed = false,
            logWindowShown = true,
        }),
        login = true,
    })

    assertTruthy(context.Deathpool:IsShown(), "startup should show the main window when it is not hidden")
    assertTruthy(context.DeathpoolLog:IsShown(), "startup should restore the log window when its saved preference is open")
end

local function testAddonRestoresSavedHistoryFilterAfterReload()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
            collapsed = false,
            logWindowShown = true,
            historySuccessfulOnly = false,
            deathHistory = {
                Fixtures.storedDeath({
                    timestamp = 100,
                    name = "Savedallhistory",
                    sourceName = "Savedallsource",
                }),
            },
            successfullyPredictedDeaths = {
                Fixtures.storedDeath({
                    timestamp = 101,
                    name = "Savedsuccess",
                }),
            },
        }),
        login = true,
    })

    assertEquals(context.DeathpoolLog.showSuccessfulOnly, false, "startup should restore the saved all-history filter mode")
    assertEquals(context.DeathpoolLog.logSubtitle:GetText(), "All Predictions", "startup should restore the saved all-history subtitle")
    assertEquals(context.DeathpoolLog.filterButton:GetText(), "SHOW SUCCESS ONLY", "startup should restore the alternate filter action")
    assertEquals(context.DeathpoolLog.rows[1].sourceName:GetText(), "Savedallsource", "startup should restore all-history rows as sources when that mode was saved")
end

local function testAddonLoadRestoresSavedCollapsedWindowPosition()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = true,
            hasSeenIntroDemo = true,
            collapsed = true,
            collapsedWindowHeight = 98,
            collapsedWindowPosition = {
                point = "CENTER",
                relativePoint = "CENTER",
                x = -180,
                y = 72,
            },
        }),
    })
    local Deathpool = context.Deathpool

    assertEquals(Deathpool.width, 350, "addon load should restore the minimized width")
    assertEquals(Deathpool.height, 100, "addon load should restore the minimized height")
    assertEquals(Deathpool.points[1][4], -180, "addon load should restore the saved minimized x offset")
    assertEquals(Deathpool.points[1][5], 72, "addon load should restore the saved minimized y offset")
end

local function testExpandingReloadedCollapsedWindowRestoresRecentDeathRows()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
            hasSeenFirstRun = true,
            collapsed = true,
            recentDeaths = {
                Fixtures.storedDeath({
                    name = "Reloadmini",
                    level = 19,
                    sourceName = "Murloc",
                    zone = "Westfall",
                }),
            },
        }),
    })
    local Deathpool = context.Deathpool

    assertEquals(Deathpool.isCollapsed, true, "startup should restore the saved mini-log state")
    assertEquals(Deathpool.recentDeathsFrame:IsShown(), false, "collapsed startup should hide the expanded recent death pane")
    assertEquals(Deathpool.deathRows[1].sourceName:GetText(), "Murloc", "collapsed startup should still populate expanded death row data")

    _G.DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, false)

    assertEquals(Deathpool.isCollapsed, false, "expanding the mini-log should restore the expanded state")
    assertEquals(Deathpool.recentDeathsFrame:IsShown(), true, "expanding the mini-log should show the expanded recent death pane")
    assertEquals(Deathpool.deathRows[1]:IsShown(), true, "expanding the mini-log should show populated death rows")
    assertEquals(Deathpool.deathRows[1].sourceName:GetText(), "Murloc", "expanded death rows should show saved recent deaths")
end

local function testAddonLoadDefaultsCombatAutoMinimizeToEnabled()
    createLoadedAddonContext()

    assertEquals(DeathpoolCharacterState.showInCombat, getDefault("showInCombat"), "addon load should honor the configured show-in-combat default")
end

local function testAddonLoadDefaultsDeathAnnouncementToEnabled()
    createLoadedAddonContext()

    assertEquals(
        DeathpoolCharacterState.announcements.enabled,
        getDefault("announcements").enabled,
        "addon load should honor the configured guild announcement default"
    )
    assertEquals(
        DeathpoolCharacterState.announcements.announceScoreOnDeath,
        getDefault("announcements").announceScoreOnDeath,
        "addon load should honor the configured death announcement default"
    )

    assertEquals(
        _G.DeathpoolUISettings.guildAnnouncementsEnabledCheckbox:GetChecked(),
        getDefault("announcements").enabled,
        "settings panel should show the configured guild announcement default"
    )
    assertEquals(
        _G.DeathpoolUISettings.announceDeathToGuildCheckbox:IsEnabled(),
        getDefault("announcements").enabled,
        "settings panel should enable guild announcement options from the configured default"
    )
end

local function testCombatAutoMinimizeCollapsesVisibleExpandedWindow()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
            collapsed = false,
            showInCombat = false,
        }),
        login = true,
    })
    local Deathpool = context.Deathpool
    local dispatchEvent = context.dispatchEvent
    local controller = context.controller

    assertEquals(Deathpool.isCollapsed, false, "window should begin expanded for the show-in-combat test")
    assertEquals(dispatchEvent(controller, "PLAYER_REGEN_DISABLED"), true, "combat event should dispatch when registered")
    assertEquals(Deathpool.isCollapsed, true, "entering combat should collapse the visible main window when show-in-combat is disabled")
    assertEquals(DeathpoolCharacterState.collapsed, true, "entering combat should persist the collapsed state")
end

local function testShowInCombatCommandKeepsWindowVisibleInCombat()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
            collapsed = false,
            showInCombat = false,
        }),
        login = true,
    })
    local Deathpool = context.Deathpool
    local chatMessages = context.chatMessages
    local dispatchEvent = context.dispatchEvent
    local controller = context.controller

    context.runSlash("showincombat")
    assertEquals(DeathpoolCharacterState.showInCombat, true, "showincombat command should enable showing the window in combat")
    assertContains(chatMessages[#chatMessages], "Show in combat enabled", "showincombat should announce enablement")

    assertEquals(dispatchEvent(controller, "PLAYER_REGEN_DISABLED"), true, "combat event should still dispatch after toggling the setting")
    assertEquals(Deathpool.isCollapsed, false, "entering combat should not collapse the main window while show-in-combat is enabled")
end

local function testPlayerDeathPreservesFinalScoreAndPrintsIt()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
            totalPoints = 12345,
            announcements = {
                enabled = true,
            },
        }),
        login = true,
    })
    local Deathpool = context.Deathpool
    local dispatchEvent = context.dispatchEvent
    local controller = context.controller
    local sentChatMessages = context.sentChatMessages

    assertEquals(Deathpool.totalPointsValue:GetText(), "12,345", "startup should show the pre-death running score")
    assertEquals(Deathpool.collapsedPointsValue:GetText(), "12,345", "startup should show the pre-death collapsed score")

    assertEquals(dispatchEvent(controller, "PLAYER_DEAD"), true, "player death should dispatch when registered")
    assertEquals(DeathpoolCharacterState.totalPoints, 12345, "player death should preserve the stored final score")
    assertEquals(Deathpool.totalPointsValue:GetText(), "12,345", "player death should leave the main score visible")
    assertEquals(Deathpool.collapsedPointsValue:GetText(), "12,345", "player death should leave the collapsed score visible")
    assertTruthy(string.find(context.chatMessages[#context.chatMessages], "score", 1, true), "player death should print the final score")
    assertEquals(#sentChatMessages, 1, "player death should send exactly one guild chat announcement")
    assertEquals(
        sentChatMessages[1].message,
        "[Hardcore Death Pool] Final score: 12,345",
        "player death should announce the player and final score in guild chat"
    )
    assertEquals(sentChatMessages[1].chatType, "GUILD", "player death should announce the final score to guild chat")
end

local function testPlayerDeathSkipsGuildAnnouncementWhenDisabled()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
            totalPoints = 12345,
            announcements = {
                enabled = true,
                announceScoreOnDeath = false,
            },
        }),
        login = true,
    })
    local dispatchEvent = context.dispatchEvent
    local controller = context.controller
    local sentChatMessages = context.sentChatMessages

    assertEquals(dispatchEvent(controller, "PLAYER_DEAD"), true, "player death should still dispatch when guild announcement is disabled")
    assertTruthy(string.find(context.chatMessages[#context.chatMessages], "score", 1, true), "player death should still print the final score when guild announcement is disabled")
    assertEquals(#sentChatMessages, 0, "player death should skip the guild chat announcement when disabled")
end

local function testPlayerDeathSkipsGuildAnnouncementWhenMasterDisabled()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
            totalPoints = 12345,
            announcements = {
                enabled = false,
                announceScoreOnDeath = true,
            },
        }),
        login = true,
    })
    local dispatchEvent = context.dispatchEvent
    local controller = context.controller
    local sentChatMessages = context.sentChatMessages

    assertEquals(dispatchEvent(controller, "PLAYER_DEAD"), true, "player death should still dispatch when announcements are disabled")
    assertTruthy(string.find(context.chatMessages[#context.chatMessages], "score", 1, true), "player death should still print the final score when announcements are disabled")
    assertEquals(#sentChatMessages, 0, "player death should skip guild chat when the announcement master switch is disabled")
end

local function testPlayerDeathSkipsGuildAnnouncementWhenNotInGuild()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
            totalPoints = 12345,
            announcements = {
                enabled = true,
                announceScoreOnDeath = true,
            },
        }),
        inGuild = false,
        login = true,
    })

    assertEquals(
        context.dispatchEvent(context.controller, "PLAYER_DEAD"),
        true,
        "player death should still dispatch when the player is not in a guild"
    )
    assertTruthy(
        string.find(context.chatMessages[#context.chatMessages], "score", 1, true),
        "player death should still print the final score when the player is not in a guild"
    )
    assertEquals(#context.sentChatMessages, 0, "player death should not send guild chat when the player is not in a guild")
end

local function testPlayerLevelUpAnnouncesScoreEveryTenLevels()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            totalPoints = 12345,
            announcements = {
                enabled = true,
            },
        }),
    })
    local dispatchEvent = context.dispatchEvent
    local controller = context.controller
    local sentChatMessages = context.sentChatMessages

    assertEquals(dispatchEvent(controller, "PLAYER_LEVEL_UP", 10), true, "player level up should dispatch when registered")
    assertEquals(#sentChatMessages, 1, "level 10 should send one guild announcement")
    assertEquals(
        sentChatMessages[1].message,
        "[Hardcore Death Pool] HarnessPlayer has reached level 10! Their score is 12,345",
        "level-up announcement should include the player, level, and formatted score"
    )
    assertEquals(sentChatMessages[1].chatType, "GUILD", "level-up announcement should use guild chat")

    dispatchEvent(controller, "PLAYER_LEVEL_UP", 60)
    assertEquals(#sentChatMessages, 2, "level 60 should send another guild announcement")
    assertEquals(
        sentChatMessages[2].message,
        "[Hardcore Death Pool] HarnessPlayer has reached level 60! Their score is 12,345",
        "level 60 announcement should use the same message format"
    )
end

local function testPlayerLevelUpSkipsLevelsBetweenAnnouncements()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            totalPoints = 12345,
            announcements = {
                enabled = true,
            },
        }),
    })

    assertEquals(
        context.dispatchEvent(context.controller, "PLAYER_LEVEL_UP", 19),
        true,
        "non-announcement level ups should still dispatch"
    )
    assertEquals(#context.sentChatMessages, 0, "levels between multiples of 10 should not send guild announcements")
end

local function testPlayerLevelUpSkipsWhenGuildAnnouncementsDisabled()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            totalPoints = 12345,
            announcements = {
                enabled = false,
            },
        }),
    })

    assertEquals(
        context.dispatchEvent(context.controller, "PLAYER_LEVEL_UP", 10),
        true,
        "player level up should dispatch while guild announcements are disabled"
    )
    assertEquals(#context.sentChatMessages, 0, "disabled guild announcements should suppress level-up messages")
end

local function testPlayerLevelUpSkipsWhenLevelUpAnnouncementsDisabled()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            totalPoints = 12345,
            announcements = {
                enabled = true,
                announceScoreOnLevelUp = false,
            },
        }),
    })

    assertEquals(
        context.dispatchEvent(context.controller, "PLAYER_LEVEL_UP", 10),
        true,
        "player level up should dispatch while level-up announcements are disabled"
    )
    assertEquals(#context.sentChatMessages, 0, "disabled level-up announcements should suppress guild messages")
end

local function testPlayerLevelUpSkipsWhenNotInGuild()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            totalPoints = 12345,
            announcements = {
                enabled = true,
                announceScoreOnLevelUp = true,
            },
        }),
        inGuild = false,
    })

    assertEquals(
        context.dispatchEvent(context.controller, "PLAYER_LEVEL_UP", 10),
        true,
        "player level up should still dispatch when the player is not in a guild"
    )
    assertEquals(#context.sentChatMessages, 0, "player level up should not send guild chat when the player is not in a guild")
end

local function testEscapeClosesAndPersistsMainWindowHiddenState()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
        }),
        login = true,
    })
    local Deathpool = context.Deathpool

    assertTruthy(Deathpool:IsShown(), "startup should show the main window before escape is pressed")
    assertEquals(context.pressEscape(), true, "escape should close the special main window")
    assertEquals(Deathpool:IsShown(), false, "escape should hide the main window")
    assertEquals(DeathpoolCharacterState.hidden, true, "escape should persist the main window as hidden")
end

local function testEscapeDoesNotCloseCollapsedMainWindow()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
            collapsed = true,
        }),
        login = true,
    })
    local Deathpool = context.Deathpool

    assertTruthy(Deathpool:IsShown(), "startup should show the collapsed main window before escape is pressed")
    assertEquals(Deathpool.isCollapsed, true, "startup should keep the main window collapsed for the escape exclusion test")
    assertEquals(context.pressEscape(), false, "escape should not close the collapsed main window")
    assertTruthy(Deathpool:IsShown(), "escape should leave the collapsed main window visible")
    assertEquals(DeathpoolCharacterState.hidden, false, "escape should not persist the collapsed main window as hidden")
end

local function testSlashCommandsReachTheirExpectedBranches()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
            showInCombat = true,
            recentDeaths = {},
        }),
        login = true,
    })
    local Deathpool = context.Deathpool
    local DeathpoolLog = context.DeathpoolLog
    local chatMessages = context.chatMessages

    context.runSlash("  hide  ")
    assertEquals(Deathpool:IsShown(), false, "hide command should hide the main window")
    assertEquals(DeathpoolCharacterState.hidden, true, "hide command should persist the main window as hidden")

    context.runSlash("show")
    assertTruthy(Deathpool:IsShown(), "show command should show the main window")
    assertEquals(DeathpoolCharacterState.hidden, false, "show command should persist the main window as visible")

    context.runSlash("toggle")
    assertEquals(Deathpool:IsShown(), false, "toggle command should hide the main window when it starts visible")

    context.runSlash("")
    assertTruthy(Deathpool:IsShown(), "empty command should behave like toggle and show the main window")
    assertEquals(DeathpoolLog:IsShown(), false, "showing the main window again should keep the default hidden log window closed")

    context.runSlash("log")
    assertTruthy(DeathpoolLog:IsShown(), "log command should show the history window when it starts hidden")
    assertEquals(DeathpoolCharacterState.logWindowShown, true, "log command should persist the desired open state")

    context.runSlash("log")
    assertEquals(DeathpoolLog:IsShown(), false, "log command should hide the history window after it was opened")
    assertEquals(DeathpoolCharacterState.logWindowShown, false, "log command should persist the desired closed state")

    context.runSlash("setup")
    assertTruthy(Deathpool.setupFrame:IsShown(), "setup command should show the setup window")

    DeathpoolUI.SetWindowCollapsed(Deathpool, DeathpoolCharacterState, true)
    context.runSlash("setup")
    assertEquals(Deathpool.isCollapsed, false, "setup command should expand the main window before showing setup")
    assertTruthy(Deathpool.setupFrame:IsShown(), "setup command should keep setup visible after expanding the main window")

    Deathpool:Hide()
    assertEquals(Deathpool.setupFrame:IsShown(), false, "hiding the main window should close slash-opened setup")
    assertEquals(Deathpool.setupFrame.backdropOverlay:IsShown(), false, "hiding the main window should clear slash-opened setup backdrop")
    context.runSlash("setup")
    assertTruthy(Deathpool:IsShown(), "setup command should show the main window")
    assertTruthy(Deathpool.setupFrame:IsShown(), "setup command should keep the setup window shown after showing main")

    context.runSlash("debug")
    assertEquals(_G.DeathpoolDebugState.IsEnabled(), true, "debug command should reach the debug toggle branch")

    context.runSlash("showincombat")
    assertEquals(DeathpoolCharacterState.showInCombat, false, "showincombat command should reach the combat setting branch")

    context.runSlash("minimap")
    assertEquals(DeathpoolCharacterState.minimap.hide, true, "minimap command should hide the minimap icon")
    assertContains(chatMessages[#chatMessages], "Minimap icon disabled", "minimap command should announce disablement")

    context.runSlash("minimap")
    assertEquals(DeathpoolCharacterState.minimap.hide, false, "minimap command should show the minimap icon again")
    assertContains(chatMessages[#chatMessages], "Minimap icon enabled", "minimap command should announce enablement")

    context.runSlash("demo")
    assertTruthy(getIntroDemoState(Deathpool) ~= nil, "demo command should reach the intro demo branch")

    local messageCountBeforeHelp = #chatMessages
    context.runSlash("help")
    local sawIntroHelp = false
    local sawSetupHelp = false
    for messageIndex = messageCountBeforeHelp + 1, #chatMessages do
        if string.find(chatMessages[messageIndex], "/deathpool resetintro", 1, true) then
            sawIntroHelp = true
        end
        if string.find(chatMessages[messageIndex], "/deathpool setup", 1, true) then
            sawSetupHelp = true
        end
    end
    assertEquals(sawIntroHelp, true, "help command should list the resetintro command")
    assertEquals(sawSetupHelp, true, "help command should list the setup command")

    local messageCountBeforeMissingDebugDeath = #chatMessages
    context.runSlash("debugdeath")
    assertEquals(#chatMessages, messageCountBeforeMissingDebugDeath + 1, "debugdeath with no payload should print usage")

    local messageCountBeforeBadDebugDeath = #chatMessages
    context.runSlash("debugdeath definitely not a death message")
    assertEquals(#chatMessages, messageCountBeforeBadDebugDeath + 1, "debugdeath with bad text should print the no-match message")

    local recentDeathCountBeforeTestDeath = #(DeathpoolCharacterState.recentDeaths or {})
    context.runSlash("testdeath")
    assertEquals(
        #DeathpoolCharacterState.recentDeaths,
        recentDeathCountBeforeTestDeath + 1,
        "testdeath command should add a synthetic death row"
    )
    assertEquals(
        DeathpoolCharacterState.recentDeaths[#DeathpoolCharacterState.recentDeaths].server,
        "Defias Pillager",
        "testdeath command should persist the current server on stored death rows"
    )
end

local function testSettingsPanelRegistersAddonCategoryAndReflectsSavedState()
    createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            announcements = {
                enabled = true,
                announceScoreOnDeath = true,
                announceScoreOnLevelUp = false,
            },
            minimap = {
                hide = true,
            },
            showInCombat = true,
        }),
    })

    local category = _G.Settings.registeredAddOnCategories[#_G.Settings.registeredAddOnCategories]
    ---@type DeathpoolUISettingsPanelModule
    local settingsModule = _G.DeathpoolUISettings
    local function getRelativeToAndXOffset(region)
        local _, relativeTo, _, x = region:GetPoint(1)
        return relativeTo, x
    end

    assertTruthy(category ~= nil, "settings panel should register an addon category")
    assertTruthy(category.frame ~= nil, "settings panel should register a category frame")
    assertEquals(category.frame.name, "Deathpool", "settings panel should register the Deathpool category")
    assertEquals(category.name, "Hardcore Death Pool", "settings panel should register the full addon display name")

    category.frame:Show()
    assertEquals(
        settingsModule.guildAnnouncementsEnabledCheckbox:GetChecked(),
        true,
        "settings panel should reflect saved guild announcements enabled state"
    )
    assertEquals(
        settingsModule.announceDeathToGuildCheckbox:GetChecked(),
        true,
        "settings panel should reflect saved death announcement state"
    )
    assertEquals(
        settingsModule.announceDeathToGuildCheckbox:IsEnabled(),
        true,
        "settings panel should enable death announcements when guild announcements are enabled"
    )
    assertEquals(
        settingsModule.announceScoreOnLevelUpCheckbox:GetChecked(),
        false,
        "settings panel should reflect saved level-up announcement state"
    )
    assertEquals(
        settingsModule.announceScoreOnLevelUpCheckbox:IsEnabled(),
        true,
        "settings panel should enable level-up announcements when guild announcements are enabled"
    )
    assertEquals(
        settingsModule.announceScoreOnLevelUpCheckbox.label:GetText(),
        "Announce score every " .. DeathpoolConstants.ANNOUNCEMENTS.levelUpFrequency .. " levels",
        "settings panel should build the level-up label from the announcement frequency constant"
    )
    local deathRelativeTo, deathX = getRelativeToAndXOffset(settingsModule.announceDeathToGuildCheckbox)
    assertEquals(
        deathRelativeTo,
        settingsModule.guildAnnouncementsEnabledCheckbox,
        "settings panel should anchor death announcements under the guild announcement master setting"
    )
    assertEquals(deathX, 24, "settings panel should indent death announcements under the guild announcement master setting")

    local levelUpRelativeTo, levelUpX = getRelativeToAndXOffset(settingsModule.announceScoreOnLevelUpCheckbox)
    assertEquals(
        levelUpRelativeTo,
        settingsModule.announceDeathToGuildCheckbox,
        "settings panel should anchor level-up announcements under death announcements"
    )
    assertEquals(levelUpX, 0, "settings panel should align level-up and death announcements")

    local minimapRelativeTo, minimapX = getRelativeToAndXOffset(settingsModule.disableMinimapIconCheckbox)
    assertEquals(
        minimapRelativeTo,
        settingsModule.announceScoreOnLevelUpCheckbox,
        "settings panel should place minimap settings after announcement settings"
    )
    assertEquals(minimapX, -24, "settings panel should return minimap settings to the top-level alignment")
    assertEquals(
        settingsModule.showInCombatCheckbox:GetChecked(),
        true,
        "settings panel should reflect saved show-in-combat state"
    )
    assertEquals(
        settingsModule.disableMinimapIconCheckbox:GetChecked(),
        true,
        "settings panel should reflect saved minimap icon state"
    )
end

local function testSettingsPanelInitializeRebindsCheckboxesToLatestOptions()
    createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            showInCombat = false,
        }),
    })

    ---@type DeathpoolUISettingsPanelModule
    local settingsModule = _G.DeathpoolUISettings
    local reboundState = Fixtures.addonDatabase({
        announcements = {
            enabled = true,
            announceScoreOnDeath = true,
            announceScoreOnLevelUp = false,
        },
        minimap = {
            hide = true,
        },
        showInCombat = true,
    })

    settingsModule.Initialize({
        GetDisableMinimapIcon = function()
            return DeathpoolDatabase.GetMinimapHidden(reboundState)
        end,
        GetDeathAnnouncementToGuild = function()
            return DeathpoolDatabase.GetAnnounceDeathToGuild(reboundState)
        end,
        GetGuildAnnouncementsEnabled = function()
            return DeathpoolDatabase.GetGuildAnnouncementsEnabled(reboundState)
        end,
        GetAnnounceScoreOnLevelUp = function()
            return DeathpoolDatabase.GetAnnounceScoreOnLevelUp(reboundState)
        end,
        GetShowInCombat = function()
            return DeathpoolDatabase.GetShowInCombat(reboundState)
        end,
        SetDisableMinimapIcon = function(disabled)
            return DeathpoolDatabase.SetMinimapHidden(reboundState, disabled)
        end,
        SetDeathAnnouncementToGuild = function(enabled)
            return DeathpoolDatabase.SetAnnounceDeathToGuild(reboundState, enabled)
        end,
        SetGuildAnnouncementsEnabled = function(enabled)
            return DeathpoolDatabase.SetGuildAnnouncementsEnabled(reboundState, enabled)
        end,
        SetAnnounceScoreOnLevelUp = function(enabled)
            return DeathpoolDatabase.SetAnnounceScoreOnLevelUp(reboundState, enabled)
        end,
        SetShowInCombat = function(enabled)
            return DeathpoolDatabase.SetShowInCombat(reboundState, enabled)
        end,
    })

    assertEquals(
        settingsModule.guildAnnouncementsEnabledCheckbox:GetChecked(),
        true,
        "settings initialize should refresh guild announcements enabled state from the latest options"
    )
    assertEquals(
        settingsModule.announceDeathToGuildCheckbox:GetChecked(),
        true,
        "settings initialize should refresh death announcement state from the latest options"
    )
    assertEquals(
        settingsModule.announceDeathToGuildCheckbox:IsEnabled(),
        true,
        "settings initialize should enable death announcements when latest options enable guild announcements"
    )
    assertEquals(
        settingsModule.announceScoreOnLevelUpCheckbox:GetChecked(),
        false,
        "settings initialize should refresh level-up announcement state from the latest options"
    )
    assertEquals(
        settingsModule.announceScoreOnLevelUpCheckbox:IsEnabled(),
        true,
        "settings initialize should enable level-up announcements when latest options enable guild announcements"
    )
    assertEquals(
        settingsModule.showInCombatCheckbox:GetChecked(),
        true,
        "settings initialize should refresh show-in-combat from the latest options"
    )
    assertEquals(
        settingsModule.disableMinimapIconCheckbox:GetChecked(),
        true,
        "settings initialize should refresh minimap icon state from the latest options"
    )
end

local function testSettingsPanelCheckboxesUseSharedSettingHandlers()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            announcements = {
                enabled = false,
                announceScoreOnDeath = false,
                announceScoreOnLevelUp = false,
            },
            minimap = {
                hide = false,
            },
            showInCombat = false,
        }),
    })

    ---@type DeathpoolUISettingsPanelModule
    local settingsModule = _G.DeathpoolUISettings

    settingsModule.categoryFrame:Show()

    settingsModule.guildAnnouncementsEnabledCheckbox:SetChecked(true)
    settingsModule.guildAnnouncementsEnabledCheckbox:Click()
    assertEquals(
        DeathpoolCharacterState.announcements.enabled,
        true,
        "settings guild announcements checkbox should persist the enabled state"
    )
    assertEquals(
        settingsModule.announceDeathToGuildCheckbox:IsEnabled(),
        true,
        "settings guild announcements checkbox should enable death announcement settings"
    )
    assertEquals(
        settingsModule.announceScoreOnLevelUpCheckbox:IsEnabled(),
        true,
        "settings guild announcements checkbox should enable level-up announcement settings"
    )
    assertEquals(
        settingsModule.announceScoreOnLevelUpCheckbox:GetChecked(),
        false,
        "enabling guild announcements should preserve the saved level-up announcement state"
    )
    settingsModule.guildAnnouncementsEnabledCheckbox:SetChecked(false)
    settingsModule.guildAnnouncementsEnabledCheckbox:Click()
    assertEquals(
        DeathpoolCharacterState.announcements.enabled,
        false,
        "settings guild announcements checkbox should persist the disabled state"
    )
    assertEquals(
        settingsModule.announceDeathToGuildCheckbox:IsEnabled(),
        false,
        "settings guild announcements checkbox should disable death announcement settings"
    )
    assertEquals(
        settingsModule.announceScoreOnLevelUpCheckbox:IsEnabled(),
        false,
        "settings guild announcements checkbox should disable level-up announcement settings"
    )
    assertEquals(
        settingsModule.announceScoreOnLevelUpCheckbox:GetChecked(),
        false,
        "disabling guild announcements should preserve the saved level-up announcement state"
    )
    settingsModule.guildAnnouncementsEnabledCheckbox:SetChecked(true)
    settingsModule.guildAnnouncementsEnabledCheckbox:Click()

    settingsModule.showInCombatCheckbox:SetChecked(true)
    settingsModule.showInCombatCheckbox:Click()
    assertEquals(
        DeathpoolCharacterState.showInCombat,
        true,
        "settings show-in-combat checkbox should persist the enabled state"
    )

    settingsModule.showInCombatCheckbox:SetChecked(false)
    settingsModule.showInCombatCheckbox:Click()
    assertEquals(
        DeathpoolCharacterState.showInCombat,
        false,
        "settings show-in-combat checkbox should persist the disabled state"
    )

    settingsModule.announceDeathToGuildCheckbox:SetChecked(true)
    settingsModule.announceDeathToGuildCheckbox:Click()
    assertEquals(
        DeathpoolCharacterState.announcements.announceScoreOnDeath,
        true,
        "settings death announcement checkbox should persist the enabled state"
    )

    settingsModule.announceDeathToGuildCheckbox:SetChecked(false)
    settingsModule.announceDeathToGuildCheckbox:Click()
    assertEquals(
        DeathpoolCharacterState.announcements.announceScoreOnDeath,
        false,
        "settings death announcement checkbox should persist the disabled state"
    )

    settingsModule.announceScoreOnLevelUpCheckbox:SetChecked(true)
    settingsModule.announceScoreOnLevelUpCheckbox:Click()
    assertEquals(
        DeathpoolCharacterState.announcements.announceScoreOnLevelUp,
        true,
        "settings level-up announcement checkbox should persist the enabled state"
    )

    settingsModule.announceScoreOnLevelUpCheckbox:SetChecked(false)
    settingsModule.announceScoreOnLevelUpCheckbox:Click()
    assertEquals(
        DeathpoolCharacterState.announcements.announceScoreOnLevelUp,
        false,
        "settings level-up announcement checkbox should persist the disabled state"
    )

    settingsModule.disableMinimapIconCheckbox:SetChecked(true)
    settingsModule.disableMinimapIconCheckbox:Click()
    assertEquals(
        DeathpoolCharacterState.minimap.hide,
        true,
        "settings minimap checkbox should persist the disabled state"
    )
    assertEquals(
        context.libDBIconState.hideCalls[#context.libDBIconState.hideCalls],
        "Deathpool",
        "settings minimap checkbox should hide the registered minimap icon"
    )

    settingsModule.disableMinimapIconCheckbox:SetChecked(false)
    settingsModule.disableMinimapIconCheckbox:Click()
    assertEquals(
        DeathpoolCharacterState.minimap.hide,
        false,
        "settings minimap checkbox should persist the enabled state"
    )
    assertEquals(
        context.libDBIconState.showCalls[#context.libDBIconState.showCalls],
        "Deathpool",
        "settings minimap checkbox should show the registered minimap icon"
    )
end

local function testDispatcherSkipsUnregisteredEvents()
    local context = UIHarness.CreateAddon()

    assertEquals(
        context.dispatchEvent(context.controller, "PLAYER_ENTERING_WORLD"),
        false,
        "dispatcher should ignore events that were never registered"
    )
end

local function testHardcoreDeathsEventIsNotRegistered()
    local context = createLoadedAddonContext()

    assertEquals(
        context.dispatchEvent(context.controller, "HARDCORE_DEATHS", "[Ignored] drowned in Durotar! They were level 6"),
        false,
        "native hardcore death alerts should not dispatch through the addon frame"
    )
end

local function testNonHardcoreDeathsChannelDoesNotAddDeaths()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
        }),
        login = true,
    })

    assertEquals(
        context.dispatchEvent(
            context.controller,
            "CHAT_MSG_CHANNEL",
            "[Ignored] drowned in Durotar! They were level 6",
            "Sender",
            "",
            "1. General - Durotar",
            "",
            "",
            0,
            1,
            "General - Durotar"
        ),
        true,
        "channel chat messages should dispatch through the addon frame"
    )
    assertEquals(#DeathpoolCharacterState.recentDeaths, 0, "non-hardcoredeaths channels should not insert deaths")
end

local function testHardcoreDeathsChannelFlowsThroughParserLogicAndUi()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
            lockedPrediction = Fixtures.prediction({
                levelRange = "10-19",
                source = "hogger",
                zone = "elwynn forest",
            }),
            lastPrediction = Fixtures.prediction({
                levelRange = "10-19",
                source = "hogger",
                zone = "elwynn forest",
            }),
        }),
        login = true,
    })
    local Deathpool = context.Deathpool
    local DeathpoolDebug = context.DeathpoolDebug
    local DeathpoolLog = context.DeathpoolLog
    local DeathpoolLogic = _G.DeathpoolLogic
    local dispatchEvent = context.dispatchEvent
    local controller = context.controller
    local waitingPromptMinDuration = DEMO_RULES.waitingForFirstDeathMinDurationSeconds
    local rawMessage = "[Drakedog] has been slain by Hogger in Elwynn Forest! They were level 12"

    assertEquals(
        dispatchEvent(
            controller,
            "CHAT_MSG_CHANNEL",
            rawMessage,
            "Sender",
            "",
            "5. HardcoreDeaths",
            "",
            "",
            0,
            5,
            "HardcoreDeaths"
        ),
        true,
        "HardcoreDeaths channel messages should dispatch through the addon frame"
    )
    assertEquals(#DeathpoolCharacterState.recentDeaths, 1, "death event should insert a recent death row")
    assertEquals(#DeathpoolCharacterState.deathHistory, 1, "death event should insert a history death row")
    assertEquals(#DeathpoolCharacterState.successfullyPredictedDeaths, 1, "death event should record successful predictions")

    local storedDeath = DeathpoolCharacterState.recentDeaths[1]
    local historyDeath = DeathpoolCharacterState.deathHistory[1]
    local awardedPoints = DeathpoolLogic.GetStoredDeathAwardedPoints(storedDeath)
    local comboMultiplier = DeathpoolLogic.GetStoredDeathComboMultiplierValue(storedDeath)
    local totalMultiplier = DeathpoolLogic.GetStoredDeathMultiplierValue(storedDeath)
    local basePoints = DeathpoolLogic.GetStoredDeathBasePoints(storedDeath)
    local formattedAwardedPoints = DeathpoolLogic.FormatPoints(awardedPoints)

    assertEquals(storedDeath.name, "Drakedog", "parser flow should persist the parsed player name")
    assertEquals(storedDeath.level, 12, "parser flow should persist the parsed level")
    assertEquals(storedDeath.sourceName, "Hogger", "parser flow should persist the parsed source")
    assertEquals(storedDeath.zone, "Elwynn Forest", "parser flow should persist the parsed zone")
    assertEquals(storedDeath.server, "Defias Pillager", "insert flow should persist the current server name")
    assertEquals(storedDeath.matchedPrediction, true, "evaluation flow should mark the stored death as matched")
    assertEquals(storedDeath.points, DeathpoolLogic.GetStoredDeathBasePoints(storedDeath), "evaluation flow should persist the matched base points")
    assertEquals(storedDeath.awardedPoints, awardedPoints, "evaluation flow should persist the awarded points")
    assertEquals(DeathpoolCharacterState.totalPoints, awardedPoints, "evaluation flow should roll awarded points into the total score")
    assertEquals(DeathpoolCharacterState.correctPredictionStreak, 1, "evaluation flow should increment the current streak")
    assertEquals(DeathpoolCharacterState.longestPredictionStreak, 1, "evaluation flow should update the longest streak")
    assertEquals(historyDeath.matchedPrediction, true, "history insert should keep the evaluation result")
    assertEquals(historyDeath.prediction.elements.zone, "elwynn forest", "history insert should preserve the locked prediction")
    assertEquals(storedDeath.sameZoneBonusApplied, true, "same-zone deaths should persist the applied same-zone bonus flag")

    assertEquals(Deathpool.waitingPromptText:IsShown(), true, "ui refresh should keep the waiting prompt visible until the minimum intro duration completes")
    assertEquals(Deathpool.deathRows[1]:IsShown(), false, "ui refresh should keep the recent deaths list hidden during the waiting prompt minimum duration")

---@diagnostic disable-next-line: need-check-nil
    Deathpool:GetScript("OnUpdate")(Deathpool, waitingPromptMinDuration)
    assertEquals(Deathpool.deathRows[1].sourceName:GetText(), "Hogger", "ui refresh should show the parsed death in the recent deaths list after the waiting prompt minimum duration")
    assertEquals(Deathpool.deathRows[1].multiplier, nil, "ui refresh should omit the removed main-window combo column")
    assertEquals(Deathpool.deathRows[1].awardedPoints:GetText(), tostring(awardedPoints), "ui refresh should show the evaluated total points after the waiting prompt minimum duration")
    assertEquals(Deathpool.totalPointsValue:GetText(), formattedAwardedPoints, "ui refresh should show the updated total score")
    assertEquals(Deathpool.currentStreakValue:GetText(), "1", "ui refresh should show the updated current streak")
    assertEquals(Deathpool.collapsedLogFrame.rows[1].sourceName:GetText(), "Hogger", "ui refresh should update the collapsed death log")
    assertEquals(Deathpool.collapsedLogFrame.rows[1].awardedPoints:GetText(), tostring(awardedPoints), "ui refresh should update the collapsed death log points")
    assertEquals(Deathpool.collapsedPointsValue:GetText(), formattedAwardedPoints, "ui refresh should update the collapsed score")
    assertEquals(DeathpoolLog.rows[1].sourceName:GetText(), "Hogger", "ui refresh should update the successful history log with the death source")
    assertEquals(DeathpoolLog.rows[1].awardedPoints:GetText(), tostring(awardedPoints), "ui refresh should update history totals")
    assertEquals(DeathpoolDebug.detailValues.name:GetText(), "Drakedog", "ui refresh should update the debug detail view")
    assertEquals(DeathpoolDebug.detailValues.totalPoints:GetText(), tostring(awardedPoints), "ui refresh should update debug total points")
    assertEquals(DeathpoolDebug.detailValues.currentPredictionStreak:GetText(), "1", "ui refresh should update debug current streak")
    assertContains(DeathpoolDebug.detailValues.lockedPrediction:GetText(), "Level 10-19, source Hogger, or zone Elwynn Forest", "ui refresh should update the debug locked prediction summary")
    assertEquals(DeathpoolDebug.detailValues.basePoints:GetText(), tostring(basePoints), "ui refresh should update debug base points")
    assertEquals(DeathpoolDebug.detailValues.comboMultiplier:GetText(), "x" .. tostring(comboMultiplier), "ui refresh should update debug combo bonus")
    assertEquals(DeathpoolDebug.detailValues.multiplier:GetText(), "x" .. tostring(totalMultiplier), "ui refresh should update debug total multiplier")
    assertEquals(
        DeathpoolDebug.detailValues.sourceMessage:GetText(),
        storedDeath.sourceMessage,
        "ui refresh should update the debug raw message edit box"
    )
    assertEquals(DeathpoolDebug.detailValues.awardedPoints:GetText(), tostring(awardedPoints), "ui refresh should update debug awarded points")
end

local function testHardcoreDeathsChannelWithoutSameZoneBonus()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
            lockedPrediction = Fixtures.prediction({
                levelRange = false,
                source = "hogger",
                zone = false,
                zoneLabel = false,
            }),
            lastPrediction = Fixtures.prediction({
                levelRange = false,
                source = "hogger",
                zone = false,
                zoneLabel = false,
            }),
        }),
        login = true,
    })
    local dispatchEvent = context.dispatchEvent
    local controller = context.controller
    local sourcePoints = LogicHelpers.getExpectedBasePoints({ source = true })
    local expectedAwardedPoints = sourcePoints * LogicHelpers.getDisplayMultiplier(1, 1)
    local rawMessage = "[Drakedog] has been slain by Hogger in Westfall! They were level 12"

    assertEquals(
        dispatchEvent(
            controller,
            "CHAT_MSG_CHANNEL",
            rawMessage,
            "Sender",
            "",
            "5. HardcoreDeaths",
            "",
            "",
            0,
            5,
            "HardcoreDeaths"
        ),
        true,
        "HardcoreDeaths channel messages should still dispatch when the death is outside the player's current zone"
    )

    local storedDeath = DeathpoolCharacterState.recentDeaths[1]
    assertEquals(storedDeath.sameZoneBonusApplied, false, "different-zone deaths should not persist the same-zone bonus flag")
    assertEquals(
        _G.DeathpoolLogic.GetStoredDeathSameZoneBonusPoints(storedDeath),
        0,
        "different-zone deaths should not award same-zone bonus points"
    )
    assertEquals(
        _G.DeathpoolLogic.GetStoredDeathAwardedPoints(storedDeath),
        expectedAwardedPoints,
        "different-zone deaths should keep the normal awarded score"
    )
end

local function testHardcoreDeathsChannelApplySameZoneBonusWithoutZonePrediction()
    local context = createLoadedAddonContext({
        state = Fixtures.addonDatabase({
            hidden = false,
            hasSeenIntroDemo = true,
            lockedPrediction = Fixtures.prediction({
                levelRange = false,
                source = "hogger",
                zone = false,
                zoneLabel = false,
            }),
            lastPrediction = Fixtures.prediction({
                levelRange = false,
                source = "hogger",
                zone = false,
                zoneLabel = false,
            }),
        }),
        login = true,
    })
    local dispatchEvent = context.dispatchEvent
    local controller = context.controller
    local sourcePoints = LogicHelpers.getExpectedBasePoints({ source = true })
    local sameZonePoints = _G.DeathpoolConstants.SCORING.sameZoneFixedBonusPoints
    local expectedMultiplier = LogicHelpers.getDisplayMultiplier(1, 1)
    local rawMessage = "[Drakedog] has been slain by Hogger in Elwynn Forest! They were level 12"

    assertEquals(
        dispatchEvent(
            controller,
            "CHAT_MSG_CHANNEL",
            rawMessage,
            "Sender",
            "",
            "5. HardcoreDeaths",
            "",
            "",
            0,
            5,
            "HardcoreDeaths"
        ),
        true,
        "HardcoreDeaths channel messages should still dispatch when same-zone bonus comes from a non-zone prediction"
    )

    local storedDeath = DeathpoolCharacterState.recentDeaths[1]
    assertEquals(storedDeath.sameZoneBonusApplied, true, "same-zone deaths should persist the bonus flag even without a zone prediction")
    assertEquals(
        _G.DeathpoolLogic.GetStoredDeathSameZoneBonusPoints(storedDeath),
        sameZonePoints,
        "same-zone deaths should award bonus points even when zone was not predicted"
    )
    assertEquals(
        _G.DeathpoolLogic.GetStoredDeathAwardedPoints(storedDeath),
        (sourcePoints + sameZonePoints) * expectedMultiplier,
        "same-zone bonus should add into the total for non-zone predictions"
    )
end

testAddonDefersUiCreationUntilAddonLoaded()
testMainWindowVisibilityPersistsThroughStartup()
testIncompleteSetupReopensUntilComplete()
testStartGameOpensSetupBeforeNormalGameplay()
testHidingIntroDemoResumesBeforeIncompleteSetup()
testAddonLoadRebindsUiToSavedVariablesTable()
testReloadDoesNotPersistVisibleMainWindowAsHidden()
testDebugLogOnlyPrintsWhileDebugModeIsEnabled()
testDebugToggleControlsWindowAndPrinting()
testReloadClearsLegacySavedDebugFlagAndSessionDebugMode()
testFirstShowStartsAndDismissesIntroDemo()
testDemoCommandReopensIntroPreview()
testReplayedDemoStartGameOpensIncompleteSetup()
testDemoCommandPrintsErrorWhileCollapsed()
testIntroCommandResetsIntroductionFlagsAndPrintsMessage()
testResetCommandRequiresDebugModeAndReinitializesDefaults()
testHidingMainWindowClosesLogWindow()
testSetupWindowClosesLogWindowWithoutRememberingLogState()
testHidingMainWindowDoesNotCompleteIntroDemo()
testAddonRestoresOpenLogWindowAfterReload()
testAddonRestoresSavedHistoryFilterAfterReload()
testAddonLoadRestoresSavedCollapsedWindowPosition()
testExpandingReloadedCollapsedWindowRestoresRecentDeathRows()
testAddonLoadDefaultsCombatAutoMinimizeToEnabled()
testAddonLoadDefaultsDeathAnnouncementToEnabled()
testCombatAutoMinimizeCollapsesVisibleExpandedWindow()
testShowInCombatCommandKeepsWindowVisibleInCombat()
testPlayerDeathPreservesFinalScoreAndPrintsIt()
testPlayerDeathSkipsGuildAnnouncementWhenDisabled()
testPlayerDeathSkipsGuildAnnouncementWhenMasterDisabled()
testPlayerDeathSkipsGuildAnnouncementWhenNotInGuild()
testPlayerLevelUpAnnouncesScoreEveryTenLevels()
testPlayerLevelUpSkipsLevelsBetweenAnnouncements()
testPlayerLevelUpSkipsWhenGuildAnnouncementsDisabled()
testPlayerLevelUpSkipsWhenLevelUpAnnouncementsDisabled()
testPlayerLevelUpSkipsWhenNotInGuild()
testEscapeClosesAndPersistsMainWindowHiddenState()
testEscapeDoesNotCloseCollapsedMainWindow()
testSlashCommandsReachTheirExpectedBranches()
testSettingsPanelRegistersAddonCategoryAndReflectsSavedState()
testSettingsPanelInitializeRebindsCheckboxesToLatestOptions()
testSettingsPanelCheckboxesUseSharedSettingHandlers()
testDispatcherSkipsUnregisteredEvents()
testHardcoreDeathsEventIsNotRegistered()
testNonHardcoreDeathsChannelDoesNotAddDeaths()
testHardcoreDeathsChannelFlowsThroughParserLogicAndUi()
testHardcoreDeathsChannelWithoutSameZoneBonus()
testHardcoreDeathsChannelApplySameZoneBonusWithoutZonePrediction()

suite:finish()

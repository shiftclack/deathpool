package.path = table.concat({
    "./src/?.lua",
    "./?.lua",
    "./?/init.lua",
    package.path,
}, ";")

local TestHelpers = require("tests.support_helpers")
local suite = TestHelpers.CreateSuite()
local assertEquals = function(actual, expected, message)
    suite:assertEquals(actual, expected, message)
end
local assertTruthy = function(value, message)
    suite:assertTruthy(value, message)
end

local function resetEnvironment()
    package.loaded.DeathpoolDatabase = nil
    package.loaded.DeathpoolLogic = nil
    package.loaded.DeathpoolLogicPrediction = nil
    package.loaded.DeathpoolLogicScoring = nil
    package.loaded.DeathpoolLogicDeaths = nil
    package.loaded.DeathpoolLogicState = nil
    package.loaded.DeathpoolConstants = nil
    package.loaded.DeathpoolDebug = nil
    package.loaded.DeathpoolUI = nil
    package.loaded.DeathpoolUIMinimap = nil
    _G.DeathpoolDatabase = nil
    _G.DeathpoolLogic = nil
    _G.DeathpoolConstants = nil
    _G.DeathpoolDebug = nil
    DeathpoolUIMinimap = nil
    DeathpoolCharacterState = nil
    DeathpoolUI = nil
end

local function createButton(dataObject)
    local button = {
        dataObject = dataObject,
        icon = {
            texturePath = dataObject.icon,
        },
        scripts = {},
    }

    function button:GetScript(eventName)
        return self.scripts[eventName]
    end

    button.scripts.OnClick = dataObject.OnClick
    return button
end

local function createLibStubs()
    local state = {
        registerCalls = {},
        refreshCalls = {},
        hideCalls = {},
        showCalls = {},
    }

    local libDataBroker = {}

    function libDataBroker.NewDataObject(_, name, dataObject)
        state.lastDataObjectName = name
        state.lastDataObject = dataObject
        return dataObject
    end

    local libDBIcon = {}

    function libDBIcon.Register(_, name, dataObject, database)
        state.registerCalls[#state.registerCalls + 1] = {
            name = name,
            dataObject = dataObject,
            database = database,
        }
        state.button = createButton(dataObject)
    end

    function libDBIcon.Refresh(_, name, database)
        state.refreshCalls[#state.refreshCalls + 1] = {
            name = name,
            database = database,
        }
    end

    function libDBIcon.Hide(_, name)
        state.hideCalls[#state.hideCalls + 1] = name
        if state.button then
            state.button.hidden = true
        end
    end

    function libDBIcon.Show(_, name)
        state.showCalls[#state.showCalls + 1] = name
        if state.button then
            state.button.hidden = false
        end
    end

    function libDBIcon.GetMinimapButton()
        return state.button
    end

    LibStub = function(libraryName, silent)
        local libraries = {
            ["LibDataBroker-1.1"] = libDataBroker,
            ["LibDBIcon-1.0"] = libDBIcon,
        }

        local library = libraries[libraryName]
        if library ~= nil then
            return library
        end

        if not silent then
            error("Unknown library: " .. tostring(libraryName))
        end

        return nil
    end

    return state
end

local function loadMinimapModule()
    resetEnvironment()

    local state = createLibStubs()

    _G.DeathpoolConstants = require("DeathpoolConstants")
    _G.DeathpoolDatabase = require("DeathpoolDatabase")
    _G.DeathpoolDebug = require("DeathpoolDebug")
    _G.DeathpoolLogic = require("DeathpoolLogic")
    _G.DeathpoolUI = require("DeathpoolUI")
    require("DeathpoolLogicPrediction")
    require("DeathpoolLogicScoring")
    require("DeathpoolLogicDeaths")
    require("DeathpoolLogicState")
    local module = require("DeathpoolUIMinimap")
    return module, state
end

local function createFrame(options)
    options = options or {}

    local frame = {
        shown = options.shown == true,
        isCollapsed = options.isCollapsed == true,
        scripts = {},
    }

    function frame:SetScript(eventName, callback)
        self.scripts[eventName] = callback
    end

    function frame:GetScript(eventName)
        return self.scripts[eventName]
    end

    function frame:IsShown()
        return self.shown == true
    end

    function frame:Show()
        self.shown = true
        local onShow = self:GetScript("OnShow")
        if onShow then
            onShow(self)
        end
    end

    function frame:Hide()
        self.shown = false
        local onHide = self:GetScript("OnHide")
        if onHide then
            onHide(self)
        end
    end

    function frame:Raise()
        self.raised = true
    end

    local function createChild()
        return {
            hidden = false,
            Hide = function(self)
                self.hidden = true
            end,
        }
    end

    frame.logFrame = createChild()
    frame.helpFrame = createChild()

    return frame
end

local function testIsEnabledReflectsFeatureFlag()
    local minimap = loadMinimapModule()

    assertEquals(minimap.IsEnabled(), true, "minimap module should stay enabled when its bundled libraries are present")
end

local function testInitializeModelDatabaseDefaultsCreatesMinimapSettings()
    loadMinimapModule()
    local database = {}

    _G.DeathpoolDatabase.GetMinimapSettings(database)

    assertTruthy(type(database.minimap) == "table", "database model should create a minimap settings table")
    assertEquals(database.minimap.hide, false, "database model should leave the minimap icon visible by default")
end

local function testInitializeRegistersOnceAndThenRefreshes()
    local minimap, state = loadMinimapModule()
    local frame = createFrame()
    local firstDatabase = {}
    local secondDatabase = {
        minimap = {
            hide = true,
        },
    }

    minimap.Initialize(frame, firstDatabase)
    assertEquals(#state.registerCalls, 1, "initialization should register the minimap button once")
    assertEquals(#state.refreshCalls, 0, "initialization should not refresh before the button exists")
    assertEquals(#state.showCalls, 1, "initialization should show the minimap icon when it is enabled")
    assertTruthy(state.button ~= nil, "initialization should create the minimap button through LibDBIcon")
    assertEquals(state.lastDataObject.type, "data source", "initialization should expose the broker as a data source for Titan-style displays")
    assertEquals(state.lastDataObject.label, "Deathpool", "initialization should expose the launcher label for broker displays")
    assertEquals(state.lastDataObject.text, "0", "initialization should expose the current score text for broker displays")
    assertEquals(state.lastDataObject.value, "0", "initialization should expose the current score value for broker displays")
    assertEquals(
        state.button.icon.texturePath,
        minimap.ICON_PATH,
        "initialization should use the configured minimap icon asset"
    )

    local secondFrame = createFrame()
    minimap.Initialize(secondFrame, secondDatabase)
    assertEquals(#state.registerCalls, 1, "reinitialization should not register a second minimap button")
    assertEquals(#state.refreshCalls, 1, "reinitialization should refresh the existing minimap button")
end

local function testSetHiddenPersistsAndUpdatesTheIcon()
    local minimap, state = loadMinimapModule()
    local frame = createFrame()
    local database = {}

    minimap.Initialize(frame, database)
    minimap.SetHidden(frame, database, true)
    assertEquals(database.minimap.hide, true, "hiding the minimap icon should persist the hidden state")
    assertEquals(#state.hideCalls, 1, "hiding the minimap icon should call into LibDBIcon")

    minimap.SetHidden(frame, database, false)
    assertEquals(database.minimap.hide, false, "showing the minimap icon should persist the visible state")
    assertEquals(#state.showCalls, 2, "showing the minimap icon should call into LibDBIcon again")
end

local function testRefreshLauncherTextUpdatesBrokerScoreFromDatabase()
    local minimap, state = loadMinimapModule()
    local frame = createFrame()
    local database = {
        totalPoints = 1234,
    }

    minimap.Initialize(frame, database)
    assertEquals(state.lastDataObject.text, "1,234", "initialization should seed the broker text from the current score")
    assertEquals(state.lastDataObject.value, "1,234", "initialization should seed the broker value from the current score")

    database.totalPoints = 12345
    minimap.RefreshLauncherText(frame, database)
    assertEquals(state.lastDataObject.text, "12,345", "refresh should update the broker text from the live database score")
    assertEquals(state.lastDataObject.value, "12,345", "refresh should update the broker value from the live database score")
end

local function testTogglePreservesCollapsedStateWhenOpening()
    local minimap = loadMinimapModule()
    local frame = createFrame({
        shown = false,
        isCollapsed = true,
    })
    local database = {
        hidden = true,
        logWindowShown = true,
    }
    local logStateCalls = {}

    DeathpoolUI = {
        ApplyDesiredLogWindowState = function(targetFrame, targetDatabase)
            logStateCalls[#logStateCalls + 1] = {
                frame = targetFrame,
                database = targetDatabase,
            }
        end,
    }
    frame:SetScript("OnShow", function(self)
        DeathpoolUI.ApplyDesiredLogWindowState(self, database)
    end)

    minimap.Toggle(frame, database)

    assertEquals(frame:IsShown(), true, "opening from the minimap should show the main window")
    assertEquals(database.hidden, false, "opening from the minimap should persist the main window as visible")
    assertEquals(frame.isCollapsed, true, "opening from the minimap should preserve the collapsed main window state")
    assertEquals(#logStateCalls, 1, "opening from the minimap should rely on the frame OnShow handler to restore the log window once")
    assertEquals(frame.raised, true, "opening from the minimap should raise the main window")
end

local function testButtonClickUsesInitializeClosure()
    local minimap, state = loadMinimapModule()
    local frame = createFrame({
        shown = false,
    })
    local database = {
        hidden = true,
    }

    DeathpoolUI = {
        ApplyDesiredLogWindowState = function()
        end,
    }

    minimap.Initialize(frame, database)
    state.button:GetScript("OnClick")()

    assertEquals(frame:IsShown(), true, "minimap button click should show the main window through the registered callback")
    assertEquals(database.hidden, false, "minimap button click should persist the main window as visible")
end

local function testButtonClickTracksMostRecentInitializationTarget()
    local minimap, state = loadMinimapModule()
    local firstFrame = createFrame({
        shown = false,
    })
    local firstDatabase = {
        hidden = true,
    }
    local secondFrame = createFrame({
        shown = false,
    })
    local secondDatabase = {
        hidden = true,
    }

    DeathpoolUI = {
        ApplyDesiredLogWindowState = function()
        end,
    }

    minimap.Initialize(firstFrame, firstDatabase)
    minimap.Initialize(secondFrame, secondDatabase)
    state.button:GetScript("OnClick")()

    assertEquals(firstFrame:IsShown(), false, "reinitialized minimap button should not keep toggling the original frame")
    assertEquals(firstDatabase.hidden, true, "reinitialized minimap button should not mutate the original database")
    assertEquals(secondFrame:IsShown(), true, "reinitialized minimap button should toggle the current frame")
    assertEquals(secondDatabase.hidden, false, "reinitialized minimap button should mutate the current database")
end

local function testTooltipShowsCurrentPredictionAndScore()
    local minimap, state = loadMinimapModule()
    local frame = createFrame()
    local database = {
        totalPoints = 1234,
        lockedPrediction = {
            elements = {
                levelRange = "20-29",
                source = "hogger",
                zone = "elwynn forest",
            },
        },
    }
    local tooltip = {
        lines = {},
    }

    function tooltip:AddLine(text)
        self.lines[#self.lines + 1] = text
    end

    minimap.Initialize(frame, database)
    state.lastDataObject.OnTooltipShow(tooltip)

    assertEquals(tooltip.lines[1], "Hardcore Death Pool", "tooltip should start with the addon name")
    assertEquals(tooltip.lines[2], "Level 20-29, source Hogger, or zone Elwynn Forest.", "tooltip should show the current locked prediction text")
    assertEquals(tooltip.lines[3], "Score: 1,234", "tooltip should show the current running score")
end

local function testToggleHidesAnOpenWindow()
    local minimap = loadMinimapModule()
    local frame = createFrame({
        shown = true,
    })
    local database = {
        hidden = false,
    }

    minimap.Toggle(frame, database)

    assertEquals(frame:IsShown(), false, "clicking the minimap button while open should hide the main window")
    assertEquals(database.hidden, true, "hiding from the minimap should persist the main window as hidden")
end

testIsEnabledReflectsFeatureFlag()
testInitializeModelDatabaseDefaultsCreatesMinimapSettings()
testInitializeRegistersOnceAndThenRefreshes()
testSetHiddenPersistsAndUpdatesTheIcon()
testRefreshLauncherTextUpdatesBrokerScoreFromDatabase()
testTogglePreservesCollapsedStateWhenOpening()
testButtonClickUsesInitializeClosure()
testButtonClickTracksMostRecentInitializationTarget()
testTooltipShowsCurrentPredictionAndScore()
testToggleHidesAnOpenWindow()

suite:finish()

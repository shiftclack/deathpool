local _, ns = ...
---@cast ns DeathpoolNamespace

local DeathpoolUI = ns.DeathpoolUI
local DeathpoolUIAutocomplete = ns.DeathpoolUIAutocomplete
local DeathpoolDatabase = ns.DeathpoolDatabase
local DeathpoolConstants = ns.DeathpoolConstants
local DeathpoolUIDebug = ns.DeathpoolUIDebug
local DeathpoolUIHelp = ns.DeathpoolUIHelp
local DeathpoolUILog = ns.DeathpoolUILog
local DeathpoolUIMain = ns.DeathpoolUIMain or {}
local DeathpoolUIMainCollapsed = ns.DeathpoolUIMainCollapsed
local DeathpoolUIMainPrediction = ns.DeathpoolUIMainPrediction
local DeathpoolUIMainRecentDeaths = ns.DeathpoolUIMainRecentDeaths
local DeathpoolUIMode = ns.DeathpoolUIMode
local DeathpoolUIRefresh = ns.DeathpoolUIRefresh
local DeathpoolUISetup = ns.DeathpoolUISetup
local DeathpoolUITooltip = ns.DeathpoolUITooltip
ns.DeathpoolUIMain = DeathpoolUIMain
local DEMO_RULES = DeathpoolConstants.DEMO
local WAITING_FOR_FIRST_DEATH_MIN_DURATION_SECONDS = DEMO_RULES.waitingForFirstDeathMinDurationSeconds

---@class DeathpoolMainLayout
---@field outsideGutter integer
---@field scrollbarWidth integer
---@field titlebarDragLeftInset integer
---@field titlebarDragRightInset integer
---@field titlebarDragTopInset integer
---@field titlebarDragHeight integer
---@field standardButtonWidth integer
---@field standardButtonHeight integer
---@field compactButtonHeight integer
---@field actionButtonGap integer
---@field modalButtonGap integer
---@field mainWindowHeight integer
---@field expandedWindowWidth integer
---@field footerGutter integer
---@field logWindowHeight integer
---@field logWindowWidth integer
---@field logVisibleRows integer
---@field deathLogRowHeight integer
---@field collapsedWindowWidth integer
---@field collapsedWindowHeight integer
---@field collapsedWindowMinHeight integer
---@field collapsedWindowMaxHeight integer
---@field collapsedLogVisibleRows integer
---@field collapsedLogHeaderY integer
---@field collapsedLogFrameY integer
---@field collapsedLogRowHeight integer
---@field deathLogHeaderY integer
---@field deathLogFrameY integer
---@field deathLogDividerY integer
---@field logVerticalSpacing integer
---@field historyScrollbarGap integer
---@field scrollbarInset integer
---@field historySubtitleY integer
---@field historySubtitleHeaderSpacing integer
---@field historyLogHeaderY integer
---@field historyLogFrameY integer
---@field scoreSummaryY integer
---@field predictionLabelX integer
---@field predictionControlX integer
---@field predictionSectionTop integer
---@field predictionLevelRowY integer
---@field predictionSourceRowY integer
---@field predictionZoneRowY integer
---@field predictionSummaryY integer
---@field predictionSummaryWidth integer
---@field predictionIntroDemoPanelX integer
---@field predictionIntroDemoPanelY integer
---@field predictionIntroDemoPanelWidth integer
---@field predictionIntroDemoPanelHeight integer
---@field predictionButtonY integer

---@class DeathpoolWidget
---@field [string] any

---@class DeathpoolEditBox: DeathpoolWidget

---@class DeathpoolPredictionPayoutPreviewRow
---@field text string

---@alias DeathpoolIntroDemoDisplayLogic DeathpoolMainLogic|DeathpoolRefreshLogic

---@class DeathpoolIntroDemoController
---@field IsActive fun(self: DeathpoolIntroDemoController): boolean
---@field GetDisplayedState fun(self: DeathpoolIntroDemoController, logic: DeathpoolIntroDemoDisplayLogic): DeathpoolDisplayState|nil
---@field Dismiss fun(self: DeathpoolIntroDemoController)
---@field Tick fun(self: DeathpoolIntroDemoController, elapsed: number)

---@class DeathpoolMainLogic
---@field NormalizePredictionValue fun(value: string|nil, anyValue: string|nil): string|nil
---@field GetPredictionElements fun(prediction: DeathpoolPrediction|DeathpoolPredictionElements|nil): DeathpoolPredictionElements|nil
---@field FormatLockedPrediction fun(prediction: DeathpoolPrediction|DeathpoolPredictionElements|nil): string
---@field UpdateDraftPrediction fun(database: DeathpoolCharacterState, prediction: DeathpoolPrediction|DeathpoolPredictionElements): DeathpoolPrediction|nil
---@field ApplyLockedPrediction fun(database: DeathpoolCharacterState, prediction: DeathpoolPrediction|DeathpoolPredictionElements): DeathpoolPrediction|nil
---@field ClearLockedPrediction fun(database: DeathpoolCharacterState)
---@field GetDisplayState fun(database: DeathpoolCharacterState): DeathpoolDisplayState
---@field GetPredictionPayoutPreviewRows fun(prediction: DeathpoolPrediction|DeathpoolPredictionElements|nil): DeathpoolPredictionPayoutPreviewRow[]
---@field ToDisplayText fun(value: string|nil): string|nil

---@class DeathpoolMainFrameShell: DeathpoolRefreshReadyControllerFrame
---@field [string] any
---@field state DeathpoolCharacterState
---@field introDemoController DeathpoolIntroDemoController|nil
---@field isCollapsed boolean|nil
---@field activeEditBox DeathpoolEditBox|nil
---@field suggestionList string[]|nil
---@field suggestionKind string|nil
---@field collapsedWindowStates table<string, boolean>|nil

---@class DeathpoolMainFrame: DeathpoolMainFrameShell
---@field logFrame DeathpoolWidget
---@field helpFrame DeathpoolWidget
---@field githubLinkFrame DeathpoolGitHubLinkFrame
---@field dropdown DeathpoolWidget
---@field gameInfoCallout DeathpoolWidget
---@field sourceEditBox DeathpoolEditBox
---@field zoneEditBox DeathpoolEditBox
---@field lockButton DeathpoolWidget
---@field pauseButton DeathpoolWidget
---@field bottomLogButton DeathpoolWidget
---@field helpButton DeathpoolWidget
---@field minimizeButton DeathpoolWidget
---@field levelRangeButtons DeathpoolWidget[]
---@field collapsedLogHeaders DeathpoolWidget[]
---@field collapsedLogFrame DeathpoolWidget
---@field collapsedScoreDivider DeathpoolWidget
---@field collapsedPointsValue DeathpoolWidget
---@field collapsedPointsLabel DeathpoolWidget
---@field collapsedResizeHandle DeathpoolWidget
---@field recentDeathsFrame DeathpoolWidget
---@field demoModeWatermark DeathpoolWidget
---@field emptyPredictionPrompt DeathpoolWidget
---@field waitingPromptText DeathpoolWidget
---@field waitingPromptDots DeathpoolWidget
---@field waitingPromptHelpText DeathpoolWidget
---@field setupFrame DeathpoolSetupFrame
---@field deathRows DeathpoolWidget[]
---@field totalPointsValue DeathpoolWidget
---@field currentStreakValue DeathpoolWidget
---@field longestStreakValue DeathpoolWidget
---@field introDemoAttractPanel DeathpoolWidget
---@field levelRangeLabel DeathpoolWidget
---@field sourceLabel DeathpoolWidget
---@field zoneLabel DeathpoolWidget
---@field currentPredictionLabel DeathpoolWidget
---@field lockedPredictionValue DeathpoolWidget
---@field selectedLevelRange string
---@field predictionInputsLocked boolean
---@field setupActive boolean
---@field waitingPromptDotCount integer
---@field waitingPromptElapsed number
---@field waitingPromptDisplayDuration number
---@field isWaitingForFirstDeathPromptShown boolean
---@field ApplyPredictionInputState fun(prediction: DeathpoolPrediction|DeathpoolPredictionElements|nil)
---@field RefreshPredictionActionButtonState fun()
---@field SetPredictionInputsLocked fun(locked: boolean)
---@field RefreshAuxiliaryWindowState fun(self: DeathpoolMainFrame)
---@field RefreshIntroDemoVisibility fun(self: DeathpoolMainFrame)
---@field RefreshRecentDeathLogState fun(self: DeathpoolMainFrame)
---@field RefreshCollapsedSummary fun(self: DeathpoolMainFrame)

---@class DeathpoolMainBuildContext
---@field frame DeathpoolMainFrameShell
---@field state DeathpoolCharacterState
---@field logic DeathpoolMainLogic
---@field layout DeathpoolMainLayout
---@field maxRecentDeaths integer
---@field levelRanges string[]
---@field deathLogColumns DeathpoolDeathLogColumn[]
---@field collapsedLogColumns DeathpoolDeathLogColumn[]

---@class DeathpoolMainContext: DeathpoolMainBuildContext
---@field frame DeathpoolMainFrame

---@param ctx DeathpoolMainContext
---@return DeathpoolDisplayState
local function GetMainWindowDisplayState(ctx)
    return DeathpoolUI.GetIntroDemoDisplayedState(ctx.frame, ctx.logic) or ctx.logic.GetDisplayState(DeathpoolUI.GetState(ctx.frame))
end

---@param ctx DeathpoolMainContext
---@return DeathpoolUIModeState
local function ResolveMainWindowMode(ctx)
    return DeathpoolUIMode.Resolve(ctx.frame, GetMainWindowDisplayState(ctx), DeathpoolUI.GetState(ctx.frame))
end

---@param frame DeathpoolMainFrameShell
local function ToggleLogWindow(frame)
    local isLogShown = frame.logFrame:IsShown()
    DeathpoolUI.SetLogWindowShown(frame, DeathpoolUI.GetState(frame), not isLogShown)
end

---@param ctx DeathpoolMainBuildContext
---@param region DeathpoolWidget
---@param lines string[]|fun(): string[]
local function AttachGameInfoCallout(ctx, region, lines)
    local frame = ctx.frame

    DeathpoolUITooltip.AttachGameInfoCallout(region, {
        callout = function()
            return frame.gameInfoCallout
        end,
        owner = function()
            return frame.lockButton
        end,
        relativeTo = function()
            return frame.lockButton
        end,
        point = "BOTTOMRIGHT",
        relativePoint = "TOPRIGHT",
        xOffset = 0,
        yOffset = 10,
        lines = lines,
        shouldShow = function()
            return frame.gameInfoCallout ~= nil
                and frame.isCollapsed ~= true
                and frame:IsShown()
        end,
    })
end

---@param frame DeathpoolMainFrame
---@param elapsed number
local function TickWaitingForFirstDeathPrompt(frame, elapsed)
    local previousDisplayDuration
    local didAdvanceWaitingPromptDots
    local didCompleteMinimumDuration

    if frame.isWaitingForFirstDeathPromptShown ~= true then
        return
    end

    previousDisplayDuration = frame.waitingPromptDisplayDuration
    didAdvanceWaitingPromptDots = false
    frame.waitingPromptElapsed = frame.waitingPromptElapsed + elapsed
    frame.waitingPromptDisplayDuration = previousDisplayDuration + elapsed
    didCompleteMinimumDuration = previousDisplayDuration < WAITING_FOR_FIRST_DEATH_MIN_DURATION_SECONDS
        and frame.waitingPromptDisplayDuration >= WAITING_FOR_FIRST_DEATH_MIN_DURATION_SECONDS

    while frame.waitingPromptElapsed >= 1 do
        frame.waitingPromptElapsed = frame.waitingPromptElapsed - 1
        frame.waitingPromptDotCount = frame.waitingPromptDotCount + 1
        didAdvanceWaitingPromptDots = true
        if frame.waitingPromptDotCount > 3 then
            frame.waitingPromptDotCount = 0
        end
    end

    if didAdvanceWaitingPromptDots or didCompleteMinimumDuration then
        frame:RefreshRecentDeathLogState()
    end
end

---@param frame DeathpoolMainFrameShell
---@param ctx DeathpoolMainBuildContext
local function AttachMainFrameScripts(frame, ctx)
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        DeathpoolUI.SaveWindowPosition(self, DeathpoolUI.GetState(self), self.isCollapsed)
    end)
    frame:SetScript("OnMouseUp", function(self, button)
        if self.isCollapsed == true and button == "LeftButton" then
            DeathpoolUI.SetWindowCollapsed(self, DeathpoolUI.GetState(self), false)
        end
    end)
    frame:SetScript("OnHide", function(self)
        if self.githubLinkFrame then
            self.githubLinkFrame:Hide()
        end
        DeathpoolUITooltip.HideGameInfoCallout(self.gameInfoCallout)
        if self.RefreshIntroDemoVisibility then
            self:RefreshIntroDemoVisibility()
        end
    end)
    frame:SetScript("OnUpdate", function(self, elapsed)
        if self.introDemoController then
            self.introDemoController:Tick(elapsed)
        end

        TickWaitingForFirstDeathPrompt(self, elapsed)
    end)
    frame:SetScript("OnSizeChanged", function(self, width, height)
        local normalizedHeight

        if self.isCollapsed ~= true then
            return
        end

        normalizedHeight = DeathpoolUI.NormalizeCollapsedWindowHeight(height)

        if width ~= ctx.layout.collapsedWindowWidth or normalizedHeight ~= height then
            if self.isAdjustingCollapsedSize then
                return
            end

            self.isAdjustingCollapsedSize = true
            self:SetSize(ctx.layout.collapsedWindowWidth, normalizedHeight)
            self.isAdjustingCollapsedSize = false
            return
        end

        DeathpoolUI.SaveCollapsedWindowHeight(self, DeathpoolUI.GetState(self))
        if self.RefreshCollapsedSummary then
            self:RefreshCollapsedSummary()
        end
    end)
end

---@param ctx DeathpoolMainBuildContext
local function CreateHeaderSection(ctx)
    local frame = ctx.frame

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -5)
    title:SetText("HARDCORE DEATH POOL")

    local minimizeButton = CreateFrame("Button", "DeathpoolMinimizeButton", frame)
    minimizeButton:SetSize(25, 25)
    minimizeButton:SetPoint("RIGHT", frame.CloseButton, "LEFT", 7, 0)
    minimizeButton:SetScript("OnClick", function()
        DeathpoolUI.SetWindowCollapsed(frame, DeathpoolUI.GetState(frame), not frame.isCollapsed)
    end)
    frame.minimizeButton = minimizeButton

    AttachGameInfoCallout(ctx, minimizeButton, {
        "Show the mini log",
    })
end

---@param ctx DeathpoolMainBuildContext
local function CreateScoreSummarySection(ctx)
    local frame = ctx.frame
    local scoreWidth = 60
    local scoreX = ctx.layout.expandedWindowWidth - ctx.layout.outsideGutter - scoreWidth

    local totalPointsValue = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    totalPointsValue:SetPoint("TOPLEFT", frame, "TOPLEFT", scoreX, ctx.layout.scoreSummaryY)
    totalPointsValue:SetWidth(scoreWidth)
    totalPointsValue:SetJustifyH("RIGHT")
    frame.totalPointsValue = totalPointsValue
    DeathpoolUI.RegisterCollapsibleRegion(frame, totalPointsValue)

    local totalPointsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    totalPointsLabel:SetPoint("LEFT", totalPointsValue, "LEFT", -27, 0)
    totalPointsLabel:SetText("Score:")
    DeathpoolUI.RegisterCollapsibleRegion(frame, totalPointsLabel)

    local currentStreakValue = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    currentStreakValue:SetPoint("RIGHT", totalPointsLabel, "LEFT", -44, 0)
    currentStreakValue:SetWidth(28)
    currentStreakValue:SetJustifyH("LEFT")
    frame.currentStreakValue = currentStreakValue
    DeathpoolUI.RegisterCollapsibleRegion(frame, currentStreakValue)

    local currentStreakLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    currentStreakLabel:SetPoint("RIGHT", currentStreakValue, "LEFT", -8, 0)
    currentStreakLabel:SetText("Current streak:")
    DeathpoolUI.RegisterCollapsibleRegion(frame, currentStreakLabel)

    local longestStreakValue = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    longestStreakValue:SetPoint("RIGHT", currentStreakLabel, "LEFT", -44, 0)
    longestStreakValue:SetWidth(28)
    longestStreakValue:SetJustifyH("LEFT")
    frame.longestStreakValue = longestStreakValue
    DeathpoolUI.RegisterCollapsibleRegion(frame, longestStreakValue)

    local longestStreakLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    longestStreakLabel:SetPoint("RIGHT", longestStreakValue, "LEFT", -8, 0)
    longestStreakLabel:SetText("Longest streak:")
    DeathpoolUI.RegisterCollapsibleRegion(frame, longestStreakLabel)
end

---@param ctx DeathpoolMainBuildContext
local function CreateActionButtons(ctx)
    local frame = ctx.frame
    local layout = ctx.layout

    frame.gameInfoCallout = DeathpoolUITooltip.CreateGameInfoCallout("DeathpoolGameInfoCallout", frame)

    local helpButton = CreateFrame("Button", "DeathpoolHelpButton", frame, "GameMenuButtonTemplate")
    helpButton:SetSize(layout.standardButtonWidth, layout.standardButtonHeight)
    helpButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", layout.predictionControlX, layout.predictionButtonY)
    helpButton:SetText("HELP")
    helpButton:SetScript("OnClick", function()
        if not helpButton:IsEnabled() then
            return
        end
        frame.helpFrame:Show()
        frame.helpFrame:Raise()
    end)
    frame.helpButton = helpButton
    DeathpoolUI.RegisterCollapsibleRegion(frame, helpButton)
    AttachGameInfoCallout(ctx, helpButton, {
        "More information",
    })

    local bottomLogButton = CreateFrame("Button", "DeathpoolBottomLogButton", frame, "GameMenuButtonTemplate")
    bottomLogButton:SetSize(100, layout.standardButtonHeight)
    bottomLogButton:SetPoint("LEFT", helpButton, "RIGHT", layout.actionButtonGap, 0)
    bottomLogButton:SetText(DeathpoolUI.LOG_TOGGLE_BUTTON_TEXT)
    bottomLogButton:SetScript("OnClick", function()
        if not bottomLogButton:IsEnabled() then
            return
        end
        ToggleLogWindow(frame)
    end)
    frame.bottomLogButton = bottomLogButton
    DeathpoolUI.RegisterCollapsibleRegion(frame, bottomLogButton)
    AttachGameInfoCallout(ctx, bottomLogButton, {
        "Open the log window",
    })

    local pauseButton = CreateFrame("Button", "DeathpoolPauseButton", frame, "GameMenuButtonTemplate")
    pauseButton:SetSize(layout.standardButtonWidth, layout.standardButtonHeight)
    pauseButton:SetPoint("LEFT", bottomLogButton, "RIGHT", layout.actionButtonGap, 0)
    pauseButton:SetText("PAUSE")
    pauseButton:SetScript("OnClick", function()
        ---@cast frame DeathpoolMainFrame
        DeathpoolUIMainPrediction.OnMainPredictionPauseButtonClicked(frame, ctx.logic)
    end)
    frame.pauseButton = pauseButton
    DeathpoolUI.RegisterCollapsibleRegion(frame, pauseButton)
    AttachGameInfoCallout(ctx, pauseButton, {
        "Pause to change your prediction",
    })

    local lockButton = CreateFrame("Button", "DeathpoolLockButton", frame, "GameMenuButtonTemplate")
    lockButton:SetSize(layout.standardButtonWidth, layout.standardButtonHeight)
    lockButton:SetPoint("LEFT", pauseButton, "RIGHT", layout.actionButtonGap, 0)
    lockButton:SetText("LOCK IN")
    lockButton:SetScript("OnClick", function()
        ---@cast frame DeathpoolMainFrame
        DeathpoolUIMainPrediction.OnMainPredictionLockButtonClicked(frame, ctx.logic, ctx.levelRanges)
    end)
    frame.lockButton = lockButton
    DeathpoolUI.RegisterCollapsibleRegion(frame, lockButton)
    AttachGameInfoCallout(ctx, lockButton, {
        "Begin the game",
    })
end

---@param ctx DeathpoolMainContext
---@param uiMode DeathpoolUIModeState
local function RefreshAuxiliaryWindowState(ctx, uiMode)
    local frame = ctx.frame
    local isDemoShown = DeathpoolUIMode.IsDemoMode(uiMode)
    local hasSeenFirstRun = DeathpoolDatabase.GetHasSeenFirstRun(DeathpoolUI.GetState(frame))

    if isDemoShown or not hasSeenFirstRun then
        frame.bottomLogButton:Disable()
    else
        frame.bottomLogButton:Enable()
    end

    if isDemoShown then
        frame.helpButton:Disable()
    else
        frame.helpButton:Enable()
    end

    if isDemoShown then
        frame.logFrame:Hide()
        frame.helpFrame:Hide()
        if frame.githubLinkFrame then
            frame.githubLinkFrame:Hide()
        end

        frame.collapsedWindowStates.logFrame = false
        -- Starting the demo intentionally closes Help instead of restoring it afterward.
        frame.collapsedWindowStates.helpFrame = false
    elseif DeathpoolUI.ApplyDesiredLogWindowState then
        DeathpoolUI.ApplyDesiredLogWindowState(frame, DeathpoolUI.GetState(frame))
    end
end

---@param frame DeathpoolMainFrame
---@param ctx DeathpoolMainContext
local function RefreshIntroDemoVisibility(frame, ctx)
    local uiMode = ResolveMainWindowMode(ctx)
    local isIntroDemoShown = DeathpoolUIMode.IsDemoMode(uiMode)
    local shouldShowIntroDemo = isIntroDemoShown and not frame.isCollapsed and frame:IsShown()

    RefreshAuxiliaryWindowState(ctx, uiMode)

    if isIntroDemoShown then
        frame.SetPredictionInputsLocked(uiMode.inputsLocked)
    end

    if frame.demoModeWatermark then
        if shouldShowIntroDemo then
            frame.demoModeWatermark:Show()
        else
            frame.demoModeWatermark:Hide()
        end
    end

    if frame.introDemoAttractPanel then
        if shouldShowIntroDemo then
            frame.introDemoAttractPanel:Show()
        else
            frame.introDemoAttractPanel:Hide()
        end
    end
end

---@param ctx DeathpoolMainBuildContext
local function AttachMainFrameMethods(ctx)
    local frame = ctx.frame

    frame.RefreshAuxiliaryWindowState = function(_self)
        ---@cast ctx DeathpoolMainContext
        RefreshAuxiliaryWindowState(ctx, ResolveMainWindowMode(ctx))
    end
    frame.RefreshIntroDemoVisibility = function(self)
        ---@cast ctx DeathpoolMainContext
        ---@cast self DeathpoolMainFrame
        RefreshIntroDemoVisibility(self, ctx)
    end
end

---@param frame DeathpoolMainFrameShell
local function InitializeMainFrameDefaults(frame)
    frame.collapsedWindowStates = {}
    frame.predictionInputsLocked = false
    frame.setupActive = false
    frame.waitingPromptDotCount = 0
    frame.waitingPromptElapsed = 0
    frame.waitingPromptDisplayDuration = 0
    frame.isWaitingForFirstDeathPromptShown = false
end

---@param ctx DeathpoolMainContext
local function InitializeMainFrameState(ctx)
    local frame = ctx.frame

    frame.SetPredictionInputsLocked(DeathpoolDatabase.GetLockedPrediction(DeathpoolUI.GetState(frame)) ~= nil)
    frame.RefreshPredictionActionButtonState()
    frame:RefreshIntroDemoVisibility()
end

---@param state DeathpoolCharacterState
---@param logic DeathpoolMainLogic
---@param maxRecentDeaths integer
---@return DeathpoolMainFrame
---@return DeathpoolRefreshReadyDebugFrame
---@return DeathpoolRefreshReadyHistoryFrame
function DeathpoolUIMain.Initialize(state, logic, maxRecentDeaths)
    ---@type DeathpoolMainLayout
    local layout = DeathpoolUI.LAYOUT
    maxRecentDeaths = maxRecentDeaths or 5

    local frame = CreateFrame("Frame", "DeathpoolFrame", UIParent, "BasicFrameTemplateWithInset")
    ---@cast frame DeathpoolMainFrameShell
    frame.state = state
    frame:SetSize(layout.expandedWindowWidth, layout.mainWindowHeight)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(10)
    frame:SetMovable(true)
    frame:SetResizable(false)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:Hide()
    DeathpoolUI.SetEscapeClosable(frame, true)

    ---@type DeathpoolMainBuildContext
    local ctx = {
        frame = frame,
        state = state,
        logic = logic,
        layout = layout,
        maxRecentDeaths = maxRecentDeaths,
        levelRanges = DeathpoolUI.LEVEL_RANGES,
        deathLogColumns = DeathpoolUI.DEATH_LOG_COLUMNS,
        collapsedLogColumns = DeathpoolUI.COLLAPSED_LOG_COLUMNS,
    }

    AttachMainFrameScripts(frame, ctx)

    local debugWindow = DeathpoolUIDebug.CreateDebugWindow()
    local logWindow = DeathpoolUILog.CreateHistoryWindow(frame)
    local helpWindow = DeathpoolUIHelp.CreateHelpWindow(frame)
    local setupWindow = DeathpoolUISetup.CreateWindow(frame)
    frame.helpFrame = helpWindow
    frame.githubLinkFrame = helpWindow.githubLinkFrame
    frame.logFrame = logWindow
    frame.setupFrame = setupWindow
    frame.dropdown = DeathpoolUIAutocomplete.CreateSuggestionDropdown(frame)

    DeathpoolUIRefresh.AttachRefreshMethods(frame, debugWindow, logWindow, logic)

    CreateHeaderSection(ctx)
    DeathpoolUIMainCollapsed.CreateMainCollapsedSection(
        frame,
        layout,
        maxRecentDeaths,
        DeathpoolUI.COLLAPSED_LOG_COLUMNS
    )

    DeathpoolUIMainRecentDeaths.CreateMainRecentDeathsSection(
        frame,
        layout,
        maxRecentDeaths,
        DeathpoolUI.DEATH_LOG_COLUMNS
    )
    CreateScoreSummarySection(ctx)
    DeathpoolUIMainPrediction.CreateMainPredictionSection(
        frame,
        layout,
        logic,
        DeathpoolUI.LEVEL_RANGES
    )
    CreateActionButtons(ctx)
    DeathpoolUIMainPrediction.CreateMainCurrentPredictionSummarySection(frame, layout, logic)
    DeathpoolUIMainPrediction.AttachMainPredictionMethods(frame, logic)
    AttachMainFrameMethods(ctx)
    InitializeMainFrameDefaults(frame)

    ---@cast frame DeathpoolMainFrame
    ---@cast ctx DeathpoolMainContext
    DeathpoolUIMainPrediction.AttachMainPredictionEditBoxHandlers(frame, logic)
    InitializeMainFrameState(ctx)
    DeathpoolUI.ApplyDesiredLogWindowState(frame, state)

    return frame, debugWindow, logWindow
end

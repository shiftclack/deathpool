local _, ns = ...
---@cast ns DeathpoolNamespace

local DeathpoolUI = ns.DeathpoolUI or {}
local DeathpoolDatabase = ns.DeathpoolDatabase
local DeathpoolUIMode = ns.DeathpoolUIMode
local DeathpoolUISetup = ns.DeathpoolUISetup
ns.DeathpoolUI = DeathpoolUI

---@alias DeathpoolRefreshFontStringMap table<string, table>

---@class DeathpoolRefreshLogic
---@field GetDisplayState fun(database: DeathpoolCharacterState): DeathpoolDisplayState
---@field FormatLockedPrediction fun(prediction: DeathpoolPrediction|DeathpoolPredictionElements|nil): string
---@field FormatMultiplier fun(multiplierValue: number|string|nil): string
---@field FormatPoints fun(points: number|string|nil): string
---@field GetComboDetails fun(prediction: DeathpoolPrediction|DeathpoolPredictionElements|nil, death: DeathpoolDeath|nil, streak: integer|nil): DeathpoolComboDetails
---@field GetStoredDeathComboDetails fun(death: DeathpoolDeath): DeathpoolComboDetails
---@field GetStoredDeathBasePoints fun(death: DeathpoolDeath): integer
---@field GetStoredDeathSameZoneBonusPoints fun(death: DeathpoolDeath): integer
---@field GetStoredDeathMultiplierValue fun(death: DeathpoolDeath): integer
---@field GetStoredDeathAwardedPoints fun(death: DeathpoolDeath): integer

---@class DeathpoolRefreshViewState
---@field history DeathpoolDeathLogDisplayEntry[]
---@field subtitle string
---@field filterButtonText string

---@class DeathpoolRefreshScoreValues
---@field comboDetails DeathpoolComboDetails
---@field basePoints integer|nil
---@field sameZoneBonusPoints integer|nil
---@field totalMultiplier integer|nil
---@field awardedPoints integer|nil

---@class DeathpoolRefreshStateFields
---@field totalPoints integer
---@field currentPredictionStreak integer
---@field longestPredictionStreak integer
---@field lockedPrediction string

---@class DeathpoolRefreshLatestDeathFields
---@field time string|nil
---@field name string|nil
---@field level integer|nil
---@field sourceName string|nil
---@field zone string|nil
---@field sourceMessage string|nil

---@class DeathpoolRefreshDebugParsedDeathFields: DeathpoolRefreshLatestDeathFields
---@field predictionStreak integer|nil

---@class DeathpoolRefreshDebugScoreFields
---@field basePoints integer|nil
---@field comboMultiplier string|nil
---@field streakMultiplier string|nil
---@field multiplier string|nil
---@field awardedPoints integer|nil
---@field pointFormula string|nil
---@field comboDetails string|nil

---@class DeathpoolRefreshDebugDetailFields: DeathpoolRefreshStateFields
---@field time string|nil
---@field name string|nil
---@field level integer|nil
---@field sourceName string|nil
---@field zone string|nil
---@field predictionStreak integer|nil
---@field sourceMessage string|nil
---@field basePoints integer|nil
---@field comboMultiplier string|nil
---@field streakMultiplier string|nil
---@field multiplier string|nil
---@field awardedPoints integer|nil
---@field pointFormula string|nil
---@field comboDetails string|nil

---@class DeathpoolRefreshControllerFrame
---@field displayCache table|nil
---@field introDemoController DeathpoolIntroDemoController|nil
---@field totalPointsValue table|nil
---@field currentStreakValue table|nil
---@field longestStreakValue table|nil
---@field recentDeathsFrame table|nil
---@field emptyPredictionPrompt table|nil
---@field setupFrame DeathpoolSetupFrame|nil
---@field waitingPromptText table|nil
---@field waitingPromptDots table|nil
---@field waitingPromptHelpText table|nil
---@field waitingPromptDotCount integer|nil
---@field waitingPromptElapsed number|nil
---@field waitingPromptDisplayDuration number|nil
---@field isWaitingForFirstDeathPromptShown boolean|nil
---@field setupActive boolean|nil
---@field detailValues DeathpoolRefreshFontStringMap|nil
---@field lockedPredictionValue table|nil
---@field pauseButton table|nil
---@field collapsedLogFrame table|nil
---@field collapsedPointsValue table|nil
---@field GetHeight fun(self: DeathpoolRefreshControllerFrame): number|nil
---@field RefreshIntroDemoVisibility fun(self: DeathpoolRefreshControllerFrame)|nil
---@field ApplyPredictionInputState fun(prediction: DeathpoolPrediction|DeathpoolPredictionElements|nil)
---@field SetPredictionInputsLocked fun(locked: boolean)
---@field RefreshPredictionActionButtonState fun()
---@field RefreshRecentDeathLogState fun(self: DeathpoolRefreshControllerFrame)|nil
---@field RefreshLatestDeathDetails fun(self: DeathpoolRefreshControllerFrame, death: DeathpoolDeath|nil)|nil
---@field RefreshLockedPrediction fun(self: DeathpoolRefreshControllerFrame)|nil
---@field RefreshDeaths fun(self: DeathpoolRefreshControllerFrame)|nil
---@field RefreshCollapsedSummary fun(self: DeathpoolRefreshControllerFrame)|nil
---@field InvalidateLogDisplayCaches fun()|nil

---@class DeathpoolRefreshReadyControllerFrame: DeathpoolRefreshControllerFrame
---@field totalPointsValue table
---@field currentStreakValue table
---@field longestStreakValue table
---@field recentDeathsFrame table
---@field deathRows table[]
---@field emptyPredictionPrompt table
---@field setupFrame DeathpoolSetupFrame
---@field waitingPromptText table
---@field waitingPromptDots table
---@field waitingPromptHelpText table
---@field waitingPromptDotCount integer
---@field waitingPromptElapsed number
---@field waitingPromptDisplayDuration number
---@field isWaitingForFirstDeathPromptShown boolean
---@field setupActive boolean
---@field detailValues DeathpoolRefreshFontStringMap|nil
---@field lockedPredictionValue table
---@field collapsedLogFrame table
---@field collapsedPointsValue table
---@field GetHeight fun(self: DeathpoolRefreshReadyControllerFrame): number
---@field ApplyPredictionInputState fun(prediction: DeathpoolPrediction|DeathpoolPredictionElements|nil)
---@field SetPredictionInputsLocked fun(locked: boolean)
---@field RefreshPredictionActionButtonState fun()
---@field RefreshRecentDeathLogState fun(self: DeathpoolRefreshReadyControllerFrame)
---@field RefreshLatestDeathDetails fun(self: DeathpoolRefreshReadyControllerFrame, death: DeathpoolDeath|nil)
---@field RefreshLockedPrediction fun(self: DeathpoolRefreshReadyControllerFrame)
---@field RefreshDeaths fun(self: DeathpoolRefreshReadyControllerFrame)
---@field RefreshCollapsedSummary fun(self: DeathpoolRefreshReadyControllerFrame)
---@field InvalidateLogDisplayCaches fun()

---@class DeathpoolRefreshDebugFrame
---@field detailValues DeathpoolRefreshFontStringMap|nil
---@field RefreshLatestDeathDetails fun(self: DeathpoolRefreshDebugFrame, death: DeathpoolDeath|nil, state: DeathpoolDisplayState)|nil

---@class DeathpoolRefreshReadyDebugFrame: DeathpoolRefreshDebugFrame
---@field detailValues DeathpoolRefreshFontStringMap
---@field RefreshLatestDeathDetails fun(self: DeathpoolRefreshReadyDebugFrame, death: DeathpoolDeath|nil, state: DeathpoolDisplayState)

---@class DeathpoolRefreshHistoryFrame
---@field rows table[]|nil
---@field logSubtitle table|nil
---@field filterButton table|nil
---@field columnHeaders table<string, table>|nil
---@field showSuccessfulOnly boolean|nil
---@field scrollFrame table
---@field displayCache table|nil
---@field RefreshHistory fun(self: DeathpoolRefreshHistoryFrame)|nil

---@class DeathpoolRefreshReadyHistoryFrame: DeathpoolRefreshHistoryFrame
---@field rows table[]
---@field logSubtitle table
---@field filterButton table
---@field columnHeaders table<string, table>
---@field scrollFrame table
---@field RefreshHistory fun(self: DeathpoolRefreshReadyHistoryFrame)

---@param Deathpool DeathpoolRefreshReadyControllerFrame
---@param DeathpoolDebug DeathpoolRefreshReadyDebugFrame
---@param DeathpoolLog DeathpoolRefreshReadyHistoryFrame
---@param logic DeathpoolRefreshLogic
function DeathpoolUI.AttachRefreshMethods(Deathpool, DeathpoolDebug, DeathpoolLog, logic)
    local deathLogColumns = DeathpoolUI.DEATH_LOG_COLUMNS
    local historyLogColumns = DeathpoolUI.HISTORY_LOG_COLUMNS
    local DeathpoolUIMinimap = ns.DeathpoolUIMinimap
    local displayCache = DeathpoolUI.CreateDeathLogDisplayCache()
    local FIRST_RUN_PROMPT_TEXT = "Make your prediction"
    local WAITING_FOR_FIRST_DEATH_TEXT = "Waiting for first death"
    local WAITING_FOR_FIRST_DEATH_HELP_TEXT = "Click HELP if you are missing deaths"
    ---@return DeathpoolCharacterState
    local function GetState()
        return DeathpoolUI.GetState(Deathpool)
    end

    ---@param viewKey string
    ---@param sourceDeaths DeathpoolDeath[]
    ---@param viewOptions table
    ---@return DeathpoolDeathLogDisplayEntry[]
    local function GetCachedViewEntries(viewKey, sourceDeaths, viewOptions)
        return DeathpoolUI.GetOrderedDeathLogViewEntries(displayCache, viewKey, sourceDeaths, viewOptions)
    end

    ---@param state DeathpoolDisplayState
    ---@return DeathpoolDisplayState
    local function BuildDisplayedState(state)
        return {
            deaths = state.deaths,
            totalPoints = state.totalPoints,
            currentPredictionStreak = state.currentPredictionStreak,
            longestPredictionStreak = state.longestPredictionStreak,
            lockedPrediction = state.lockedPrediction,
            draftPrediction = state.draftPrediction,
            lastPrediction = state.lastPrediction,
        }
    end

    ---@return DeathpoolDisplayState
    local function GetBaseDisplayedState()
        return BuildDisplayedState(logic.GetDisplayState(GetState()))
    end

    ---@param frame DeathpoolRefreshReadyControllerFrame
    ---@return DeathpoolDisplayState|nil
    local function GetDemoDisplayedState(frame)
        local introDemoController = frame.introDemoController
        local displayState = introDemoController and introDemoController:GetDisplayedState(logic) or nil
        if not displayState then
            return nil
        end

        return BuildDisplayedState(displayState)
    end

    ---@param frame DeathpoolRefreshReadyControllerFrame
    ---@return DeathpoolDisplayState
    local function GetDisplayedState(frame)
        return GetDemoDisplayedState(frame) or GetBaseDisplayedState()
    end

    ---@param frame DeathpoolRefreshReadyControllerFrame
    ---@return string
    local function GetWaitingForFirstDeathPromptText(frame)
        return WAITING_FOR_FIRST_DEATH_TEXT .. string.rep(".", frame.waitingPromptDotCount)
    end

    ---@param frame DeathpoolRefreshReadyControllerFrame
    ---@param notificationKind string|nil
    ---@return string|nil
    local function GetRecentDeathPaneNotificationText(frame, notificationKind)
        if notificationKind == "firstRun" then
            return FIRST_RUN_PROMPT_TEXT
        end

        if notificationKind == "waiting" then
            return GetWaitingForFirstDeathPromptText(frame)
        end

        return nil
    end

    ---@param frame DeathpoolRefreshReadyControllerFrame
    ---@param notificationKind string|nil
    ---@param notificationText string|nil
    local function RefreshEmptyPredictionPrompt(frame, notificationKind, notificationText)
        if notificationKind == "waiting" then
            frame.emptyPredictionPrompt:Hide()
        elseif notificationText then
            frame.emptyPredictionPrompt:SetText(notificationText)
            frame.emptyPredictionPrompt:Show()
        else
            frame.emptyPredictionPrompt:Hide()
        end
    end

    ---@param frame DeathpoolRefreshReadyControllerFrame
    ---@param notificationKind string|nil
    local function RefreshWaitingPromptText(frame, notificationKind)
        if notificationKind ~= "waiting" then
            frame.waitingPromptText:Hide()
            frame.waitingPromptDots:Hide()
            return
        end

        frame.waitingPromptText:SetText(WAITING_FOR_FIRST_DEATH_TEXT)
        frame.waitingPromptDots:SetText(string.rep(".", frame.waitingPromptDotCount))
        frame.waitingPromptText:Show()
        frame.waitingPromptDots:Show()
    end

    ---@param frame DeathpoolRefreshReadyControllerFrame
    ---@param showWaitingHelpText boolean
    ---@param notificationKind string|nil
    local function RefreshWaitingPromptHelpText(frame, showWaitingHelpText, notificationKind)
        if notificationKind == "waiting" and showWaitingHelpText then
            frame.waitingPromptHelpText:SetText(WAITING_FOR_FIRST_DEATH_HELP_TEXT)
            frame.waitingPromptHelpText:Show()
            return
        end

        frame.waitingPromptHelpText:Hide()
    end

    ---@param frame DeathpoolRefreshReadyControllerFrame
    ---@param showRows boolean
    local function RefreshRecentDeathRowVisibility(frame, showRows)
        for _, row in ipairs(frame.deathRows) do
            if showRows and row.death ~= nil then
                row:Show()
            else
                row:Hide()
            end
        end
    end

    ---@param frame DeathpoolRefreshReadyControllerFrame
    ---@param uiMode DeathpoolUIModeState
    ---@param notificationText string|nil
    local function RefreshRecentDeathPanePrompt(frame, uiMode, notificationText)
        if DeathpoolUIMode.IsDemoMode(uiMode) or DeathpoolUIMode.HasModal(uiMode) then
            RefreshEmptyPredictionPrompt(frame, nil, nil)
            DeathpoolUISetup.Refresh(frame.setupFrame, frame, not DeathpoolUIMode.IsSetupModal(uiMode))
            RefreshWaitingPromptText(frame, nil)
            RefreshWaitingPromptHelpText(frame, false, nil)
            return
        end

        RefreshEmptyPredictionPrompt(frame, uiMode.prompt, notificationText)
        DeathpoolUISetup.Refresh(frame.setupFrame, frame, false)
        RefreshWaitingPromptText(frame, uiMode.prompt)
        RefreshWaitingPromptHelpText(frame, uiMode.showWaitingHelp, uiMode.prompt)
    end

    ---@param frame DeathpoolRefreshHistoryFrame
    ---@return DeathpoolRefreshViewState
    local function GetHistoryViewState(frame)
        local state = GetState()

        if frame.showSuccessfulOnly == true then
            return {
                history = GetCachedViewEntries(
                    "successfulView",
                    DeathpoolDatabase.GetSuccessfullyPredictedDeaths(state),
                    { sortMode = "successful" }
                ),
                subtitle = DeathpoolUI.HISTORY_SUBTITLE_SUCCESS_ONLY,
                filterButtonText = DeathpoolUI.HISTORY_FILTER_BUTTON_SHOW_ALL,
            }
        end

        return {
            history = GetCachedViewEntries(
                "historyView",
                DeathpoolDatabase.GetDeathHistory(state),
                {}
            ),
            subtitle = DeathpoolUI.HISTORY_SUBTITLE_ALL,
            filterButtonText = DeathpoolUI.HISTORY_FILTER_BUTTON_SHOW_SUCCESS_ONLY,
        }
    end

    ---@param frame DeathpoolRefreshReadyControllerFrame
    ---@param state DeathpoolDisplayState
    local function RefreshScoreSummary(frame, state)
        frame.totalPointsValue:SetText(logic.FormatPoints(state.totalPoints))
        frame.currentStreakValue:SetText(tostring(state.currentPredictionStreak))
        frame.longestStreakValue:SetText(tostring(state.longestPredictionStreak))
        if DeathpoolUIMinimap and DeathpoolUIMinimap.RefreshLauncherText then
            DeathpoolUIMinimap.RefreshLauncherText(frame, GetState())
        end
    end

    ---@param detailValues DeathpoolRefreshFontStringMap
    ---@param detailFields table<string, any>
    local function ApplyDetailValues(detailValues, detailFields)
        for fieldName, fontString in pairs(detailValues) do
            fontString:SetText(DeathpoolUI.GetDeathFieldValue(detailFields[fieldName]))
        end
    end

    ---@param frame DeathpoolRefreshReadyControllerFrame
    local function DisablePredictionActionsForDemo(frame)
        local uiMode = DeathpoolUIMode.Resolve(frame, GetDisplayedState(frame), GetState())
        if not DeathpoolUIMode.IsDemoMode(uiMode) then
            return
        end

        frame.SetPredictionInputsLocked(uiMode.inputsLocked)
        frame.pauseButton:Disable()
    end

    ---@param comboDetails DeathpoolComboDetails
    ---@return string
    local function FormatDebugComboDetails(comboDetails)
        local comboParts = {}

        for _, combo in ipairs(comboDetails.combos) do
            comboParts[#comboParts + 1] = string.format(
                "%s %s",
                tostring(combo.label or "-"),
                tostring(combo.displayMultiplier or logic.FormatMultiplier(combo.multiplier))
            )
        end

        if #comboParts <= 0 then
            return comboDetails.displayComboSum
        end

        return table.concat(comboParts, " / ")
    end

    ---@return DeathpoolDisplayState
    ---@return DeathpoolDeath|nil
    local function GetLiveDebugSnapshot()
        local displayState = GetBaseDisplayedState()
        local deaths = displayState.deaths
        return displayState, deaths[#deaths]
    end

    ---@param state DeathpoolDisplayState
    ---@return DeathpoolRefreshStateFields
    local function GetDebugStateFields(state)
        return {
            totalPoints = state.totalPoints,
            currentPredictionStreak = state.currentPredictionStreak,
            longestPredictionStreak = state.longestPredictionStreak,
            lockedPrediction = logic.FormatLockedPrediction(state.lockedPrediction),
        }
    end

    ---@param death DeathpoolDeath|nil
    ---@return DeathpoolRefreshDebugParsedDeathFields
    local function GetDebugParsedDeathFields(death)
        local deathFields = death or {}

        return {
            time = death and DeathpoolUI.GetStoredDeathTime(death),
            name = deathFields.name,
            level = deathFields.level,
            sourceName = deathFields.sourceName,
            zone = deathFields.zone,
            predictionStreak = deathFields.predictionStreak,
            sourceMessage = deathFields.sourceMessage,
        }
    end

    ---@param death DeathpoolDeath|nil
    ---@return DeathpoolRefreshScoreValues
    local function GetDebugScoreValues(death)
        return {
            comboDetails = death and logic.GetStoredDeathComboDetails(death) or logic.GetComboDetails(nil, nil, 0),
            basePoints = death and logic.GetStoredDeathBasePoints(death) or nil,
            sameZoneBonusPoints = death and logic.GetStoredDeathSameZoneBonusPoints(death) or nil,
            totalMultiplier = death and logic.GetStoredDeathMultiplierValue(death) or nil,
            awardedPoints = death and logic.GetStoredDeathAwardedPoints(death) or nil,
        }
    end

    ---@param death DeathpoolDeath|nil
    ---@param scoreValues DeathpoolRefreshScoreValues
    ---@return string|nil
    local function GetDebugPointFormula(death, scoreValues)
        if not death then
            return nil
        end

        local leftHandPoints = (scoreValues.basePoints or 0) + (scoreValues.sameZoneBonusPoints or 0)
        return string.format(
            "%d x%d = %d",
            leftHandPoints,
            scoreValues.totalMultiplier or 0,
            scoreValues.awardedPoints or 0
        )
    end

    ---@param death DeathpoolDeath|nil
    ---@return DeathpoolRefreshDebugScoreFields
    local function GetDebugScoreFields(death)
        local scoreValues = GetDebugScoreValues(death)
        local comboDetails = scoreValues.comboDetails

        return {
            basePoints = scoreValues.basePoints,
            comboMultiplier = comboDetails and logic.FormatMultiplier(comboDetails.comboMultiplier) or nil,
            streakMultiplier = comboDetails and logic.FormatMultiplier(comboDetails.streakMultiplier) or nil,
            multiplier = comboDetails and comboDetails.displayComboSum or nil,
            awardedPoints = scoreValues.awardedPoints,
            pointFormula = GetDebugPointFormula(death, scoreValues),
            comboDetails = FormatDebugComboDetails(comboDetails),
        }
    end

    ---@param death DeathpoolDeath|nil
    ---@param state DeathpoolDisplayState
    ---@return DeathpoolRefreshDebugDetailFields
    local function GetDebugDetailFields(death, state)
        local stateFields = GetDebugStateFields(state)
        local parsedDeathFields = GetDebugParsedDeathFields(death)
        local scoreFields = GetDebugScoreFields(death)

        return {
            totalPoints = stateFields.totalPoints,
            currentPredictionStreak = stateFields.currentPredictionStreak,
            longestPredictionStreak = stateFields.longestPredictionStreak,
            lockedPrediction = stateFields.lockedPrediction,
            time = parsedDeathFields.time,
            name = parsedDeathFields.name,
            level = parsedDeathFields.level,
            sourceName = parsedDeathFields.sourceName,
            zone = parsedDeathFields.zone,
            predictionStreak = parsedDeathFields.predictionStreak,
            sourceMessage = parsedDeathFields.sourceMessage,
            basePoints = scoreFields.basePoints,
            comboMultiplier = scoreFields.comboMultiplier,
            streakMultiplier = scoreFields.streakMultiplier,
            multiplier = scoreFields.multiplier,
            awardedPoints = scoreFields.awardedPoints,
            pointFormula = scoreFields.pointFormula,
            comboDetails = scoreFields.comboDetails,
        }
    end

    ---@param self DeathpoolRefreshReadyControllerFrame
    function Deathpool:RefreshRecentDeathLogState()
        local state = GetDisplayedState(self)
        local deaths = state.deaths
        local uiMode = DeathpoolUIMode.Resolve(self, state, GetState())
        local recentEntries = GetCachedViewEntries("recentView", deaths, {})
        local wasWaitingForFirstDeathPromptShown = self.isWaitingForFirstDeathPromptShown == true
        local recentDeathPaneNotificationKind = uiMode.prompt
        local recentDeathPaneNotificationText = GetRecentDeathPaneNotificationText(self, recentDeathPaneNotificationKind)

        self.isWaitingForFirstDeathPromptShown = recentDeathPaneNotificationKind == "waiting"
        if self.isWaitingForFirstDeathPromptShown then
            if not wasWaitingForFirstDeathPromptShown then
                self.waitingPromptDotCount = 0
                self.waitingPromptElapsed = 0
                self.waitingPromptDisplayDuration = 0
            end
        else
            self.waitingPromptDotCount = 0
            self.waitingPromptElapsed = 0
            self.waitingPromptDisplayDuration = 0
        end

        DeathpoolUI.RefreshDeathLogRows(self.recentDeathsFrame, recentEntries, {
            columns = deathLogColumns,
            reverseOrder = false,
        })
        RefreshRecentDeathRowVisibility(self, uiMode.showRecentDeathRows)

        RefreshRecentDeathPanePrompt(self, uiMode, recentDeathPaneNotificationText)
        self.RefreshPredictionActionButtonState()
    end

    ---@param self DeathpoolRefreshReadyControllerFrame
    function Deathpool:RefreshDeaths()
        local state = GetDisplayedState(self)
        local deaths = state.deaths

        self:RefreshRecentDeathLogState()

        RefreshScoreSummary(self, state)
        self:RefreshLatestDeathDetails(deaths[#deaths])
        local debugState, latestDeath = GetLiveDebugSnapshot()
        DeathpoolDebug:RefreshLatestDeathDetails(latestDeath, debugState)
        if self.RefreshIntroDemoVisibility then
            self:RefreshIntroDemoVisibility()
        end
        DeathpoolLog:RefreshHistory()
    end

    ---@param self DeathpoolRefreshReadyControllerFrame
    ---@param death DeathpoolDeath|nil
    function Deathpool:RefreshLatestDeathDetails(death)
        if not self.detailValues then
            return
        end

        ---@type DeathpoolRefreshLatestDeathFields
        local detailFields = {
            time = death and DeathpoolUI.GetStoredDeathTime(death),
            name = death and death.name,
            level = death and death.level,
            sourceName = death and death.sourceName,
            zone = death and death.zone,
            sourceMessage = death and death.sourceMessage,
        }

        ApplyDetailValues(self.detailValues, detailFields)
    end

    ---@param self DeathpoolRefreshReadyControllerFrame
    function Deathpool:RefreshLockedPrediction()
        local state = GetDisplayedState(self)
        local lockedPrediction = state.lockedPrediction
        local inputPrediction = lockedPrediction or state.draftPrediction or state.lastPrediction
        local uiMode = DeathpoolUIMode.Resolve(self, state, GetState())
        self.lockedPredictionValue:SetText(logic.FormatLockedPrediction(lockedPrediction))

        self.ApplyPredictionInputState(inputPrediction)

        DeathpoolUI.HideDropdown(self)

        self.SetPredictionInputsLocked(uiMode.inputsLocked)

        self.RefreshPredictionActionButtonState()
        self:RefreshRecentDeathLogState()
        DisablePredictionActionsForDemo(self)

        local debugState, latestDeath = GetLiveDebugSnapshot()
        DeathpoolDebug:RefreshLatestDeathDetails(latestDeath, debugState)
    end

    ---@param self DeathpoolRefreshReadyControllerFrame
    function Deathpool:RefreshCollapsedSummary()
        local state = GetDisplayedState(self)
        local deaths = state.deaths
        local recentEntries = GetCachedViewEntries("recentView", deaths, {})
        local visibleRowCount = DeathpoolUI.GetCollapsedVisibleRowCount(self:GetHeight())
        local offset = math.max(#deaths - visibleRowCount, 0)

        DeathpoolUI.RefreshDeathLogRows(self.collapsedLogFrame, recentEntries, {
            columns = DeathpoolUI.COLLAPSED_LOG_COLUMNS,
            offset = offset,
            reverseOrder = false,
            maxRows = visibleRowCount,
        })

        self.collapsedPointsValue:SetText(logic.FormatPoints(state.totalPoints))
    end

    ---@param self DeathpoolRefreshReadyDebugFrame
    ---@param death DeathpoolDeath|nil
    ---@param state DeathpoolDisplayState
    function DeathpoolDebug:RefreshLatestDeathDetails(death, state)
        ApplyDetailValues(self.detailValues, GetDebugDetailFields(death, state))
    end

    ---@param self DeathpoolRefreshReadyHistoryFrame
    function DeathpoolLog:RefreshHistory()
        local viewState = GetHistoryViewState(self)
        local history = viewState.history
        self.logSubtitle:SetText(viewState.subtitle)
        self.filterButton:SetText(viewState.filterButtonText)
        if self.columnHeaders.time then
            self.columnHeaders.time:SetText(
                self.showSuccessfulOnly == true and DeathpoolUI.HISTORY_SUCCESS_RANK_LABEL or "Time"
            )
        end
        local totalHistory = #history

        FauxScrollFrame_Update(
            self.scrollFrame,
            totalHistory,
            #self.rows,
            DeathpoolUI.LAYOUT.deathLogRowHeight
        )

        local offset = FauxScrollFrame_GetOffset(self.scrollFrame)
        DeathpoolUI.RefreshDeathLogRows(self, history, {
            columns = historyLogColumns,
            offset = offset,
            reverseOrder = true,
            columnContext = {
                showRank = self.showSuccessfulOnly == true,
            },
        })
    end

    function Deathpool.InvalidateLogDisplayCaches()
        DeathpoolUI.InvalidateDeathLogDisplayCache(displayCache)
    end

    DeathpoolLog.displayCache = displayCache
    Deathpool.displayCache = displayCache
end

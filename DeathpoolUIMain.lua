local DeathpoolUI = _G.DeathpoolUI or {}
local DeathpoolDatabase = _G.DeathpoolDatabase
local DeathpoolDebug = _G.DeathpoolDebug
local DeathpoolConstants = _G.DeathpoolConstants
local DeathpoolUIMode = _G.DeathpoolUIMode
local DeathpoolUISetup = _G.DeathpoolUISetup
local SCORE_RULES = DeathpoolConstants.SCORING
local DEMO_RULES = DeathpoolConstants.DEMO
local EMPTY_PREDICTION_PROMPT_TEXT = "Make your prediction"
local WAITING_FOR_FIRST_DEATH_MIN_DURATION_SECONDS = DEMO_RULES.waitingForFirstDeathMinDurationSeconds

---@class DeathpoolMainLayout
---@field mainWindowHeight integer
---@field expandedWindowWidth integer
---@field logWindowHeight integer
---@field logWindowWidth integer
---@field logVisibleRows integer
---@field collapsedWindowWidth integer
---@field collapsedWindowHeight integer
---@field collapsedWindowMinHeight integer
---@field collapsedWindowMaxHeight integer
---@field collapsedLogVisibleRows integer
---@field collapsedLogRowHeight integer
---@field deathLogHeaderY integer
---@field deathLogFrameY integer
---@field deathLogDividerY integer
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

local function DebugUI(...)
    DeathpoolDebug.Log(...)
end

---@param frame DeathpoolMainFrameShell
---@return DeathpoolCharacterState
local function GetState(frame)
    return DeathpoolUI.GetState(frame)
end

---@param frame DeathpoolMainFrameShell
---@return DeathpoolIntroDemoController|nil
local function GetIntroDemoController(frame)
    return frame.introDemoController
end

---@param frame DeathpoolMainFrameShell
---@return boolean
local function IsIntroDemoActive(frame)
    local introDemoController = GetIntroDemoController(frame)
    return introDemoController ~= nil and introDemoController:IsActive() == true
end

---@param frame DeathpoolMainFrameShell
---@param logic DeathpoolMainLogic
---@return DeathpoolDisplayState|nil
local function GetIntroDemoDisplayedState(frame, logic)
    local introDemoController = GetIntroDemoController(frame)
    if introDemoController then
        return introDemoController:GetDisplayedState(logic)
    end

    return nil
end

---@param points number
---@return string
local function FormatPointCallout(points)
    local awardedPoints = points or 0

    if awardedPoints == 1 then
        return "1 point"
    end

    return tostring(awardedPoints) .. " points"
end

---@param ctx DeathpoolMainContext
---@return DeathpoolPredictionElements
local function BuildPredictionElements(ctx)
    local frame = ctx.frame
    local logic = ctx.logic
    local trimText = DeathpoolUI.TrimText

    return {
        levelRange = DeathpoolUI.NormalizeLevelRangeValue(frame.selectedLevelRange),
        source = logic.NormalizePredictionValue(trimText(frame.sourceEditBox:GetText())),
        zone = logic.NormalizePredictionValue(trimText(frame.zoneEditBox:GetText())),
    }
end

---@param ctx DeathpoolMainContext
---@return boolean
local function HasAnyPredictionSelected(ctx)
    local elements = BuildPredictionElements(ctx)
    return elements.levelRange ~= nil or elements.source ~= nil or elements.zone ~= nil
end

---@param ctx DeathpoolMainContext
---@return DeathpoolPrediction
local function BuildLockedPrediction(ctx)
    return {
        elements = BuildPredictionElements(ctx),
        lockedAt = time(),
    }
end

---@param ctx DeathpoolMainContext
---@return DeathpoolPrediction
local function BuildDraftPrediction(ctx)
    return {
        elements = BuildPredictionElements(ctx),
    }
end

---@param ctx DeathpoolMainContext
---@return DeathpoolPrediction|nil
local function UpdateDraftPrediction(ctx)
    local frame = ctx.frame

    if frame.predictionInputsLocked then
        return nil
    end

    return ctx.logic.UpdateDraftPrediction(GetState(frame), BuildDraftPrediction(ctx))
end

---@param ctx DeathpoolMainContext
---@param prediction DeathpoolPrediction|DeathpoolPredictionElements|nil
local function ApplyPredictionInputState(ctx, prediction)
    DeathpoolUI.ApplyPredictionInputState(ctx.frame, ctx.logic, prediction)
end

---@param ctx DeathpoolMainContext
---@param locked boolean
local function SetPredictionInputsLocked(ctx, locked)
    DeathpoolUI.ApplyPredictionInputLockState(ctx.frame, locked)
end

---@param ctx DeathpoolMainContext
---@return DeathpoolDisplayState
local function GetMainWindowDisplayState(ctx)
    return GetIntroDemoDisplayedState(ctx.frame, ctx.logic) or ctx.logic.GetDisplayState(GetState(ctx.frame))
end

---@param ctx DeathpoolMainContext
---@return DeathpoolUIModeState
local function ResolveMainWindowMode(ctx)
    return DeathpoolUIMode.Resolve(ctx.frame, GetMainWindowDisplayState(ctx), GetState(ctx.frame))
end

---@param ctx DeathpoolMainContext
local function RefreshActionButtonState(ctx)
    local frame = ctx.frame
    local uiMode = ResolveMainWindowMode(ctx)

    if uiMode.mainBlocked then
        frame.lockButton:Disable()
        frame.pauseButton:Disable()
        return
    end

    if DeathpoolUIMode.IsDemoMode(uiMode) then
        frame.lockButton:Enable()
        frame.pauseButton:Disable()
        return
    end

    local hasLockedPrediction = DeathpoolDatabase.GetLockedPrediction(GetState(frame)) ~= nil

    if hasLockedPrediction then
        frame.lockButton:Disable()
    elseif HasAnyPredictionSelected(ctx) then
        frame.lockButton:Enable()
    else
        frame.lockButton:Disable()
    end

    if hasLockedPrediction then
        frame.pauseButton:Enable()
    else
        frame.pauseButton:Disable()
    end
end

---@param frame DeathpoolMainFrameShell
local function ToggleLogWindow(frame)
    local isLogShown = frame.logFrame:IsShown()
    DeathpoolUI.SetLogWindowShown(frame, GetState(frame), not isLogShown)
end

---@param ctx DeathpoolMainBuildContext
---@param region DeathpoolWidget
---@param lines string[]|fun(): string[]
local function AttachGameInfoCallout(ctx, region, lines)
    local frame = ctx.frame

    DeathpoolUI.AttachGameInfoCallout(region, {
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
        DeathpoolUI.SaveWindowPosition(self, GetState(self), self.isCollapsed)
    end)
    frame:SetScript("OnMouseUp", function(self, button)
        if self.isCollapsed == true and button == "LeftButton" then
            DeathpoolUI.SetWindowCollapsed(self, GetState(self), false)
        end
    end)
    frame:SetScript("OnHide", function(self)
        DeathpoolUI.HideGameInfoCallout(self.gameInfoCallout)
        if self.RefreshIntroDemoVisibility then
            self:RefreshIntroDemoVisibility()
        end
    end)
    frame:SetScript("OnUpdate", function(self, elapsed)
        if self.introDemoController and self.introDemoController.Tick then
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

        DeathpoolUI.SaveCollapsedWindowHeight(self, GetState(self))
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
    title:SetText("HARDCORE DEATHPOOL")

    local minimizeButton = CreateFrame("Button", "DeathpoolMinimizeButton", frame)
    minimizeButton:SetSize(25, 25)
    minimizeButton:SetPoint("RIGHT", frame.CloseButton, "LEFT", 7, 0)
    minimizeButton:SetScript("OnClick", function()
        DeathpoolUI.SetWindowCollapsed(frame, GetState(frame), not frame.isCollapsed)
    end)
    frame.minimizeButton = minimizeButton

    AttachGameInfoCallout(ctx, minimizeButton, {
        "Show the mini log",
    })
end

---@param ctx DeathpoolMainBuildContext
local function CreateCollapsedSection(ctx)
    local frame = ctx.frame
    local layout = ctx.layout

    frame.collapsedLogHeaders = {}
    for _, column in ipairs(ctx.collapsedLogColumns) do
        local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        header:SetPoint("TOPLEFT", frame, "TOPLEFT", 18 + column.x, -32)
        header:SetWidth(column.width)
        header:SetJustifyH(column.justifyH or "LEFT")
        header:SetWordWrap(false)
        header:SetNonSpaceWrap(false)
        header:SetText(column.label)
        header:Hide()
        frame.collapsedLogHeaders[#frame.collapsedLogHeaders + 1] = header
        DeathpoolUI.RegisterCollapsedVisibleRegion(frame, header)
    end

    local collapsedLogFrame = CreateFrame("Frame", nil, frame)
    collapsedLogFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -48)
    collapsedLogFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 34)
    collapsedLogFrame:Hide()
    frame.collapsedLogFrame = collapsedLogFrame
    DeathpoolUI.RegisterCollapsedVisibleRegion(frame, collapsedLogFrame)
    DeathpoolUI.CreateDeathLogList(collapsedLogFrame, {
        columns = ctx.collapsedLogColumns,
        rowCount = math.min(ctx.maxRecentDeaths, layout.collapsedLogVisibleRows),
        rowHeight = layout.collapsedLogRowHeight,
        rowLeft = 0,
        rowTop = 0,
        rowRight = 0,
        tooltipOptions = DeathpoolUI.COLLAPSED_LOG_TOOLTIP_OPTIONS,
    })

    for _, row in ipairs(collapsedLogFrame.rows) do
        row:Hide()
        row:SetScript("OnMouseUp", function(_, button)
            if frame.isCollapsed == true and button == "LeftButton" then
                DeathpoolUI.SetWindowCollapsed(frame, GetState(frame), false)
            end
        end)
        DeathpoolUI.RegisterCollapsedVisibleRegion(frame, row)
    end

    local collapsedScoreDivider = frame:CreateTexture(nil, "ARTWORK")
    collapsedScoreDivider:SetColorTexture(1, 0.82, 0, 0.45)
    collapsedScoreDivider:SetSize(314, 1)
    collapsedScoreDivider:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 30)
    collapsedScoreDivider:Hide()
    frame.collapsedScoreDivider = collapsedScoreDivider
    DeathpoolUI.RegisterCollapsedVisibleRegion(frame, collapsedScoreDivider)

    local collapsedPointsValue = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    collapsedPointsValue:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 16)
    collapsedPointsValue:SetWidth(60)
    collapsedPointsValue:SetJustifyH("RIGHT")
    collapsedPointsValue:Hide()
    frame.collapsedPointsValue = collapsedPointsValue
    DeathpoolUI.RegisterCollapsedVisibleRegion(frame, collapsedPointsValue)

    local collapsedPointsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    collapsedPointsLabel:SetPoint("RIGHT", collapsedPointsValue, "LEFT", -6, 0)
    collapsedPointsLabel:SetText("Score:")
    collapsedPointsLabel:Hide()
    frame.collapsedPointsLabel = collapsedPointsLabel
    DeathpoolUI.RegisterCollapsedVisibleRegion(frame, collapsedPointsLabel)

    local collapsedResizeHandle = CreateFrame("Button", nil, frame)
    collapsedResizeHandle:SetSize(16, 16)
    collapsedResizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6)
    collapsedResizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    collapsedResizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    collapsedResizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    collapsedResizeHandle:Hide()
    collapsedResizeHandle:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or frame.isCollapsed ~= true then
            return
        end

        frame:StartSizing("BOTTOMRIGHT")
    end)
    collapsedResizeHandle:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        DeathpoolUI.SaveCollapsedWindowHeight(frame, GetState(frame))
    end)
    frame.collapsedResizeHandle = collapsedResizeHandle
    DeathpoolUI.RegisterCollapsedVisibleRegion(frame, collapsedResizeHandle)
end

---@param ctx DeathpoolMainBuildContext
local function CreateRecentDeathsSection(ctx)
    local frame = ctx.frame
    local layout = ctx.layout

    for _, column in ipairs(ctx.deathLogColumns) do
        local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        header:SetPoint("TOPLEFT", frame, "TOPLEFT", column.x, layout.deathLogHeaderY)
        header:SetWidth(column.width)
        header:SetJustifyH(column.justifyH or "LEFT")
        header:SetWordWrap(false)
        header:SetNonSpaceWrap(false)
        header:SetText(column.label)
        DeathpoolUI.RegisterCollapsibleRegion(frame, header)
    end

    local recentDeathsFrame = CreateFrame("Frame", nil, frame)
    recentDeathsFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, layout.deathLogFrameY)
    recentDeathsFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, layout.deathLogFrameY)
    recentDeathsFrame:SetHeight(ctx.maxRecentDeaths * 20)
    frame.recentDeathsFrame = recentDeathsFrame
    DeathpoolUI.RegisterCollapsibleRegion(frame, recentDeathsFrame)

    local demoModeWatermark = recentDeathsFrame:CreateFontString(nil, "BACKGROUND", "QuestTitleFont")
    demoModeWatermark:SetPoint("CENTER", recentDeathsFrame, "CENTER", 0, 20)
    demoModeWatermark:SetWidth(math.floor(((layout.expandedWindowWidth - 14) * 2) / 3))
    demoModeWatermark:SetJustifyH("CENTER")
    demoModeWatermark:SetJustifyV("MIDDLE")
    demoModeWatermark:SetWordWrap(true)
    demoModeWatermark:SetTextColor(0.5, 0.5, 0.5, 0.1)
    demoModeWatermark:SetText("DEMO MODE")
    demoModeWatermark:Hide()
    recentDeathsFrame.demoModeWatermark = demoModeWatermark
    frame.demoModeWatermark = demoModeWatermark

    local emptyPredictionPrompt = recentDeathsFrame:CreateFontString(nil, "OVERLAY", "QuestTitleFont")
    emptyPredictionPrompt:SetPoint("CENTER", recentDeathsFrame, "CENTER", 0, 20)
    emptyPredictionPrompt:SetWidth(math.floor(((layout.expandedWindowWidth - 14) * 2) / 3))
    emptyPredictionPrompt:SetJustifyH("CENTER")
    emptyPredictionPrompt:SetJustifyV("MIDDLE")
    emptyPredictionPrompt:SetWordWrap(true)
    emptyPredictionPrompt:SetTextColor(1, 0.82, 0, 1)
    emptyPredictionPrompt:SetText(EMPTY_PREDICTION_PROMPT_TEXT)
    emptyPredictionPrompt:Hide()
    recentDeathsFrame.emptyPredictionPrompt = emptyPredictionPrompt
    frame.emptyPredictionPrompt = emptyPredictionPrompt

    local waitingPromptText = recentDeathsFrame:CreateFontString(nil, "OVERLAY", "QuestTitleFont")
    waitingPromptText:SetPoint("CENTER", recentDeathsFrame, "CENTER", 0, 20)
    waitingPromptText:SetJustifyH("CENTER")
    waitingPromptText:SetJustifyV("MIDDLE")
    waitingPromptText:SetWordWrap(false)
    waitingPromptText:SetTextColor(1, 0.82, 0, 1)
    waitingPromptText:Hide()
    recentDeathsFrame.waitingPromptText = waitingPromptText
    frame.waitingPromptText = waitingPromptText

    local waitingPromptDots = recentDeathsFrame:CreateFontString(nil, "OVERLAY", "QuestTitleFont")
    waitingPromptDots:SetPoint("LEFT", waitingPromptText, "RIGHT", 0, 0)
    waitingPromptDots:SetJustifyH("LEFT")
    waitingPromptDots:SetJustifyV("MIDDLE")
    waitingPromptDots:SetWordWrap(false)
    waitingPromptDots:SetTextColor(1, 0.82, 0, 1)
    waitingPromptDots:Hide()
    recentDeathsFrame.waitingPromptDots = waitingPromptDots
    frame.waitingPromptDots = waitingPromptDots

    local waitingPromptHelpText = recentDeathsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    waitingPromptHelpText:SetPoint("TOP", waitingPromptText, "BOTTOM", 0, -6)
    waitingPromptHelpText:SetWidth(math.floor(((layout.expandedWindowWidth - 14) * 2) / 3))
    waitingPromptHelpText:SetJustifyH("CENTER")
    waitingPromptHelpText:SetJustifyV("TOP")
    waitingPromptHelpText:SetWordWrap(true)
    waitingPromptHelpText:SetTextColor(1, 0.82, 0, 1)
    waitingPromptHelpText:Hide()
    recentDeathsFrame.waitingPromptHelpText = waitingPromptHelpText
    frame.waitingPromptHelpText = waitingPromptHelpText

    DeathpoolUI.CreateDeathLogList(recentDeathsFrame, {
        columns = ctx.deathLogColumns,
        rowCount = ctx.maxRecentDeaths,
        rowHeight = 20,
        rowLeft = 0,
        rowTop = 0,
        rowRight = 0,
        tooltipOptions = DeathpoolUI.MAIN_LOG_TOOLTIP_OPTIONS,
    })

    frame.deathRows = recentDeathsFrame.rows
end

---@param ctx DeathpoolMainBuildContext
local function CreateScoreSummarySection(ctx)
    local frame = ctx.frame
    local scoreWidth = 60
    local scoreX = ctx.layout.expandedWindowWidth - 22 - scoreWidth

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

---@param frame DeathpoolMainFrameShell
---@param selectedLevelRange string
local function SelectLevelRange(frame, selectedLevelRange)
    frame.selectedLevelRange = selectedLevelRange
    for _, button in ipairs(frame.levelRangeButtons) do
        if button.levelRangeValue == selectedLevelRange then
            button:Disable()
        else
            button:Enable()
        end
    end
end

---@param ctx DeathpoolMainBuildContext
local function CreateLevelRangeButtons(ctx)
    local frame = ctx.frame
    local layout = ctx.layout

    frame.selectedLevelRange = ctx.levelRanges[1]
    frame.levelRangeButtons = {}

    for index, levelRange in ipairs(ctx.levelRanges) do
        local button = CreateFrame("Button", "DeathpoolLevelRangeButton" .. index, frame, "GameMenuButtonTemplate")
        button:SetSize(64, 24)
        button:SetPoint(
            "TOPLEFT",
            frame,
            "TOPLEFT",
            layout.predictionControlX + ((index - 1) * 74),
            layout.predictionLevelRowY + 8
        )
        button:SetText(levelRange)
        button.levelRangeValue = levelRange
        button:SetScript("OnClick", function(self)
            if frame.predictionInputsLocked then
                return
            end

            SelectLevelRange(frame, self.levelRangeValue)
            ---@cast ctx DeathpoolMainContext
            UpdateDraftPrediction(ctx)
            if frame.RefreshRecentDeathLogState then
                frame:RefreshRecentDeathLogState()
            end
            RefreshActionButtonState(ctx)
        end)
        frame.levelRangeButtons[index] = button
        DeathpoolUI.RegisterCollapsibleRegion(frame, button)
        AttachGameInfoCallout(ctx, button, {
            FormatPointCallout(SCORE_RULES.fixedLevelRangePoints[levelRange]),
        })
    end

    frame.levelRangeButtons[1]:Disable()
end

---@param frame DeathpoolMainFrameShell
---@param name string
---@param pointX number
---@param pointY number
---@return DeathpoolEditBox
local function CreatePredictionEditBox(frame, name, pointX, pointY)
    local editBox = CreateFrame("EditBox", name, frame, "InputBoxTemplate")
    editBox:SetPoint("TOPLEFT", frame, "TOPLEFT", pointX, pointY)
    editBox:SetAutoFocus(false)
    editBox:SetSize(180, 24)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetText("")
    editBox:SetCursorPosition(0)
    return editBox
end

---@param ctx DeathpoolMainBuildContext
local function CreateIntroDemoAttractPanel(ctx)
    local frame = ctx.frame
    local layout = ctx.layout
    local width = layout.predictionIntroDemoPanelWidth
    local height = layout.predictionIntroDemoPanelHeight
    local panel = CreateFrame("Frame", nil, frame)

    panel:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        layout.predictionIntroDemoPanelX,
        layout.predictionIntroDemoPanelY
    )
    panel:SetSize(width, height)
    panel:Hide()

    local text = panel:CreateFontString(nil, "OVERLAY", "QuestTitleFont")
    text:SetPoint("CENTER", panel, "CENTER", 0, 0)
    text:SetWidth(width - 24)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetWordWrap(true)
    text:SetTextColor(1, 0.82, 0, 1)
    text:SetFontObject(GameFontHighlightLarge)
    text:SetText(DeathpoolUI.GetIntroDemoAttractModeText())
    panel.text = text

    frame.introDemoAttractPanel = panel
    DeathpoolUI.RegisterCollapsibleRegion(frame, panel)
end

---@param ctx DeathpoolMainBuildContext
---@return DeathpoolWidget
local function CreatePredictionSection(ctx)
    local frame = ctx.frame
    local layout = ctx.layout
    local addLabel = DeathpoolUI.AddLabel

    local predictionTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    predictionTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", layout.predictionLabelX, layout.predictionSectionTop)
    predictionTitle:SetText("Prediction")
    DeathpoolUI.RegisterCollapsibleRegion(frame, predictionTitle)

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(1, 0.82, 0, 0.45)
    divider:SetSize(layout.expandedWindowWidth - 44, 1)
    divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, layout.deathLogDividerY)
    DeathpoolUI.RegisterCollapsibleRegion(frame, divider)

    local levelRangeLabel = addLabel(
        frame,
        "Level range:",
        "TOPLEFT",
        frame,
        "TOPLEFT",
        layout.predictionLabelX,
        layout.predictionLevelRowY
    )
    DeathpoolUI.RegisterCollapsibleRegion(frame, levelRangeLabel)
    CreateLevelRangeButtons(ctx)

    local sourceLabel = addLabel(
        frame,
        "Source:",
        "TOPLEFT",
        frame,
        "TOPLEFT",
        layout.predictionLabelX,
        layout.predictionSourceRowY
    )
    DeathpoolUI.RegisterCollapsibleRegion(frame, sourceLabel)
    frame.sourceLabel = sourceLabel
    AttachGameInfoCallout(ctx, sourceLabel, {
        FormatPointCallout(SCORE_RULES.fixedElementPoints.source),
    })

    frame.sourceEditBox = CreatePredictionEditBox(
        frame,
        "DeathpoolSourceEditBox",
        layout.predictionControlX + 5,
        layout.predictionSourceRowY + 11
    )
    DeathpoolUI.RegisterCollapsibleRegion(frame, frame.sourceEditBox)
    AttachGameInfoCallout(ctx, frame.sourceEditBox, {
        FormatPointCallout(SCORE_RULES.fixedElementPoints.source),
    })
    CreateIntroDemoAttractPanel(ctx)

    local zoneLabel = addLabel(
        frame,
        "Location:",
        "TOPLEFT",
        frame,
        "TOPLEFT",
        layout.predictionLabelX,
        layout.predictionZoneRowY
    )
    DeathpoolUI.RegisterCollapsibleRegion(frame, zoneLabel)
    frame.zoneLabel = zoneLabel
    AttachGameInfoCallout(ctx, zoneLabel, {
        FormatPointCallout(SCORE_RULES.fixedElementPoints.zone),
    })

    frame.zoneEditBox = CreatePredictionEditBox(
        frame,
        "DeathpoolZoneEditBox",
        layout.predictionControlX + 5,
        layout.predictionZoneRowY + 11
    )
    DeathpoolUI.RegisterCollapsibleRegion(frame, frame.zoneEditBox)
    AttachGameInfoCallout(ctx, frame.zoneEditBox, {
        FormatPointCallout(SCORE_RULES.fixedElementPoints.zone),
    })

    return zoneLabel
end

---@param ctx DeathpoolMainBuildContext
---@return string[]
local function GetCurrentPredictionGameInfoCalloutLines(ctx)
    local displayState
    local prediction
    local lines = {
        "Bonus Multipliers",
    }

    if IsIntroDemoActive(ctx.frame) then
        displayState = GetIntroDemoDisplayedState(ctx.frame, ctx.logic) or ctx.logic.GetDisplayState(GetState(ctx.frame))
    else
        displayState = ctx.logic.GetDisplayState(GetState(ctx.frame))
    end

    prediction = displayState.lockedPrediction or displayState.draftPrediction or displayState.lastPrediction

    for _, row in ipairs(ctx.logic.GetPredictionPayoutPreviewRows(prediction)) do
        lines[#lines + 1] = row.text
    end

    return lines
end

---@param ctx DeathpoolMainBuildContext
---@param zoneLabel DeathpoolWidget
local function CreateCurrentPredictionSummarySection(ctx, zoneLabel)
    local frame = ctx.frame
    local layout = ctx.layout

    local currentPredictionTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    currentPredictionTitle:SetPoint("TOPLEFT", zoneLabel, "TOPLEFT", 0, layout.predictionZoneRowY - layout.predictionSourceRowY)
    currentPredictionTitle:SetText("Current prediction:")
    frame.currentPredictionLabel = currentPredictionTitle
    DeathpoolUI.RegisterCollapsibleRegion(frame, currentPredictionTitle)
    AttachGameInfoCallout(ctx, currentPredictionTitle, function()
        return GetCurrentPredictionGameInfoCalloutLines(ctx)
    end)

    local currentPredictionValue = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    currentPredictionValue:SetPoint("TOPLEFT", currentPredictionTitle, "BOTTOMLEFT", 0, -6)
    currentPredictionValue:SetWidth(layout.predictionSummaryWidth)
    currentPredictionValue:SetJustifyH("LEFT")
    currentPredictionValue:SetJustifyV("TOP")
    currentPredictionValue:SetWordWrap(true)
    currentPredictionValue:SetText(ctx.logic.FormatLockedPrediction(nil))
    frame.lockedPredictionValue = currentPredictionValue
    DeathpoolUI.RegisterCollapsibleRegion(frame, currentPredictionValue)
    AttachGameInfoCallout(ctx, currentPredictionValue, function()
        return GetCurrentPredictionGameInfoCalloutLines(ctx)
    end)
end

---@param ctx DeathpoolMainContext
local function OnLockButtonClicked(ctx)
    local frame = ctx.frame

    if IsIntroDemoActive(frame) then
        if frame.introDemoController and frame.introDemoController.Dismiss then
            frame.introDemoController:Dismiss()
        end
        return
    end

    local trimText = DeathpoolUI.TrimText
    local sourceText = trimText(frame.sourceEditBox:GetText())
    local zoneText = trimText(frame.zoneEditBox:GetText())
    local lockedPrediction = BuildLockedPrediction(ctx)
    ctx.logic.ApplyLockedPrediction(GetState(frame), lockedPrediction)
    DeathpoolDatabase.SetHasSeenFirstRun(GetState(frame), true)
    local lockedElements = ctx.logic.GetPredictionElements(lockedPrediction)
    ---@cast lockedElements DeathpoolPredictionElements

    local prediction = string.format(
        "Prediction locked at %s: levelRange=%s, source=%s, zone=%s",
        date("%H:%M:%S"),
        lockedElements.levelRange or ctx.levelRanges[1],
        sourceText or "-",
        zoneText or "-"
    )
    DebugUI(prediction)
    SetPredictionInputsLocked(ctx, true)
    frame:RefreshLockedPrediction()
    RefreshActionButtonState(ctx)
    frame:RefreshAuxiliaryWindowState()
end

---@param ctx DeathpoolMainContext
local function OnPauseButtonClicked(ctx)
    local frame = ctx.frame
    local preservedSourceText = frame.sourceEditBox:GetText()
    local preservedZoneText = frame.zoneEditBox:GetText()

    ctx.logic.ClearLockedPrediction(GetState(frame))
    DeathpoolUI.HideDropdown(frame)
    SetPredictionInputsLocked(ctx, false)
    frame:RefreshLockedPrediction()
    frame.sourceEditBox:SetText(preservedSourceText or "")
    frame.zoneEditBox:SetText(preservedZoneText or "")
    UpdateDraftPrediction(ctx)
    RefreshActionButtonState(ctx)
end

---@param ctx DeathpoolMainBuildContext
local function CreateActionButtons(ctx)
    local frame = ctx.frame
    local layout = ctx.layout

    local lockButton = CreateFrame("Button", "DeathpoolLockButton", frame, "GameMenuButtonTemplate")
    lockButton:SetSize(120, 28)
    lockButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -24, layout.predictionButtonY)
    lockButton:SetText("LOCK IN")
    lockButton:SetScript("OnClick", function()
        ---@cast ctx DeathpoolMainContext
        OnLockButtonClicked(ctx)
    end)
    frame.lockButton = lockButton
    DeathpoolUI.RegisterCollapsibleRegion(frame, lockButton)
    frame.gameInfoCallout = DeathpoolUI.CreateGameInfoCallout("DeathpoolGameInfoCallout", frame)
    AttachGameInfoCallout(ctx, lockButton, {
        "Begin the game",
    })

    local pauseButton = CreateFrame("Button", "DeathpoolPauseButton", frame, "GameMenuButtonTemplate")
    pauseButton:SetSize(120, 28)
    pauseButton:SetPoint("RIGHT", lockButton, "LEFT", -16, 0)
    pauseButton:SetText("PAUSE")
    pauseButton:SetScript("OnClick", function()
        ---@cast ctx DeathpoolMainContext
        OnPauseButtonClicked(ctx)
    end)
    frame.pauseButton = pauseButton
    DeathpoolUI.RegisterCollapsibleRegion(frame, pauseButton)
    AttachGameInfoCallout(ctx, pauseButton, {
        "Pause to change your prediction",
    })

    local bottomLogButton = CreateFrame("Button", "DeathpoolBottomLogButton", frame, "GameMenuButtonTemplate")
    bottomLogButton:SetSize(100, 28)
    bottomLogButton:SetPoint("RIGHT", pauseButton, "LEFT", -16, 0)
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

    local helpButton = CreateFrame("Button", "DeathpoolHelpButton", frame, "GameMenuButtonTemplate")
    helpButton:SetSize(120, 28)
    helpButton:SetPoint("RIGHT", bottomLogButton, "LEFT", -16, 0)
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
end

---@param ctx DeathpoolMainContext
---@param editBox DeathpoolEditBox
---@param suggestionKind string
local function AttachPredictionEditBoxHandlers(ctx, editBox, suggestionKind)
    local frame = ctx.frame

    ---@param activeEditBox DeathpoolEditBox
    local function SetActiveSuggestionInput(activeEditBox)
        frame.activeEditBox = activeEditBox
        frame.suggestionKind = suggestionKind
        if suggestionKind == "source" then
            frame.suggestionList = DeathpoolUI.GetSourceSuggestions(GetState(frame))
        else
            frame.suggestionList = DeathpoolUI.GetZoneSuggestions(GetState(frame))
        end
    end

    editBox:SetScript("OnTextChanged", function(self)
        if frame.predictionInputsLocked then
            return
        end
        SetActiveSuggestionInput(self)
        DeathpoolUI.UpdateSuggestions(frame, self:GetText())
        UpdateDraftPrediction(ctx)
        if frame.RefreshRecentDeathLogState then
            frame:RefreshRecentDeathLogState()
        end
        RefreshActionButtonState(ctx)
    end)

    editBox:SetScript("OnEditFocusGained", function(self)
        if frame.predictionInputsLocked then
            return
        end
        SetActiveSuggestionInput(self)
    end)

    editBox:SetScript("OnEditFocusLost", function()
        DeathpoolUI.HideDropdown(frame)
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        DeathpoolUI.HideDropdown(frame)
    end)
end

---@param ctx DeathpoolMainContext
---@param uiMode DeathpoolUIModeState
local function RefreshAuxiliaryWindowState(ctx, uiMode)
    local frame = ctx.frame
    local isDemoShown = DeathpoolUIMode.IsDemoMode(uiMode)
    local hasSeenFirstRun = DeathpoolDatabase.GetHasSeenFirstRun(GetState(frame))

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

        frame.collapsedWindowStates.logFrame = false
        -- Starting the demo intentionally closes Help instead of restoring it afterward.
        frame.collapsedWindowStates.helpFrame = false
    elseif DeathpoolUI.ApplyDesiredLogWindowState then
        DeathpoolUI.ApplyDesiredLogWindowState(frame, GetState(frame))
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
        SetPredictionInputsLocked(ctx, uiMode.inputsLocked)
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

    frame.ApplyPredictionInputState = function(prediction)
        ---@cast ctx DeathpoolMainContext
        ApplyPredictionInputState(ctx, prediction)
    end
    frame.RefreshPredictionActionButtonState = function()
        ---@cast ctx DeathpoolMainContext
        RefreshActionButtonState(ctx)
    end
    frame.SetPredictionInputsLocked = function(locked)
        ---@cast ctx DeathpoolMainContext
        SetPredictionInputsLocked(ctx, locked)
    end
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

    SetPredictionInputsLocked(ctx, DeathpoolDatabase.GetLockedPrediction(GetState(frame)) ~= nil)
    RefreshActionButtonState(ctx)
    frame:RefreshIntroDemoVisibility()
end

---@param state DeathpoolCharacterState
---@param logic DeathpoolMainLogic
---@param maxRecentDeaths integer
---@return DeathpoolMainFrame
---@return DeathpoolRefreshReadyDebugFrame
---@return DeathpoolRefreshReadyHistoryFrame
function DeathpoolUI.Initialize(state, logic, maxRecentDeaths)
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

    local debugWindow = DeathpoolUI.CreateDebugWindow()
    local logWindow = DeathpoolUI.CreateHistoryWindow(frame)
    local helpWindow = DeathpoolUI.CreateHelpWindow(frame)
    local setupWindow = DeathpoolUISetup.CreateWindow(frame)
    frame.helpFrame = helpWindow
    frame.logFrame = logWindow
    frame.setupFrame = setupWindow
    frame.dropdown = DeathpoolUI.CreateSuggestionDropdown(frame)

    DeathpoolUI.AttachRefreshMethods(frame, debugWindow, logWindow, logic)

    CreateHeaderSection(ctx)
    CreateCollapsedSection(ctx)
    CreateRecentDeathsSection(ctx)
    CreateScoreSummarySection(ctx)
    local zoneLabel = CreatePredictionSection(ctx)
    CreateActionButtons(ctx)
    CreateCurrentPredictionSummarySection(ctx, zoneLabel)
    AttachMainFrameMethods(ctx)
    InitializeMainFrameDefaults(frame)

    ---@cast frame DeathpoolMainFrame
    ---@cast ctx DeathpoolMainContext
    AttachPredictionEditBoxHandlers(ctx, frame.sourceEditBox, "source")
    AttachPredictionEditBoxHandlers(ctx, frame.zoneEditBox, "zone")
    InitializeMainFrameState(ctx)
    DeathpoolUI.ApplyDesiredLogWindowState(frame, state)

    return frame, debugWindow, logWindow
end

local _, ns = ...
---@cast ns DeathpoolNamespace

local DeathpoolUI = ns.DeathpoolUI or {}
local DeathpoolDatabase = ns.DeathpoolDatabase
local DeathpoolDebug = ns.DeathpoolDebug
local DeathpoolConstants = ns.DeathpoolConstants
local DeathpoolUIMode = ns.DeathpoolUIMode
local DeathpoolUISetup = ns.DeathpoolUISetup
ns.DeathpoolUI = DeathpoolUI

local SCORE_RULES = DeathpoolConstants.SCORING
local PREDICTION_CONTROL_HEIGHT = 24
local PREDICTION_EDIT_CONTROL_OFFSET_X = 7
local PREDICTION_LEVEL_CONTROL_ROW_OFFSET_Y = 8
local PREDICTION_EDIT_CONTROL_ROW_OFFSET_Y = 11

local function DebugUI(...)
    DeathpoolDebug.Log(...)
end

---@param frame DeathpoolMainFrameShell
---@return boolean
local function IsIntroDemoActive(frame)
    local introDemoController = frame.introDemoController
    return introDemoController ~= nil and introDemoController:IsActive() == true
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

---@param frame DeathpoolMainFrameShell
---@param region DeathpoolWidget
---@param lines string[]|fun(): string[]
local function AttachPredictionGameInfoCallout(frame, region, lines)
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

---@param frame DeathpoolMainFrameShell
---@param logic DeathpoolMainLogic
---@return DeathpoolPredictionElements
local function BuildPredictionElements(frame, logic)
    local trimText = DeathpoolUI.TrimText

    return {
        levelRange = DeathpoolUI.NormalizeLevelRangeValue(frame.selectedLevelRange),
        source = logic.NormalizePredictionValue(trimText(frame.sourceEditBox:GetText())),
        zone = logic.NormalizePredictionValue(trimText(frame.zoneEditBox:GetText())),
    }
end

---@param frame DeathpoolMainFrameShell
---@param logic DeathpoolMainLogic
---@return boolean
local function HasAnyPredictionSelected(frame, logic)
    local elements = BuildPredictionElements(frame, logic)
    return elements.levelRange ~= nil or elements.source ~= nil or elements.zone ~= nil
end

---@param frame DeathpoolMainFrameShell
---@param logic DeathpoolMainLogic
---@return DeathpoolPrediction
local function BuildLockedPrediction(frame, logic)
    return {
        elements = BuildPredictionElements(frame, logic),
        lockedAt = time(),
    }
end

---@param frame DeathpoolMainFrameShell
---@param logic DeathpoolMainLogic
---@return DeathpoolPrediction
local function BuildDraftPrediction(frame, logic)
    return {
        elements = BuildPredictionElements(frame, logic),
    }
end

---@param frame DeathpoolMainFrameShell
---@param logic DeathpoolMainLogic
---@return DeathpoolPrediction|nil
local function UpdateDraftPrediction(frame, logic)
    if frame.predictionInputsLocked then
        return nil
    end

    return logic.UpdateDraftPrediction(DeathpoolUI.GetState(frame), BuildDraftPrediction(frame, logic))
end

---@param frame DeathpoolMainFrameShell
---@param logic DeathpoolMainLogic
---@return DeathpoolDisplayState
local function GetMainPredictionDisplayState(frame, logic)
    return DeathpoolUI.GetIntroDemoDisplayedState(frame, logic) or logic.GetDisplayState(DeathpoolUI.GetState(frame))
end

---@param frame DeathpoolMainFrameShell
---@param logic DeathpoolMainLogic
---@return DeathpoolUIModeState
local function ResolveMainPredictionMode(frame, logic)
    return DeathpoolUIMode.Resolve(frame, GetMainPredictionDisplayState(frame, logic), DeathpoolUI.GetState(frame))
end

---@param frame DeathpoolMainFrameShell
---@param logic DeathpoolMainLogic
local function RefreshActionButtonState(frame, logic)
    local uiMode = ResolveMainPredictionMode(frame, logic)

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

    local hasLockedPrediction = DeathpoolDatabase.GetLockedPrediction(DeathpoolUI.GetState(frame)) ~= nil

    if hasLockedPrediction then
        frame.lockButton:Disable()
    elseif HasAnyPredictionSelected(frame, logic) then
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

---@param frame DeathpoolMainFrameShell
---@param layout DeathpoolMainLayout
---@param logic DeathpoolMainLogic
---@param levelRanges string[]
local function CreateLevelRangeButtons(frame, layout, logic, levelRanges)
    frame.selectedLevelRange = levelRanges[1]
    frame.levelRangeButtons = {}

    for index, levelRange in ipairs(levelRanges) do
        local button = CreateFrame("Button", "DeathpoolLevelRangeButton" .. index, frame, "GameMenuButtonTemplate")
        button:SetSize(64, layout.compactButtonHeight)
        button:SetPoint(
            "TOPLEFT",
            frame,
            "TOPLEFT",
            layout.predictionControlX + ((index - 1) * 68),
            layout.predictionLevelRowY + PREDICTION_LEVEL_CONTROL_ROW_OFFSET_Y
        )
        button:SetText(levelRange)
        button.levelRangeValue = levelRange
        button:SetScript("OnClick", function(self)
            if frame.predictionInputsLocked then
                return
            end

            SelectLevelRange(frame, self.levelRangeValue)
            UpdateDraftPrediction(frame, logic)
            if frame.RefreshRecentDeathLogState then
                frame:RefreshRecentDeathLogState()
            end
            RefreshActionButtonState(frame, logic)
        end)
        frame.levelRangeButtons[index] = button
        DeathpoolUI.RegisterCollapsibleRegion(frame, button)
        AttachPredictionGameInfoCallout(frame, button, {
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
    editBox:SetSize(180, PREDICTION_CONTROL_HEIGHT)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetText("")
    editBox:SetCursorPosition(0)
    return editBox
end

---@param frame DeathpoolMainFrameShell
---@param layout DeathpoolMainLayout
---@param text string
---@param rowY number
---@param controlRowOffsetY number
---@return DeathpoolWidget
local function CreatePredictionControlLabel(frame, layout, text, rowY, controlRowOffsetY)
    local label = DeathpoolUI.AddLabel(
        frame,
        text,
        "TOPLEFT",
        frame,
        "TOPLEFT",
        layout.predictionLabelX,
        rowY + controlRowOffsetY
    )
    label:SetHeight(PREDICTION_CONTROL_HEIGHT)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    return label
end

---@param frame DeathpoolMainFrameShell
---@param layout DeathpoolMainLayout
local function CreateIntroDemoAttractPanel(frame, layout)
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

---@param frame DeathpoolMainFrameShell
---@param layout DeathpoolMainLayout
---@param logic DeathpoolMainLogic
---@param levelRanges string[]
function DeathpoolUI.CreateMainPredictionSection(frame, layout, logic, levelRanges)
    local predictionTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    predictionTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", layout.predictionLabelX, layout.predictionSectionTop)
    predictionTitle:SetText("Prediction")
    DeathpoolUI.RegisterCollapsibleRegion(frame, predictionTitle)

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(1, 0.82, 0, 0.45)
    divider:SetSize(layout.expandedWindowWidth - (layout.outsideGutter * 2), 1)
    divider:SetPoint("TOPLEFT", frame, "TOPLEFT", layout.outsideGutter, layout.deathLogDividerY)
    DeathpoolUI.RegisterCollapsibleRegion(frame, divider)

    local levelRangeLabel = CreatePredictionControlLabel(
        frame,
        layout,
        "Level range:",
        layout.predictionLevelRowY,
        PREDICTION_LEVEL_CONTROL_ROW_OFFSET_Y
    )
    DeathpoolUI.RegisterCollapsibleRegion(frame, levelRangeLabel)
    frame.levelRangeLabel = levelRangeLabel
    CreateLevelRangeButtons(frame, layout, logic, levelRanges)

    local sourceLabel = CreatePredictionControlLabel(
        frame,
        layout,
        "Source:",
        layout.predictionSourceRowY,
        PREDICTION_EDIT_CONTROL_ROW_OFFSET_Y
    )
    DeathpoolUI.RegisterCollapsibleRegion(frame, sourceLabel)
    frame.sourceLabel = sourceLabel
    AttachPredictionGameInfoCallout(frame, sourceLabel, {
        FormatPointCallout(SCORE_RULES.fixedElementPoints.source),
    })

    frame.sourceEditBox = CreatePredictionEditBox(
        frame,
        "DeathpoolSourceEditBox",
        layout.predictionControlX + PREDICTION_EDIT_CONTROL_OFFSET_X,
        layout.predictionSourceRowY + PREDICTION_EDIT_CONTROL_ROW_OFFSET_Y
    )
    DeathpoolUI.RegisterCollapsibleRegion(frame, frame.sourceEditBox)
    AttachPredictionGameInfoCallout(frame, frame.sourceEditBox, {
        FormatPointCallout(SCORE_RULES.fixedElementPoints.source),
    })
    CreateIntroDemoAttractPanel(frame, layout)

    local zoneLabel = CreatePredictionControlLabel(
        frame,
        layout,
        "Location:",
        layout.predictionZoneRowY,
        PREDICTION_EDIT_CONTROL_ROW_OFFSET_Y
    )
    DeathpoolUI.RegisterCollapsibleRegion(frame, zoneLabel)
    frame.zoneLabel = zoneLabel
    AttachPredictionGameInfoCallout(frame, zoneLabel, {
        FormatPointCallout(SCORE_RULES.fixedElementPoints.zone),
    })

    frame.zoneEditBox = CreatePredictionEditBox(
        frame,
        "DeathpoolZoneEditBox",
        layout.predictionControlX + PREDICTION_EDIT_CONTROL_OFFSET_X,
        layout.predictionZoneRowY + PREDICTION_EDIT_CONTROL_ROW_OFFSET_Y
    )
    DeathpoolUI.RegisterCollapsibleRegion(frame, frame.zoneEditBox)
    AttachPredictionGameInfoCallout(frame, frame.zoneEditBox, {
        FormatPointCallout(SCORE_RULES.fixedElementPoints.zone),
    })
end

---@param frame DeathpoolMainFrameShell
---@param logic DeathpoolMainLogic
---@return string[]
local function GetCurrentPredictionGameInfoCalloutLines(frame, logic)
    local displayState
    local prediction
    local lines = {
        "Bonus Multipliers",
    }

    if IsIntroDemoActive(frame) then
        displayState = DeathpoolUI.GetIntroDemoDisplayedState(frame, logic) or logic.GetDisplayState(DeathpoolUI.GetState(frame))
    else
        displayState = logic.GetDisplayState(DeathpoolUI.GetState(frame))
    end

    prediction = displayState.lockedPrediction or displayState.draftPrediction or displayState.lastPrediction

    for _, row in ipairs(logic.GetPredictionPayoutPreviewRows(prediction)) do
        lines[#lines + 1] = row.text
    end

    return lines
end

---@param frame DeathpoolMainFrameShell
---@param layout DeathpoolMainLayout
---@param logic DeathpoolMainLogic
function DeathpoolUI.CreateMainCurrentPredictionSummarySection(frame, layout, logic)
    local currentPredictionTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    currentPredictionTitle:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        layout.predictionLabelX,
        layout.predictionZoneRowY + (layout.predictionZoneRowY - layout.predictionSourceRowY)
    )
    currentPredictionTitle:SetText("Current prediction:")
    frame.currentPredictionLabel = currentPredictionTitle
    DeathpoolUI.RegisterCollapsibleRegion(frame, currentPredictionTitle)
    AttachPredictionGameInfoCallout(frame, currentPredictionTitle, function()
        return GetCurrentPredictionGameInfoCalloutLines(frame, logic)
    end)

    local currentPredictionValue = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    currentPredictionValue:SetPoint("TOPLEFT", currentPredictionTitle, "BOTTOMLEFT", 0, -6)
    currentPredictionValue:SetWidth(layout.predictionSummaryWidth)
    currentPredictionValue:SetJustifyH("LEFT")
    currentPredictionValue:SetJustifyV("TOP")
    currentPredictionValue:SetWordWrap(true)
    currentPredictionValue:SetText(logic.FormatLockedPrediction(nil))
    frame.lockedPredictionValue = currentPredictionValue
    DeathpoolUI.RegisterCollapsibleRegion(frame, currentPredictionValue)
    AttachPredictionGameInfoCallout(frame, currentPredictionValue, function()
        return GetCurrentPredictionGameInfoCalloutLines(frame, logic)
    end)
end

---@param frame DeathpoolMainFrame
---@param logic DeathpoolMainLogic
---@param levelRanges string[]
function DeathpoolUI.OnMainPredictionLockButtonClicked(frame, logic, levelRanges)
    if IsIntroDemoActive(frame) then
        if frame.introDemoController and frame.introDemoController.Dismiss then
            frame.introDemoController:Dismiss()
        end
        if frame.setupFrame then
            DeathpoolUISetup.ShowOnMainWindowOpen(frame.setupFrame, frame)
        end
        return
    end

    local trimText = DeathpoolUI.TrimText
    local sourceText = trimText(frame.sourceEditBox:GetText())
    local zoneText = trimText(frame.zoneEditBox:GetText())
    local lockedPrediction = BuildLockedPrediction(frame, logic)
    logic.ApplyLockedPrediction(DeathpoolUI.GetState(frame), lockedPrediction)
    DeathpoolDatabase.SetHasSeenFirstRun(DeathpoolUI.GetState(frame), true)
    local lockedElements = logic.GetPredictionElements(lockedPrediction)
    ---@cast lockedElements DeathpoolPredictionElements

    local prediction = string.format(
        "Prediction locked at %s: levelRange=%s, source=%s, zone=%s",
        date("%H:%M:%S"),
        lockedElements.levelRange or levelRanges[1],
        sourceText or "-",
        zoneText or "-"
    )
    DebugUI(prediction)
    DeathpoolUI.ApplyPredictionInputLockState(frame, true)
    frame:RefreshLockedPrediction()
    RefreshActionButtonState(frame, logic)
    frame:RefreshAuxiliaryWindowState()
end

---@param frame DeathpoolMainFrame
---@param logic DeathpoolMainLogic
function DeathpoolUI.OnMainPredictionPauseButtonClicked(frame, logic)
    local preservedSourceText = frame.sourceEditBox:GetText()
    local preservedZoneText = frame.zoneEditBox:GetText()

    logic.ClearLockedPrediction(DeathpoolUI.GetState(frame))
    DeathpoolUI.HideDropdown(frame)
    DeathpoolUI.ApplyPredictionInputLockState(frame, false)
    frame:RefreshLockedPrediction()
    frame.sourceEditBox:SetText(preservedSourceText or "")
    frame.zoneEditBox:SetText(preservedZoneText or "")
    UpdateDraftPrediction(frame, logic)
    RefreshActionButtonState(frame, logic)
end

---@param frame DeathpoolMainFrame
---@param logic DeathpoolMainLogic
---@param editBox DeathpoolEditBox
---@param suggestionKind string
local function AttachPredictionEditBoxHandler(frame, logic, editBox, suggestionKind)
    ---@param activeEditBox DeathpoolEditBox
    local function SetActiveSuggestionInput(activeEditBox)
        frame.activeEditBox = activeEditBox
        frame.suggestionKind = suggestionKind
        if suggestionKind == "source" then
            frame.suggestionList = DeathpoolUI.GetSourceSuggestions(DeathpoolUI.GetState(frame))
        else
            frame.suggestionList = DeathpoolUI.GetZoneSuggestions(DeathpoolUI.GetState(frame))
        end
    end

    ---@param self DeathpoolEditBox
    ---@param userInput boolean
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if frame.predictionInputsLocked then
            return
        end
        SetActiveSuggestionInput(self)
        if userInput then
            DeathpoolUI.UpdateSuggestions(frame, self:GetText())
        else
            DeathpoolUI.HideDropdown(frame)
        end
        UpdateDraftPrediction(frame, logic)
        if frame.RefreshRecentDeathLogState then
            frame:RefreshRecentDeathLogState()
        end
        RefreshActionButtonState(frame, logic)
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

---@param frame DeathpoolMainFrame
---@param logic DeathpoolMainLogic
function DeathpoolUI.AttachMainPredictionEditBoxHandlers(frame, logic)
    AttachPredictionEditBoxHandler(frame, logic, frame.sourceEditBox, "source")
    AttachPredictionEditBoxHandler(frame, logic, frame.zoneEditBox, "zone")
end

---@param frame DeathpoolMainFrameShell
---@param logic DeathpoolMainLogic
function DeathpoolUI.AttachMainPredictionMethods(frame, logic)
    frame.ApplyPredictionInputState = function(prediction)
        DeathpoolUI.ApplyPredictionInputState(frame, logic, prediction)
    end
    frame.RefreshPredictionActionButtonState = function()
        ---@cast frame DeathpoolMainFrame
        RefreshActionButtonState(frame, logic)
    end
    frame.SetPredictionInputsLocked = function(locked)
        DeathpoolUI.ApplyPredictionInputLockState(frame, locked)
    end
end

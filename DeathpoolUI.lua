local DeathpoolUI = _G.DeathpoolUI or {}
local DeathpoolDatabase = _G.DeathpoolDatabase
local ITEM_QUALITY_COLORS = _G.ITEM_QUALITY_COLORS
local DeathpoolConstants = _G.DeathpoolConstants
local DeathpoolLogic = _G.DeathpoolLogic

DeathpoolUI.LOG_TOGGLE_BUTTON_TEXT = "LOG"
DeathpoolUI.HISTORY_SUBTITLE_ALL = "All Predictions"
DeathpoolUI.HISTORY_SUBTITLE_SUCCESS_ONLY = "Successful Predictions"
DeathpoolUI.HISTORY_FILTER_BUTTON_SHOW_ALL = "SHOW ALL"
DeathpoolUI.HISTORY_FILTER_BUTTON_SHOW_SUCCESS_ONLY = "SHOW SUCCESS ONLY"

DeathpoolUI.LEVEL_RANGES = { "None" }
for _, levelRange in ipairs(DeathpoolConstants.SCORING.levelRanges) do
    table.insert(DeathpoolUI.LEVEL_RANGES, levelRange)
end

DeathpoolUI.DEATH_LOG_COLUMNS = {
    { key = "time", label = "Time", x = 22, width = 50, justifyH = "LEFT" },
    { key = "name", label = "Name", x = 82, width = 122, justifyH = "LEFT" },
    { key = "level", label = "Level", x = 212, width = 44 , justifyH = "LEFT"},
    { key = "sourceName", label = "Source", x = 264, width = 136, justifyH = "LEFT" },
    { key = "zone", label = "Location", x = 440, width = 120, justifyH = "LEFT" },
    { key = "awardedPoints", label = "Points", x = 582, width = 46, justifyH = "RIGHT" },
}

DeathpoolUI.HISTORY_LOG_COLUMNS = {
    { key = "time", label = "Time", x = 12, width = 44, justifyH = "LEFT" },
    { key = "name", label = "Name", x = 62, width = 78, justifyH = "LEFT" },
    { key = "level", label = "Level", x = 146, width = 30, justifyH = "LEFT" },
    { key = "awardedPoints", label = "Points", x = 180, width = 32, justifyH = "RIGHT" },
}

DeathpoolUI.HISTORY_SUCCESS_RANK_LABEL = "Rank"

DeathpoolUI.COLLAPSED_LOG_COLUMNS = {
    { key = "name", label = "Name", x = 0, width = 94, justifyH = "LEFT" },
    { key = "level", label = "Lvl", x = 100, width = 26, justifyH = "LEFT" },
    { key = "sourceName", label = "Source", x = 132, width = 88, justifyH = "LEFT" },
    { key = "zone", label = "Location", x = 226, width = 88, justifyH = "LEFT" },
}

DeathpoolUI.COLORS = {
    poorMatchDeath = { 0.62, 0.62, 0.62 },
    commonMatchDeath = { 1.0, 1.0, 1.0 },
    uncommonMatchDeath = { 0.12, 1.0, 0.0 },
    rareMatchDeath = { 0.0, 0.44, 0.87 },
    epicMatchDeath = { 0.64, 0.21, 0.93 },
    predictionInputActive = { 1.0, 1.0, 1.0, 1.0 },
    predictionInputLocked = { 0.5, 0.5, 0.5, 1.0 },
}

DeathpoolUI.LAYOUT = {
    mainWindowHeight = 424,
    expandedWindowWidth = 650,
    logWindowHeight = 424,
    logWindowWidth = 260,
    logVisibleRows = 19,
    collapsedWindowWidth = 350,
    collapsedWindowHeight = 176,
    collapsedWindowMinHeight = 98,
    collapsedWindowMaxHeight = 176,
    collapsedLogVisibleRows = 5,
    collapsedLogRowHeight = 18,
    deathLogHeaderY = -36,
    deathLogFrameY = -56,
    deathLogDividerY = -152,
    scoreSummaryY = -162,
    predictionLabelX = 22,
    predictionControlX = 104,
    predictionSectionTop = -174,
    predictionLevelRowY = -210,
    predictionSourceRowY = -250,
    predictionZoneRowY = -286,
    predictionSummaryY = 88,
    predictionSummaryWidth = 390,
    predictionIntroDemoPanelX = 306,
    predictionIntroDemoPanelY = -239,
    predictionIntroDemoPanelWidth = 314,
    predictionIntroDemoPanelHeight = 58,
    predictionButtonY = 22,
}

---@param height number|nil
---@return number
function DeathpoolUI.NormalizeCollapsedWindowHeight(height)
    local layout = DeathpoolUI.LAYOUT
    local normalizedHeight = height

    if normalizedHeight == nil then
        normalizedHeight = layout.collapsedWindowHeight
    end

    normalizedHeight = tonumber(normalizedHeight) or layout.collapsedWindowHeight
    if normalizedHeight < layout.collapsedWindowMinHeight then
        normalizedHeight = layout.collapsedWindowMinHeight
    end
    if normalizedHeight > layout.collapsedWindowMaxHeight then
        normalizedHeight = layout.collapsedWindowMaxHeight
    end

    return normalizedHeight
end

---@param height number|nil
---@return integer
function DeathpoolUI.GetCollapsedVisibleRowCount(height)
    local layout = DeathpoolUI.LAYOUT
    local normalizedHeight = DeathpoolUI.NormalizeCollapsedWindowHeight(height)
    local visibleRowCount = math.floor(
        ((normalizedHeight - layout.collapsedWindowMinHeight) / layout.collapsedLogRowHeight) + 1
    )

    if visibleRowCount < 1 then
        return 1
    end
    if visibleRowCount > layout.collapsedLogVisibleRows then
        return layout.collapsedLogVisibleRows
    end

    return visibleRowCount
end

---@param frame table
---@param database DeathpoolCharacterState
---@return number|nil
function DeathpoolUI.SaveCollapsedWindowHeight(frame, database)
    if not frame then
        return nil
    end

    local height = DeathpoolUI.NormalizeCollapsedWindowHeight(frame:GetHeight())
    DeathpoolDatabase.SetCollapsedWindowHeight(database, height)
    return height
end

---@param frame table
---@param region table
function DeathpoolUI.RegisterCollapsibleRegion(frame, region)
    frame.collapsibleRegions = frame.collapsibleRegions or {}
    table.insert(frame.collapsibleRegions, region)
end

---@param frame table
---@param region table
function DeathpoolUI.RegisterCollapsedVisibleRegion(frame, region)
    frame.collapsedVisibleRegions = frame.collapsedVisibleRegions or {}
    table.insert(frame.collapsedVisibleRegions, region)
end

---@param frame table|nil
---@param closable boolean|nil
function DeathpoolUI.SetEscapeClosable(frame, closable)
    if not frame then
        return
    end

    local specialFrames = _G.UISpecialFrames
    local frameName
    if frame.GetName then
        frameName = frame:GetName()
    else
        frameName = frame.name
    end
    if type(specialFrames) ~= "table" or not frameName or frameName == "" then
        return
    end

    local existingIndex = nil
    for index, existingName in ipairs(specialFrames) do
        if existingName == frameName then
            existingIndex = index
            break
        end
    end

    if closable == true then
        if existingIndex == nil then
            table.insert(specialFrames, frameName)
        end
        return
    end

    if existingIndex ~= nil then
        table.remove(specialFrames, existingIndex)
    end
end

---@param value any
---@return string
function DeathpoolUI.GetDeathFieldValue(value)
    if value == nil or value == "" then
        return "-"
    end

    return tostring(value)
end

---@param value number|string|nil
---@return string
function DeathpoolUI.FormatNumberWithCommas(value)
    local numberValue = tonumber(value) or 0
    local sign = ""
    local digits = tostring(numberValue)

    if numberValue < 0 then
        sign = "-"
        digits = string.sub(digits, 2)
    end

    local formatted = digits
    while true do
        local updatedValue, replacements = string.gsub(formatted, "^(%d+)(%d%d%d)", "%1,%2")
        formatted = updatedValue
        if replacements == 0 then
            break
        end
    end

    return sign .. formatted
end

---@param value any
---@param allowEmptyValue boolean|nil
---@return string
function DeathpoolUI.GetTooltipFieldValue(value, allowEmptyValue)
    if allowEmptyValue == true and value == "" then
        return ""
    end

    return DeathpoolUI.GetDeathFieldValue(value)
end

---@param multiplierValue number|string|nil
---@return string
function DeathpoolUI.GetMultiplierDisplay(multiplierValue)
    if tonumber(multiplierValue) == 0 then
        return "-"
    end

    return DeathpoolLogic.FormatMultiplier(multiplierValue)
end

---@param parent table
---@param text string
---@param point string
---@param relativeTo table|nil
---@param relativePoint string|nil
---@param x number|nil
---@param y number|nil
---@return table
function DeathpoolUI.AddLabel(parent, text, point, relativeTo, relativePoint, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint(point, relativeTo or parent, relativePoint or point, x or 0, y or 0)
    label:SetText(text)
    return label
end

---@param index integer
---@param fallbackColor number[]
---@return number[]
local function GetItemQualityColor(index, fallbackColor)
    if ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[index] then
        local qualityColor = ITEM_QUALITY_COLORS[index]
        return { qualityColor.r, qualityColor.g, qualityColor.b }
    end

    return fallbackColor
end

---@param points number
---@return number[]
local function GetScoreColor(points)
    local colors = DeathpoolUI.COLORS
    local quality = DeathpoolLogic.GetPointColorQuality(points)

    if quality == 0 then
        return GetItemQualityColor(0, colors.poorMatchDeath)
    end

    if quality == 1 then
        return GetItemQualityColor(1, colors.commonMatchDeath)
    end

    if quality == 2 then
        return GetItemQualityColor(2, colors.uncommonMatchDeath)
    end

    if quality == 3 then
        return GetItemQualityColor(3, colors.rareMatchDeath)
    end

    return GetItemQualityColor(4, colors.epicMatchDeath)
end

---@param value any
---@return string|nil
function DeathpoolUI.TrimText(value)
    if value == nil then
        return nil
    end

    local trimmed = tostring(value):gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then
        return nil
    end

    return trimmed
end

---@param list string[]
---@param value any
function DeathpoolUI.EnsureUniqueValue(list, value)
    local trimmed = DeathpoolUI.TrimText(value)
    if not trimmed then
        return
    end

    local normalizedValue = string.lower(trimmed)
    for _, existingValue in ipairs(list) do
        if string.lower(tostring(existingValue)) == normalizedValue then
            return
        end
    end

    table.insert(list, trimmed)
end

---@param frame table
---@return DeathpoolFrameAnchor|nil
local function GetFrameAnchor(frame)
    if not frame.GetPoint then
        return nil
    end

    local point, _, relativePoint, xOffset, yOffset = frame:GetPoint(1)
    if not point then
        return nil
    end

    return {
        point = point,
        relativePoint = relativePoint,
        x = xOffset or 0,
        y = yOffset or 0,
    }
end

---@param frame table
---@param anchor DeathpoolFrameAnchor
---@return boolean
local function ApplyFrameAnchor(frame, anchor)
    if not anchor.point then
        return false
    end

    frame:ClearAllPoints()
    frame:SetPoint(
        anchor.point,
        UIParent,
        anchor.relativePoint or anchor.point,
        anchor.x or 0,
        anchor.y or 0
    )
    return true
end

---@param frame table
---@return DeathpoolCharacterState
function DeathpoolUI.GetState(frame)
    local currentFrame = frame

    while currentFrame do
        if currentFrame.state then
            return currentFrame.state
        end

        if not currentFrame.GetParent then
            break
        end

        currentFrame = currentFrame:GetParent()
    end

    --- this used to return nil, but now we consider it programmer error
    error("state table is required", 2)
end

---@param frame table|nil
---@param database DeathpoolCharacterState
---@param collapsed boolean|nil
function DeathpoolUI.SaveWindowPosition(frame, database, collapsed)
    if not frame then
        return
    end

    local anchor = GetFrameAnchor(frame)
    if not anchor then
        return
    end

    DeathpoolDatabase.SetWindowPosition(database, collapsed, anchor)
end

---@param frame table
---@param database DeathpoolCharacterState
---@param collapsed boolean
---@return boolean
local function RestoreWindowPosition(frame, database, collapsed)
    local anchor = DeathpoolDatabase.GetWindowPosition(database, collapsed)
    if not anchor or not anchor.point then
        return false
    end

    return ApplyFrameAnchor(frame, anchor)
end

---@param value string|nil
---@return string|nil
function DeathpoolUI.NormalizeLevelRangeValue(value)
    if value == nil or value == "" or value == DeathpoolUI.LEVEL_RANGES[1] then
        return nil
    end

    return value
end

---@param frame table
---@param logic table
---@param prediction DeathpoolPrediction|DeathpoolPredictionElements|nil
function DeathpoolUI.ApplyPredictionInputState(frame, logic, prediction)
    local elements = logic.GetPredictionElements(prediction) or {}
    local selectedLevelRange = DeathpoolUI.NormalizeLevelRangeValue(elements.levelRange) or DeathpoolUI.LEVEL_RANGES[1]

    frame.selectedLevelRange = selectedLevelRange

    if frame.sourceEditBox then
        frame.sourceEditBox:SetText(logic.ToDisplayText(elements.source) or "")
    end

    if frame.zoneEditBox then
        frame.zoneEditBox:SetText(logic.ToDisplayText(elements.zone) or "")
    end
end

---@param frame table
---@return boolean
local function HasActiveIntroDemo(frame)
    local introDemoController = frame.introDemoController
    return introDemoController ~= nil and introDemoController:IsActive() == true
end

---@param frame table
---@param predictionInputsLocked boolean
---@return string
local function GetLockButtonLabel(frame, predictionInputsLocked)
    local isIntroDemoShown = HasActiveIntroDemo(frame)

    if isIntroDemoShown then
        return "START GAME"
    end

    if predictionInputsLocked then
        return "LOCKED IN"
    end

    return "LOCK IN"
end

---@param frame table
---@param locked boolean|nil
function DeathpoolUI.ApplyPredictionInputLockState(frame, locked)
    local predictionInputsLocked = locked == true
    frame.predictionInputsLocked = predictionInputsLocked
    local editBoxColor

    if predictionInputsLocked then
        editBoxColor = DeathpoolUI.COLORS.predictionInputLocked
    else
        editBoxColor = DeathpoolUI.COLORS.predictionInputActive
    end

    if frame.lockButton then
        frame.lockButton:SetText(GetLockButtonLabel(frame, predictionInputsLocked))
    end

    for _, button in ipairs(frame.levelRangeButtons or {}) do
        if predictionInputsLocked then
            if button.levelRangeValue == frame.selectedLevelRange then
                button:Enable()
            else
                button:Disable()
            end
        elseif button.levelRangeValue == frame.selectedLevelRange then
            button:Disable()
        else
            button:Enable()
        end
    end

    if frame.sourceEditBox then
        if predictionInputsLocked then
            frame.sourceEditBox:Disable()
        else
            frame.sourceEditBox:Enable()
        end
        frame.sourceEditBox:SetTextColor(unpack(editBoxColor))
    end

    if frame.zoneEditBox then
        if predictionInputsLocked then
            frame.zoneEditBox:Disable()
        else
            frame.zoneEditBox:Enable()
        end
        frame.zoneEditBox:SetTextColor(unpack(editBoxColor))
    end

    if predictionInputsLocked then
        DeathpoolUI.HideDropdown(frame)
    end
end

---@param death DeathpoolDeath
---@return number[]
function DeathpoolUI.GetDeathRowColor(death)
    return GetScoreColor(DeathpoolLogic.GetStoredDeathAwardedPoints(death))
end

---@param regions table[]|nil
---@param shown boolean|nil
local function SetRegionsShown(regions, shown)
    if not regions then
        return
    end

    for _, region in ipairs(regions) do
        if shown then
            region:Show()
        else
            region:Hide()
        end
    end
end

---@param frame table
local function UpdateCollapseButton(frame)
    if frame.minimizeButton then
        local texturePrefix = frame.isCollapsed and "UI-PlusButton" or "UI-MinusButton"

        frame.minimizeButton:SetNormalTexture("Interface\\Buttons\\" .. texturePrefix .. "-UP")
        frame.minimizeButton:SetPushedTexture("Interface\\Buttons\\" .. texturePrefix .. "-DOWN")
        frame.minimizeButton:SetHighlightTexture("Interface\\Buttons\\" .. texturePrefix .. "-Hilight")
        frame.minimizeButton:SetDisabledTexture("Interface\\Buttons\\" .. texturePrefix .. "-DISABLED")
    end
end

---@param frame table
---@param stateKey string
local function RememberAndHideWindow(frame, stateKey)
    local childFrame = frame[stateKey]
    if not childFrame then
        return
    end

    local childShown = childFrame:IsShown()

    if childShown or frame:IsShown() or frame.collapsedWindowStates[stateKey] == nil then
        frame.collapsedWindowStates[stateKey] = childShown
    end
    childFrame:Hide()
end

---@param frame table
---@param stateKey string
local function RestoreCollapsedWindowState(frame, stateKey)
    local childFrame = frame[stateKey]
    if childFrame and frame.collapsedWindowStates[stateKey] then
        childFrame:Show()
    end

    frame.collapsedWindowStates[stateKey] = false
end

---@param frame table
local function ApplyWindowResizeState(frame)
    local layout = DeathpoolUI.LAYOUT

    if not frame.SetResizable then
        return
    end

    frame:SetResizable(frame.isCollapsed)
    if frame.isCollapsed ~= true then
        return
    end

    if frame.SetMinResize then
        frame:SetMinResize(layout.collapsedWindowWidth, layout.collapsedWindowMinHeight)
    end
    if frame.SetMaxResize then
        frame:SetMaxResize(layout.collapsedWindowWidth, layout.collapsedWindowMaxHeight)
    end
end

---@param frame table
local function ApplyCollapsedChildWindowState(frame)
    if frame.isCollapsed then
        RememberAndHideWindow(frame, "logFrame")
        RememberAndHideWindow(frame, "helpFrame")
        return
    end

    RestoreCollapsedWindowState(frame, "logFrame")
    RestoreCollapsedWindowState(frame, "helpFrame")
end

---@param logFrame table
---@param shouldShow boolean
local function ApplyLogWindowDisplayState(logFrame, shouldShow)
    if shouldShow then
        if logFrame.RefreshHistory then
            logFrame:RefreshHistory()
        end
        logFrame:Show()
        return
    end

    logFrame:Hide()
end

---@param frame table
---@return boolean
local function IsSetupWindowShown(frame)
    return frame.setupFrame ~= nil and frame.setupFrame:IsShown() == true
end

---@param frame table
---@param database DeathpoolCharacterState
---@param collapsed boolean
function DeathpoolUI.SetWindowCollapsed(frame, database, collapsed)
    local layout = DeathpoolUI.LAYOUT

    frame.collapsedWindowStates = frame.collapsedWindowStates or {}
    if frame.isCollapsed ~= nil and frame.isCollapsed ~= (collapsed == true) then
        DeathpoolUI.SaveWindowPosition(frame, database, frame.isCollapsed)
    end
    frame.isCollapsed = collapsed == true
    frame:SetSize(
        frame.isCollapsed and layout.collapsedWindowWidth or layout.expandedWindowWidth,
        frame.isCollapsed
            and DeathpoolUI.NormalizeCollapsedWindowHeight(DeathpoolDatabase.GetCollapsedWindowHeight(database))
            or layout.mainWindowHeight
    )
    ApplyWindowResizeState(frame)
    RestoreWindowPosition(frame, database, frame.isCollapsed)
    SetRegionsShown(frame.collapsibleRegions, not frame.isCollapsed)
    SetRegionsShown(frame.collapsedVisibleRegions, frame.isCollapsed)
    UpdateCollapseButton(frame)
    DeathpoolUI.SetEscapeClosable(frame, not frame.isCollapsed)
    ApplyCollapsedChildWindowState(frame)
    DeathpoolUI.HideGameInfoCallout(frame.gameInfoCallout)

    DeathpoolDatabase.SetCollapsed(database, frame.isCollapsed)

    if frame.RefreshCollapsedSummary then
        frame:RefreshCollapsedSummary()
    end

    if frame.RefreshIntroDemoVisibility and HasActiveIntroDemo(frame) then
        frame:RefreshIntroDemoVisibility()
    elseif frame.demoModeWatermark then
        frame.demoModeWatermark:Hide()
        if frame.introDemoAttractPanel then
            frame.introDemoAttractPanel:Hide()
        end
    end
end

---@param database DeathpoolCharacterState
---@return boolean
function DeathpoolUI.ShouldLogWindowBeShown(database)
    return DeathpoolDatabase.GetLogWindowShown(database)
end

---@param frame table|nil
---@param database DeathpoolCharacterState
---@param shown boolean|nil
function DeathpoolUI.SetLogWindowShown(frame, database, shown)
    if not frame or not frame.logFrame then
        return
    end

    frame.collapsedWindowStates = frame.collapsedWindowStates or {}
    local shouldShow = shown == true
    DeathpoolDatabase.SetLogWindowShown(database, shouldShow)

    if frame.isCollapsed then
        frame.collapsedWindowStates.logFrame = shouldShow
    end

    if IsSetupWindowShown(frame) then
        frame.logFrame:Hide()
        return
    end

    ApplyLogWindowDisplayState(frame.logFrame, shouldShow)
end

---@param frame table|nil
---@param database DeathpoolCharacterState
function DeathpoolUI.ApplyDesiredLogWindowState(frame, database)
    if not frame or not frame.logFrame then
        return
    end

    local shouldShow = DeathpoolUI.ShouldLogWindowBeShown(database)

    frame.collapsedWindowStates = frame.collapsedWindowStates or {}
    frame.collapsedWindowStates.logFrame = shouldShow

    if frame.isCollapsed or not frame:IsShown() or IsSetupWindowShown(frame) then
        frame.logFrame:Hide()
        return
    end

    ApplyLogWindowDisplayState(frame.logFrame, shouldShow)
end

_G.DeathpoolUI = DeathpoolUI

return DeathpoolUI

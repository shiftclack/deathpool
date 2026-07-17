local DeathpoolUI = _G.DeathpoolUI
local DeathpoolDatabase = _G.DeathpoolDatabase

---@class DeathpoolHistoryParentFrame: DeathpoolMainFrameShell
---@field [string] any
---@field frameStrata string|nil

---@class DeathpoolHistoryFrame: DeathpoolRefreshHistoryFrame
---@field [string] any
---@field CloseButton table|nil
---@field dragHandle table
---@field rows table[]
---@field logSubtitle table
---@field filterButton table
---@field columnHeaders table<string, table>
---@field showSuccessfulOnly boolean
---@field scrollFrame table

---@param parentFrame DeathpoolHistoryParentFrame
---@return DeathpoolHistoryFrame
function DeathpoolUI.CreateHistoryWindow(parentFrame)
    ---@type DeathpoolDeathLogColumn[]
    local historyColumns = DeathpoolUI.HISTORY_LOG_COLUMNS
    ---@type DeathpoolMainLayout
    local layout = DeathpoolUI.LAYOUT
    local visibleRows = layout.logVisibleRows
    local rowHeight = layout.deathLogRowHeight
    local rowLeft = layout.outsideGutter
    local headerTop = layout.historyLogHeaderY
    local rowTop = layout.historyLogFrameY
    local filterButtonBottom = layout.footerGutter
    ---@type DeathpoolCharacterState
    local state = DeathpoolUI.GetState(parentFrame)

    local DeathpoolLog = CreateFrame("Frame", "DeathpoolLogFrame", UIParent, "BasicFrameTemplateWithInset")
    ---@cast DeathpoolLog DeathpoolHistoryFrame
    DeathpoolLog:SetSize(layout.logWindowWidth, layout.logWindowHeight)
    DeathpoolLog:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", 12, 0)
    DeathpoolLog:SetFrameStrata(parentFrame.frameStrata or "MEDIUM")
    DeathpoolLog:SetToplevel(true)
    DeathpoolLog:SetMovable(false)
    DeathpoolLog:EnableMouse(true)
    DeathpoolLog:Hide()

    local dragHandle = CreateFrame("Frame", nil, DeathpoolLog)
    dragHandle:SetPoint(
        "TOPLEFT",
        DeathpoolLog,
        "TOPLEFT",
        layout.titlebarDragLeftInset,
        layout.titlebarDragTopInset
    )
    dragHandle:SetPoint(
        "TOPRIGHT",
        DeathpoolLog,
        "TOPRIGHT",
        -layout.titlebarDragRightInset,
        layout.titlebarDragTopInset
    )
    dragHandle:SetHeight(layout.titlebarDragHeight)
    dragHandle:EnableMouse(true)
    dragHandle:RegisterForDrag("LeftButton")
    dragHandle:SetScript("OnDragStart", function()
        parentFrame:StartMoving()
    end)
    dragHandle:SetScript("OnDragStop", function()
        parentFrame:StopMovingOrSizing()
        DeathpoolUI.SaveWindowPosition(parentFrame, state, parentFrame.isCollapsed)
    end)
    DeathpoolLog.dragHandle = dragHandle

    if DeathpoolLog.CloseButton then
        DeathpoolLog.CloseButton:SetScript("OnClick", function()
            DeathpoolUI.SetLogWindowShown(parentFrame, state, false)
        end)
    end

    local logTitle = DeathpoolLog:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    logTitle:SetPoint("TOP", DeathpoolLog, "TOP", 0, -5)
    logTitle:SetText("LOG")

    local logSubtitle = DeathpoolLog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    logSubtitle:SetPoint("TOP", DeathpoolLog, "TOP", 0, layout.historySubtitleY)
    logSubtitle:SetText(
        DeathpoolDatabase.GetHistorySuccessfulOnly(state)
            and DeathpoolUI.HISTORY_SUBTITLE_SUCCESS_ONLY
            or DeathpoolUI.HISTORY_SUBTITLE_ALL
    )
    DeathpoolLog.logSubtitle = logSubtitle
    DeathpoolLog.showSuccessfulOnly = DeathpoolDatabase.GetHistorySuccessfulOnly(state)
    ---@type table<string, table>
    DeathpoolLog.columnHeaders = {}

    for _, column in ipairs(historyColumns) do
        local header = DeathpoolLog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        header:SetPoint("TOPLEFT", DeathpoolLog, "TOPLEFT", rowLeft + column.x, headerTop)
        header:SetWidth(column.width)
        header:SetJustifyH(column.justifyH)
        header:SetWordWrap(false)
        header:SetNonSpaceWrap(false)
        if column.key == "time" and DeathpoolLog.showSuccessfulOnly == true then
            header:SetText(DeathpoolUI.HISTORY_SUCCESS_RANK_LABEL)
        else
            header:SetText(column.label)
        end
        DeathpoolLog.columnHeaders[column.key] = header
    end

    local logScrollFrame = CreateFrame(
        "ScrollFrame",
        "DeathpoolLogScrollFrame",
        DeathpoolLog,
        "FauxScrollFrameTemplate"
    )
    logScrollFrame:SetPoint("TOPLEFT", DeathpoolLog, "TOPLEFT", layout.outsideGutter, rowTop)
    logScrollFrame:SetPoint("BOTTOMRIGHT", DeathpoolLog, "BOTTOMRIGHT", -(layout.outsideGutter + layout.scrollbarInset), 50)
    DeathpoolLog.scrollFrame = logScrollFrame

    DeathpoolUI.CreateDeathLogList(DeathpoolLog, {
        columns = historyColumns,
        rowCount = visibleRows,
        rowHeight = rowHeight,
        rowLeft = rowLeft,
        rowTop = rowTop,
        rowRight = -(layout.outsideGutter + layout.historyScrollbarGap + layout.scrollbarInset),
        tooltipOptions = DeathpoolUI.LOG_WINDOW_TOOLTIP_OPTIONS,
    })

    local filterButton = CreateFrame("Button", "DeathpoolLogFilterButton", DeathpoolLog, "GameMenuButtonTemplate")
    filterButton:SetSize(160, layout.compactButtonHeight)
    filterButton:SetPoint("BOTTOM", DeathpoolLog, "BOTTOM", 0, filterButtonBottom)
    filterButton:SetText(
        DeathpoolLog.showSuccessfulOnly == true
            and DeathpoolUI.HISTORY_FILTER_BUTTON_SHOW_ALL
            or DeathpoolUI.HISTORY_FILTER_BUTTON_SHOW_SUCCESS_ONLY
    )
    filterButton:SetScript("OnClick", function()
        DeathpoolLog.showSuccessfulOnly = DeathpoolLog.showSuccessfulOnly ~= true
        DeathpoolDatabase.SetHistorySuccessfulOnly(state, DeathpoolLog.showSuccessfulOnly)
        if DeathpoolLog.scrollFrame then
            DeathpoolLog.scrollFrame.offset = 0
        end
        if DeathpoolLog.RefreshHistory then
            DeathpoolLog:RefreshHistory()
        end
    end)
    DeathpoolLog.filterButton = filterButton

    logScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, rowHeight, function()
            DeathpoolLog:RefreshHistory()
        end)
    end)

    return DeathpoolLog
end

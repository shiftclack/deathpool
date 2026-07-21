local _, ns = ...
---@cast ns DeathpoolNamespace

local DeathpoolUI = ns.DeathpoolUI
local DeathpoolLogic = ns.DeathpoolLogic
local EMPTY_DEATHS = {}

---@class DeathpoolDeathDisplayFields
---@field time string
---@field name string
---@field level string
---@field sourceName string
---@field zone string
---@field points string
---@field multiplier string
---@field streakMultiplier string
---@field awardedPoints string

---@class DeathpoolDeathLogDisplayEntry
---@field death DeathpoolDeath
---@field displayFields DeathpoolDeathDisplayFields
---@field awardedPointsValue integer
---@field timestampValue integer
---@field color number[]

---@class DeathpoolDeathLogCacheView
---@field sourceRef DeathpoolDeath[]|nil
---@field sourceSnapshot DeathpoolDeath[]
---@field orderedEntries DeathpoolDeathLogDisplayEntry[]

---@class DeathpoolDeathLogDisplayCache
---@field entriesByDeath table<DeathpoolDeath, DeathpoolDeathLogDisplayEntry>
---@field recentView DeathpoolDeathLogCacheView
---@field historyView DeathpoolDeathLogCacheView
---@field successfulView DeathpoolDeathLogCacheView
---@field [string] DeathpoolDeathLogCacheView|table<DeathpoolDeath, DeathpoolDeathLogDisplayEntry>

---@class DeathpoolDeathLogColumn
---@field key string
---@field label string
---@field x number
---@field width number
---@field justifyH string|nil

---@class DeathpoolDeathLogViewOptions
---@field sortMode string|nil

---@class DeathpoolDeathLogCreateOptions
---@field columns DeathpoolDeathLogColumn[]|nil
---@field rowHeight integer|nil
---@field rowCount integer|nil
---@field rowLeft number|nil
---@field rowTop number|nil
---@field rowRight number|nil
---@field tooltipOptions DeathpoolLogTooltipOptions|nil
---@field fontObject string|nil

---@class DeathpoolDeathLogColumnContext
---@field showRank boolean|nil
---@field rank integer|nil

---@class DeathpoolDeathLogRefreshOptions
---@field columns DeathpoolDeathLogColumn[]|nil
---@field offset integer|nil
---@field maxRows integer|nil
---@field reverseOrder boolean|nil
---@field columnContext DeathpoolDeathLogColumnContext|nil

---@return DeathpoolDeathLogCacheView
local function CreateCacheView()
    return {
        sourceRef = nil,
        sourceSnapshot = {},
        orderedEntries = {},
    }
end

---@param death DeathpoolDeath
---@return integer
local function GetDisplayedPointsValue(death)
    return DeathpoolLogic.GetStoredDeathBasePoints(death)
        + DeathpoolLogic.GetStoredDeathSameZoneBonusPoints(death)
end

---@param death DeathpoolDeath
---@return DeathpoolDeathDisplayFields
local function CreateDisplayFields(death)
    return {
        time = DeathpoolUI.GetDeathFieldValue(DeathpoolUI.GetStoredDeathTime(death)),
        name = DeathpoolUI.GetDeathFieldValue(death.name),
        level = DeathpoolUI.GetDeathFieldValue(death.level),
        sourceName = DeathpoolUI.GetDeathFieldValue(death.sourceName),
        zone = DeathpoolUI.GetDeathFieldValue(death.zone),
        points = DeathpoolUI.GetDeathFieldValue(GetDisplayedPointsValue(death)),
        multiplier = DeathpoolUI.GetDeathFieldValue(
            DeathpoolUI.GetMultiplierDisplay(DeathpoolLogic.GetStoredDeathComboMultiplierValue(death))
        ),
        streakMultiplier = DeathpoolUI.GetDeathFieldValue(
            DeathpoolUI.GetMultiplierDisplay(DeathpoolLogic.GetStoredDeathStreakMultiplierValue(death))
        ),
        awardedPoints = DeathpoolUI.GetDeathFieldValue(DeathpoolLogic.GetStoredDeathAwardedPoints(death)),
    }
end

---@param death DeathpoolDeath
---@return DeathpoolDeathLogDisplayEntry
local function CreateDisplayCacheEntry(death)
    return {
        death = death,
        displayFields = CreateDisplayFields(death),
        awardedPointsValue = DeathpoolLogic.GetStoredDeathAwardedPoints(death),
        timestampValue = tonumber(death.timestamp) or 0,
        color = DeathpoolUI.GetDeathRowColor(death),
    }
end

---@param left DeathpoolDeathLogDisplayEntry
---@param right DeathpoolDeathLogDisplayEntry
---@return boolean
local function CompareSuccessfulEntries(left, right)
    if left.awardedPointsValue == right.awardedPointsValue then
        return left.timestampValue < right.timestampValue
    end

    return left.awardedPointsValue < right.awardedPointsValue
end

---@param view DeathpoolDeathLogCacheView
---@param sourceDeaths DeathpoolDeath[]
---@return boolean
local function SnapshotMatches(view, sourceDeaths)
    if view.sourceRef ~= sourceDeaths then
        return false
    end

    if #view.sourceSnapshot ~= #sourceDeaths then
        return false
    end

    for index, death in ipairs(sourceDeaths) do
        if view.sourceSnapshot[index] ~= death then
            return false
        end
    end

    return true
end

---@param view DeathpoolDeathLogCacheView
---@param sourceDeaths DeathpoolDeath[]
---@param orderedEntries DeathpoolDeathLogDisplayEntry[]
local function ReplaceViewEntries(view, sourceDeaths, orderedEntries)
    view.sourceRef = sourceDeaths
    view.sourceSnapshot = {}
    view.orderedEntries = orderedEntries

    for index, death in ipairs(sourceDeaths) do
        view.sourceSnapshot[index] = death
    end
end

---@param cache DeathpoolDeathLogDisplayCache
---@param death DeathpoolDeath
---@return DeathpoolDeathLogDisplayEntry
local function GetOrCreateCacheEntry(cache, death)
    local entry = cache.entriesByDeath[death]
    if entry then
        return entry
    end

    entry = CreateDisplayCacheEntry(death)
    cache.entriesByDeath[death] = entry
    return entry
end

---@return DeathpoolDeathLogDisplayCache
function DeathpoolUI.CreateDeathLogDisplayCache()
    return {
        entriesByDeath = {},
        recentView = CreateCacheView(),
        historyView = CreateCacheView(),
        successfulView = CreateCacheView(),
    }
end

---@param cache DeathpoolDeathLogDisplayCache
function DeathpoolUI.InvalidateDeathLogDisplayCache(cache)
    for _, view in ipairs({
        cache.recentView,
        cache.historyView,
        cache.successfulView,
    }) do
        view.sourceRef = nil
        view.sourceSnapshot = {}
        view.orderedEntries = {}
    end
end

---@param cache DeathpoolDeathLogDisplayCache
---@param viewKey string
---@param sourceDeaths DeathpoolDeath[]
---@param options DeathpoolDeathLogViewOptions
---@return DeathpoolDeathLogDisplayEntry[]
function DeathpoolUI.GetOrderedDeathLogViewEntries(cache, viewKey, sourceDeaths, options)
    if not cache or not cache.entriesByDeath or not viewKey then
        return {}
    end

    sourceDeaths = sourceDeaths or EMPTY_DEATHS
    options = options or {}

    local view = cache[viewKey]
    if not view then
        view = CreateCacheView()
        cache[viewKey] = view
    end

    if SnapshotMatches(view, sourceDeaths) then
        return view.orderedEntries
    end

    local orderedEntries = {}
    for index, death in ipairs(sourceDeaths) do
        orderedEntries[index] = GetOrCreateCacheEntry(cache, death)
    end

    if options.sortMode == "successful" then
        table.sort(orderedEntries, CompareSuccessfulEntries)
    end

    ReplaceViewEntries(view, sourceDeaths, orderedEntries)
    return view.orderedEntries
end

---@param item DeathpoolDeathLogDisplayEntry
---@param columnKey string
---@param context DeathpoolDeathLogColumnContext
---@return any
local function GetDeathLogItemValue(item, columnKey, context)
    if columnKey == "time" and context.showRank == true then
        return "#" .. tostring(context.rank or 0)
    end

    return item.displayFields[columnKey]
end

---@param item DeathpoolDeath|DeathpoolDeathLogDisplayEntry
---@return DeathpoolDeathLogDisplayEntry
local function NormalizeDeathLogItem(item)
    if item.displayFields then
        ---@cast item DeathpoolDeathLogDisplayEntry
        return item
    end

    ---@cast item DeathpoolDeath
    return CreateDisplayCacheEntry(item)
end

---@param row table
---@param anchor table|nil
local function ShowDeathLogRowTooltip(row, anchor)
    if not row.death then
        return
    end

    DeathpoolUI.ShowStandardizedTooltip(anchor or row, {
        death = row.death,
    }, row.tooltipOptions.showPredictionString, row.tooltipOptions.showIdentity, row.tooltipOptions.showFullCombos)
end

local function HideDeathLogTooltip()
    GameTooltip:Hide()
end

---@param tooltipOptions DeathpoolLogTooltipOptions
---@return boolean
local function HasHoverColumns(tooltipOptions)
    return type(tooltipOptions.hoverColumns) == "table"
end

---@param row table
---@param column DeathpoolDeathLogColumn
---@return table
local function CreateColumnTooltipTarget(row, column)
    local target = CreateFrame("Button", nil, row)
    target:SetPoint("TOPLEFT", row, "TOPLEFT", column.x, 0)
    target:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", column.x, 0)
    target:SetWidth(column.width)
    target:EnableMouse(true)
    target:SetScript("OnEnter", function(self)
        ShowDeathLogRowTooltip(row, self)
    end)
    target:SetScript("OnLeave", HideDeathLogTooltip)
    return target
end

---@param row table
---@param tooltipOptions DeathpoolLogTooltipOptions
local function ApplyDeathLogRowTooltipScripts(row, tooltipOptions)
    if HasHoverColumns(tooltipOptions) then
        row:SetScript("OnEnter", nil)
        row:SetScript("OnLeave", nil)
        return
    end

    row:SetScript("OnEnter", function(self)
        ShowDeathLogRowTooltip(self)
    end)
    row:SetScript("OnLeave", HideDeathLogTooltip)
end

---@param row table
---@param column DeathpoolDeathLogColumn
---@param fontObject string
---@param tooltipOptions DeathpoolLogTooltipOptions
local function CreateDeathLogColumnCell(row, column, fontObject, tooltipOptions)
    local cell = row:CreateFontString(nil, "OVERLAY", fontObject)
    cell:SetPoint("LEFT", row, "LEFT", column.x, 0)
    cell:SetWidth(column.width)
    cell:SetJustifyH(column.justifyH or "LEFT")
    cell:SetWordWrap(false)
    cell:SetNonSpaceWrap(false)
    row[column.key] = cell

    if HasHoverColumns(tooltipOptions) and tooltipOptions.hoverColumns[column.key] == true then
        local target = CreateColumnTooltipTarget(row, column)
        row.tooltipTargets[column.key] = target
        row[column.key .. "TooltipTarget"] = target
    end
end

---@param frame table
---@param options DeathpoolDeathLogCreateOptions
function DeathpoolUI.CreateDeathLogList(frame, options)
    local columns = options.columns or {}
    local rowHeight = options.rowHeight or 18
    local rowCount = options.rowCount or 0
    local rowLeft = options.rowLeft or 0
    local rowTop = options.rowTop or 0
    local rowRight = options.rowRight or 0
    local tooltipOptions = options.tooltipOptions or {}
    local fontObject = options.fontObject or "GameFontHighlightSmall"

    frame.rows = {}
    frame.logColumns = columns
    frame.logRowHeight = rowHeight
    frame.logTooltipOptions = tooltipOptions
    if frame.SetClipsChildren then
        frame:SetClipsChildren(true)
    end

    for rowIndex = 1, rowCount do
        local row = CreateFrame("Button", nil, frame)
        row:SetHeight(rowHeight)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", rowLeft, rowTop - ((rowIndex - 1) * rowHeight))
        row:SetPoint("RIGHT", frame, "RIGHT", rowRight, 0)
        row.tooltipOptions = tooltipOptions
        row.tooltipTargets = {}
        if row.SetClipsChildren then
            row:SetClipsChildren(true)
        end

        ApplyDeathLogRowTooltipScripts(row, tooltipOptions)

        for _, column in ipairs(columns) do
            CreateDeathLogColumnCell(row, column, fontObject, tooltipOptions)
        end

        frame.rows[rowIndex] = row
    end
end

---@param row table
---@param columns DeathpoolDeathLogColumn[]
local function ClearDeathLogRow(row, columns)
    row.death = nil
    for _, column in ipairs(columns) do
        local cell = row[column.key]
        if cell then
            cell:SetText("")
        end
    end
    row:Hide()
end

---@param deaths table[]
---@param rowIndex integer
---@param offset integer
---@param reverseOrder boolean
---@return integer
local function GetDeathLogRowDataIndex(deaths, rowIndex, offset, reverseOrder)
    if reverseOrder then
        return #deaths - offset - rowIndex + 1
    end

    return offset + rowIndex
end

---@param row table
---@param columns DeathpoolDeathLogColumn[]
---@param item DeathpoolDeathLogDisplayEntry
---@param items DeathpoolDeathLogDisplayEntry[]
---@param dataIndex integer
---@param columnContext DeathpoolDeathLogColumnContext
local function PopulateDeathLogRow(row, columns, item, items, dataIndex, columnContext)
    local rowContext = {
        showRank = columnContext.showRank == true,
        rank = (#items - dataIndex) + 1,
    }

    row.death = item.death
    for _, column in ipairs(columns) do
        local cell = row[column.key]
        if cell then
            cell:SetText(GetDeathLogItemValue(item, column.key, rowContext))
            cell:SetTextColor(item.color[1], item.color[2], item.color[3])
        end
    end
    row:Show()
end

---@param frame table
---@param items (DeathpoolDeath|DeathpoolDeathLogDisplayEntry)[]
---@param options DeathpoolDeathLogRefreshOptions
function DeathpoolUI.RefreshDeathLogRows(frame, items, options)
    if not frame or not frame.rows then
        return
    end

    items = items or EMPTY_DEATHS
    options = options or {}

    local columns = options.columns or frame.logColumns or {}
    local offset = options.offset or 0
    local maxRows = options.maxRows or #frame.rows
    local reverseOrder = options.reverseOrder ~= false
    local columnContext = options.columnContext or {}

    for rowIndex, row in ipairs(frame.rows) do
        if rowIndex > maxRows then
            ClearDeathLogRow(row, columns)
        else
            local dataIndex = GetDeathLogRowDataIndex(items, rowIndex, offset, reverseOrder)
            local item = items[dataIndex]

            if item then
                PopulateDeathLogRow(row, columns, NormalizeDeathLogItem(item), items, dataIndex, columnContext)
            else
                ClearDeathLogRow(row, columns)
            end
        end
    end
end

return DeathpoolUI

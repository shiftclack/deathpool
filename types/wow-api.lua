---@meta

---@class ColorInfo
---@field r number
---@field g number
---@field b number

---@class RaidWarningFrame
---@field UnregisterEvent fun(self: RaidWarningFrame, eventName: string)

---@class MinimapTooltip
---@field AddLine fun(self: MinimapTooltip, text: string, red: number|nil, green: number|nil, blue: number|nil, wrap: boolean|nil)

---@class MinimapLauncher
---@field type string
---@field label string
---@field text string
---@field value string
---@field suffix string
---@field icon string
---@field OnClick fun()
---@field OnTooltipShow fun(tooltip: MinimapTooltip|nil)

---@class LibDataBrokerApi
---@field NewDataObject fun(self: LibDataBrokerApi, name: string, dataObject: MinimapLauncher): MinimapLauncher

---@class LibDBIconApi
---@field Hide fun(self: LibDBIconApi, name: string)
---@field Show fun(self: LibDBIconApi, name: string)
---@field Refresh fun(self: LibDBIconApi, name: string, database: DeathpoolMinimapSettings)
---@field Register fun(self: LibDBIconApi, name: string, dataObject: MinimapLauncher, database: DeathpoolMinimapSettings)

---@class SettingsCategory
---@field ID number|string|nil
---@field name string|nil

---@class SettingsApi
---@field RegisterCanvasLayoutCategory fun(frame: table, name: string): SettingsCategory
---@field RegisterAddOnCategory fun(category: SettingsCategory): SettingsCategory

---@type table<integer, ColorInfo>
ITEM_QUALITY_COLORS = {}

---@type string[]
UISpecialFrames = {}

---@type RaidWarningFrame|nil
RaidWarningFrame = nil

---@type SettingsApi
Settings = {
    RegisterCanvasLayoutCategory = function(_, name)
        return {
            name = name,
        }
    end,
    RegisterAddOnCategory = function(category)
        return category
    end,
}

---@type fun(unit: string): string
UnitFactionGroup = function(_)
    return "Alliance"
end

---@overload fun(libraryName: "LibDataBroker-1.1", silent: boolean|nil): LibDataBrokerApi|nil
---@overload fun(libraryName: "LibDBIcon-1.0", silent: boolean|nil): LibDBIconApi|nil
---@type fun(libraryName: string, silent: boolean|nil): table|nil
LibStub = function(_, _)
    return nil
end

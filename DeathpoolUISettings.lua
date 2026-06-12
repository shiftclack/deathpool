---@class DeathpoolUISettingsPanelCheckbox
---@field label table|nil
---@field SetPoint fun(self: DeathpoolUISettingsPanelCheckbox, point: string, relativeTo: table, relativePoint: string, x: number, y: number)
---@field SetScript fun(self: DeathpoolUISettingsPanelCheckbox, eventName: string, handler: function)
---@field SetSize fun(self: DeathpoolUISettingsPanelCheckbox, width: number, height: number)
---@field CreateFontString fun(self: DeathpoolUISettingsPanelCheckbox, childName: string|nil, layer: string|nil, template: string|nil): table
---@field SetChecked fun(self: DeathpoolUISettingsPanelCheckbox, value: boolean)
---@field GetChecked fun(self: DeathpoolUISettingsPanelCheckbox): boolean
---@field Disable fun(self: DeathpoolUISettingsPanelCheckbox)
---@field Click fun(self: DeathpoolUISettingsPanelCheckbox, button: string|nil)

---@class DeathpoolUISettingsSettingsApi
---@field GetBlizzardDeathAlertsSuppressed fun(): boolean
---@field GetDeathAnnouncementToGuild fun(): boolean
---@field GetShowInCombat fun(): boolean
---@field SetBlizzardDeathAlertsSuppressed fun(enabled: boolean): boolean
---@field SetDeathAnnouncementToGuild fun(enabled: boolean): boolean
---@field SetShowInCombat fun(enabled: boolean): boolean

---@class DeathpoolUISettingsPanelModule
---@field categoryFrame table|nil
---@field announceDeathToGuildCheckbox DeathpoolUISettingsPanelCheckbox|nil
---@field suppressAlertsCheckbox DeathpoolUISettingsPanelCheckbox|nil
---@field showInCombatCheckbox DeathpoolUISettingsPanelCheckbox|nil
---@field Initialize fun(settingsApi: DeathpoolUISettingsSettingsApi)

local DeathpoolUISettings = _G.DeathpoolUISettings or {}
---@cast DeathpoolUISettings DeathpoolUISettingsPanelModule
local Settings = _G.Settings

---@type DeathpoolUISettingsSettingsApi|nil
local activeSettingsApi = nil
local categoryRegistered = false
local categoryFrame = nil
local announceDeathToGuildCheckbox = nil
local suppressAlertsCheckbox = nil
local showInCombatCheckbox = nil
local historicalLimitCheckbox = nil
local forceEnableNativeDeathAnnouncements = nil
local forceEnableNativeDeathAlerts = nil

---@return DeathpoolUISettingsSettingsApi
local function GetSettingsApi()
    local settingsApi = activeSettingsApi
    ---@cast settingsApi DeathpoolUISettingsSettingsApi
    return settingsApi
end

local function RefreshCheckboxStates()
    local settingsApi = GetSettingsApi()

    if suppressAlertsCheckbox then
        suppressAlertsCheckbox:SetChecked(settingsApi.GetBlizzardDeathAlertsSuppressed())
    end

    if announceDeathToGuildCheckbox then
        announceDeathToGuildCheckbox:SetChecked(settingsApi.GetDeathAnnouncementToGuild())
    end

    if showInCombatCheckbox then
        showInCombatCheckbox:SetChecked(settingsApi.GetShowInCombat())
    end
end

---@param parent table
---@param labelText string
---@param onClick fun(self: table)
---@return DeathpoolUISettingsPanelCheckbox
local function CreateCheckbox(parent, labelText, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    ---@cast checkbox DeathpoolUISettingsPanelCheckbox
    checkbox:SetSize(24, 24)
    checkbox:SetScript("OnClick", onClick)

    local label = checkbox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    label:SetJustifyH("LEFT")
    label:SetText(labelText)
    checkbox.label = label

    return checkbox
end

local function CreateCategoryFrame()
    local frame = CreateFrame("Frame", "DeathpoolSettingsPanel", UIParent)
    frame.name = "Deathpool"

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -16)
    title:SetJustifyH("LEFT")
    title:SetText("Hardcore Deathpool")

    -- local description = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    -- description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    -- description:SetJustifyH("LEFT")
    -- description:SetWordWrap(true)
    -- description:SetText(
    --     "A hardcore death prediction game"
    -- )

    showInCombatCheckbox = CreateCheckbox(frame, "Show in combat", function(self)
        local settingsApi = GetSettingsApi()
        settingsApi.SetShowInCombat(self:GetChecked())
        RefreshCheckboxStates()
    end)
    showInCombatCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)

    announceDeathToGuildCheckbox = CreateCheckbox(frame, "Announce death to guild", function(self)
        local settingsApi = GetSettingsApi()
        settingsApi.SetDeathAnnouncementToGuild(self:GetChecked())
        RefreshCheckboxStates()
    end)
    announceDeathToGuildCheckbox:SetPoint("TOPLEFT", showInCombatCheckbox, "BOTTOMLEFT", 0, -12)

    suppressAlertsCheckbox = CreateCheckbox(frame, "Hide native death alerts (experimental)", function(self)
        local settingsApi = GetSettingsApi()
        settingsApi.SetBlizzardDeathAlertsSuppressed(self:GetChecked())
        RefreshCheckboxStates()
    end)
    suppressAlertsCheckbox:SetPoint("TOPLEFT", announceDeathToGuildCheckbox, "BOTTOMLEFT", 0, -12)

    historicalLimitCheckbox = CreateCheckbox(frame, "Increase historical death tracking limit (may hurt performance)", function(self)
        local settingsApi = GetSettingsApi()
        settingsApi.SetShowInCombat(self:GetChecked())
        RefreshCheckboxStates()
    end)
    historicalLimitCheckbox:SetPoint("TOPLEFT", suppressAlertsCheckbox, "BOTTOMLEFT", 0, -12)
    historicalLimitCheckbox.label:SetTextColor(0.5, 0.5, 0.5, 1)
    historicalLimitCheckbox:Disable()

    forceEnableNativeDeathAnnouncements = CreateCheckbox(frame, "Force the game to enable death announcements", function(self)
        local settingsApi = GetSettingsApi()
        settingsApi.SetShowInCombat(self:GetChecked())
        RefreshCheckboxStates()
    end)
    forceEnableNativeDeathAnnouncements:SetPoint("TOPLEFT", historicalLimitCheckbox, "BOTTOMLEFT", 0, -12)
    forceEnableNativeDeathAnnouncements.label:SetTextColor(0.5, 0.5, 0.5, 1)
    forceEnableNativeDeathAnnouncements:Disable()

    forceEnableNativeDeathAlerts = CreateCheckbox(frame, "Force the game to enable death alerts", function(self)
        local settingsApi = GetSettingsApi()
        settingsApi.SetShowInCombat(self:GetChecked())
        RefreshCheckboxStates()
    end)
    forceEnableNativeDeathAlerts:SetPoint("TOPLEFT", forceEnableNativeDeathAnnouncements, "BOTTOMLEFT", 0, -12)
    forceEnableNativeDeathAlerts.label:SetTextColor(0.5, 0.5, 0.5, 1)
    forceEnableNativeDeathAlerts:Disable()
    frame:SetScript("OnShow", RefreshCheckboxStates)

    return frame
end

---@param settingsApi DeathpoolUISettingsSettingsApi
function DeathpoolUISettings.Initialize(settingsApi)
    activeSettingsApi = settingsApi

    if categoryRegistered ~= true then
        categoryFrame = CreateCategoryFrame()
        local category = Settings.RegisterCanvasLayoutCategory(categoryFrame, "Hardcore Deathpool")
        Settings.RegisterAddOnCategory(category)
        categoryRegistered = true

        DeathpoolUISettings.categoryFrame = categoryFrame
        DeathpoolUISettings.announceDeathToGuildCheckbox = announceDeathToGuildCheckbox
        DeathpoolUISettings.suppressAlertsCheckbox = suppressAlertsCheckbox
        DeathpoolUISettings.showInCombatCheckbox = showInCombatCheckbox
    end

    RefreshCheckboxStates()
end

_G.DeathpoolUISettings = DeathpoolUISettings

return DeathpoolUISettings

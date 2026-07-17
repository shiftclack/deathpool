---@class DeathpoolUISettingsPanelCheckbox
---@field label table|nil
---@field SetPoint fun(self: DeathpoolUISettingsPanelCheckbox, point: string, relativeTo: table, relativePoint: string, x: number, y: number)
---@field SetScript fun(self: DeathpoolUISettingsPanelCheckbox, eventName: string, handler: function)
---@field SetSize fun(self: DeathpoolUISettingsPanelCheckbox, width: number, height: number)
---@field CreateFontString fun(self: DeathpoolUISettingsPanelCheckbox, childName: string|nil, layer: string|nil, template: string|nil): table
---@field SetChecked fun(self: DeathpoolUISettingsPanelCheckbox, value: boolean)
---@field GetChecked fun(self: DeathpoolUISettingsPanelCheckbox): boolean
---@field Enable fun(self: DeathpoolUISettingsPanelCheckbox)
---@field Disable fun(self: DeathpoolUISettingsPanelCheckbox)
---@field IsEnabled fun(self: DeathpoolUISettingsPanelCheckbox): boolean
---@field Click fun(self: DeathpoolUISettingsPanelCheckbox, button: string|nil)

---@class DeathpoolUISettingsSettingsApi
---@field GetDisableMinimapIcon fun(): boolean
---@field GetGuildAnnouncementsEnabled fun(): boolean
---@field GetDeathAnnouncementToGuild fun(): boolean
---@field GetAnnounceScoreOnLevelUp fun(): boolean
---@field GetShowInCombat fun(): boolean
---@field SetDisableMinimapIcon fun(disabled: boolean): boolean
---@field SetGuildAnnouncementsEnabled fun(enabled: boolean): boolean
---@field SetDeathAnnouncementToGuild fun(enabled: boolean): boolean
---@field SetAnnounceScoreOnLevelUp fun(enabled: boolean): boolean
---@field SetShowInCombat fun(enabled: boolean): boolean

---@class DeathpoolUISettingsPanelModule
---@field categoryFrame table|nil
---@field guildAnnouncementsEnabledCheckbox DeathpoolUISettingsPanelCheckbox|nil
---@field announceDeathToGuildCheckbox DeathpoolUISettingsPanelCheckbox|nil
---@field announceScoreOnLevelUpCheckbox DeathpoolUISettingsPanelCheckbox|nil
---@field disableMinimapIconCheckbox DeathpoolUISettingsPanelCheckbox|nil
---@field showInCombatCheckbox DeathpoolUISettingsPanelCheckbox|nil
---@field Initialize fun(settingsApi: DeathpoolUISettingsSettingsApi)

local DeathpoolUISettings = _G.DeathpoolUISettings or {}
---@cast DeathpoolUISettings DeathpoolUISettingsPanelModule
local DeathpoolConstants = _G.DeathpoolConstants
local Settings = _G.Settings

---@type DeathpoolUISettingsSettingsApi|nil
local activeSettingsApi = nil
local categoryRegistered = false
local categoryFrame = nil
local guildAnnouncementsEnabledCheckbox = nil
local announceDeathToGuildCheckbox = nil
local announceScoreOnLevelUpCheckbox = nil
local disableMinimapIconCheckbox = nil
local showInCombatCheckbox = nil
local GUILD_ANNOUNCEMENT_CHILD_INDENT = 24

---@return DeathpoolUISettingsSettingsApi
local function GetSettingsApi()
    local settingsApi = activeSettingsApi
    ---@cast settingsApi DeathpoolUISettingsSettingsApi
    return settingsApi
end

local function RefreshCheckboxStates()
    local settingsApi = GetSettingsApi()
    local guildAnnouncementsEnabled = settingsApi.GetGuildAnnouncementsEnabled()

    if guildAnnouncementsEnabledCheckbox then
        guildAnnouncementsEnabledCheckbox:SetChecked(guildAnnouncementsEnabled)
    end

    if announceDeathToGuildCheckbox then
        announceDeathToGuildCheckbox:SetChecked(settingsApi.GetDeathAnnouncementToGuild())
        if guildAnnouncementsEnabled then
            announceDeathToGuildCheckbox:Enable()
        else
            announceDeathToGuildCheckbox:Disable()
        end
    end

    if announceScoreOnLevelUpCheckbox then
        announceScoreOnLevelUpCheckbox:SetChecked(settingsApi.GetAnnounceScoreOnLevelUp())
        if guildAnnouncementsEnabled then
            announceScoreOnLevelUpCheckbox:Enable()
        else
            announceScoreOnLevelUpCheckbox:Disable()
        end
    end

    if showInCombatCheckbox then
        showInCombatCheckbox:SetChecked(settingsApi.GetShowInCombat())
    end

    if disableMinimapIconCheckbox then
        disableMinimapIconCheckbox:SetChecked(settingsApi.GetDisableMinimapIcon())
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
    local layout = DeathpoolUI.LAYOUT
    local frame = CreateFrame("Frame", "DeathpoolSettingsPanel", UIParent)
    frame.name = "Deathpool"

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", layout.outsideGutter, -layout.outsideGutter)
    title:SetJustifyH("LEFT")
    title:SetText("Hardcore Death Pool")

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

    guildAnnouncementsEnabledCheckbox = CreateCheckbox(frame, "Enable guild announcements", function(self)
        local settingsApi = GetSettingsApi()
        settingsApi.SetGuildAnnouncementsEnabled(self:GetChecked())
        RefreshCheckboxStates()
    end)
    guildAnnouncementsEnabledCheckbox:SetPoint("TOPLEFT", showInCombatCheckbox, "BOTTOMLEFT", 0, -12)

    announceDeathToGuildCheckbox = CreateCheckbox(frame, "Announce death to guild", function(self)
        local settingsApi = GetSettingsApi()
        settingsApi.SetDeathAnnouncementToGuild(self:GetChecked())
        RefreshCheckboxStates()
    end)
    announceDeathToGuildCheckbox:SetPoint(
        "TOPLEFT",
        guildAnnouncementsEnabledCheckbox,
        "BOTTOMLEFT",
        GUILD_ANNOUNCEMENT_CHILD_INDENT,
        -12
    )

    announceScoreOnLevelUpCheckbox = CreateCheckbox(
        frame,
        "Announce score every " .. DeathpoolConstants.ANNOUNCEMENTS.levelUpFrequency .. " levels",
        function(self)
            local settingsApi = GetSettingsApi()
            settingsApi.SetAnnounceScoreOnLevelUp(self:GetChecked())
            RefreshCheckboxStates()
        end
    )
    announceScoreOnLevelUpCheckbox:SetPoint("TOPLEFT", announceDeathToGuildCheckbox, "BOTTOMLEFT", 0, -12)

    disableMinimapIconCheckbox = CreateCheckbox(frame, "Disable minimap icon", function(self)
        local settingsApi = GetSettingsApi()
        settingsApi.SetDisableMinimapIcon(self:GetChecked())
        RefreshCheckboxStates()
    end)
    disableMinimapIconCheckbox:SetPoint(
        "TOPLEFT",
        announceScoreOnLevelUpCheckbox,
        "BOTTOMLEFT",
        -GUILD_ANNOUNCEMENT_CHILD_INDENT,
        -12
    )

    frame:SetScript("OnShow", RefreshCheckboxStates)

    return frame
end

---@param settingsApi DeathpoolUISettingsSettingsApi
function DeathpoolUISettings.Initialize(settingsApi)
    activeSettingsApi = settingsApi

    if categoryRegistered ~= true then
        categoryFrame = CreateCategoryFrame()
        local category = Settings.RegisterCanvasLayoutCategory(categoryFrame, "Hardcore Death Pool")
        Settings.RegisterAddOnCategory(category)
        categoryRegistered = true

        DeathpoolUISettings.categoryFrame = categoryFrame
        DeathpoolUISettings.guildAnnouncementsEnabledCheckbox = guildAnnouncementsEnabledCheckbox
        DeathpoolUISettings.announceDeathToGuildCheckbox = announceDeathToGuildCheckbox
        DeathpoolUISettings.announceScoreOnLevelUpCheckbox = announceScoreOnLevelUpCheckbox
        DeathpoolUISettings.disableMinimapIconCheckbox = disableMinimapIconCheckbox
        DeathpoolUISettings.showInCombatCheckbox = showInCombatCheckbox
    end

    RefreshCheckboxStates()
end

_G.DeathpoolUISettings = DeathpoolUISettings

return DeathpoolUISettings

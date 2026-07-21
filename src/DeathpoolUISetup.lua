local _, ns = ...
---@cast ns DeathpoolNamespace

local DeathpoolUISetup = {}
local DeathpoolUI = ns.DeathpoolUI
local DeathpoolDatabase = ns.DeathpoolDatabase
local DeathpoolSetup = ns.DeathpoolSetup
ns.DeathpoolUISetup = DeathpoolUISetup

---@class DeathpoolSetupFrame
---@field Show fun(self: DeathpoolSetupFrame)
---@field Hide fun(self: DeathpoolSetupFrame)
---@field IsShown fun(self: DeathpoolSetupFrame): boolean
---@field SetSize fun(self: DeathpoolSetupFrame, width: number, height: number)
---@field SetPoint fun(self: DeathpoolSetupFrame, point: string, relativeTo: table, relativePoint: string, xOffset: number, yOffset: number)
---@field SetFrameStrata fun(self: DeathpoolSetupFrame, strata: string)
---@field SetToplevel fun(self: DeathpoolSetupFrame, enabled: boolean)
---@field SetMovable fun(self: DeathpoolSetupFrame, enabled: boolean)
---@field EnableMouse fun(self: DeathpoolSetupFrame, enabled: boolean)
---@field SetScript fun(self: DeathpoolSetupFrame, scriptType: string, handler: function)
---@field CreateFontString fun(self: DeathpoolSetupFrame, name: string|nil, layer: string, template: string): DeathpoolSetupFontString
---@field title DeathpoolSetupFontString
---@field subtitle DeathpoolSetupFontString
---@field enableDeathAnnouncementsButton DeathpoolSetupButton
---@field enableDeathAnnouncementsText DeathpoolSetupFontString
---@field joinHardcoreDeathsButton DeathpoolSetupButton
---@field joinHardcoreDeathsText DeathpoolSetupFontString
---@field backdropOverlay DeathpoolModalBackdropOverlay
---@field titlebarDragHandle DeathpoolModalTitlebarDragHandle
---@field CloseButton DeathpoolSetupButton|nil
---@field ownerFrame table

---@class DeathpoolSetupButton
---@field Enable fun(self: DeathpoolSetupButton)
---@field Disable fun(self: DeathpoolSetupButton)
---@field IsEnabled fun(self: DeathpoolSetupButton): boolean
---@field SetSize fun(self: DeathpoolSetupButton, width: number, height: number)
---@field SetPoint fun(self: DeathpoolSetupButton, point: string, relativeTo: table, relativePoint: string, xOffset: number, yOffset: number)
---@field SetText fun(self: DeathpoolSetupButton, text: string)
---@field SetScript fun(self: DeathpoolSetupButton, scriptType: string, handler: function)
---@field GetFontString fun(self: DeathpoolSetupButton): DeathpoolSetupFontString

---@class DeathpoolSetupFontString
---@field ClearAllPoints fun(self: DeathpoolSetupFontString)
---@field SetPoint fun(self: DeathpoolSetupFontString, point: string, relativeTo: table, relativePoint: string, xOffset: number, yOffset: number)
---@field SetText fun(self: DeathpoolSetupFontString, text: string)
---@field SetJustifyH fun(self: DeathpoolSetupFontString, justify: string)
---@field SetJustifyV fun(self: DeathpoolSetupFontString, justify: string)
---@field SetTextColor fun(self: DeathpoolSetupFontString, red: number, green: number, blue: number, alpha: number)

---@param ownerFrame table
local function RefreshOwnerFrame(ownerFrame)
    ownerFrame:RefreshDeaths()
    ownerFrame:RefreshLockedPrediction()
    ownerFrame:RefreshCollapsedSummary()
end

---@param ownerFrame table
---@param active boolean
function DeathpoolUISetup.ApplyMainWindowState(ownerFrame, active)
    ownerFrame.setupActive = active == true

    if ownerFrame.setupActive then
        for _, button in ipairs(ownerFrame.levelRangeButtons) do
            button:Disable()
        end

        ownerFrame.sourceEditBox:Disable()
        ownerFrame.zoneEditBox:Disable()
        ownerFrame.sourceEditBox:SetTextColor(unpack(DeathpoolUI.COLORS.predictionInputLocked))
        ownerFrame.zoneEditBox:SetTextColor(unpack(DeathpoolUI.COLORS.predictionInputLocked))
        ownerFrame.emptyPredictionPrompt:Hide()
        DeathpoolUI.HideDropdown(ownerFrame)
        return
    end

    DeathpoolUI.ApplyPredictionInputLockState(
        ownerFrame,
        DeathpoolDatabase.GetLockedPrediction(DeathpoolUI.GetState(ownerFrame)) ~= nil
    )
end

---@param setupFrame DeathpoolSetupFrame
---@param setupState DeathpoolSetupState
local function RefreshSetupRows(setupFrame, setupState)
    if setupState.hasEnabledDeathAnnouncements then
        setupFrame.enableDeathAnnouncementsButton:SetText("ENABLED")
        setupFrame.enableDeathAnnouncementsButton:Disable()
    else
        setupFrame.enableDeathAnnouncementsButton:SetText("ENABLE")
        setupFrame.enableDeathAnnouncementsButton:Enable()
    end

    if setupState.hasJoinedHardcoreDeathsChannel then
        setupFrame.joinHardcoreDeathsButton:SetText("JOINED")
        setupFrame.joinHardcoreDeathsButton:Disable()
    else
        setupFrame.joinHardcoreDeathsButton:SetText("JOIN")
        setupFrame.joinHardcoreDeathsButton:Enable()
    end
end

---@param ownerFrame table
local function HideOwnerLogWindow(ownerFrame)
    ownerFrame.logFrame:Hide()
end

---@param ownerFrame table
---@return boolean
local function CanCloseSetupWindow(ownerFrame)
    local database = DeathpoolUI.GetState(ownerFrame)
    return DeathpoolDatabase.GetHasSeenIntroDemo(database)
        and DeathpoolDatabase.GetHasSeenFirstRun(database)
end

---@param setupFrame DeathpoolSetupFrame
---@param ownerFrame table
local function RefreshSetupCloseButtonState(setupFrame, ownerFrame)
    local closeButton = setupFrame.CloseButton
    if not closeButton then
        return
    end

    if CanCloseSetupWindow(ownerFrame) then
        closeButton:Enable()
    else
        closeButton:Disable()
    end
end

---@param setupFrame DeathpoolSetupFrame
---@param ownerFrame table
---@param forceHide boolean
function DeathpoolUISetup.Refresh(setupFrame, ownerFrame, forceHide)
    local setupState = DeathpoolSetup.GetState()
    local active = setupState.isComplete ~= true and forceHide ~= true and setupFrame:IsShown()

    if active then
        DeathpoolUI.ShowExpandedOwnerFrame(ownerFrame)
        HideOwnerLogWindow(ownerFrame)
    end

    DeathpoolUISetup.ApplyMainWindowState(ownerFrame, active)
    RefreshSetupRows(setupFrame, setupState)
    RefreshSetupCloseButtonState(setupFrame, ownerFrame)

    if active then
        setupFrame.backdropOverlay:Show()
        setupFrame:Show()
    else
        setupFrame.backdropOverlay:Hide()
        setupFrame:Hide()
    end
end

---@param setupFrame DeathpoolSetupFrame
---@param ownerFrame table
---@return boolean
function DeathpoolUISetup.ShowOnMainWindowOpen(setupFrame, ownerFrame)
    if setupFrame:IsShown() then
        return true
    end

    if not DeathpoolSetup.ShouldShowOnMainWindowOpen() then
        return false
    end

    if ownerFrame.introDemoController and ownerFrame.introDemoController:IsActive() then
        return false
    end

    DeathpoolUISetup.Show(setupFrame, ownerFrame)
    return true
end

---@param setupFrame DeathpoolSetupFrame
---@param ownerFrame table
function DeathpoolUISetup.Show(setupFrame, ownerFrame)
    local setupState = DeathpoolSetup.GetState()

    DeathpoolUI.ShowExpandedOwnerFrame(ownerFrame)
    HideOwnerLogWindow(ownerFrame)
    DeathpoolUISetup.ApplyMainWindowState(ownerFrame, setupState.isComplete ~= true)
    RefreshSetupRows(setupFrame, setupState)
    RefreshSetupCloseButtonState(setupFrame, ownerFrame)
    setupFrame.backdropOverlay:Show()
    setupFrame:Show()
end

---@param ownerFrame table
---@return DeathpoolSetupFrame
function DeathpoolUISetup.CreateWindow(ownerFrame)
    local layout = DeathpoolUI.LAYOUT
    local setupFrame = CreateFrame("Frame", "DeathpoolSetupFrame", UIParent, "BasicFrameTemplateWithInset")
    ---@cast setupFrame DeathpoolSetupFrame
    setupFrame.ownerFrame = ownerFrame
    setupFrame:SetSize(430, 150)
    setupFrame:SetPoint("CENTER", ownerFrame, "CENTER", 0, 0)
    setupFrame:SetFrameStrata("DIALOG")
    setupFrame:SetToplevel(true)
    setupFrame:SetMovable(false)
    setupFrame:EnableMouse(true)
    setupFrame:Hide()

    setupFrame.backdropOverlay = DeathpoolUI.CreateModalBackdropOverlay(ownerFrame)

    setupFrame:SetScript("OnShow", function(self)
        self.backdropOverlay:Show()
        RefreshSetupCloseButtonState(self, ownerFrame)
        HideOwnerLogWindow(ownerFrame)
    end)
    setupFrame:SetScript("OnHide", function(self)
        self.backdropOverlay:Hide()
        DeathpoolUISetup.ApplyMainWindowState(ownerFrame, false)
    end)

    if setupFrame.CloseButton then
        setupFrame.CloseButton:SetScript("OnClick", function()
            if CanCloseSetupWindow(ownerFrame) then
                setupFrame:Hide()
            end
        end)
        RefreshSetupCloseButtonState(setupFrame, ownerFrame)
    end

    local title = setupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    ---@cast title DeathpoolSetupFontString
    title:SetPoint("TOP", setupFrame, "TOP", 0, -6)
    title:SetText("SETUP")
    setupFrame.title = title

    setupFrame.titlebarDragHandle = DeathpoolUI.CreateModalTitlebarDragHandle(setupFrame, ownerFrame)

    local subtitle = setupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ---@cast subtitle DeathpoolSetupFontString
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -14)
    subtitle:SetText("Let's make sure you're set up!")
    setupFrame.subtitle = subtitle

    local enableDeathAnnouncementsButton = CreateFrame("Button", nil, setupFrame, "GameMenuButtonTemplate")
    ---@cast enableDeathAnnouncementsButton DeathpoolSetupButton
    enableDeathAnnouncementsButton:SetSize(96, layout.compactButtonHeight)
    enableDeathAnnouncementsButton:SetPoint("TOPLEFT", setupFrame, "TOPLEFT", 70, -64)
    enableDeathAnnouncementsButton:GetFontString():ClearAllPoints()
    enableDeathAnnouncementsButton:GetFontString():SetPoint("CENTER", enableDeathAnnouncementsButton, "CENTER", 0, -1)
    enableDeathAnnouncementsButton:GetFontString():SetJustifyV("MIDDLE")
    enableDeathAnnouncementsButton:SetText("ENABLE")
    enableDeathAnnouncementsButton:SetScript("OnClick", function()
        if not enableDeathAnnouncementsButton:IsEnabled() then
            return
        end

        DeathpoolSetup.EnableDeathAnnouncements()
        RefreshOwnerFrame(ownerFrame)
    end)
    setupFrame.enableDeathAnnouncementsButton = enableDeathAnnouncementsButton

    local enableDeathAnnouncementsText = setupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ---@cast enableDeathAnnouncementsText DeathpoolSetupFontString
    enableDeathAnnouncementsText:SetPoint("LEFT", enableDeathAnnouncementsButton, "RIGHT", 10, 0)
    enableDeathAnnouncementsText:SetJustifyH("LEFT")
    enableDeathAnnouncementsText:SetTextColor(1, 0.82, 0, 1)
    enableDeathAnnouncementsText:SetText("Hardcore death announcements")
    setupFrame.enableDeathAnnouncementsText = enableDeathAnnouncementsText

    local joinHardcoreDeathsButton = CreateFrame("Button", nil, setupFrame, "GameMenuButtonTemplate")
    ---@cast joinHardcoreDeathsButton DeathpoolSetupButton
    joinHardcoreDeathsButton:SetSize(96, layout.compactButtonHeight)
    joinHardcoreDeathsButton:SetPoint("TOPLEFT", enableDeathAnnouncementsButton, "BOTTOMLEFT", 0, -8)
    joinHardcoreDeathsButton:GetFontString():ClearAllPoints()
    joinHardcoreDeathsButton:GetFontString():SetPoint("CENTER", joinHardcoreDeathsButton, "CENTER", 0, -1)
    joinHardcoreDeathsButton:GetFontString():SetJustifyV("MIDDLE")
    joinHardcoreDeathsButton:SetText("JOIN")
    joinHardcoreDeathsButton:SetScript("OnClick", function()
        if not joinHardcoreDeathsButton:IsEnabled() then
            return
        end

        DeathpoolSetup.JoinHardcoreDeathsChannel()
        RefreshOwnerFrame(ownerFrame)
    end)
    setupFrame.joinHardcoreDeathsButton = joinHardcoreDeathsButton

    local joinHardcoreDeathsText = setupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ---@cast joinHardcoreDeathsText DeathpoolSetupFontString
    joinHardcoreDeathsText:SetPoint("LEFT", joinHardcoreDeathsButton, "RIGHT", 10, 0)
    joinHardcoreDeathsText:SetJustifyH("LEFT")
    joinHardcoreDeathsText:SetTextColor(1, 0.82, 0, 1)
    joinHardcoreDeathsText:SetText("The HardcoreDeaths channel")
    setupFrame.joinHardcoreDeathsText = joinHardcoreDeathsText

    return setupFrame
end

return DeathpoolUISetup

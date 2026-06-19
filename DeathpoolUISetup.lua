local DeathpoolUISetup = {}
local DeathpoolUI = _G.DeathpoolUI
local DeathpoolDatabase = _G.DeathpoolDatabase
local DeathpoolSetup = _G.DeathpoolSetup

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
---@field backdropOverlay DeathpoolSetupBackdropOverlay
---@field titlebarDragHandle DeathpoolSetupDragHandle
---@field ownerFrame table

---@class DeathpoolSetupButton
---@field Enable fun(self: DeathpoolSetupButton)
---@field Disable fun(self: DeathpoolSetupButton)
---@field IsEnabled fun(self: DeathpoolSetupButton): boolean
---@field SetSize fun(self: DeathpoolSetupButton, width: number, height: number)
---@field SetPoint fun(self: DeathpoolSetupButton, point: string, relativeTo: table, relativePoint: string, xOffset: number, yOffset: number)
---@field SetText fun(self: DeathpoolSetupButton, text: string)
---@field SetScript fun(self: DeathpoolSetupButton, scriptType: string, handler: function)

---@class DeathpoolSetupFontString
---@field SetPoint fun(self: DeathpoolSetupFontString, point: string, relativeTo: table, relativePoint: string, xOffset: number, yOffset: number)
---@field SetText fun(self: DeathpoolSetupFontString, text: string)
---@field SetJustifyH fun(self: DeathpoolSetupFontString, justify: string)
---@field SetTextColor fun(self: DeathpoolSetupFontString, red: number, green: number, blue: number, alpha: number)

---@class DeathpoolSetupBackdropOverlay
---@field Show fun(self: DeathpoolSetupBackdropOverlay)
---@field Hide fun(self: DeathpoolSetupBackdropOverlay)
---@field SetAllPoints fun(self: DeathpoolSetupBackdropOverlay)
---@field SetFrameLevel fun(self: DeathpoolSetupBackdropOverlay, frameLevel: number)
---@field EnableMouse fun(self: DeathpoolSetupBackdropOverlay, enabled: boolean)
---@field RegisterForDrag fun(self: DeathpoolSetupBackdropOverlay, button: string)
---@field SetScript fun(self: DeathpoolSetupBackdropOverlay, scriptType: string, handler: function)
---@field CreateTexture fun(self: DeathpoolSetupBackdropOverlay, name: string|nil, layer: string): DeathpoolSetupTexture
---@field texture DeathpoolSetupTexture

---@class DeathpoolSetupDragHandle
---@field SetPoint fun(self: DeathpoolSetupDragHandle, point: string, relativeTo: table, relativePoint: string, xOffset: number, yOffset: number)
---@field SetHeight fun(self: DeathpoolSetupDragHandle, height: number)
---@field EnableMouse fun(self: DeathpoolSetupDragHandle, enabled: boolean)
---@field RegisterForDrag fun(self: DeathpoolSetupDragHandle, button: string)
---@field SetScript fun(self: DeathpoolSetupDragHandle, scriptType: string, handler: function)

---@class DeathpoolSetupTexture
---@field SetAllPoints fun(self: DeathpoolSetupTexture)
---@field SetColorTexture fun(self: DeathpoolSetupTexture, red: number, green: number, blue: number, alpha: number)

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
        setupFrame.enableDeathAnnouncementsButton:Disable()
    else
        setupFrame.enableDeathAnnouncementsButton:Enable()
    end

    if setupState.hasJoinedHardcoreDeathsChannel then
        setupFrame.joinHardcoreDeathsButton:Disable()
    else
        setupFrame.joinHardcoreDeathsButton:Enable()
    end
end

---@param setupFrame DeathpoolSetupFrame
local function ShowBackdropOverlay(setupFrame)
    setupFrame.backdropOverlay:Show()
end

---@param setupFrame DeathpoolSetupFrame
local function HideBackdropOverlay(setupFrame)
    setupFrame.backdropOverlay:Hide()
end

---@param ownerFrame table
local function StartOwnerFrameDrag(ownerFrame)
    ownerFrame:StartMoving()
end

---@param ownerFrame table
local function StopOwnerFrameDrag(ownerFrame)
    ownerFrame:StopMovingOrSizing()
    DeathpoolUI.SaveWindowPosition(ownerFrame, DeathpoolUI.GetState(ownerFrame), ownerFrame.isCollapsed)
end

---@param ownerFrame table
local function ShowExpandedOwnerFrame(ownerFrame)
    if ownerFrame.isCollapsed == true then
        DeathpoolUI.SetWindowCollapsed(ownerFrame, DeathpoolUI.GetState(ownerFrame), false)
    end

    if not ownerFrame:IsShown() then
        ownerFrame:Show()
    end
end

---@param ownerFrame table
local function HideOwnerLogWindow(ownerFrame)
    ownerFrame.logFrame:Hide()
end

---@param setupFrame DeathpoolSetupFrame
---@param ownerFrame table
---@param forceHide boolean
function DeathpoolUISetup.Refresh(setupFrame, ownerFrame, forceHide)
    local setupState = DeathpoolSetup.GetState()
    local active = setupState.isComplete ~= true and forceHide ~= true and setupFrame:IsShown()

    if active then
        ShowExpandedOwnerFrame(ownerFrame)
        HideOwnerLogWindow(ownerFrame)
    end

    DeathpoolUISetup.ApplyMainWindowState(ownerFrame, active)
    RefreshSetupRows(setupFrame, setupState)

    if active then
        ShowBackdropOverlay(setupFrame)
        setupFrame:Show()
    else
        HideBackdropOverlay(setupFrame)
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

    DeathpoolSetup.MarkShownThisSession()
    DeathpoolUISetup.Show(setupFrame, ownerFrame)
    return true
end

---@param setupFrame DeathpoolSetupFrame
---@param ownerFrame table
function DeathpoolUISetup.Show(setupFrame, ownerFrame)
    local setupState = DeathpoolSetup.GetState()

    ShowExpandedOwnerFrame(ownerFrame)
    HideOwnerLogWindow(ownerFrame)
    DeathpoolUISetup.ApplyMainWindowState(ownerFrame, setupState.isComplete ~= true)
    RefreshSetupRows(setupFrame, setupState)
    ShowBackdropOverlay(setupFrame)
    setupFrame:Show()
end

---@param ownerFrame table
---@return DeathpoolSetupFrame
function DeathpoolUISetup.CreateWindow(ownerFrame)
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

    local backdropOverlay = CreateFrame("Frame", nil, ownerFrame)
    ---@cast backdropOverlay DeathpoolSetupBackdropOverlay
    backdropOverlay:SetAllPoints()
    backdropOverlay:SetFrameLevel(ownerFrame:GetFrameLevel() + 40)
    backdropOverlay:EnableMouse(true)
    backdropOverlay:RegisterForDrag("LeftButton")
    backdropOverlay:SetScript("OnDragStart", function()
        StartOwnerFrameDrag(ownerFrame)
    end)
    backdropOverlay:SetScript("OnDragStop", function()
        StopOwnerFrameDrag(ownerFrame)
    end)
    local backdropTexture = backdropOverlay:CreateTexture(nil, "BACKGROUND")
    ---@cast backdropTexture DeathpoolSetupTexture
    backdropTexture:SetAllPoints()
    backdropTexture:SetColorTexture(0, 0, 0, 0.58)
    backdropOverlay.texture = backdropTexture
    backdropOverlay:Hide()
    setupFrame.backdropOverlay = backdropOverlay

    setupFrame:SetScript("OnShow", function(self)
        ShowBackdropOverlay(self)
        HideOwnerLogWindow(ownerFrame)
    end)
    setupFrame:SetScript("OnHide", function(self)
        local shouldStartIntroDemo = ownerFrame.shouldStartIntroDemoAfterSetup == true

        HideBackdropOverlay(self)
        DeathpoolUISetup.ApplyMainWindowState(ownerFrame, false)
        ownerFrame.shouldStartIntroDemoAfterSetup = false

        if shouldStartIntroDemo and ownerFrame:IsShown() and ownerFrame.introDemoController then
            ownerFrame.introDemoController:Show()
        end
    end)

    local title = setupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    ---@cast title DeathpoolSetupFontString
    title:SetPoint("TOP", setupFrame, "TOP", 0, -6)
    title:SetText("SETUP")
    setupFrame.title = title

    local titlebarDragHandle = CreateFrame("Frame", nil, setupFrame)
    ---@cast titlebarDragHandle DeathpoolSetupDragHandle
    titlebarDragHandle:SetPoint("TOPLEFT", setupFrame, "TOPLEFT", 8, -4)
    titlebarDragHandle:SetPoint("TOPRIGHT", setupFrame, "TOPRIGHT", -32, -4)
    titlebarDragHandle:SetHeight(22)
    titlebarDragHandle:EnableMouse(true)
    titlebarDragHandle:RegisterForDrag("LeftButton")
    titlebarDragHandle:SetScript("OnDragStart", function()
        StartOwnerFrameDrag(ownerFrame)
    end)
    titlebarDragHandle:SetScript("OnDragStop", function()
        StopOwnerFrameDrag(ownerFrame)
    end)
    setupFrame.titlebarDragHandle = titlebarDragHandle

    local subtitle = setupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ---@cast subtitle DeathpoolSetupFontString
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -14)
    subtitle:SetText("Let's make sure you're set up!")
    setupFrame.subtitle = subtitle

    local enableDeathAnnouncementsButton = CreateFrame("Button", nil, setupFrame, "GameMenuButtonTemplate")
    ---@cast enableDeathAnnouncementsButton DeathpoolSetupButton
    enableDeathAnnouncementsButton:SetSize(96, 24)
    enableDeathAnnouncementsButton:SetPoint("TOPLEFT", setupFrame, "TOPLEFT", 70, -64)
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
    joinHardcoreDeathsButton:SetSize(96, 24)
    joinHardcoreDeathsButton:SetPoint("TOPLEFT", enableDeathAnnouncementsButton, "BOTTOMLEFT", 0, -8)
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

_G.DeathpoolUISetup = DeathpoolUISetup

return DeathpoolUISetup

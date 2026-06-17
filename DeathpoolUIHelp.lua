local DeathpoolUI = _G.DeathpoolUI
local DeathpoolConstants = _G.DeathpoolConstants
local HELP_RULES = DeathpoolConstants.HELP
local DOWNLOAD_AREA_WIDTH = 204

---@class DeathpoolHelpOwnerFrame: DeathpoolMainFrameShell
---@field [string] any

---@class DeathpoolHelpFrame
---@field [string] any
---@field downloadArea table
---@field downloadLink table
---@field downloadUrlBox table
---@field closeButton table
---@field demoButton table

---@return string
local function BuildHelpWindowText()
    local skull = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12:12:0:0|t"
    local diamond = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:12:12|t"
    return table.concat({"",
        diamond .. " Game Overview " .. diamond,
        "",
        "Hardcore Deathpool is a |cFFFFFF00death prediction minigame|r for your faction.",
        "",
        skull .. " Predict the |cFFFFFF00level|r, |cFFFFFF00location|r and |cFFFFFF00source|r of incoming deaths\n",
        skull .. " View deaths in |cFFFFFF00real time|r\n",
        skull .. " Earn points if |cFFFFFF00any part|r of your prediction matches\n",
        skull .. " Win even more with |cFFFFFF00streak bonuses|r\n",
        skull .. " Gain |cFFFFFF00extra points|r if someone dies in the same zone as you\n",
        skull .. " The game ends when you die and receive your |cFFFFFF00final score|r\n",
        "",
        "",
        diamond .. " Missing deaths? " .. diamond,
        "",
        "Press Escape, Press Options, type |cFFFFFF00Hardcore|r into the Search menu. "
            .. "Set |cFFFFFF00Hardcore death announcements|r to |cFFFFFF00All Deaths|r. "
            .. "Then type |cFFFFFF00/join hardcoredeaths|r to join the chat channel.",
        "",
    }, "\n")
end


---@return string
function DeathpoolUI.GetHelpWindowText()
    return BuildHelpWindowText()
end

---@return string
function DeathpoolUI.GetDownloadUrl()
    return HELP_RULES.downloadUrl
end

---@param ownerFrame DeathpoolHelpOwnerFrame
---@return DeathpoolHelpFrame
function DeathpoolUI.CreateHelpWindow(ownerFrame)
    local downloadUrl = DeathpoolUI.GetDownloadUrl()

    local helpFrame = CreateFrame("Frame", "DeathpoolHelpFrame", UIParent, "BasicFrameTemplateWithInset")
    ---@cast helpFrame DeathpoolHelpFrame
    helpFrame:SetSize(500, 410)
    helpFrame:SetPoint("CENTER", UIParent, "CENTER", 20, -10)
    helpFrame:SetFrameStrata("DIALOG")
    helpFrame:SetToplevel(true)
    helpFrame:SetMovable(true)
    helpFrame:EnableMouse(true)
    helpFrame:RegisterForDrag("LeftButton")
    helpFrame:SetScript("OnDragStart", helpFrame.StartMoving)
    helpFrame:SetScript("OnDragStop", helpFrame.StopMovingOrSizing)
    helpFrame:Hide()

    local title = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", helpFrame, "TOP", 0, -6)
    title:SetText("HELP")

    local scrollFrame = CreateFrame("ScrollFrame", "DeathpoolHelpScrollFrame", helpFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", helpFrame, "TOPLEFT", 18, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", helpFrame, "BOTTOMRIGHT", -30, 84)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(404)
    scrollFrame:SetScrollChild(content)

    local helpText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    helpText:SetPoint("TOPLEFT", content, "TOPLEFT", 8, 0)
    helpText:SetJustifyH("LEFT")
    helpText:SetJustifyV("TOP")
    helpText:SetWordWrap(true)
    helpText:SetNonSpaceWrap(false)
    helpText:SetWidth(396)
    helpText:SetText(DeathpoolUI.GetHelpWindowText())

    content:SetHeight(helpText:GetStringHeight() + 12)

    local footer = CreateFrame("Frame", nil, helpFrame)
    footer:SetPoint("BOTTOMLEFT", helpFrame, "BOTTOMLEFT", 16, 12)
    footer:SetPoint("BOTTOMRIGHT", helpFrame, "BOTTOMRIGHT", -16, 12)
    footer:SetHeight(60)

    local downloadArea = CreateFrame("Frame", nil, footer)
    downloadArea:SetSize(DOWNLOAD_AREA_WIDTH, 40)
    downloadArea:SetPoint("BOTTOMLEFT", footer, "BOTTOMLEFT", 8, 4)

    local downloadLink = CreateFrame("Button", nil, downloadArea)
    downloadLink:SetSize(DOWNLOAD_AREA_WIDTH, 18)
    downloadLink:SetPoint("BOTTOMLEFT", downloadArea, "BOTTOMLEFT", 0, 0)
    downloadLink:SetNormalFontObject("GameFontHighlightSmall")
    downloadLink:SetHighlightFontObject("GameFontHighlightSmall")
    downloadLink:SetText("Download on GitHub")
    downloadLink:GetFontString():SetJustifyH("LEFT")
    downloadLink:GetFontString():SetWidth(DOWNLOAD_AREA_WIDTH)
    downloadLink:GetFontString():SetTextColor(0.25, 0.6, 1.0)

    local downloadUrlBox = CreateFrame("EditBox", nil, downloadArea, "InputBoxTemplate")
    downloadUrlBox:SetAutoFocus(false)
    downloadUrlBox:SetSize(DOWNLOAD_AREA_WIDTH, 20)
    downloadUrlBox:SetPoint("TOPLEFT", downloadArea, "TOPLEFT", 0, 0)
    downloadUrlBox:SetFontObject("GameFontHighlightSmall")
    downloadUrlBox:SetText(downloadUrl)
    downloadUrlBox:SetCursorPosition(0)
    ---@param self table
    downloadUrlBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:HighlightText(0, 0)
    end)
    ---@param self table
    downloadUrlBox:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)
    ---@param self table
    ---@param userInput boolean
    downloadUrlBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(downloadUrl)
            self:HighlightText()
        end
    end)
    downloadUrlBox:Hide()

    ---@param self table
    downloadLink:SetScript("OnEnter", function(self)
        self:GetFontString():SetTextColor(0.45, 0.75, 1.0)
    end)
    ---@param self table
    downloadLink:SetScript("OnLeave", function(self)
        self:GetFontString():SetTextColor(0.25, 0.6, 1.0)
    end)
    downloadLink:SetScript("OnClick", function()
        downloadUrlBox:Show()
        downloadUrlBox:SetFocus()
        downloadUrlBox:HighlightText()
    end)

    local closeButton = CreateFrame("Button", "DeathpoolHelpCloseButton", helpFrame, "GameMenuButtonTemplate")
    closeButton:SetSize(120, 28)
    closeButton:SetPoint("BOTTOMRIGHT", helpFrame, "BOTTOMRIGHT", -18, 16)
    closeButton:SetText("CLOSE")
    closeButton:SetScript("OnClick", function()
        helpFrame:Hide()
    end)

    local demoButton = CreateFrame("Button", "DeathpoolHelpDemoButton", helpFrame, "GameMenuButtonTemplate")
    demoButton:SetSize(120, 28)
    demoButton:SetPoint("RIGHT", closeButton, "LEFT", -12, 0)
    demoButton:SetText("DEMO")
    demoButton:SetScript("OnClick", function()
        helpFrame:Hide()
        if ownerFrame and ownerFrame.introDemoController and ownerFrame.introDemoController.Show then
            ownerFrame.introDemoController:Show()
        end
    end)

    helpFrame.downloadArea = downloadArea
    helpFrame.downloadLink = downloadLink
    helpFrame.downloadUrlBox = downloadUrlBox
    helpFrame.closeButton = closeButton
    helpFrame.demoButton = demoButton

    return helpFrame
end

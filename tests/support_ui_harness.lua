package.path = table.concat({
    "./?.lua",
    "./?/init.lua",
    package.path,
}, ";")

local function createRegion(regionKind, name, parent, template)
    local region = {
        kind = regionKind,
        name = name,
        parent = parent,
        template = template,
        children = {},
        points = {},
        scripts = {},
        visible = true,
        enabled = true,
    }

    function region:SetSize(width, height)
        self.width = width
        self.height = height
        if self.scripts.OnSizeChanged then
            self.scripts.OnSizeChanged(self, width, height)
        end
    end

    function region:GetSize()
        return self.width, self.height
    end

    function region:GetWidth()
        return self.width or 0
    end

    function region:GetHeight()
        return self.height or 0
    end

    function region:SetWidth(width)
        self.width = width
        if self.scripts.OnSizeChanged then
            self.scripts.OnSizeChanged(self, self.width, self.height)
        end
    end

    function region:SetHeight(height)
        self.height = height
        if self.scripts.OnSizeChanged then
            self.scripts.OnSizeChanged(self, self.width, self.height)
        end
    end

    function region:SetPoint(...)
        self.points[#self.points + 1] = { ... }
    end

    function region:GetPoint(index)
        local point = self.points[index or 1]
        if not point then
            return nil
        end

        return unpack(point)
    end

    function region:ClearAllPoints()
        self.points = {}
    end

    function region:SetFrameStrata(value)
        self.frameStrata = value
    end

    function region:SetToplevel(value)
        self.toplevel = value
    end

    function region:SetMovable(value)
        self.movable = value
    end

    function region:SetResizable(value)
        self.resizable = value
    end

    function region:SetClipsChildren(value)
        self.clipsChildren = value
    end

    function region:SetMinResize(width, height)
        self.minResize = {
            width = width,
            height = height,
        }
    end

    function region:SetMaxResize(width, height)
        self.maxResize = {
            width = width,
            height = height,
        }
    end

    function region:EnableMouse(value)
        self.mouseEnabled = value
    end

    function region:RegisterForDrag(button)
        self.dragButton = button
    end

    function region:RegisterEvent(eventName)
        self.registeredEvents = self.registeredEvents or {}
        self.registeredEvents[eventName] = true
    end

    function region:SetScript(eventName, handler)
        self.scripts[eventName] = handler
    end

    function region:GetScript(eventName)
        return self.scripts[eventName]
    end

    function region:Show()
        local wasShown = self.visible == true
        self.visible = true
        if not wasShown and self.scripts.OnShow then
            self.scripts.OnShow(self)
        end
    end

    function region:Hide()
        local wasShown = self.visible == true
        self.visible = false
        if wasShown and self.scripts.OnHide then
            self.scripts.OnHide(self)
        end
    end

    function region:IsShown()
        return self.visible == true
    end

    function region:GetName()
        return self.name
    end

    function region:GetParent()
        return self.parent
    end

    function region:SetText(text)
        self.text = text
    end

    function region:GetText()
        return self.text
    end

    function region:SetChecked(value)
        self.checked = value == true
    end

    function region:GetChecked()
        return self.checked == true
    end

    function region:SetTextColor(red, green, blue, alpha)
        self.textColor = { red, green, blue, alpha }
    end

    function region:SetOwner(owner, anchor)
        self.owner = owner
        self.anchor = anchor
        self.lines = {}
    end

    function region:ClearLines()
        self.lines = {}
    end

    function region:AddLine(text, red, green, blue, wrap)
        self.lines = self.lines or {}
        self.lines[#self.lines + 1] = {
            left = text,
            right = nil,
            leftColor = red and { red, green, blue } or nil,
            rightColor = nil,
            wrap = wrap == true,
        }
    end

    function region:AddDoubleLine(leftText, rightText, leftR, leftG, leftB, rightR, rightG, rightB)
        self.lines = self.lines or {}
        self.lines[#self.lines + 1] = {
            left = leftText,
            right = rightText,
            leftColor = leftR and { leftR, leftG, leftB } or nil,
            rightColor = rightR and { rightR, rightG, rightB } or nil,
        }
    end

    function region:SetNormalTexture(texture)
        self.normalTexture = texture
    end

    function region:GetNormalTexture()
        return self.normalTexture
    end

    function region:SetPushedTexture(texture)
        self.pushedTexture = texture
    end

    function region:GetPushedTexture()
        return self.pushedTexture
    end

    function region:SetDisabledTexture(texture)
        self.disabledTexture = texture
    end

    function region:GetDisabledTexture()
        return self.disabledTexture
    end

    function region:SetHighlightTexture(texture)
        self.highlightTexture = texture
    end

    function region:GetHighlightTexture()
        return self.highlightTexture
    end

    function region:SetNormalFontObject(fontObject)
        self.normalFontObject = fontObject
    end

    function region:SetHighlightFontObject(fontObject)
        self.highlightFontObject = fontObject
    end

    function region:SetJustifyH(value)
        self.justifyH = value
    end

    function region:SetJustifyV(value)
        self.justifyV = value
    end

    function region:SetWordWrap(value)
        self.wordWrap = value
    end

    function region:SetMultiLine(value)
        self.multiLine = value
    end

    function region:SetNonSpaceWrap(value)
        self.nonSpaceWrap = value
    end

    function region:SetTextInsets(left, right, top, bottom)
        self.textInsets = { left, right, top, bottom }
    end

    function region:SetColorTexture(red, green, blue, alpha)
        self.colorTexture = { red, green, blue, alpha }
    end

    function region:SetTexture(path)
        self.texturePath = path
    end

    function region:SetAutoFocus(value)
        self.autoFocus = value
    end

    function region:SetFontObject(value)
        self.fontObject = value
    end

    function region:SetCursorPosition(value)
        self.cursorPosition = value
    end

    function region:SetAllPoints()
        self.allPoints = true
    end

    function region:SetFocus()
        self.hasFocus = true
    end

    function region:ClearFocus()
        self.hasFocus = false
    end

    function region:HighlightText(startIndex, endIndex)
        self.highlightRange = { startIndex, endIndex }
    end

    function region:SetScrollChild(child)
        self.scrollChild = child
    end

    function region:Raise()
        self.raised = true
    end

    function region:Enable()
        self.enabled = true
    end

    function region:Disable()
        self.enabled = false
    end

    function region:IsEnabled()
        return self.enabled == true
    end

    function region:Click(button)
        if self.scripts.OnClick then
            self.scripts.OnClick(self, button)
        end
    end

    function region:StartMoving()
        self.startedMoving = true
    end

    function region:StartSizing(point)
        self.startedSizing = point
    end

    function region:StopMovingOrSizing()
        self.stoppedMoving = true
    end

    function region:SetFrameLevel(value)
        self.frameLevel = value
    end

    function region:GetFrameLevel()
        return self.frameLevel or 0
    end

    function region:GetFontString()
        if not self.fontString then
            self.fontString = createRegion("FontString", nil, self, nil)
        end
        return self.fontString
    end

    function region:CreateFontString(childName, _, childTemplate)
        local child = createRegion("FontString", childName, self, childTemplate)
        self.children[#self.children + 1] = child
        return child
    end

    function region:CreateTexture(childName, childLayer)
        local child = createRegion("Texture", childName, self, childLayer)
        self.children[#self.children + 1] = child
        return child
    end

    function region:GetStringHeight()
        local text = self.text or ""
        local lineCount = 1
        for _ in string.gmatch(text, "\n") do
            lineCount = lineCount + 1
        end
        return lineCount * 12
    end

    function region:GetStringWidth()
        local text = self.text or ""
        return string.len(text) * 6
    end

    return region
end

local function walkRegions(region, callback)
    callback(region)
    for _, child in ipairs(region.children or {}) do
        walkRegions(child, callback)
    end
    if region.fontString then
        walkRegions(region.fontString, callback)
    end
end

local function findRegionText(root, needle)
    local matchedText = nil
    walkRegions(root, function(region)
        if matchedText ~= nil then
            return
        end
        if type(region.text) == "string" and string.find(region.text, needle, 1, true) then
            matchedText = region.text
        end
    end)
    return matchedText
end

local function findDropdownButtonByText(dropdown, text)
    for _, button in ipairs(dropdown.buttons or {}) do
        if button:IsShown() and button.text and button.text:GetText() == text then
            return button
        end
    end

    return nil
end

local function dispatchEvent(frame, eventName, ...)
    if not frame or not eventName then
        return false
    end

    local eventArgs = { ... }
    local fired = false
    local dispatchedFrames = {}

    local function fireFrame(target)
        if not target or dispatchedFrames[target] then
            return
        end
        dispatchedFrames[target] = true

        if not (target.registeredEvents and target.registeredEvents[eventName]) then
            return
        end

        local onEvent = target:GetScript("OnEvent")
        if not onEvent then
            return
        end

        onEvent(target, eventName, unpack(eventArgs))
        fired = true
    end

    fireFrame(frame)

    for _, createdFrame in ipairs(_G.__frames or {}) do
        fireFrame(createdFrame)
    end

    return fired
end

local function pressEscape()
    for _, frameName in ipairs(_G.UISpecialFrames or {}) do
        local frame = _G[frameName]
        if frame and frame:IsShown() then
            frame:Hide()
            return true
        end
    end

    return false
end

local function initializeBundledLibs()
    local libDataBroker = {}
    local libDBIcon = {}

    function libDataBroker.NewDataObject(_, _, dataObject)
        return dataObject
    end

    function libDBIcon.Register()
    end

    function libDBIcon.Refresh()
    end

    function libDBIcon.Hide()
    end

    function libDBIcon.Show()
    end

    _G.LibStub = function(libraryName, silent)
        if libraryName == "LibDataBroker-1.1" then
            return libDataBroker
        end

        if libraryName == "LibDBIcon-1.0" then
            return libDBIcon
        end

        if not silent then
            error("Unknown library: " .. tostring(libraryName))
        end

        return nil
    end
end

---@param options table|nil
local function initializeGlobals(options)
    options = options or {}
    UIParent = createRegion("Frame", "UIParent", nil, nil)
    UIParent:SetSize(1024, 768)
    DeathpoolCharacterState = nil
    _G.LibStub = nil
    _G.UISpecialFrames = {}
    _G.__frames = {}
    local function registerCanvasLayoutCategory(frame, name)
        local category = {
            ID = _G.Settings.nextCategoryId,
            name = name,
            frame = frame,
        }

        function category:GetID()
            return self.ID
        end

        _G.Settings.nextCategoryId = _G.Settings.nextCategoryId + 1
        _G.Settings.registeredCanvasCategories[#_G.Settings.registeredCanvasCategories + 1] = category
        return category
    end

    local function registerAddOnCategory(category)
        _G.Settings.registeredAddOnCategories[#_G.Settings.registeredAddOnCategories + 1] = category
        return category
    end

    _G.Settings = {
        registeredCanvasCategories = {},
        registeredAddOnCategories = {},
        nextCategoryId = 1,
        RegisterCanvasLayoutCategory = registerCanvasLayoutCategory,
        RegisterAddOnCategory = registerAddOnCategory,
    }
    rawset(_G, "wipe", function(values)
        for key in pairs(values) do
            values[key] = nil
        end

        return values
    end)

    CreateFrame = function(kind, name, parent, template)
        local frame = createRegion(kind, name, parent, template)
        _G.__frames[#_G.__frames + 1] = frame
        if parent then
            parent.children[#parent.children + 1] = frame
        end
        if name then
            _G[name] = frame
        end
        return frame
    end

    DEFAULT_CHAT_FRAME = {
        messages = {},
    }

    function DEFAULT_CHAT_FRAME:AddMessage(message)
        self.messages[#self.messages + 1] = message
    end

    _G.__sentChatMessages = {}

    rawset(_G, "SendChatMessage", function(message, chatType, language, target)
        _G.__sentChatMessages[#_G.__sentChatMessages + 1] = {
            message = message,
            chatType = chatType,
            language = language,
            target = target,
        }
    end)

    SlashCmdList = {}

    UIDropDownMenu_SetWidth = function(dropdown, width)
        dropdown.dropdownWidth = width
    end

    UIDropDownMenu_SetText = function(dropdown, text)
        dropdown.dropdownText = text
        dropdown.text = text
    end

    UIDropDownMenu_Initialize = function(dropdown, initializer)
        dropdown.dropdownInitializer = initializer
    end

    UIDropDownMenu_CreateInfo = function()
        return {}
    end

    UIDropDownMenu_AddButton = function(info, level)
        if not _G.__dropdownButtons then
            _G.__dropdownButtons = {}
        end
        _G.__dropdownButtons[#_G.__dropdownButtons + 1] = {
            info = info,
            level = level,
        }
    end

    CloseDropDownMenus = function()
    end

    GameTooltip = {
        lines = {},
        visible = false,
    }

    function GameTooltip:SetOwner(owner, anchor)
        self.owner = owner
        self.anchor = anchor
        self.lines = {}
    end

    function GameTooltip:AddDoubleLine(leftText, rightText, leftR, leftG, leftB, rightR, rightG, rightB)
        self.lines[#self.lines + 1] = {
            left = leftText,
            right = rightText,
            leftColor = leftR and { leftR, leftG, leftB } or nil,
            rightColor = rightR and { rightR, rightG, rightB } or nil,
        }
    end

    function GameTooltip:Show()
        self.visible = true
    end

    function GameTooltip:Hide()
        self.visible = false
    end

    FauxScrollFrame_Update = function(frame, totalItems, visibleItems, itemHeight)
        frame.lastUpdate = {
            totalItems = totalItems,
            visibleItems = visibleItems,
            itemHeight = itemHeight,
        }
    end

    FauxScrollFrame_GetOffset = function(frame)
        return frame.offset or 0
    end

    FauxScrollFrame_OnVerticalScroll = function(frame, offset, itemHeight, updateFunc)
        frame.offset = math.floor(offset / itemHeight)
        updateFunc()
    end

    time = function()
        return 24680
    end

    date = function(formatString)
        if formatString == "%H:%M:%S" then
            return "12:34:56"
        end
        return "10:05"
    end

    UnitName = function(_)
        return "HarnessPlayer"
    end

    UnitLevel = function()
        return 17
    end

    GetZoneText = function()
        return "Elwynn Forest"
    end

    GetRealmName = function()
        return "Defias Pillager"
    end

    -- https://wago.tools/db2/GlobalStrings?build=1.15.5.57979&filter%5BBaseTag%5D=HARDCORE_CAUSEOFDEATH&page=1&sort%5BBaseTag%5D=asc
    -- not all of these are used, we include everything to ensure proper testing
    rawset(_G, "HARDCORE_CAUSEOFDEATH_CREATURE", "|Hplayer:%s|h[%s]|h has been slain by a %s in %s! They were level %d")
    rawset(_G, "HARDCORE_CAUSEOFDEATH_DROWNING", "|Hplayer:%s|h[%s]|h drowned to death in %s! They were level %d")
    rawset(_G, "HARDCORE_CAUSEOFDEATH_DUEL", "|Hplayer:%s|h[%s]|h has been slain in a duel by %s in $s! They were level %d")
    rawset(_G, "HARDCORE_CAUSEOFDEATH_FALLING", "|Hplayer:%s|h[%s]|h fell to their death in %s! They were level %d")
    rawset(_G, "HARDCORE_CAUSEOFDEATH_FATIGUE", "|Hplayer:%s|h[%s]|h died of fatigue in %s! They were level %d")
    rawset(_G, "HARDCORE_CAUSEOFDEATH_FIRE", "|Hplayer:%s|h[%s]|h was burnt to death by fire in %s! They were level %d")
    rawset(_G, "HARDCORE_CAUSEOFDEATH_LAVA", "|Hplayer:%s|h[%s]|h was burnt to a crisp by lava in %s! They were level %d")
    rawset(_G, "HARDCORE_CAUSEOFDEATH_NONE", "|Hplayer:%s|h[%s]|h has died at level %d")
    rawset(_G, "HARDCORE_CAUSEOFDEATH_PVP", "|Hplayer:%s|h[%s]|h has been slain by %s in %s! They were level %d")
    rawset(_G, "HARDCORE_CAUSEOFDEATH_SLIME", "|Hplayer:%s|h[%s]|h was slimed to death in %s! They w")

    rawset(_G, "UnitFactionGroup", function(_)
        return options.faction or "Alliance"
    end)

    _G.ITEM_QUALITY_COLORS = {
        [0] = { r = 0.62, g = 0.62, b = 0.62 },
        [1] = { r = 1.0, g = 1.0, b = 1.0 },
        [2] = { r = 0.12, g = 1.0, b = 0.0 },
        [3] = { r = 0.0, g = 0.44, b = 0.87 },
        [4] = { r = 0.64, g = 0.21, b = 0.93 },
    }

    _G.__dropdownButtons = nil
    initializeBundledLibs()
end

local function loadUiModules()
    package.loaded.DeathpoolConstants = nil
    package.loaded.DeathpoolDatabase = nil
    package.loaded.DeathpoolLogic = nil
    package.loaded.DeathpoolLogicPrediction = nil
    package.loaded.DeathpoolLogicScoring = nil
    package.loaded.DeathpoolLogicDeaths = nil
    package.loaded.DeathpoolLogicState = nil
    package.loaded.DeathpoolDebug = nil
    _G.DeathpoolConstants = require("DeathpoolConstants")
    _G.DeathpoolDatabase = require("DeathpoolDatabase")
    _G.DeathpoolDebug = require("DeathpoolDebug")
    _G.DeathpoolLogic = require("DeathpoolLogic")
    require("DeathpoolLogicPrediction")
    require("DeathpoolLogicScoring")
    require("DeathpoolLogicDeaths")
    require("DeathpoolLogicState")

    package.loaded.DeathpoolUI = nil
    package.loaded.DeathpoolUITooltip = nil
    package.loaded.DeathpoolUIDeathLogList = nil
    package.loaded.DeathpoolUIAutocomplete = nil
    package.loaded.DeathpoolUIHelp = nil
    package.loaded.DeathpoolUIRefresh = nil
    package.loaded.DeathpoolUILog = nil
    package.loaded.DeathpoolSettings = nil
    package.loaded.DeathpoolUISettings = nil
    package.loaded.DeathpoolUIDemo = nil
    package.loaded.DeathpoolDemo = nil
    package.loaded.DeathpoolUIDebug = nil
    package.loaded.DeathpoolUIMinimap = nil
    package.loaded.DeathpoolUIMain = nil
    package.loaded.DeathpoolCommands = nil
    package.loaded.DeathpoolMigration = nil

    local DeathpoolUI = require("DeathpoolUI")
    local DeathpoolUIMinimap = require("DeathpoolUIMinimap")
    require("DeathpoolMigration")
    require("DeathpoolUITooltip")
    require("DeathpoolUIDeathLogList")
    require("DeathpoolUIAutocomplete")
    require("DeathpoolUIHelp")
    require("DeathpoolUIRefresh")
    require("DeathpoolUILog")
    require("DeathpoolSettings")
    require("DeathpoolUISettings")
    require("DeathpoolUIDemo")
    require("DeathpoolDemo")
    require("DeathpoolUIDebug")
    require("DeathpoolUIMain")

    return DeathpoolUI, DeathpoolUIMinimap
end

local UIHarness = {}

function UIHarness.Create(options)
    options = options or {}
    initializeGlobals(options)

    local printedMessages = {}
    local DeathpoolUI, DeathpoolUIMinimap = loadUiModules()
    DeathpoolCharacterState = _G.DeathpoolDatabase.Init(options.state)
    local Deathpool, DeathpoolDebug, DeathpoolLog = DeathpoolUI.Initialize(
        DeathpoolCharacterState,
        _G.DeathpoolLogic,
        _G.DeathpoolConstants.STORAGE.maxRecentDeaths
    )
    local introDemoController = _G.DeathpoolDemo.Initialize(
        DeathpoolCharacterState,
        function()
            Deathpool:RefreshDeaths()
            Deathpool:RefreshLockedPrediction()
            Deathpool:RefreshCollapsedSummary()
        end
    )
    introDemoController:AttachFrame(Deathpool)

    return {
        DeathpoolUI = DeathpoolUI,
        DeathpoolUIMinimap = DeathpoolUIMinimap,
        Deathpool = Deathpool,
        DeathpoolDebug = DeathpoolDebug,
        DeathpoolLog = DeathpoolLog,
        introDemoController = introDemoController,
        printedMessages = printedMessages,
        dispatchEvent = dispatchEvent,
        pressEscape = pressEscape,
        findRegionText = findRegionText,
        findDropdownButtonByText = findDropdownButtonByText,
    }
end

function UIHarness.CreateAddon(options)
    options = options or {}
    initializeGlobals(options)

    local DeathpoolUI, DeathpoolUIMinimap = loadUiModules()
    package.loaded.DeathpoolParser = nil
    package.loaded.DeathpoolCommands = nil
    package.loaded.Deathpool = nil
    _G.DeathpoolDebug = require("DeathpoolDebug")
    _G.DeathpoolMigration = require("DeathpoolMigration")
    DeathpoolCharacterState = options.state
    _G.DeathpoolParser = require("DeathpoolParser")
    _G.DeathpoolCommands = require("DeathpoolCommands")
    require("Deathpool")

    local function getController()
        return rawget(_G, "DeathpoolAddonFrame")
    end

    local function getMainFrame()
        return rawget(_G, "DeathpoolFrame")
    end

    local function getDebugFrame()
        return rawget(_G, "DeathpoolDebugFrame")
    end

    local function getLogFrame()
        return rawget(_G, "DeathpoolLogFrame")
    end

    return {
        DeathpoolUI = DeathpoolUI,
        DeathpoolUIMinimap = DeathpoolUIMinimap,
        controller = getController(),
        getController = getController,
        getMainFrame = getMainFrame,
        getDebugFrame = getDebugFrame,
        getLogFrame = getLogFrame,
        chatMessages = DEFAULT_CHAT_FRAME.messages,
        sentChatMessages = _G.__sentChatMessages,
        dispatchEvent = dispatchEvent,
        pressEscape = pressEscape,
    }
end

return UIHarness

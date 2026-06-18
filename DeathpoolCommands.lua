---@alias DeathpoolCommandsPrintMessage fun(message: string)

---@class DeathpoolCommandsAddonFrame
---@field state DeathpoolCharacterState
---@field mainFrame DeathpoolMinimapControllerFrame|nil

---@class DeathpoolSlashCommand
---@field raw string
---@field lowered string
---@field command string

local DeathpoolCommands = _G.DeathpoolCommands or {}
local DeathpoolDatabase = _G.DeathpoolDatabase
local DeathpoolDebug = _G.DeathpoolDebug
local DeathpoolDebugState = _G.DeathpoolDebugState
local DeathpoolSettings = _G.DeathpoolSettings
local DeathpoolUI = _G.DeathpoolUI
local DeathpoolUIMinimap = _G.DeathpoolUIMinimap

---@type DeathpoolCommandsAddonFrame|nil
local activeAddonFrame = nil

---@type DeathpoolCommandsPrintMessage|nil
local activePrintMessage = nil

---@return DeathpoolCommandsAddonFrame|nil
local function GetAddonFrame()
    return activeAddonFrame
end

---@return DeathpoolCharacterState|nil
local function GetState()
    local addonFrame = GetAddonFrame()
    return addonFrame and addonFrame.state or nil
end

---@param message string
local function Print(message)
    if activePrintMessage then
        activePrintMessage(message)
    end
end

---@param message string
---@return DeathpoolSlashCommand
local function NormalizeSlashCommand(message)
    local trimmedMessage = DeathpoolUI.TrimText(message) or ""
    local loweredMessage = string.lower(trimmedMessage)

    return {
        raw = trimmedMessage,
        lowered = loweredMessage,
        command = string.match(loweredMessage, "^(%S+)") or "",
    }
end

local function PrintSlashHelp()
    Print("Commands: /deathpool show, /deathpool hide, /deathpool toggle, /deathpool minimap")
    Print("Windows: /deathpool log, /deathpool demo, /deathpool showincombat")
    Print("Debug: /deathpool debug, /deathpool testdeath, /deathpool debugdeath <deathstring>")
    Print("Dangerous: /deathpool resetintro, /deathpool reset")
end

---@param hidden boolean
local function SetMainWindowHidden(hidden)
    local addonFrame = GetAddonFrame()
    local state = GetState()
    local mainFrame = addonFrame and addonFrame.mainFrame or nil
    if not mainFrame or not state then
        return
    end

    if hidden then
        mainFrame:Hide()
    else
        mainFrame:Show()
    end

    DeathpoolDatabase.SetHidden(state, hidden)
end

local function ToggleLogCommand()
    local addonFrame = GetAddonFrame()
    local state = GetState()
    local mainFrame = addonFrame and addonFrame.mainFrame or nil
    if not mainFrame or not state then
        return
    end

    DeathpoolUI.SetLogWindowShown(mainFrame, state, not DeathpoolUI.ShouldLogWindowBeShown(state))
end

---@return boolean
local function ToggleShowInCombatCommand()
    local enabled = DeathpoolSettings.ToggleShowInCombat()
    if enabled then
        Print("Show in combat enabled.")
    else
        Print("Show in combat disabled.")
    end

    return enabled
end

local function ToggleMinimapCommand()
    local addonFrame = GetAddonFrame()
    local state = GetState()
    local mainFrame = addonFrame and addonFrame.mainFrame or nil
    if DeathpoolUIMinimap and DeathpoolUIMinimap.ToggleHidden and mainFrame and state then
        if DeathpoolUIMinimap.ToggleHidden(mainFrame, state) then
            Print("Minimap icon disabled.")
        else
            Print("Minimap icon enabled.")
        end
    end
end

local function ShowCommand()
    SetMainWindowHidden(false)
end

local function HideCommand()
    SetMainWindowHidden(true)
end

local function DemoCommand()
    local addonFrame = GetAddonFrame()
    local mainFrame = addonFrame and addonFrame.mainFrame or nil
    if not mainFrame then
        return
    end

    if mainFrame.isCollapsed == true then
        Print("Expand the main window before using /deathpool demo.")
        return
    end

    SetMainWindowHidden(false)
    if mainFrame.introDemoController then
        mainFrame.introDemoController:Show()
    end
end

local function IntroCommand()
    local state = GetState()
    if not state then
        return
    end

    if not DeathpoolDebugState.IsEnabled() then
        Print("Intro reset requires debug mode")
        return
    end

    DeathpoolDatabase.SetHasSeenIntroDemo(state, false)
    DeathpoolDatabase.SetHasSeenFirstRun(state, false)
    Print("Introduction enabled.")
end

local function ResetCommand()
    local state = GetState()
    if not state then
        return
    end

    if not DeathpoolDebugState.IsEnabled() then
        Print("Database reset requires debug mode")
        return
    end

    DeathpoolDatabase.ResetAllState(state)
    Print("Database reset complete")
end

local function ToggleWindowCommand()
    local state = GetState()
    local addonFrame = GetAddonFrame()
    local mainFrame = addonFrame and addonFrame.mainFrame or nil
    if not mainFrame or not state then
        return
    end

    local hidden = DeathpoolDatabase.GetHidden(state)
    SetMainWindowHidden(not hidden)
end

local SLASH_COMMAND_HANDLERS = {
    show = ShowCommand,
    hide = HideCommand,
    debug = DeathpoolDebug.ToggleDebugCommand,
    log = ToggleLogCommand,
    demo = DemoCommand,
    resetintro = IntroCommand,
    reset = ResetCommand,
    showincombat = ToggleShowInCombatCommand,
    minimap = ToggleMinimapCommand,
    toggle = ToggleWindowCommand,
    [""] = ToggleWindowCommand,
    help = PrintSlashHelp,
    testdeath = DeathpoolDebug.AddTestDeath,
}

---@param addonFrame DeathpoolCommandsAddonFrame
---@param printMessage DeathpoolCommandsPrintMessage
function DeathpoolCommands.Initialize(addonFrame, printMessage)
    activeAddonFrame = addonFrame
    activePrintMessage = printMessage
end

---@param message string
function DeathpoolCommands.HandleSlashCommand(message)
    local parsedCommand = NormalizeSlashCommand(message)

    if DeathpoolDebug.IsDebugDeathCommand(parsedCommand.lowered) then
        DeathpoolDebug.HandleDebugDeathCommand(parsedCommand.raw)
        return
    end

    local handler = SLASH_COMMAND_HANDLERS[parsedCommand.command]
    if handler then
        handler()
        return
    end

    PrintSlashHelp()
end

SLASH_DEATHPOOL1 = "/deathpool"
SlashCmdList.DEATHPOOL = function(message)
    DeathpoolCommands.HandleSlashCommand(message)
end

_G.DeathpoolCommands = DeathpoolCommands

return DeathpoolCommands

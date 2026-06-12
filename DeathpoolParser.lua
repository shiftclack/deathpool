---@class DeathpoolParser
---@field BuildPatternFromFormat fun(formatString: string|nil): string|nil
---@field GetBlizzardDeathPatterns fun(): DeathpoolParserPattern[]
---@field ParseBlizzardDeathMessage fun(message: string|nil): DeathpoolParsedDeathEvent|nil
local DeathpoolParser = {}

---@class DeathpoolParserPattern
---@field name string
---@field pattern string

---@class DeathpoolParsedDeathEvent
---@field name string
---@field level integer
---@field causeType string
---@field sourceName string|nil
---@field zone string|nil
---@field server string|nil
---@field sourceMessage string
---@field isBlizzardVerified boolean

local unpack = unpack

-- Blizzard death format globals do not change during normal play, so we cache the
-- compiled matcher lists instead of rebuilding them on every death event parse.
---@type DeathpoolParserPattern[]|nil
local cachedDefaultPatterns = nil

---@param text string
---@return string|nil
local function TrimText(text)
    local trimmed = string.match(text, "^%s*(.-)%s*$")
    if trimmed == "" then
        return nil
    end

    return trimmed
end

---@param message string|nil
---@return string|nil
local function SanitizeDeathMessage(message)
    if not message or message == "" then
        return nil
    end

    local sanitizedMessage = message
    sanitizedMessage = string.gsub(sanitizedMessage, "|H.-|h(.-)|h", "%1")
    sanitizedMessage = string.gsub(sanitizedMessage, "|c%x%x%x%x%x%x%x%x", "")
    sanitizedMessage = string.gsub(sanitizedMessage, "|r", "")

    return sanitizedMessage
end

---@param text string
---@return string|nil
local function StripLeadingArticle(text)
    local stripped = TrimText(text)
    if not stripped then
        return nil
    end

    stripped = string.gsub(stripped, "^%[(.-)%]$", "%1")

    stripped = string.gsub(stripped, "^a%s+", "", 1)
    stripped = string.gsub(stripped, "^an%s+", "", 1)
    stripped = string.gsub(stripped, "^the%s+", "", 1)

    return TrimText(stripped)
end

---@param text string
---@return string
local function EscapePattern(text)
    local escaped = string.gsub(text, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    return escaped
end

---@param formatString string|nil
---@return string|nil
function DeathpoolParser.BuildPatternFromFormat(formatString)
    if not formatString or formatString == "" then
        return nil
    end

    local pattern = EscapePattern(formatString)
    pattern = string.gsub(pattern, "%%%%%d+%$s", "(.+)")
    pattern = string.gsub(pattern, "%%%%%d+%$d", "(%%d+)")
    pattern = string.gsub(pattern, "%%%%s", "(.+)")
    pattern = string.gsub(pattern, "%%%%d", "(%%d+)")

    return "^" .. pattern .. "$"
end

---@return DeathpoolParserPattern[]
function DeathpoolParser.GetBlizzardDeathPatterns()
    if cachedDefaultPatterns ~= nil then
        return cachedDefaultPatterns
    end

    local patterns = {}

    for globalName, globalValue in pairs(_G) do
        if type(globalName) == "string"
            and type(globalValue) == "string"
            and string.match(globalName, "^HARDCORE_CAUSEOFDEATH_") then
            local pattern = DeathpoolParser.BuildPatternFromFormat(globalValue)
            if pattern then
                table.insert(patterns, {
                    name = globalName,
                    pattern = pattern,
                })
            end
        end
    end

    table.sort(patterns, function(left, right)
        return left.name < right.name
    end)

    -- Parsing sits directly on the HARDCORE_DEATHS hot path, so caching the
    -- compiled pattern table keeps repeated death messages from paying the
    -- global scan and pattern-build cost each time.
    cachedDefaultPatterns = patterns

    return patterns
end

---@param ... any
---@return integer|nil
local function ExtractFirstLevel(...)
    for index = 1, select("#", ...) do
        local value = select(index, ...)
        local level = tonumber(value)
        if level then
            return level
        end
    end

    return nil
end

---@param ... any
---@return string|nil
local function ExtractFirstName(...)
    for index = 1, select("#", ...) do
        local value = select(index, ...)
        if type(value) == "string" and not tonumber(value) then
            return value
        end
    end

    return nil
end

---@param message string
---@return DeathpoolParsedDeathEvent|nil
local function ParseObservedHardcoreDeathMessage(message)
    local playerName, sourceName, zone, level, causeType

    playerName, sourceName, zone, level = string.match(
        message,
        "^%[(.-)%]%s+has been slain by (.+) in (.-)! They were level (%d+)$"
    )
    causeType = "HARDCORE_CAUSEOFDEATH_CREATURE"

    if not playerName then
        playerName, zone, level = string.match(
            message,
            "^%[(.-)%]%s+fell to their death in (.-)! They were level (%d+)$"
        )

        if playerName then
            sourceName = "Falling"
            causeType = "HARDCORE_CAUSEOFDEATH_FALL"
        end
    end

    if not playerName then
        playerName, zone, level = string.match(
            message,
            "^%[(.-)%]%s+drowned in (.-)! They were level (%d+)$"
        )

        if not playerName then
            playerName, zone, level = string.match(
                message,
                "^%[(.-)%]%s+drowned to death in (.-)! They were level (%d+)$"
            )
        end

        if playerName then
            sourceName = "Drowning"
            causeType = "HARDCORE_CAUSEOFDEATH_DROWNING"
        end
    end

    if not playerName then
        playerName, zone, level = string.match(
            message,
            "^%[(.-)%]%s+was burnt to a crisp by lava in (.-)! They were level (%d+)$"
        )

        if playerName then
            sourceName = "Burning"
            causeType = "HARDCORE_CAUSEOFDEATH_BURNING"
        end
    end

    if playerName then
        local trimmedPlayerName = TrimText(playerName)
        local parsedLevel = tonumber(level)
        if not trimmedPlayerName or not parsedLevel then
            return nil
        end

        return {
            name = trimmedPlayerName,
            level = parsedLevel,
            causeType = causeType,
            sourceName = StripLeadingArticle(sourceName),
            zone = TrimText(zone),
            sourceMessage = message,
            isBlizzardVerified = true,
        }
    end

    return nil
end

---@param message string|nil
---@return DeathpoolParsedDeathEvent|nil
function DeathpoolParser.ParseBlizzardDeathMessage(message)
    local sanitizedMessage = SanitizeDeathMessage(message)
    if not sanitizedMessage then
        return nil
    end

    local observedDeath = ParseObservedHardcoreDeathMessage(sanitizedMessage)
    if observedDeath then
        return observedDeath
    end

    for _, matcher in ipairs(DeathpoolParser.GetBlizzardDeathPatterns()) do
        local captures = { string.match(sanitizedMessage, matcher.pattern) }
        if captures[1] then
            local level = ExtractFirstLevel(unpack(captures))
            if not level then
                return nil
            end

            local name = ExtractFirstName(unpack(captures))
            if not name then
                return nil
            end

            return {
                name = name,
                level = level,
                causeType = matcher.name,
                sourceMessage = sanitizedMessage,
                isBlizzardVerified = true,
            }
        end
    end

    return nil
end

_G.DeathpoolParser = DeathpoolParser

return DeathpoolParser

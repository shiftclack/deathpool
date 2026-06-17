---@diagnostic disable: need-check-nil
---@diagnostic disable: param-type-mismatch

package.path = table.concat({
    "./?.lua",
    "./?/init.lua",
    package.path,
}, ";")

local function loadParserModule()
    package.loaded.DeathpoolParser = nil
    _G.DeathpoolParser = nil
    return require("DeathpoolParser")
end

local OFFICIAL_ENGLISH_HARDCORE_DEATH_FORMATS = {
    HARDCORE_CAUSEOFDEATH_CREATURE = "|Hplayer:%s|h[%s]|h has been slain by a %s in %s! They were level %d",
    HARDCORE_CAUSEOFDEATH_DROWNING = "|Hplayer:%s|h[%s]|h drowned to death in %s! They were level %d",
    HARDCORE_CAUSEOFDEATH_FALLING = "|Hplayer:%s|h[%s]|h fell to their death in %s! They were level %d",
    HARDCORE_CAUSEOFDEATH_FATIGUE = "|Hplayer:%s|h[%s]|h died of fatigue in %s! They were level %d",
    HARDCORE_CAUSEOFDEATH_FIRE = "|Hplayer:%s|h[%s]|h was burnt to death by fire in %s! They were level %d",
    HARDCORE_CAUSEOFDEATH_LAVA = "|Hplayer:%s|h[%s]|h was burnt to a crisp by lava in %s! They were level %d",
    HARDCORE_CAUSEOFDEATH_NONE = "|Hplayer:%s|h[%s]|h has died at level %d",
    HARDCORE_CAUSEOFDEATH_PVP = "|Hplayer:%s|h[%s]|h has been slain by %s in %s! They were level %d",
}

local function installDefaultHardcoreDeathFormats()
    for key, value in pairs(OFFICIAL_ENGLISH_HARDCORE_DEATH_FORMATS) do
        rawset(_G, key, value)
    end
end

installDefaultHardcoreDeathFormats()

local DeathpoolParser = loadParserModule()
local TestData = require("tests.fixtures.death_announcements")
local TestHelpers = require("tests.support_helpers")
local suite = TestHelpers.CreateSuite()
local assertEquals = function(actual, expected, message)
    suite:assertEquals(actual, expected, message)
end
local assertTruthy = function(value, message)
    suite:assertTruthy(value, message)
end

local function assertContains(text, needle, message)
    suite:assertContains(text, needle, message)
end

---@param overrides table<string, any>
---@param callback fun(parser: DeathpoolParser)
local function withParserGlobals(overrides, callback)
    local saved = {}

    for key, value in pairs(_G) do
        if type(key) == "string"
            and (string.match(key, "^HARDCORE_CAUSEOFDEATH_") or key == "UNKNOWN") then
            saved[key] = value
            rawset(_G, key, nil)
        end
    end

    for key, value in pairs(overrides or {}) do
        rawset(_G, key, value)
    end

    DeathpoolParser = loadParserModule()

    local ok, err = pcall(callback, DeathpoolParser)

    for key in pairs(_G) do
        if type(key) == "string"
            and (string.match(key, "^HARDCORE_CAUSEOFDEATH_") or key == "UNKNOWN") then
            rawset(_G, key, nil)
        end
    end

    for key, previousValue in pairs(saved) do
        rawset(_G, key, previousValue)
    end

    installDefaultHardcoreDeathFormats()
    DeathpoolParser = loadParserModule()

    if not ok then
        error(err)
    end
end

local function testObservedCreatureDeath()
    local death = DeathpoolParser.ParseBlizzardDeathMessage(
        "[Drakedog] has been slain by a Kobold Vermin in Elwynn Forest! They were level 6"
    )

    assertTruthy(death, "observed Hardcore creature death should parse")
    assertEquals(death.name, "Drakedog", "observed death should capture name")
    assertEquals(death.level, 6, "observed death should capture level")
    assertEquals(death.sourceName, "Kobold Vermin", "observed death should strip leading article from source")
    assertEquals(death.zone, "Elwynn Forest", "observed death should capture zone")
    assertEquals(death.causeType, "HARDCORE_CAUSEOFDEATH_CREATURE", "observed death should set creature cause type")
end

local function testColorAndHyperlinkSanitizing()
    local death = DeathpoolParser.ParseBlizzardDeathMessage(
        "|cffff2020[Drakedog]|r has been slain by "
            .. "|Hunit:Creature-0|h[a Kobold Miner]|h in Elwynn Forest! They were level 10"
    )

    assertTruthy(death, "parser should sanitize Blizzard color and hyperlink markup")
    assertEquals(death.name, "Drakedog", "sanitized message should keep player name")
    assertEquals(
        death.sourceName,
        "Kobold Miner",
        "sanitized message should keep source name"
    )
end

local function testLocalizedFormatPattern()
    withParserGlobals({
        UNKNOWN = "Unknown",
        HARDCORE_CAUSEOFDEATH_FALLING = "%s died from falling at level %d",
        HARDCORE_CAUSEOFDEATH_UNKNOWN = "Level %d death",
    }, function(parser)
        local death = parser.ParseBlizzardDeathMessage("Alamo died from falling at level 12")

        assertTruthy(death, "generic Blizzard format string should parse")
        assertEquals(death.name, "Alamo", "generic pattern should capture player name")
        assertEquals(death.level, 12, "generic pattern should capture level")
        assertEquals(death.causeType, "HARDCORE_CAUSEOFDEATH_FALLING", "generic pattern should preserve the format source")
        assertEquals(death.sourceName, "Falling", "generic pattern should infer the environmental source from the cause type")
        assertEquals(death.zone, nil, "generic pattern should not invent a zone")
    end)
end

local function testOfficialEnglishFormatPatternConversion()
    local cases = {
        {
            name = "creature",
            format = OFFICIAL_ENGLISH_HARDCORE_DEATH_FORMATS.HARDCORE_CAUSEOFDEATH_CREATURE,
            pattern = "^%[(.+)%] has been slain by a (.+) in (.+)! They were level (%d+)$",
            message = "[C] has been slain by a Kobold Vermin in Elwynn Forest! They were level 6",
        },
        {
            name = "drowning",
            format = OFFICIAL_ENGLISH_HARDCORE_DEATH_FORMATS.HARDCORE_CAUSEOFDEATH_DROWNING,
            pattern = "^%[(.+)%] drowned to death in (.+)! They were level (%d+)$",
            message = "[D] drowned to death in The Deadmines! They were level 18",
        },
        {
            name = "falling",
            format = OFFICIAL_ENGLISH_HARDCORE_DEATH_FORMATS.HARDCORE_CAUSEOFDEATH_FALLING,
            pattern = "^%[(.+)%] fell to their death in (.+)! They were level (%d+)$",
            message = "[F] fell to their death in Cliffspring Falls! They were level 16",
        },
        {
            name = "lava",
            format = OFFICIAL_ENGLISH_HARDCORE_DEATH_FORMATS.HARDCORE_CAUSEOFDEATH_LAVA,
            pattern = "^%[(.+)%] was burnt to a crisp by lava in (.+)! They were level (%d+)$",
            message = "[B] was burnt to a crisp by lava in Ironforge! They were level 13",
        },
        {
            name = "pvp",
            format = OFFICIAL_ENGLISH_HARDCORE_DEATH_FORMATS.HARDCORE_CAUSEOFDEATH_PVP,
            pattern = "^%[(.+)%] has been slain by (.+) in (.+)! They were level (%d+)$",
            message = "[S] has been slain by Playername in Theramore Isle! They were level 36",
        },
    }

    for _, case in ipairs(cases) do
        local pattern = DeathpoolParser.BuildPatternFromFormat(case.format)

        assertEquals(pattern, case.pattern, case.name .. " official format should convert to the expected pattern")
        assertTruthy(
            string.match(case.message, pattern) ~= nil,
            case.name .. " official pattern should match sanitized channel text"
        )
    end
end

local function testObservedFallingDeath()
    local death = DeathpoolParser.ParseBlizzardDeathMessage(
        "[Ming] fell to their death in Cliffspring Falls! They were level 16"
    )

    assertTruthy(death, "observed Hardcore falling death should parse")
    assertEquals(death.name, "Ming", "observed falling death should capture name")
    assertEquals(death.level, 16, "observed falling death should capture level")
    assertEquals(death.sourceName, "Falling", "observed falling death should normalize the source label")
    assertEquals(death.zone, "Cliffspring Falls", "observed falling death should capture zone")
    assertEquals(death.causeType, "HARDCORE_CAUSEOFDEATH_FALLING", "observed falling death should set the fall cause type")
end

local function testObservedDrowningDeath()
    local death = DeathpoolParser.ParseBlizzardDeathMessage(
        "[Ming] drowned to death in The Deadmines! They were level 18"
    )

    assertTruthy(death, "observed Hardcore drowning death should parse")
    assertEquals(death.name, "Ming", "observed drowning death should capture name")
    assertEquals(death.level, 18, "observed drowning death should capture level")
    assertEquals(death.sourceName, "Drowning", "observed drowning death should normalize the source label")
    assertEquals(death.zone, "The Deadmines", "observed drowning death should capture zone")
    assertEquals(
        death.causeType,
        "HARDCORE_CAUSEOFDEATH_DROWNING",
        "observed drowning death should set the drowning cause type"
    )
end

local function testDrownedInMessageDoesNotParse()
    local death = DeathpoolParser.ParseBlizzardDeathMessage(
        "[Ming] drowned in The Deadmines! They were level 18"
    )

    assertEquals(death, nil, "drowned-in wording should not parse without an official matching format")
end

local function testObservedDeathStripsNamedArticles()
    local death = DeathpoolParser.ParseBlizzardDeathMessage(
        "[Drakedog] has been slain by the Hogger in Elwynn Forest! They were level 12"
    )

    assertTruthy(death, "observed death with named mob article should parse")
    assertEquals(death.sourceName, "Hogger", "observed death should strip leading 'the' from source names")
end

local function testObservedDeathStripsBracketedArticles()
    local death = DeathpoolParser.ParseBlizzardDeathMessage(
        "[Drakedog] has been slain by [an Ancient Spider] in Tirisfal Glades! They were level 8"
    )

    assertTruthy(death, "observed death with bracketed article should parse")
    assertEquals(death.sourceName, "Ancient Spider", "observed death should strip bracketed leading articles")
end

local function testBuildPatternFromMultiplePlaceholders()
    local pattern = DeathpoolParser.BuildPatternFromFormat("%s was slain by %s at level %d")

    assertTruthy(pattern, "pattern builder should support multiple ordinary format placeholders")
    assertTruthy(
        string.match("Drakedog was slain by Hogger at level 12", pattern) ~= nil,
        "multi-placeholder patterns should match the corresponding formatted text"
    )
end

local function testBuildPatternEscapesLiteralCharacters()
    local pattern = DeathpoolParser.BuildPatternFromFormat("(%s) at level %d?")

    assertTruthy(pattern, "pattern builder should return a pattern for literal punctuation")
    assertTruthy(
        string.match("(Drakedog) at level 12?", pattern) ~= nil,
        "pattern builder should escape literal punctuation before replacing placeholders"
    )
end

local function testGetBlizzardDeathPatternsFiltersAndSorts()
    withParserGlobals({
        HARDCORE_CAUSEOFDEATH_ZETA = "%s z %d",
        HARDCORE_CAUSEOFDEATH_ALPHA = "%s a %d",
        SOME_OTHER_GLOBAL = "%s ignored %d",
        HARDCORE_CAUSEOFDEATH_BAD = "",
    }, function(parser)
        local patterns = parser.GetBlizzardDeathPatterns()

        assertEquals(#patterns, 2, "pattern list should only include non-empty Hardcore death formats")
        assertEquals(patterns[1].name, "HARDCORE_CAUSEOFDEATH_ALPHA", "pattern list should sort by global name")
        assertEquals(patterns[2].name, "HARDCORE_CAUSEOFDEATH_ZETA", "pattern list should keep later names after sorting")
    end)
end

local function testGetBlizzardDeathPatternsCachesCurrentGlobalsUntilReload()
    withParserGlobals({
        HARDCORE_CAUSEOFDEATH_ALPHA = "%s a %d",
    }, function(parser)
        local firstPatterns = parser.GetBlizzardDeathPatterns()
        rawset(_G, "HARDCORE_CAUSEOFDEATH_ZETA", "%s z %d")
        local secondPatterns = parser.GetBlizzardDeathPatterns()

        assertEquals(firstPatterns, secondPatterns, "pattern cache should reuse the compiled list after the first scan")
        assertEquals(#secondPatterns, 1, "cached pattern list should not rebuild until the parser module reloads")
    end)

    withParserGlobals({
        HARDCORE_CAUSEOFDEATH_ALPHA = "%s a %d",
        HARDCORE_CAUSEOFDEATH_ZETA = "%s z %d",
    }, function(parser)
        local rebuiltPatterns = parser.GetBlizzardDeathPatterns()

        assertEquals(#rebuiltPatterns, 2, "reloading the parser should rebuild patterns from the current globals")
    end)
end

local function testInitializeBuildsDefaultPatterns()
    withParserGlobals({
        HARDCORE_CAUSEOFDEATH_CREATURE = OFFICIAL_ENGLISH_HARDCORE_DEATH_FORMATS.HARDCORE_CAUSEOFDEATH_CREATURE,
    }, function(parser)
        assertEquals(
            parser.GetCachedDefaultPatternsSummary(),
            "cachedDefaultPatterns: not built",
            "parser initialize test should start before the cache is built"
        )

        parser.Initialize()

        local summary = parser.GetCachedDefaultPatternsSummary()
        assertContains(summary, "cachedDefaultPatterns: 1 patterns", "parser initialize should build the pattern cache")
        assertContains(
            summary,
            "HARDCORE_CAUSEOFDEATH_CREATURE",
            "parser initialize should build patterns from Hardcore death globals"
        )
    end)
end

local function testCachedDefaultPatternsSummary()
    withParserGlobals({
        HARDCORE_CAUSEOFDEATH_CREATURE = OFFICIAL_ENGLISH_HARDCORE_DEATH_FORMATS.HARDCORE_CAUSEOFDEATH_CREATURE,
    }, function(parser)
        assertEquals(
            parser.GetCachedDefaultPatternsSummary(),
            "cachedDefaultPatterns: not built",
            "pattern cache summary should report when the cache has not been built"
        )

        parser.GetBlizzardDeathPatterns()

        local summary = parser.GetCachedDefaultPatternsSummary()
        assertContains(summary, "cachedDefaultPatterns: 1 patterns", "pattern cache summary should include the cache size")
        assertContains(summary, "1. HARDCORE_CAUSEOFDEATH_CREATURE", "pattern cache summary should include pattern names")
        assertContains(
            summary,
            "roles=[1=name, 2=sourceName, 3=zone, 4=level]",
            "pattern cache summary should include capture roles"
        )
        assertContains(
            summary,
            "pattern=^%[(.+)%] has been slain by a (.+) in (.+)! They were level (%d+)$",
            "pattern cache summary should include compiled Lua patterns"
        )
    end)
end

local function testSourceMessagePreservesSanitizedText()
    local death = DeathpoolParser.ParseBlizzardDeathMessage(
        "|cffff2020[Drakedog]|r has been slain by "
            .. "|Hunit:Creature-0|h[a Kobold Miner]|h in Elwynn Forest! They were level 10"
    )

    assertContains(
        death.sourceMessage,
        "[Drakedog] has been slain by [a Kobold Miner] in Elwynn Forest! They were level 10",
        "parsed deaths should preserve the sanitized source message for debugging"
    )
end

local function testBlankMessagesReturnNil()
    assertEquals(
        DeathpoolParser.ParseBlizzardDeathMessage(""),
        nil,
        "blank messages should not parse"
    )
    assertEquals(
        DeathpoolParser.ParseBlizzardDeathMessage(nil),
        nil,
        "nil messages should not parse"
    )
end

local function testMalformedObservedMessagesReturnNil()
    local death = DeathpoolParser.ParseBlizzardDeathMessage(
        "[Drakedog] has been slain by Hogger! They were level 12"
    )

    assertEquals(death, nil, "observed messages missing the zone segment should not parse")
end

local function testUnknownMessagesReturnNil()
    local death = DeathpoolParser.ParseBlizzardDeathMessage("This is not a Hardcore death message")
    assertEquals(death, nil, "unknown message should not parse")
end

local function testFixtureParserMessages()
    for _, case in ipairs(TestData.parser_messages or {}) do
        local death = DeathpoolParser.ParseBlizzardDeathMessage(case.rawMessage)
        local label = "fixture " .. tostring(case.id)

        if case.expectNil == true then
            assertEquals(death, nil, label .. " should not parse")
        else
            assertTruthy(death, label .. " should parse")
            assertEquals(death.name, case.expected.name, label .. " should capture name")
            assertEquals(death.level, case.expected.level, label .. " should capture level")
            assertEquals(death.sourceName, case.expected.sourceName, label .. " should capture source")
            assertEquals(death.zone, case.expected.zone, label .. " should capture zone")

            -- The observed raw text alone does not reliably distinguish named mobs from player killers.
            -- Keep fixture coverage on the parsed shape while the addon remains conservative here.
            if case.category ~= "observed_pvp" then
                assertEquals(
                    death.causeType,
                    case.expected.causeType,
                    label .. " should preserve cause type"
                )
            end

            assertEquals(
                death.isBlizzardVerified,
                case.expected.isBlizzardVerified,
                label .. " should mark Blizzard verification"
            )

            if case.sanitizedSourceMessage ~= nil then
                assertContains(
                    death.sourceMessage,
                    case.sanitizedSourceMessage,
                    label .. " should preserve the sanitized source message"
                )
            end
        end
    end
end

testObservedCreatureDeath()
testColorAndHyperlinkSanitizing()
testLocalizedFormatPattern()
testOfficialEnglishFormatPatternConversion()
testObservedFallingDeath()
testObservedDrowningDeath()
testDrownedInMessageDoesNotParse()
testObservedDeathStripsNamedArticles()
testObservedDeathStripsBracketedArticles()
testBuildPatternFromMultiplePlaceholders()
testBuildPatternEscapesLiteralCharacters()
testGetBlizzardDeathPatternsFiltersAndSorts()
testGetBlizzardDeathPatternsCachesCurrentGlobalsUntilReload()
testInitializeBuildsDefaultPatterns()
testCachedDefaultPatternsSummary()
testSourceMessagePreservesSanitizedText()
testBlankMessagesReturnNil()
testMalformedObservedMessagesReturnNil()
testUnknownMessagesReturnNil()
testFixtureParserMessages()

suite:finish()

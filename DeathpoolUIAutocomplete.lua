local DeathpoolUI = _G.DeathpoolUI or {}
local DeathpoolDatabase = _G.DeathpoolDatabase

---@class DeathpoolAutocompleteButton: DeathpoolWidget
---@field rowBackground table
---@field highlight table
---@field hoverHighlight table
---@field text table

---@class DeathpoolSuggestionDropdown: DeathpoolWidget
---@field buttons DeathpoolAutocompleteButton[]
---@field background table
---@field topBorder table
---@field bottomBorder table
---@field leftBorder table
---@field rightBorder table

-- let's default to dungeons. predictable zone names that are useful to the user.
---@type string[]
local ZONE_VALUES = {
    "Blackfathom Deeps",
    "Blackrock Depths",
    "Blackrock Spire",
    "Blackwing Lair",
    "Dire Maul",
    "Gnomeregan",
    "Maraudon",
    "Molten Core",
    "Naxxramas",
    "No Zone Prediction",
    "Onyxia's Lair",
    "Ragefire Chasm",
    "Razorfen Downs",
    "Razorfen Kraul",
    "Ruins of Ahn'Qiraj",
    "Scarlet Monastery",
    "Scholomance",
    "Shadowfang Keep",
    "Stratholme",
    "Temple of Ahn'Qiraj",
    "The Deadmines",
    "The Stockade",
    "The Temple of Atal'Hakkar",
    "Uldaman",
    "Wailing Caverns",
    "Zul'Farrak",
    "Zul'Gurub",
}

-- some common prediction options
---@type string[]
DeathpoolUI.SourceList = {
    "Benny Blaanco",
    "Bloodfeather Harpy",
    "Bristleback Battleboar",
    "Bristleback Quilboar",
    "Burning Blade Cultist",
    "Burning Blade Thug",
    "Dark Iron Demolitionist",
    "Dark Iron Dwarf",
    "Dark Iron Saboteur",
    "Dark Strand Cultist",
    "Dark Strand Enforcer",
    "Dark Strand Fanatic",
    "Defias Bandit",
    "Defias Pillager",
    "Defias Rogue Wizard",
    "Defias Smuggler",
    "Defias Trapper",
    "Drowning",
    "Dust Devil",
    "Falling",
    "Felmusk Satyr",
    "Fizzle Darkstorm",
    "Forest Spider",
    "Furbolg Ursa",
    "Galak Scout",
    "Galak Wrangler",
    "Garrick Padfoot",
    "Gnarlpine Defender",
    "Gnarlpine Mystic",
    "Gnarlpine Pathfinder",
    "Goldtooth",
    "Harpy Roguefeather",
    "Harvest Watcher",
    "Hogger",
    "Kobold Geomancer",
    "Kobold Laborer",
    "Kobold Miner",
    "Kolkar Packhound",
    "Kolkar Stormer",
    "Kolkar Wrangler",
    "Kurzen Jungle Fighter",
    "Kurzen Medicine Man",
    "Kurzen Wrangler",
    "Moonrage Glutton",
    "Moonrage Sentry",
    "Moonrage White Scalebane",
    "Mor'Ladim",
    "Mosh'Ogg Brute",
    "Mosh'Ogg Spellcrafter",
    "Murloc Coastrunner",
    "Murloc Forager",
    "Murloc Oracle",
    "Murloc Tidehunter",
    "Murloc Warrior",
    "Nightbane Shadow Weaver",
    "Ogre Brute",
    "Ornery Plainstrider",
    "Plainstrider",
    "Prairie Wolf",
    "Princess",
    "Razormane Defender",
    "Razormane Quilboar",
    "Razormane Water Seeker",
    "Rockjaw Bonesnapper",
    "Scarlet Adept",
    "Scarlet Evoker",
    "Scarlet Missionary",
    "Scarlet Preserver",
    "Scarlet Warrior",
    "Shadowmaw Panther",
    "Skeletal Warrior",
    "Son of Arugal",
    "Stitches",
    "Sunscale Lashtail",
    "Sunscale Scytheclaw",
    "Swoop",
    "Twilight Fire Guard",
    "Twilight Geomancer",
    "Twilight Shadowmage",
    "Vagash",
    "Venture Co. Geologist",
    "Venture Co. Laborer",
    "Venture Co. Logger",
    "Venture Co. Mercenary",
    "Witchwing Harpy",
    "Witchwing Slayer",
    "Witherbark Headhunter",
    "Witherbark Shadow Hunter",
    "Worgen Nightbane",
}

---@type table<string, boolean>
local HighlightedSourceSuggestions = {
    ["falling"] = true,
    ["benny blaanco"] = true,
    ["vagash"] = true,
}

---@return string[]
local function BuildDefaultZoneSuggestions()
    ---@type string[]
    local zones = {}

    for _, zone in ipairs(ZONE_VALUES) do
        if zone ~= "No Zone Prediction" then
            zones[#zones + 1] = zone
        end
    end

    return zones
end

---@type string[]
DeathpoolUI.ZoneList = BuildDefaultZoneSuggestions()

---@param defaultValues string[]
---@param historyValues string[]
---@return string[]
local function MergeSuggestionValues(defaultValues, historyValues)
    local values = {}
    local seenValues = {}

    for _, value in ipairs(defaultValues) do
        if not seenValues[value] then
            seenValues[value] = true
            values[#values + 1] = value
        end
    end
    for _, value in ipairs(historyValues) do
        if not seenValues[value] then
            seenValues[value] = true
            values[#values + 1] = value
        end
    end

    table.sort(values)

    return values
end

---@param database DeathpoolCharacterState
---@return string[]
function DeathpoolUI.GetSourceSuggestions(database)
    return MergeSuggestionValues(
        DeathpoolUI.SourceList,
        DeathpoolDatabase.GetDeathHistorySourceNames(database)
    )
end

---@param database DeathpoolCharacterState
---@return string[]
function DeathpoolUI.GetZoneSuggestions(database)
    return MergeSuggestionValues(
        DeathpoolUI.ZoneList,
        DeathpoolDatabase.GetDeathHistoryZones(database)
    )
end

---@param parent table
---@return DeathpoolSuggestionDropdown
function DeathpoolUI.CreateSuggestionDropdown(parent)
    local dropdown = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    ---@cast dropdown DeathpoolSuggestionDropdown
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    dropdown:SetSize(180, 160)
    dropdown.buttons = {}
    dropdown.background = dropdown:CreateTexture(nil, "BACKGROUND")
    dropdown.background:SetAllPoints()
    dropdown.background:SetColorTexture(0.05, 0.05, 0.05, 0.96)
    dropdown.topBorder = dropdown:CreateTexture(nil, "BORDER")
    dropdown.topBorder:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 0, 0)
    dropdown.topBorder:SetPoint("TOPRIGHT", dropdown, "TOPRIGHT", 0, 0)
    dropdown.topBorder:SetHeight(1)
    dropdown.topBorder:SetColorTexture(1.0, 0.82, 0.0, 0.9)
    dropdown.bottomBorder = dropdown:CreateTexture(nil, "BORDER")
    dropdown.bottomBorder:SetPoint("BOTTOMLEFT", dropdown, "BOTTOMLEFT", 0, 0)
    dropdown.bottomBorder:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", 0, 0)
    dropdown.bottomBorder:SetHeight(1)
    dropdown.bottomBorder:SetColorTexture(1.0, 0.82, 0.0, 0.9)
    dropdown.leftBorder = dropdown:CreateTexture(nil, "BORDER")
    dropdown.leftBorder:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 0, 0)
    dropdown.leftBorder:SetPoint("BOTTOMLEFT", dropdown, "BOTTOMLEFT", 0, 0)
    dropdown.leftBorder:SetWidth(1)
    dropdown.leftBorder:SetColorTexture(0.8, 0.8, 0.8, 0.8)
    dropdown.rightBorder = dropdown:CreateTexture(nil, "BORDER")
    dropdown.rightBorder:SetPoint("TOPRIGHT", dropdown, "TOPRIGHT", 0, 0)
    dropdown.rightBorder:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", 0, 0)
    dropdown.rightBorder:SetWidth(1)
    dropdown.rightBorder:SetColorTexture(0.8, 0.8, 0.8, 0.8)
    dropdown:Hide()
    return dropdown
end

---@param frame table|nil
function DeathpoolUI.HideDropdown(frame)
    if frame and frame.dropdown then
        frame.dropdown:Hide()
    end
end

---@param frame table
---@param matches string[]
local function ShowDropdown(frame, matches)
    if not frame or not frame.dropdown or not frame.activeEditBox then
        return
    end

    ---@type DeathpoolSuggestionDropdown
    local dropdown = frame.dropdown
    ---@type DeathpoolEditBox
    local activeEditBox = frame.activeEditBox
    local visibleCount = math.min(#matches, 10)

    if visibleCount <= 0 then
        DeathpoolUI.HideDropdown(frame)
        return
    end

    dropdown:ClearAllPoints()
    dropdown:SetPoint("TOPLEFT", activeEditBox, "BOTTOMLEFT", 0, -2)
    dropdown:SetPoint("RIGHT", activeEditBox, "RIGHT", 0, 0)
    dropdown:SetHeight(visibleCount * 16)
    dropdown:Show()

    for index = 1, visibleCount do
        local value = matches[index]
        local button = dropdown.buttons[index]

        if not button then
            button = CreateFrame("Button", nil, dropdown)
            ---@cast button DeathpoolAutocompleteButton
            dropdown.buttons[index] = button
            button:SetHeight(16)
            button:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 0, -((index - 1) * 16))
            button:SetPoint("RIGHT", dropdown, "RIGHT", 0, 0)
            button.rowBackground = button:CreateTexture(nil, "BACKGROUND")
            button.rowBackground:SetPoint("TOPLEFT", button, "TOPLEFT", 1, 0)
            button.rowBackground:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 0)
            button.rowBackground:SetColorTexture(0.12, 0.12, 0.12, 0.98)
            button.highlight = button:CreateTexture(nil, "BORDER")
            button.highlight:SetPoint("TOPLEFT", button, "TOPLEFT", 1, 0)
            button.highlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 0)
            button.highlight:SetColorTexture(0.78, 0.62, 0.08, 0.75)
            button.highlight:Hide()
            button.hoverHighlight = button:CreateTexture(nil, "ARTWORK")
            button.hoverHighlight:SetPoint("TOPLEFT", button, "TOPLEFT", 1, 0)
            button.hoverHighlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 0)
            button.hoverHighlight:SetColorTexture(1.0, 0.82, 0.0, 0.18)
            button.hoverHighlight:Hide()
            button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            button.text:SetPoint("LEFT", button, "LEFT", 8, 0)
            button.text:SetPoint("RIGHT", button, "RIGHT", -8, 0)
            button.text:SetJustifyH("LEFT")
        end

        button.text:SetText(value)
        button.text:SetTextColor(1.0, 1.0, 1.0)
        if frame.suggestionKind == "source"
            and HighlightedSourceSuggestions[string.lower(value)]
        then
            button.highlight:Show()
        else
            button.highlight:Hide()
        end
        button:Show()
        ---@param self DeathpoolAutocompleteButton
        button:SetScript("OnEnter", function(self)
            self.hoverHighlight:Show()
            self.text:SetTextColor(1.0, 0.93, 0.6)
        end)
        ---@param self DeathpoolAutocompleteButton
        button:SetScript("OnLeave", function(self)
            self.hoverHighlight:Hide()
            self.text:SetTextColor(1.0, 1.0, 1.0)
        end)
        button:SetScript("OnClick", function()
            if frame.activeEditBox then
                frame.isSelectingSuggestion = true
                frame.activeEditBox:SetText(value)
                frame.isSelectingSuggestion = false
            end
            DeathpoolUI.HideDropdown(frame)
            if frame.RefreshPredictionActionButtonState then
                frame:RefreshPredictionActionButtonState()
            end
        end)
    end

    for index = visibleCount + 1, #dropdown.buttons do
        if dropdown.buttons[index].highlight then
            dropdown.buttons[index].highlight:Hide()
        end
        if dropdown.buttons[index].hoverHighlight then
            dropdown.buttons[index].hoverHighlight:Hide()
        end
        dropdown.buttons[index]:Hide()
    end
end

---@param frame table|nil
---@param input string|nil
function DeathpoolUI.UpdateSuggestions(frame, input)
    ---@type string[]
    local matches = {}

    if frame and frame.isSelectingSuggestion then
        DeathpoolUI.HideDropdown(frame)
        return
    end

    if not input or input == "" or not frame or not frame.suggestionList then
        DeathpoolUI.HideDropdown(frame)
        return
    end

    local lowerInput = string.lower(input)
    for _, value in ipairs(frame.suggestionList) do
        if string.find(string.lower(value), lowerInput, 1, true) then
            table.insert(matches, value)
        end
    end

    ShowDropdown(frame, matches)
end

_G.DeathpoolUI = DeathpoolUI

return DeathpoolUI

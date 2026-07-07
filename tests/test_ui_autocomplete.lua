local UITestContext = require("tests.support_ui_test_context")
local testContext = UITestContext.Create()
local suite = testContext.suite
local Fixtures = testContext.Fixtures
local createUIContext = testContext.createUIContext
local assertEquals = testContext.assertEquals
local assertTruthy = testContext.assertTruthy

local function testAutocompleteBuildsBothListsFromCurrentDeathHistory()
    local context = createUIContext()
    local Deathpool = context.Deathpool
    local findDropdownButtonByText = context.findDropdownButtonByText

    table.insert(DeathpoolCharacterState.deathHistory, Fixtures.storedDeath({
        sourceName = "Zealous History Beast",
        zone = "Zephyr Canyon",
    }))

    Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
    Deathpool.sourceEditBox:SetText("zealous")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
    assertTruthy(
        findDropdownButtonByText(Deathpool.dropdown, "Zealous History Beast"),
        "source suggestions should query history added after UI initialization"
    )

    Deathpool.zoneEditBox:GetScript("OnEditFocusGained")(Deathpool.zoneEditBox)
    Deathpool.zoneEditBox:SetText("zephyr")
    Deathpool.zoneEditBox:GetScript("OnTextChanged")(Deathpool.zoneEditBox, true)
    assertTruthy(
        findDropdownButtonByText(Deathpool.dropdown, "Zephyr Canyon"),
        "location suggestions should query history added after UI initialization"
    )
end

local function testAutocompleteMergesHistoryWithDefaultsWithoutDuplicates()
    local context = createUIContext(Fixtures.addonDatabase({
        deathHistory = {
            Fixtures.storedDeath({
                sourceName = "Hogger",
                zone = "Uldaman",
            }),
        },
    }))
    local DeathpoolUI = context.DeathpoolUI
    local sourceSuggestions = DeathpoolUI.GetSourceSuggestions(DeathpoolCharacterState)
    local zoneSuggestions = DeathpoolUI.GetZoneSuggestions(DeathpoolCharacterState)
    local hoggerCount = 0
    local uldamanCount = 0

    for _, source in ipairs(sourceSuggestions) do
        if source == "Hogger" then
            hoggerCount = hoggerCount + 1
        end
    end
    for _, zone in ipairs(zoneSuggestions) do
        if zone == "Uldaman" then
            uldamanCount = uldamanCount + 1
        end
    end

    assertEquals(hoggerCount, 1, "historical sources should not duplicate curated defaults")
    assertEquals(uldamanCount, 1, "historical locations should not duplicate curated defaults")
end

local function testAutocompleteHidesDropdownForBlankAndNoMatches()
    local context = createUIContext()
    local Deathpool = context.Deathpool

    Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
    Deathpool.sourceEditBox:SetText("hog")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
    assertTruthy(Deathpool.dropdown:IsShown(), "typing a matching source should show the dropdown")

    Deathpool.sourceEditBox:SetText("")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
    assertEquals(Deathpool.dropdown:IsShown(), false, "blank autocomplete input should hide the dropdown")

    Deathpool.sourceEditBox:SetText("zzzz-no-match")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
    assertEquals(Deathpool.dropdown:IsShown(), false, "unmatched autocomplete input should hide the dropdown")
end

local function testAutocompleteDropdownCapsVisibleResultsAtTen()
    local context = createUIContext()
    local Deathpool = context.Deathpool

    Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
    Deathpool.sourceEditBox:SetText("r")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)

    local visibleCount = 0
    for _, button in ipairs(Deathpool.dropdown.buttons or {}) do
        if button:IsShown() then
            visibleCount = visibleCount + 1
        end
    end

    assertEquals(visibleCount, 10, "autocomplete dropdown should cap visible matches at ten rows")
end

local function testDynamicSourceSuggestionsPreserveCuratedHighlighting()
    local context = createUIContext()
    local Deathpool = context.Deathpool
    local findDropdownButtonByText = context.findDropdownButtonByText

    Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
    Deathpool.sourceEditBox:SetText("vag")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)

    local vagashButton = findDropdownButtonByText(Deathpool.dropdown, "Vagash")
    assertTruthy(vagashButton, "highlighted curated sources should remain in the dynamic list")
    assertTruthy(
        vagashButton and vagashButton.highlight:IsShown(),
        "dynamic source suggestions should preserve curated highlighting"
    )
end

local function testAutocompleteEscapeAndFocusLostHideDropdown()
    local context = createUIContext()
    local Deathpool = context.Deathpool

    Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
    Deathpool.sourceEditBox:SetText("hog")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
    assertTruthy(Deathpool.dropdown:IsShown(), "matching autocomplete input should show the dropdown before escape")

    Deathpool.sourceEditBox.hasFocus = true
    Deathpool.sourceEditBox:GetScript("OnEscapePressed")(Deathpool.sourceEditBox)
    assertEquals(Deathpool.dropdown:IsShown(), false, "escape should hide the autocomplete dropdown")
    assertEquals(Deathpool.sourceEditBox.hasFocus, false, "escape should clear focus from the active edit box")

    Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
    Deathpool.sourceEditBox:SetText("hog")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
    assertTruthy(Deathpool.dropdown:IsShown(), "matching autocomplete input should show the dropdown before focus loss")

    Deathpool.sourceEditBox:GetScript("OnEditFocusLost")(Deathpool.sourceEditBox)
    assertEquals(Deathpool.dropdown:IsShown(), false, "focus loss should hide the autocomplete dropdown")
end

local function testAutocompleteSelectionStaysClosedAfterProgrammaticTextChange()
    local context = createUIContext()
    local Deathpool = context.Deathpool

    Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
    Deathpool.sourceEditBox:SetText("hog")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
    assertTruthy(Deathpool.dropdown:IsShown(), "matching autocomplete input should show the dropdown before selection")

    Deathpool.dropdown.buttons[1]:GetScript("OnClick")()
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, false)

    assertEquals(Deathpool.sourceEditBox:GetText(), "Hogger", "one click should apply the chosen autocomplete value")
    assertEquals(Deathpool.dropdown:IsShown(), false, "programmatic selection text changes should not reopen a single-result dropdown")
end

testAutocompleteBuildsBothListsFromCurrentDeathHistory()
testAutocompleteMergesHistoryWithDefaultsWithoutDuplicates()
testAutocompleteHidesDropdownForBlankAndNoMatches()
testAutocompleteDropdownCapsVisibleResultsAtTen()
testDynamicSourceSuggestionsPreserveCuratedHighlighting()
testAutocompleteEscapeAndFocusLostHideDropdown()
testAutocompleteSelectionStaysClosedAfterProgrammaticTextChange()

suite:finish()

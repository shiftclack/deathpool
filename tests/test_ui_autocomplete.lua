local UITestContext = require("tests.support_ui_test_context")
local testContext = UITestContext.Create()
local suite = testContext.suite
local Fixtures = testContext.Fixtures
local createUIContext = testContext.createUIContext
local assertEquals = testContext.assertEquals
local assertTruthy = testContext.assertTruthy

local function testAutocompleteLearnsAndDedupesZones()
    local context = createUIContext(Fixtures.addonDatabase({
        learnedZones = {
            "Westfall",
            "Ashenvale",
            "Westfall",
        },
    }))
    local DeathpoolUI = context.DeathpoolUI

    DeathpoolUI.InitializeSuggestionLists(DeathpoolCharacterState)

    local westfallCount = 0
    for _, zone in ipairs(DeathpoolUI.ZoneList) do
        if zone == "Westfall" then
            westfallCount = westfallCount + 1
        end
    end

    assertEquals(westfallCount, 1, "suggestion list initialization should dedupe learned zones")
    assertTruthy(DeathpoolCharacterState.learnedZones ~= nil, "suggestion list initialization should preserve learned zone storage")
end

local function testRegisterObservedZoneTrimsAndIgnoresBlankInput()
    local context = createUIContext(Fixtures.addonDatabase({
        learnedZones = {},
    }))
    local DeathpoolUI = context.DeathpoolUI

    DeathpoolUI.InitializeSuggestionLists(DeathpoolCharacterState)
    DeathpoolUI.RegisterObservedZone("  Westfall  ", DeathpoolCharacterState)
    DeathpoolUI.RegisterObservedZone(" ", DeathpoolCharacterState)
    DeathpoolUI.RegisterObservedZone(nil, DeathpoolCharacterState)

    assertEquals(DeathpoolCharacterState.learnedZones[1], "Westfall", "register observed zone should trim surrounding whitespace")
    assertEquals(#DeathpoolCharacterState.learnedZones, 1, "register observed zone should ignore blank or nil zones")
end

local function testAutocompleteHidesDropdownForBlankAndNoMatches()
    local context = createUIContext()
    local Deathpool = context.Deathpool

    Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
    Deathpool.sourceEditBox:SetText("hog")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox)
    assertTruthy(Deathpool.dropdown:IsShown(), "typing a matching source should show the dropdown")

    Deathpool.sourceEditBox:SetText("")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox)
    assertEquals(Deathpool.dropdown:IsShown(), false, "blank autocomplete input should hide the dropdown")

    Deathpool.sourceEditBox:SetText("zzzz-no-match")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox)
    assertEquals(Deathpool.dropdown:IsShown(), false, "unmatched autocomplete input should hide the dropdown")
end

local function testAutocompleteDropdownCapsVisibleResultsAtTen()
    local context = createUIContext()
    local Deathpool = context.Deathpool

    Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
    Deathpool.sourceEditBox:SetText("r")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox)

    local visibleCount = 0
    for _, button in ipairs(Deathpool.dropdown.buttons or {}) do
        if button:IsShown() then
            visibleCount = visibleCount + 1
        end
    end

    assertEquals(visibleCount, 10, "autocomplete dropdown should cap visible matches at ten rows")
end

local function testAutocompleteEscapeAndFocusLostHideDropdown()
    local context = createUIContext()
    local Deathpool = context.Deathpool

    Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
    Deathpool.sourceEditBox:SetText("hog")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox)
    assertTruthy(Deathpool.dropdown:IsShown(), "matching autocomplete input should show the dropdown before escape")

    Deathpool.sourceEditBox.hasFocus = true
    Deathpool.sourceEditBox:GetScript("OnEscapePressed")(Deathpool.sourceEditBox)
    assertEquals(Deathpool.dropdown:IsShown(), false, "escape should hide the autocomplete dropdown")
    assertEquals(Deathpool.sourceEditBox.hasFocus, false, "escape should clear focus from the active edit box")

    Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
    Deathpool.sourceEditBox:SetText("hog")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox)
    assertTruthy(Deathpool.dropdown:IsShown(), "matching autocomplete input should show the dropdown before focus loss")

    Deathpool.sourceEditBox:GetScript("OnEditFocusLost")(Deathpool.sourceEditBox)
    assertEquals(Deathpool.dropdown:IsShown(), false, "focus loss should hide the autocomplete dropdown")
end

local function testAutocompleteSelectionSuppressesRecursiveUpdates()
    local context = createUIContext()
    local Deathpool = context.Deathpool

    Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
    Deathpool.sourceEditBox:SetText("hog")
    Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox)
    assertTruthy(Deathpool.dropdown:IsShown(), "matching autocomplete input should show the dropdown before selection")

    Deathpool.dropdown.buttons[1]:GetScript("OnClick")()

    assertEquals(Deathpool.dropdown:IsShown(), false, "selecting an autocomplete suggestion should end with the dropdown hidden")
    assertEquals(Deathpool.isSelectingSuggestion, false, "autocomplete suggestion clicks should clear the temporary selection guard")
    assertEquals(Deathpool.sourceEditBox:GetText(), "Hogger", "selecting an autocomplete suggestion should still apply the chosen value")
end

testAutocompleteLearnsAndDedupesZones()
testRegisterObservedZoneTrimsAndIgnoresBlankInput()
testAutocompleteHidesDropdownForBlankAndNoMatches()
testAutocompleteDropdownCapsVisibleResultsAtTen()
testAutocompleteEscapeAndFocusLostHideDropdown()
testAutocompleteSelectionSuppressesRecursiveUpdates()

suite:finish()

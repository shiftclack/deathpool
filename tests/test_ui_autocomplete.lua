local assert = require("luassert")
describe("Autocomplete UI", function()
    local UITestContext = require("tests.support_ui_test_context")
    local testContext
    local Fixtures
    local createUIContext
    local env

    before_each(function()
        testContext = UITestContext.Create()
        Fixtures = testContext.Fixtures
        env = nil
        createUIContext = function(...)
            local context = testContext.createUIContext(...)
            env = context.env
            return context
        end
    end)

    describe("suggestion sources", function()
        it("builds source and zone lists from current death history", function()
            local context = createUIContext()
            local Deathpool = context.Deathpool
            local findDropdownButtonByText = context.findDropdownButtonByText

            table.insert(env.DeathpoolCharacterState.deathHistory, Fixtures.storedDeath({
                sourceName = "Zealous History Beast",
                zone = "Zephyr Canyon",
            }))

            Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
            Deathpool.sourceEditBox:SetText("zealous")
            Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
            assert.is_truthy(
                findDropdownButtonByText(Deathpool.dropdown, "Zealous History Beast"),
                "source suggestions should query history added after UI initialization"
            )

            Deathpool.zoneEditBox:GetScript("OnEditFocusGained")(Deathpool.zoneEditBox)
            Deathpool.zoneEditBox:SetText("zephyr")
            Deathpool.zoneEditBox:GetScript("OnTextChanged")(Deathpool.zoneEditBox, true)
            assert.is_truthy(
                findDropdownButtonByText(Deathpool.dropdown, "Zephyr Canyon"),
                "location suggestions should query history added after UI initialization"
            )
        end)

        it("merges history with defaults without duplicates", function()
            local context = createUIContext(Fixtures.addonDatabase({
                deathHistory = {
                    Fixtures.storedDeath({
                        sourceName = "Hogger",
                        zone = "Uldaman",
                    }),
                },
            }))
            local sourceSuggestions = context.DeathpoolUIAutocomplete.GetSourceSuggestions(env.DeathpoolCharacterState)
            local zoneSuggestions = context.DeathpoolUIAutocomplete.GetZoneSuggestions(env.DeathpoolCharacterState)
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

            assert.equals(1, hoggerCount, "historical sources should not duplicate curated defaults")
            assert.equals(1, uldamanCount, "historical locations should not duplicate curated defaults")
        end)

        it("preserves curated highlighting for dynamic source suggestions", function()
            local context = createUIContext()
            local Deathpool = context.Deathpool
            local findDropdownButtonByText = context.findDropdownButtonByText

            Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
            Deathpool.sourceEditBox:SetText("vag")
            Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)

            local vagashButton = findDropdownButtonByText(Deathpool.dropdown, "Vagash")
            assert.is_truthy(vagashButton, "highlighted curated sources should remain in the dynamic list")
            assert.is_truthy(
                vagashButton and vagashButton.highlight:IsShown(),
                "dynamic source suggestions should preserve curated highlighting"
            )
        end)
    end)

    describe("matching and visibility", function()
        it("hides the dropdown for blank and unmatched input", function()
            local context = createUIContext()
            local Deathpool = context.Deathpool

            Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
            Deathpool.sourceEditBox:SetText("hog")
            Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
            assert.is_truthy(Deathpool.dropdown:IsShown(), "typing a matching source should show the dropdown")

            Deathpool.sourceEditBox:SetText("")
            Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
            assert.equals(false, Deathpool.dropdown:IsShown(), "blank autocomplete input should hide the dropdown")

            Deathpool.sourceEditBox:SetText("zzzz-no-match")
            Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
            assert.equals(false, Deathpool.dropdown:IsShown(), "unmatched autocomplete input should hide the dropdown")
        end)

        it("caps visible results at ten", function()
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

            assert.equals(10, visibleCount, "autocomplete dropdown should cap visible matches at ten rows")
        end)
    end)

    describe("dismissal and selection", function()
        it("hides the dropdown on escape and focus loss", function()
            local context = createUIContext()
            local Deathpool = context.Deathpool

            Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
            Deathpool.sourceEditBox:SetText("hog")
            Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
            assert.is_truthy(Deathpool.dropdown:IsShown(), "matching autocomplete input should show the dropdown before escape")

            Deathpool.sourceEditBox.hasFocus = true
            Deathpool.sourceEditBox:GetScript("OnEscapePressed")(Deathpool.sourceEditBox)
            assert.equals(false, Deathpool.dropdown:IsShown(), "escape should hide the autocomplete dropdown")
            assert.equals(false, Deathpool.sourceEditBox.hasFocus, "escape should clear focus from the active edit box")

            Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
            Deathpool.sourceEditBox:SetText("hog")
            Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
            assert.is_truthy(Deathpool.dropdown:IsShown(), "matching autocomplete input should show the dropdown before focus loss")

            Deathpool.sourceEditBox:GetScript("OnEditFocusLost")(Deathpool.sourceEditBox)
            assert.equals(false, Deathpool.dropdown:IsShown(), "focus loss should hide the autocomplete dropdown")
        end)

        it("keeps the dropdown closed after programmatic selection", function()
            local context = createUIContext()
            local Deathpool = context.Deathpool

            Deathpool.sourceEditBox:GetScript("OnEditFocusGained")(Deathpool.sourceEditBox)
            Deathpool.sourceEditBox:SetText("hog")
            Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, true)
            assert.is_truthy(Deathpool.dropdown:IsShown(), "matching autocomplete input should show the dropdown before selection")

            Deathpool.dropdown.buttons[1]:GetScript("OnClick")()
            Deathpool.sourceEditBox:GetScript("OnTextChanged")(Deathpool.sourceEditBox, false)

            assert.equals("Hogger", Deathpool.sourceEditBox:GetText(), "one click should apply the chosen autocomplete value")
            assert.equals(false, Deathpool.dropdown:IsShown(), "programmatic selection text changes should not reopen a single-result dropdown")
        end)
    end)
end)

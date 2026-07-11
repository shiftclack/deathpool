# AGENTS.md file

## Overview of the Deathpool project

- This is an addon for _World of Warcraft Classic Hardcore_
- The addon's short name is "Deathpool", and its full name is "Hardcore Death Pool"
- Developed in WoW Lua 5.1

### Source of truth

When project guidance conflicts, use this order of precedence:

1. The user's explicit request in the current task
2. [AGENTS.md](AGENTS.md)
3. Documentation in the [docs](docs) directory.
4. Existing tested behavior in the codebase
5. [README.md](README.md) examples, mockups, and older notes

### Status of project

The project is currently in its early stages. We want to keep things focused on the specific features 
we need while not worrying about backward compatibility yet.

### Goals

- Provide an experience where the user (a WoW hardcore player) can predict attributes of upcoming deaths of other players
- There will be a points system where the player is awarded points for correctly guessing deaths
- These predictions involve no exchange of any in-game items or currency of any kind
- The UI should reflect the built-in WoW UI style, including its UI elements such as buttons and tooltips

### Technical goals

- Build a project that works well with coding agents
- Utilize unit tests extensively, but not in a brittle way
- Maintain a codebase that is easy for Lua beginners to understand

### Compatibility

Deathpool is intended *only* for official WoW Hardcore Classic realms. It does not support Retail WoW.

## Common commands

The `Makefile` should wrap all common commands used by the human developer and coding agent.

- `make check` run all tests and linting
- `make coverage-summary` print out the `luacov` code coverage summary
- `make install` will install the addon files to a local Windows WoW installation
- `make dist` to build a .zip file for distribution
- `make deps` to install required build dependencies in Windows

Note: `make build-ci`, `dist-ci`, `deps-ci`, and `clean-ci` are UNIX compatible equivalents to the Windows commands.

## Game

For documentation on the game, refer to [docs/game.md](docs/game.md).

## UI

For documentation on the UI, refer to [docs/ui.md](docs/ui.md).

## Repo layout

Top-level directories:
- `docs/` contains project documentation such as `docs/game.md` and `docs/ui.md`
- `dist/` contains distribution/build output files; do not test or lint
- `libs/` contains bundled third-party libraries used by the addon; do not test or lint
- `media/` contains addon media such as textures
- `tests/` contains the Lua test harness, fixtures, and test suites

Top-level addon files:
- `Deathpool.lua` should stay thin and focus on addon bootstrapping, event wiring, and coordination
- `DeathpoolCommands.lua` should contain slash command parsing, help text, and slash command handlers
- `DeathpoolConstants.lua` is the central source for gameplay, scoring, and storage constants
- `DeathpoolDebug.lua` owns debug state, logging helpers, and debug window coordination
- `DeathpoolDatabase.lua` owns SavedVariables defaults, normalization, and database accessors
- `DeathpoolParser.lua` should contain Blizzard death message parsing and sanitizing only
- `DeathpoolLogic.lua` is the shared logic namespace/bootstrap file
- `DeathpoolLogicPrediction.lua` should contain prediction related logic
- `DeathpoolLogicScoring.lua` should contain score logic
- `DeathpoolLogicDeaths.lua` should contain death logic
- `DeathpoolLogicState.lua` should contain database-backed gameplay state transitions
- `DeathpoolMigration.lua` should contain code for migrating SavedVariables on startup
- `DeathpoolSettings.lua` should contain settings actions and controller-owned Blizzard settings side effects
- `DeathpoolSetup.lua` should contain setup state, setup actions, and controller-owned Blizzard setup side effects
- `DeathpoolAnnouncements.lua` should contain controller-owned guild and local announcement behavior
- `DeathpoolDemo.lua` should contain controller-owned intro demo session lifecycle, playback, and dismissal orchestration
- `DeathpoolUI.lua` should contain shared UI constants, layout values, common widget helpers, and top-level frame creation
- `DeathpoolUITooltip.lua` should contain standardized tooltip building for death rows and prediction previews
- `DeathpoolUIDeathLogList.lua` should contain reusable death log row creation and row refresh behavior
- `DeathpoolUIAutocomplete.lua` should contain history-backed suggestion lists and dropdown behavior for prediction inputs
- `DeathpoolUIHelp.lua` should contain the help window
- `DeathpoolUISetup.lua` should contain the setup window
- `DeathpoolUIMode.lua` should contain the resolver for the current UI mode
- `DeathpoolUIRefresh.lua` should coordinate refreshing windows and projecting model state into widgets
- `DeathpoolUILog.lua` should contain the historical death log window
- `DeathpoolUISettings.lua` should contain the Blizzard Settings panel
- `DeathpoolUIDemo.lua` should contain scripted intro/demo data and inline onboarding callouts for the main window
- `DeathpoolUIDebug.lua` should contain the debugging UI window
- `DeathpoolUIMain.lua` should contain the main prediction UI window composition and collapsed/expanded interactions
- `DeathpoolUIMinimap.lua` should contain all minimap button integration, feature-flagging, and LibDBIcon or broker specific code

Unit tests are supported:
- `tests/support_fixtures.lua` contains our test fixtures
- `tests/support_helpers.lua` contains our test helpers
- `tests/support_logic_helpers.lua` contains shared logic test helpers
- `tests/support_logic_loader.lua` loads logic modules in the test harness
- `tests/support_ui_harness.lua` is a ui test harness
- `tests/support_ui_test_context.lua` contains shared UI test context helpers
- `tests/test_addon.lua` covers addon/controller behavior
- `tests/test_logic.lua` covers shared game logic behavior
- `tests/test_logic_database.lua`, `tests/test_logic_database_state.lua`, and `tests/test_logic_database_retention.lua` cover database behavior and retention rules
- `tests/test_logic_deaths.lua` covers stored death helpers
- `tests/test_logic_prediction.lua` covers prediction normalization and matching helpers
- `tests/test_logic_scoring.lua` covers scoring rules
- `tests/test_migration.lua` covers SavedVariables migrations
- `tests/test_minimap.lua` covers minimap integration behavior
- `tests/test_parser.lua` parses death events
- `tests/test_ui.lua`, `tests/test_ui_autocomplete.lua`, `tests/test_ui_demo.lua`, and `tests/test_ui_interactions.lua` cover UI behavior

Support files:
- `Makefile` should contain reusable commands for building, testing and static analysis. It should be compatible with Windows systems for development and Linux for CI.
- `.luacheckrc` should contain our `luacheck` configuration. Keep changes focused and only update it when project lint rules or recognized WoW globals genuinely need to change
- `luacov.*.out` contain `luacheck` output
- `Deathpool.toc` and `Deathpool_Vanilla.toc` are the WoW TOC files for this project that control file load order

### .toc files

When adding new files, they must be added to two `.toc` files in order for the game to load them. Order is important. They are:

1. `Deathpool.toc`
2. `Deathpool_Vanilla.toc`

### Model, View Controller (MVC)

- Treat `DeathpoolDatabase.lua` and `DeathpoolLogic*.lua` as the domain/model layer. They own SavedVariables shape, defaulting, normalization, querying, sorting, and gameplay state transitions.
- Treat `DeathpoolUI*.lua` as the view layer. UI code should read model state through model APIs and update widgets, but should not directly modify the database state, sort model collections, or implement gameplay rules.
- Treat `Deathpool.lua` as a thin controller/coordinator. It should react to WoW events and slash commands, call into model code, and ask the UI to refresh.
- If code is asking `if DeathpoolCharacterState then ...` or building fallback tables in UI code, that is usually a sign the responsibility belongs back in the model layer.

## Lua

### Environments

There are three environments we develop for:
- WoW Lua 5.1 in-game (where we ship code)
- Windows running Lua 5.1 for local development/debugging
- Linux running Lua 5.1 for testing/building in GitHub Actions CI

### Compatibility

- Do not attempt to be forward-compatible with newer versions of Lua
- It's better to only support 5.1 for the sake of simplicity and low likelihood of a WoW upgrade in the future
- Do not unnecessarily add shims for backward compatibility without explicit instructions
- Do not use `require()` anywhere in the addon code as its not supported by WoW Lua. The only exception are unit tests in the `tests/` directory
- Only use Blizzard APIs that are available to Classic-era addons
- Do not invent APIs or assume Retail-only helpers exist in Classic
- No runtime code loading
- No external I/O
- All dependencies are known and ordered at load time (`.toc` files)

### Parsing behavior

The death feed parser is intentionally conservative. The addon listens only to `CHAT_MSG_CHANNEL` messages from the `hardcoredeaths` channel and parses Blizzard death announcement text plus localized Blizzard `HARDCORE_CAUSEOFDEATH_*` format strings where available. Do not, under any circumstances, communicate with or parse data from other addons such as Deathlog or the Hardcore addon! (Parsing debug data for development is acceptable.)

- Death rows are populated only from the official Blizzard death announcements channel payload.
- The addon does not attempt `/who` lookups or any other follow-up enrichment for guild, race, or class.

### Use of third party libraries

Unrestrained use of third party libraries is prohibited. They should not be introduced, or used, without specific, unambiguous, clear instructions.
The current libraries are explicitly permitted:

- Minimap
    - The Minimap icon uses LibDBIcon for compatibility with addons such as Titan Panel and Leatrix. 
    - The use of these libraries should be strictly confined to `DeathpoolUIMinimap.lua`
    - Maintain the ability to easily remove them at any time.
    - Permitted Libs for the Minimap
        - LibDBIcon
        - LibDataBroker
        - CallbackHandler
        - LibStub

### Prefer numbers to strings

- Use numeric multiplier values internally
- Prefer built-in math and numeric operations over string manipulation or regular expressions when calculating score or multiplier behavior
- Present the multiplier in `xN` format only in user-facing UI elements
- Do not use regular expressions when data could more easily be compared numerically

### Change style

- Prefer small, direct changes over broad refactors
- Do not introduce new modules, frameworks, or abstractions unless they clearly reduce complexity
- Keep the addon readable to a human who is still learning Lua and WoW addon development
- When in doubt, choose the simpler implementation that matches the current project style

### Nil-check contracts

- Keep `nil` guards at real boundaries: WoW event handlers, slash commands, SavedVariables/database normalization, and UI scripts that can legitimately fire before state is bound
- Inside a module, prefer explicit helper contracts over repeated defensive checks
- If one helper always normalizes inputs for the next helper, remove the downstream `nil` fallback branches and let misuse fail loudly during development
- Avoid writing the same code path to accept multiple internal shapes unless that flexibility is required by a real public caller
- If a private helper only exists for one file, prefer keeping it `local` and stricter rather than treating it like a defensive utility
- If you find UI code building fallback tables like `state = state or {}` or iterating `values or {}` deep inside private refresh/cache helpers, first ask whether the normalization belongs at the module boundary instead

### LuaLS annotations

- LuaLS is used to provide type checking via annotations
- Warnings are surfaced both in the editor UI and as part of `make check`
- When adding new functions, add LuaLS style `---@param` and `---@return` comments to specify types
- Check for existing types before adding new ones, especially for files with similar names like DeathpoolUI*.lua or DeathpoolLogic*.lua.
- Prefer being strict about parameters, it helps future developers reason about the codebase

### Lua Environment Differences (WoW vs Standard Lua)

World of Warcraft uses a restricted Lua 5.1 runtime with significant differences from standard Lua:

- **No dynamic module loading**  
  Functions like `require`, `dofile`, and `loadfile` are not available. All addon code must be loaded statically via the `.toc` file in a fixed order.

- **No filesystem or OS access**  
  Lua in WoW cannot read or write arbitrary files, execute shell commands, or access system libraries. `os.*` and `io.*` are not available.

- **No `package` system**  
  The standard Lua module system (`package.path`, `package.loaders`, etc.) is absent.

- **No `debug`**
  The `debug.*` functions are not available in WoW Lua.

- **Shared global environment**  
  All addon files execute in a shared global scope unless explicitly scoped. Namespacing via tables (e.g., `Deathpool.*`) is required to avoid collisions.

- **Event-driven execution model**  
  Code runs in response to Blizzard API events (e.g., `CHAT_MSG_CHANNEL`) rather than a traditional main loop.

- **Sandboxed and API-limited**  
  Only Blizzard-provided APIs are available. Many standard Lua libraries are partially or fully unavailable.

- **Static load order is authoritative**  
  Dependency ordering must be handled manually via the `.toc` file. There is no runtime dependency resolution.

### WoW Lua's extra functions

_If the test system doesn't have a particular function available, then mock it. Do not pollute production code with guards for the tests!_

Here are some useful functions which are specific to WoW Lua:

#### wipe()

`wipe()` is like setting `table={}`, except that it keeps the variable's internal pointer

Example:
```lua
local tab = {}
tab.Hello = "Goodbye"
print(tab.Hello) -- print "Goodbye"
tab = table.wipe(tab)
print(tab.Hello) -- print nil
```

#### date()

`date()` is a reference to the Lua `os.date` function

Example:
```lua
print(date())
Fri Jun  5 14:18:19 2026 
```

#### time()

`time()` is a reference to the Lua `os.time` function

Example:
```lua
print(time())
1779344612
```

## Static analysis

- Use `make check` to run all tests
- Linting is provided by `luacheck` (`make lint`)
- Use `lua-language-server` to check our LuaLS/EmmyLua annotations (`make luals`)
- When running into issues with `make check` around globals, check:
  - `.luacheckrc` which defines exceptions for WoW globals in the build system
  - `.luarc.json` which defines exceptions for `lua-language-server`
- If a Blizzard/WoW API is valid in Classic but tooling flags it as an undefined global, prefer updating `.luacheckrc` and `.luarc.json` over adding local aliases or other production-code workarounds just to satisfy tooling
- Do not rewrite addon code from `SomeWowApi(...)` to `local SomeWowApi = _G.SomeWowApi` solely to silence linting; reserve local aliases for real code readability or behavior reasons, not config drift

## Testing

### Test plumbing

- Do not add defensive branches for missing WoW globals only for the tests
- Do not add default values to production code only for the tests
- Prefer mocking Blizzard APIs in the test harness over checking for their availability in production code

### Test expectations

***After you make changes, always run linting and tests using `make check`.***

- If you fix a bug in parser or scoring behavior, add or update a test when practical
- Prefer unit tests for parser and logic behavior over manual-only verification
- Keep tests lightweight and runnable in the local Lua test harness
- Do not add guards to the code to cover only test scenarios!
- Consider using `assertContains()` instead of `assertEquals()` when making assertions about a long string

### Debugging

- Debugging must be performed by the user, as there is no permission for the coding agent to take control of World of Warcraft directly
- Debugging should be facilitated via a simple `make install` command which installs the addon files

## Datastores

### SavedVariables

SavedVariables is how WoW persists user configuration and data for the addon.

- The addon uses per-character SavedVariables via `DeathpoolCharacterState`
- Treat `DeathpoolCharacterState` as persistent user data
- Initialize SavedVariables through `DeathpoolDatabase.Init(DeathpoolCharacterState)` in the controller and preserve that table identity afterward
- `DeathpoolDatabase.Init`, migrations, and defaulting mutate the provided table in place and return the same table for convenience
- Do not persist debug mode in `DeathpoolCharacterState`; debug enablement is session-only state owned by `DeathpoolDebug.lua`
- When adding fields, initialize missing values defensively in `DeathpoolDatabase`
- Do not require users to delete SavedVariables for normal addon updates
- Prefer additive schema changes over breaking renames

### Migrations

- In `DeathpoolMigration.lua` we have a set of migrations for SavedVariables
- We don't want to litter the code with backward compatibility checks, so keep migration code in this file
- It is OK to still program defensively in case of corrupt data loaded from SavedVariables
- This file is currently ***empty*** until we have a v1.0 release

## Documentation hygiene

- If behavior, commands, or visible UI changes, update `AGENTS.md` when the change would otherwise surprise the next contributor. Also consider updating `docs/` files if needed 
- Do not update the `README.md` unless explicitly instructed to do so
- Prefer correcting stale docs rather than leaving contradictions behind

## Canonical patterns

### Example: Use of model
```lua
-- GOOD: use DeathpoolDatabase model
local recentDeaths = DeathpoolDatabase.GetRecentDeaths(database)

-- BAD: bypass model accessors
local recentDeaths = DeathpoolCharacterState.recentDeaths
```

### Example: UI vs Logic
```lua
-- GOOD:
logic.ApplyLockedPrediction(GetState(), BuildLockedPrediction())

-- BAD (UI leaking logic):
DeathpoolCharacterState.lockedPrediction = BuildLockedPrediction()
```

### Example: Test vs production separation
```lua
-- GOOD: override in test harness
time = function() return 24680 end

-- BAD: test-only guard in production
if not time then time = function() return 0 end end
```

### Example: SavedVariables handling
```lua
-- GOOD: Initialize through database layer
DeathpoolCharacterState = DeathpoolDatabase.Init(DeathpoolCharacterState)

-- BAD: Replacing table identity
DeathpoolCharacterState = {}
```

### Example: Controller vs state mutation
```lua
-- GOOD:
DeathpoolDatabase.SetTotalPoints(GetState(), 0)

-- BAD:
DeathpoolCharacterState.totalPoints = 0
```

### Example: function with LuaLS annotations
```lua
-- GOOD:
---@param database DeathpoolCharacterState
---@return boolean
 local function isCharacterAlive(database)
  [...]
  return true
 end

-- BAD (no annotations):
 local function isCharacterAlive(database)
  [...]
  return true
 end
```

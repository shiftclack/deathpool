DEATHPOOL_INSTALL_DIR ?= C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns\Deathpool
DEATHPOOL_INSTALL_DIR_MACOS ?= /Applications/World of Warcraft/_classic_era_/Interface/AddOns
DEATHPOOL_SOURCES := *.lua tests/*.lua
DOCKER_SRC_DIR ?= /lua
DOCKER_TEST_IMAGE ?= ghcr.io/shiftclack/lua-wow:1.1.0
LUA ?= lua
LUA_LANGUAGE_SERVER ?= lua-language-server
LUAC ?= luac
LUACHECK ?= luacheck
LUASRCDIET ?= luasrcdiet

.PHONY: all build build-ci check check-docker clean clean-ci coverage coverage-report \
	coverage-summary deps deps-ci dist dist-ci dist-docker install install-macos lint luals \
	minify-ci syntax test

all: syntax lint test build

check: syntax lint luals test

check-ci: syntax lint luals-ci test

check-docker:
	@docker run -v $(CURDIR):$(DOCKER_SRC_DIR) $(DOCKER_TEST_IMAGE) make check-ci

syntax:
	@$(LUAC) -p $(DEATHPOOL_SOURCES)

lint:
	@$(LUACHECK) $(DEATHPOOL_SOURCES)

luals:
	@lua-language-server --check .

luals-ci:
	@[ -d "${DOCKER_SRC_DIR}" ] && lua-language-server --check $(DOCKER_SRC_DIR) || lua-language-server .

test:
	@$(LUA) tests/test_addon.lua
	@$(LUA) tests/test_logic.lua
	@$(LUA) tests/test_minimap.lua
	@$(LUA) tests/test_migration.lua
	@$(LUA) tests/test_parser.lua
	@$(LUA) tests/test_ui.lua
	@$(LUA) tests/test_ui_interactions.lua
	@$(LUA) tests/test_ui_autocomplete.lua
	@$(LUA) tests/test_ui_demo.lua

coverage:
	@$(LUA) -lluacov tests/test_addon.lua
	@$(LUA) -lluacov tests/test_logic.lua
	@$(LUA) -lluacov tests/test_minimap.lua
	@$(LUA) -lluacov tests/test_migration.lua
	@$(LUA) -lluacov tests/test_parser.lua
	@$(LUA) -lluacov tests/test_ui.lua
	@$(LUA) -lluacov tests/test_ui_interactions.lua
	@$(LUA) -lluacov tests/test_ui_autocomplete.lua
	@$(LUA) -lluacov tests/test_ui_demo.lua

coverage-report: coverage
	@$(LUA) -e "require('luacov.reporter').report()"

coverage-summary: coverage-report
	@$(LUA) -e "local summary = false; for line in io.lines([[luacov.report.out]]) do if line == [[Summary]] then summary = true end; if summary then print(line) end end"

# note: does not currently minify
dist: test clean build
	@cd /D dist && zip -r Deathpool.zip Deathpool

dist-ci: test clean-ci build-ci minify-ci
	@cd dist && zip -r Deathpool.zip Deathpool

dist-docker:
	@docker run -v $(CURDIR):$(DOCKER_SRC_DIR) -e SRC_DIR=$(DOCKER_SRC_DIR) $(DOCKER_TEST_IMAGE) make dist-ci

build:
	@powershell -NoProfile -Command "New-Item -ItemType Directory -Force -Path dist,dist\Deathpool,dist\Deathpool\libs | Out-Null"
	@powershell -NoProfile -Command "Copy-Item -Recurse libs\LibStub,libs\CallbackHandler-1.0,libs\LibDataBroker-1.1,libs\LibDBIcon-1.0 dist\Deathpool\libs -Force"
	@powershell -NoProfile -Command "Copy-Item -Recurse LICENSE,*.lua,*.toc dist\Deathpool -Force"

build-ci:
	@mkdir -p dist/Deathpool
	@cp LICENSE *.lua *.toc dist/Deathpool/
	@mkdir -p dist/Deathpool/libs
	@cp -r libs/LibStub libs/CallbackHandler-1.0 libs/LibDataBroker-1.1 libs/LibDBIcon-1.0 dist/Deathpool/libs/

minify-ci:
	@bash scripts/minify.sh

clean:
	@powershell -NoProfile -Command "if (Test-Path dist) { Remove-Item -Recurse -Force dist }"
	@powershell -NoProfile -Command "if (Test-Path Deathpool.zip) { Remove-Item -Force Deathpool.zip }"

clean-ci:
	@rm -rf dist Deathpool.zip

# using scoop on windows https://scoop.sh/
deps:
	@scoop install lua-for-windows make luacheck zip unzip lua-language-server
	@luarocks install luacov
	@luarocks install luasrcdiet

deps-ci:
	@apt update
	@apt install -y lua5.1 lua-check luarocks
	@luarocks install luacov
	@luarocks install luasrcdiet

install: build
	@powershell -NoProfile -Command "if ('$(DEATHPOOL_INSTALL_DIR)' -notmatch '[\\/]Interface[\\/]AddOns[\\/]Deathpool$$') { throw 'DEATHPOOL_INSTALL_DIR must end with Interface\\AddOns\\Deathpool' }"
	@powershell -NoProfile -Command "Copy-Item -Path dist\Deathpool\* -Destination '$(DEATHPOOL_INSTALL_DIR)' -Recurse -Force"

install-macos: build-ci
	@cp -r "dist/Deathpool" "$(DEATHPOOL_INSTALL_DIR_MACOS)"
	

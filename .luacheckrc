std = "lua51"

codes = true
ranges = true
max_code_line_length = 200
max_string_line_length = 200
max_comment_line_length = 200
max_cyclomatic_complexity = 13

-- Tests intentionally stub WoW globals and use busted assertions.
files["tests/**"] = {
  std = "lua51+busted",
  max_cyclomatic_complexity = 13,
  globals = {
     "_G",
     "CloseDropDownMenus",
     "CreateFrame",
     "DEFAULT_CHAT_FRAME",
     "DeathpoolUI",
     "FauxScrollFrame_GetOffset",
     "FauxScrollFrame_OnVerticalScroll",
     "FauxScrollFrame_Update",
     "GameTooltip",
     "GetRealmName",
     "GetZoneText",
     "SlashCmdList",
     "UIDropDownMenu_AddButton",
     "UIDropDownMenu_CreateInfo",
     "UIDropDownMenu_Initialize",
     "UIDropDownMenu_SetText",
     "UIDropDownMenu_SetWidth",
     "UIParent",
     "UnitLevel",
     "UnitName",
     "date",
     "time",
  },
}

files["tests/test_minimap.lua"] = {
  globals = {
     "DeathpoolUI",
     "DeathpoolUIMinimap",
     "LibStub",
  },
}

-- Writable addon-owned globals.
globals = {
   "_G",
   "DeathpoolCharacterState",
   "DeathpoolUI",
   "SLASH_DEATHPOOL1",
}

-- Read-only WoW and Lua APIs.
read_globals = {
   "ADDON_NAME",
   "BasicFrameTemplateWithInset",
   "CloseDropDownMenus",
   "CreateFrame",
   "DEFAULT_CHAT_FRAME",
   "FauxScrollFrame_GetOffset",
   "FauxScrollFrame_OnVerticalScroll",
   "FauxScrollFrame_Update",
   "GameFontDisableSmall",
   "GameFontHighlightLarge",
   "GameFontHighlightSmall",
   "GameFontNormal",
   "GameFontNormalSmall",
   "GameTooltip",
   "GetRealmName",
   "GameMenuButtonTemplate",
   "GetZoneText",
   "HARDCORE_CAUSEOFDEATH_CREATURE",
   "InputBoxTemplate",
   "JoinChannelByName",
   "SendChatMessage",
   "SetCVar",
   "UIDropDownMenu_AddButton",
   "UIDropDownMenu_CreateInfo",
   "UIDropDownMenu_Initialize",
   "UIDropDownMenu_SetText",
   "UIDropDownMenu_SetWidth",
   "UIParent",
   "UIDropDownMenuTemplate",
   "UNKNOWN",
   "UnitLevel",
   "UnitName",
   "date",
   "pairs",
   "ipairs",
   "pcall",
   "select",
   "string",
   "table",
   "time",
   "tonumber",
   "tostring",
   "type",
   "unpack",
   "wipe",
   SlashCmdList = {
      read_only = false,
      fields = {
         DEATHPOOL = { read_only = false },
      },
   },
}

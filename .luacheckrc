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
     "LibStub",
  },
}

-- Writable addon-owned globals.
globals = {
   "DeathpoolCharacterState",
   "SLASH_DEATHPOOL1",
}

-- Read-only WoW and Lua APIs.
read_globals = {
   "CreateFrame",
   "DEFAULT_CHAT_FRAME",
   "FauxScrollFrame_GetOffset",
   "FauxScrollFrame_OnVerticalScroll",
   "FauxScrollFrame_Update",
   "GameFontHighlightLarge",
   "GameTooltip",
   "GetRealmName",
   "GetCVar",
   "GetZoneText",
   "GetChannelName",
   "IsInGuild",
   "JoinPermanentChannel",
   "SendChatMessage",
   "SetCVar",
   "UIParent",
   "UnitLevel",
   "UnitName",
   "date",
   "time",
   "wipe",
   SlashCmdList = {
      read_only = false,
      fields = {
         DEATHPOOL = { read_only = false },
      },
   },
}

std = "lua51"

codes = true
ranges = true
max_code_line_length = 200
max_string_line_length = 200
max_comment_line_length = 200
max_cyclomatic_complexity = 13

-- Tests use Busted assertions.
files["tests/**"] = {
  std = "lua51+busted",
  max_cyclomatic_complexity = 13,
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
   "FormatLargeNumber",
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
   "strtrim",
   "time",
   "wipe",
   SlashCmdList = {
      read_only = false,
      fields = {
         DEATHPOOL = { read_only = false },
      },
   },
}

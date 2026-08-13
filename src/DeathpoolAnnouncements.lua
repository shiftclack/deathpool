local _, ns = ...
---@cast ns DeathpoolNamespace

local DeathpoolAnnouncements = ns.DeathpoolAnnouncements or {}
local DeathpoolConstants = ns.DeathpoolConstants
local DeathpoolDatabase = ns.DeathpoolDatabase
ns.DeathpoolAnnouncements = DeathpoolAnnouncements

local ANNOUNCEMENT_RULES = DeathpoolConstants.ANNOUNCEMENTS
local MIN_ANNOUNCE_LEVEL = 10

---@param state DeathpoolCharacterState
---@param level integer
function DeathpoolAnnouncements.AnnouncePlayerLevelUp(state, level)
    if level % ANNOUNCEMENT_RULES.levelUpFrequency ~= 0 then
        return
    end

    if not IsInGuild() then
        return
    end

    if not DeathpoolDatabase.GetGuildAnnouncementsEnabled(state) then
        return
    end

    if not DeathpoolDatabase.GetAnnounceScoreOnLevelUp(state) then
        return
    end

    SendChatMessage(
        string.format(
            "[Hardcore Death Pool] %s has reached level %d! Their score is %s",
            UnitName("player"),
            level,
            FormatLargeNumber(DeathpoolDatabase.GetTotalPoints(state))
        ),
        "GUILD"
    )
end

---@param state DeathpoolCharacterState
---@param printMessage DeathpoolPrint
function DeathpoolAnnouncements.AnnouncePlayerDeath(state, printMessage)
    local formattedScore = FormatLargeNumber(DeathpoolDatabase.GetTotalPoints(state))
    local playerLevel = UnitLevel("player")

    printMessage("Your final score is " .. formattedScore .. ".")

    if playerLevel >= MIN_ANNOUNCE_LEVEL and
        IsInGuild() and
        DeathpoolDatabase.GetGuildAnnouncementsEnabled(state) and
        DeathpoolDatabase.GetAnnounceDeathToGuild(state)
    then
        SendChatMessage(
            string.format(
                "[Hardcore Death Pool] Final score: %s",
                formattedScore
            ),
            "GUILD"
        )
    end
end

return DeathpoolAnnouncements

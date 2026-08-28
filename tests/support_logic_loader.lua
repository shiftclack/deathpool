package.path = table.concat({
    "./src/?.lua",
    "./?.lua",
    "./?/init.lua",
    package.path,
}, ";")

local AddonLoader = require("tests.support_addon_loader")
local loader = AddonLoader.ResetDefault()

rawset(_G, "wipe", function(values)
    for key in pairs(values) do
        values[key] = nil
    end

    return values
end)

rawset(_G, "FormatLargeNumber", tostring)
rawset(_G, "strtrim", function(text)
    return (tostring(text):gsub("^%s+", ""):gsub("%s+$", ""))
end)

loader:Load("DeathpoolConstants")
loader:Load("DeathpoolMigration")
loader:Load("DeathpoolDatabase")
loader:Load("DeathpoolDebug")
rawset(_G, "GetZoneText", function()
    return "Test Logic Zone"
end)
loader:Load("DeathpoolLogic")
loader:Load("DeathpoolLogicPrediction")
loader:Load("DeathpoolLogicScoring")
loader:Load("DeathpoolLogicDeaths")
loader:Load("DeathpoolLogicState")
loader:Load("DeathpoolStats")

return {
    loader = loader,
    ns = loader.ns,
    DeathpoolConstants = loader.ns.DeathpoolConstants,
    DeathpoolDatabase = loader.ns.DeathpoolDatabase,
    DeathpoolMigration = loader.ns.DeathpoolMigration,
    DeathpoolLogic = loader.ns.DeathpoolLogic,
    DeathpoolStats = loader.ns.DeathpoolStats,
}

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

return {
    loader = loader,
    ns = loader.ns,
    DeathpoolConstants = loader.ns.DeathpoolConstants,
    DeathpoolDatabase = loader.ns.DeathpoolDatabase,
    DeathpoolLogic = loader.ns.DeathpoolLogic,
}

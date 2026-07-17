package.path = table.concat({
    "./src/?.lua",
    "./?.lua",
    "./?/init.lua",
    package.path,
}, ";")

package.loaded.DeathpoolConstants = nil
package.loaded.DeathpoolDatabase = nil
package.loaded.DeathpoolMigration = nil
package.loaded.DeathpoolDebug = nil
package.loaded.DeathpoolLogic = nil
package.loaded.DeathpoolLogicPrediction = nil
package.loaded.DeathpoolLogicScoring = nil
package.loaded.DeathpoolLogicDeaths = nil
package.loaded.DeathpoolLogicState = nil

rawset(_G, "wipe", function(values)
    for key in pairs(values) do
        values[key] = nil
    end

    return values
end)

_G.DeathpoolConstants = require("DeathpoolConstants")
_G.DeathpoolMigration = require("DeathpoolMigration")
_G.DeathpoolDatabase = require("DeathpoolDatabase")
_G.DeathpoolDebug = require("DeathpoolDebug")
rawset(_G, "GetZoneText", function()
    return "Test Logic Zone"
end)
_G.DeathpoolLogic = require("DeathpoolLogic")
require("DeathpoolLogicPrediction")
require("DeathpoolLogicScoring")
require("DeathpoolLogicDeaths")
require("DeathpoolLogicState")

return _G.DeathpoolLogic

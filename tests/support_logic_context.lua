local AddonLoader = require("tests.support_addon_loader")

local LogicContext = {}

---@param options table|nil
---@return table
function LogicContext.Create(options)
    options = options or {}
    local loader = AddonLoader.Create()
    local env = loader.env

    env.wipe = function(values)
        for key in pairs(values) do
            values[key] = nil
        end

        return values
    end

    env.FormatLargeNumber = tostring
    env.strtrim = function(text)
        return (tostring(text):gsub("^%s+", ""):gsub("%s+$", ""))
    end
    env.GetZoneText = function()
        return options.zoneText or "Test Logic Zone"
    end
    env.date = os.date
    env.time = os.time

    loader:LoadThrough("DeathpoolMigration")

    return {
        env = env,
        loader = loader,
        ns = loader.ns,
        DeathpoolConstants = loader.ns.DeathpoolConstants,
        DeathpoolDatabase = loader.ns.DeathpoolDatabase,
        DeathpoolMigration = loader.ns.DeathpoolMigration,
        DeathpoolLogic = loader.ns.DeathpoolLogic,
        DeathpoolStats = loader.ns.DeathpoolStats,
    }
end

return LogicContext

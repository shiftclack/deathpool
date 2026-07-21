local AddonLoader = {}

local DEFAULT_ADDON_NAME = "Deathpool"
local DEFAULT_SOURCE_DIR = "./src"

local defaultLoader = nil

local function buildSourcePath(sourceDir, moduleName)
    return sourceDir .. "/" .. moduleName .. ".lua"
end

local function loadModule(self, moduleName)
    if self.loaded[moduleName] then
        return self.results[moduleName]
    end

    local path = buildSourcePath(self.sourceDir, moduleName)
    local chunk, loadError = loadfile(path)
    if not chunk then
        error(loadError)
    end

    local result = chunk(self.addonName, self.ns)
    self.loaded[moduleName] = true
    self.results[moduleName] = result

    return result
end

function AddonLoader.Create(options)
    options = options or {}

    return {
        addonName = options.addonName or DEFAULT_ADDON_NAME,
        sourceDir = options.sourceDir or DEFAULT_SOURCE_DIR,
        ns = options.ns or {},
        loaded = {},
        results = {},
        Load = loadModule,
    }
end

function AddonLoader.GetDefault()
    if not defaultLoader then
        defaultLoader = AddonLoader.Create()
    end

    return defaultLoader
end

function AddonLoader.ResetDefault()
    defaultLoader = AddonLoader.Create()
    return defaultLoader
end

return AddonLoader

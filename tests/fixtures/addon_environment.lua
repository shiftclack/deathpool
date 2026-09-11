-- luacheck: globals SandboxBareGlobal
---@diagnostic disable: undefined-global

local addonName, ns = ...

SandboxBareGlobal = "bare write"
_G.SandboxExplicitGlobal = "explicit write"
ns.environmentFixtureLoaded = true

return {
    addonName = addonName,
    hasStandardType = type({}) == "table",
}

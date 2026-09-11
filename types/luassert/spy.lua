---@meta luassert.spy

-- Spies are callable tables that preserve the wrapped mock's behavior.
---@class LuassertSpy
---@overload fun(...: any): ...any
---@field clear fun(self: LuassertSpy): LuassertSpy

---@class LuassertSpyModule
---@field new fun(callback?: function): LuassertSpy
local spy = {}

return spy

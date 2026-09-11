---@meta luassert

-- Common assertions and Lua type/value checks. This module is tooling-only;
-- test files explicitly require luassert, leaving Lua's global assert intact.
---@class Luassert
---@overload fun(value: any, message?: string): any
---@field same fun(expected: any, actual: any, message?: string)
---@field equals fun(expected: any, actual: any, message?: string)
---@field is_true fun(value: any, message?: string): true
---@field is_false fun(value: any, message?: string): false
---@field is_truthy fun(value: any, message?: string)
---@field is_falsy fun(value: any, message?: string): false|nil
---@field is_nil fun(value: any, message?: string)
---@field is_boolean fun(value: any, message?: string): boolean
---@field is_number fun(value: any, message?: string): number
---@field is_table fun(value: any, message?: string): table
---@field is_function fun(value: any, message?: string): function
---@field is_string fun(value: any, message?: string): string
---@field is_userdata fun(value: any, message?: string): userdata
---@field is_thread fun(value: any, message?: string): thread
---@field is_not_true fun(value: any, message?: string): any
---@field is_not_false fun(value: any, message?: string): any
---@field is_not_truthy fun(value: any, message?: string): false|nil
---@field is_not_falsy fun(value: any, message?: string): any
---@field is_not_nil fun(value: any, message?: string): any
---@field is_not_boolean fun(value: any, message?: string): any
---@field is_not_number fun(value: any, message?: string): any
---@field is_not_table fun(value: any, message?: string): any
---@field is_not_function fun(value: any, message?: string): any
---@field is_not_string fun(value: any, message?: string): any
---@field is_not_userdata fun(value: any, message?: string): any
---@field is_not_thread fun(value: any, message?: string): any
---@field matches fun(pattern: string, actual: string, init?: integer, plain?: boolean, message?: string)
---@field has_error fun(callback: fun(), expected?: any, message?: string): any
---@field is_not { equal: fun(expected: any, actual: any, message?: string) }
---@field spy fun(value: LuassertSpy, message?: string): LuassertSpyAssertions
local luassert = {}

---@class LuassertSpyAssertions
---@field was_called fun(count?: integer)
---@field was_not_called fun()
---@field was_called_with fun(...: any)

return luassert

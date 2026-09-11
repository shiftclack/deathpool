---@meta busted

---@class Busted
---@field before_each fun(callback: fun())
---@field after_each fun(callback: fun())
---@field describe fun(name: string, callback: fun())
---@field it fun(name: string, callback: fun())
local busted = {}

---@param callback fun()
---@return nil
function before_each(callback) end

---@param callback fun()
---@return nil
function after_each(callback) end

---@param name string
---@param callback fun()
---@return nil
function describe(name, callback) end

---@param name string
---@param callback fun()
---@return nil
function it(name, callback) end

return busted

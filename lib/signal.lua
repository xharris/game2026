local M = {
    _DESCRIPTION =
[[
How to use:

local signal = require 'src.signal'

signal.emit('myevent', 1, {'thing'})
signal.on('myevent', function(num, stringlist)
    return true -- remove connection
end)

]]
}

---@alias SignalFn fun(...):boolean? return true to remove the connection

---@type table<string, SignalFn[]>
local fns = {}

---@param key string
---@param ... any
M.emit = function (key, ...)
    if fns[key] then
        for i, f in lume.ripairs(fns[key]) do
            ---@cast f SignalFn
            if f(...) then
                lume.remove(fns[key], i)
            end
        end
    end
end

---@generic F : function
---@param key string
---@param fn F
M.on = function (key, fn)
    if not fns[key] then
        fns[key] = {}
    end
    lume.push(fns[key], fn)
end

return M
local M = {}

local xform = love.math.newTransform()
local push = lume.fn(love.graphics.push, 'all')
local pop = love.graphics.pop

M.pos = vec2()

M.push = function()
    push()
    xform:reset()
    local ww, wh = love.graphics.getDimensions()
    xform:translate(-M.pos.x + (ww/2), -M.pos.y + (wh/2))
    love.graphics.applyTransform(xform)
end

M.pop = function()
    pop()
end

---@param x number
---@param y number
M.to_world = function(x, y)
    return xform:inverseTransformPoint(x, y)
end

---@param x number
---@param y number
M.to_screen = function(x, y)
    return xform:transformPoint(x, y)
end

return M
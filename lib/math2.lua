---@class Transform
---@field ox? number
---@field oy? number
---@field r? number
---@field sx? number
---@field sy? number
---@field kx? number
---@field ky? number

local M = {}

local weakkeytable = require 'lib.weakkeytable'

local floor = math.floor

---@type Transform
M.default_xform = {r=0, ox=0, oy=0, sx=0, sy=0, kx=0, ky=0}

---Get position from direction and distance
---@param r? number
---@param dist? number
M.move_direction = function (r, dist)
    dist = dist or 0
    r = r or 0
    -- use sin/cos so that 0 radians == down (0,1)
    return math.sin(r) * dist, math.cos(r) * dist
end

---@type table<Entity, love.Transform>
local transforms = weakkeytable()

---@param e Entity
local get_transform = function (e)
    local xform = transforms[e]
    if not xform then
        xform = love.math.newTransform()
        transforms[e] = xform
    end
    return xform
end

M.get_transform = get_transform

---@param x number
M.round = function (x)
    return floor(x + 0.5)
end

---@param x number
---@param y number
---@param grid_width number
M.array2d_to_array1d = function (x, y, grid_width)
    return (y * grid_width + x) + 1
end

---@param idx number
---@param grid_width number
M.array1d_to_array2d = function (idx, grid_width)
    local i = idx - 1      -- undo +1
    local x = i % grid_width
    local y = math.floor(i / grid_width)
    return x, y
end


local pow = math.pow

-- Godot ease()
--
-- NATURAL `[-2, -5]` _(jumping, ui)_ </br>
-- DECEL `[0.2, 0.5]` _(landing, falling with resistance)_ </br>
-- ACCEL `[2, 4]` _(charge, takeoff)_ </br>
-- BULLET TIME `[-0.3, -0.8]` _(special effects)_
--
-- 0=0, 1=no ease
M.ease = function(x, c)
    if x < 0 then
        x = 0
    elseif x > 1.0 then
        x = 1.0
    end
    if c > 0 then
        if c < 1.0 then
            return 1.0 - pow(1.0 - x, 1.0 / c)
        else
            return pow(x, c)
        end
    elseif c < 0 then
        -- inout ease
        if (x < 0.5) then
            return pow(x * 2.0, -c) * 0.5
        else
            return (1.0 - pow(1.0 - (x - 0.5) * 2.0, -c)) * 0.5 + 0.5
        end
    else
        return 0 -- no ease (raw)
    end
end

return M
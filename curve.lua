local ease = require 'lib.math2'.ease
local lerp = lume.lerp

---@param a number
---@param b number
---@param c? number
local curve = function(a, b, c)
    ---@param x number [0, 1]
    return function(x)
        return lerp(a, b, ease(x, c or 1))
    end
end

return {
    damage = curve(3, 12),
    knockback = curve(150, 400),
    stun = curve(0.2, 3)
}
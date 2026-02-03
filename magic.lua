local M = {}

local api = require 'api'

---@param target Entity
---@param me Entity
local target_is_owner = function(target, me)
    local owner = api.entity.owner(target)
    if owner and owner == api.entity.owner(me) then
        return true
    end
    return false
end

---@type Magic
M.missile = {
    on_hit = function (target, me)
        if target_is_owner(target, me) then return end
        api.entity.take_damage(target, 1)
        -- knockback
        local knockback_dir = me.vel:norm()
        target.vel = knockback_dir * 300
        -- mini stun
        target.stun_timer = 2
    end
}

return M
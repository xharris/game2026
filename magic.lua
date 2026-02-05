local M = {}

local api = require 'api'
local tick = require 'lib.tick'
local weakkeys = require 'lib.weakkeytable'

local lerp = lume.lerp
local rad = math.rad
local random = love.math.random
local remove = lume.remove

local E = {}
M.effects = E

---@param target Entity
---@param me Entity
local target_is_owner = function(target, me)
    local owner = api.entity.owner(target)
    if owner and owner == api.entity.owner(me) then
        return true
    end
    return false
end

---@param magic string
---@param source Entity magic entity
---@param target Entity
---@param delta Vector.lua
---@param ticks_left? number
M.apply = function(magic, source, target, delta, ticks_left)
    if target_is_owner(target, source) then
        return true
    end
    ---@type Magic
    local config = E[magic]
    if not config then
        log.warn('missing magic config:', magic)
        return true
    end
    local ticks = config.ticks or 1
    ticks_left = (ticks_left or config.ticks or 1) - 1
    config.apply(target, source, delta, ticks - ticks_left)
    -- tick down
    if ticks_left > 0 then
        tick.delay(
            lume.fn(M.apply, magic, source, target, delta, ticks_left),
            config.duration and (config.duration / config.ticks) or 1
        )
    end
    if not config.pierce then
        return true
    end
end

---@param magic string[]
---@param source Entity magic entity
---@param target Entity
---@param delta Vector.lua
M.apply_all = function(magic, source, target, delta)
    if not target.hp then
        return
    end
    for i, name in lume.ripairs(magic) do
        if M.apply(name, source, target, delta) then
            table.remove(magic, i)
        end
    end
    if #magic == 0 then
        source.queue_free = true
    end
end

M.update = function(dt)

end

---@type Magic
E.missile = {
    apply = function (target, me)
        api.entity.take_damage(target, api.curve.damage(0.5))
        -- knockback
        target.vel = me.vel:norm() * api.curve.knockback(0.1)
        -- stun
        target.stun_timer = api.curve.stun(0.1)
    end
}

---@type Magic
E.fire = {
    ticks = 3,
    apply = function (target, me)
        api.entity.take_damage(target, api.curve.damage(0))
        -- random knockback
        local angle_offset = rad(lerp(-10, 10, random()))
        target.vel = target.vel:norm():rotate(angle_offset) * api.curve.knockback(0)
        -- stun
        target.stun_timer = api.curve.stun(0)
    end
}

return M
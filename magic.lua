local M = {}

local api = require 'api'
local tick = require 'lib.tick'

local lerp = lume.lerp
local rad = math.rad
local random = love.math.random

local E = {}
M.effects = E

---@param target Entity
---@param me Entity
local target_is_owner = function(target, me)
    local owner = api.entity.owner(me)
    if owner and target._id == owner._id then
        return true
    end
    return false
end

---@param magic string
---@param me Entity magic entity
---@param target Entity
---@param delta Vector.lua
---@param ticks_left? number
M.apply = function(magic, me, target, delta, ticks_left)
    if  me.item_transfer or
        me._id == target._id or
        target.tag == 'magic' or
        target_is_owner(target, me)
    then
        return false
    end
    ---@type Magic
    local config = E[magic]
    if not config then
        log.warn('missing magic config:', magic)
        return true
    end
    local ticks = config.ticks or 1
    ticks_left = (ticks_left or config.ticks or 1) - 1
    log.debug("apply", magic, "to", target.tag)
    config.apply(target, me, delta, ticks - ticks_left)
    -- tick down
    if ticks_left > 0 then
        local tick_delay = config.duration and (config.duration / config.ticks) or 1
        log.debug("tick", magic, "after", tick_delay)
        tick.delay(
            lume.fn(M.apply, magic, me, target, delta, ticks_left),
            tick_delay
        )
    end
end

---@param magic string[]
---@param source Entity magic entity
---@param target Entity
---@param delta Vector.lua
M.apply_all = function(magic, source, target, delta)
    for i, name in lume.ripairs(magic) do
        if M.apply(name, source, target, delta) then
            table.remove(magic, i)
        end
    end
    if #magic == 0 then
        source.queue_free = true
    end
end

---@type Magic
E.missile = {
    apply = function (target, me)
        api.entity.take_damage(target, api.curve.damage(0.5))
        -- knockback
        target.vel = me.vel:norm() * api.curve.knockback(0.1)
        -- stun
        target.stun_timer = api.curve.stun(0.1)
        me.queue_free = true
    end
}

---@type Magic
E.fire = {
    ticks = 3,
    apply = function (target, me, _, tick)
        api.entity.take_damage(target, api.curve.damage(0))
        local knockback_dir = me.vel:norm()
        if tick == 1 then
            -- knockback from source on first tick
            knockback_dir = (target.pos - me.pos):norm()
        else
            -- 'knockback' in direction of velocity
            local angle_offset = rad(lerp(-30, 30, random()))
            knockback_dir = target.vel:norm():rotate(angle_offset)
        end
        log.debug("knock back", knockback_dir, api.curve.knockback(0.1))
        target.vel = knockback_dir * api.curve.knockback(0.1)
        -- stun
        target.stun_timer = api.curve.stun(0.1)
        -- no pierce
        me.queue_free = true
    end
}

return M
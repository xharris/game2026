local M = {}

local signal = require 'lib.signal'
local weakkey = require 'lib.weakkeytable'

local E = {}

---@alias OnEntityPrimary fun(entity:Entity)
E.signal_primary = signal.new 'entity_primary'

---@alias OnEntityHitboxCollide fun(me:Entity, other:Entity, delta:Vector.lua)
E.signal_hitbox_collision = signal.new 'entity_hitbox_collision'

---@alias OnEntityDied fun(me:Entity, cause?:Entity)
E.signal_died = signal.new 'entity_died'

---@type Entity[]
E.entities = {}

---@type table<Entity, Entity>
local owners = weakkey()

---@param owner? Entity
E.new = function(owner)
    ---@type Entity
    local e = {
        tag = 'entity',
        pos = vec2(),
        vel = vec2(),
        accel = vec2(),
        aim_dir = vec2(),
    }
    if owner then
        owners[e] = owner
    end
    lume.push(E.entities, e)
    return e
end

E.owner = function(me)
    return owners[me]
end

---@param me Entity
---@param amt number
---@param source? Entity
E.take_damage = function(me, amt, source)
    log.debug(me.tag, 'took', amt, 'damage')
    me.hp = me.hp - amt
    if me.hp <= 0 then
        E.signal_died.emit(me, source)
        me.queue_free = true
    end
end

---@param tag EntityTag
E.find_by_tag = function(tag)
    ---@type Entity[]
    local out = {}
    for _, e in ipairs(E.entities) do
        if e.tag == tag then
            lume.push(out, e)
        end
    end
    return out
end

M.entity = E

return M
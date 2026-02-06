local A = {}

local signal = require 'lib.signal'
local weakkey = require 'lib.weakkeytable'
local copy = require 'lib.copy'

A.curve = require 'curve'

local E = {}

---@alias OnEntityPrimary fun(entity:Entity)
E.signal_primary = signal.new 'entity_primary'

---@alias OnEntityHitboxCollide fun(me:Entity, other:Entity, delta:Vector.lua)
E.signal_hitbox_collision = signal.new 'entity_hitbox_collision'

---@alias OnEntityDied fun(me:Entity, cause?:Entity)
E.signal_died = signal.new 'entity_died'

---@alias OnEntityFreed fun(me:Entity)
E.signal_freed = signal.new 'entity_freed'

---@type Entity[]
E.entities = {}

---@type Entity[]? all entities created will also be added to this table
E.group = nil

---@type table<Entity, Entity>
local owners = weakkey()

local id = 0

---@type table<string, Entity>
local entity_by_id = {}

---@param owner? Entity
E.new = function(owner)
    id = id + 1
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
    if E.group then
        lume.push(E.group, e)
    end
    e._id = tostring(id)
    entity_by_id[e._id] = e
    return e
end

---@param id string
E.get = function(id)
    return entity_by_id[id]
end

---@param me Entity
---@param set? Entity set new owner of `me`
E.owner = function(me, set)
    if set then
        owners[me] = set
    end
    return owners[me]
end

---@param me Entity
---@param amt number
---@param source? Entity
E.take_damage = function(me, amt, source)
    if not me.hp then
        log.warn(me.tag, "does not have hp component")
        return
    end
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

---@param e Entity
E.clone = function(e)
    local c = E.new(E.owner(e))
    for k, v in pairs(e) do
        if type(v) == "table" then
            c[k] = copy(v)
        elseif vector.isvector(v) then
            ---@cast v Vector.lua
            c[k] = v:clone()
        else
            c[k] = v
        end
    end
    c.queue_free = false
    return c
end

A.entity = E

local I = {}



return A
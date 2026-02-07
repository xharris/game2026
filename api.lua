local A = {}

local signal = require 'lib.signal'
local weakkey = require 'lib.weakkeytable'
local copy = require 'lib.copy'
local tick = require 'lib.tick'

local lerp = lume.lerp
local min = math.min

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

local entities_by_tag = {}

E.changed = function()
    entities_by_tag = {}
    for _, e in ipairs(E.entities) do
        if not entities_by_tag[e.tag] then
            entities_by_tag[e.tag] = {}
        end
        lume.push(entities_by_tag[e.tag], e)
    end
end

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
    E.changed()
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
---@return Entity[]
E.find_by_tag = function(tag)
    return entities_by_tag[tag] or {}
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
        elseif k ~= '_id' then
            c[k] = v
        end
    end
    c.queue_free = false
    return c
end

A.entity = E

local I = {}

---@param from Entity
---@param from_key ItemKey
---@param to Entity
---@param to_key ItemKey
I.transfer = function(from, from_key, to, to_key)
    local item = E.get(from[from_key])
    log.debug("transfer magic")
    if to[to_key] ~= nil then
        -- can't transfer if item already in that slot
        log.debug(to.tag, to_key, "is full")
        return
    end
    if item then
        item.item_transfer = {
            start_pos = item.pos:clone(),
            from = from._id,
            from_key = from_key,
            to = to._id,
            duration = 1,
            t = 0,
            to_key = to_key,
        }
    else
        log.warn("item not found", from.tag, from_key)
    end
    from[from_key] = nil
    return item
end

A.item = I

A.update = function(dt)
    for _, e in ipairs(E.entities) do
        local transfer = e.item_transfer
        if transfer then
            local from = E.get(transfer.from)
            local to = E.get(transfer.to)
            local target_pos = to.pos
            if transfer.to_key == 'item_wand' and to.aim_dir then
                target_pos = to.pos + (to.aim_dir * 30)
            end
 
            if not to or not from or not target_pos or transfer.t > transfer.duration then
                -- finished transfer
                log.debug("transfer done")
                e.item_transfer = nil
                if to then
                    -- set owner to destination entity
                    to[transfer.to_key] = e._id
                    E.owner(e, to)
                    -- restore in source entity after seconds
                    if from and e.item.restore_after_transfer then
                        log.debug("restore after", e.item.restore_after_transfer, "sec to", transfer.from_key)
                        tick.delay(function ()
                            local cloned = E.clone(e)
                            E.owner(cloned, from)
                            cloned.pos:set(transfer.start_pos)
                            cloned.vel:set(0, 0)
                            -- cloned.pos:set(from.pos)
                            from[transfer.from_key] = cloned._id
                        end, e.item.restore_after_transfer)
                    end
                else
                    log.warn("could not find transfer dest")
                end
            else
                transfer.t = transfer.t + dt
                local progress = transfer.t / min(transfer.duration, 1)
                e.pos.x = lerp(from.pos.x, target_pos.x, progress)
                e.pos.y = lerp(from.pos.y, target_pos.y, progress)
            end
        end
    end
end

return A
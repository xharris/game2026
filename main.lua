io.stdout:setvbuf("no")

math.random = love.math.random

lume = require 'lib.lume'
vector = require 'lib.vector'
log = require 'lib.log'
vec2 = vector.new
const = require 'const'

local api = require 'api'
local entity = require 'entity'
local magic = require 'magic'
local map = require 'map'
local camera = require 'camera'
local mui = require 'lib.mui'
local tick = require 'lib.tick'
local zone = require 'zone'

---@type OnEntityPrimary
local on_entity_primary = function (e)
    local projectile = api.entity.new(e)
    projectile.tag = 'magic'
    projectile.pos:set(e.pos)
    projectile.vel:set(e.aim_dir * 500)
    projectile.hitbox = {r=10}
    projectile.magic = {'fire'}
end

---@type OnEntityHitboxCollide
local on_entity_hitbox_collision = function (me, other, delta)
    if me.magic then
        magic.apply_all(me.magic, me, other, delta)
    end
end

---@type OnEntityDied
local on_entity_died = function (me, cause)
    local owner = api.entity.owner(me)
    if me.tag == 'enemy' and owner and owner.enemy_spawn then
        owner.enemy_spawn.current_alive = owner.enemy_spawn.current_alive - 1
    end
end

---@type OnEntityFreed
local on_entity_freed = function (me)
    local owner = api.entity.owner(me)
    if owner and me.item and me.item.restore_after_remove then
        -- restore item after time
        log.debug("restore", me.tag, "after", me.item.restore_after_remove)
        me.item.restore_timer = tick.delay(
            function()
                local clone = api.entity.clone(me)
                if owner.storage == me._id then
                    owner.storage = clone._ids
                end
            end,
            me.item.restore_after_remove
        )
    end
end

function love.load()
    log.serialize = lume.serialize
    log.info('load begin')

    api.entity.signal_primary.on(on_entity_primary)
    api.entity.signal_hitbox_collision.on(on_entity_hitbox_collision)
    api.entity.signal_died.on(on_entity_died)
    api.entity.signal_freed.on(on_entity_freed)

    zone.load('map.forest.init')

    local zones = api.entity.find_by_tag('zone')
    local player_spawn = lume.randomchoice(zones)
    if not player_spawn then
        log.error("could not find a player spawn")
    else
        player_spawn.zone_disabled = true
        -- add player
        local player = api.entity.new()
        player.tag = 'player'
        player.body = {r=15, weight=1}
        player.controller_id = 1
        player.pos:set(player_spawn.pos)
        player.hurtbox = {r=12}
        player.move_speed = 120
        player.camera = {weight=1}
    end

    log.info('load end')
end

function love.update(dt)
    tick.update(dt)
    zone.update(dt)
    entity.update(dt)
end

function love.draw()
    camera.push()

    entity.draw()
    love.graphics.setColor(0, 0, 0, 1)
    local gw, gh = love.graphics.getDimensions()
    love.graphics.line(0, -gh, 0, gh)
    love.graphics.line(-gw, 0, gw, 0)

    camera.pop()

end

local function error_printer(msg, layer)
	return (debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", ""))
end

function love.errorhandler(msg)
    if tostring(msg):find("stack overflow") then
        print(msg)
    else
        log.error(error_printer(msg, 2))
    end
end
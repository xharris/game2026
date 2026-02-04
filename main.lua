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

---@type OnEntityPrimary
local on_entity_primary = function (e)
    local projectile = api.entity.new(e)
    projectile.tag = 'magic'
    projectile.pos:set(e.pos)
    projectile.vel:set(e.aim_dir * 500)
    projectile.hitbox = {r=10}
    projectile.magic = {'missile'}
end

---@type OnEntityHitboxCollide
local on_entity_hitbox_collision = function (me, other, delta)
    if me.magic and other.hp then
        for i, name in lume.ripairs(me.magic) do
            ---@type Magic?
            local config = magic[name]
            if config then
                config.on_hit(other, me, delta)
                if not config.pierce then
                    table.remove(me.magic, i)
                end
            end
        end
        if #me.magic == 0 then
            me.queue_free = true
        end
    end
end

---@type OnEntityDied
local on_entity_died = function (me, cause)
    local owner = api.entity.owner(me)
    if me.tag == 'enemy' and owner and owner.enemy_spawn then
        owner.enemy_spawn.current_alive = owner.enemy_spawn.current_alive - 1
    end
end

---@type OnEntityDied
local on_entity_died = function (me, cause)
    local owner = api.entity.owner(me)
    if me.tag == 'enemy' and owner and owner.enemy_spawn then
        owner.enemy_spawn.current_alive = owner.enemy_spawn.current_alive - 1
    end
end

local created_zones = {}

---@param zone string
---@param offset? Vector.lua
local load_zone = function(zone, offset)
    local size = 16
    offset = offset or vec2()
    if created_zones[zone..tostring(offset)] then
        return
    end
    created_zones[zone..tostring(offset)] = true
    local tiles = map.load(zone, {
        filler      = '#a5a5a7',
        path        = '#ffffff',
        special     = '#d186df',
        enemy_spawn = '#fe5b59',
        zone        = '#57b9f2',
    })

    ---@type MapTile[]
    local zone_tiles = {}
    ---@type Entity[]
    local entities = {}
    for _, tile in ipairs(tiles) do
        local e = api.entity.new()
        e.pos = tile.pos * size
        e.pos = e.pos
        e.tag = tile.layer
        e.rect = {
            fill = true,
            color = tile.color,
            w=size,
            h=size,
        }
        if e.tag == 'zone' then
            lume.push(zone_tiles, tile)
        end
        if e.tag == 'enemy_spawn' then
            e.enemy_spawn = {
                enemies = {
                    {name='slime', weight=1}
                },
                every = 3,
                max_alive = 3,
            }
        end
        lume.push(entities, e)
    end

    -- offset by random zone marker
    local zone = lume.randomchoice(zone_tiles)
    if zone then
        offset = offset - (zone.pos * size)
    end
    for _, e in ipairs(entities) do
        e.pos = e.pos + offset
    end
end

function love.load()
    log.serialize = lume.serialize
    log.info('load begin')

    api.entity.signal_primary.on(on_entity_primary)
    api.entity.signal_hitbox_collision.on(on_entity_hitbox_collision)
    api.entity.signal_died.on(on_entity_died)

    load_zone('map/forest/forest.png')

    local zones = api.entity.find_by_tag('zone')
    local player_spawn = lume.randomchoice(zones)
    if not player_spawn then
        log.error("could not find a player spawn")
    else
        log.info("spawn player", player_spawn.pos)
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
    local players = api.entity.find_by_tag 'player'
    local zones = api.entity.find_by_tag 'zone'
    local enemy_spawns = api.entity.find_by_tag 'enemy_spawn'

    -- moving to new zone
    for _, p in ipairs(players) do
        for _, z in ipairs(zones) do
            local dist = (p.pos - z.pos):getmag()
            if dist < 30 then
                load_zone('map/forest/forest.png', z.pos)
            end
        end
    end

    -- enemy spawn
    for _, e in ipairs(enemy_spawns) do
        local config = e.enemy_spawn
        if config then
            if config.timer and config.timer > 0 then
                -- tick spawn timer
                config.timer = config.timer - dt
            end
            local current_alive = config.current_alive or 0
            if (not config.timer or config.timer <= 0) and current_alive < config.max_alive then
                -- spawn enemy
                local enemy = api.entity.new(e)
                enemy.tag = 'enemy'
                enemy.body = {r=15, weight=1}
                enemy.pos:set(e.pos)
                enemy.hurtbox = {r=12}
                enemy.hp = 8
                enemy.move_speed = 50
                enemy.ai = {
                    patrol_radius=200,
                    vision_radius=200,
                    patrol_cooldown=3
                }
                config.timer = config.every
                config.current_alive = current_alive + 1
                log.debug "spawn enemy"
            end
        end
    end

    -- enemy spawn
    for _, e in ipairs(enemy_spawns) do
        local config = e.enemy_spawn
        if config then
            if config.timer and config.timer > 0 then
                -- tick spawn timer
                config.timer = config.timer - dt
            end
            if (not config.timer or config.timer <= 0) and (config.current_alive or 0) < config.max_alive then
                -- spawn enemy
                local enemy = api.entity.new(e)
                enemy.tag = 'enemy'
                enemy.body = {r=15, weight=1}
                enemy.pos:set(400, 300)
                enemy.hurtbox = {r=12}
                enemy.hp = 30
                enemy.move_speed = 50
                enemy.ai = {
                    patrol_radius=200,
                    vision_radius=200,
                    patrol_cooldown=3
                }
                config.timer = config.every
                config.current_alive = config.current_alive + 1
            end
        end
    end

    entity.update(dt)
end

function love.draw()
    camera.push()

    entity.draw()

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
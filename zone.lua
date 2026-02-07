local M = {}

---@class Zone
---@field name string
---@field image string
---@field map_layers? MapLayers
---@field bg_color? string
---@field size? number
---@field special? table<string, MapSpecial>
---@field enemy_pool? Entity[]

---@class MapSpecial
---@field new fun(pos:Vector.lua, tile_size:number)

---@class LoadedZone
---@field id number
---@field name string
---@field entities Entity[]

local api = require 'api'
local map = require 'map'
local mui = require 'lib.mui'

---@type table<string, Zone>
local zones = {}

local id = 0

---@type LoadedZone[]
local loaded_zones = {}

---@type Entity[]
local enemy_pool = {}

---@param path string
---@param from_zone Entity? spawned from a zone tile
M.load = function(path, from_zone)
    -- load zone config
    ---@type Zone
    local zone = require(path)
    if not zone then
        log.error('did not find zone', path)
        return
    end
    enemy_pool = zone.enemy_pool
    zones[zone.name] = zone
    -- disable other loaded zones (except from_zone)
    for _, prev_zone in ipairs(loaded_zones) do
        if prev_zone.id ~= id and (not from_zone or prev_zone.id ~= from_zone.zone_id) then
            for _, e in ipairs(prev_zone.entities) do
                e.disabled = true
            end
        end
    end
    id = id + 1
    ---@type LoadedZone
    local loaded = {
        id = id,
        name = zone.name,
        entities = {},
    }
    lume.push(loaded_zones, loaded)
    api.entity.group = loaded.entities
    -- set bg color
    love.graphics.setBackgroundColor(lume.color(zone.bg_color or mui.BLACK))
    -- get tile data
    local tiles = map.load(zone.image, zone.map_layers or {
        filler      = '#a5a5a7',
        path        = '#ffffff',
        special     = '#d186df',
        enemy_spawn = '#fe5b59',
        zone        = '#57b9f2',
    })
    -- get starting zone tile
    ---@type MapTile[]
    local zone_tiles = {}
    for _, tile in ipairs(tiles) do
        if tile.layer == 'zone' then
            lume.push(zone_tiles, tile)
        end
    end
    local starting_zone = lume.randomchoice(zone_tiles)
    if not starting_zone then
        log.error('no zone tiles in', path)
        return
    end
    local size = zone.size or 128
    local starting_pos = starting_zone.pos * size
    -- calculate offset to align zones
    local offset = - starting_pos
    log.debug("create zone", zone.name, "at offset", offset)
    -- spawn entities from tiles
    for _, tile in ipairs(tiles) do
        if tile.layer == 'special' and zone.special then
            local name = lume.randomchoice(lume.keys(zone.special))
            ---@type MapSpecial?
            local special = zone.special[name]
            if special then
                special.new((tile.pos * size) + offset, size)
            end
            
        elseif tile.layer == 'filler' and false then
            -- TODO single entity with spritebatches (drawing each individually is expensive)
            -- fill in with entities
            for ix = 1, 6 do
                for iy = 1, 6 do
                    local e = api.entity.new()
                    local tile_pos = vec2(ix, iy) * (size/6) - (vec2(size, size) / 2)
                    e.pos = (tile.pos * size) + tile_pos + offset
                    e.rect = {
                        fill = true,
                        color = tile.color,
                        w = 5,
                        h = 5,
                    }
                end
            end
        else
            local e = api.entity.new()
            e.pos = (tile.pos * size) + offset
            e.tag = tile.layer
            e.rect = {
                fill = true,
                color = tile.color,
                w=size,
                h=size,
            }

            if e.tag == 'zone' and tile == starting_zone then
                -- new zone tiles should not trigger loads themselves
                e.zone_disabled = from_zone ~= nil
                e.zone_id = id
            end

            if e.tag == 'enemy_spawn' then
                e.enemy_spawn = {
                    every = 3,
                    max_alive = 1,
                }
            end
        end
    end
    api.entity.group = nil
end

M.update = function(dt)
    local players = api.entity.find_by_tag 'player'
    local zones = lume.clone(api.entity.find_by_tag 'zone')
    local enemy_spawns = api.entity.find_by_tag 'enemy_spawn'

    -- moving to new zone
    local zones_to_load = {}
    for _, z in ipairs(zones) do
        if not z.zone_disabled then
            for _, p in ipairs(players) do
                local dist = (p.pos - z.pos):getmag()
                if dist < 30 then
                    z.zone_disabled = true
                    lume.push(zones_to_load, z)
                    break
                end
            end
        end
    end
    
    for _, z in ipairs(zones_to_load) do
        M.load('map.forest.init', z)
    end
    
    -- enemy spawn
    for _, e in ipairs(enemy_spawns) do
        local config = e.enemy_spawn
        if config and #enemy_pool > 0 then
            if config.timer and config.timer > 0 then
                -- tick spawn timer
                config.timer = config.timer - dt
            end
            local current_alive = config.current_alive or 0
            if (not config.timer or config.timer <= 0) and current_alive < config.max_alive then
                log.debug("spawn enemy")
                local enemy_template = lume.randomchoice(enemy_pool)
                -- spawn enemy
                local spawn_pos = e.pos:clone()
                local enemy = api.entity.new(e)
                enemy.tag = 'enemy'
                -- copy template properties
                enemy.body = enemy_template.body and lume.clone(enemy_template.body) or nil
                enemy.hurtbox = enemy_template.hurtbox and lume.clone(enemy_template.hurtbox) or nil
                enemy.hitbox = enemy_template.hitbox and lume.clone(enemy_template.hitbox) or nil
                enemy.hp = enemy_template.hp
                enemy.move_speed = enemy_template.move_speed
                enemy.ai = enemy_template.ai and lume.clone(enemy_template.ai) or nil
                enemy.z = 1
                enemy.pos:set(spawn_pos)
                config.timer = config.every
                config.current_alive = current_alive + 1
                log.debug("spawn enemy", config.current_alive, "body:", enemy.body, "hurtbox:", enemy.hurtbox, "hp:", enemy.hp)
            end
        end
    end
end

return M
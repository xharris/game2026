io.stdout:setvbuf("no")

lume = require 'lib.lume'
vector = require 'lib.vector'
log = require 'lib.log'
vec2 = vector.new
const = require 'const'

local api = require 'api'
local entity = require 'entity'
local magic = require 'magic'
local map = require 'map'

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

function love.load()
    log.serialize = lume.serialize
    log.info('load begin')

    api.entity.signal_primary.on(on_entity_primary)
    api.entity.signal_hitbox_collision.on(on_entity_hitbox_collision)

    -- add player
    local player = api.entity.new()
    player.tag = 'player'
    player.body = {r=15, weight=1}
    player.controller_id = 1
    player.pos:set(30, 30)
    player.hurtbox = {r=12}
    player.friction = const.FRICTION.NORMAL
    player.move_speed = 120

    -- add enemy
    local enemy = api.entity.new()
    enemy.tag = 'enemy'
    enemy.body = {r=15, weight=1}
    enemy.pos:set(400, 300)
    enemy.hurtbox = {r=12}
    enemy.hp = 30
    -- enemy.friction = const.FRICTION.NORMAL
    enemy.move_speed = 50
    enemy.ai = {
        patrol_radius=200,
        vision_radius=200,
        patrol_cooldown=3
    }

    log.info('load end')
end

function love.update(dt)
    entity.update(dt)
end

function love.draw()
    entity.draw()
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
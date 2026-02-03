local M = {}

local mui = require 'lib.mui'
local baton = require 'lib.baton'
local signal = require 'lib.signal'
local bump = require 'lib.bump'
local weakkeys = require 'lib.weakkeytable'
local hc = require 'lib.hc'
local api = require 'api'

--[[
entity = {
    pos = {vector},
    vel = {vector},
    ase = {image, json, animation, loop}, -- always center image
    body = {shape},
    hitbox = {shape},
    hurtbox = {shape},
    hp = 10,
    aim_dir = {vector}, -- normalized
    magic_effects = {magic.type...},
    ai = {state='patrol', time_left=0},
    controller_id = 1
}
]]

---@class Shape
---@field r number
---@field weight? number

---@class Magic
---@field pierce? boolean
---@field on_hit fun(target:Entity, me:Entity, delta: Vector.lua)

---@class Entity
---@field queue_free? boolean remove from system
---@field tag string
---@field pos Vector.lua
---@field vel Vector.lua
---@field accel Vector.lua
---@field friction? number [0, 1] 1 = stop immediately
---@field max_speed? number
---@field move_speed? number move X pixels per second
---@field aim_dir Vector.lua
---@field body? Shape
---@field controller_id? number
---@field hp? number
---@field hurtbox? Shape
---@field hitbox? Shape
---@field magic? string[]

local push = lume.fn(love.graphics.push, 'all')
local pop = love.graphics.pop
local set_color = love.graphics.setColor
local circle = love.graphics.circle
local translate = love.graphics.translate
local lerp = lume.lerp
local abs = math.abs
local clamp = lume.clamp

M.world_body = hc.new(64)
M.world_hitbox = hc.new(64)

---@param size? number
local new_hc_world = function(size)
    size = size or 64
    local world = hc.new(size)
    local shapes = weakkeys()
    return {
        world = world,
        ---@param e Entity
        ---@param shape Shape
        ---@param pos? Vector.lua
        get = function(e, shape, pos)
            local body = shapes[shape]
            if not body then
                pos = pos or vec2()
                -- add to physics world
                body = world:circle(pos.x, pos.y, shape.r)
                shapes[shape] = body
            end
            body._entity = e
            return body
        end,
        ---@param shape Shape
        remove = function(shape)
            if not shape then
                return
            end
            local body = shapes[shape]
            shapes[shape] = nil
            if body then
                world:remove(body)
            end
        end,
        ---@param shape Shape
        has = function(shape)
            return shapes[shape] ~= nil
        end
    }
end

local hc_body = new_hc_world()
local hc_hitbox = new_hc_world()
local hc_hurtbox = hc_hitbox

local hitbox_hit = weakkeys()

local input = baton.new{
    controls = {
        join = {'mouse:1', 'button:a', 'axis:triggerright+', 'axis:triggerleft+'},
        -- move
        move_left = {'key:a', 'axis:leftx-'},
        move_right = {'key:d', 'axis:leftx+'},
        move_up = {'key:w', 'axis:lefty-'},
        move_down = {'key:s', 'axis:lefty+'},
        -- aim
        aim_left = {'key:left', 'axis:rightx-'},
        aim_right = {'key:right', 'axis:rightx+'},
        aim_up = {'key:up', 'axis:righty-'},
        aim_down = {'key:down', 'axis:righty+'},
        -- actions
        primary = {'mouse:1', 'button:rightshoulder', 'axis:triggerright+'},
        -- TODO dash/roll?
        -- secondary = {'mouse:2', 'button:b'},
        next = {'mouse:2', 'button:leftshoulder', 'axis:triggerleft+'},
        start = {'button:start', 'key:return'},
    },
    pairs = {
        move = {'move_left', 'move_right', 'move_up', 'move_down'},
        aim = {'aim_left', 'aim_right', 'aim_up', 'aim_down'},
    },
}

M.update = function(dt)
    input:update()
    for i, e in lume.ripairs(api.entity.entities) do
        ---@cast e Entity
        if e.queue_free then
            table.remove(api.entity.entities, i)
            hc_body.remove(e.body)
            hc_hitbox.remove(e.hitbox)
            hc_hurtbox.remove(e.hurtbox)
        else
            local movex, movey = 0, 0
            if e.controller_id then
                -- controller input
                -- move direction
                movex, movey = input:get 'move'
                -- acceleration
                e.accel.x = movex * e.move_speed
                e.accel.y = movey * e.move_speed
                -- aim direction
                local aimx, aimy = 0, 0
                if input:getActiveDevice() == 'joy' then
                    aimx, aimy = input:get 'aim'
                else
                    local mouse = vec2(love.mouse.getPosition())
                    aimx, aimy = (mouse - e.pos):unpack()
                end
                e.aim_dir:set(aimx, aimy):norm()
                -- shoot projectile
                if input:pressed 'primary' then
                    api.entity.signal_primary.emit(e)
                end
            end
            -- friction (only when not accelerating)
            if e.friction and e.accel:getmag() == 0 then
                local damping = math.pow(1 - e.friction, dt * 60)
                e.vel.x = e.vel.x * damping
                e.vel.y = e.vel.y * damping
            end
            -- apply acceleration
            e.vel = e.vel + e.accel * dt
            if e.max_speed then
                -- limit speed
                e.vel.x = clamp(e.vel.x, -e.max_speed, e.max_speed)
                e.vel.y = clamp(e.vel.y, -e.max_speed, e.max_speed)
            end
            if e.body then
                local body = hc_body.get(e, e.body, e.pos)
                -- apply velocity
                local move = e.vel * dt
                body._shape = e.body
                body:move(move.x, move.y)
                -- body collision response
                for other, delta in pairs(hc_body.world:collisions(body)) do
                    local self_weight = body._shape.weight or 0
                    local other_weight = other._shape.weight or 0
                    
                    if self_weight >= 1 and other_weight >= 1 then
                        -- both immovable, no movement
                    elseif self_weight >= 1 then
                        -- self is immovable, only other moves
                        other:move(-delta.x, -delta.y)
                    elseif other_weight >= 1 then
                        -- other is immovable, only self moves
                        body:move(delta.x, delta.y)
                    else
                        -- distribute movement based on weight ratio
                        local total_weight = self_weight + other_weight
                        if total_weight > 0 then
                            local self_move_factor = other_weight / total_weight
                            local other_move_factor = self_weight / total_weight
                            
                            body:move(delta.x * self_move_factor, delta.y * self_move_factor)
                            other:move(-delta.x * other_move_factor, -delta.y * other_move_factor)
                        else
                            -- both have weight 0, split movement equally
                            body:move(delta.x * 0.5, delta.y * 0.5)
                            other:move(-delta.x * 0.5, -delta.y * 0.5)
                        end
                    end
                end
                e.pos:set(body:center())
            else
                -- apply velocity
                e.pos:set(
                    e.pos + e.vel * dt
                )
            end
            if e.hurtbox then
                local hurtbox = hc_hurtbox.get(e, e.hurtbox)
                hurtbox:moveTo(e.pos.x, e.pos.y)
            end
            if e.hitbox then
                -- hitbox collision response
                local hitbox = hc_hitbox.get(e, e.hitbox, e.pos)
                hitbox._entity = e
                hitbox:moveTo(e.pos.x, e.pos.y)
                local hit = {}
                if not hitbox_hit[e] then
                    hitbox_hit[e] = {}
                end
                for other, delta in pairs(hc_hitbox.world:collisions(hitbox)) do
                    ---@type Entity?
                    local other_entity = other._entity
                    if other_entity then
                        if not hitbox_hit[e][other_entity] then
                            -- only hit once until separated
                            api.entity.signal_hitbox_collision.emit(e, other_entity, vec2(delta.x, delta.y))
                        end
                        hit[other_entity] = true -- track all current collisions
                    end
                end
                hitbox_hit[e] = hit
            end
        end
    end
end

M.draw = function()
    for _, e in ipairs(api.entity.entities) do
        push()
        translate(e.pos.x, e.pos.y)
        -- draw body
        local body = e.body
        if body then
            set_color(lume.color(mui.BLUE_500))
            circle("fill", 0, 0, body.r)
        end
        local hurtbox = e.hurtbox
        if hurtbox then
            set_color(lume.color(mui.GREEN_500))
            circle("fill", 0, 0, hurtbox.r)
        end
        local hitbox = e.hitbox
        if hitbox then
            set_color(lume.color(mui.RED_500))
            circle("fill", 0, 0, hitbox.r)
        end
        -- draw aim
        circle("line", e.aim_dir.x * 30, e.aim_dir.y * 30, 3)
        pop()
    end
end

return M
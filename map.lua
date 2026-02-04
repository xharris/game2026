local M = {}

---@class MapZone
---@field zones string[] names of possible zones to other zones

local api = require 'api'

local layers = {
    filler = '#a5a5a7',
    path = '#ffffff',
    special = '#d186df',
    boss = '#fe5b59',
    zone = '#57b9f2',
}

local is_layer = function (name, r, g, b, a)
    local r2, g2, b2, a2 = lume.color(layers[name])
    -- compare with small epsilon for float precision
    local epsilon = 0.01
    return math.abs(r-r2) < epsilon and 
           math.abs(g-g2) < epsilon and 
           math.abs(b-b2) < epsilon and 
           math.abs(a-a2) < epsilon
end

-- -- add enemy
-- local enemy = api.entity.new()
-- enemy.tag = 'enemy'
-- enemy.body = {r=15, weight=1}
-- enemy.pos:set(400, 300)
-- enemy.hurtbox = {r=12}
-- enemy.hp = 30
-- -- enemy.friction = const.FRICTION.NORMAL
-- enemy.move_speed = 50
-- enemy.ai = {
--     patrol_radius=200,
--     vision_radius=200,
--     patrol_cooldown=3
-- }

---@param start string path to image of starting level
M.new = function(start)
    local size = 16
    local data = love.image.newImageData(start)
    ---@type Entity[]
    local zones = {}

    for x = 0, data:getWidth()-1 do
        for y = 0, data:getHeight()-1 do
            local r,g,b,a = data:getPixel(x, y)
            
            local pos = vec2(x*size, y*size)
            local layer
            for key, _ in pairs(layers) do
                if is_layer(key, r, g, b, a) then
                    layer = key
                    break
                end
            end

            if layer == 'path' then
                local e = api.entity.new()
                e.pos = pos
                e.rect = {
                    color = layers.path,
                    w = size,
                    h = size,
                }

            elseif layer == 'zone' then
                local e = api.entity.new()
                e.tag = 'zone'
                e.pos = pos
                e.rect = {
                    color = layers.zone,
                    w = size,
                    h = size,
                }
                lume.push(zones, e)

            end
        end
    end
    -- turn a random zone into a player spawn
    local player_spawn = lume.randomchoice(zones)
    if player_spawn then
        player_spawn.tag = 'checkpoint'
    end
end

return M
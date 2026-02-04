local M = {}

---@class MapZone
---@field connections string[] names of possible connections to other zones

local api = require 'api'

local layer = {
    connection = '#57b9f2',
    boss = '#fe5b59',
    special = '#d186df',
    filler = '#a5a5a7',
    path = '#ffffff'
}

local is_layer = function (name, r, g, b, a)
    local r2, g2, b2, a2 = lume.color(layer[name])
    return r==r2 and g==g2 and b==b2 and a==a2
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
    local size = 32
    local data = love.image.newImageData(start)
    for x = 0, data:getWidth()-1 do
        for y = 0, data:getHeight()-1 do
            local r,g,b,a = data:getPixel(x, y)
            if is_layer('path', r, g, b, a) then
                local tile = api.entity.new()
                tile.pos:set(x*size, y*size)
                tile.rect = {
                    color = layer.path,
                    w = size,
                    h = size,
                }
            end
        end
    end
end

return M
local M = {}

---@alias MapLayers table<string, string> 

---@class MapZone
---@field zones string[] names of possible zones to other zones

---@class MapTile
---@field color string
---@field layer string
---@field pos Vector.lua

local api = require 'api'

---@param start string path to image of starting level
---@param layers MapLayers {name:color}
M.load = function(start, layers)
    local is_layer = function (name, r, g, b, a)
        local r2, g2, b2, a2 = lume.color(layers[name])
        -- compare with small epsilon for float precision
        local epsilon = 0.01
        return math.abs(r-r2) < epsilon and
            math.abs(g-g2) < epsilon and
            math.abs(b-b2) < epsilon and
            math.abs(a-a2) < epsilon
    end

    local data = love.image.newImageData(start)

    ---@type MapTile[]
    local tiles = {}

    for x = 0, data:getWidth()-1 do
        for y = 0, data:getHeight()-1 do
            local r,g,b,a = data:getPixel(x, y)
            
            local pos = vec2(x, y)
            local layer
            for key, _ in pairs(layers) do
                if is_layer(key, r, g, b, a) then
                    layer = key
                    break
                end
            end

            if layer then
                lume.push(tiles, {
                    color = layers[layer],
                    layer = layer,
                    pos = pos
                } --[[@as MapTile]])
            end
        end
    end

    return tiles
end

return M
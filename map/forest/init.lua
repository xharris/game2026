local M = {}

local mui = require 'lib.mui'

---@type Zone
return {
    size = 20,
    image = 'map/test/test.png',
    bg_color = mui.CYAN_100,
    special = {
        campfire = {
            new = function (pos, tile_size)
                -- create campfire
                log.debug("spawn campfire")
            end
        }
    },
    enemy_pool = {
        -- slime
        {
            body = {r=15, weight=1},
            hurtbox = {r=12},
            hp = 8,
            move_speed = 50,
            ai = {
                patrol_radius=200,
                vision_radius=200,
                patrol_cooldown=3
            },
        }
    }
}
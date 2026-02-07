local M = {}

local mui = require 'lib.mui'
local api = require 'api'

---@type Zone
return {
    name = 'forest',
    size = 32,
    image = 'map/test/test.png',
    bg_color = mui.CYAN_100,
    special = {
        campfire = {
            new = function (pos, tile_size)
                -- create campfire
                log.debug("spawn campfire", pos)
                local campfire = api.entity.new()
                campfire.tag = 'magic_source'
                campfire.rect = {
                    fill = true,
                    color=mui.BROWN_500,
                    w=18,
                    h=9,
                }
                campfire.pos = pos:clone()
                -- create fire magic
                local fire = api.entity.new(campfire)
                fire.tag = 'magic'
                fire.magic = {'fire'}
                fire.item = {
                    can_transfer = true,
                    restore_after_transfer = 3,
                    restore_after_remove = 3,
                }
                fire.hitbox = {r=10}
                fire.pos = campfire.pos:clone()
                -- add fire to camp... fire
                campfire.item_stored = fire._id
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
                patrol_radius=20,
                vision_radius=50,
                patrol_cooldown=3
            },
        }
    }
}
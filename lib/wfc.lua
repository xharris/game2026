local M = {}

local find = lume.find
local push = lume.push
local clone = lume.clone
local randomchoice = lume.randomchoice
local remove = lume.remove

---@alias WfcDir 'l'|'r'|'u'|'d'

---@class WfcRule
---@field tile string
---@field other string
---@field dir WfcDir tile can be [left|right|etc] of other

---@class WfcCell
---@field x number
---@field y number
---@field tiles string[]

---@param rules WfcRule[]
---@param w number
---@param h number
M.collapse = function(rules, w, h)
    ---@type string[] all possible tiles
    local tiles = {}
    ---@type (string[])[][]
    local grid = {}

    ---@param rule WfcRule
    local find_rule = function(rule)
        for _, r in ipairs(rules) do
            if r.dir == rule.dir and r.tile == rule.tile and r.other == rule.other then
                return true
            end
        end
        return false
    end

    ---@param dir WfcDir
    ---@param x number
    ---@param y number
    ---@param tile string
    local is_allowed = function(dir, x, y, tile)
        for _, other in ipairs(grid[x][y]) do

            ---@type WfcRule
            local rule = {tile=tile, other=other, dir=dir}
            if not find_rule(rule) then
                return true
            end

        end
        return false
    end

    -- get all possible tiles
    for _, r in ipairs(rules) do
        if not find(tiles, r.tile) then
            push(tiles, r.tile)
        end
    end
    -- setup grid
    for x = 1, w do
        grid[x] = {}
        for y = 1, h do
            grid[x][y] = clone(tiles)
        end
    end
    -- collapse
    repeat
        -- get lowest entropy
        local min_entropy
        for x = 1, w do
            for y = 1, h do
                if not min_entropy or (#grid[x][y] > 1 and #grid[x][y] < min_entropy) then
                    min_entropy = #grid[x][y]
                end
            end
        end
        -- get all cells with lowest entropy
        ---@type WfcCell[]
        local next_cells = {}
        for x = 1, w do
            for y = 1, h do
                if #grid[x][y] == min_entropy then
                    push(next_cells, {x=x, y=y, tiles=grid[x][y]})
                end
            end
        end
        -- pick random cell with lowest entropy
        local cell = randomchoice(next_cells)
        if not cell then
            return grid -- nothing left, all done
        end
        grid[cell.x][cell.y] = {randomchoice(cell.tiles)}

        -- update grid
        for x = 1, w do
            for y = 1, h do

                ---@type string[]
                local allowed = grid[x][y]
                for _, tile in ipairs(allowed) do
                    if not is_allowed('r', x+1, y, tile) then
                        remove(allowed, tile)
                    end

                    if not is_allowed('l', x-1, y, tile) then
                        remove(allowed, tile)
                    end

                    if not is_allowed('u', x, y-1, tile) then
                        remove(allowed, tile)
                    end

                    if not is_allowed('d', x, y+1, tile) then
                        remove(allowed, tile)
                    end
                end
                grid[x][y] = allowed

            end
        end

    until false
end

log.debug(
    M.collapse(
        {
            {tile='w', dir='l', other='w'},
            {tile='w', dir='r', other='w'},

            {tile='w', dir='l', other='e'},
            {tile='e', dir='l', other='w'},
            
            {tile='e', dir='l', other='e'},
            {tile='e', dir='l', other='e'},
        },
        16,
        16
    )
)

return M
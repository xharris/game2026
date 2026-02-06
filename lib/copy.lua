-- deep copy table

-- local copy_t
-- copy_t = function (t, copied)
--     copied = copied or {}
--     local new = {}
--     for k, v in pairs(t) do
--         if not copied[v] then
--             copied[v] = true
--             if type(v) == 'table' then
--                 new[k] = copy_t(v, copied)
--             else
--                 new[k] = v
--             end
--         end
--     end
--     return new
-- end

local copy3
copy3 = function(obj, seen)
	-- Handle non-tables and previously-seen tables.
	if type(obj) ~= 'table' then return obj end
	if seen and seen[obj] then return seen[obj] end

	-- New table; mark it as seen an copy recursively.
	local s = seen or {}
	local res = {}
	s[obj] = res
	for k, v in next, obj do res[copy3(k, s)] = copy3(v, s) end
	return setmetatable(res, getmetatable(obj))
end

---@generic V : table
---@param v V
---@return V
local copy = function (v)
    return copy3(v)
end

return copy
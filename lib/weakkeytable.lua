-- can use table as key. when the table is garbase collected, it is removed from this table.
return function ()
    return setmetatable({}, { __mode = "k" })
end
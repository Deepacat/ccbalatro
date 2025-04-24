-- -- -- -- general functions -- -- -- --
local gen = {}
-- removes the first occurence of value in table
function gen.del(t, v)
    for i = 1, #t do
        if t[i] == v then
            table.remove(t, i)
            return
        end
    end
end

-- shorthand for table.remove
gen.deli = table.remove

-- shorthand for table.insert
function gen.add(t, v)
    return table.insert(t, v)
end

-- returns the number of occurences of value appears in table
function gen.count(t, v)
    local c = 0
    for i = 1, #t do
        if t[i] == v then
            c = c + 1
        end
    end
    return c
end

-- iterator in for loops to iterate over items in order they were added, similar to ipairs without key
function gen.all(t)
    local i = 0
    local n = #t
    return function()
        i = i + 1
        if i <= n then return t[i] end
    end
end

-- random number from 0 to x, or random entry in table
function gen.rnd(x)
    if type(x) == "number" then return math.random(x) end
    if type(x) == "table" then return x[math.random(#x)] end
end

-- shorthand for math.floor
function gen.flr(x)
    return math.floor(x)
end

-- shorthand for math.abs
function gen.abs(x)
    return math.abs(x)
end

-- -- -- -- general functions end -- -- -- --

return gen

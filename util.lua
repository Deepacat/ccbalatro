local util = {}

util.cocreate = coroutine.create
util.costatus = coroutine.status
util.coresume = coroutine.resume
util.yield = coroutine.yield

function util.dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. util.dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

-- removes the first occurence of value in table
function util.del(t, v)
    for i = 1, #t do
        if t[i] == v then
            table.remove(t, i)
            return
        end
    end
end

-- shorthand for table.remove
util.deli = table.remove

-- clear a table while preserving
-- object references to it
function util.clear(table)
	for i=#table,1,-1 do
		util.deli(table,i)
	end
end

-- shorthand for table.insert
function util.add(t, v)
    return table.insert(t, v)
end

-- returns the number of occurences of value appears in table
function util.count(t, v)
    local c = 0
    for i = 1, #t do
        if t[i] == v then
            c = c + 1
        end
    end
    return c
end

-- iterator in for loops to iterate over items in order they were added, similar to ipairs without key
function util.all(t)
    local i = 0
    return function()
        i = i + 1
        return t[i]
    end
end

-- random number from 0 to x, or random entry in table
function util.rnd(x)
    if type(x) == "number" then return math.random(x) end
    if type(x) == "table" then return x[math.random(#x)] end
end

-- shorthand for math.floor
function util.flr(x)
    return math.floor(x)
end

-- shorthand for math.abs
function util.abs(x)
    return math.abs(x)
end

function util.max(x, y)
    if x == nil or y == nil then return 0 end
    return math.max(x, y)
end

function util.min(x, y)
    if x == nil or y == nil then return 0 end
    return math.min(x, y)
end

-- Helpers
function util.contains(table, value)
    -- is there a value in a table
    for item in util.all(table) do
        if item == value then
            return true
        end
    end
    return false
end

return util

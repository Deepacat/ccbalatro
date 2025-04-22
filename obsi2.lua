--discord.gg/boronide, code generated using luamin.js™



package.preload["obsi2"] = function()
    local a = fs.getDir(shell.getRunningProgram())
    local b = {}
    local c = { maxfps = 20, mintps = 60, multiUpdate = true, renderingAPI = "basic", sleepOption = 1 }
    local d; local e; local f, g, h, i, j; local k = function(...) end; local l; b.fs, l = require("obsi2.fs")(a)
    b.system = require("obsi2.system")
    if not periphemu then c.sleepOption = 2 end; b.graphics, d, e = require("obsi2.graphics")(b.fs, c.renderingAPI)
    b.timer, j = require("obsi2.timer")()
    b.keyboard = require("obsi2.keyboard")
    b.mouse, g, i, h = require("obsi2.mouse")()
    b.audio, f = require("obsi2.audio")(b.fs)
    b.state = require("obsi2.state")
    b.debug = false; b.version = "2.0.2"
    b.load = k; b.update = k; b.draw = k; b.onMousePress = k; b.onMouseRelease = k; b.onMouseMove = k; b.onKeyPress = k; b.onKeyRelease =
        k; b.onWindowFlush = k; b.onResize = k; b.onEvent = k; b.onQuit = k; local a = false; function b.quit() a = true end; local function k()
        return
            periphemu and os.epoch(("nano")) / 10 ^ 9 or os.clock()
    end; local function m(a)
        local a = os.startTimer(a)
        while true do
            local b, b = os.pullEventRaw("timer")
            if b == a then break end
        end
    end; local n = k()
    local o = 1 / c.maxfps; local p = n; local q = n; local r = n; local s = n; local t = 0; l()
    local function l()
        b.load()
        while true do
            local a = k()
            if c.multiUpdate then
                local a = false; for d = 1, o / (1 / c.mintps) do
                    b.update(1 / c.mintps)
                    a = true
                end; if not a then b.update(o) end
            else
                b.update(o)
            end; q = k() - a; b.draw(o)
            p = k() - q - a; b.graphics.setCanvas()
            f(o)
            if b.debug then
                local a, c = b.graphics.bgColor, b.graphics.fgColor; b.graphics.bgColor, b.graphics.fgColor =
                    colors.black, colors.white; b.graphics.write("Obsi " .. b.version, 1, 1)
                b.graphics.write(b.system.getHost(), 1, 2)
                b.graphics.write(
                    ("rendering: %s [%sx%s -> %sx%s]"):format(b.graphics.getRenderer(), b.graphics.getWidth(),
                        b.graphics.getHeight(), b.graphics.getPixelSize()), 1, 3)
                b.graphics.write(("%s FPS"):format(b.timer.getFPS()), 1, 4)
                b.graphics.write(("%0.2fms update"):format(q * 1000), 1, 5)
                b.graphics.write(("%0.2fms draw"):format(p * 1000), 1, 6)
                b.graphics.write(("%0.2fms frame"):format(r * 1000), 1, 7)
                b.graphics.bgColor, b.graphics.fgColor = a, c
            end; b.graphics.flushAll()
            b.onWindowFlush(e)
            b.graphics.show()
            if k() > s + 1 then
                s = k()
                j(t / 1)
                t = 0
            else
                t = t + 1
            end; r = k() - a; if c.sleepOption == 1 then
                if r > 1 / c.maxfps then
                    m(0)
                else
                    m((1 / c.maxfps - r) /
                        1.1)
                end
            else
                m(0)
            end; b.graphics.clear()
            b.graphics.bgColor, b.graphics.fgColor = colors.black, colors.white; b.graphics.resetOrigin()
            o = k() - n; n = k()
        end
    end; local function c()
        while true do
            local c = { os.pullEventRaw() }
            if c[1] == "mouse_click" then
                g(c[3], c[4], c[2])
                b.onMousePress(c[3], c[4], c[2])
            elseif c[1] == "mouse_up" then
                i(c[3], c[4], c[2])
                b.onMouseRelease(c[3], c[4], c[2])
            elseif c[1] == "mouse_move" then
                h(c[3], c[4])
                b.onMouseMove(c[3], c[4])
            elseif c[1] == "mouse_drag" then
                h(c[3], c[4])
                b.onMouseMove(c[3], c[4])
            elseif c[1] == "term_resize" or c[1] == "monitor_resize" then
                local a, c = term.getSize()
                e.reposition(1, 1, a, c)
                d:resize(a, c)
                b.graphics.pixelWidth, b.graphics.pixelHeight = d.width, d.height; b.graphics.width, b.graphics.height =
                    a, c; b.onResize(a, c)
            elseif c[1] == "key" and not c[3] then
                b.keyboard.keys[keys.getName(c[2])] = true; b.keyboard.scancodes[c[2]] = true; b.onKeyPress(c[2])
            elseif c[1] == "key_up" then
                b.keyboard.keys[keys.getName(c[2])] = false; b.keyboard.scancodes[c[2]] = false; b.onKeyRelease(c[2])
            elseif c[1] == "terminate" or a then
                b.onQuit()
                b.graphics.clearPalette()
                term.setBackgroundColor(colors.black)
                term.clear()
                term.setCursorPos(1, 1)
                return
            end; b.onEvent(c)
        end
    end; local function a(a)
        b.graphics.clearPalette()
        term.setBackgroundColor(colors.black)
        term.clear()
        term.setCursorPos(1, 1)
        printError(debug.traceback(a, 2))
    end; function b.init() parallel.waitForAny(function() xpcall(l, a) end, function() xpcall(c, a) end) end; return b
end; package.preload["obsi2.state"] = function()
    local a = {}
    local b = {}
    local c = {}
    function a.newScene(a)
        local b = {}
        b.variables = {}
        function b:setVariable(a, b) self.variables[a] = b end; function b:getVariable(a) return self.variables[a] end; b.objects = {}
        c[a] = b; return b
    end; function a.getScene(a) return c[a] end; function a.setScene(a, b) c[a] = b end; function a.everyScene()
        return
            pairs(c)
    end; function a.setGlobal(a, c) b[a] = c end; function a.getGlobal(a) return b[a] end; a.newScene(
        "Default")
    return a
end; package.preload["obsi2.timer"] = function()
    local a = {}
    local b = os.clock()
    local c = 0; local function d(a) c = a end; function a.getTime() return os.clock() - b end; function a.getFPS()
        return
            c
    end; return function() return a, d end
end; package.preload["obsi2.fs"] = function()
    local a = {}
    local b = false; local c = ""
    local d = vfs or fs; local function e(a) return b and d.combine(c, a) or a end; function a.createDirectory(a)
        local a, b = e(a)
        if not a then return false, b end; local a = pcall(d.makeDir, a)
        return a
    end; function a.getDirectoryItems(a)
        local a, b = e(a)
        if not a then return nil, b end; local a, b = pcall(d.list, a)
        return a and b or {}
    end; function a.newFile(a, b)
        local c, e = e(a)
        if not c then return nil, e end; b = b or "c"
        local e = {}
        e.path = c; e.name = d.getName(a)
        e.mode = b; function e:open(a)
            if a == "c" then return end; local a, b = d.open(self.path, a and a .. "b")
            if not a then return false, b end; self.file = a; return true
        end; if b ~= "c" then
            local a, b = e:open(b)
            if not a then return nil, b end
        end; function e:getMode() return self.mode end; function e:write(a, b)
            if self.file and (self.mode == "w" or self.mode == "a") then
                b = b or #a; self.file.write(a:sub(b))
                return true
            else
                return false, "File is not opened for writing"
            end
        end; function e:flush()
            if self.mode == "w" and self.file then
                self.file.flush()
                return true
            else
                return false, "File is not opened for writing"
            end
        end; function e:read(a)
            if not self.file then
                local a, a = self:open("r")
                if a then return nil, a end
            elseif self.mode ~= "r" then
                return nil, "File is not opened for reading"
            end; return a and self.file.read(a) or
                self.file.readAll()
        end; function e:lines()
            if not self.file then
                local a, a = self:open("r")
                if a then error(a) end
            elseif self.mode ~= "r" then
                return nil, "File is not opened for reading"
            end; return function()
                return self
                    .file.readLine(false)
            end
        end; function e:seek(a) if self.file then self.file.seek("set", a) end end; function e:tell()
            if self.file then
                return
                    self.file.seek("cur", 0)
            end
        end; function e:close()
            if self.file then self.file.close() end; self.file = nil; self.mode = "c"
        end; return e
    end; function a.getInfo(a)
        a = e(a)
        local a, a = pcall(d.attributes, a)
        if not a then return nil end; return {
            type = (a.isDir and "directory" or "file"),
            size = a.size,
            modtime = a
                .modified,
            createtime = a.created,
            readonly = a.isReadOnly
        }
    end; function a.read(a)
        a = e(a)
        local a, b = d.open(a, "rb")
        if not a then return nil, b end; local b = a.readAll() or ""
        a.close()
        return b
    end; function a.write(a, b)
        a = e(a)
        local a, c = d.open(a, "wb")
        if not a then return false, c end; a.write(b)
        a.close()
        return true
    end; function a.remove(a)
        a = e(a)
        local a, b = pcall(d.delete, a)
        return a, b
    end; function a.lines(a)
        a = e(a)
        local a, b = d.open(a, "rb")
        if not a then error(b) end; return function() return a.readLine(false) or a.close() end
    end; local function e(e)
        c = d.combine(e)
        return a, function() b = true end
    end; return e
end; package.preload["obsi2.mouse"] = function()
    local a = {}
    local b = {}
    local c, d = 0, 0; function a.getX() return c end; function a.getY() return d end; function a.getPosition()
        return c,
            d
    end; function a.canMove() return not not (config and (config.get("mouse_move_throttle") >= 0)) end; function a.isDown(
        a)
        return b[a] or false
    end; local function e(a, e, f)
        c, d = a, e; b[f] = true
    end; local function f(a, e, f)
        c, d = a, e; b[f] = false
    end; local function b(a, b) c, d = a or c, b or d end; return function() return a, e, f, b end
end; package.preload["obsi2.graphics"] = function()
    local a; local b = {}
    b.neat = require("obsi2.graphics.neat")
    b.pixelbox = require("obsi2.graphics.pixelbox")
    b.basic = require("obsi2.graphics.basic")
    local c = require("obsi2.graphics.nfpParser")
    local d = require("obsi2.graphics.orliParser")
    local e; do
        local a, b = term.getSize()
        e = window.create(term.current(), 1, 1, a, b, false)
    end; local f = {}
    local g, h, i, j, k = math.floor, math.ceil, math.abs, math.max, math.min; local l; local m; local n = {}
    f.originX = 1; f.originY = 1; f.width, f.height = term.getSize()
    f.fgColor = colors.white; f.bgColor = colors.black; local function o(a, b, c)
        if type(a) ~= c then
            error(
                ("Argument '%s' must be a %s, not a %s"):format(b, c, type(a)), 3)
        end
    end; local p = {}
    for a = 0, 15 do p[2 ^ a] = ("%x"):format(a) end; local function q(a) return p[a] end; function f.setPaletteColor(a,
                                                                                                                      b,
                                                                                                                      c,
                                                                                                                      d)
        if type(a) == "string" then
            if #a ~= 1 then error(("Argument `color: string` must be 1 character long, not %s"):format(#a)) end; a =
                tonumber(a, 16)
            if not a then error(("Argument `color: string` must be a valid hex character, not %s"):format(a)) end; a = 2 ^
                a
        elseif type(a) ~= "number" then
            error(("Argument `color` must be either integer or string, not %s"):format(type(
                a)))
        end; o(b, "r", "number")
        o(c, "g", "number")
        o(d, "b", "number")
        e.setPaletteColor(a, b, c, d)
    end; function f.offsetOrigin(a, b)
        o(a, "x", "number")
        o(b, "y", "number")
        f.originX = f.originX + g(a)
        f.originY = f.originY + g(b)
    end; function f.setOrigin(a, b)
        o(a, "x", "number")
        o(b, "y", "number")
        f.originX = g(a)
        f.originY = g(b)
    end; function f.resetOrigin()
        f.originX = 1; f.originY = 1
    end; function f.getOrigin() return f.originX, f.originY end; function f.getPixelWidth() return f.pixelWidth end; function f.getPixelHeight()
        return
            f.pixelHeight
    end; function f.getWidth() return f.width end; function f.getHeight() return f.height end; function f.getSize()
        return
            f.width, f.height
    end; function f.getPixelSize() return f.pixelWidth, f.pixelHeight end; function f.termToPixelCoordinates(
        a, b)
        if l.owner == "basic" then
            return a, b
        elseif l.owner == "neat" then
            return a, g(b * 1.5)
        elseif l.owner == "pixelbox" then
            return
                a * 2, b * 3
        end
    end; function f.pixelToTermCoordinates(a, b)
        if l.owner == "basic" then
            return a, b
        elseif l.owner == "neat" then
            return
                a, g(b / 1.5)
        elseif l.owner == "pixelbox" then
            return g(a / 2), g(b / 3)
        end
    end; local function p(a)
        if type(a) == "string" then return 2 ^ tonumber(a, 16) end; return a
    end; function f.setBackgroundColor(a) f.bgColor = p(a) end; function f.setForegroundColor(a) f.fgColor = p(a) end; function f.getBackgroundColor()
        return
            f.bgColor
    end; function f.getForegroundColor() return f.fgColor end; local function r(a, b)
        return (a >= 1) and
            (b >= 1) and (a <= m.width) and (b <= m.height)
    end; local function s(a, b, c)
        c = c or f.fgColor; a, b = g(a - f.originX + 1), g(b - f.originY + 1)
        if r(a, b) then m:setPixel(a, b, c) end
    end; function f.point(a, b)
        o(a, "x", "number")
        o(b, "y", "number")
        s(a, b)
    end; function f.points(a)
        for b = 1, #a do
            local a = a[b]
            s(a[1], a[2])
        end
    end; function f.rectangle(a, b, c, d, e)
        o(b, "x", "number")
        o(c, "y", "number")
        o(d, "width", "number")
        o(e, "height", "number")
        local h, i = f.getPixelSize()
        b = g(b - f.originX + 1)
        c = g(c - f.originY + 1)
        local g = j(1, b)
        local j = j(1, c)
        local l = k(h, b + d - 1)
        local k = k(i, c + e - 1)
        if g > l or j > k then return end; if a == "fill" then
            for a = j, k do
                for b = g, l do
                    m:setPixel(b, a, f
                        .fgColor)
                end
            end
        elseif a == "line" then
            if b >= 1 and b <= h then for a = j, k do m:setPixel(b, a, f.fgColor) end end; local a = b + d - 1; if a >= 1 and a <= h then
                for b = j, k do
                    m:setPixel(a, b, f.fgColor)
                end
            end; if c >= 1 and c <= i then
                for a = g, l do
                    m:setPixel(a, c,
                        f.fgColor)
                end
            end; local a = c + e - 1; if a >= 1 and a <= i then
                for b = g, l do
                    m:setPixel(b,
                        a, f.fgColor)
                end
            end
        end
    end; function f.line(a, b)
        local a, c = g(a[1]), g(a[2])
        local b, d = g(b[1]), g(b[2])
        local e, f = i(b - a), i(d - c)
        local g, h = (a < b) and 1 or -1, (c < d) and 1 or -1; local i = e - f; while a ~= b or c ~= d do
            s(a, c)
            local b = i * 2; if b > -f then
                i = i - f; a = a + g
            end; if b < e then
                i = i + e; c = c + h
            end
        end; s(b, d)
    end; local function k(a, b)
        local e, f, g; e, g = d.parse(b)
        if e then return e end; e, f = c.parse(b)
        if e then return e end; if a:sub(-5):lower() == ".orli" then
            error(g)
        elseif a:sub(-4):lower() == ".nfp" then
            error(f)
        else
            error(("Extension of the image is not supported: %s"):format(a), 2)
        end
    end; function f.newImage(b)
        local a, c = a.read(b)
        if not a then error(c) end; local a = k(b, a)
        return a
    end; function f.newBlankImage(a, b, c)
        o(a, "width", "number")
        o(b, "height", "number")
        c = c and p(c) or -1; a = g(j(a, 1))
        b = g(j(b, 1))
        local d = {}
        d.data = {}
        for b = 1, b do
            d.data[b] = {}
            for a = 1, a do d.data[b][a] = c end
        end; d.width = a; d.height = b; return d
    end; function f.newImagesFromTilesheet(b, c, d)
        local a, e = a.read(b)
        if not a then error(e) end; local a = k(b, a)
        if a.width % c ~= 0 then
            error(("Tilemap width can't be divided by tile's width: %s and %s"):format(a.width, c))
        elseif a.height % d ~= 0 then
            error(("Tilemap height can't be divided by tile's height: %s and %s"):format(a.height, d))
        end; local b = {}
        for e = d, a.height, d do
            for g = c, a.width, c do
                local f = f.newBlankImage(c, d, -1)
                for b = 1, d do for h = 1, c do f.data[b][h] = a.data[e - d + b][g - c + h] end end; b[#b + 1] = f
            end
        end; return b
    end; function f.newCanvas(a, b)
        a, b = g(a or l.width), g(b or l.height)
        local c = {}
        c.width = a; c.height = b; c.data = {}
        for b = 1, b do
            c.data[b] = {}
            for a = 1, a do c.data[b][a] = colors.black end
        end; function c:setPixel(a, b, c) self.data[b][a] = c end; function c:getPixel(a, b) return self.data[b][a] end; function c:clear()
            for a = 1, self.height do
                for b = 1, self.width do
                    self.data[a][b] =
                        f.bgColor
                end
            end
        end; return c
    end; local function c(a, b, c)
        local d = a.data; for e = 1, a.height do
            for a = 1, a.width do
                if not d[e] then error(("iy: %s, #image.data: %s"):format(e, #d)) end; local d = d[e][a]
                if d > 0 then s(b + a - 1, c + e - 1, d) end
            end
        end
    end; function f.draw(a, b, d, e, g)
        o(b, "x", "number")
        o(d, "y", "number")
        e = e or 1; g = g or 1; if e == 0 or g == 0 then return elseif (e > 0 and b - f.originX > m.width) or (g > 0 and d - f.originY > m.height) then return end; if e == 1 and g == 1 then
            c(a, b, d)
            return
        end; local c = i(e) / e; local f = i(g) / g; e = i(e)
        g = i(g)
        for i = 1, a.height * g do
            local g = h(i / g)
            for j = 1, a.width * e do
                local e = h(j / e)
                if not a.data[g] then error(("py: %s, #image.data: %s"):format(g, #a.data)) end; local a = a.data[g][e]
                if a > 0 then s(b + j * c - c, d + i * f - f, a) end
            end
        end
    end; function f.write(a, b, c, d, e)
        o(a, "text", "string")
        o(b, "x", "number")
        o(c, "y", "number")
        local g = {}
        g.text = a; g.x = b; g.y = c; d = d or f.fgColor; e = e or f.bgColor; if type(d) == "number" then
            d = q(d):rep(#
                a)
        elseif type(d) == "string" and #d == 1 then
            d = d:rep(#a)
        end; if type(e) == "number" then
            e = q(e):rep(#
                a)
        elseif type(e) == "string" and #e == 1 then
            e = e:rep(#a)
        end; if type(d) ~= "string" then
            error(
                "fgColor is not a number or a string!")
        elseif type(e) ~= "string" then
            error(
                "bgColor is not a number or a string!")
        end; g.fgColor = d; g.bgColor = e; n[#n + 1] = g
    end; function f.newPalette(b)
        o(b, "palettePath", "string")
        local a, b = a.newFile(b, "r")
        if not a then error(b) end; local b = {}
        for c = 1, 16 do
            local a = a.file.readLine()
            if not a then error("File could not be read completely!") end; local d = {}
            for a in a:gmatch("%d+") do
                if not tonumber(a) then error(("Can't put %s as a number"):format(a)) end; d[#d + 1] = tonumber(a) / 255
            end; if #d > 3 then error("More colors than should be possible!") end; b[c] = { table.unpack(d) }
        end; a:close()
        return { data = b }
    end; function f.setPalette(a)
        for b = 1, 16 do
            local a = a.data[b]
            e.setPaletteColor(2 ^ (b - 1), a[1], a[2], a[3])
        end
    end; function f.getPallete()
        local a = {}
        local b = { data = a }
        for b = 1, 16 do a[b] = { term.getPaletteColor(2 ^ (b - 1)) } end; return b
    end; function f.clearPalette() shell.run("clear", "palette") end; function f.setCanvas(a) m = a or l end; function f.getCanvas()
        return
            m
    end; function f.clear() for a = 1, m.height do for b = 1, m.width do m:setPixel(b, a, f.bgColor) end end end; function f.setRenderer(
        a)
        local b = b[a]
        if b then
            b.own(l)
            local a, b = f.getSize()
            l:resize(a, b)
            f.pixelWidth, f.pixelHeight = l.width, l.height
        else
            error(("Unknown renderer name: %s"):format(a))
        end
    end; function f.getRenderer() return l.owner end; function f.flushCanvas() l:render() end; function f.flushText()
        for a = 1, #n do
            local a = n[a]
            local b = a.text; if a.x + #b >= 1 and a.y >= 1 and a.x <= f.getWidth() and a.y <= f.getHeight() then
                e.setCursorPos(a.x, a.y)
                e.blit(b, a.fgColor or q(f.fgColor):rep(#b), a.bgColor or q(f.bgColor):rep(#b))
            end
        end; n = {}
    end; function f.flushAll()
        f.flushCanvas()
        f.flushText()
    end; function f.show()
        e.setVisible(true)
        e.setVisible(false)
    end; return function(c, d)
        l = b[d].newCanvas(e)
        f.pixelWidth, f.pixelHeight = l.width, l.height; m = l; a = c; return f, l, e
    end
end; package.preload["obsi2.graphics.basic"] = function()
    local a = {}
    local b = table.concat; local c = {}
    for a = 0, 15 do c[2 ^ a] = ("%x"):format(a) end; local function d(a) return c[a] end; local c = {}
    function c:render()
        local a = self.data; local c = self.term.blit; local e = self.term.setCursorPos; local f = ("0"):rep(self.width)
        local g = (" "):rep(self.width)
        local h = {}
        for i = 1, self.height do
            for b = 1, self.width do h[b] = d(a[i][b]) end; e(1, i)
            c(g, f, b(h))
        end
    end; function c:resize(a, b)
        if self.height > b then
            for a = 1, self.height - b do table.remove(self.data) end
        elseif self.height < b then
            for b = self.height, b do
                self.data[b] = {}
                for a = 1, a do self.data[b][a] = colors.black end
            end
        end; if self.width > a then
            for b = 1, b do for a = 1, self.width - a - 1 do table.remove(self.data[b]) end end
        elseif self.width < a then
            for b = 1, b do
                for a = self.width + 1, a do
                    self.data[b][a] =
                        colors.black
                end
            end
        end; self.width = a; self.height = b
    end; function c:setPixel(a, b, c) self.data[b][a] = c end; function a.newCanvas(a, b, d)
        local e = {}
        if (not b or not d) then if a then b, d = a.getSize() else b, d = term.getSize() end end; e.width = b; e.height =
            d; e.term = a or term; e.setPixel = c.setPixel; e.resize = c.resize; e.render = c.render; e.owner = "basic"
        local a = {}
        for c = 1, d do
            a[c] = {}
            for b = 1, b do a[c][b] = colors.black end
        end; e.data = a; return e
    end; function a.own(a)
        a.render = c.render; a.resize = c.resize; a.setPixel = c.setPixel; a.owner = "basic"
    end; a.getBlit = d; return a
end; package.preload["obsi2.graphics.orliParser"] = function()
    local a = {}
    local b, c, d, e = math.max, math.floor, math.ceil, math.log; local f, g = bit32.rshift, bit32.band; local h = string
        .unpack; local function i(a, b) return h(">B", a, b) end; local function j(a, b) return h(">H", a, b) end; local function h(
        a, b)
        return a:sub(b, b)
    end; local function k(a, b) return g(a, b) end; local function g(a, b) return f(a, 8 - b) end; function a.parse(
        a)
        if a:sub(1, 5) ~= "\153ORLI" then return nil, "Data is not the supported ORLI format" end; local f, j = j(a, 6),
            j(a, 8)
        local l = i(a, 10)
        local m = {}
        local b = b(d(e(l, 2)), 1)
        local d = 2 ^ (8 - b) - 1; local e = 11 + l; for b = 11, 11 + l - 1 do m[#m + 1] = h(a, b) end; local h = {}
        local l = {}
        h.data = l; h.width = f; h.height = j; for a = 1, j do
            l[a] = {}
            for b = 1, f do l[a][b] = colors.red end
        end; local n = 1; for e = e, #a do
            local a = i(a, e)
            local d = k(a, d)
            local a = g(a, b)
            local a = m[a + 1]
            for b = n, n + d - 1 do
                local d = (b - 1) % f + 1; local b = c((b - 1) / f) + 1; if not l[b] then
                    error(
                        ("INCORRECT HEIGHT, FILE IS CORRUPTED (y: %i, h: %i)"):format(b, j), 4)
                end; l[b][d] = tonumber(a, 16) and
                    2 ^ tonumber(a, 16) or -1
            end; n = n + d; if n > f * j then break end
        end; return h
    end; return a
end; package.preload["obsi2.graphics.pixelbox"] = function()
    local a = {}
    local b = {}
    local c = table.concat; local d = { { 2, 3, 4, 5, 6 }, { 4, 1, 6, 3, 5 }, { 1, 4, 5, 2, 6 }, { 2, 6, 3, 5, 1 }, { 3, 6, 1, 4, 2 }, { 4, 5, 2, 3, 1 } }
    local e = {}
    local f = {}
    local g = {}
    local h = {}
    local function i(a, b, c, e, f, g)
        local a = { a, b, c, e, f, g }
        local b = {}
        for c = 1, 6 do
            local a = a[c]
            local c = b[a]
            b[a] = c and c + 1 or 1
        end; local c = {}
        for a, b in pairs(b) do c[#c + 1] = { a, b } end; table.sort(c, function(a, b) return a[2] > b[2] end)
        local b = {}
        for e = 1, 6 do
            local f = a[e]
            if f == c[1][1] then
                b[e] = 1
            elseif f == c[2][1] then
                b[e] = 0
            else
                local d = d[e]
                for f = 1, 5 do
                    local d = d[f]
                    local a = a[d]
                    local d = a == c[1][1]
                    local a = a == c[2][1]
                    if d or a then
                        b[e] = d and 1 or 0; break
                    end
                end
            end
        end; local a = 128; local d = b[6]
        if b[1] ~= d then a = a + 1 end; if b[2] ~= d then a = a + 2 end; if b[3] ~= d then a = a + 4 end; if b[4] ~= d then
            a =
                a + 8
        end; if b[5] ~= d then a = a + 16 end; local b, e; if #c > 1 then
            b = c[d + 1][1]
            e = c[2 - d][1]
        else
            b = c[1][1]
            e = c[1][1]
        end; return a, b, e
    end; local d = 0; local function j()
        for a = 0, 15 do h[2 ^ a] = ("%x"):format(a) end; local a = math.floor; local b = string.char; for c = 0, 6 ^ 6 do
            local h = a(c / 1) % 6; local j = a(c / 6) % 6; local k = a(c / 36) % 6; local l = a(c / 216) % 6; local m =
                a(c / 1296) % 6; local a = a(c / 7776) % 6; local c = {}
            c[a] = 5; c[m] = 4; c[l] = 3; c[k] = 2; c[j] = 1; c[h] = 0; local n = c[j] + c[k] * 3 + c[l] * 4 + c[m] * 20 +
                c[a] * 100; if not e[n] then
                d = d + 1; local a, d, h = i(h, j, k, l, m, a)
                local d = c[d] + 1; local c = c[h] + 1; f[n] = d; g[n] = c; e[n] = b(a)
            end
        end
    end; function a.restore(a, b, c)
        if not c then
            local c = {}
            for d = 1, a.height do
                if not c[d] then c[d] = {} end; for a = 1, a.width do c[d][a] = b end
            end; a.data = c
        else
            local c = a.data; for d = 1, a.height do
                if not c[d] then c[d] = {} end; for a = 1, a.width do if not c[d][a] then c[d][a] = b end end
            end; if #a.data > a.height then for b = 1, #a.data - a.height do table.remove(a.data) end end
        end
    end; local d = {}
    local i = { 0, 0, 0, 0, 0, 0 }
    function b:render()
        local a = self.term; local a, b = a.blit, a.setCursorPos; local j = self.data; local k, l, m = {}, {}, {}
        local n = self.width; local o = 0; for p = 1, self.height, 3 do
            o = o + 1; local q = j[p]
            local r = j[p + 1]
            local j = j[p + 2]
            local p = 0; for a = 1, n - 1, 2 do
                local b = a + 1; local a, b, c, j, n, o = q[a], q[b], r[a], r[b], j[a], j[b]
                local q, r, s = " ", 1, a; local t = b == a and c == a and j == a and n == a and o == a; if not t then
                    d[o] = 5; d[n] = 4; d[j] = 3; d[c] = 2; d[b] = 1; d[a] = 0; local d = d[b] + d[c] * 3 + d[j] * 4 +
                        d[n] * 20 + d[o] * 100; local f = f[d]
                    local g = g[d]
                    i[1] = a; i[2] = b; i[3] = c; i[4] = j; i[5] = n; i[6] = o; r = i[f]
                    s = i[g]
                    q = e[d]
                end; p = p + 1; k[p] = q; l[p] = h[r]
                m[p] = h[s]
            end; b(1, o)
            a(c(k), c(l), c(m))
        end
    end; function b:clear(b) a.restore(self, b) end; function b:setPixel(a, b, c) self.data[b][a] = c end; function b:resize(
        b, c, d)
        self.width = b * 2; self.height = c * 3; a.restore(self, d or self.background or colors.black, true)
    end; function a.newCanvas(c, d)
        local e = {}
        e.background = d or c.getBackgroundColor() or colors.black; e.term = c; local c, d = c.getSize()
        e.width = c * 2; e.height = d * 3; e.owner = "pixelbox"
        e.clear = b.clear; e.render = b.render; e.resize = b.resize; e.setPixel = b.setPixel; a.restore(e, e.background)
        return e
    end; function a.own(a)
        a.clear = b.clear; a.render = b.render; a.resize = b.resize; a.setPixel = b.setPixel; a.owner = "pixelbox"
    end; j()
    return a
end; package.preload["obsi2.graphics.neat"] = function()
    local a = {}
    local b = math.floor; local c = math.ceil; local d = table.concat; local e = {}
    for a = 0, 15 do e[2 ^ a] = ("%x"):format(a) end; local function f(a) return e[a] end; local function e(a)
        return c((a + 2) /
            2) * 3
    end; local c = {}
    function c:setPixel(a, b, c) self.data[b][a] = c end; function c:render()
        local a = self.data; local c = self.term.blit; local e = self.term.setCursorPos; local g, g = self.term.getSize()
        g = b((g + 1) / 2) * 2; local b = true; local h = 1; local i = {}
        local j = {}
        for g = 1, g do
            local k = ""
            if b then
                k = ("\143"):rep(self.width)
                for b = 1, self.width do
                    i[b] = f(a[h][b])
                    j[b] = f(a[h + 1][b])
                end
            else
                k = ("\131"):rep(self.width)
                for b = 1, self.width do
                    i[b] = f(a[h - 1][b])
                    j[b] = f(a[h][b])
                end
            end; e(1, g)
            c(k, d(i), d(j))
            b = not b; h = h + (b and 1 or 2)
        end
    end; function c:resize(a, b)
        b = e(b)
        if self.height > b then
            for a = 1, self.height - b do table.remove(self.data) end
        elseif self.height < b then
            for b = self.height + 1, b do
                self.data[b] = {}
                for a = 1, a do self.data[b][a] = colors.black end
            end
        end; if self.width > a then
            for b = 1, b do for a = 1, self.width - a - 1 do table.remove(self.data[b]) end end
        elseif self.width < a then
            for b = 1, b do
                for a = self.width + 1, a do
                    self.data[b][a] =
                        colors.black
                end
            end
        end; self.width = a; self.height = b
    end; function a.newCanvas(a, b, d)
        local f = {}
        if (not b or not d) then if a then b, d = a.getSize() else b, d = term.getSize() end end; d = e(d)
        f.width = b; f.height = d; f.term = a or term; f.setPixel = c.setPixel; f.resize = c.resize; f.render = c.render; f.owner =
        "neat"
        local a = {}
        for c = 1, d do
            a[c] = {}
            for b = 1, b do a[c][b] = colors.black end
        end; f.data = a; return f
    end; function a.own(a)
        a.render = c.render; a.resize = c.resize; a.setPixel = c.setPixel; a.owner = "neat"
    end; return a
end; package.preload["obsi2.graphics.nfpParser"] = function()
    local a = {}
    function a.consise(a, b, c)
        for c = 1, c do
            a[c] = a[c] or {}
            for b = 1, b do a[c][b] = a[c][b] or -1 end
        end; return a
    end; function a.parse(b)
        local c, d = 1, 1; local e = 0; local f = {}
        local g = {}
        f.data = g; for a = 1, #b do
            local b = b:sub(a, a)
            if not tonumber(b, 16) and b ~= "\n" and b ~= " " then
                return nil,
                    ("Unknown character (%s) at %s\nMake sure your image is valid .nfp"):format(b, a)
            end; if b == "\n" then
                d = d + 1; c = 1
            else
                if not g[d] then g[d] = {} end; g[d][c] = (b == " ") and -1 or 2 ^ tonumber(b, 16)
                e = math.max(e, c)
                c = c + 1
            end
        end; f.width = e; f.height = d; a.consise(g, e, d)
        return f
    end; return a
end; package.preload["obsi2.system"] = function()
    local a = {}
    local b; local c; local d = _HOST:match("%(.-%)"):sub(2, -2)
    local e = _HOST:sub(15, 21)
    if _HOST:lower():match("minecraft") then c = false else c = true end; do
        local a = shell.programs()
        for c = 1, #a do if a[c] == "multishell" then b = true end end
    end; function a.isAdvanced() return b end; function a.isEmulated() return c end; function a.getHost() return d end; function a.getVersion()
        return
            e
    end; function a.getClockSpeed()
        if config then return config.get("clockSpeed") end; return 20
    end; return a
end; package.preload["obsi2.audio"] = function()
    local a; local b = require("obsi2.audio.onbParser")
    local c = require("obsi2.audio.nbsParser")
    local d = os.clock()
    local e = {}
    local f = {}
    local g = false; local h = {}
    h.sounds = {}
    h.max = 0; local i = {}
    function e.playNote(a, b, c, d, e)
        d = math.max(math.min(d or 1, 3), 0)
        c = math.max(math.min(c, 24), 0)
        e = e or 0; i[#i + 1] = { pitch = c, speaker = a, instrument = b, volume = d, latency = e }
        table.sort(i, function(a, b) return a.latency < b.latency end)
    end; function e.playSound(a, b, c, d, e)
        d = math.max(math.min(d or 1, 3), 0)
        c = math.max(math.min(c, 24), 0)
        e = e or 0; i[#i + 1] = { pitch = c, speaker = a, sound = b, volume = d, latency = e }
        table.sort(i, function(a, b) return a.latency < b.latency end)
    end; function e.isAvailable() return not g end; function e.refreshChannels()
        local a = { peripheral.find("speaker") }
        if #a ~= 0 then
            f = a; g = false
        else
            if periphemu then
                periphemu.create("ObsiSpeaker", "speaker")
                f[1] = peripheral.wrap("ObsiSpeaker")
                g = false
            else
                f[1] = { playAudio = function() end, playNote = function() end, playSound = function() end, stop = function() end }
                g = true
            end
        end
    end; function e.getChannelCount() return #f end; function e.isPlaying() return #i > 0 or #h > 0 end; function e.notesPlaying()
        return #
            i
    end; function e.newSound(d)
        local a, e = a.read(d)
        if not a then error(e) end; local b, e = b.parseONB(a)
        if b then return b end; local a, b = c.parseNBS(a)
        if a then return a end; if d:sub(-4):lower() == ".onb" then
            error(e)
        elseif d:sub(-4):lower() == ".nbs" then
            error(b)
        else
            error(("Extension of the audio is not supported: %s"):format(d), 2)
        end
    end; function e.play(a, b)
        local a = { audio = a, startTime = os.clock(), holdTime = os.clock(), lastNote = 1, loop = b or false, playing = true, volume = 1 }
        for b = 1, h.max + 1 do
            if not h.sounds[b] then
                h.sounds[b] = a; if b > h.max then h.max = b end; return b
            end
        end; return -1
    end; function e.stop(a)
        if type(a) == "number" then
            h.sounds[a] = nil; return
        end; for b = 1, h.max do
            local c = h.sounds[b]
            if c then if c.audio == a then h.sounds[b] = nil end end
        end
    end; function e.isID(a, b)
        if h.sounds[b] then return h.sounds[b].audio == a end; return false
    end; local function b(a)
        if a.playing then
            a.holdTime = os.clock()
            a.playing = false
        end
    end; function e.pause(a)
        if type(a) == "number" then
            local a = h.sounds[a]
            if a then b(a) end; return
        end; for c = 1, h.max do
            local c = h.sounds[c]
            if c then if c.audio == a then b(c) end end
        end
    end; local function b(a)
        if not a.playing then
            a.startTime = os.clock() + a.startTime - a.holdTime; a.playing = true; local b = a.audio.notes[a.lastNote]
            while b and b.timing + a.startTime < d do
                a.lastNote = a.lastNote + 1; b = a.audio.notes[a.lastNote]
            end; if a.lastNote > #a.audio.notes then
                a.lastNote = 1; a.startTime = os.clock()
            end
        end
    end; function e.unpause(a)
        if type(a) == "number" then
            local a = h.sounds[a]
            if a then b(a) end; return
        end; for c = 1, h.max do
            local c = h.sounds[c]
            if c and c.audio == a then b(c) end
        end
    end; local function b(a, b) a.volume = b end; function e.setVolume(a, c)
        if type(a) == "number" then
            local a = h.sounds[a]
            if a then b(a, c) end; return
        end; for d = 1, h.max do
            local d = h.sounds[d]
            if d and d.audio == a then b(d, c) end
        end
    end; function e.getVolume(a) return h.sounds[a] and h.sounds[a].volume or 0 end; function e.isPaused(a)
        return h
            .sounds[a] and h.sounds[a].playing or false
    end; local function b(a)
        if a == 0 then a = 0.025 end; d = d + a; for b, c in ipairs(i) do
            c.latency = c.latency - a; if c.latency <= 0 then
                local a = f[((c.speaker - 1) % #f) + 1]
                if c.sound then a.playSound(c.sound, c.volume, c.pitch) else a.playNote(c.instrument, c.volume, c.pitch) end; table
                    .remove(i, b)
            end
        end; for a = 1, h.max do
            local b = h.sounds[a]
            if b and b.playing then
                local c = true; local e = 0; while c do
                    e = e + 1; if e > 1000 then break end; c = false; local e = b.audio.notes[b.lastNote]
                    if b.startTime + e.timing < d then
                        local a = f[(e.speaker - 1) % #f + 1]
                        a.playNote(e.instrument, math.min(e.volume * b.volume, 3), e.pitch)
                        b.lastNote = b.lastNote + 1
                    end; if b.lastNote > #b.audio.notes then
                        if b.loop then
                            b.lastNote = 1; b.startTime = d
                        else
                            h.sounds[a] = nil
                        end
                    elseif b.audio.notes[b.lastNote].timing < d - b.startTime then
                        c = true
                    end
                end
            end
        end
    end; local function c(c)
        a = c; e.refreshChannels()
        return e, b
    end; return c
end; package.preload["obsi2.audio.nbsParser"] = function()
    local a = {}
    function a.parseNBS(a)
        local a = string.gsub(a, "\r\n", "\n")
        local b = 1; local c = string.byte; local d = bit.blshift; local function e()
            local a = a:sub(b, b + 3)
            b = b + 4; if #a < 4 then return end; local b = c(a, 1)
            local e = c(a, 2)
            local f = c(a, 3)
            local a = c(a, 4)
            return b + d(e, 8) + d(f, 16) + d(a, 24)
        end; local function f()
            local a = a:sub(b, b + 1)
            b = b + 2; if #a < 2 then return end; local b = c(a, 1)
            local a = c(a, 2)
            return b + d(a, 8)
        end; local function d()
            local a = a:sub(b, b)
            b = b + 1; return c(a, 1)
        end; local function c()
            local c = e()
            if c then
                local a = a:sub(b, b + c - 1)
                b = b + c; return a
            end
        end; local a = {}
        a.zeros = f()
        local e = a.zeros ~= 0; local g = 0; if e then
            a.length = a.zeros; a.zeros = nil
        else
            g = d()
            a.nbs_version = g; a.vanilla_instrument_count = d()
            if g >= 3 then a.length = f() end
        end; a.layer_count = f()
        a.name = c()
        a.author = c()
        a.ogauthor = c()
        a.desc = c()
        a.tempo = f() or 1000; b = b + 23; c()
        if g >= 4 then
            a.loop = d()
            a.max_loops = d()
            a.loop_start_tick = f()
        end; local b = a.tempo / 100; local b = 1 / b; local h = {}
        local i = -1; while true do
            local a = f()
            if a == 0 then break end; i = i + a; local a = 1; h[i] = {}
            local b = -1; while true do
                local c = f()
                b = b + c; if c == 0 then break end; local c = d() + 1; local j = d()
                local k, l, m; if not e then
                    if g >= 4 then
                        k = d() / 100; l = d() - 100; m = f()
                    end
                end; h[i][a] = {
                    inst = c,
                    note = j,
                    velocity = k or 1,
                    panning = l or 0,
                    fine_pitch = m,
                    layer =
                        b + 1
                }
                a = a + 1
            end
        end; local e = {}
        for a = 1, a.layer_count do
            local b = c()
            local c; if g > 0 then
                d()
                c = d() / 100; d()
            end; local b = { name = b, velocity = c or 1 }
            e[a] = b
        end; for a = 0, i do
            local a = h[a]
            if a then
                for b = 1, #a do
                    local a = a[b]
                    local b = a.layer; local b = e[b]
                    a.velocity_layer = b.velocity
                end
            end
        end; local c = d()
        if c and c ~= 0 then error(("Sorry, no custom instruments! Count: %s"):format(c), 3) end; local c = {
            name = a
                .name,
            description = a.desc,
            bpm = a.tempo * 60,
            duration = -1,
            notes = {}
        }
        local d = 0; local e = 0; local f = {}
        local g = { "harp", "bass", "basedrum", "snare", "hat", "guitar", "flute", "bell", "chime", "xylophone",
            "iron_xylophone", "cow_bell", "didgeridoo", "bit", "banjo", "pling" }
        while true do
            local c = h[d]
            if c then
                for a = 1, #c do
                    local a = c[a]
                    local b = a.inst; local c = a.velocity * a.velocity_layer; local a = a.note - 33; if a > 24 then
                        a =
                            a % 12 + 12
                    elseif a < 0 then
                        a = a % 12
                    end; if b <= 16 then
                        local b = g[b]
                        f[#f + 1] = { instrument = b, volume = c, pitch = a, speaker = 1, timing = e }
                    end
                end
            end; local c = false; local f = 0; for a = d + 1, a.length do
                if h[a] then
                    c = true; f = a - d; d = a; break
                end
            end; if not c then break end; e = e + b * f
        end; c.duration = e; table.sort(f, function(a, b) return a.timing < b.timing end)
        c.notes = f; return c
    end; return a
end; package.preload["obsi2.audio.onbParser"] = function()
    local a = {}
    function a.parseONB(a)
        if a:sub(-1) ~= "\n" then a = a .. "\n" end; local b = {}
        for a in a:gmatch("(.-)\n") do b[#b + 1] = a end; if b[1] ~= "ONB,Obsi NoteBlock" then
            return nil,
                "File doesn't have ONB signature"
        end; local a = b[2]
        local c = b[3]
        local d = tonumber(b[4]) or 60; local e = 0; local f = {}
        for a in (b[5] .. ","):gmatch("(.-),") do f[#f + 1] = a end; local g = {}
        for a = 6, #b do
            local a = b[a] .. ","
            if a:sub(1, 1) ~= "#" and a:find("%w") then
                local b = {}
                local c = 1; local h; for d = 1, #f do
                    h = a:find(",", c)
                    if not h then
                        if f[d] == "volume" then b[f[d]] = 1 end
                    else
                        b[f[d]] = a:sub(c, h - 1)
                        c = h + 1
                    end
                end; local a = {}
                if not b.timing then a[#a + 1] = "timing" end; if not b.pitch then a[#a + 1] = "pitch" end; if not b.instrument then
                    a[#a + 1] =
                    "instrument"
                end; if #a > 0 then
                    local b = ""
                    for c, d in ipairs(a) do
                        b = b .. d; if c ~= #a then b = b .. ", " end
                    end; return nil, ("Fields like: {%s} are not present!"):format(b)
                end; b.pitch = tonumber(b.pitch)
                b.timing = tonumber(b.timing) * (60 / d)
                e = math.max(e, b.timing + (60 / d))
                b.speaker = tonumber(b.speaker) or 1; b.volume = tonumber(b.volume) or 1; g[#g + 1] = b
            end
        end; table.sort(g, function(a, b) return a.timing < b.timing end)
        return { name = a, description = c, bpm = d, notes = g, duration = e }
    end; return a
end; package.preload["obsi2.keyboard"] = function()
    local a = {}
    a.keys = {}
    a.scancodes = {}
    function a.isDown(b) return a.keys[b] or false end; function a.isScancodeDown(b) return a.scancodes[b] or false end; return
        a
end; return package.preload["obsi2"]()
--[[
OBSI 2 LICENSE:

MIT License

Copyright (c) 2024 simadude

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]
--[[
PIXELBOX LICENSE:

MIT License

Copyright (c) 2022 Oliver Caha

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]
--[[
NBSTUNES LICENSE:

MIT License

Copyright (c) 2023 Xella

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]

package.preload["obsi2"] = function()
local gamePath = fs.getDir(shell.getRunningProgram())

---@class obsi
local obsi = {}

---@class obsi.Config
---@field maxfps number
---@field mintps number
---@field multiUpdate boolean
---@field renderingAPI obsi.RenderingName
---@field sleepOption 1|2
local config = {
	maxfps = 20,
	mintps = 60,
	multiUpdate = true,
	renderingAPI = "basic",
	sleepOption = 1
}

local canvas
local winh
---@type fun(), fun(), fun(), fun(), fun()
local soundLoop, mouseDown, mouseMove, mouseUp, setFps
local emptyFunc = function(...) end
---@type fun()
local fsInit
obsi.fs, fsInit = require("obsi2.fs")(gamePath)
---@type obsi.system
obsi.system = require("obsi2.system")
if not periphemu then
	config.sleepOption = 2
end
---@type obsi.graphics, obsi.InternalCanvas, Window
obsi.graphics, canvas, winh = require("obsi2.graphics")(obsi.fs, config.renderingAPI)
obsi.timer, setFps = require("obsi2.timer")()
obsi.keyboard = require("obsi2.keyboard")
obsi.mouse, mouseDown, mouseUp, mouseMove = require("obsi2.mouse")()
obsi.audio, soundLoop = require("obsi2.audio")(obsi.fs)
obsi.state = require("obsi2.state")
obsi.debug = false
obsi.version = "2.0.2"

obsi.load = emptyFunc
---@type fun(dt: number)
obsi.update = emptyFunc
---@type fun(dt: number)
obsi.draw = emptyFunc
---@type fun(x: number, y: number, button: integer)
obsi.onMousePress = emptyFunc
---@type fun(x: number, y: number, button: integer)
obsi.onMouseRelease = emptyFunc
---@type fun(x: number, y: number)
obsi.onMouseMove = emptyFunc
---@type fun(key: integer)
obsi.onKeyPress = emptyFunc
---@type fun(key: integer)
obsi.onKeyRelease = emptyFunc
---@type fun(wind: Window)
obsi.onWindowFlush = emptyFunc -- sends a window object as a first argument, which you can mutate if you wish.
---@type fun(w: integer, h: integer)
obsi.onResize = emptyFunc	-- sends width and height of the window in characters, not pixels. 
---@type fun(eventData: table)
obsi.onEvent = emptyFunc -- for any events that aren't caught! Runs last so that you won't mutate it.
---@type fun()
obsi.onQuit = emptyFunc -- called when Obsi recieves "terminate" event.

local quit = false
function obsi.quit()
	quit = true
end

local function clock()
	return periphemu and os.epoch(("nano")--[[@as "local"]])/10^9 or os.clock()
end

---@param time number
local function sleepRaw(time)
	local timerID = os.startTimer(time)
	while true do
		local _, tID = os.pullEventRaw("timer")
		if tID == timerID then
			break
		end
	end
end

local t = clock()
local dt = 1/config.maxfps

local drawTime = t
local updateTime = t
local frameTime = t
local lastSecond = t
local frames = 0

fsInit() -- use game's path

local function gameLoop()
	obsi.load()
	while true do
		local startTime = clock()
		if config.multiUpdate then
			local updated = false
			for _ = 1, dt/(1/config.mintps) do
				obsi.update(1/config.mintps)
				updated = true
			end
			if not updated then
				obsi.update(dt)
			end
		else
			obsi.update(dt)
		end
		updateTime = clock() - startTime
		obsi.draw(dt)
		drawTime = clock() - updateTime - startTime
		obsi.graphics.setCanvas()
		soundLoop(dt)
		if obsi.debug then
			local bg, fg = obsi.graphics.bgColor, obsi.graphics.fgColor
			obsi.graphics.bgColor, obsi.graphics.fgColor = colors.black, colors.white
			obsi.graphics.write("Obsi "..obsi.version, 1, 1)
			obsi.graphics.write(obsi.system.getHost(), 1, 2)
			obsi.graphics.write(("rendering: %s [%sx%s -> %sx%s]"):format(obsi.graphics.getRenderer(), obsi.graphics.getWidth(), obsi.graphics.getHeight(), obsi.graphics.getPixelSize()), 1, 3)
			obsi.graphics.write(("%s FPS"):format(obsi.timer.getFPS()), 1, 4)
			obsi.graphics.write(("%0.2fms update"):format(updateTime*1000), 1, 5)
			obsi.graphics.write(("%0.2fms draw"):format(drawTime*1000), 1, 6)
			obsi.graphics.write(("%0.2fms frame"):format(frameTime*1000), 1, 7)
			obsi.graphics.bgColor, obsi.graphics.fgColor = bg, fg
		end
		-- obsi.debugger.print(("%0.2fms frame [%sx%s]"):format(frameTime*1000, obsi.graphics.getPixelSize()))
		obsi.graphics.flushAll()
		obsi.onWindowFlush(winh)
		obsi.graphics.show()
		if clock() > lastSecond+1 then
			lastSecond = clock()
			setFps(frames/1)
			frames = 0
		else
			frames = frames + 1
		end
		frameTime = clock() - startTime
		if config.sleepOption == 1 then
			if frameTime > 1/config.maxfps then
				sleepRaw(0)
			else
				sleepRaw((1/config.maxfps-frameTime)/1.1)
			end
		else
			sleepRaw(0)
		end
		obsi.graphics.clear()
		obsi.graphics.bgColor, obsi.graphics.fgColor = colors.black, colors.white
		obsi.graphics.resetOrigin()
		dt = clock()-t
		t = clock()
	end
end

local function eventLoop()
	while true do
		local eventData = {os.pullEventRaw()}
		if eventData[1] == "mouse_click" then
			mouseDown(eventData[3], eventData[4], eventData[2])
			obsi.onMousePress(eventData[3], eventData[4], eventData[2])
		elseif eventData[1] == "mouse_up" then
			mouseUp(eventData[3], eventData[4], eventData[2])
			obsi.onMouseRelease(eventData[3], eventData[4], eventData[2])
		elseif eventData[1] == "mouse_move" then -- apparently the second index is only there for compatibility? Alright.
			mouseMove(eventData[3], eventData[4])
			obsi.onMouseMove(eventData[3], eventData[4])
		elseif eventData[1] == "mouse_drag" then
			mouseMove(eventData[3], eventData[4])
			obsi.onMouseMove(eventData[3], eventData[4])
		elseif eventData[1] == "term_resize" or eventData[1] == "monitor_resize" then
			local w, h = term.getSize()
			winh.reposition(1, 1, w, h)
			canvas:resize(w, h)
			obsi.graphics.pixelWidth, obsi.graphics.pixelHeight = canvas.width, canvas.height
			obsi.graphics.width, obsi.graphics.height = w, h
			obsi.onResize(w, h)
		elseif eventData[1] == "key" and not eventData[3] then
			obsi.keyboard.keys[keys.getName(eventData[2])] = true
			obsi.keyboard.scancodes[eventData[2]] = true
			obsi.onKeyPress(eventData[2])

			-- --the code below is only for testing!

			-- if eventData[2] == keys.l then
			-- 	local rentab = {
			-- 		["pixelbox"] = "neat",
			-- 		["neat"] = "basic",
			-- 		["basic"] = "pixelbox",
			-- 	}
			-- 	obsi.graphics.setRenderer(rentab[obsi.graphics.getRenderer()] or "neat")
			-- elseif eventData[2] == keys.p then
			-- 	obsi.debug = not obsi.debug
			-- end
		elseif eventData[1] == "key_up" then
			obsi.keyboard.keys[keys.getName(eventData[2])] = false
			obsi.keyboard.scancodes[eventData[2]] = false
			obsi.onKeyRelease(eventData[2])
		elseif eventData[1] == "terminate" or quit then
			obsi.onQuit()
			obsi.graphics.clearPalette()
			term.setBackgroundColor(colors.black)
			term.clear()
			term.setCursorPos(1, 1)
			return
		end
		obsi.onEvent(eventData)
	end
end

local function catch(err)
	obsi.graphics.clearPalette()
	term.setBackgroundColor(colors.black)
	term.clear()
	term.setCursorPos(1, 1)
	printError(debug.traceback(err, 2))
	-- if obsi.debugger then
	-- 	obsi.debugger.print(debug.traceback(err, 2))
	-- end
end

function obsi.init()
	parallel.waitForAny(function() xpcall(gameLoop, catch) end, function() xpcall(eventLoop, catch) end)
end

return obsi

end
package.preload["obsi2.state"] = function()
---@class obsi.state
local state = {}
local globals = {}
---@type table<string, obsi.Scene>
local scenes = {}

---@return obsi.Scene
---@param sceneName string
function state.newScene(sceneName)
	---@class obsi.Scene
	local scene = {}

	scene.variables = {}

	---@param varName string
	---@param value any
	function scene:setVariable(varName, value)
		self.variables[varName] = value
	end

	---@param varName string
	function scene:getVariable(varName)
		return self.variables[varName]
	end

	scene.objects = {}

	scenes[sceneName] = scene
	return scene
end

---@param sceneName string
---@return obsi.Scene?
function state.getScene(sceneName)
	return scenes[sceneName]
end

---@param sceneName string
---@param scene obsi.Scene?
function state.setScene(sceneName, scene)
	scenes[sceneName] = scene
end

function state.everyScene()
	return pairs(scenes)
end

---@param name string
---@param val any
function state.setGlobal(name, val)
	globals[name] = val
end

---@return any
function state.getGlobal(name)
	return globals[name]
end

state.newScene("Default")

return state
end
package.preload["obsi2.timer"] = function()
---@class obsi.timer
local timer = {}
local initTime = os.clock()
local fps = 0

---@param n integer
local function setFPS(n)
	fps = n
end

---@return number # Time in seconds since the initialization of `timer` module.
function timer.getTime()
	return os.clock() - initTime
end

---@return integer # Returns how many Frames have been drawn since last second.
function timer.getFPS()
	return fps
end

return function() return timer, setFPS end
end
package.preload["obsi2.fs"] = function()
---@class obsi.fs
local obsifs = {}
local useGamePath = false
local gamePath = ""
local fs = vfs or fs

---@param path string
---@return string
local function getPath(path)
	-- if useGamePath then
	-- 	local s = fs.combine(gamePath, path):reverse():sub(-#gamePath):reverse()
	-- 	if s ~= gamePath then
	-- 		return nil, ("Attempt to get outside of the game's directory: %s"):format(s)
	-- 	end
	-- end
	return useGamePath and fs.combine(gamePath, path) or path
end

---@param dirPath any
---@return boolean, string?
function obsifs.createDirectory(dirPath)
	local dp, e = getPath(dirPath)
	if not dp then
		return false, e
	end
	local suc = pcall(fs.makeDir, dp)
	return suc
end

---@param dirPath any
---@return table|nil, string?
function obsifs.getDirectoryItems(dirPath)
	local dp, e = getPath(dirPath)
	if not dp then
		return nil, e
	end
	local suc, res = pcall(fs.list, dp)
	return suc and res or {}
end

---Creates a new obsi.File object. Does not necessarily create a new file. Needs to be opened manually for writing.
---@param filePath string
---@param fileMode? fileMode
---@return obsi.File?, string?
function obsifs.newFile(filePath, fileMode)
	local fp, e = getPath(filePath)
	if not fp then
		return nil, e
	end
	fileMode = fileMode or "c"

	---@class obsi.File
	local file = {}

	file.path = fp
	file.name = fs.getName(filePath)

	---@alias fileMode "c"|"r"|"w"|"a"
	---@type fileMode
	file.mode = fileMode

	---@param mode fileMode
	function file:open(mode)
		if mode == "c" then
			return
		end
		local f, e = fs.open(self.path, mode and mode.."b")
		if not f then
			return false, e
		end
		self.file = f
		return true
	end

	if fileMode ~= "c" then
		local b, e = file:open(fileMode)
		if not b then
			return nil, e
		end
	end

	function file:getMode()
		return self.mode
	end

	function file:write(data, size)
		if self.file and (self.mode == "w" or self.mode == "a") then
			size = size or #data
			self.file.write(data:sub(size))
			return true
		else
			return false, "File is not opened for writing"
		end
	end

	function file:flush()
		if self.mode == "w" and self.file then
			self.file.flush()
			return true
		else
			return false, "File is not opened for writing"
		end
	end

	function file:read(count)
		if not self.file then
			local _, r = self:open("r")
			if r then
				return nil, r
			end
		elseif self.mode ~= "r" then
			return nil, "File is not opened for reading"
		end
		return count and self.file.read(count) or self.file.readAll()
	end

	function file:lines()
		if not self.file then
			local _, r = self:open("r")
			if r then
				error(r)
			end
		elseif self.mode ~= "r" then
			return nil, "File is not opened for reading"
		end
		return function ()
			return self.file.readLine(false)
		end
	end

	function file:seek(pos)
		if self.file then
			self.file.seek("set", pos)
		end
	end

	function file:tell()
		if self.file then
			return self.file.seek("cur", 0)
		end
	end

	function file:close()
		if self.file then
			self.file.close()
		end
		self.file = nil
		self.mode = "c"
	end

	return file
end

---@class obsi.FileInfo
---@field type "directory"|"file"
---@field size number
---@field modtime number
---@field createtime number
---@field readonly boolean

---@param filePath string
---@return obsi.FileInfo?
function obsifs.getInfo(filePath)
	filePath = getPath(filePath)
	local e, info = pcall(fs.attributes, filePath)
	if not info then
		return nil
	end
	return {
		type = (info.isDir and "directory" or "file"),
		size = info.size,
		modtime = info.modified,
		createtime = info.created,
		readonly = info.isReadOnly
	}
end

---Returns contents of the file in a form of a string.
---If the file can't be read, then nil and an error message is returned.
---@param filePath string
---@return string|nil, nil|string
function obsifs.read(filePath)
	filePath = getPath(filePath)
	local fh, e = fs.open(filePath, "rb")
	if not fh then
		return nil, e
	end
	local contents = fh.readAll() or ""
	fh.close()
	return contents
end

---@param filePath string
---@param data string
---@return boolean, string?
function obsifs.write(filePath, data)
	filePath = getPath(filePath)
	local fh, e = fs.open(filePath, "wb")
	if not fh then
		return false, e
	end
	fh.write(data)
	fh.close()
	return true
end

---@param path string
---@return boolean, string?
function obsifs.remove(path)
	path = getPath(path)
	local r, e = pcall(fs.delete, path)
	return r, e
end

---Returns an iterator, similar to `io.lines`.
---If the file can't be read, then the function errors.
---@param filePath string
---@return fun(): string|nil
function obsifs.lines(filePath)
	filePath = getPath(filePath)
	local fh, e = fs.open(filePath, "rb")
	if not fh then
		error(e)
	end
	return function ()
		return fh.readLine(false) or fh.close()
	end
end

local function init(path)
	gamePath = fs.combine(path)
	return obsifs, function() useGamePath = true end
end

return init
end
package.preload["obsi2.mouse"] = function()
---@class obsi.mouse
local mouse = {}
local buttons = {}
local mx, my = 0, 0

---Returns the position of the mouse on X axis. 
---@return integer
function mouse.getX()
	return mx
end

---Returns the position of the mouse on Y axis.
---@return integer
function mouse.getY()
	return my
end

---Returns the position of the mouse.
---@return integer, integer
function mouse.getPosition()
	return mx, my
end

---Returns either true or false if "mouse_move" event can fire on CraftOS-PC.
---@return boolean
function mouse.canMove()
	return not not (config and (config.get("mouse_move_throttle") >= 0))
end

---Returns if true or false if the mouse button is down.
---@param button integer
function mouse.isDown(button)
	return buttons[button] or false
end

---@param qx integer
---@param qy integer
---@param b integer
local function setMouseDown(qx, qy, b)
	mx, my = qx, qy
	buttons[b] = true
end

---@param qx integer
---@param qy integer
---@param b integer
local function setMouseUp(qx, qy, b)
	mx, my = qx, qy
	buttons[b] = false
end

---@param qx integer
---@param qy integer
local function setMousePos(qx, qy)
	mx, my = qx or mx, qy or my
end

return function ()
	return mouse, setMouseDown, setMouseUp, setMousePos
end
end
package.preload["obsi2.graphics"] = function()
---@type obsi.fs
local fs
local renderers = {}
renderers.neat = require("obsi2.graphics.neat")
renderers.pixelbox = require("obsi2.graphics.pixelbox")
renderers.basic = require("obsi2.graphics.basic")
local nfp = require("obsi2.graphics.nfpParser")
local orli = require("obsi2.graphics.orliParser")
---@type Window
local wind
do
	local w, h = term.getSize()
	wind = window.create(term.current(), 1, 1, w, h, false)
end

---@class obsi.graphics
local graphics = {}

local floor, ceil, abs, max, min = math.floor, math.ceil, math.abs, math.max, math.min

---@alias obsi.InternalCanvas neat.Canvas|pixelbox.box|basic.Canvas
---@alias obsi.RenderingName "basic"|"neat"|"pixelbox"

---@type obsi.InternalCanvas
local internalCanvas
---@type obsi.Canvas|obsi.InternalCanvas
local currentCanvas

---@class obsi.TextPiece
---@field x integer
---@field y integer
---@field text string
---@field fgColor string?
---@field bgColor string?

---@type obsi.TextPiece[]
local textBuffer = {}

graphics.originX = 1
graphics.originY = 1

graphics.width, graphics.height = term.getSize()

graphics.fgColor = colors.white
graphics.bgColor = colors.black

---@param value any
---@param paramName string
---@param expectedType type
local function checkType(value, paramName, expectedType)
	if type(value) ~= expectedType then
		error(("Argument '%s' must be a %s, not a %s"):format(paramName, expectedType, type(value)), 3)
	end
end

---@type table<integer, string>
local toBlit = {}
for i = 0, 15 do
	toBlit[2^i] = ("%x"):format(i)
end

local function getBlit(color)
	return toBlit[color]
end

---Sets a specific palette color
---@param color string|ccTweaked.colors.color
---@param r number value within the range [0-1]
---@param g number value within the range [0-1]
---@param b number value within the range [0-1]
function graphics.setPaletteColor(color, r, g, b)
	if type(color) == "string" then
		if #color ~= 1 then
			error(("Argument `color: string` must be 1 character long, not %s"):format(#color))
		end
		color = tonumber(color, 16)
		if not color then
			error(("Argument `color: string` must be a valid hex character, not %s"):format(color))
		end
		color = 2^color
	elseif type(color) ~= "number" then
		error(("Argument `color` must be either integer or string, not %s"):format(type(color)))
	end
	checkType(r, "r", "number")
	checkType(g, "g", "number")
	checkType(b, "b", "number")
	wind.setPaletteColor(color, r, g, b)
end

---@param x integer
---@param y integer
function graphics.offsetOrigin(x, y)
	checkType(x, "x", "number")
	checkType(y, "y", "number")
	graphics.originX = graphics.originX + floor(x)
	graphics.originY = graphics.originY + floor(y)
end

---@param x integer
---@param y integer
function graphics.setOrigin(x, y)
	checkType(x, "x", "number")
	checkType(y, "y", "number")
	graphics.originX = floor(x)
	graphics.originY = floor(y)
end

function graphics.resetOrigin()
	graphics.originX = 1
	graphics.originY = 1
end

---@return integer, integer
function graphics.getOrigin()
	return graphics.originX, graphics.originY
end

function graphics.getPixelWidth()
	return graphics.pixelWidth
end

function graphics.getPixelHeight()
	return graphics.pixelHeight
end

function graphics.getWidth()
	return graphics.width
end

function graphics.getHeight()
	return graphics.height
end

function graphics.getSize()
	return graphics.width, graphics.height
end

function graphics.getPixelSize()
	return graphics.pixelWidth, graphics.pixelHeight
end

function graphics.termToPixelCoordinates(x, y)
	if internalCanvas.owner == "basic" then
		return x, y
	elseif internalCanvas.owner == "neat" then
		return x, floor(y*1.5)
	elseif internalCanvas.owner == "pixelbox" then
		return x*2, y*3
	end
end

function graphics.pixelToTermCoordinates(x, y)
	if internalCanvas.owner == "basic" then
		return x, y
	elseif internalCanvas.owner == "neat" then
		return x, floor(y/1.5)
	elseif internalCanvas.owner == "pixelbox" then
		return floor(x/2), floor(y/3)
	end
end

---@param col ccTweaked.colors.color|string
---@return ccTweaked.colors.color
local function toColor(col)
	if type(col) == "string" then
		return 2^tonumber(col, 16)
	end
	return col
end

---@param color ccTweaked.colors.color|string
function graphics.setBackgroundColor(color)
	graphics.bgColor = toColor(color)
end

---@param color ccTweaked.colors.color|string
function graphics.setForegroundColor(color)
	graphics.fgColor = toColor(color)
end

---@return ccTweaked.colors.color
function graphics.getBackgroundColor()
	return graphics.bgColor
end

---@return ccTweaked.colors.color
function graphics.getForegroundColor()
	return graphics.fgColor
end

---@param x number
---@param y number
---@return boolean
local function inBounds(x, y)
	return (x >= 1) and (y >= 1) and (x <= currentCanvas.width) and (y <= currentCanvas.height)
end

---@param x number
---@param y number
---@param color? ccTweaked.colors.color
local function safeOffsetPixel(x, y, color)
	color = color or graphics.fgColor
	x, y = floor(x-graphics.originX+1), floor(y-graphics.originY+1)
	if inBounds(x, y) then
		currentCanvas:setPixel(x, y, color)
	end
end

---@param x number
---@param y number
function graphics.point(x, y)
	checkType(x, "x", "number")
	checkType(y, "y", "number")

	safeOffsetPixel(x, y)
end

---@param points table[]
function graphics.points(points)
	for i = 1, #points do
		local point = points[i]
		safeOffsetPixel(point[1], point[2])
	end
end

---Asked Claude to optimize this function.
---@param mode "fill"|"line"
---@param x integer
---@param y integer
---@param width integer
---@param height integer
function graphics.rectangle(mode, x, y, width, height)
	checkType(x, "x", "number")
	checkType(y, "y", "number")
	checkType(width, "width", "number")
	checkType(height, "height", "number")

	-- Get screen dimensions
	local screenWidth, screenHeight = graphics.getPixelSize()

	-- Adjust coordinates based on origin
	x = floor(x - graphics.originX + 1)
	y = floor(y - graphics.originY + 1)

	-- Clamp rectangle coordinates and dimensions to screen bounds
	local startX = max(1, x)
	local startY = max(1, y)
	local endX = min(screenWidth, x + width - 1)
	local endY = min(screenHeight, y + height - 1)

	-- If the rectangle is completely offscreen, return early
	if startX > endX or startY > endY then
		return
	end

	if mode == "fill" then
		for ry = startY, endY do
			for rx = startX, endX do
				currentCanvas:setPixel(rx, ry, graphics.fgColor)
			end
		end
	elseif mode == "line" then
		-- Left vertical line
		if x >= 1 and x <= screenWidth then
			for ry = startY, endY do
				currentCanvas:setPixel(x, ry, graphics.fgColor)
			end
		end
		-- Right vertical line
		local rightX = x + width - 1
		if rightX >= 1 and rightX <= screenWidth then
			for ry = startY, endY do
				currentCanvas:setPixel(rightX, ry, graphics.fgColor)
			end
		end
		-- Top horizontal line
		if y >= 1 and y <= screenHeight then
			for rx = startX, endX do
				currentCanvas:setPixel(rx, y, graphics.fgColor)
			end
		end
		-- Bottom horizontal line
		local bottomY = y + height - 1
		if bottomY >= 1 and bottomY <= screenHeight then
			for rx = startX, endX do
				currentCanvas:setPixel(rx, bottomY, graphics.fgColor)
			end
		end
	end
end

function graphics.line(point1, point2)
	local x1, y1 = floor(point1[1]), floor(point1[2])
	local x2, y2 = floor(point2[1]), floor(point2[2])
	local dx, dy = abs(x2-x1), abs(y2-y1)
	local sx, sy = (x1 < x2) and 1 or -1, (y1 < y2) and 1 or -1
	local err = dx-dy
	while x1 ~= x2 or y1 ~= y2 do
		safeOffsetPixel(x1, y1)
		local err2 = err * 2
		if err2 > -dy then
			err = err - dy
			x1 = x1 + sx
		end
		if err2 < dx then
			err = err + dx
			y1 = y1 + sy
		end
	end
	safeOffsetPixel(x2, y2)
end

---@class obsi.Image
---@field data integer[][]
---@field width integer
---@field height integer

local function getCorrectImage(imagePath, contents)
	local image, e2, e1
	image, e1 = orli.parse(contents)
	if image then
		return image
	end
	image, e2 = nfp.parse(contents)
	if image then
		return image
	end
	if imagePath:sub(-5):lower() == ".orli" then
		error(e1)
	elseif imagePath:sub(-4):lower() == ".nfp" then
		error(e2)
	else
		error(("Extension of the image is not supported: %s"):format(imagePath), 2)
	end
end

---@param imagePath string
---@return obsi.Image
function graphics.newImage(imagePath)
	local contents, e = fs.read(imagePath)
	if not contents then
		error(e)
	end
	local image = getCorrectImage(imagePath, contents)
	return image
end

---Returns a blank obsi.Image with a solid color. 
---@param width integer
---@param height integer
---@param filler? ccTweaked.colors.color|string
---@return obsi.Image
function graphics.newBlankImage(width, height, filler)
	checkType(width, "width", "number")
	checkType(height, "height", "number")

	filler = filler and toColor(filler) or -1
	width = floor(max(width, 1))
	height = floor(max(height, 1))

	local image = {}
	image.data = {}
	for y = 1, height do
		image.data[y] = {}
		for x = 1, width do
			image.data[y][x] = filler
		end
	end
	image.width = width
	image.height = height

	return image
end


---Returns an array of obsi.Image objects that represent the tiles on the Tilemap.
---@param imagePath string
---@return obsi.Image[]
function graphics.newImagesFromTilesheet(imagePath, tileWidth, tileHeight)
	local contents, e = fs.read(imagePath)
	if not contents then
		error(e)
	end
	local map = getCorrectImage(imagePath, contents)

	if map.width % tileWidth ~= 0 then
		error(("Tilemap width can't be divided by tile's width: %s and %s"):format(map.width, tileWidth))
	elseif map.height % tileHeight ~= 0 then
		error(("Tilemap height can't be divided by tile's height: %s and %s"):format(map.height, tileHeight))
	end

	local images = {}

	for ty = tileHeight, map.height, tileHeight do
		for tx = tileWidth, map.width, tileWidth do
			local image = graphics.newBlankImage(tileWidth, tileHeight, -1)
			for py = 1, tileHeight do
				for px = 1, tileWidth do
					image.data[py][px] = map.data[ty-tileHeight+py][tx-tileWidth+px]
				end
			end
			images[#images+1] = image
		end
	end

	return images
end

---Creates a new obsi.Canvas object.
---@param width integer?
---@param height integer?
---@return obsi.Canvas
function graphics.newCanvas(width, height)
	width, height = floor(width or internalCanvas.width), floor(height or internalCanvas.height)

	---@class obsi.Canvas
	local canvas = {}
	canvas.width = width
	canvas.height = height
	canvas.data = {}
	for y = 1, height do
		canvas.data[y] = {}
		for x = 1, width do
			canvas.data[y][x] = colors.black
		end
	end

	---@param x integer
	---@param y integer
	---@param color ccTweaked.colors.color
	function canvas:setPixel(x, y, color)
		self.data[y][x] = color
	end

	---@param x integer
	---@param y integer
	---@return ccTweaked.colors.color
	function canvas:getPixel(x, y)
		return self.data[y][x]
	end

	function canvas:clear()
		for y = 1, self.height do
			for x = 1, self.width do
				self.data[y][x] = graphics.bgColor
			end
		end
	end

	return canvas
end

---@param image obsi.Image
---@param x integer
---@param y integer
local function drawNoScale(image, x, y)
	local data = image.data
	for iy = 1, image.height do
		for ix = 1, image.width do
			if not data[iy] then
				error(("iy: %s, #image.data: %s"):format(iy, #data))
			end
			local pix = data[iy][ix]
			if pix > 0 then
				safeOffsetPixel(x+ix-1, y+iy-1, pix)
			end
		end
	end
end

---Draws an obsi.Image or obsi.Canvas at certain coordinates.
---@param image obsi.Image|obsi.Canvas
---@param x integer x position
---@param y integer y position
---@param sx? number x scale
---@param sy? number y scale
function graphics.draw(image, x, y, sx, sy)
	---@cast image obsi.Image
	checkType(x, "x", "number")
	checkType(y, "y", "number")
	sx = sx or 1
	sy = sy or 1

	-- check if the image out of the screen or if it's too small to be drawn
	if sx == 0 or sy == 0 then
		return
	elseif (sx > 0 and x-graphics.originX > currentCanvas.width) or (sy > 0 and y-graphics.originY > currentCanvas.height) then
		return
	end

	-- a little optimization to not bother with scaling
	if sx == 1 and sy == 1 then
		drawNoScale(image, x, y)
		return
	end
	local signsx = abs(sx)/sx
	local signsy = abs(sy)/sy
	sx = abs(sx)
	sy = abs(sy)
	-- variable naming:
	-- i_ - iterative variable
	-- p_ - pixel position on the image
	-- s_ - scale for each axis

	for iy = 1, image.height*sy do
		local py = ceil(iy/sy)
		for ix = 1, image.width*sx do
			local px = ceil(ix/sx)
			if not image.data[py] then
				error(("py: %s, #image.data: %s"):format(py, #image.data))
			end
			local pix = image.data[py][px]
			if pix > 0 then
				safeOffsetPixel(x+ix*signsx-signsx, y+iy*signsy-signsy, pix)
			end
		end
	end
end

--- Writes a text on the terminal.
---
--- Beware that it uses terminal coordinates and not pixel coordinates.
---@param text string
---@param x integer
---@param y integer
---@param fgColor? string|ccTweaked.colors.color
---@param bgColor? string|ccTweaked.colors.color
function graphics.write(text, x, y, fgColor, bgColor)
	checkType(text, "text", "string")
	checkType(x, "x", "number")
	checkType(y, "y", "number")
	local textPiece = {}
	textPiece.text = text
	textPiece.x = x
	textPiece.y = y

	fgColor = fgColor or graphics.fgColor
	bgColor = bgColor or graphics.bgColor

	if type(fgColor) == "number" then
		fgColor = getBlit(fgColor):rep(#text)
	elseif type(fgColor) == "string" and #fgColor == 1 then
		fgColor = fgColor:rep(#text)
	end
	---@cast fgColor string|nil

	if type(bgColor) == "number" then
		bgColor = getBlit(bgColor):rep(#text)
	elseif type(bgColor) == "string" and #bgColor == 1 then
		bgColor = bgColor:rep(#text)
	end
	---@cast bgColor string|nil

	if type(fgColor) ~= "string" then
		error("fgColor is not a number or a string!")
	elseif type(bgColor) ~= "string" then
		error("bgColor is not a number or a string!")
	end

	textPiece.fgColor = fgColor
	textPiece.bgColor = bgColor

	textBuffer[#textBuffer+1] = textPiece
end

---@class obsi.Palette
---@field data number[][]

---Creates a new obsi.Palette object.
---@param palettePath string
---@return obsi.Palette
function graphics.newPalette(palettePath)
	checkType(palettePath, "palettePath", "string")
	local fh, e = fs.newFile(palettePath, "r")
	if not fh then
		error(e)
	end

	local cols = {}
	for i = 1, 16 do
		local line = fh.file.readLine()
		if not line then
			error("File could not be read completely!")
		end
		local occurrences = {}
		for str in line:gmatch("%d+") do
			if not tonumber(str) then
				error(("Can't put %s as a number"):format(str))
			end
			occurrences[#occurrences+1] = tonumber(str)/255
		end
		if #occurrences > 3 then
			error("More colors than should be possible!")
		end
		cols[i] = {table.unpack(occurrences)}
	end

	fh:close()
	return {data = cols}
end

---@param palette obsi.Palette
function graphics.setPalette(palette)
	for i = 1, 16 do
		local colors = palette.data[i]
		wind.setPaletteColor(2^(i-1), colors[1], colors[2], colors[3])
	end
end

---@return obsi.Palette
function graphics.getPallete()
	local cols = {}
	local pal = {data = cols}
	for i = 1, 16 do
		cols[i] = {term.getPaletteColor(2^(i-1))}
	end
	return pal
end

function graphics.clearPalette()
	shell.run("clear", "palette")
end

---@param canvas obsi.Canvas|nil
function graphics.setCanvas(canvas)
	currentCanvas = canvas or internalCanvas
end

---@return obsi.Canvas|obsi.InternalCanvas
function graphics.getCanvas()
	return currentCanvas
end

---Internal function that clears the canvas.
function graphics.clear()
	for y = 1, currentCanvas.height do
		for x = 1, currentCanvas.width do
			currentCanvas:setPixel(x, y, graphics.bgColor)
		end
	end
end

---@param rend obsi.RenderingName
function graphics.setRenderer(rend)
	local renderer = renderers[rend]
	if renderer then
		renderer.own(internalCanvas)
		local w, h = graphics.getSize()
		internalCanvas:resize(w, h)
		graphics.pixelWidth, graphics.pixelHeight = internalCanvas.width, internalCanvas.height
	else
		error(("Unknown renderer name: %s"):format(rend))
	end
end

function graphics.getRenderer()
	return internalCanvas.owner
end

---Internal function that draws the canvas.
function graphics.flushCanvas()
	internalCanvas:render()
end

---Internal function that draws all the texts.
function graphics.flushText()
	for i = 1, #textBuffer do
		local textPiece = textBuffer[i]
		local text = textPiece.text
		if textPiece.x+#text >= 1 and textPiece.y >= 1 and textPiece.x <= graphics.getWidth() and textPiece.y <= graphics.getHeight() then
			wind.setCursorPos(textPiece.x, textPiece.y)
			wind.blit(text, textPiece.fgColor or getBlit(graphics.fgColor):rep(#text), textPiece.bgColor or getBlit(graphics.bgColor):rep(#text))
		end
	end
	textBuffer = {}
end

function graphics.flushAll()
	graphics.flushCanvas()
	graphics.flushText()
end

function graphics.show()
	wind.setVisible(true)
	wind.setVisible(false)
end

return function (obsifs, renderingAPI)
	internalCanvas = renderers[renderingAPI].newCanvas(wind)
	graphics.pixelWidth, graphics.pixelHeight = internalCanvas.width, internalCanvas.height
	currentCanvas = internalCanvas
	fs = obsifs
	return graphics, internalCanvas, wind
end

end
package.preload["obsi2.graphics.basic"] = function()
local basic = {}
local concat = table.concat

---@type table<integer, string>
local toBlit = {}
for i = 0, 15 do
	toBlit[2^i] = ("%x"):format(i)
end

local function getBlit(color)
	return toBlit[color]
end

local template = {}

function template:render()
	local canvasdata = self.data
	local blit = self.term.blit
	local setCursorPos = self.term.setCursorPos
	local fgcol = ("0"):rep(self.width)
	local txtstr = (" "):rep(self.width)
	local bgcoltab = {}
	for by = 1, self.height do
		for x = 1, self.width do
			bgcoltab[x] = getBlit(canvasdata[by][x])
		end
		setCursorPos(1, by)
		blit(txtstr, fgcol, concat(bgcoltab))
	end
end

function template:resize(w, h)
	if self.height > h then
		for y = 1, self.height-h do
			table.remove(self.data)
		end
	elseif self.height < h then
		for y = self.height, h do
			self.data[y] = {}
			for x = 1, w do
				self.data[y][x] = colors.black
			end
		end
	end
	if self.width > w then
		for y = 1, h do
			for x = 1, self.width-w-1 do
				table.remove(self.data[y])
			end
		end
	elseif self.width < w then
		for y = 1, h do
			for x = self.width+1, w do
				self.data[y][x] = colors.black
			end
		end
	end
	self.width = w
	self.height = h
end

---@param x integer
---@param y integer
---@param color ccTweaked.colors.color
function template:setPixel(x, y, color)
	self.data[y][x] = color
end

---@param terminal ccTweaked.term.Redirect?
---@param width integer?
---@param height integer?
function basic.newCanvas(terminal, width, height)
	---@class basic.Canvas
	local canvas = {}
	if (not width or not height) then
		if terminal then
			width, height = terminal.getSize()
		else
			width, height = term.getSize()
		end
	end

	canvas.width = width
	canvas.height = height
	canvas.term = terminal or term
	canvas.setPixel = template.setPixel
	canvas.resize = template.resize
	canvas.render = template.render
	canvas.owner = "basic"
	local data = {}
	for y = 1, height do
		data[y] = {}
		for x = 1, width do
			data[y][x] = colors.black
		end
	end
	---@type number[][]
	canvas.data = data

	return canvas
end

function basic.own(canvas)
	canvas.render = template.render
	canvas.resize = template.resize
	canvas.setPixel = template.setPixel
	canvas.owner = "basic"
end

basic.getBlit = getBlit

return basic
end
package.preload["obsi2.graphics.orliParser"] = function()
---@diagnostic disable: deprecated
local orli = {}
local max, floor, ceil, log = math.max, math.floor, math.ceil, math.log
local brs, band = bit32.rshift, bit32.band
local sunpack = string.unpack
---@param data string
---@param index integer
local function getByte(data, index)
	return sunpack(">B", data, index)
end

---@param data string
---@param index integer
local function getShort(data, index)
	return sunpack(">H", data, index)
end

---@param data string
---@param index integer
local function getChar(data, index)
	return data:sub(index, index)
end

---@param byte integer
---@param lengthMask integer
---@return integer
local function getColorLength(byte, lengthMask)
	return band(byte, lengthMask)
end

---@param byte integer
---@param colorBit integer
---@return integer
local function getColor(byte, colorBit)
	return brs(byte, 8-colorBit)
end

---@param str string
---@return obsi.Image?, string?
function orli.parse(str)
	if str:sub(1, 5) ~= "\153ORLI" then
		return nil, "Data is not the supported ORLI format"
	end
	local width, height = getShort(str, 6), getShort(str, 8)
	local colorCount = getByte(str, 10)
	local cols = {}
	local colorBit = max(ceil(log(colorCount, 2)), 1)
	local lengthMask = 2^(8-colorBit) - 1
	local index = 11+colorCount
	for i = 11, 11+colorCount-1 do
		cols[#cols+1] = getChar(str, i)
	end

	local image = {}
	local data = {}
	image.data = data
	image.width = width
	image.height = height
	for y = 1, height do
		data[y] = {}
		for x = 1, width do
			data[y][x] = colors.red -- In case when Orli is corrupted, we can quickly figure it out by having this as a default color.
		end
	end

	local j = 1
	for i = index, #str do
		local d = getByte(str, i)
		local l = getColorLength(d, lengthMask)
		local c = getColor(d, colorBit)
		local col = cols[c+1]
		for j1 = j, j + l-1 do
			local x = (j1-1)%width+1
			local y = floor((j1-1)/width)+1
			if not data[y] then
				error(("INCORRECT HEIGHT, FILE IS CORRUPTED (y: %i, h: %i)"):format(y, height), 4)
			end
			data[y][x] = tonumber(col, 16) and 2^tonumber(col, 16) or -1
		end
		j = j + l
		if j > width*height then
			-- yeah... either we got some data left over, or we don't have enough data.
			-- do I error here?
			break
		end
	end

	return image
end

return orli
end
package.preload["obsi2.graphics.pixelbox"] = function()
local pixelbox = {}

-- Created by dev9551 (https://github.com/9551-Dev)
-- Edited by Sima to easily integrate with Obsi Game Engine and use with Lua Language Server (LLS)

local box_object = {}

local t_cat  = table.concat

local sampling_lookup = {
	{2,3,4,5,6},
	{4,1,6,3,5},
	{1,4,5,2,6},
	{2,6,3,5,1},
	{3,6,1,4,2},
	{4,5,2,3,1}
}

local texel_character_lookup  = {}
local texel_foreground_lookup = {}
local texel_background_lookup = {}
local to_blit = {}

local function calculate_texel(v1,v2,v3,v4,v5,v6)
	local texel_data = {v1,v2,v3,v4,v5,v6}

	local state_lookup = {}
	for i = 1, 6 do
		local subpixel_state = texel_data[i]
		local current_count = state_lookup[subpixel_state]

		state_lookup[subpixel_state] = current_count and current_count + 1 or 1
	end

	local sortable_states = {}
	for k,v in pairs(state_lookup) do
		-- sortable_states[#sortable_states+1] = {
		-- 	value = k,
		-- 	count = v
		-- }
		sortable_states[#sortable_states+1] = {k, v}
	end

	table.sort(sortable_states,function(a,b)
		return a[2] > b[2]
	end)

	local texel_stream = {}
	for i=1,6 do
		local subpixel_state = texel_data[i]

		if subpixel_state == sortable_states[1][1] then
			texel_stream[i] = 1
		elseif subpixel_state == sortable_states[2][1] then
			texel_stream[i] = 0
		else
			local sample_points = sampling_lookup[i]
			for sample_index = 1, 5 do
				local sample_subpixel_index = sample_points[sample_index]
				local sample_state = texel_data[sample_subpixel_index]

				local common_state_1 = sample_state == sortable_states[1][1]
				local common_state_2 = sample_state == sortable_states[2][1]

				if common_state_1 or common_state_2 then
					texel_stream[i] = common_state_1 and 1 or 0
					break
				end
			end
		end
	end

	local char_num = 128
	local stream_6 = texel_stream[6]
	if texel_stream[1] ~= stream_6 then char_num = char_num + 1  end
	if texel_stream[2] ~= stream_6 then char_num = char_num + 2  end
	if texel_stream[3] ~= stream_6 then char_num = char_num + 4  end
	if texel_stream[4] ~= stream_6 then char_num = char_num + 8  end
	if texel_stream[5] ~= stream_6 then char_num = char_num + 16 end

	local state_1,state_2
	if #sortable_states > 1 then
		state_1 = sortable_states[  stream_6+1][1]
		state_2 = sortable_states[2-stream_6  ][1]
	else
		state_1 = sortable_states[1][1]
		state_2 = sortable_states[1][1]
	end

	return char_num,state_1,state_2
end

local real_entries = 0
local function generate_lookups()
	for i = 0, 15 do
		to_blit[2^i] = ("%x"):format(i)
	end
	local floor = math.floor
	local char = string.char
	for encoded_pattern=0,6^6 do
		local subtexel_1 = floor(encoded_pattern/1) % 6
		local subtexel_2 = floor(encoded_pattern/6) % 6
		local subtexel_3 = floor(encoded_pattern/36) % 6
		local subtexel_4 = floor(encoded_pattern/216) % 6
		local subtexel_5 = floor(encoded_pattern/1296) % 6
		local subtexel_6 = floor(encoded_pattern/7776) % 6

		local pattern_lookup = {}
		pattern_lookup[subtexel_6] = 5
		pattern_lookup[subtexel_5] = 4
		pattern_lookup[subtexel_4] = 3
		pattern_lookup[subtexel_3] = 2
		pattern_lookup[subtexel_2] = 1
		pattern_lookup[subtexel_1] = 0

		local pattern_identifier = pattern_lookup[subtexel_2] + pattern_lookup[subtexel_3] * 3 + pattern_lookup[subtexel_4] * 4 + pattern_lookup[subtexel_5] * 20 + pattern_lookup[subtexel_6] * 100

		if not texel_character_lookup[pattern_identifier] then
			real_entries = real_entries + 1
			local character,sub_state_1,sub_state_2 = calculate_texel(
				subtexel_1,subtexel_2,
				subtexel_3,subtexel_4,
				subtexel_5,subtexel_6
			)

			local color_1_location = pattern_lookup[sub_state_1] + 1
			local color_2_location = pattern_lookup[sub_state_2] + 1

			texel_foreground_lookup[pattern_identifier] = color_1_location
			texel_background_lookup[pattern_identifier] = color_2_location

			texel_character_lookup[pattern_identifier] = char(character)
		end
	end
end

---@param box table
---@param color ccTweaked.colors.color
---@param keep_existing? boolean
function pixelbox.restore(box, color, keep_existing)
	if not keep_existing then
		local new_canvas = {}

		for y = 1, box.height do
			if not new_canvas[y] then new_canvas[y] = {} end
			for x = 1, box.width do
				new_canvas[y][x] = color
			end
		end

		box.data = new_canvas
	else
		local canvas = box.data

		for y = 1, box.height do
			if not canvas[y] then canvas[y] = {} end
			for x = 1, box.width do
				if not canvas[y][x] then
					canvas[y][x] = color
				end
			end
		end
		if #box.data > box.height then
			for _ = 1, #box.data - box.height do
				table.remove(box.data)
			end
		end
	end
end

local color_lookup  = {}
local texel_body = {0,0,0,0,0,0}

function box_object:render()
	local t = self.term
	local blit_line,set_cursor = t.blit, t.setCursorPos
	local canv = self.data
	local char_line, fg_line, bg_line = {}, {}, {}
	local width = self.width

	local sy = 0
	for y = 1, self.height, 3 do
		sy = sy + 1
		local layer_1 = canv[y]
		local layer_2 = canv[y+1]
		local layer_3 = canv[y+2]

		local n = 0
		for x = 1, width-1, 2 do
			local xp1 = x+1
			local b1, b2, b3, b4, b5, b6 = layer_1[x], layer_1[xp1], layer_2[x], layer_2[xp1], layer_3[x], layer_3[xp1]

			local char, fg, bg = " ", 1, b1

			local single_color = b2 == b1 and b3 == b1 and b4 == b1 and b5 == b1 and b6 == b1

			if not single_color then
				color_lookup[b6] = 5
				color_lookup[b5] = 4
				color_lookup[b4] = 3
				color_lookup[b3] = 2
				color_lookup[b2] = 1
				color_lookup[b1] = 0

				local pattern_identifier = color_lookup[b2] + color_lookup[b3] * 3 + color_lookup[b4] * 4 + color_lookup[b5] * 20 + color_lookup[b6] * 100

				local fg_location = texel_foreground_lookup[pattern_identifier]
				local bg_location = texel_background_lookup[pattern_identifier]

				texel_body[1] = b1
				texel_body[2] = b2
				texel_body[3] = b3
				texel_body[4] = b4
				texel_body[5] = b5
				texel_body[6] = b6

				fg = texel_body[fg_location]
				bg = texel_body[bg_location]

				char = texel_character_lookup[pattern_identifier]
			end

			n = n + 1
			char_line[n] = char
			fg_line[n] = to_blit[fg]
			bg_line[n] = to_blit[bg]
		end

		set_cursor(1, sy)
		blit_line(t_cat(char_line), t_cat(fg_line), t_cat(bg_line))
	end
end

---@param color ccTweaked.colors.color
function box_object:clear(color)
	pixelbox.restore(self,color)
end

---@param x integer
---@param y integer
---@param color ccTweaked.colors.color
function box_object:setPixel(x,y,color)
	self.data[y][x] = color
end

---@param w integer
---@param h integer
---@param color ccTweaked.colors.color
function box_object:resize(w, h, color)
	self.width = w*2
	self.height = h*3
	pixelbox.restore(self, color or self.background or colors.black, true)
end

---@param terminal ccTweaked.term.Redirect
---@param bg? ccTweaked.colors.color
---@return pixelbox.box
function pixelbox.newCanvas(terminal, bg)
	---@class pixelbox.box
	local box = {}
	box.background = bg or terminal.getBackgroundColor() or colors.black
	box.term = terminal

	local w,h = terminal.getSize()
	box.width = w*2
	box.height = h*3
	box.owner = "pixelbox"
	box.clear = box_object.clear
	box.render = box_object.render
	box.resize = box_object.resize
	box.setPixel = box_object.setPixel

	pixelbox.restore(box, box.background)
	return box
end

---@param canvas basic.Canvas|neat.Canvas|pixelbox.box
function pixelbox.own(canvas)
	canvas.clear = box_object.clear
	canvas.render = box_object.render
	canvas.resize = box_object.resize
	canvas.setPixel = box_object.setPixel
	canvas.owner = "pixelbox"
end

generate_lookups()
return pixelbox
end
package.preload["obsi2.graphics.neat"] = function()
local neat = {}
local floor = math.floor
local ceil = math.ceil
local concat = table.concat

---@type table<integer, string>
local toBlit = {}
for i = 0, 15 do
	toBlit[2^i] = ("%x"):format(i)
end

local function getBlit(color)
	return toBlit[color]
end

local function goodHeight(height)
	return ceil((height+2) / 2) * 3
end

local template = {}
---@param x integer
---@param y integer
---@param color ccTweaked.colors.color
function template:setPixel(x, y, color)
	self.data[y][x] = color
end

function template:render()
	local canvasdata = self.data
	local blit = self.term.blit
	local setCursorPos = self.term.setCursorPos
	local _, termHeight = self.term.getSize()
	termHeight = floor((termHeight+1)/2)*2
	local subposup = true
	local y = 1
	local fgcoltab = {}
	local bgcoltab = {}
	for by = 1, termHeight do
		local txtstr = ""
		if subposup then
			txtstr = ("\143"):rep(self.width)
			for x = 1, self.width do
				fgcoltab[x] = getBlit(canvasdata[y][x])
				bgcoltab[x] = getBlit(canvasdata[y+1][x])
			end
		else
			txtstr = ("\131"):rep(self.width)
			for x = 1, self.width do
				fgcoltab[x] = getBlit(canvasdata[y-1][x])
				bgcoltab[x] = getBlit(canvasdata[y][x])
			end
		end
		setCursorPos(1, by)
		blit(txtstr, concat(fgcoltab), concat(bgcoltab))
		subposup = not subposup
		y = y + (subposup and 1 or 2)
	end
end

function template:resize(w, h)
	h = goodHeight(h)
	if self.height > h then
		for y = 1, self.height-h do
			table.remove(self.data)
		end
	elseif self.height < h then
		for y = self.height+1, h do
			self.data[y] = {}
			for x = 1, w do
				self.data[y][x] = colors.black
			end
		end
	end
	if self.width > w then
		for y = 1, h do
			for x = 1, self.width-w-1 do
				table.remove(self.data[y])
			end
		end
	elseif self.width < w then
		for y = 1, h do
			for x = self.width+1, w do
				self.data[y][x] = colors.black
			end
		end
	end
	self.width = w
	self.height = h
end

---@param terminal ccTweaked.term.Redirect??
---@param width integer?
---@param height integer?
function neat.newCanvas(terminal, width, height)
	---@class neat.Canvas
	local canvas = {}
	if (not width or not height) then
		if terminal then
			width, height = terminal.getSize()
		else
			width, height = term.getSize()
		end
	end
	-- God bless your soul if your terminal is 1 character in height, lol.
	height = goodHeight(height)

	canvas.width = width
	canvas.height = height
	canvas.term = terminal or term
	canvas.setPixel = template.setPixel
	canvas.resize = template.resize
	canvas.render = template.render
	canvas.owner = "neat"
	local data = {}
	for y = 1, height do
		data[y] = {}
		for x = 1, width do
			data[y][x] = colors.black
		end
	end
	---@type number[][]
	canvas.data = data

	return canvas
end

function neat.own(canvas)
	canvas.render = template.render
	canvas.resize = template.resize
	canvas.setPixel = template.setPixel
	canvas.owner = "neat"
end

return neat
end
package.preload["obsi2.graphics.nfpParser"] = function()
local nfp = {}

---Takes inconsistent 2D array as an argument and returns a consistent one instead.
---@param data integer[][]
---@param width integer
---@param height integer
---@return integer[][]
function nfp.consise(data, width, height)
	for y = 1, height do
		data[y] = data[y] or {}
		for x = 1, width do
			data[y][x] = data[y][x] or -1
		end
	end
	return data
end

---@param text string
---@return obsi.Image?, string?
function nfp.parse(text)
	local x, y = 1, 1
	local width = 0
	local img = {}
	local data = {}
	img.data = data
	for i = 1, #text do
		local char = text:sub(i, i)
		if not tonumber(char, 16) and char ~= "\n" and char ~= " " then
			return nil, ("Unknown character (%s) at %s\nMake sure your image is valid .nfp"):format(char, i)
		end
		if char == "\n" then
			y = y + 1
			x = 1
		else
			if not data[y] then
				data[y] = {}
			end
			data[y][x] = (char == " ") and -1 or 2^tonumber(char, 16)
			width = math.max(width, x)
			x = x + 1
		end
	end
	img.width = width
	img.height = y
	nfp.consise(data, width, y)
	return img
end

return nfp
end
package.preload["obsi2.system"] = function()
---@class obsi.system
local system = {}
local isAdvanced
local isEmulated
local host = _HOST:match("%(.-%)"):sub(2, -2)
local ver = _HOST:sub(15, 21)

if _HOST:lower():match("minecraft") then
	isEmulated = false
else
	isEmulated = true
end

do
	local programs = shell.programs()
	for i = 1, #programs do
		if programs[i] == "multishell" then
			isAdvanced = true
		end
	end
end

function system.isAdvanced()
	return isAdvanced
end

function system.isEmulated()
	return isEmulated
end

function system.getHost()
	return host
end

function system.getVersion()
	return ver
end

function system.getClockSpeed()
	if config then
		return config.get("clockSpeed")
	end
	return 20
end

return system
end
package.preload["obsi2.audio"] = function()
local fs
local onb = require("obsi2.audio.onbParser")
local nbs = require("obsi2.audio.nbsParser")
local t = os.clock()
---@class obsi.audio
local audio = {}

---@type ccTweaked.peripheral.Speaker[]
local channels = {}
local fakeSpeaker = false

---@class note
---@field speaker integer
---@field pitch number
---@field volume number
---@field instrument ccTweaked.peripheral.instrument?
---@field sound string?
---@field latency number?
---@field timing number?

---@class obsi.Audio
---@field name string
---@field description string
---@field bpm number
---@field duration number measured in seconds
---@field notes note[]

---@class obsi.PlayingAudio
---@field audio obsi.Audio
---@field startTime number
---@field holdTime number
---@field lastNote integer
---@field volume number
---@field loop boolean
---@field playing boolean

local audiobuffer = {}
---@type obsi.PlayingAudio[]
audiobuffer.sounds = {}
audiobuffer.max = 0

---@type note[]
local notebuffer = {}

-- Plays a single note. If you are not sure what channel to use, just use 1.
---@param channel integer
---@param instrument ccTweaked.peripheral.instrument
---@param pitch number  from 0 to 24
---@param volume number? from 0 to 3
---@param latency number? in seconds
function audio.playNote(channel, instrument, pitch, volume, latency)
	volume = math.max(math.min(volume or 1, 3), 0)
	pitch = math.max(math.min(pitch, 24), 0)
	latency = latency or 0
	notebuffer[#notebuffer+1] = {pitch = pitch, speaker = channel, instrument = instrument, volume = volume, latency = latency}
	table.sort(notebuffer, function (n1, n2)
		return n1.latency < n2.latency
	end)
end

-- Plays a single note. If you are not sure what channel to use, just use 1.
---@param channel integer
---@param sound string
---@param pitch number  from 0 to 24
---@param volume number? from 0 to 3
---@param latency number? in seconds
function audio.playSound(channel, sound, pitch, volume, latency)
	volume = math.max(math.min(volume or 1, 3), 0)
	pitch = math.max(math.min(pitch, 24), 0)
	latency = latency or 0
	notebuffer[#notebuffer+1] = {pitch = pitch, speaker = channel, sound = sound, volume = volume, latency = latency}
	table.sort(notebuffer, function (n1, n2)
		return n1.latency < n2.latency
	end)
end

function audio.isAvailable()
	return not fakeSpeaker
end

-- Refreshes the list of speakers (channels).
--
-- By default it should be called internally, but you can use it in your code if you want.
function audio.refreshChannels()
	local chans = {peripheral.find("speaker")}
	if #chans ~= 0 then
		channels = chans
		fakeSpeaker = false
	else
		if periphemu then
			periphemu.create("ObsiSpeaker", "speaker")
			channels[1] = peripheral.wrap("ObsiSpeaker") --[[@as ccTweaked.peripheral.Speaker]]
			fakeSpeaker = false
		else
			channels[1] = {
				playAudio = function() end,
				playNote = function() end,
				playSound = function() end,
				stop = function() end,
			}
			fakeSpeaker = true
		end
	end
end

function audio.getChannelCount()
	return #channels
end

function audio.isPlaying()
	return #notebuffer > 0 or #audiobuffer > 0
end

function audio.notesPlaying()
	return #notebuffer
end

---@param soundPath ccTweaked.fs.path
---@return obsi.Audio
function audio.newSound(soundPath)
	local contents, e = fs.read(soundPath)
	if not contents then
		error(e)
	end
	local mus, e1 = onb.parseONB(contents)
	if mus then
		return mus
	end
	local mus, e2 = nbs.parseNBS(contents)
	if mus then
		return mus
	end
	if soundPath:sub(-4):lower() == ".onb" then
		error(e1)
	elseif soundPath:sub(-4):lower() == ".nbs" then
		error(e2)
	else
		error(("Extension of the audio is not supported: %s"):format(soundPath), 2)
	end
end

---@param source obsi.Audio
---@param loop? boolean
---@return integer
function audio.play(source, loop)
	---@type obsi.PlayingAudio
	local paudio = {
		audio = source,
		startTime = os.clock(),
		holdTime = os.clock(),
		lastNote = 1,
		loop = loop or false,
		playing = true,
		volume = 1
	}
	for i = 1, audiobuffer.max+1 do
		if not audiobuffer.sounds[i] then
			audiobuffer.sounds[i] = paudio
			if i > audiobuffer.max then
				audiobuffer.max = i
			end
			return i
		end
	end
	return -1
end

---@param source obsi.Audio|integer
function audio.stop(source)
	if type(source) == "number" then
		audiobuffer.sounds[source] = nil
		return
	end
	for i = 1, audiobuffer.max do
		local s = audiobuffer.sounds[i]
		if s then
			if s.audio == source then
				audiobuffer.sounds[i] = nil
			end
		end
	end
end

---@param source obsi.Audio
---@param id integer
---@return boolean
function audio.isID(source, id)
	if audiobuffer.sounds[id] then
		return audiobuffer.sounds[id].audio == source
	end
	return false
end

---@param source obsi.PlayingAudio
local function pauseAudio(source)
	if source.playing then
		source.holdTime = os.clock()
		source.playing = false
	end
end

---@param source obsi.Audio|integer
function audio.pause(source)
	if type(source) == "number" then
		local s = audiobuffer.sounds[source]
		if s then
			pauseAudio(s)
		end
		return
	end
	for i = 1, audiobuffer.max do
		local s = audiobuffer.sounds[i]
		if s then
			if s.audio == source then
				pauseAudio(s)
			end
		end
	end
end

---@param source obsi.PlayingAudio
local function unpauseAudio(source)
	if not source.playing then
		source.startTime = os.clock()+source.startTime-source.holdTime
		source.playing = true
		local note = source.audio.notes[source.lastNote]
		while note and note.timing+source.startTime < t do
			source.lastNote = source.lastNote + 1
			note = source.audio.notes[source.lastNote]
		end
		if source.lastNote > #source.audio.notes then
			source.lastNote = 1
			source.startTime = os.clock()
		end
	end
end

---@param source obsi.Audio|integer
function audio.unpause(source)
	if type(source) == "number" then
		local s = audiobuffer.sounds[source]
		if s then
			unpauseAudio(s)
		end
		return
	end
	for i = 1, audiobuffer.max do
		local s = audiobuffer.sounds[i]
		if s and s.audio == source then
			unpauseAudio(s)
		end
	end
end

---@param source obsi.PlayingAudio
---@param volume number
local function setVolumeAudio(source, volume)
	source.volume = volume
end

---@param source obsi.Audio|integer
---@param volume number
function audio.setVolume(source, volume)
	if type(source) == "number" then
		local s = audiobuffer.sounds[source]
		if s then
			setVolumeAudio(s, volume)
		end
		return
	end
	for i = 1, audiobuffer.max do
		local s = audiobuffer.sounds[i]
		if s and s.audio == source then
			setVolumeAudio(s, volume)
		end
	end
end

---@param id integer
function audio.getVolume(id)
	return audiobuffer.sounds[id] and audiobuffer.sounds[id].volume or 0
end

---@param id integer
---@return boolean
function audio.isPaused(id)
	return audiobuffer.sounds[id] and audiobuffer.sounds[id].playing or false
end

---@param dt number
local function soundLoop(dt)
	if dt == 0 then
		dt = 0.025 -- Should, but most of the time doesn't fix crashing on non-Java platforms.
	end
	t = t + dt
	for i, note in ipairs(notebuffer) do
		note.latency = note.latency - dt
		if note.latency <= 0 then
			local speaker = channels[((note.speaker-1) % #channels)+1]
			if note.sound then
				speaker.playSound(note.sound, note.volume, note.pitch)
			else
				speaker.playNote(note.instrument, note.volume, note.pitch)
			end
			table.remove(notebuffer, i)
		end
	end
	for i = 1, audiobuffer.max do
		local s = audiobuffer.sounds[i]
		if s and s.playing then
			local nextCanPlay = true
			local r = 0
			while nextCanPlay do
				r = r + 1
				if r > 1000 then
					-- Yes, this is my fix for crashing in Minecraft.
					break
				end
				nextCanPlay = false
				local note = s.audio.notes[s.lastNote]
				if s.startTime+note.timing < t then
					local speaker = channels[(note.speaker-1)%#channels+1]
					speaker.playNote(note.instrument, math.min(note.volume*s.volume, 3), note.pitch)
					s.lastNote = s.lastNote + 1
				end
				if s.lastNote > #s.audio.notes then
					if s.loop then
					   s.lastNote = 1
					   s.startTime = t
					else
						audiobuffer.sounds[i] = nil
					end
				elseif s.audio.notes[s.lastNote].timing < t-s.startTime then
					nextCanPlay = true
				end
			end
		end
	end
end

local function init(obsifs)
	fs = obsifs
	audio.refreshChannels()
	return audio, soundLoop
end

return init
end
package.preload["obsi2.audio.nbsParser"] = function()
local nbs = {}

-- The parsing function for .nbs was made by Xella. Huge thanks to them for making it.
-- This thing is just a bit modified to work with the Obsi Game Engine.
-- The original repo can be found here: https://github.com/Xella37/NBS-Tunes-CC

function nbs.parseNBS(data)
	local nbsRaw = string.gsub(data, "\r\n", "\n")
	local seekPos = 1

	local byte = string.byte
	local lshift = bit.blshift --[[@as function]]

	local function readInteger()
		local buffer = nbsRaw:sub(seekPos, seekPos+3)
		seekPos = seekPos + 4

		if #buffer < 4 then return end

		local byte1 = byte(buffer, 1)
		local byte2 = byte(buffer, 2)
		local byte3 = byte(buffer, 3)
		local byte4 = byte(buffer, 4)

		return byte1 + lshift(byte2, 8) + lshift(byte3, 16) + lshift(byte4, 24)
	end

	local function readShort()
		local buffer = nbsRaw:sub(seekPos, seekPos+1)
		seekPos = seekPos + 2

		if #buffer < 2 then return end

		local byte1 = byte(buffer, 1)
		local byte2 = byte(buffer, 2)

		return byte1 + lshift(byte2, 8)
	end

	local function readByte()
		local buffer = nbsRaw:sub(seekPos, seekPos)
		seekPos = seekPos + 1

		return byte(buffer, 1)
	end

	local function readString()
		local length = readInteger()
		if length then
			local txt = nbsRaw:sub(seekPos, seekPos + length - 1)
			seekPos = seekPos + length
			return txt
		end
	end

	-- Metadata
	local song = {}
	song.zeros = readShort() -- new in version 1
	local legacy = song.zeros ~= 0
	local version = 0

	if legacy then
		song.length = song.zeros -- zeros don't exist in v0, so use those bytes for length
		song.zeros = nil
	else
		version = readByte()
		song.nbs_version = version
		song.vanilla_instrument_count = readByte()

		if version >= 3 then -- zeros replaced song length, but was added back in in v3
			song.length = readShort()
		end
	end
	song.layer_count = readShort() --- called height in legacy
	song.name = readString()
	song.author = readString()
	song.ogauthor = readString()
	song.desc = readString()
	song.tempo = readShort() or 1000
	seekPos = seekPos + 23 -- Sima: gotta skip some stuff
	readString()
	if version >= 4 then
		song.loop = readByte()
		song.max_loops = readByte()
		song.loop_start_tick = readShort()
	end

	-- song.tempo is 100 * the t/s, we compute the delay (or seconds per tick) to use when playing the audio
	local ticksPerSecond = song.tempo / 100
	local delay = 1 / ticksPerSecond

	local ticks = {}
	local currenttick = -1

	while true do
		-- We skip by step layers ahead
		local step = readShort()

		-- A zero step means we go to the next part (which we don't need so we just ignore that)
		if step == 0 then
			break
		end

		currenttick = currenttick + step

		-- lpos is the current layer (in the internal structure, we ignore NBS's editor layers for convenience)
		local lpos = 1
		ticks[currenttick] = {}

		local currentLayer = -1
		while true do
			-- Check how big the jump from this note to the next one is
			local jump = readShort()
			currentLayer = currentLayer + jump

			-- If its zero, we should go to the next tick
			if jump == 0 then
				break
			end

			-- But if its not, we read the instrument and note number
			local inst = readByte() + 1 -- +1 so it starts at 1
			local note = readByte()
			local velocity, panning, note_block_pitch
			if not legacy then
				if version >= 4 then -- note panning, velocity and note block fine pitch added in v4
					velocity = readByte() / 100
					panning = readByte() - 100
					note_block_pitch = readShort()
				end
			end

			-- And add them to the internal structure
			ticks[currenttick][lpos] = {
				inst = inst,
				note = note,
				velocity = velocity or 1,
				panning = panning or 0,
				fine_pitch = note_block_pitch,
				layer = currentLayer+1,
			}
			lpos = lpos + 1
		end
	end

	-- we now parse the headers
	local layers = {}
	for i = 1, song.layer_count do
		local name = readString()
		local velocity
		if version > 0 then
			readByte() -- Sima: `locked` is not useful for playing.
			velocity = readByte() / 100
			readByte() -- Sima: `panning` is also not very useful since we are planning for manual stuff.
		end

		local layer = {
			name = name,
			velocity = velocity or 1,
		}
		layers[i] = layer
	end

	for i = 0, currenttick do
		local tick = ticks[i]
		if tick then
			for j = 1, #tick do
				local sound = tick[j]
				local layerNr = sound.layer
				local layer = layers[layerNr]
				sound.velocity_layer = layer.velocity
			end
		end
	end

	-- parse custom instruments
	local customInstrumentCount = readByte() -- in one of the test turned out to be nil??
	if customInstrumentCount and customInstrumentCount ~= 0 then
		error(("Sorry, no custom instruments! Count: %s"):format(customInstrumentCount), 3)
	end

	-- now, let's convert this to Obsi readable stuff!
	---@type obsi.Audio
	local s = {
		name = song.name,
		description = song.desc,
		bpm = song.tempo*60,
		duration = -1,
		notes = {},
	}

	local currentTick = 0
	local time = 0
	local notes = {}

	local instruments = {
		"harp", --0 = Piano (Air)
		"bass", --1 = Double Bass (Wood)
		"basedrum", --2 = Bass Drum (Stone)
		"snare", --3 = Snare Drum (Sand)
		"hat", --4 = Click (Glass)
		"guitar", --5 = Guitar (Wool)
		"flute", --6 = Flute (Clay)
		"bell", --7 = Bell (Block of Gold)
		"chime", --8 = Chime (Packed Ice)
		"xylophone", --9 = Xylophone (Bone Block)
		"iron_xylophone", --10 = Iron Xylophone (Iron Block)
		"cow_bell", --11 = Cow Bell (Soul Sand)
		"didgeridoo", --12 = Didgeridoo (Pumpkin)
		"bit", --13 = Bit (Block of Emerald)
		"banjo", --14 = Banjo (Hay)
		"pling", --15 = Pling (Glowstone)
	}
	while true do
		local tick = ticks[currentTick]
		if tick then
			for j = 1, #tick do
				local sound = tick[j]
				local inst = sound.inst
				local noteVolume = sound.velocity * sound.velocity_layer

				-- I don't need octave offset, sory Xella :3
				-- This is how the thing is defined in the NBS specification anyway.
				local pitch = sound.note - 33
				if pitch > 24 then
					pitch = pitch % 12 + 12
				elseif pitch < 0 then
					pitch = pitch % 12
				end

				if inst <= 16 then
					local instrument = instruments[inst]
					notes[#notes+1] = {instrument = instrument, volume = noteVolume, pitch = pitch, speaker = 1, timing = time} ---@type note
				end
			end
		end

		local found = false
		local waitTicks = 0
		for j = currentTick+1, song.length do
			if ticks[j] then
				found = true
				waitTicks = j - currentTick
				currentTick = j
				break
			end
		end
		if not found then
			break -- stop playing
		end
		time = time + delay * waitTicks
	end
	s.duration = time
	table.sort(notes, function (note1, note2)
		return note1.timing < note2.timing
	end)
	s.notes = notes
	return s
end

return nbs
end
package.preload["obsi2.audio.onbParser"] = function()
local onb = {}

---@param data string
---@return obsi.Audio?, string?
function onb.parseONB(data)
	if data:sub(-1) ~= "\n" then
		data = data.."\n"
	end
	---@type string[]
	local lines = {}
	for s in data:gmatch("(.-)\n") do
		lines[#lines+1] = s
	end
	-- first we check if the first one has ONB signature
	if lines[1] ~= "ONB,Obsi NoteBlock" then
		return nil, "File doesn't have ONB signature"
	end
	-- now let's carefully parse each line
	-- first some metadata
	local name = lines[2]
	local description = lines[3]
	local bpm = tonumber(lines[4]) or 60
	local duration = 0
	-- preparing to parse some stuff
	local columnNames = {}
	for s in (lines[5]..","):gmatch("(.-),") do
		columnNames[#columnNames+1] = s
	end
	local notes = {}
	for l = 6, #lines do
		local str = lines[l]..","
		if str:sub(1, 1) ~= "#" and str:find("%w") then
			local note = {}
			local charstart = 1
			local charend
			for i = 1, #columnNames do
				charend = str:find(",", charstart)
				if not charend then
					if columnNames[i] == "volume" then
						note[columnNames[i]] = 1
					end
				else
					note[columnNames[i]] = str:sub(charstart, charend-1)
					charstart = charend+1
				end
			end
			local notPresent = {}
			if not note.timing then
				notPresent[#notPresent+1] = "timing"
			end
			if not note.pitch then
				notPresent[#notPresent+1] = "pitch"
			end
			if not note.instrument then
				notPresent[#notPresent+1] = "instrument"
			end
			if #notPresent > 0 then
				local nP = ""
				for i, s in ipairs(notPresent) do
					nP = nP..s
					if i ~= #notPresent then
						nP = nP..", "
					end
				end
				return nil, ("Fields like: {%s} are not present!"):format(nP)
			end
			note.pitch = tonumber(note.pitch)
			note.timing = tonumber(note.timing)*(60/bpm)
			duration = math.max(duration, note.timing+(60/bpm))
			note.speaker = tonumber(note.speaker) or 1
			note.volume = tonumber(note.volume) or 1
			notes[#notes+1] = note
		end
	end
	table.sort(notes, function (note1, note2)
		return note1.timing < note2.timing
	end)
	return {
		name = name,
		description = description,
		bpm = bpm,
		notes = notes,
		duration = duration
	}
end

return onb
end
package.preload["obsi2.keyboard"] = function()
---@class obsi.keyboard
local keyboard = {}
keyboard.keys = {}
keyboard.scancodes = {}

---@param key string
---@return boolean
function keyboard.isDown(key)
	return keyboard.keys[key] or false
end

---@param scancode integer
---@return boolean
function keyboard.isScancodeDown(scancode)
	return keyboard.scancodes[scancode] or false
end

return keyboard
end
return package.preload["obsi2"]()

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
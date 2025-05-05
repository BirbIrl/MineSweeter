---@diagnostic disable: redefined-local

local serpent = require("library.modules.serpent")
local bath = require("library.modules.bath")
local vector = require("library.modules.vector")
local tween = require("library.modules.tween")
local Tile = require("tileLogic")
local sounds = require("sounds")
local globals = require("globals")
local buttons = require "buttons" -- woe lua syntax be upon ye
local tileFont = love.graphics.newFont("data/fonts/monocraft-birb-fix.ttf", 100)
love.graphics.setDefaultFilter("nearest")

config = { --- @diagnostic disable-line: lowercase-global
	zoom = 2,
	pan = vector.new(0, 0),
	pause = false,
	enableRendering = true,
	fieldsize = vector.new(1, 1),
	mobile = false,
	showFlagButton = false,
	flagMode = false,
	chillMode = false,
	panSpeed = 500,
	dragging = true,
}

local gridTemplate = {
	new = function(fieldsize)
		local grid = {}
		grid.gamestate = {
			forceClick = true,
			freebies = love.math.random(9, 9),
			finished = false,
			decayRate = globals.defaultDecayRate
		}
		grid.gamestate.score = {
			tiles = 0
		}
		grid.tiles = {}
		grid.unloadedTiles = {}
		function grid:addTile(tile, pos)
			self.tiles = self.tiles or {}
			self.tiles[pos.x] = self.tiles[pos.x] or {}
			self.tiles[pos.x][pos.y] = tile
		end

		function grid:generateStarterField(fieldsize)
			for x = -math.floor(fieldsize.x / 2), fieldsize.x / 2, 1 do
				for y = -math.floor(fieldsize.y / 2), fieldsize.y / 2, 1 do
					local pos = vector.new(x, y)
					self:addTile(Tile:new(grid, pos), pos)
				end
			end
			config.pan.x = love.graphics.getWidth() / 2
			config.pan.y = love.graphics.getHeight() / 2
		end

		function grid:lambdaOnAllTiles(fun, tileGrid)
			tileGrid = tileGrid or self.tiles
			local hits = 0
			for _, column in pairs(tileGrid) do
				for _, tile in pairs(column) do
					if fun(tile) then
						hits = hits + 1
					end
				end
			end
			return hits
		end

		function grid:tick()
			local modifier = self.gamestate.score.tiles - 20
			if modifier < 0 then
				modifier = 1
			end
			self.gamestate.decayRate = globals.defaultDecayRate * math.pow(modifier, 0.5)
		end

		if fieldsize then
			grid:generateStarterField(fieldsize)
		end

		return grid
	end

}



local grid

function love.keypressed(key)
	if key == "r" then
		grid = gridTemplate.new(config.fieldsize)
	elseif key == "p" then
		config.pause = not config.pause
	elseif key == "=" then
		love.audio.setVolume(love.audio.getVolume() + 0.1)
	elseif key == "-" then
		if love.audio.getVolume() < 0.1 then
			love.audio.setVolume(0)
		else
			love.audio.setVolume(love.audio.getVolume() - 0.1)
		end
	elseif key == "]" then
		config.panSpeed = config.panSpeed * 1.25
	elseif key == "[" then
		config.panSpeed = config.panSpeed / 1.25
	elseif key == "c" then
		config.chillMode = not config.chillMode
	elseif key == "m" then
		config.dragging = not config.dragging
	elseif key == "space" then
		config.showFlagButton = true
		config.flagMode = not config.flagMode
	elseif key == "f1" then
		config.enableRendering = not config.enableRendering
	elseif key == "f11" then
		love.window.setFullscreen(not love.window.getFullscreen())
	end
end

function love.load()
	grid = gridTemplate.new(config.fieldsize)
end

local input = {
	m1 = {
		lastMousePos = nil,
		startingMousePos = nil
	},
	m2 = {
		lastMousePos = nil,
		startingMousePos = nil
	},
	t1 = {
		lastTouchPos = nil,
		startingTouchPos = nil,
		touchId = nil
	},
	t2 = {
		lastTouchPos = nil,
		startingTouchPos = nil,
		touchId = nil
	},
}
local function triggerTile(grid, mousePos, mouseButton)
	local size = globals.tilesize * config.zoom
	if not grid.gamestate.finished then
		local x = math.floor(
			(mousePos.x - config.pan.x) / (size * globals.tileGap)
		)
		local y = math.floor(
			(mousePos.y - config.pan.y) / (size * globals.tileGap)
		)
		if grid.tiles[x] and grid.tiles[x][y] then
			if mouseButton == 1 and not config.flagMode then
				grid.tiles[x][y]:trigger(nil, true, grid.gamestate.forceClick)
				grid.gamestate.forceClick = false
			elseif mouseButton == 2 or config.flagMode then
				grid.tiles[x][y]:flag(true)
			elseif mouseButton == 3 then
			else
				error("need to provide mouse button for triggerTile")
			end
		end
	end

	if config.chillMode and not grid.gamestate.finished then
		grid:lambdaOnAllTiles(function(tile)
			for i = 1, 10, 1 do
				tile:tick(0.025)
			end
		end)
	end
end
local tickTimer = 0
local ticksThisSecond = 0
local timer = 0
function love.update(dt)
	if not config.pause then
		tickTimer = tickTimer + dt
		if tickTimer > 0.045 then
			tickTimer = tickTimer - 0.045
			ticksThisSecond = ticksThisSecond + 1
			local aliveTiles = 0
			grid:tick()
			grid:lambdaOnAllTiles(function(tile)
				if not (grid.gamestate.finished or config.chillMode) then
					tile:tick(1 / 60)
				end
				if tile.mine == false and tile.decay > 0 then
					aliveTiles = aliveTiles + 1
				end
			end)
			if aliveTiles == 0 and not grid.gamestate.forceClick and not grid.gamestate.finished then
				grid.gamestate.finished = true
				sounds.gameEnd:play()
				grid:lambdaOnAllTiles(function(tile)
					tile.parentGrid.tiles[tile.position.x] = tile.parentGrid.tiles[tile.position.x] or {}
					tile.parentGrid.tiles[tile.position.x][tile.position.y] = tile
					tile.parentGrid.unloadedTiles[tile.position.x][tile.position.y] = nil
				end, grid.unloadedTiles)
				-- this can be optimised but i cba
			end
		end

		grid:lambdaOnAllTiles(function(tile)
			tile:updateAnim(dt)
		end)
	end

	if love.keyboard.isDown("w") then
		config.pan = config.pan + vector.new(0, config.panSpeed * dt)
	elseif love.keyboard.isDown("s") then
		config.pan = config.pan + vector.new(0, -config.panSpeed * dt)
	end
	if love.keyboard.isDown("d") then
		config.pan = config.pan + vector.new(-config.panSpeed * dt, 0)
	elseif love.keyboard.isDown("a") then
		config.pan = config.pan + vector.new(config.panSpeed * dt, 0)
	end
	local touches = love.touch.getTouches()
	if touches[1] and not config.mobile then
		config.mobile = true
		config.showFlagButton = true
	end

	if not touches[2] then
		input.t1.lastTouchPos = nil
		input.t1.touchId = nil
		input.t2.lastTouchPos = nil
		input.t2.touchId = nil
		if love.mouse.isDown(1) then
			local newPos = vector.new(love.mouse.getPosition())
			if input.m1.lastMousePos and config.dragging then
				config.pan.x = config.pan.x + (newPos.x - input.m1.lastMousePos.x)
				config.pan.y = config.pan.y + (newPos.y - input.m1.lastMousePos.y)
			end
			input.m1.startingMousePos = input.m1.startingMousePos or newPos
			input.m1.lastMousePos = newPos
		else
			if input.m1.lastMousePos or input.m1.startingMousePos then
				if input.m1.lastMousePos:dist(input.m1.startingMousePos) <= 10 or not config.dragging then
					if config.showFlagButton and buttons.flag:isWithinRange(input.m1.lastMousePos) then
						config.flagMode = not config.flagMode
					elseif (grid.gamestate.finished or grid.gamestate.forceClick) and config.mobile and buttons.chill:isWithinRange(input.m1.lastMousePos) then
						config.chillMode = not config.chillMode
					elseif buttons.reset:isWithinRange(input.m1.lastMousePos) and (grid.gamestate.finished or grid.gamestate.forceClick) then
						grid = gridTemplate.new(config.fieldsize)
					elseif not config.pause then
						triggerTile(grid, input.m1.lastMousePos, 1)
					end
				end
				input.m1.lastMousePos = nil
				input.m1.startingMousePos = nil
			end
		end
		if love.mouse.isDown(2) then
			local newPos = vector.new(love.mouse.getPosition())
			input.m2.startingMousePos = input.m2.startingMousePos or newPos
			if input.m2.lastMousePos and config.dragging then
				config.pan.x = config.pan.x + (newPos.x - input.m2.lastMousePos.x)
				config.pan.y = config.pan.y + (newPos.y - input.m2.lastMousePos.y)
			end
			input.m2.lastMousePos = newPos
		else
			if input.m2.lastMousePos or input.m2.startingMousePos then
				if input.m2.lastMousePos:dist(input.m2.startingMousePos) <= 10 or not config.dragging then
					if not config.pause then
						triggerTile(grid, input.m2.lastMousePos, 2)
					end
				end
				input.m2.lastMousePos = nil
				input.m2.startingMousePos = nil
			end
		end
	else
		input.m1.lastMousePos = nil
		input.m1.startingMousePos = nil
		for i, value in ipairs(touches) do
			local t = "t" .. i
			local x, y = love.touch.getPosition(value)
			local pos = vector.new(x, y)
			if input[t].touchId ~= value then
				input[t].touchId = value
				input[t].startingTouchPos = pos
				input[t].lastTouchPos = nil
			else
				input[t].lastTouchPos = input[t].newTouchPos
			end
			input[t].newTouchPos = vector.new(x, y)
		end
	end
	if input.t1.lastTouchPos and input.t2.lastTouchPos then
		local center = (input.t1.startingTouchPos + input.t2.startingTouchPos) / 2
		local zoomAmount = ((input.t1.newTouchPos - input.t2.newTouchPos):getmag() -
			(input.t1.lastTouchPos - input.t2.lastTouchPos):getmag()) / 100
		local oldZoom = config.zoom
		config.zoom = config.zoom + (config.zoom * zoomAmount)
		config.pan.x = config.pan.x + (center.x - config.pan.x) * (1 - config.zoom / oldZoom)
		config.pan.y = config.pan.y + (center.y - config.pan.y) * (1 - config.zoom / oldZoom)
	end
	for _, button in pairs(buttons) do
		button:update()
	end
end

local function printTileLabel(tile, x, y, tileSize, scale, tileOpacity)
	local label = tile.label
	local color = { 1, 1, 1, 1 * tileOpacity }
	if label == 0 then
		color = { 0, 0, 0, 0 }
	elseif label == 1 then
		color = { 0, 0, 1, 1 * tileOpacity }
	elseif label == 2 then
		color = { 0, 0.5, 0, 1 * tileOpacity }
	elseif label == 3 then
		color = { 1, 0, 0, 1 * tileOpacity }
	elseif label == 4 then
		color = { 0, 0, 0.5, 1 * tileOpacity }
	elseif label == 5 then
		color = { 0.5, 0, 0, 1 * tileOpacity }
	elseif label == 6 then
		color = { 0, 0.5, 0.5, 1 * tileOpacity }
	elseif label == 7 then
		color = { 0.5, 0, 0.5, 1 * tileOpacity }
	elseif label == 8 then
		color = { 0.5, 0.5, 0.5, 1 * tileOpacity }
	end

	if tile.flagged then
		label = "F"
		if tile.halflife then
			color = { 1, 1, 0, 1 * tileOpacity }
		else
			if tile.mine then
				color = { 1, 1, 0, 0.5 * tileOpacity }
			else
				color = { 1, 0, 0, 1 * tileOpacity }
			end
		end
	end

	love.graphics.print({ color, label }, tileFont, x + scale / 4.5, y - scale * 0.26,
		nil,
		scale / 100,
		scale / 100)
end

function love.draw() ---@diagnostic disable-line: duplicate-set-field
	local tileSize = globals.tilesize * config.zoom
	if config.enableRendering then
		grid:lambdaOnAllTiles(function(tile)
			local tileOpacity = tile.decay
			if tileOpacity > 1 then tileOpacity = 1 end
			local scale = tileSize
			local translate = vector.new(0, 0)
			if grid.gamestate.finished then
				tileOpacity = 1
			else
				scale = scale * tileOpacity
			end
			for _, anim in pairs(tile.anims) do
				for trait, values in pairs(anim.subject) do
					if trait == "scale" then
						scale = scale * values.x
					elseif trait == "translate" then
						translate = vector.new(values.x, values.y)
					elseif trait == "opacity" then
						tileOpacity = tileOpacity * values
					end
				end
			end
			if scale < 0 then scale = 0 end
			local x = config.pan.x + (tileSize * globals.tileGap) * (tile.position.x + translate.x + 1) -
				((tileSize + scale) / 2)
			local y = config.pan.y + (tileSize * globals.tileGap) * (tile.position.y + translate.y + 1) -
				((tileSize + scale) / 2)
			if x > -scale and y > -scale and x < love.graphics.getWidth() and y < love.graphics.getHeight() then
				if tile.cleared then
					if tile.mine then
						love.graphics.setColor(1, 0.25, 0.25, 1 * tileOpacity)
					else
						love.graphics.setColor(0.75, 0.75, 0.75, 1 * tileOpacity)
					end
					love.graphics.rectangle("fill", x, y, scale, scale)
				elseif tile.label then
					love.graphics.setColor(0.2, 0.2, 0.2, 1 * tileOpacity)
					love.graphics.rectangle("fill", x, y, scale,
						scale)
				elseif tile.mine ~= nil then -- TODO: delete the blue tint and replace with smth else
					love.graphics.setColor(0.05, 0.1, 0.2, 1 * tileOpacity)
					love.graphics.rectangle("fill", x, y, scale, scale)
				end
				love.graphics.setColor(1, 1, 1, 1 * tileOpacity)
				if not (tile.cleared and tile.mine) then
					if not config.pause then
						printTileLabel(tile, x, y, tileSize, scale, tileOpacity)
					end
				end
				love.graphics.rectangle("line", x, y, scale, scale)
			end
		end)
	end
	if config.showFlagButton then
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.rectangle("line", buttons.flag.x, buttons.flag.y, buttons.flag.width, buttons.flag.height)

		if config.flagMode then
			love.graphics.setColor(1, 1, 0, 1)
		else
			love.graphics.setColor(1, 1, 0, 0.25)
		end
		love.graphics.printf("F", tileFont,
			buttons.flag.x + buttons.flag.width / 18, buttons.flag.y - buttons.flag.height * 0.26, buttons.flag.width,
			"center", 0, 1)
	end
	if grid.gamestate.finished or grid.gamestate.forceClick then
		if config.mobile then
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.rectangle("line", buttons.reset.x, buttons.reset.y, buttons.reset.width, buttons.reset.height)
			love.graphics.printf("R", tileFont,
				buttons.reset.x + buttons.reset.width / 18, buttons.reset.y - buttons.reset.height * 0.26,
				buttons.reset.width,
				"center", 0, 1)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.rectangle("line", buttons.chill.x, buttons.chill.y, buttons.chill.width, buttons.chill.height)

			if config.chillMode then
				love.graphics.setColor(1, 1, 1, 1)
			else
				love.graphics.setColor(1, 1, 1, 0.25)
			end
			love.graphics.printf("C", tileFont,
				buttons.chill.x + buttons.chill.width / 18, buttons.chill.y - buttons.chill.height * 0.26,
				buttons.chill.width,
				"center", 0, 1)
		end
	end
	local splash = ""
	if grid.gamestate.finished then
		splash = "Death :(\nScore: " .. grid.gamestate.score.tiles
	elseif config.pause then
		splash = "Game Paused"
	elseif grid.gamestate.forceClick then
		splash = "Escape the void.\nClick the tile to begin."
	end
	local textScale = (love.graphics.getWidth() + love.graphics.getHeight()) / (1080 + 1920)
	if textScale > 0.5 then
		textScale = 0.5
	end
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(splash, tileFont, 0,
		(love.graphics.getHeight() - (textScale * 200)) * 0.75, love.graphics.getWidth() / textScale,
		"center", 0, textScale)
	local usefulInfo =
		"VoidSweeper v1.3" ..
		"\nDeveloped by birbirl" ..
		"\nFPS: " .. love.timer.getFPS()
	if config.chillMode then
		usefulInfo = usefulInfo .. "\nChill Mode Enabled!"
	end
	if grid.gamestate.forceClick or config.pause then
		usefulInfo = usefulInfo ..
			"\n!When a tile with a flag is consumed, it restores tiles around it if it's correct, and destroys tiles if it's wrong" ..
			"\n!The void speeds up as more tiles get revealed"
		if config.mobile then
			usefulInfo = usefulInfo ..
				"\n- Tap on a tile to reveal it" ..
				"\n- Use F button to switch to flag mode" ..
				"\n- You can move/zoom the camera by dragging/pinching" ..
				"\n- Use the C button to enable Chill Mode (void advances only when you tap a tile)"
		else
			usefulInfo = usefulInfo ..
				"\n- Volume: " ..
				math.floor(love.audio.getVolume() * 10) / 10 ..
				"\n- Left click to reveal a tile" ..
				"\n- Right Click to place a flag" ..
				"\n- Drag click/wasd to move the camera" ..
				"\n- Scroll to zoom in/out" ..
				"\n- R to restart" ..
				"\n- P to pause" ..
				"\n- C to enable Chill Mode (void advances only when you click a tile)" ..
				"\n- Space to enable force-flag for left click" ..
				"\n- M to disable drag clicking" ..
				"\n- ]/[ to raise/lower wasd camera speed" ..
				"\n- +/- to raise/lower volume" ..
				"\n- f1 to disable rendering (debug)" ..
				"\n- f11 to fullscreen"
		end
	end
	love.graphics.printf(usefulInfo, tileFont, 0, 0, love.graphics.getWidth() * (1 / 0.15), "left", 0, 0.15)
end

function love.wheelmoved(x, y)
	y = bath.sign(y) / 4 -- the web version seems to go from -2 to 2 sometimes which breaks everything
	local mouseX, mouseY = love.mouse.getPosition()
	local oldZoom = config.zoom
	config.zoom = config.zoom + (config.zoom * y * 0.5)
	config.pan.x = config.pan.x + (mouseX - config.pan.x) * (1 - config.zoom / oldZoom)
	config.pan.y = config.pan.y + (mouseY - config.pan.y) * (1 - config.zoom / oldZoom)
end

--[[
TODO if i ever feel like it:
# new anim system that can be toggled, so that highlight for macro is on hover not on click
# non-void mode
# proper text display system (the font is currently bugged and has too high ascent)
# auto scrolling with grid expanding
--]]

---@diagnostic disable: redefined-local
local lume = require("library.modules.lume")
local serpent = require("library.modules.serpent")
local vector = require("library.modules.vector")
local Tile = require("tileLogic")
local globals = require("globals")
local tileFont = love.graphics.newFont("data/fonts/monocraft.ttc", 100)


love.graphics.setDefaultFilter("nearest")
love.window.setMode(1920, 1080, { resizable = true })


local gridTemplate = {
	new = function(fieldsize)
		local grid = {}
		grid.gamestate = {
			forceClick = true,
			freebies = love.math.random(20, 25),
			finished = false,
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
			for x = 1, fieldsize.x, 1 do
				for y = 1, fieldsize.y, 1 do
					local pos = vector.new(x, y)
					self:addTile(Tile:new(grid, pos), pos)
				end
			end
		end

		function grid:lambdaOnAllTiles()
		end

		if fieldsize then
			grid:generateStarterField(fieldsize)
		end

		return grid
	end

}


local config = {
	zoom = 2,
	pan = vector.new(0, 0),
	pause = false,
	fieldsize = vector.new(20, 25)
}
local grid
local function addTile(grid, tile, x, y)
	grid.tiles = grid.tiles or {}
	grid.tiles[x] = grid.tiles[x] or {}
	grid.tiles[x][y] = tile
end

function love.keypressed(key)
	if key == "r" then
		grid = gridTemplate.new(vector.new(10, 10))
		config.pan = vector.new(0, 0)
	end
	if key == "p" then
		config.pause = not config.pause
	end
end

function love.load()
	grid = gridTemplate.new(vector.new(10, 10))
end

local function printTileLabel(tile, x, y, size, tileOpacity)
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
		color = { 1, 1, 0, 1 * tileOpacity }
	end

	love.graphics.print({ color, label }, tileFont, config.pan.x + size * x + size / 4.5, config.pan.y + size * y, nil,
		size / 100,
		size / 100)
end

local m1 = {
	lastMousePos = nil,
	startingMousePos = nil
}
local m2 = {
	lastMousePos = nil,
	startingMousePos = nil
}
local m3 = {
	lastMousePos = nil,
	startingMousePos = nil
}
local function triggerTile(grid, mousePos, mouseButton)
	local size = globals.tilesize * config.zoom
	if not grid.gamestate.finished then
		x = math.floor(
			(mousePos.x - config.pan.x) / size
		)
		y = math.floor(
			(mousePos.y - config.pan.y) / size
		)
		if grid.tiles[x] and grid.tiles[x][y] then
			if mouseButton == 1 then
				grid.tiles[x][y]:trigger(nil, grid.gamestate.forceClick)
				grid.gamestate.forceClick = false
			elseif mouseButton == 2 then
				grid.tiles[x][y]:flag()
			elseif mouseButton == 3 then
			else
				error("need to provide mouse button for triggerTile")
			end
		end
	end
end

function love.update()
	if not config.pause then
		local aliveTiles = 0
		for x, column in pairs(grid.tiles) do
			if type(x) == "number" then
				for y, tile in pairs(column) do
					if not grid.gamestate.finished then
						tile:tick()
					end
					if tile.mine ~= nil and tile.decay > 0 then
						aliveTiles = aliveTiles + 1
					end
				end
			end
		end
		if aliveTiles == 0 and not grid.gamestate.forceClick and not grid.gamestate.finished then
			print(aliveTiles)
			grid.gamestate.finished = true
			local score = 0
			for x, column in pairs(grid.tiles) do
				if type(x) == "number" then
					for y, tile in pairs(column) do
						if tile.cleared then
							score = score + 1
						end
					end
				end
			end
			grid.gamestate.score.tiles = score
			print(grid.gamestate.score.tiles)
		end

		if love.mouse.isDown(1) then
			local newPos = vector.new(love.mouse.getPosition())
			if m1.lastMousePos then
				config.pan.x = config.pan.x + (newPos.x - m1.lastMousePos.x)
				config.pan.y = config.pan.y + (newPos.y - m1.lastMousePos.y)
			end
			m1.startingMousePos = m1.startingMousePos or newPos
			m1.lastMousePos = newPos
		else
			if m1.lastMousePos or m1.startingMousePos then
				if m1.lastMousePos:dist(m1.startingMousePos) <= 10 then
					triggerTile(grid, m1.lastMousePos, 1)
				end
				m1.lastMousePos = nil
				m1.startingMousePos = nil
			end
		end
		if love.mouse.isDown(2) then
			local newPos = vector.new(love.mouse.getPosition())
			m2.startingMousePos = m2.startingMousePos or newPos
			if m2.lastMousePos then
				config.pan.x = config.pan.x + (newPos.x - m2.lastMousePos.x)
				config.pan.y = config.pan.y + (newPos.y - m2.lastMousePos.y)
			end
			m2.lastMousePos = newPos
		else
			if m2.lastMousePos or m2.startingMousePos then
				if m2.lastMousePos:dist(m2.startingMousePos) <= 10 then
					triggerTile(grid, m2.lastMousePos, 2)
				end
				m2.lastMousePos = nil
				m2.startingMousePos = nil
			end
		end
		if love.mouse.isDown(3) then
			local newPos = vector.new(love.mouse.getPosition())
			m3.startingMousePos = m3.startingMousePos or newPos
			if m3.lastMousePos then
				config.pan.x = config.pan.x + (newPos.x - m3.lastMousePos.x)
				config.pan.y = config.pan.y + (newPos.y - m3.lastMousePos.y)
			end
			m3.lastMousePos = newPos
		else
			if m3.lastMousePos or m3.startingMousePos then
				if m3.lastMousePos:dist(m3.startingMousePos) <= 10 then
					triggerTile(grid, m3.lastMousePos, 3)
				end
				m3.lastMousePos = nil
				m3.startingMousePos = nil
			end
		end
	end
	love.timer.sleep(0.015) --- limits the game to 60fps lol
end

function love.draw() ---@diagnostic disable-line: duplicate-set-field
	local size = globals.tilesize * config.zoom
	for x, row in pairs(grid.tiles) do
		if type(x) == "number" then
			for y, tile in pairs(row) do
				local tileOpacity = tile.decay
				if grid.gamestate.finished then
					tileOpacity = 1
				end
				if tile.cleared then
					if tile.mine then
						love.graphics.setColor(1, 0.25, 0.25, 1 * tileOpacity)
					else
						love.graphics.setColor(0.75, 0.75, 0.75, 1 * tileOpacity)
					end
					love.graphics.rectangle("fill", config.pan.x + size * x, config.pan.y + size * y, size, size)
				elseif tile.label then
					love.graphics.setColor(0.2, 0.2, 0.2, 1 * tileOpacity)
					love.graphics.rectangle("fill", config.pan.x + size * x, config.pan.y + size * y, size, size)
				elseif tile.mine ~= nil then -- TODO: delete the blue tint and replace with smth else
					love.graphics.setColor(0.05, 0.1, 0.2, 1 * tileOpacity)
					love.graphics.rectangle("fill", config.pan.x + size * x, config.pan.y + size * y, size, size)
				end
				love.graphics.setColor(1, 1, 1, 1 * tileOpacity)
				if not (tile.cleared and tile.mine) then
					if not config.pause then
						printTileLabel(tile, x, y, size, tileOpacity)
					end
				end

				love.graphics.rectangle("line", config.pan.x + size * x, config.pan.y + size * y, size, size)
			end
		end
	end
	local splash = ""
	if grid.gamestate.finished then
		splash = "Death :(\nScore: " .. grid.gamestate.score.tiles
	elseif config.pause then
		splash = "Game Paused"
	end
	local textScale = love.graphics.getWidth() * 0.5 / 1080
	love.graphics.printf(splash, tileFont, 0,
		love.graphics.getHeight() * 0.05, love.graphics.getWidth() / textScale,
		"center", 0, textScale)
	love.graphics.print(
		"MineSweeter alpha" ..
		"\nFPS: " ..
		love.timer.getFPS() ..
		"\nLeft click to reveal a tile\nRight Click to mark a mine\nR to restart\nP to pause",
		tileFont, 0, 0, 0, 1 / 5)
end

function love.wheelmoved(x, y)
	local mouseX, mouseY = love.mouse.getPosition()
	local oldZoom = config.zoom
	config.zoom = config.zoom + (config.zoom * y * 0.05)
	config.pan.x = config.pan.x + (mouseX - config.pan.x) * (1 - config.zoom / oldZoom)
	config.pan.y = config.pan.y + (mouseY - config.pan.y) * (1 - config.zoom / oldZoom)
end

--[[
TODO:
# fix the web version so it doesn't stretch
# add decay
# scrolling with grid
# walls of mines sometimes
# add tile culling

--]]

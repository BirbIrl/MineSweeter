---@diagnostic disable: redefined-local

local serpent = require("library.modules.serpent")
local bath = require("library.modules.bath")
local vector = require("library.modules.vector")
local tween = require("library.modules.tween")
local Tile = require("tileLogic")
local sounds = require("sounds")
local globals = require("globals")
local tileFont = love.graphics.newFont("data/fonts/monocraft.ttc", 100)

love.graphics.setDefaultFilter("nearest")

local config = {
	zoom = 2,
	pan = vector.new(0, 0),
	pause = false,
	enableRendering = true,
	fieldsize = vector.new(1, 1)
}

local gridTemplate = {
	new = function(fieldsize)
		local grid = {}
		grid.gamestate = {
			forceClick = true,
			freebies = love.math.random(10, 10),
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
			self.gamestate.decayRate = globals.defaultDecayRate * math.sqrt(self.gamestate.score.tiles)
			print(self.gamestate.decayRate / globals.defaultDecayRate)
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
	end
	if key == "p" then
		config.pause = not config.pause
	end
	if key == "f1" then
		config.enableRendering = not config.enableRendering
	end
	if key == "f11" then
		love.window.setFullscreen(not love.window.getFullscreen())
	end
end

function love.load()
	grid = gridTemplate.new(config.fieldsize)
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
		local x = math.floor(
			(mousePos.x - config.pan.x) / (size * globals.tileGap)
		)
		local y = math.floor(
			(mousePos.y - config.pan.y) / (size * globals.tileGap)
		)
		if grid.tiles[x] and grid.tiles[x][y] then
			if mouseButton == 1 then
				grid.tiles[x][y]:trigger(nil, true, grid.gamestate.forceClick)
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
local tickTimer = 0
local ticksThisSecond = 0
local timer = 0
function love.update(dt)
	tickTimer = tickTimer + dt
	if not config.pause then
		if tickTimer > 0.045 then
			tickTimer = tickTimer - 0.045
			ticksThisSecond = ticksThisSecond + 1
			local aliveTiles = 0
			grid:tick()
			grid:lambdaOnAllTiles(function(tile)
				if not grid.gamestate.finished then
					tile:tick(dt)
				end
				if tile.mine ~= nil and tile.decay > 0 then
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
				if not config.pause then
					triggerTile(grid, m1.lastMousePos, 1)
				end
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
				if not config.pause then
					triggerTile(grid, m2.lastMousePos, 2)
				end
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
		color = { 1, 1, 0, 1 * tileOpacity }
	end

	love.graphics.print({ color, label }, tileFont, x + scale / 4.5, y,
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
						tileOpacity = values
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
	local splash = ""
	if grid.gamestate.finished then
		splash = "Death :(\nScore: " .. grid.gamestate.score.tiles
	elseif config.pause then
		splash = "Game Paused"
	end
	local textScale = (love.graphics.getWidth() + love.graphics.getHeight()) / (1080 + 1920)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(splash, tileFont, 0,
		(love.graphics.getHeight() - (textScale * 200)) * 0.75, love.graphics.getWidth() / textScale,
		"center", 0, textScale)
	love.graphics.print(
		"MineSweeter alpha v0.2" ..
		"\nFPS: " ..
		love.timer.getFPS() ..
		"\nLeft click to reveal a tile\nRight Click to mark a mine\nR to restart\nP to pause\nf1 to disable rendering (debug)\nf11 to fullscreen",
		tileFont, 0, 0, 0, 0.15)
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
TODO:
# scrolling with grid expanding
# walls of mines sometimes
--]]

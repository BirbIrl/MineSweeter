---@diagnostic disable: redefined-local
local lume = require("library.modules.lume")
local serpent = require("library.modules.serpent")
local vector = require("library.modules.vector")
local Tile = require("tileLogic")
local globals = require("globals")
local tileFont = love.graphics.newFont("data/fonts/monocraft.ttc", 100)


local config = {
	zoom = 2,
	pan = vector.new(0, 0),
	fieldsize = vector.new(20, 25)
}
local grid
local function addTile(grid, tile, x, y)
	grid = grid or {}
	grid[x] = grid[x] or {}
	grid[x][y] = tile
end

function love.keypressed(key)
	if key == "r" then
		grid = {
			gamestate = {
				freebies = math.random(15, 22)
			}
		}
		for x = 1, config.fieldsize.x, 1 do
			for y = 1, config.fieldsize.y, 1 do
				addTile(grid, Tile:new(grid, vector.new(x, y)), x, y)
			end
		end
	end
end

function love.load()
	grid = {
		gamestate = {
			forceClick = true,
			freebies = math.random(15, 22)
		}
	}
	for x = 1, config.fieldsize.x, 1 do
		for y = 1, config.fieldsize.y, 1 do
			addTile(grid, Tile:new(grid, vector.new(x, y)), x, y)
		end
	end
end

local function printTileLabel(tile, x, y, size)
	local label = tile.label
	local color = { 1, 1, 1, 1 }
	if label == 0 then
		color = { 0, 0, 0, 0 }
	elseif label == 1 then
		color = { 0, 0, 1, 1 }
	elseif label == 2 then
		color = { 0, 0.5, 0, 1 }
	elseif label == 3 then
		color = { 1, 0, 0, 1 }
	elseif label == 4 then
		color = { 0, 0, 0.5, 1 }
	elseif label == 5 then
		color = { 0.5, 0, 0, 1 }
	elseif label == 6 then
		color = { 0, 0.5, 0.5, 1 }
	elseif label == 7 then
		color = { 0.5, 0, 0.5, 1 }
	elseif label == 8 then
		color = { 0.5, 0.5, 0.5, 1 }
	end

	if tile.flagged then
		label = "F"
		color = { 1, 1, 0, 1 }
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
	x = math.floor(
		(mousePos.x - config.pan.x) / size
	)
	y = math.floor(
		(mousePos.y - config.pan.y) / size
	)
	if grid[x] and grid[x][y] then
		if mouseButton == 1 then
			grid[x][y]:trigger(nil, grid.gamestate.forceClick)
			grid.gamestate.forceClick = false
		elseif mouseButton == 2 then
			grid[x][y]:flag()
		elseif mouseButton == 3 then
		else
			error("need to provide mouse button for triggerTile")
		end
	end
end

function love.update()
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

function love.draw() ---@diagnostic disable-line: duplicate-set-field
	local size = globals.tilesize * config.zoom
	for x, row in pairs(grid) do
		if type(x) == "number" then
			for y, tile in pairs(row) do
				if tile.cleared then
					if tile.mine then
						love.graphics.setColor(1, 0.25, 0.25, 1)
					else
						love.graphics.setColor(0.75, 0.75, 0.75, 1)
					end
					love.graphics.rectangle("fill", config.pan.x + size * x, config.pan.y + size * y, size, size)
				elseif tile.label then
					love.graphics.setColor(0.2, 0.2, 0.2, 1)
					love.graphics.rectangle("fill", config.pan.x + size * x, config.pan.y + size * y, size, size)
				elseif tile.mine ~= nil then -- TODO: delete the blue tint and replace with smth else
					love.graphics.setColor(0.05, 0.1, 0.2, 1)
					love.graphics.rectangle("fill", config.pan.x + size * x, config.pan.y + size * y, size, size)
				end
				love.graphics.setColor(1, 1, 1, 1)
				if not (tile.cleared and tile.mine) then
					printTileLabel(tile, x, y, size)
				end

				love.graphics.rectangle("line", config.pan.x + size * x, config.pan.y + size * y, size, size)
			end
		end
	end
end

function love.wheelmoved(x, y)
	local mouseX, mouseY = love.mouse.getPosition()
	local oldZoom = config.zoom
	config.zoom = config.zoom + (config.zoom * y * 0.05)
	config.pan.x = config.pan.x + (mouseX - config.pan.x) * (1 - config.zoom / oldZoom)
	config.pan.y = config.pan.y + (mouseY - config.pan.y) * (1 - config.zoom / oldZoom)
end

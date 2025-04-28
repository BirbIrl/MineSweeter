---@diagnostic disable: redefined-local
local lume = require("library.modules.lume")
local serpent = require("library.modules.serpent")
local vector = require("library.modules.vector")
local Tile = require("tileLogic")
local globals = require("globals")
local tileFont = love.graphics.newFont("data/fonts/monocraft.ttc", 100)


local config = {
	zoom = 2,
	pan = vector.new(0, 0)
}
local grid = {
	gamestate = {
		freebies = math.random(15, 22)
	}
}
local function addTile(grid, tile, x, y)
	grid = grid or {}
	grid[x] = grid[x] or {}
	grid[x][y] = tile
end


function love.load()
	for x = 1, 10, 1 do
		for y = 1, 10, 1 do
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
	elseif label == "F" then
		color = { 1, 1, 0, 1 }
	end


	love.graphics.print({ color, label }, tileFont, config.pan.x + size * x + size / 4.5, config.pan.y + size * y, nil,
		size / 100,
		size / 100)
end

local lastMousePos
local startingMousePos

local function triggerTile(grid, mousePos)
	local size = globals.tilesize * config.zoom
	x = math.floor(
		(mousePos.x - config.pan.x) / size
	)
	y = math.floor(
		(mousePos.y - config.pan.y) / size
	)
	if grid[x] and grid[x][y] then
		grid[x][y]:trigger()
	end
	print(x, y)
end

function love.update()
	if love.mouse.isDown(1) then
		local newPos = vector.new(love.mouse.getPosition())
		startingMousePos = startingMousePos or newPos
		if lastMousePos then
			config.pan.x = config.pan.x + (newPos.x - lastMousePos.x)
			config.pan.y = config.pan.y + (newPos.y - lastMousePos.y)
		end
		lastMousePos = newPos
	else
		if lastMousePos or startingMousePos then
			if lastMousePos:dist(startingMousePos) <= 10 then
				triggerTile(grid, lastMousePos)
			end
			lastMousePos = nil
			startingMousePos = nil
		end
	end
end

function love.draw() ---@diagnostic disable-line: duplicate-set-field
	local size = globals.tilesize * config.zoom
	for x, row in pairs(grid) do
		if type(x) == "number" then
			for y, tile in pairs(row) do
				if tile.cleared then
					if tile.isMine then
						love.graphics.setColor(1, 0.25, 0.25, 1)
					else
						love.graphics.setColor(0.75, 0.75, 0.75, 1)
					end
					love.graphics.rectangle("fill", config.pan.x + size * x, config.pan.y + size * y, size, size)
				elseif tile.label then
					love.graphics.setColor(0.2, 0.2, 0.2, 1)
					love.graphics.rectangle("fill", config.pan.x + size * x, config.pan.y + size * y, size, size)
				elseif tile.isMine ~= nil then -- TODO: delete
					love.graphics.setColor(0, 0, 0.2, 1)
					love.graphics.rectangle("fill", config.pan.x + size * x, config.pan.y + size * y, size, size)
				end
				love.graphics.setColor(1, 1, 1, 1)
				printTileLabel(tile, x, y, size)
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

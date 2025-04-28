---@diagnostic disable: redefined-local
local globals = require("globals")
local vector = require("library.modules.vector")
local tileTemplate = {
	new = nil -- defined later
}
local function lambdaInRadius(grid, pos, func, radius, curve)
	local hits = 0
	radius = radius or 1
	for x = -radius, radius, 1 do
		for y = -radius, radius, 1 do
			if not (curve and x ^ 2 + y ^ 2 > radius ^ 2)
				and grid[pos.x + x] then
				if grid[pos.x + x][pos.y + y] then
					if func(grid[pos.x + x][pos.y + y]) == true then
						hits = hits + 1
					end
				end
			end
		end
	end
	return hits
end
local function generateTilesInRadius(grid, pos, radius, curve)
	local hits = 0
	radius = radius or 1
	for x = -radius, radius, 1 do
		for y = -radius, radius, 1 do
			if not (curve and x ^ 2 + y ^ 2 > radius ^ 2) then
				if not grid[pos.x + x] then grid[pos.x + x] = {} end
				if not grid[pos.x + x][pos.y + y] then
					grid[pos.x + x][pos.y + y] = tileTemplate:new(grid, vector.new(pos.x + x, pos.y + y))
				end
			end
		end
	end
end
tileTemplate = {
	new = function(self, parentGrid, position)
		local tile =
		{
			size = globals.tilesize,
			label = nil,
			mine = nil,
			chain = nil,
			flagged = false,
			position = position,
			parentGrid = parentGrid,
			cleared = false,
		}

		function tile:observe(chain)
			if self.mine == nil then
				if not self.chain then self.chain = chain end
				if self.parentGrid.gamestate.freebies > 0 then
					self.mine = false
					self.parentGrid.gamestate.freebies = self.parentGrid.gamestate.freebies - 1
				elseif math.random() <= globals.mineChance * self.chain then
					self.mine = true
				else
					self.mine = false
				end
			else
				return false
			end
			return true
		end

		function tile:generateNew(x, y, isMine, grid)
			grid = parentGrid or grid or {}
			grid[x] = grid[x] or {}
			grid[x][y] = tileTemplate:new()
		end

		function tile:triggerInRadius(radius, curve, chain)
			return lambdaInRadius(self.parentGrid, self.position, function(tile)
				if not tile.cleared then
					return tile:trigger(chain)
				end
				return false
			end, radius, curve)
		end

		function tile:observeInRadius(radius, curve, chain)
			return lambdaInRadius(self.parentGrid, self.position, function(tile)
				return tile:observe(chain)
			end, radius, curve)
		end

		function tile:generateInRadius(radius, curve)
			generateTilesInRadius(self.parentGrid, self.position, radius, curve)
		end

		function tile:countInRadiusFlagsOrRevealedBombs(radius, curve)
			return lambdaInRadius(self.parentGrid, self.position, function(tile)
				return (tile.flagged or (tile.cleared and tile.mine))
			end, radius, curve)
		end

		function tile:getLabel(chain)
			self.label = lambdaInRadius(self.parentGrid, self.position, function(tile)
				if tile.mine then
					return true
				else
					return false
				end
			end)
			if self.label == 0 then
				self:triggerInRadius(1, false, chain + 1)
			end
		end

		function tile:trigger(chain, force)
			chain = chain or 1
			if not self.flagged then
				if self.cleared == false then
					if self.mine == nil and not force then
						return false
					end
					self.cleared = true
					if self.mine then
						print("Boom!!")
					else
						self.chain = chain
						self:generateInRadius(10, true)
						self:observeInRadius(1, false, chain + 1)
						self:getLabel(chain)
					end
				else
					if self.label == self:countInRadiusFlagsOrRevealedBombs() then
						self:triggerInRadius(1, false, chain)
					end
				end
			end
		end

		function tile:flag()
			if self.mine ~= nil and not self.cleared then
				self.flagged = not self.flagged
			end
		end

		return tile
	end
}
return tileTemplate

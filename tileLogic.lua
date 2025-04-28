---@diagnostic disable: redefined-local
local globals = require("globals")
local function lambaOnNeighbours(grid, pos, func)
	local hits = 0
	for x = -1, 1, 1 do
		for y = -1, 1, 1 do
			if grid[pos.x + x] then
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
local tileTemplate = {
	new = function(self, parentGrid, position)
		local tile =
		{
			size = globals.tilesize,
			label = nil,
			isMine = nil,
			position = position,
			parentGrid = parentGrid,
			cleared = false,
		}

		function tile:observe()
			if self.isMine == nil then
				if self.parentGrid.gamestate.freebies > 0 then
					self.isMine = false
					self.parentGrid.gamestate.freebies = self.parentGrid.gamestate.freebies - 1
				elseif math.random() <= 0.25 then
					self.isMine = true
				else
					self.isMine = false
				end
			else
				return false
			end
			return true
		end

		function tile:triggerNeighbours()
			lambaOnNeighbours(self.parentGrid, self.position, function(tile)
				return tile:trigger()
			end)
		end

		function tile:observeNeighbours()
			lambaOnNeighbours(self.parentGrid, self.position, function(tile)
				return tile:observe()
			end)
		end

		function tile:getLabel()
			self.label = lambaOnNeighbours(self.parentGrid, self.position, function(tile)
				if tile.isMine then
					return true
				else
					return false
				end
			end)
			if self.label == 0 then
				self:triggerNeighbours()
			end
		end

		function tile:trigger()
			if self.cleared == false then
				if self.isMine == nil then
					self:observe()
				end
				self.cleared = true
				if self.isMine then
					print("Boom!!")
				else
					self:observeNeighbours()
					self:getLabel()
				end
			end
		end

		return tile
	end
}
return tileTemplate

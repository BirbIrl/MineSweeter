---@diagnostic disable: redefined-local
local globals = require("globals")
local vector = require("library.modules.vector")
local serpent = require("library.modules.serpent")
local sounds = require("sounds")
local anims = require "anim"
local tileTemplate = {
	new = nil -- defined later
}



tileTemplate = {
	new = function(self, parentGrid, position)
		local tile =
		{
			size = globals.tilesize,
			label = nil,
			mine = nil,
			flagged = false,
			position = position,
			parentGrid = parentGrid,
			decay = 1 + (love.math.random() * 0.5),
			anims = {},
			decaying = false,
			halflife = 0.75,
			cleared = false,
			exhausted = nil
		}

		function tile:lambdaInRadius(func, pos, radius, curve, includeSelf)
			local hits = 0
			pos = pos or self.pos
			radius = radius or 1
			for x = -radius, radius, 1 do
				for y = -radius, radius, 1 do
					local tileRadius = math.sqrt(x ^ 2 + y ^ 2)
					local pos = self.position
					local grid = self.parentGrid
					if not (curve and tileRadius > radius)
						and (includeSelf or not (x == 0 and y == 0))
						and grid.tiles[pos.x + x] then
						if grid.tiles[pos.x + x][pos.y + y] then
							if func(grid.tiles[pos.x + x][pos.y + y], tileRadius) == true then
								hits = hits + 1
							end
						end
					end
				end
			end
			return hits
		end

		function tile:generateTilesInRadius(pos, radius, curve, chainSource)
			local chainPenalty = 0
			pos = pos or self.pos
			radius = radius or 1
			for x = -radius, radius, 1 do
				for y = -radius, radius, 1 do
					grid = self.parentGrid
					if not (curve and x ^ 2 + y ^ 2 > radius ^ 2) then
						if not grid.tiles[pos.x + x] then grid.tiles[pos.x + x] = {} end
						if not grid.tiles[pos.x + x][pos.y + y]
							and not (grid.unloadedTiles[pos.x + x] and grid.unloadedTiles[pos.x + x][pos.y + y]) then
							local tile = tileTemplate:new(grid, vector.new(pos.x + x, pos.y + y))
							grid.tiles[pos.x + x][pos.y + y] = tile
							if chainSource then
								chainPenalty = math.sqrt(chainSource:dist(tile.position))
							end
							tile.anims[#self.anims + 1] = anims.reveal(0.25,
								chainPenalty / 10 - 0.1)
						end
					end
				end
			end
		end

		function tile:observe(chainSource)
			if self.mine == nil then
				local chainPenalty = 1
				if chainSource then
					chainPenalty = math.sqrt(chainSource:dist(self.position))
				end
				self.anims[#self.anims + 1] = anims.popScale(1.2, 0.25, chainPenalty / 10)
				self.anims[#self.anims + 1] = anims.shuffleAway(chainSource, self.position, 0.25, chainPenalty / 10)

				if self.parentGrid.gamestate.freebies > 0 then
					self.mine = false
					self.parentGrid.gamestate.freebies = self.parentGrid.gamestate.freebies - 1
				elseif love.math.random() <= globals.mineChance * chainPenalty
				then
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
			grid.tiles[x] = grid.tiles[x] or {}
			grid.tiles[x][y] = tileTemplate:new()
		end

		function tile:triggerInRadius(radius, curve, includeSelf, chainSource)
			return self:lambdaInRadius(function(tile)
				if not tile.cleared then
					return tile:trigger(chainSource)
				end
				return false
			end, self.position, radius, curve, includeSelf)
		end

		function tile:highlightForMacroInRadius(radius, curve)
			return self:lambdaInRadius(function(tile)
				if not tile.cleared then
					tile.anims[#tile.anims + 1] = anims.popScale(1.15, 0.15)
				end
			end, self.position, radius, curve)
		end

		function tile:observeInRadius(radius, curve, includeSelf, chainSource)
			return self:lambdaInRadius(function(tile)
				return tile:observe(chainSource)
			end, self.position, radius, curve, includeSelf)
		end

		function tile:startDecayInRadius(radius, curve, includeSelf, strength, falloff)
			strength = strength or 0
			falloff = falloff or 1
			return self:lambdaInRadius(function(tile, tileRadius)
				if tile.decay > 0 then
					if strength >= 0 then
						tile.decaying = true
					else
						tile.anims[#tile.anims + 1] = anims.popScale(1 - strength * 0.15 / (tileRadius * falloff), 0.25)
					end
					tile.decay = tile.decay - strength / (tileRadius * falloff)
				end
			end, self.position, radius, curve, includeSelf)
		end

		function tile:countInRadiusFlagsOrRevealedBombs(radius, curve)
			return self:lambdaInRadius(function(tile)
				return (tile.flagged or (tile.cleared and tile.mine))
			end, self.position, radius, curve)
		end

		function tile:getLabel(chainSource)
			self.label = self:lambdaInRadius(function(tile)
				if tile.mine then
					return true
				else
					return false
				end
			end)
			if self.label == 0 then
				self:triggerInRadius(1, false, false, chainSource)
			end
		end

		function tile:tick(dt)
			if self.exhausted then
				self.exhausted = self.exhausted - (dt * 4)
				print(self.exhausted)
				self.decay = self.exhausted
			elseif self.decaying and self.decay > 0 then
				self.decay = self.decay - self.parentGrid.gamestate.decayRate * dt
			end
			if self.halflife and self.decay < self.halflife then
				if self.flagged then
					if self.mine then
						self:startDecayInRadius(4, true, false, -0.25, 0.5)
						sounds.flag:clone():play()
					else
						self:startDecayInRadius(3, true, false, 0.25, 0.5)
						sounds.boom:clone():play()
					end
					self.anims[#self.anims + 1] = anims.popUp()
					self.anims[#self.anims + 1] = anims.shove()
					if self.decay < 0.5 then
						self.decay = 1
					end
					self.exhausted = self.decay
				end
				self:startDecayInRadius(1, true)
				self.halflife = false
			end
			if self.decay < 0 and
				(not self.exhausted or self.exhausted < -4) then
				self.decay = 0
				self.loaded = false
				if self.flagged then
					print("flag purged")
				end
				self.anims = {}
				local unloadedGrid = self.parentGrid.unloadedTiles
				unloadedGrid[self.position.x] = unloadedGrid[self.position.x] or {}
				unloadedGrid[self.position.x][self.position.y] = self
				self.parentGrid.tiles[self.position.x][self.position.y] = nil
			end
		end

		function tile:updateAnim(dt)
			for i, anim in pairs(self.anims) do
				if not anim:tick(dt) then
					self.anims[i] = nil
				end
			end
		end

		function tile:chord(chainSource)
			if self.label == self:countInRadiusFlagsOrRevealedBombs() then
				if self.parentGrid.gamestate.freebies > 0 then
					chainSource = self.position
				end
				if self:triggerInRadius(1, false, true, chainSource) > 0 then
					sounds.reveal:clone():play()
				else
					sounds.fail:clone():play()
				end
			else
				self:highlightForMacroInRadius()
				sounds.fail:clone():play()
			end
		end

		function tile:trigger(chainSource, player, force)
			if player and tile.exhausted then
				return false
			end
			if not chainSource then
				chainSource = self.position
				self.anims[#self.anims + 1] = anims.popScale(1.15, 0.15)
			end
			if self.flagged then
				if player then
					sounds.fail:clone():play()
				end
				return false
			end
			if self.decay > 0 then
				if self.cleared == false then
					if self.mine == nil and not force then
						if player then
							sounds.fail:clone():play()
						end
						return false
					end
					self.cleared = true
					if force then
						self.decaying = true
					end
					if self.mine then
						self:startDecayInRadius(4, true, false, 1, 0.4)
						self.decaying = true
						sounds.boom:play()
					else
						if player then
							sounds.reveal:clone():play()
						end
						self:generateTilesInRadius(self.position, 8, true, chainSource)
						self:observeInRadius(1, false, true, chainSource)
						self:getLabel(chainSource)
					end
					self.parentGrid.gamestate.score.tiles = self.parentGrid.gamestate.score.tiles + 1
					return true
				else
					if player then
						tile:chord(chainSource)
					end
				end
			end
		end

		function tile:flag(player)
			self.anims[#self.anims + 1] = anims.popScale(1.15, 0.15)
			if not self.cleared then
				if self.mine ~= nil then
					self.flagged = not self.flagged
					sounds.flag:clone():play()
				else
					sounds.fail:clone():play()
				end
			elseif player then
				tile:chord()
			end
		end

		return tile
	end
}
return tileTemplate

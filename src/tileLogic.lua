---@diagnostic disable: redefined-local
local globals = require("globals")
local vector = require("library.modules.vector")
local tween = require("library.modules.tween")
local serpent = require("library.modules.serpent")
local sounds = require("sounds")
local tileTemplate = {
	new = nil -- defined later
}

local animTemplate = {
}
function animTemplate:new(tween, delay)
	delay = delay or 0
	local twn = tween
	twn.delay = delay
	function twn:tick(dt)
		if delay > 0 then
			delay = delay - dt
		elseif twn:update(dt) then
			self = nil
		end
	end

	return twn
end

function animTemplate:newMirrored(tween, delay)
	local twn = self:new(tween, delay)
	twn.hasLooped = false
	function twn:tick(dt)
		if self.delay > 0 then
			self.delay = self.delay - dt
		elseif twn:update(dt) then
			if not self.hasLooped then
				local tmp = self.initial
				self.initial = self.target
				self.target = tmp
				self:reset()
				self.hasLooped = true
			else
				self = nil
			end
		end
	end

	return twn
end

local anims = {
	popScale = function(size, duration, delay)
		return animTemplate:newMirrored(
			tween.new(duration, { scale = { x = 1, y = 1 } }, { scale = { x = size, y = size } }, "inOutSine"), delay)
	end,
	reveal = function(duration, delay)
		return animTemplate:new(
			tween.new(duration, { opacity = 0 }, { opacity = 1 }, "inOutSine"), delay)
	end,
	shuffleAway = function(sourcePos, targetPos, duration, delay)
		local translate = targetPos - sourcePos
		translate = translate / 20
		return animTemplate:newMirrored(
			tween.new(duration, { translate = { x = 0, y = 0 } }, { translate = { x = translate.x, y = translate.y } },
				"inOutSine"),
			delay)
	end
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
			halflife = 0.5,
			cleared = false,
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
					tile.decaying = true
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

		function tile:tick()
			if tile.decaying and tile.decay > 0 then
				tile.decay = tile.decay - self.parentGrid.gamestate.decayRate
			end
			if tile.decay < 0 then
				tile.decay = 0
				tile.loaded = false
				local unloadedGrid = self.parentGrid.unloadedTiles
				unloadedGrid[self.position.x] = unloadedGrid[self.position.x] or {}
				unloadedGrid[self.position.x][self.position.y] = self
				self.parentGrid.tiles[self.position.x][self.position.y] = nil
			end
			if tile.halflife and tile.decay < tile.halflife then
				tile:startDecayInRadius(1, true)
				tile.halflife = false
			end
		end

		function tile:updateAnim(dt)
			for _, anim in pairs(self.anims) do
				anim:tick(dt)
			end
		end

		function tile:trigger(chainSource, player, force)
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
						self:startDecayInRadius(4, true, false, 1, 0.5)
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
					if player and self.label == self:countInRadiusFlagsOrRevealedBombs() then
						if self.parentGrid.gamestate.freebies > 0 then
							chainSource = self.position
						end
						if self:triggerInRadius(1, false, true) > 0 then
							sounds.reveal:clone():play()
						else
							sounds.fail:clone():play()
						end
					elseif player then
						self:highlightForMacroInRadius()
						sounds.fail:clone():play()
					end
				end
			end
		end

		function tile:flag()
			self.anims[#self.anims + 1] = anims.popScale(1.15, 0.15)
			if self.mine ~= nil and not self.cleared then
				self.flagged = not self.flagged
				sounds.flag:clone():play()
			end
		end

		return tile
	end
}
return tileTemplate

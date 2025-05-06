local tween = require("library.modules.tween")
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
return anims

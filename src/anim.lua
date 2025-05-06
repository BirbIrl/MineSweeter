local tween = require("library.modules.tween")
local animTemplate = {
}
function animTemplate:new(tween, delay, name, persistent)
	delay = delay or 0
	local twn = tween
	twn.name = name
	twn.delay = delay
	function twn:tick(dt)
		if delay > 0 then
			delay = delay - dt
		elseif twn:update(dt) and not persistent then
			return false
		end
		return true
	end

	return twn
end

function animTemplate:newMirrored(tween, delay, name)
	local twn = self:new(tween, delay, name)
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
				return false
			end
		end
		return true
	end

	return twn
end

local anims = {
}
anims.popScale = function(size, duration, delay)
	return animTemplate:newMirrored(
		tween.new(duration, { scale = { x = 1, y = 1 } }, { scale = { x = size, y = size } }, "inOutSine"), delay,
		"popScale")
end
anims.reveal = function(duration, delay)
	return animTemplate:new(
		tween.new(duration, { opacity = 0 }, { opacity = 1 }, "inOutSine"), delay, "reveal")
end
anims.popUp = function(strength, duration, delay)
	strength = strength or 0.75
	delay = delay or 0
	duration = duration or 0.25

	return animTemplate:newMirrored(
		tween.new(duration, { translate = { x = 0, y = 0 } },
			{ translate = { x = 0, y = -1 * strength } },
			"outSine"), delay, "popUp")
end
anims.shove = function(strength, duration, delay)
	strength = strength or 1
	delay = delay or 0
	duration = duration or 0.5

	return animTemplate:new(
		tween.new(duration, { translate = { x = 0, y = 0 } },
			{
				translate = {
					x = 3 * (math.random() - 0.5) * strength, y = math.random() / 2
				}
			},
			"inOutSine"), delay, "shove", true)
end
anims.shuffleAway = function(sourcePos, targetPos, duration, delay)
	local translate = targetPos - sourcePos
	translate = translate / 20
	return animTemplate:newMirrored(
		tween.new(duration, { translate = { x = 0, y = 0 } }, { translate = { x = translate.x, y = translate.y } },
			"inOutSine"), delay, "shuffleAway")
end
return anims

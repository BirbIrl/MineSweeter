local buttons = {}
local flagButton = {
	width = 100,
	height = 100,
	x = 0,
}
flagButton.y = love.graphics.getHeight() - flagButton.height

function flagButton:isWithinRange(pos)
	if pos.x > self.x and pos.x < self.width + self.x
		and pos.y > self.y and pos.y < self.height + self.y
	then
		return true
	end
end

function flagButton:update()
	self.y = love.graphics.getHeight() - self.height
end

buttons.flag = flagButton

local resetButton = {
	width = 100,
	height = 100,
}
resetButton.x = love.graphics.getWidth() - resetButton.width
resetButton.y = love.graphics.getHeight() - resetButton.height

function resetButton:isWithinRange(pos)
	if pos.x > self.x and pos.x < self.width + self.x
		and pos.y > self.y and pos.y < self.height + self.y
	then
		return true
	end
end

function resetButton:update()
	self.x = love.graphics.getWidth() - self.width
	self.y = love.graphics.getHeight() - self.height
end

buttons.reset = resetButton

local chillButton = {
	width = 100,
	height = 100,
}
chillButton.x = love.graphics.getWidth() - chillButton.width - 100
chillButton.y = love.graphics.getHeight() - chillButton.height

function chillButton:isWithinRange(pos)
	if pos.x > self.x and pos.x < self.width + self.x
		and pos.y > self.y and pos.y < self.height + self.y
	then
		return true
	end
end

function chillButton:update()
	self.x = love.graphics.getWidth() - self.width - 100
	self.y = love.graphics.getHeight() - self.height
end

buttons.chill = chillButton

return buttons

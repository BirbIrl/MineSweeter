local sounds = {
	boom = love.audio.newSource("data/audio/boom.wav", "static"),
	flag = love.audio.newSource("data/audio/flag.wav", "static"),
	reveal = love.audio.newSource("data/audio/reveal.wav", "static"),
	gameEnd = love.audio.newSource("data/audio/gameEnd.wav", "static"),
	fail = love.audio.newSource("data/audio/fail.wav", "static")
}
return sounds

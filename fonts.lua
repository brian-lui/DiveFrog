local love = _G.love

local fonts = {
	round_start = love.graphics.newFont('/fonts/Comic.otf', 60),
	round_start_flavor = love.graphics.newFont('/fonts/Comic.otf', 20),
	round_end = love.graphics.newFont('/fonts/ComicItalic.otf', 42),
	char_info = love.graphics.newFont('/fonts/CharSelect.ttf', 21),
	char_selector = love.graphics.newFont('/fonts/GoodDog.otf', 18),
	timer = love.graphics.newFont('/fonts/Comic.otf', 40),
	game_over = love.graphics.newFont('/fonts/ComicItalic.otf', 24),
	game_over_help = love.graphics.newFont('/fonts/ComicItalic.otf', 16),
	settings = love.graphics.newFont('/fonts/GoodDog.otf', 30),
	settings_options_big = love.graphics.newFont('/fonts/GoodDog.otf', 60),
	settings_options_small = love.graphics.newFont('/fonts/GoodDog.otf', 45),
	title = love.graphics.newFont('/fonts/GoodDog.otf', 30),
}

return fonts

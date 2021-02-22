local love = _G.love

local colors = require 'colors'
local fonts = require 'fonts'
local images = require 'images'
local music = require 'music'
local json = require 'dkjson'
local sounds = require 'sounds'

local settings = {}

settings.popup_window = ""

settings.data = {
	Rounds = {{1, 1}, {3, 3}, {5, 5}, {7, 7}, {9, 9}},
	Timer = {{10, 10}, {15, 15}, {20, 20}, {99, 99}},
	Speed = {{"Normal", 1.5}, {"Fast", 1.8}, {"Faster", 2.2}, {"Too Fast", 2.7}},
	Music = {{"Mute", 0}, {"50%", 0.5}, {"70%", 0.7}, {"Max", 1}},
	Sound = {{"Mute", 0}, {"50%", 0.5}, {"70%", 0.7}, {"Max", 1}},
}

-- load settings.options
settings.options = {Rounds = 3, Timer = 2, Speed = 1, Music = 3, Sound = 3}
if love.filesystem.getInfo("settings.txt") then
	local settings_string = love.filesystem.read("settings.txt")
	settings.options = json.decode(settings_string)
else
	love.filesystem.write("settings.txt", json.encode(settings.options))
end

-- load controls
settings.buttons = {p1jump = 'a', p1attack = 's', p2jump = 'l', p2attack = ';', start = 'return'}
if love.filesystem.getInfo("controls.txt") then
	local controls_string = love.filesystem.read("controls.txt")
	settings.buttons = json.decode(controls_string)
else
	love.filesystem.write("controls.txt", json.encode(settings.buttons))
end

settings.choices = {
	menu = {
		"Number of Rounds",
		"Timer",
		"Speed",
		"Music Volume",
		"Sound Volume",
		"Controls",
		"Back to Title",
	},
	action = {
		function() settings.popup_window = "Rounds" end,
		function() settings.popup_window = "Timer" end,
		function() settings.popup_window = "Speed" end,
		function() settings.popup_window = "Music" end,
		function() settings.popup_window = "Sound" end,
		function() settings.popup_window = "Controls" end,
		function()
			Params = {
				Rounds = settings.data.Rounds[settings.options.Rounds][2],
				Timer = settings.data.Timer[settings.options.Timer][2],
				Speed = settings.data.Speed[settings.options.Speed][2],
				Music = settings.data.Music[settings.options.Music][2],
				Sound = settings.data.Sound[settings.options.Sound][2],
			}

			game.best_to_x = Params.Rounds
			init_round_timer = Params.Timer * 60
			game.speed = Params.Speed
			music.currentBGM:setVolume(0.9 * Params.Music)

			love.filesystem.write("settings.txt", json.encode(settings.options))
			love.filesystem.write("controls.txt", json.encode(settings.buttons))

			game.current_screen = 'title'
		end,
	},
	option = 1
}

settings.controls = {
	key = {{"p1jump"}, {"p1attack"}, {"p2jump"}, {"p2attack"}, {"start"}, "Back"},
	assigning = false,
	option = 1
}

Params = {
	Rounds = settings.data.Rounds[settings.options.Rounds][2],
	Timer = settings.data.Timer[settings.options.Timer][2],
	Speed = settings.data.Speed[settings.options.Speed][2],
	Music = settings.data.Music[settings.options.Music][2],
	Sound = settings.data.Sound[settings.options.Sound][2],
}


function settings.receive_keypress(key)
	if settings.popup_window == "" then
		if key == settings.buttons.p1attack or key == "right" or key == "return" then
			sounds.playCharSelectSFX()
			settings.choices.action[settings.choices.option]()
		elseif key == settings.buttons.p1jump or key == "down" then
			sounds.playCharSelectSFX()
			settings.choices.option = settings.choices.option % #settings.choices.menu + 1
		elseif key == "up" then
			sounds.playCharSelectSFX()
			settings.choices.option = (settings.choices.option - 2) % #settings.choices.menu + 1
		end

	elseif settings.popup_window == "Controls" then
		if settings.controls.assigning then
			if not (key == "left" or key == "right" or key == "up" or key == "down") then
				for _, v in pairs(settings.controls.key[settings.controls.option]) do
					settings.buttons[v] = key
				end
				settings.controls.assigning = false
			end
		else
			if key == settings.buttons.p1attack or key == "right" or key == "return" then
				sounds.playCharSelectSFX()

				if settings.controls.key[settings.controls.option] == "Back" then
					settings.popup_window = ""
				else
					settings.controls.assigning = true
				end
			elseif key == settings.buttons.p1jump or key == "down" then
				sounds.playCharSelectSFX()
				settings.controls.option = settings.controls.option % #settings.controls.key + 1
			elseif key == "up" then
				sounds.playCharSelectSFX()
				settings.controls.option = (settings.controls.option - 2) % #settings.controls.key + 1
			elseif key == "left" then
				settings.popup_window = ""
			end
		end
	else
		for k in pairs(settings.data) do
			if settings.popup_window == k then
				if key == settings.buttons.p1attack or key == "return" then
					sounds.playCharSelectSFX()
					settings.popup_window = ""
				elseif key == settings.buttons.p1jump or key == "down" then
					sounds.playCharSelectSFX()
					settings.options[k] = settings.options[k] % #settings.data[k] + 1
				elseif key == "up" then
					sounds.playCharSelectSFX()
					settings.options[k] = (settings.options[k] - 2) % #settings.data[k] + 1
				end
			end
		end
	end
end

function settings.open()
	settings.choices.option = 1
	game.current_screen = "settings"
end

return settings
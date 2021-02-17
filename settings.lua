local love = _G.love

local colors = require 'colors'
local fonts = require 'fonts'
local images = require 'images'
local music = require 'music'
local json = require 'dkjson'
local sounds = require 'sounds'

local settings = {}

local popup_window = ""

local backgrounds = {
	rounds = love.graphics.newQuad(
		0,
		0,
		60,
		60,
		love.graphics.getWidth(images.settings.texture),
		love.graphics.getHeight(images.settings.texture)
	),
	timer = love.graphics.newQuad(
		0,
		0,
		70,
		60,
		love.graphics.getWidth(images.settings.texture),
		love.graphics.getHeight(images.settings.texture)
	),
	speed = love.graphics.newQuad(
		0,
		0,
		130,
		60,
		love.graphics.getWidth(images.settings.texture),
		love.graphics.getHeight(images.settings.texture)
	),
	music = love.graphics.newQuad(
		0,
		0,
		90,
		60,
		love.graphics.getWidth(images.settings.texture),
		love.graphics.getHeight(images.settings.texture)
	),
	sound = love.graphics.newQuad(
		0,
		0,
		90,
		60,
		love.graphics.getWidth(images.settings.texture),
		love.graphics.getHeight(images.settings.texture)
	),
	controls = love.graphics.newQuad(
		0,
		0,
		210,
		225,
		love.graphics.getWidth(images.settings.texture),
		love.graphics.getHeight(images.settings.texture)
	),
}

local data = {
	Rounds = {{1, 1}, {3, 3}, {5, 5}, {7, 7}, {9, 9}},
	Timer = {{10, 10}, {15, 15}, {20, 20}, {99, 99}},
	Speed = {{"Normal", 1.5}, {"Fast", 1.8}, {"Faster", 2.2}, {"Too Fast", 2.7}},
	Music = {{"Mute", 0}, {"50%", 0.5}, {"70%", 0.7}, {"Max", 1}},
	Sound = {{"Mute", 0}, {"50%", 0.5}, {"70%", 0.7}, {"Max", 1}},
}

-- load options
local options = {Rounds = 3, Timer = 2, Speed = 1, Music = 3, Sound = 3}
if love.filesystem.getInfo("settings.txt") then
	local settings_string = love.filesystem.read("settings.txt")
	options = json.decode(settings_string)
else
	love.filesystem.write("settings.txt", json.encode(options))
end

-- load controls
buttons = {p1jump = 'a', p1attack = 's', p2jump = 'l', p2attack = ';', start = 'return'}
if love.filesystem.getInfo("controls.txt") then
	local controls_string = love.filesystem.read("controls.txt")
	buttons = json.decode(controls_string)
else
	love.filesystem.write("controls.txt", json.encode(buttons))
end

local settings_choices = {
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
		function() popup_window = "Rounds" end,
		function() popup_window = "Timer" end,
		function() popup_window = "Speed" end,
		function() popup_window = "Music" end,
		function() popup_window = "Sound" end,
		function() popup_window = "Controls" end,
		function()
			Params = {
				Rounds = data.Rounds[options.Rounds][2],
				Timer = data.Timer[options.Timer][2],
				Speed = data.Speed[options.Speed][2],
				Music = data.Music[options.Music][2],
				Sound = data.Sound[options.Sound][2],
			}

			game.best_to_x = Params.Rounds
			init_round_timer = Params.Timer * 60
			game.speed = Params.Speed
			music.currentBGM:setVolume(0.9 * Params.Music)

			love.filesystem.write("settings.txt", json.encode(options))
			love.filesystem.write("controls.txt", json.encode(buttons))

			game.current_screen = 'title'
		end,
	},
	option = 1
}

Params = {
	Rounds = data.Rounds[options.Rounds][2],
	Timer = data.Timer[options.Timer][2],
	Speed = data.Speed[options.Speed][2],
	Music = data.Music[options.Music][2],
	Sound = data.Sound[options.Sound][2]
	}


function settings.receive_keypress(key)
	if popup_window == "" then
		if key == buttons.p1attack or key == "right" or key == "return" then
			sounds.playCharSelectSFX()
			settings_choices.action[settings_choices.option]()
		elseif key == buttons.p1jump or key == "down" then
			sounds.playCharSelectSFX()
			settings_choices.option = settings_choices.option % #settings_choices.menu + 1
		elseif key == "up" then
			sounds.playCharSelectSFX()
			settings_choices.option = (settings_choices.option - 2) % #settings_choices.menu + 1
		end

	elseif popup_window == "Controls" then
		if controls_choices.assigning then
			if not (key == "left" or key == "right" or key == "up" or key == "down") then
				for _, v in pairs(controls_choices.key[controls_choices.option]) do
					buttons[v] = key
				end
				controls_choices.assigning = false
			end
		else
			if key == buttons.p1attack or key == "right" or key == "return" then
				sounds.playCharSelectSFX()

				if controls_choices.key[controls_choices.option] == "Back" then
					popup_window = ""
				else
					controls_choices.assigning = true
				end
			elseif key == buttons.p1jump or key == "down" then
				sounds.playCharSelectSFX()
				controls_choices.option = controls_choices.option % #controls_choices.key + 1
			elseif key == "up" then
				sounds.playCharSelectSFX()
				controls_choices.option = (controls_choices.option - 2) % #controls_choices.key + 1
			elseif key == "left" then
				popup_window = ""
			end
		end
	else
		for k, v in pairs(data) do
			if popup_window == k then
				if key == buttons.p1attack or key == "return" then
					sounds.playCharSelectSFX()
					popup_window = ""
				elseif key == buttons.p1jump or key == "down" then
					sounds.playCharSelectSFX()
					options[k] = options[k] % #data[k] + 1
				elseif key == "up" then
					sounds.playCharSelectSFX()
					options[k] = (options[k] - 2) % #data[k] + 1
				end
			end
		end
	end
end



controls_choices = {
	key = {{"p1jump"}, {"p1attack"}, {"p2jump"}, {"p2attack"}, {"start"}, "Back"},
	assigning = false,
	option = 1
}

function settings.open()
	settings_choices.option = 1
	game.current_screen = "settings"
end

DRAW_ITEM = {
	BACKGROUND = {images.settings.background, 0, 0, 0},
	LOGO = {images.settings.logo, 232, 60},
	TEXTURE = {images.settings.texture, 280, 260}
}

function drawSettingsMain()
	love.graphics.push("all")
	love.graphics.draw(unpack(DRAW_ITEM.BACKGROUND))
	love.graphics.draw(unpack(DRAW_ITEM.LOGO))

	love.graphics.setColor(colors.OFF_WHITE)
	love.graphics.draw(unpack(DRAW_ITEM.TEXTURE))

	love.graphics.setLineWidth(3)
	if popup_window == "" then
		love.graphics.setColor(colors.ORANGE)
		if frame % 60 > 50 then
		love.graphics.setColor(colors.WHITE)
		end
	else
		love.graphics.setColor(colors.DULL_ORANGE)
	end
	love.graphics.rectangle("line", 290, 238 + 35 * settings_choices.option, 200, 34)

	if popup_window == "" then
		love.graphics.setColor(colors.ORANGE)
	else
		love.graphics.setColor(colors.DULL_ORANGE)
	end
	love.graphics.setFont(fonts.settings)
		for i = 1, #settings_choices.menu do
		love.graphics.print(settings_choices.menu[i], 300, 240 + (35 * i))
		end

	love.graphics.pop()
end


function drawSettingsPopup()
	if popup_window == "Rounds" then
	local toprint = data.Rounds[options.Rounds][1]

	love.graphics.push("all")
		love.graphics.setColor(colors.OFF_WHITE)
		love.graphics.draw(images.settings.texture, backgrounds.rounds, 510, 260)

		love.graphics.setColor(colors.ORANGE)
		love.graphics.setFont(fonts.settings_options_big)
		love.graphics.printf(toprint, 508, 252, 60, "center")
	love.graphics.pop()

	elseif popup_window == "Timer" then
	local toprint = data.Timer[options.Timer][1]
	love.graphics.push("all")
		love.graphics.setColor(colors.OFF_WHITE)
		love.graphics.draw(images.settings.texture, backgrounds.timer, 510, 295)

		love.graphics.setColor(colors.ORANGE)
		love .graphics.setFont(fonts.settings_options_big)
		love.graphics.printf(toprint, 510, 290, 70, "center")
	love.graphics.pop()

	elseif popup_window == "Speed" then
	local toprint = data.Speed[options.Speed][1]
	love.graphics.push("all")
		love.graphics.setColor(colors.OFF_WHITE)
		love.graphics.draw(images.settings.texture, backgrounds.speed, 510, 330)

		love.graphics.setColor(colors.ORANGE)
		love.graphics.setFont(fonts.settings_options_small)
		love.graphics.printf(toprint, 510, 333, 130, "center")
	love.graphics.pop()

	elseif popup_window == "Music" then
	local toprint = data.Music[options.Music][1]
	love.graphics.push("all")
		love.graphics.setColor(colors.OFF_WHITE)
		love.graphics.draw(images.settings.texture, backgrounds.music, 510, 365)

		love.graphics.setColor(colors.ORANGE)
		love.graphics.setFont(fonts.settings_options_small)
		love.graphics.printf(toprint, 510, 368, 90, "center")
	love.graphics.pop()

	elseif popup_window == "Sound" then
	local toprint = data.Sound[options.Sound][1]
	love.graphics.push("all")
		love.graphics.setColor(colors.OFF_WHITE)
		love.graphics.draw(images.settings.texture, backgrounds.sound, 510, 400)

		love.graphics.setColor(colors.ORANGE)
		love.graphics.setFont(fonts.settings_options_small)
		love.graphics.printf(toprint, 510, 403, 90, "center")
	love.graphics.pop()
	elseif popup_window == "Controls" then
	love.graphics.push("all")
		love.graphics.setColor(colors.OFF_WHITE)
		love.graphics.draw(images.settings.texture, backgrounds.controls, 510, 245)
		
		local toprint = {
		{"P1 Jump", buttons.p1jump},
		{"P1 Attack", buttons.p1attack},
		{"P2 Jump", buttons.p2jump},
		{"P2 Attack", buttons.p2attack},
		{"Start", buttons.start},
		{"Back", ""}
		}
	
		if controls_choices.assigning then
		toprint[controls_choices.option][2] = "[      ]"
		end
		
		love.graphics.setFont(fonts.settings)

		for i = 1, #toprint do
		love.graphics.setColor(colors.ORANGE)
		love.graphics.print(toprint[i][1], 525, 220 + 35 * i)

		love.graphics.setColor(colors.GREEN)
		love.graphics.print(toprint[i][2], 640, 220 + 35 * i)
		end

		love.graphics.setLineWidth(3)
		love.graphics.setColor(colors.ORANGE)
		love.graphics.rectangle("line", 520, 220 + 35 * controls_choices.option, 190, 34)
		
	love.graphics.pop()
	end
end

return settings
local love = _G.love

local images = require 'images'
local json = require 'dkjson'

settingsFont = love.graphics.newFont('/fonts/GoodDog.otf', 30)
settingsOptionsFontBig = love.graphics.newFont('/fonts/GoodDog.otf', 60)
settingsOptionsFontSmall = love.graphics.newFont('/fonts/GoodDog.otf', 45)
settings_popup_window = ""

settings_rounds_background = love.graphics.newQuad(0, 0, 60, 60,
  love.graphics.getWidth(images.settings.texture), love.graphics.getHeight(images.settings.texture))
settings_timer_background = love.graphics.newQuad(0, 0, 70, 60,
  love.graphics.getWidth(images.settings.texture), love.graphics.getHeight(images.settings.texture))
settings_speed_background = love.graphics.newQuad(0, 0, 130, 60,
  love.graphics.getWidth(images.settings.texture), love.graphics.getHeight(images.settings.texture))
settings_music_background = love.graphics.newQuad(0, 0, 90, 60,
  love.graphics.getWidth(images.settings.texture), love.graphics.getHeight(images.settings.texture))
settings_sound_background = love.graphics.newQuad(0, 0, 90, 60,
  love.graphics.getWidth(images.settings.texture), love.graphics.getHeight(images.settings.texture))
settings_controls_background = love.graphics.newQuad(0, 0, 210, 225,
  love.graphics.getWidth(images.settings.texture), love.graphics.getHeight(images.settings.texture))

settings_table = {
  Rounds = {{1, 1}, {3, 3}, {5, 5}, {7, 7}, {9, 9}},
  Timer = {{10, 10}, {15, 15}, {20, 20}, {99, 99}},
  Speed = {{"Normal", 1.5}, {"Fast", 1.8}, {"Faster", 2.2}, {"Too Fast", 2.7}},
  Music = {{"Mute", 0}, {"50%", 0.5}, {"70%", 0.7}, {"Max", 1}},
  Sound = {{"Mute", 0}, {"50%", 0.5}, {"70%", 0.7}, {"Max", 1}}
  }  

-- load settings
settings_options = {Rounds = 3, Timer = 2, Speed = 1, Music = 3, Sound = 3}

if love.filesystem.getInfo("settings.txt") then
  local settings_string = love.filesystem.read("settings.txt")
  settings_options = json.decode(settings_string)
else
  love.filesystem.write("settings.txt", json.encode(settings_options))
end

-- load controls
buttons = {p1jump = 'a', p1attack = 's', p2jump = 'l', p2attack = ';', start = 'return'}
if love.filesystem.getInfo("controls.txt") then
  local controls_string = love.filesystem.read("controls.txt")
  buttons = json.decode(controls_string)
else
  love.filesystem.write("controls.txt", json.encode(buttons))
end

Params = {
  Rounds = settings_table.Rounds[settings_options.Rounds][2],
  Timer = settings_table.Timer[settings_options.Timer][2],
  Speed = settings_table.Speed[settings_options.Speed][2],
  Music = settings_table.Music[settings_options.Music][2],
  Sound = settings_table.Sound[settings_options.Sound][2]
  }

function setupReceiveKeypress(key)
  if settings_popup_window == "" then
	if key == buttons.p1attack or key == "right" or key == "return" then
	  sound.playCharSelectSFX()
	  settings_choices.action[settings_choices.option]()

	elseif key == buttons.p1jump or key == "down" then
	  sound.playCharSelectSFX()
	  settings_choices.option = settings_choices.option % #settings_choices.menu + 1

	elseif key == "up" then
	  sound.playCharSelectSFX()
	  settings_choices.option = (settings_choices.option - 2) % #settings_choices.menu + 1
	end

  elseif settings_popup_window == "Controls" then
	if controls_choices.assigning then
	  if not (key == "left" or key == "right" or key == "up" or key == "down") then
		for _, v in pairs(controls_choices.key[controls_choices.option]) do
		  buttons[v] = key
		end
		controls_choices.assigning = false
	  end

	else  
	  if key == buttons.p1attack or key == "right" or key == "return" then
		sound.playCharSelectSFX()

		if controls_choices.key[controls_choices.option] == "Back" then
		  settings_popup_window = ""
		else
		  controls_choices.assigning = true
		end

	  elseif key == buttons.p1jump or key == "down" then
		sound.playCharSelectSFX()
		controls_choices.option = controls_choices.option % #controls_choices.key + 1

	  elseif key == "up" then
		sound.playCharSelectSFX()
		controls_choices.option = (controls_choices.option - 2) % #controls_choices.key + 1        

	  elseif key == "left" then
		settings_popup_window = ""

	  end
	end

  else
	for k, v in pairs(settings_table) do
	  if settings_popup_window == k then
		if key == buttons.p1attack or key == "return" then
		  sound.playCharSelectSFX()
		  settings_popup_window = ""

		elseif key == buttons.p1jump or key == "down" then
		  sound.playCharSelectSFX()
		  settings_options[k] = settings_options[k] % #settings_table[k] + 1 

		elseif key == "up" then
		  sound.playCharSelectSFX()
		  settings_options[k] = (settings_options[k] - 2) % #settings_table[k] + 1 
		end
	  end
	end
  end
end

function setupRounds()
  settings_popup_window = "Rounds"
end

function setupTimer()
  settings_popup_window = "Timer"
end

function setupSpeed()
  settings_popup_window = "Speed"
end

function setupMusic()
  settings_popup_window = "Music"
end

function setupSound()
  settings_popup_window = "Sound"
end

function setupControls()
  settings_popup_window = "Controls"
end

function backToTitle()
  Params = {
	Rounds = settings_table.Rounds[settings_options.Rounds][2],
	Timer = settings_table.Timer[settings_options.Timer][2],
	Speed = settings_table.Speed[settings_options.Speed][2],
	Music = settings_table.Music[settings_options.Music][2],
	Sound = settings_table.Sound[settings_options.Sound][2]
  }
  
  game.best_to_x = Params.Rounds
  init_round_timer = Params.Timer * 60
  game.speed = Params.Speed
  currentBGM:setVolume(0.9 * Params.Music)

  love.filesystem.write("settings.txt", json.encode(settings_options))  
  love.filesystem.write("controls.txt", json.encode(buttons))  

  settings_choices.option = 1
  game.current_screen = 'title'
end

settings_choices = {
  menu = {
	"Number of Rounds",
	"Timer",
	"Speed",
	"Music Volume",
	"Sound Volume",
	"Controls",
	"Back to Title"},
  action = {setupRounds, setupTimer, setupSpeed, setupMusic, setupSound, setupControls, backToTitle},
  option = 1
}

controls_choices = {
  key = {{"p1jump"}, {"p1attack"}, {"p2jump"}, {"p2attack"}, {"start"}, "Back"},
  assigning = false,
  option = 1
}

function settingsMenu()
  title_choices.option = 1
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

	love.graphics.setColor(COLOR.OFF_WHITE)
	love.graphics.draw(unpack(DRAW_ITEM.TEXTURE))

	love.graphics.setLineWidth(3)
	if settings_popup_window == "" then
	  love.graphics.setColor(COLOR.ORANGE)
	  if frame % 60 > 50 then
		love.graphics.setColor(COLOR.WHITE)
	  end
	else
	  love.graphics.setColor(COLOR.DULL_ORANGE)
	end
	love.graphics.rectangle("line", 290, 238 + 35 * settings_choices.option, 200, 34)

	if settings_popup_window == "" then
	  love.graphics.setColor(COLOR.ORANGE)
	else
	  love.graphics.setColor(COLOR.DULL_ORANGE)
	end
	love.graphics.setFont(settingsFont)
	  for i = 1, #settings_choices.menu do
		love.graphics.print(settings_choices.menu[i], 300, 240 + (35 * i))
	  end
	  
  love.graphics.pop()
end


function drawSettingsPopup()
  if settings_popup_window == "Rounds" then
	local toprint = settings_table.Rounds[settings_options.Rounds][1]

	love.graphics.push("all")
	  love.graphics.setColor(COLOR.OFF_WHITE)
	  love.graphics.draw(images.settings.texture, settings_rounds_background, 510, 260)

	  love.graphics.setColor(COLOR.ORANGE)
	  love.graphics.setFont(settingsOptionsFontBig)
	  love.graphics.printf(toprint, 508, 252, 60, "center")
	love.graphics.pop()

  elseif settings_popup_window == "Timer" then
	local toprint = settings_table.Timer[settings_options.Timer][1]
	love.graphics.push("all")
	  love.graphics.setColor(COLOR.OFF_WHITE)
	  love.graphics.draw(images.settings.texture, settings_timer_background, 510, 295)

	  love.graphics.setColor(COLOR.ORANGE)
	  love .graphics.setFont(settingsOptionsFontBig)
	  love.graphics.printf(toprint, 510, 290, 70, "center")
	love.graphics.pop()

  elseif settings_popup_window == "Speed" then
	local toprint = settings_table.Speed[settings_options.Speed][1]
	love.graphics.push("all")
	  love.graphics.setColor(COLOR.OFF_WHITE)
	  love.graphics.draw(images.settings.texture, settings_speed_background, 510, 330)

	  love.graphics.setColor(COLOR.ORANGE)
	  love.graphics.setFont(settingsOptionsFontSmall)
	  love.graphics.printf(toprint, 510, 333, 130, "center")
	love.graphics.pop()

  elseif settings_popup_window == "Music" then
	local toprint = settings_table.Music[settings_options.Music][1]
	love.graphics.push("all")
	  love.graphics.setColor(COLOR.OFF_WHITE)
	  love.graphics.draw(images.settings.texture, settings_music_background, 510, 365)

	  love.graphics.setColor(COLOR.ORANGE)
	  love.graphics.setFont(settingsOptionsFontSmall)
	  love.graphics.printf(toprint, 510, 368, 90, "center")
	love.graphics.pop()

  elseif settings_popup_window == "Sound" then
	local toprint = settings_table.Sound[settings_options.Sound][1]
	love.graphics.push("all")
	  love.graphics.setColor(COLOR.OFF_WHITE)
	  love.graphics.draw(images.settings.texture, settings_sound_background, 510, 400)

	  love.graphics.setColor(COLOR.ORANGE)
	  love.graphics.setFont(settingsOptionsFontSmall)
	  love.graphics.printf(toprint, 510, 403, 90, "center")
	love.graphics.pop()
  elseif settings_popup_window == "Controls" then
	love.graphics.push("all")
	  love.graphics.setColor(COLOR.OFF_WHITE)
	  love.graphics.draw(images.settings.texture, settings_controls_background, 510, 245)
	  
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
		
	  love.graphics.setFont(settingsFont)

	  for i = 1, #toprint do
		love.graphics.setColor(COLOR.ORANGE)
		love.graphics.print(toprint[i][1], 525, 220 + 35 * i)

		love.graphics.setColor(COLOR.GREEN)
		love.graphics.print(toprint[i][2], 640, 220 + 35 * i)
	  end

	  love.graphics.setLineWidth(3)
	  love.graphics.setColor(COLOR.ORANGE)
	  love.graphics.rectangle("line", 520, 220 + 35 * controls_choices.option, 190, 34)
	  
	love.graphics.pop()
  end
end

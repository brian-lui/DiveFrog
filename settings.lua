local json = require 'dkjson'

settings_background = love.graphics.newImage('images/Settings/SettingsBackground.jpg')
settings_logo = love.graphics.newImage('images/Settings/SettingsLogo.png')
settings_texture = love.graphics.newImage('images/Settings/SettingsMenuBk.jpg')
settingsFont = love.graphics.newFont('/fonts/GoodDog.otf', 30)
settingsOptionsFontBig = love.graphics.newFont('/fonts/GoodDog.otf', 60)
settingsOptionsFontSmall = love.graphics.newFont('/fonts/GoodDog.otf', 45)
settings_popup_window = ""

settings_rounds_background = love.graphics.newQuad(0, 0, 60, 60, 
  love.graphics.getWidth(settings_texture), love.graphics.getHeight(settings_texture))
settings_timer_background = love.graphics.newQuad(0, 0, 70, 60, 
  love.graphics.getWidth(settings_texture), love.graphics.getHeight(settings_texture))
settings_speed_background = love.graphics.newQuad(0, 0, 130, 60, 
  love.graphics.getWidth(settings_texture), love.graphics.getHeight(settings_texture))
settings_music_background = love.graphics.newQuad(0, 0, 90, 60, 
  love.graphics.getWidth(settings_texture), love.graphics.getHeight(settings_texture))
settings_sound_background = love.graphics.newQuad(0, 0, 90, 60, 
  love.graphics.getWidth(settings_texture), love.graphics.getHeight(settings_texture))

settings_table = {
  Rounds = {{1, 1}, {3, 3}, {5, 5}, {7, 7}, {9, 9}},
  Timer = {{10, 10}, {15, 15}, {20, 20}, {99, 99}},
  Speed = {{"Normal", 1.5}, {"Fast", 1.8}, {"Faster", 2.2}, {"Too Fast", 2.7}},
  Music = {{"Mute", 0}, {"50%", 0.5}, {"70%", 0.7}, {"Max", 1}},
  Sound = {{"Mute", 0}, {"50%", 0.5}, {"70%", 0.7}, {"Max", 1}}
  }  

Params = {
  Rounds = settings_table.Rounds[settings_options.Rounds][2],
  Timer = settings_table.Timer[settings_options.Timer][2],
  Speed = settings_table.Speed[settings_options.Speed][2],
  Music = settings_table.Music[settings_options.Music][2],
  Sound = settings_table.Sound[settings_options.Sound][2]
  }

--[[ Make it useable with arrow keys too]]
function setupReceiveKeypress(key)
  if key == buttons.start then
      playSFX(charselected_sfx)
      game.current_screen = "title"
  end
  
  if settings_popup_window == "" then
    if key == buttons.p1attack then
      playSFX(charselected_sfx)
      settings_choices.action[settings_choices.option]()
    
    elseif key == buttons.p1jump then
      playSFX(charselect_sfx)
      settings_choices.option = settings_choices.option % #settings_choices.menu + 1
    end

  elseif settings_popup_window == "Controls" then
    if key == buttons.p1attack then
      playSFX(charselected_sfx)
      --Press P1 Attack changes current key to ____. Then accepts next keypress as input
    elseif key = buttons.p1jump then
      playSFX(charselect_sfx)
      --Press P1 Jump moves the rectangle. Moves the "active button" variable.
    end
  --[[
    Input overwrites "active button" e.g. buttons.p2jump
  when press 'Back', also saves to json file
  ]]

--buttons = {p1jump = 'a', p1attack = 's', p2jump = 'l', p2attack = ';', start = 'return'}
--love.filesystem.write("controls.txt", json.encode(buttons))  

  else
    for k, v in pairs(settings_table) do
      if settings_popup_window == k then
        if key == buttons.p1attack then
          playSFX(charselected_sfx)
          settings_popup_window = ""

        elseif key == buttons.p1jump then
          playSFX(charselect_sfx)
          settings_options[k] = settings_options[k] % #settings_table[k] + 1
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

function settingsMenu()
  title_choices.option = 1
  game.current_screen = "settings" 
end

function drawSettingsMain()
  love.graphics.push("all")
    love.graphics.draw(settings_background, 0, 0, 0)
    love.graphics.draw(settings_logo, 232, 60)

    love.graphics.setColor(255, 255, 255, 160)
      love.graphics.draw(settings_texture, 280, 260)

    love.graphics.setLineWidth(3)
    if settings_popup_window == "" then
      love.graphics.setColor(255, 215, 0, 255)
    else
      love.graphics.setColor(195, 160, 0, 210)
    end
      love.graphics.rectangle("line", 290, 238 + 35 * settings_choices.option, 200, 34)

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
      love.graphics.setColor(255, 255, 255, 160)
        love.graphics.draw(settings_texture, settings_rounds_background, 510, 260)

      love.graphics.setColor(255, 215, 0, 255)
      love.graphics.setFont(settingsOptionsFontBig)
        love.graphics.printf(toprint, 508, 252, 60, "center")
    love.graphics.pop()

  elseif settings_popup_window == "Timer" then
    local toprint = settings_table.Timer[settings_options.Timer][1]
    love.graphics.push("all")
      love.graphics.setColor(255, 255, 255, 160)
        love.graphics.draw(settings_texture, settings_timer_background, 510, 295)

      love.graphics.setColor(255, 215, 0, 255)
      love .graphics.setFont(settingsOptionsFontBig)
        love.graphics.printf(toprint, 510, 290, 70, "center")
    love.graphics.pop()

  elseif settings_popup_window == "Speed" then
    local toprint = settings_table.Speed[settings_options.Speed][1]
    love.graphics.push("all")
      love.graphics.setColor(255, 255, 255, 160)
        love.graphics.draw(settings_texture, settings_speed_background, 510, 330)

      love.graphics.setColor(255, 215, 0, 255)
      love.graphics.setFont(settingsOptionsFontSmall)
        love.graphics.printf(toprint, 510, 333, 130, "center")
    love.graphics.pop()

  elseif settings_popup_window == "Music" then
    local toprint = settings_table.Music[settings_options.Music][1]
    love.graphics.push("all")
      love.graphics.setColor(255, 255, 255, 160)
        love.graphics.draw(settings_texture, settings_music_background, 510, 365)

      love.graphics.setColor(255, 215, 0, 255)
      love.graphics.setFont(settingsOptionsFontSmall)
        love.graphics.printf(toprint, 510, 368, 90, "center")
    love.graphics.pop()

  elseif settings_popup_window == "Sound" then
    local toprint = settings_table.Sound[settings_options.Sound][1]
    love.graphics.push("all")
      love.graphics.setColor(255, 255, 255, 160)
        love.graphics.draw(settings_texture, settings_sound_background, 510, 400)

      love.graphics.setColor(255, 215, 0, 255)
      love.graphics.setFont(settingsOptionsFontSmall)
        love.graphics.printf(toprint, 510, 403, 90, "center")
    love.graphics.pop()
  elseif settings_popup_window == "Controls" then
    
  --[[ draw background
   love.graphics.setColor(255, 255, 255, 160)
      love.graphics.draw(settings_texture, x, y)
    ]]
  
  --[[Show table:
    P1 Jump     buttons.p1jump
    P1 Attack   buttons.p1attack
    P2 Jump     buttons.p2jump
    P2 Attack   buttons.p2attack
    Start       buttons.start
    Back
    ]]

    --[[ Draw rectangle:
    love.graphics.setLineWidth(3)
    love.graphics.setColor(255, 215, 0, 255)
    love.graphics.rectangle("line", 290, 238 + 35 * settings_choices.option, 200, 34)
    ]]
  end
end

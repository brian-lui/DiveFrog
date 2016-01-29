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
settings_music_background = love.graphics.newQuad(0, 0, 60, 60, 
  love.graphics.getWidth(settings_texture), love.graphics.getHeight(settings_texture))
settings_sound_background = love.graphics.newQuad(0, 0, 60, 60, 
  love.graphics.getWidth(settings_texture), love.graphics.getHeight(settings_texture))

settings_table = {
      Rounds = {1, 3, 5, 7, 9},
      Timer = {10, 15, 20, 99},
      Speed = {"Normal", "Fast", "Faster", "Too Fast"},
      Music = {0, 5, 7, 10},
      Sound = {0, 5, 7, 10}
    }  
settings_options = {Rounds = 3, Timer = 3, Speed = 1, Music = 3, Sound = 3}


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

end

function backToTitle()
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
  --[[
  show current P1 / P2 keys at top (load from controls.txt)
  Display: "Select with [P1 attack] key"
  Options: Reassign Keys. Back to main menu
  Reassign keys: popup with:
    Press P1 Attack Key
    Press P1 Jump Key -- check if same as prev keys
    Press P2 Attack Key -- "
    Press P2 Jump Key -- "
    Write to controls.txt, refresh display at top
    Move cursor to 'Back to main menu'
  ]]
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

--[[

Use printf and "center" later

]]
function drawSettingsPopup()
  if settings_popup_window == "Rounds" then
    local toprint = settings_table.Rounds[settings_options.Rounds]

    love.graphics.push("all")
      love.graphics.setColor(255, 255, 255, 160)
        love.graphics.draw(settings_texture, settings_rounds_background, 510, 260)

      love.graphics.setColor(255, 215, 0, 255)
      love.graphics.setFont(settingsOptionsFontBig)
        love.graphics.print(toprint, 528, 252)
    love.graphics.pop()

  elseif settings_popup_window == "Timer" then
    local toprint = settings_table.Timer[settings_options.Timer]
    love.graphics.push("all")
      love.graphics.setColor(255, 255, 255, 160)
        love.graphics.draw(settings_texture, settings_timer_background, 510, 295)

      love.graphics.setColor(255, 215, 0, 255)
      love.graphics.setFont(settingsOptionsFontBig)
        love.graphics.print(toprint, 520, 290)
    love.graphics.pop()

  elseif settings_popup_window == "Speed" then
    local toprint = settings_table.Speed[settings_options.Speed]
    love.graphics.push("all")
      love.graphics.setColor(255, 255, 255, 160)
        love.graphics.draw(settings_texture, settings_speed_background, 510, 330)

      love.graphics.setColor(255, 215, 0, 255)
      love.graphics.setFont(settingsOptionsFontSmall)
        love.graphics.print(toprint, 520, 333)
    love.graphics.pop()

  elseif settings_popup_window == "Music" then
    local toprint = settings_table.Music[settings_options.Music]
    love.graphics.push("all")
      love.graphics.setColor(255, 255, 255, 160)
        love.graphics.draw(settings_texture, settings_music_background, 510, 365)

      love.graphics.setColor(255, 215, 0, 255)
      love.graphics.setFont(settingsOptionsFontBig)
        love.graphics.print(toprint, 520, 368)
    love.graphics.pop()

  elseif settings_popup_window == "Sound" then
    local toprint = settings_table.Sound[settings_options.Sound]
    love.graphics.push("all")
      love.graphics.setColor(255, 255, 255, 160)
        love.graphics.draw(settings_texture, settings_sound_background, 510, 400)

      love.graphics.setColor(255, 215, 0, 255)
      love.graphics.setFont(settingsOptionsFontBig)
        love.graphics.print(toprint, 520, 403)
    love.graphics.pop()

  end
end

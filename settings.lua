settings_background = love.graphics.newImage('images/Settings/SettingsBackground.jpg')
settings_logo = love.graphics.newImage('images/Settings/SettingsLogo.png')
settings_menu_background = love.graphics.newImage('images/Settings/SettingsMenuBk.jpg')
settingsFont = love.graphics.newFont('/fonts/GoodDog.otf', 30)
settingsOptionsFont = love.graphics.newFont('/fonts/GoodDog.otf', 60)
settings_popup_window = ""

function setupReceiveKeypress()
end

function setupRounds()
  settings_popup_window = "Rounds"
end

function setupTimer()
end

function setupSpeed()
end

function setupMusic()
end

function setupSound()
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
      love.graphics.draw(settings_menu_background, 280, 260)

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
    love.graphics.push("all")
      love.graphics.setColor(255, 215, 0, 255)
      love.graphics.setFont(settingsOptionsFont)
        love.graphics.print("5", 520, 252)
    love.graphics.pop()
  end
end

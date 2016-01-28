settings_background = love.graphics.newImage('images/Settings/SettingsBackground.jpg')
settings_logo = love.graphics.newImage('images/Settings/SettingsLogo.png')
settingsFont = love.graphics.newFont('/fonts/GoodDog.otf', 30)

function setupRounds()
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
  title.option = 1
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

function drawSettingsScreen()
  love.graphics.push("all")
    love.graphics.draw(settings_background, 0, 0, 0)
    love.graphics.draw(settings_logo, 232, 60)
   
    love.graphics.setLineWidth(3)
    love.graphics.setColor(255, 215, 0, 255)
      love.graphics.rectangle("line", 300, 238 + 35 * settings_choices.option, 200, 34)
    love.graphics.setFont(settingsFont)
      for i = 1, #settings_choices.menu do
        love.graphics.printf(settings_choices.menu[i], 315, 240 + (35 * i), 200)
      end
  love.graphics.pop()
end



require 'settings'

title_screen = love.graphics.newImage('images/Title/TitleBackground.jpg')
title_select_background = love.graphics.newImage('images/Title/TitleSelect.png')
title_logo = love.graphics.newImage('images/Title/TitleLogo.png')
title_controls_background = love.graphics.newImage('images/Title/TitleControlsBk.png')

titleFont = love.graphics.newFont('/fonts/GoodDog.otf', 30)

default_selections = {title = 1, player1P = 1, AI1P = 1, player12P = 1, player22P = 2}
if love.filesystem.getInfo("choices.txt") then
  local choices_string = love.filesystem.read("choices.txt")
  default_selections = json.decode(choices_string)
else
  love.filesystem.write("choices.txt", json.encode(default_selections))  
end

function select1P()
  game.format = "1P"
  default_selections.title = 1
  love.filesystem.write("choices.txt", json.encode(default_selections))  
  charSelect()
end

function select2P()
  game.format = "2P"
  default_selections.title = 2
  love.filesystem.write("choices.txt", json.encode(default_selections))  
  charSelect()
end

title_choices = {
  menu = {"1 Player", "2 Player", "Settings"},
  action = {select1P, select2P, settingsMenu},
  option = default_selections.title
}

function drawTitle()
  love.graphics.push("all")
    love.graphics.draw(title_screen, 0, 0)
    love.graphics.draw(title_logo, 165, 30)

    love.graphics.setColor(COLOR.OFF_WHITE)
      love.graphics.draw(title_select_background, 100, 385)
      love.graphics.draw(title_controls_background, 400, 380)

    love.graphics.setLineWidth(3)
    love.graphics.setColor(COLOR.ORANGE)
    if frame % 60 > 50 then
      love.graphics.setColor(COLOR.WHITE)
    end
    love.graphics.rectangle("line", 120, 375 + 35 * title_choices.option, 110, 35)

    love.graphics.setColor(COLOR.ORANGE)
    love.graphics.setFont(titleFont)
      local toprint = {
        {"P1 Jump:", buttons.p1jump},
        {"P1 Attack:", buttons.p1attack},
        {"P2 Jump:", buttons.p2jump},
        {"P2 Attack:", buttons.p2attack}
      }

      for i = 1, #toprint do
        love.graphics.push("all")
          love.graphics.print(toprint[i][1], 410, 370 + (30 * i))
          love.graphics.setColor(COLOR.LIGHT_GREEN)
            love.graphics.print(toprint[i][2], 540, 370 + (30 * i))
        love.graphics.pop()
      end
      for i = 1, #title_choices.menu do
        love.graphics.print(title_choices.menu[i], 130, 375  + (35 * i))
      end
    love.graphics.pop()
end

function charSelect()
  setBGM("CharSelect.ogg")
  available_chars = {Konrad, Jean, Sun, Frogson}
  char_text = {
    {"Hyper Jump", "Hyper Kick", "+40%", "Double Jump"},
    {"Wire Sea", "Frog On Land", "+20%, Wire Ocean", "Dandy Frog (Wire Sea OK)\n— Pile Bonquer (Wire Sea OK)"},
    {"Hotflame (Wire Sea OK)", "Riot Kick", "Frog Install", "Small Head"},
    {"Anti-Gravity Frog", "Wow!", "+40%", "Jackson/Bison Stances"}
    }
  if game.format == "1P" then
    p1_char = default_selections.player1P 
    p2_char = default_selections.AI1P
  elseif game.format == "2P" then
    p1_char = default_selections.player12P
    p2_char = default_selections.player22P
  else
    print("Invalid game mode selected.")
  end
  game.current_screen = "charselect"
end

function replays()
  game.current_screen = "replays"
  --[[
  Scan folder for all valid folders
  Output list of all files to a table -- https://love2d.org/wiki/love.filesystem.getDirectoryItems
  Sort table by filename -- table.sort(table)
  Show all files with 'round 0' as the end part
  Each segment is from 'round 0' until (1 - next 'round 0')

  Operations: select files, or back to main menu
  Select file: play file, delete file
    Play file --
      9th char in string is P1, 11th is P2
      Disable user input
      Allow enter key to popup "return to main menu?" (can continue playing in background for simplicity)
      For i = 1 to #-1: decode .txt into keybuffer
    Delete file -- https://love2d.org/wiki/love.filesystem.remove
  ]]
end

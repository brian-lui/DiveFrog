require 'settings'

title_screen = love.graphics.newImage('images/Title/TitleBackground.jpg')
title_select_background = love.graphics.newImage('images/Title/TitleSelect.png')
title_logo = love.graphics.newImage('images/Title/TitleLogo.png')
title_controls_background = love.graphics.newImage('images/Title/TitleControlsBk.png')

titleFont = love.graphics.newFont('/fonts/GoodDog.otf', 30)

function select1P()
  game.format="1P"
  charSelect()
end

function select2P()
  game.format="2P"
  charSelect()
end

title_choices = {
  menu = {"1 Player", "2 Player", "Settings"},
  action = {select1P, select2P, settingsMenu},
  option = 1
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


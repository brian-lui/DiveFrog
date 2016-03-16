require 'lovedebug'
require 'utilities' -- helper functions
require 'camera'
local json = require 'dkjson'
local class = require 'middleclass' -- class support
local stage = require 'stage'  -- total playing field area
local window = require 'window'  -- current view of stage
local music = require 'music'
local character = require 'character'
require 'Konrad'
require 'Jean'
require 'Sun'
require 'Frogson'
require 'AI'
require 'settings'
require 'title'
local particles = require 'particles'

-- load images
local replaysscreen = love.graphics.newImage('images/Replays.jpg')
local charselectscreen = love.graphics.newImage('images/CharSelect.jpg')
local bkmatchend = love.graphics.newImage('images/MatchEndBackground.png')
local hpbar = love.graphics.newImage('images/HPBar.png')
local portraits = love.graphics.newImage('images/Portraits.png')
local greenlight = love.graphics.newImage('images/GreenLight.png')
local portraitsQuad = love.graphics.newQuad(0, 0, 200, 140,portraits:getDimensions())

-- load fonts
local roundStartFont = love.graphics.newFont('/fonts/Comic.otf', 60)
local roundCountdownFont = love.graphics.newFont('/fonts/Comic.otf', 20)
local roundEndFont = love.graphics.newFont('/fonts/ComicItalic.otf', 42)
local charInfoFont = love.graphics.newFont('/fonts/CharSelect.ttf', 21)
local charSelectorFont = love.graphics.newFont('/fonts/GoodDog.otf', 18)
local timerFont = love.graphics.newFont('/fonts/Comic.otf', 40)
local gameoverFont = love.graphics.newFont('/fonts/ComicItalic.otf', 24)
local gameoverHelpFont = love.graphics.newFont('/fonts/ComicItalic.otf', 16)

-- color presets
COLOR = {
  WHITE = {255, 255, 255, 255},
  OFF_WHITE = {255, 255, 255, 160},
  DULL_ORANGE = {195, 160, 0, 210},
  ORANGE = {255, 215, 0, 255},
  DARK_ORANGE = {230, 147, 0, 255},
  LIGHT_GREEN = {128, 255, 128, 255},
  GRAY = {96, 96, 96, 255},
  BLACK = {0, 0, 0, 255},
  SHADOW = {0, 0, 0, 96},
  RED = {220, 0, 0, 255},
  BLUE = {14, 28, 232, 255},
  GREEN = {14, 232, 54, 255},
  PALE_BLUE = {164, 164, 255, 255},
  PALE_GREEN = {164, 255, 164, 255}
}

function drawBackground()
  love.graphics.clear()
  
  local temp_color = COLOR.WHITE

  if game.background_color then
  	temp_color = game.background_color
  elseif game.superfreeze_time > 0 then
  	temp_color = COLOR.GRAY
  elseif p1.frozenFrames > 0 and p2.frozenFrames > 0 and frame > 90 then
    temp_color = COLOR.BLACK
  end

  love.graphics.push("all")
    love.graphics.setColor(temp_color)
    love.graphics.draw(p2.stage_background, 0, 0) 
  love.graphics.pop()
end

function drawMidline() -- when low on time
  if round_timer <= 180 and round_timer > 0 then
    love.graphics.push("all")
      love.graphics.setColor(100 + (180 - round_timer) / 2, 0, 0, 200)
      love.graphics.setLineWidth(12)
      love.graphics.line(stage.center, 0, stage.center, stage.height)

      love.graphics.setLineWidth(1)
      local alpha = (180 - round_timer) / 2 + 90
      local lines = {
        {shift = 2 * round_timer, color = {255, 0, 0, alpha}},
        {shift = 4 * round_timer, color = {220, 220, 0, alpha}},
        {shift = 6 * round_timer, color = {220, 220, 220, alpha}},
        {shift = 12 * round_timer, color = {255, 255, 255, alpha}}
        }

      for _, line in pairs(lines) do
        love.graphics.setColor(line.color)
        love.graphics.line(stage.center - line.shift, 0, stage.center - line.shift, stage.height)
        love.graphics.line(stage.center + line.shift, 0, stage.center + line.shift, stage.height)
      end
    love.graphics.pop()
  end
end

function drawPrebuffer()
  if prebuffer[frame] then
    love.graphics.push("all")
      for index, _ in pairs(prebuffer[frame]) do
        prebuffer[frame][index][12] = prebuffer[frame][index][12] or COLOR.WHITE
        love.graphics.setColor(prebuffer[frame][index][12]) -- 12 is RGB table
        love.graphics.draw(unpack(prebuffer[frame][index]))
      end
    love.graphics.pop()
  end
  prebuffer[frame] = nil
end

function drawSprites()
  for side, op in pairs(Players) do
    love.graphics.push("all")

      -- Ground shadow for sprites
      love.graphics.setColor(COLOR.SHADOW)
      love.graphics.ellipse("fill", side:getCenter(), stage.floor - 5, 50, 20)

      -- Sprites
      local temp_color = {255, 255, 255, 255}

      if side.color then
        for i = 1, 4 do temp_color[i] = side.color[i] end
      end

      if game.identical_players and side == p2 then
        temp_color[1] = temp_color[1] * 0.7
        temp_color[2] = temp_color[2] * 0.85
        temp_color[3] = temp_color[3] * 0.7
      end

      love.graphics.setColor(temp_color)
      
      love.graphics.draw(side.image, side.sprite,
        side.pos[1] + side.h_mid, side.pos[2] + side.v_mid, 0, side.facing, 1, side.h_mid, side.v_mid)

    love.graphics.pop()
  end
end

function drawPostbuffer()
  if postbuffer[frame] then
    love.graphics.push("all")
      for index, _ in pairs(postbuffer[frame]) do
        postbuffer[frame][index][12] = postbuffer[frame][index][12] or COLOR.WHITE
        love.graphics.setColor(postbuffer[frame][index][12]) -- 12 is RGB table
        love.graphics.draw(unpack(postbuffer[frame][index]))
      end
    love.graphics.pop()
  end
  postbuffer[frame] = nil
end

function drawMain()
  love.graphics.clear()

  drawMidline()
  drawPrebuffer()
  drawSprites()
  drawPostbuffer()
end

function drawOverlays()
  love.graphics.clear()
                                            test.o0 = love.timer.getTime()
  -- timer
  love.graphics.push("all")
                                            test.timer0 = love.timer.getTime()
    local displayed_time = math.ceil(round_timer * min_dt)
                                            test.timer1 = love.timer.getTime()
    love.graphics.setColor(COLOR.DARK_ORANGE)
    love.graphics.setFont(timerFont)
                                            test.timer2 = love.timer.getTime()
    love.graphics.printf(displayed_time, 0, 6, window.width, "center")
                                            test.timer3 = love.timer.getTime()
  love.graphics.pop()

  for side, op in pairs(Players) do
                                            test.o1 = love.timer.getTime()
    -- HP bars
    love.graphics.draw(hpbar, window.center + (op.move * 337), 18, 0, op.flip, 1)
    -- ornament
    local pos = (frame % 180) * 8
    if side.life > pos then
      h_loc = window.center + (op.move * 53) + (op.move * pos)
      love.graphics.push("all")
        love.graphics.setColor(COLOR.OFF_WHITE)
        love.graphics.setLineWidth(1)
        love.graphics.line(h_loc, 22, h_loc, 44)
      love.graphics.pop()
    end
    -- life depleted
    if side.life < 280 then
      love.graphics.push("all")
        love.graphics.setColor(COLOR.RED)
        love.graphics.setLineWidth(23)
        love.graphics.line(window.center + (op.move * 333), 34, window.center + (op.move * 333) - op.move * (280 - side.life), 34)
      love.graphics.pop()
    end
                                            test.o2 = love.timer.getTime()
    -- win points
    for i = 1, game.best_to_x do
      if side.score >= i then
        love.graphics.draw(greenlight, window.center + (op.move * 354) - op.move * (20 * i),
        52, 0, 1, 1, op.offset * greenlight:getWidth())
      end
    end
                                            test.o3 = love.timer.getTime()
    -- player icons
    love.graphics.draw(side.icon, window.center + (op.move * 390), 10, 0, op.flip, 1, 0)
                                            test.o4 = love.timer.getTime()
    -- super bars
    love.graphics.push("all")
    if not side.isSupering then
      -- super bar base
      love.graphics.setColor(COLOR.OFF_WHITE)
      love.graphics.draw(SuperBarBase.image, window.center + (op.move * 375), window.height - 35,
        0, 1, 1, op.offset * SuperBarBase.width)
                                            test.o5 = love.timer.getTime()
      -- super meter
      local index = math.floor((frame % 64) / 8)
      local Quad = love.graphics.newQuad(0, index * SuperMeter.height,
        SuperMeter.width * (side.super / 96), SuperMeter.height,
        SuperMeter.image_size[1], SuperMeter.image_size[2])
      local supermeterColor = {0, 32 + side.super * 2, 0, 255}
      if side.super >= 32 and side.super < 64 then
        supermeterColor = {80 + side.super, 80 + side.super, 160 + side.super, 255}
      elseif side.super >= 64 then
        supermeterColor = {159 + side.super, 159 + side.super, 0, 255}
      end
      love.graphics.setColor(supermeterColor)
      love.graphics.draw(SuperMeter.image, Quad, window.center + (op.move * 373),
        window.height - 33, 0, op.flip, 1, 0)
                                            test.o6 = love.timer.getTime()
    else -- if super full, draw frog factor
      local index = math.floor((frame % FrogFactor.total_time) / FrogFactor.time_per_frame)
      local Quad = love.graphics.newQuad(index * FrogFactor.width, 0,
        FrogFactor.width * (side.super / 96), FrogFactor.height,
        FrogFactor.image_size[1], FrogFactor.image_size[2])
      love.graphics.setColor(COLOR.WHITE)
      love.graphics.draw(FrogFactor.image, Quad, window.center + (op.move * 390),
        window.height - FrogFactor.height - 10, 0, op.flip, 1, 0)
    end
    love.graphics.pop()
                                            test.o7 = love.timer.getTime()
  end
end

function drawRoundStart() -- start of round overlays
  local frames_elapsed = frame - frame0
  if frames_elapsed < 60 then
    love.graphics.push("all") 
      love.graphics.setColor(0, 0, 0, 255 - frames_elapsed * 255 / 60)
      love.graphics.rectangle("fill", 0, 0, stage.width, stage.height) 
    love.graphics.pop()
  end
  if frames_elapsed > 35 and frames_elapsed < 90 then
    love.graphics.push("all")
      love.graphics.setFont(roundStartFont)
      love.graphics.setColor(COLOR.ORANGE)
      if p1.score == game.best_to_x - 1 and p2.score == game.best_to_x - 1 then
        love.graphics.printf("Final round!", 0, 220, window.width, "center")
      else
        love.graphics.printf("Round " .. game.current_round, 0, 220, window.width, "center")
      end

      love.graphics.setFont(roundCountdownFont)
      local countdown = (90 - frames_elapsed) * 17
      love.graphics.printf(countdown, 0, 300, window.width, "center")

      
    love.graphics.pop()
  end
end

function drawRoundEnd() -- end of round overlays
  if round_end_frame > 0 then
    -- end of round win message
    if frame - round_end_frame > 60 and frame - round_end_frame < 150 then
      love.graphics.push("all")
        love.graphics.setFont(roundEndFont)
        love.graphics.setColor(COLOR.ORANGE)
        if p1.hasWon then love.graphics.printf(p1.fighter_name .. " wins!", 0, 200, window.width, "center")
        elseif p2.hasWon then love.graphics.printf(p2.fighter_name .. " wins!", 0, 200, window.width, "center")
        else love.graphics.printf("Double K.O. !!", 0, 200, window.width, "center")
        end
      love.graphics.pop()
    end

    -- end of round fade out
    if frame - round_end_frame > 120 and frame - round_end_frame < 150 then
      local light = 255 / 30 * (frame - round_end_frame - 120) -- 0 at 120 frames, 255 at 150
      love.graphics.push("all")
        love.graphics.setColor(0, 0, 0, light)
        love.graphics.rectangle("fill", 0, 0, stage.width, stage.height)
      love.graphics.pop()
    end
  end
end

function drawCharSelect()
  love.graphics.draw(charselectscreen, 0, 0, 0) -- background
  love.graphics.draw(portraits, portraitsQuad, 473, 130) -- character portrait
  love.graphics.push("all")
    love.graphics.setColor(COLOR.BLACK)
    love.graphics.setFont(charInfoFont)
    love.graphics.print(char_text[p1_char][1], 516, 350) -- character movelist
    love.graphics.print(char_text[p1_char][2], 516, 384)
    love.graphics.print(char_text[p1_char][3], 513, 425)
    love.graphics.print(char_text[p1_char][4], 430, 469)

    --p1 rectangle
    love.graphics.setFont(charSelectorFont)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(COLOR.BLUE)
    love.graphics.print("P1", 42, 20 + (p1_char * 70)) -- helptext
    if frame % 60 < 7 then 
      love.graphics.setColor(COLOR.PALE_BLUE) -- flashing rectangle
    end
    love.graphics.rectangle("line", 60, 30 + (p1_char * 70), 290, 40)
    
    --p2 rectangle
    love.graphics.setColor(COLOR.GREEN)
    love.graphics.print("P2", 355, 20 + (p2_char * 70))
    if (frame + 45) % 60 < 7 then
      love.graphics.setColor(COLOR.PALE_GREEN)
    end
    love.graphics.rectangle("line", 61, 31 + (p2_char * 70), 289, 39)
  love.graphics.pop()
end

function drawMatchEnd() -- end of the match (not end of the round)
  love.graphics.draw(bkmatchend, 0, 0) -- background

  love.graphics.push("all")
    love.graphics.setFont(gameoverFont)
    love.graphics.draw(game.match_winner.win_portrait, 100, 50)
    love.graphics.setColor(COLOR.BLACK)
    love.graphics.printf(game.match_winner.win_quote, 0, 470, window.width, "center")
    love.graphics.setFont(gameoverHelpFont)
    love.graphics.setColor(0, 0, 0, (frame * 2) % 255)
    love.graphics.print("Press enter", 650, 540)
  love.graphics.pop()

  -- fade in for match end
  local fadein = 255 - ((frame - frame0) * 255 / 60)
  if frame - frame0 < 60 then
    love.graphics.push("all") 
      love.graphics.setColor(0, 0, 0, fadein)
      love.graphics.rectangle("fill", 0, 0, stage.width, stage.height) 
    love.graphics.pop()
  end
end
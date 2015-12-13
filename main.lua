require 'utilities' -- helper functions
local class = require 'middleclass' -- class support
local screen = require 'screen'  -- screen size
local window = require 'window'  -- window size (scaled version of screen)
local buttons = require 'controls'  -- mapping of keyboard controls
local cam = require 'camera'  -- camera, focuses on specified area of the screen
local music = require 'music' -- background music
local character = require 'character' -- base character class
local particles = require 'particles' -- graphical effects
local game = {current_screen = "title"}

-- load images
local background = love.graphics.newImage('images/background.jpg')
local backgroundQuad = love.graphics.newQuad(240, 120, screen.widthPx, screen.heightPx, background:getDimensions())
local charselectscreen = love.graphics.newImage('images/CharSelectScreen.png')
local titlescreen = love.graphics.newImage('images/TitleScreen.png')  
local bkmatchend = love.graphics.newImage('images/MatchEndBackground.png')
local hpbar = love.graphics.newImage('images/HPBar.png')
local superbar = love.graphics.newImage('images/SuperBar.png')
local frogfactor = love.graphics.newImage('images/FrogFactor.png')
local portraits = love.graphics.newImage('images/Portraits.png')
local greenlight = love.graphics.newImage('images/GreenLight.png')
local redlight = love.graphics.newImage('images/RedLight.png')
local mugshot = love.graphics.newImage('images/Mugshot.png')
local portraitsQuad = love.graphics.newQuad(0, 0, 200, 140,portraits:getDimensions())

-- load fonts
--local defaultFont = love.graphics.getFont()
local titleFont = love.graphics.newFont('/fonts/GoodDog.otf', 60)
local charInfoFont = love.graphics.newFont('/fonts/CharSelect.ttf', 21)
local charSelectorFont = love.graphics.newFont('/fonts/GoodDog.otf', 18)
local timerFont = love.graphics.newFont('/fonts/Timer.otf', 48)
local gameoverFont = love.graphics.newFont('/fonts/GoodDog.otf', 40)

-- load sounds
super_sfx = "SuperFull.mp3"
charselect_sfx = "CharSelectSFX.mp3"
charselected_sfx = "CharSelectedSFX.mp3"

function love.load()
  canvas = love.graphics.newCanvas()
  canvas:setFilter('nearest') -- needed if scaling images up
  
  love.window.setMode(window.width, window.height, { borderless = true })

  setBGM("Intro.mp3")
  
  min_dt = 1/60 -- frames per second
  next_time = love.timer.getTime()
  frame = 0 -- framecount
  frame0 = 0 -- timer for start of round fade in

  init_round_timer = 1200 -- round time in frames
  round_timer = init_round_timer
  round_end_frame = 0
  input_frozen = true
  current_round = 1
  best_to_x = 1
  p1_won_match = false
  p2_won_match = false
  mugshot_on = false -- move to drawbuffer later
  keybuffer = {} 
  drawbuffer = {} -- pre-load draw instructions into future frames

end

function drawMainBackground()
  -- prepare for refactoring
  local CENTER = screen.widthPx / 2
  local LEFT = p1
  local LEFT_SIGN = -1
  local RIGHT = p2
  local RIGHT_SIGN = 1


  -- background first!
  love.graphics.draw(background, backgroundQuad, 0, 0) 

  -- HP bars
  love.graphics.draw(hpbar, 65, 20)
  love.graphics.draw(hpbar, 735, 47, math.pi)
  if p1.life < 280 then
    love.graphics.push("all")
    love.graphics.setColor(220, 0, 0, 255)
    love.graphics.setLineWidth(23)
    love.graphics.line(CENTER - 333, 34, CENTER - 333 + (280 - p1.life), 34)
    love.graphics.pop()
  end

  if p2.life < 280 then
    love.graphics.push("all")
    love.graphics.setColor(220, 0, 0, 255)
    love.graphics.setLineWidth(23)
    love.graphics.line(CENTER + 333, 34, CENTER + 333 - (280 - p2.life), 34)
    love.graphics.pop()
  end    

  -- timer
  love.graphics.push("all")
  love.graphics.setColor(230, 147, 5)
  love.graphics.setFont(timerFont)
  love.graphics.printf(math.ceil(round_timer * min_dt), 0, 6, screen.widthPx, "center")
  love.graphics.pop()

  -- if low on time, draw midline
  if round_timer <= 180 then
    love.graphics.push("all")
    love.graphics.setColor(110, 0, 0, 100)
    love.graphics.setLineWidth(12)
    love.graphics.line(screen.widthPx / 2, 0, screen.widthPx / 2, screen.heightPx)
    love.graphics.pop()
  end

  -- super bars/frog factor
  love.graphics.push("all")
  if not p1:getSuperOn() then
    love.graphics.setLineWidth(1)
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(superbar, 25, screen.heightPx - 35, 0, 2) -- super bars image
    love.graphics.setColor(17, 94, 17) -- dark line
    love.graphics.line(32, screen.heightPx - 30, math.max(32, 30 + p1:getSuper()), screen.heightPx - 30)
    love.graphics.setLineWidth(12)
    love.graphics.setColor(44, 212, 44) -- thick bar
    love.graphics.line(31, screen.heightPx - 22.5, 31 + p1:getSuper(), screen.heightPx - 22.5)
    if (frame % 48) * 2 < p1:getSuper() then -- super bar white line ornament
      love.graphics.setLineWidth(4)
      love.graphics.setColor(255, 255, 255, 180)
      love.graphics.line((frame % 48) * 2 + 31, screen.heightPx - 30, (frame % 48) * 2 + 31, screen.heightPx - 17)
    end
  else -- if super full, draw frog factor
    local frogfactorQuad = love.graphics.newQuad(0, 0, frogfactor:getWidth() * (p1:getSuper() / 96), frogfactor:getHeight(), frogfactor:getDimensions())
    love.graphics.setColor(255 - (frame % 20), 255 - (frame % 20), 255 - (frame % 20))
    love.graphics.draw(frogfactor, frogfactorQuad, 10, screen.heightPx - 60)
  end
  love.graphics.pop()
  love.graphics.push("all")
  if not p2:getSuperOn() then
    love.graphics.setLineWidth(1)
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(superbar, screen.widthPx - 108 - 25, screen.heightPx - 35, 0, 2) -- super bars image
    love.graphics.setColor(17, 94, 17) -- dark line
    love.graphics.line(screen.widthPx - 32, screen.heightPx - 30, math.min(screen.widthPx - 32, screen.widthPx - 30 - p2:getSuper()), screen.heightPx - 30)
    love.graphics.setLineWidth(12)
    love.graphics.setColor(44, 212, 44) -- thick bar
    love.graphics.line(screen.widthPx - 31, screen.heightPx - 22.5, screen.widthPx - 31 - p2:getSuper(), screen.heightPx - 22.5)
    if (frame % 48) * 2 < p2:getSuper() then -- super bar white line ornament
      love.graphics.setLineWidth(4)
      love.graphics.setColor(255, 255, 255, 180)
      love.graphics.line(screen.widthPx - ((frame % 48) * 2 + 31), screen.heightPx - 30, screen.widthPx - ((frame % 48) * 2 + 31), screen.heightPx - 17)
    end

  else -- if super full, draw frog factor
    local frogfactorQuad = love.graphics.newQuad(0, 0, frogfactor:getWidth() * (p2:getSuper() / 96), frogfactor:getHeight(), frogfactor:getDimensions())
    love.graphics.setColor(255 - (frame % 20), 255 - (frame % 20), 255 - (frame % 20))
    love.graphics.draw(frogfactor, frogfactorQuad, screen.widthPx - 150, screen.heightPx - 60) 
  end
  love.graphics.pop()

  -- win points
  for i = 1, best_to_x do
    if p1:getScore() >= i then
      love.graphics.draw(greenlight, 50 + (24 * i), 50)
    else
      love.graphics.draw(redlight, 50 + (24 * i), 50)
    end

    if p2:getScore() >= i then
      love.graphics.draw(greenlight, screen.widthPx - 50 - greenlight:getWidth() - (24 * i), 50)
    else
      love.graphics.draw(redlight, screen.widthPx - 50 - redlight:getWidth() - (24 * i), 50)
    end
  end

  -- player icons
  love.graphics.draw(p1:getIcon_Image(), 10, 10)
  love.graphics.draw(p2:getIcon_Image(), screen.widthPx - p2:getIcon_Width() - 10, 10)
end

function drawCharSelect()
  canvas:renderTo(function ()
    love.graphics.draw(charselectscreen, 0, 0, 0) -- background
    love.graphics.draw(portraits, portraitsQuad, 473, 130) -- character portrait
    love.graphics.push("all")
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(charInfoFont)
    love.graphics.printf(char_text[p1_char][1], 516, 350, 300) -- character movelist
    love.graphics.printf(char_text[p1_char][2], 516, 384, 300) -- character movelist
    love.graphics.printf(char_text[p1_char][3], 513, 425, 300) -- character movelist
    love.graphics.printf(char_text[p1_char][4], 430, 469, 300) -- character movelist
    --p1 rectangle
    love.graphics.setFont(charSelectorFont)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(14, 28, 232)
    love.graphics.printf("P1", 42, 20 + (p1_char * 70), 50) -- helptext
    if frame % 45 < 7 then love.graphics.setColor(164, 164, 255) end -- flashing rectangle
    love.graphics.rectangle("line", 60, 30 + (p1_char * 70), 290, 40)
    
    --p2 rectangle
    love.graphics.setColor(14, 232, 54)
    love.graphics.printf("P2", 355, 20 + (p2_char * 70), 50)
    if frame % 45 < 7 then love.graphics.setColor(164, 255, 164) end
    love.graphics.rectangle("line", 61, 31 + (p2_char * 70), 289, 39)
    
    love.graphics.pop()
  end)
end

function drawMatchEnd()
  canvas:renderTo(function ()

    love.graphics.draw(bkmatchend, 0, 0) -- background
    local win_portrait = ""
    local win_quote = ""

    -- get win portrait/quote
    if p1_won_match then
      win_portrait = p1:getWin_Portrait()
      win_quote = p1:getWin_Quote()
    elseif p2_won_match then
      win_portrait = p2:getWin_Portrait()
      win_quote = p2:getWin_Quote()
    end
      love.graphics.push("all")
      love.graphics.setFont(gameoverFont)
      love.graphics.draw(win_portrait, 100, 50)
      love.graphics.setColor(31, 39, 84)
      love.graphics.printf(win_quote, 50, 470, 700)
      love.graphics.setColor(31, 39, 84) -- placeholder
      love.graphics.setFont(charSelectorFont) -- placeholder
      love.graphics.printf("Press return/enter please", 600, 540, 190) -- placeholder
      love.graphics.pop()

    -- fade in
    frame = frame + 1
    local fadein = 255 - ((frame - frame0) * 255 / 60)
    if frame - frame0 < 60 then 
      love.graphics.setColor(0, 0, 0, fadein)
      love.graphics.rectangle("fill", 0, 0, screen.widthPx, screen.heightPx) 
    end

  end)  
end

function drawRoundStart() -- also unfreezes inputs after frame 90
  local fadein = 255 - ((frame - frame0) * 255 / 60)
    if frame - frame0 < 60 then 
      love.graphics.setColor(0, 0, 0, fadein)
      love.graphics.rectangle("fill", 0, 0, screen.widthPx, screen.heightPx) 
      if p1:getScore() == best_to_x - 1 and p2:getScore() == best_to_x - 1 then setBGMspeed(2 ^ (4/12)) end -- speed up music!
    end
    if frame - frame0 > 48 and frame - frame0 < 90 then
      love.graphics.setFont(titleFont)
      love.graphics.setColor(255, 255, 255)
      love.graphics.printf("Round " .. current_round, 0, 100, screen.widthPx, "center")
      if p1:getScore() == best_to_x - 1 and p2:getScore() == best_to_x - 1 then
        love.graphics.printf("Final round!", 0, 200, screen.widthPx, "center")
      end
    end
    if frame - frame0 > 90 then input_frozen = false end -- unfreeze inputs after fade in
end

function endRound() -- A draw helper function. also adds points for win, and calls newRound() / matchEnd()
  local light = 255 / 30 * (frame - round_end_frame - 120) -- 0 at 120 frames, 255 at 150

  if frame - round_end_frame <= 90 and frame - round_end_frame > 20 and mugshot_on then
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(mugshot, 100, 200)
    -- play Mugshot sfx
  end
  -- end of round win message
  if frame - round_end_frame > 60 and frame - round_end_frame < 150 then
    love.graphics.setFont(titleFont)
    love.graphics.setColor(255, 255, 255)
    if p1:getWon() then love.graphics.printf(p1:getFighter_Name() .. " wins.", 0, 200, screen.widthPx, "center")
    elseif p2:getWon() then love.graphics.printf(p2:getFighter_Name() .. " wins.", 0, 200, screen.widthPx, "center")
    else love.graphics.printf("Double K.O.", 0, 200, screen.widthPx, "center")
    end
  end

  -- end of round fade out
  if frame - round_end_frame > 120 and frame - round_end_frame < 150 then
    love.graphics.setColor(0, 0, 0, light)
    love.graphics.rectangle("fill", 0, 0, screen.widthPx, screen.heightPx) end

  -- add point if player won round, call newRound()
  if frame - round_end_frame > 144 then
    if p1:getWon() then p1:addScore() end
    if p2:getWon() then p2:addScore() end
    
    if p1:getScore() == best_to_x then p1_won_match = true end
    if p2:getScore() == best_to_x then p2_won_match = true end
    
    if not p1_won_match and not p2_won_match then
      newRound()
      round_timer = init_round_timer
      end -- new round
    
    if p1_won_match or p2_won_match then -- match end
      matchEnd()
      game.current_screen = "match_end"
    end
  end
end

function love.draw()
  canvas:clear(0, 0, 0)
  cam:render(canvas, function ()
    if game.current_screen == "maingame" then
      drawMainBackground()
      
      -- drawing sprites
        -- need to shift the sprites back if we flipped the image
      local p1shift = 0
      local p2shift = 0
        -- shift sprites if facing left
      if p2:getFacing() == -1 then p2shift = p2:getSprite_Width() end
      if p1:getFacing() == -1 then p1shift = p1:getSprite_Width() end
      
      love.graphics.draw(p1.image, p1.sprite, p1:getPos_h(), p1:getPos_v(), 0, p1.facing, 1, p1shift, 0)
      love.graphics.draw(p2.image, p2.sprite, p2:getPos_h(), p2:getPos_v(), 0, p2.facing, 1, p2shift, 0)

      -- draw extra fx
      if drawbuffer[frame] then
        love.graphics.draw(unpack(drawbuffer[frame]))
        drawbuffer[frame] = nil
      end
      

      if frame - frame0 < 110 then drawRoundStart() end

      if round_end_frame > 0 then endRound() end

      --drawDebugSprites() -- debug: draw sprite box, center, and facing
      --drawDebugHurtboxes() -- debug: draw hurtboxes and hitboxes
      --print(keybuffer[frame][1], keybuffer[frame][2], keybuffer[frame][3], keybuffer[frame][4])
    end

    if game.current_screen == "charselect" then drawCharSelect() end

    if game.current_screen == "match_end" then drawMatchEnd() end

    if game.current_screen == "title" then love.graphics.draw(titlescreen, 0, 0, 0) end
  end) -- end for cam:render()

  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(canvas, 0, 0, 0, window.scale) -- draws the entire canvas to the screen

  local cur_time = love.timer.getTime()
  if cur_time - next_time >= 0 then next_time = cur_time -- time needed to sleep until the next frame (?)
    return
    end
  love.timer.sleep(next_time - cur_time) -- advance time to next frame (?)
end

function love.update(dt)

  if game.current_screen == "maingame" then
    frame = frame + 1

    -- count down timer if not in some kind of freeze
    if not input_frozen and not (p1:getFrozen() and p2:getFrozen()) then
      round_timer = round_timer - 1
    end

    -- get button press state, and write to keybuffer table
    keybuffer[frame] = {
    love.keyboard.isDown(buttons.p1jump),
    love.keyboard.isDown(buttons.p1attack),
    love.keyboard.isDown(buttons.p2jump),
    love.keyboard.isDown(buttons.p2attack)}

    -- can we delete this part?
    if game.setBGM then
      setBGM(game.setBGM)
      game.setBGM = nil
    end

    -- read keystate from keybuffer and call the associated functions
    if not input_frozen then
      if keybuffer[frame][1] and not p1:getFrozen() and not keybuffer[frame-1][1] then p1:jump_key_press() end
      if keybuffer[frame][2] and not p1:getFrozen() and not keybuffer[frame-1][2] then p1:attack_key_press() end
      if keybuffer[frame][3] and not p2:getFrozen() and not keybuffer[frame-1][3] then p2:jump_key_press() end
      if keybuffer[frame][4] and not p2:getFrozen() and not keybuffer[frame-1][4] then p2:attack_key_press() end
    end
    -- update character positions
    t0 = love.timer.getTime()
    p1:updatePos(p2:get_Center())
    p2:updatePos(p1:get_Center())
    t1 = love.timer.getTime()

    -- check if KO. [1] is for KO, [2] is for mugshot. If mugshot, KO is always true
    if check_p1_got_hit()[1] and check_p2_got_hit()[1] then
      round_end_frame = frame
      input_frozen = true
      p1:gotHit()
      p2:gotHit()

    elseif check_p1_got_hit()[2] then
      round_end_frame = frame
      input_frozen = true
      p1:gotHit("Mugshot")
      p2:hitOpponent()

    elseif check_p1_got_hit()[1] then
      round_end_frame = frame
      input_frozen = true
      p1:gotHit(p2.hit_type)
      p2:hitOpponent()

    elseif check_p2_got_hit()[2] then
      round_end_frame = frame
      input_frozen = true
      p2:gotHit("Mugshot")
      p1:hitOpponent()

    elseif check_p2_got_hit()[1] then
      round_end_frame = frame
      input_frozen = true
      p2:gotHit(p1.hit_type)
      p1:hitOpponent()
    end
    
    -- check if timeout
    if round_timer == 0 and not input_frozen then
      round_end_frame = frame
      input_frozen = true
      local p1_from_center = math.abs((screen.widthPx / 2) - p1:get_Center())
      local p2_from_center = math.abs((screen.widthPx / 2) - p2:get_Center())
      if p1_from_center < p2_from_center and round_timer == 0 then -- inelegant, refactor later
        p2:gotHit()
        p1:hitOpponent()
      elseif p2_from_center < p1_from_center and round_timer == 0 then
        p1:gotHit()
        p2:hitOpponent()
      elseif p1_from_center == p2_from_center and round_timer == 0 then
        p1:gotHit()
        p2:gotHit()
      end 
    end  

    -- advance time (?)
    next_time = next_time + min_dt
  end
  --  cam:update(p1)
end

function startGame()
  game.current_screen = "maingame"

  frame = 0
  frame0 = frame
  input_frozen = true

  p1 = available_chars[p1_char](1)
  p2 = available_chars[p2_char](-1)

  setBGM("DetectiveDog.mp3")
end

function newRound()
  frame = 0
  frame0 = frame

  p1:setPos(p1:getStart_Pos())
  p1:setFacing(1)
  p1:setNewRound()

  p2:setPos(p2:getStart_Pos())
  p2:setFacing(-1)
  p2:setNewRound()

  round_end = false
  round_end_frame = 0
  input_frozen = true
  current_round = current_round + 1
  keybuffer = {}
end

function charSelect()
  setBGM("CharSelect.mp3")
  available_chars = {Konrad, Jean}
  char_text = {
    {"Hyper Jump", "Hyper Kick", "+40%", "Double Jump"},
    {"Wire Sea", "Frog On Land", "+20%, Wire Ocean", "Dandy Frog (Wire Sea OK)\n—— Bunker (Wire Sea OK)"}
    }
  total_chars = #available_chars
  p1_char = 1 -- default to first character
  p2_char = 2 -- default to second character
  game.current_screen = "charselect"
end

function matchEnd()
  frame = 0
  frame0 = frame
  setBGM("GameOver.mp3")
  game.current_screen = "match_end" 
  keybuffer = {}
end

function love.keypressed(key, isrepeat)

  if key == buttons.quit then quitGame() end

  -- Get keys when at title screen
  if game.current_screen == "title" then
    if key ==  buttons.start then
      charSelect()
    end
  end

  -- Get keys when at character select screen
  if game.current_screen == "charselect" then
    if key == buttons.p1jump or key == buttons.p1attack or key == buttons.p2jump or key == buttons.p2attack then
      playSFX1(charselected_sfx)
      startGame()
    end

    if key == buttons.p1up then
      if p1_char == 1 then p1_char = total_chars else p1_char = p1_char - 1 end
      portraitsQuad = love.graphics.newQuad(0, (p1_char - 1) * 140, 200, 140, portraits:getDimensions())
      playSFX1(charselect_sfx)
    end

    if key == buttons.p1down then
      if p1_char == total_chars then p1_char = 1 else p1_char = p1_char + 1 end
      portraitsQuad = love.graphics.newQuad(0, (p1_char - 1) * 140, 200, 140, portraits:getDimensions())
      playSFX1(charselect_sfx)
    end

    if key == buttons.p2up then
      if p2_char == 1 then p2_char = total_chars else p2_char = p2_char - 1 end
      playSFX2(charselect_sfx)
    end

    if key == buttons.p2down then
      if p2_char == total_chars then p2_char = 1 else p2_char = p2_char + 1 end
      playSFX2(charselect_sfx)
    end
  end

  -- Get p1/p2 inputs at main game
  if game.current_screen == "maingame" then
      -- debug
      if key == 'z' then
        for bufferframe, buffervalue in pairs(keybuffer) do
          print(bufferframe, buffervalue[1], buffervalue[2], buffervalue[3], buffervalue[4])
        end
      end
      -- debug
      if key == 'x' then
        WireSea:loadFX(100, 100)
      end
  end

  if game.current_screen == "match_end" then
    if key ==  buttons.start then
      love.load()
      charSelect()
    end
  end
end

function quitGame()
  love.event.quit()
end
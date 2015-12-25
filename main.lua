require 'utilities' -- helper functions
require 'camera'
local class = require 'middleclass' -- class support
local stage = require 'stage'  -- total playing field area
local window = require 'window'  -- current view of stage
local buttons = require 'controls'  -- mapping of keyboard controls
local music = require 'music' -- background music
local character = require 'character' -- base character class
local particles = require 'particles' -- graphics effects

-- test
print(love.filesystem.getSaveDirectory())

-- load images
local charselectscreen = love.graphics.newImage('images/CharSelect.jpg')
local titlescreen = love.graphics.newImage('images/Title.jpg')  
local bkmatchend = love.graphics.newImage('images/MatchEndBackground.png')
local hpbar = love.graphics.newImage('images/HPBar.png')
local superbar = love.graphics.newImage('images/SuperBar.png')
local frogfactor = love.graphics.newImage('images/FrogFactor.png')
local portraits = love.graphics.newImage('images/Portraits.png')
local greenlight = love.graphics.newImage('images/GreenLight.png')
local portraitsQuad = love.graphics.newQuad(0, 0, 200, 140,portraits:getDimensions())

-- load image constants
IMG = {greenlight_width = greenlight:getWidth(),
  frogfactor_width = frogfactor:getWidth(),
  frogfactor_height = frogfactor:getHeight(),
  superbar_width = superbar:getWidth()
  }

-- load fonts
local titleFont = love.graphics.newFont('/fonts/GoodDog.otf', 60)
local charInfoFont = love.graphics.newFont('/fonts/CharSelect.ttf', 21)
local charSelectorFont = love.graphics.newFont('/fonts/GoodDog.otf', 18)
local timerFont = love.graphics.newFont('/fonts/Timer.otf', 48)
local gameoverFont = love.graphics.newFont('/fonts/GoodDog.otf', 40)

-- load sounds
super_sfx = "SuperFull.ogg"
charselect_sfx = "CharSelectSFX.ogg"
charselected_sfx = "CharSelectedSFX.ogg"
mugshot_sfx = "Mugshot.ogg"
explosion_sfx = "Explosion.ogg"

-- build screen
love.window.setMode(window.width, window.height, { borderless = true })
love.window.setTitle("Divefrog")

-- build canvas layers
canvas_overlays = love.graphics.newCanvas(stage.width, stage.height)
canvas_sprites = love.graphics.newCanvas(stage.width, stage.height)
canvas_background = love.graphics.newCanvas(stage.width, stage.height)

function love.load()
  game = {
    current_screen = "title",
    best_to_x = 5,
    current_round = 0,
    match_winner = false,
    superfreeze_time = 0,
    superfreeze_player = nil}
  setBGM("Intro.ogg")
  min_dt = 1/60 -- frames per second
  next_time = love.timer.getTime()
  frame = 0 -- framecount
  frame0 = 0 -- timer for start of round fade in
  init_round_timer = 1200 -- round time in frames
  round_timer = init_round_timer
  round_end_frame = 0
  round_ended = false
  keybuffer = {false, false, false, false} -- log of all keystates during the round. Useful for netplay!
  prebuffer = {} -- pre-load draw instruction into future frames behind sprite
  postbuffer = {} -- pre-load draw instructions into future frames over sprite
  soundbuffer = {} -- pre-load sound effects into future frames
  camera_xy = {} -- corner for camera and window drawing
  debug = {boxes = false, sprites = false, midpoints = false, camera = false, keybuffer = false}
end

function drawBackground()
  canvas_background:clear()
  if game.superfreeze_time > 0 then
    love.graphics.push("all")
      love.graphics.setColor(96, 96, 96)
      love.graphics.draw(p2.stage_background, 0, 0) 
    love.graphics.pop()
  else
    love.graphics.draw(p2.stage_background, 0, 0) 
  end
end

function drawSprites()
  canvas_sprites:clear()

  --[[----------------------------------------------
                        MID-LINE      
  ----------------------------------------------]]--   
    -- draw if low on time
  if round_timer <= 180 then
    love.graphics.push("all")
      love.graphics.setColor(110, 0, 0, 200)
      love.graphics.setLineWidth(12)
      love.graphics.line(stage.center, 0, stage.center, stage.height)
    love.graphics.pop()
  end

  --[[----------------------------------------------
                  UNDER-SPRITE LAYER      
  ----------------------------------------------]]--
  if prebuffer[frame] then
    love.graphics.push("all")
    for particle_index, particle_value in pairs(prebuffer[frame]) do
      love.graphics.setColor(prebuffer[frame][particle_index][12]) -- 12 is RGB table
      love.graphics.draw(unpack(prebuffer[frame][particle_index]))
    end
    love.graphics.pop()
  end
  prebuffer[frame] = nil

  --[[----------------------------------------------
                        SPRITES      
  ----------------------------------------------]]--      
    -- need to shift the sprites back if we flipped the image
  local p1shift = 0
  local p2shift = 0
    -- shift sprites if facing left
  if p2.facing == -1 then p2shift = p2:getSprite_Width() end
  if p1.facing == -1 then p1shift = p1:getSprite_Width() end
  
  love.graphics.draw(p1.image, p1.sprite, p1:getPos_h(), p1:getPos_v(), 0, p1.facing, 1, p1shift, 0)
  love.graphics.draw(p2.image, p2.sprite, p2:getPos_h(), p2:getPos_v(), 0, p2.facing, 1, p2shift, 0)

  --[[----------------------------------------------
                  OVER-SPRITE LAYER      
  ----------------------------------------------]]--
  if postbuffer[frame] then
    for particle_index, particle_value in pairs(postbuffer[frame]) do
      love.graphics.draw(unpack(postbuffer[frame][particle_index]))
    end
  end
  postbuffer[frame] = nil
end

function drawOverlays()
  canvas_overlays:clear()
  --[[----------------------------------------------
                       OVERLAYS      
  ----------------------------------------------]]--
  -- timer
  love.graphics.push("all")
    love.graphics.setColor(230, 147, 5)
    love.graphics.setFont(timerFont)
    love.graphics.printf(math.ceil(round_timer * min_dt), 0, 6, window.width, "center")
  love.graphics.pop()

  for side, op in pairs(PLAYERS) do
    -- HP bars
    love.graphics.draw(hpbar, window.center + (op.move * 335), 20, 0, op.flip, 1)
    if side.life < 280 then
      love.graphics.push("all")
        love.graphics.setColor(220, 0, 0, 255)
        love.graphics.setLineWidth(23)
        love.graphics.line(window.center + (op.move * 333), 34, window.center + (op.move * 333) - op.move * (280 - side.life), 34)
      love.graphics.pop()
    end

    -- win points
    for i = 1, game.best_to_x do
      if side.score >= i then
        love.graphics.draw(greenlight, window.center + (op.move * 358) - op.move * (24 * i),
        50, 0, 1, 1, op.offset * IMG.greenlight_width)
      end
    end

    -- player icons
    love.graphics.draw(side.icon, window.center + (op.move * 390), 10, 0, 1, 1, op.offset * side:getIcon_Width())

    -- super bars
    love.graphics.push("all")
    if not side.super_on then
      -- super bar images
      love.graphics.setColor(255, 255, 255)
      love.graphics.draw(superbar, window.center + (op.move * 375), window.height - 35,
        0, 1, 1, op.offset * IMG.superbar_width)
      -- dark line
      love.graphics.setLineWidth(1)
      love.graphics.setColor(17, 94, 17)
      love.graphics.line(window.center + op.move * 368,
        window.height - 30,
        math.max(window.center + op.move * 368, window.center + op.move * 370 - op.move * side.super),
        window.height - 30)
      -- thick bar
      love.graphics.setLineWidth(12)
      love.graphics.setColor(44, 212, 44)
      love.graphics.line(window.center + op.move * 369,
        window.height - 22.5,
        window.center + op.move * 369 - op.move * side.super,
        window.height - 22.5)
      -- white line ornament
      if (frame % 48) * 2 < side.super then
        love.graphics.setLineWidth(4)
        love.graphics.setColor(255, 255, 255, 180)
        love.graphics.line(window.center + op.move * 369 - op.move * (frame % 48) * 2,
          window.height - 30, 
          window.center + op.move * 369 - op.move * (frame % 48) * 2,
          window.height - 17)
      end
    
    else -- if super full, draw frog factor
      local frogfactorQuad = love.graphics.newQuad(0, 0, IMG.frogfactor_width * (side.super / 96),
        IMG.frogfactor_height, IMG.frogfactor_width, IMG.frogfactor_height)
      love.graphics.setColor(255 - (frame % 20), 255 - (frame % 20), 255 - (frame % 20))
      love.graphics.draw(frogfactor, frogfactorQuad, window.center + (op.move * 390), window.height - 60, 0, 1, 1, (op.offset * 140))
    end
    love.graphics.pop()
  end

  --[[----------------------------------------------
                OVERLAYS - ROUND START      
  ----------------------------------------------]]--
  local frames_elapsed = frame - frame0
  if frames_elapsed < 60 then
    love.graphics.push("all") 
      love.graphics.setColor(0, 0, 0, 255 - frames_elapsed * 255 / 60)
      love.graphics.rectangle("fill", 0, 0, stage.width, stage.height) 
    love.graphics.pop()
  end
  if frames_elapsed > 48 and frames_elapsed < 90 then
    love.graphics.push("all")
      love.graphics.setFont(titleFont)
      love.graphics.setColor(255, 255, 255)
      love.graphics.printf("Round " .. game.current_round, 0, 200, window.width, "center")
      if p1.score == game.best_to_x - 1 and p2.score == game.best_to_x - 1 then
        love.graphics.printf("Final round!", 0, 300, window.width, "center")
      end
    love.graphics.pop()
  end

  --[[----------------------------------------------
                 OVERLAYS - ROUND END      
  ----------------------------------------------]]--
  if round_end_frame > 0 then
    -- end of round win message
    if frame - round_end_frame > 60 and frame - round_end_frame < 150 then
      love.graphics.push("all")
        love.graphics.setFont(titleFont)
        love.graphics.setColor(255, 255, 255)
        if p1.won then love.graphics.printf(p1.fighter_name .. " wins.", 0, 200, window.width, "center")
        elseif p2.won then love.graphics.printf(p2.fighter_name .. " wins.", 0, 200, window.width, "center")
        else love.graphics.printf("Double K.O.", 0, 200, window.width, "center")
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

function love.draw()
  if game.current_screen == "maingame" then
    canvas_background:renderTo(drawBackground)
    canvas_sprites:renderTo(drawSprites)
    if game.superfreeze_time == 0 then
      canvas_overlays:renderTo(drawOverlays)
    else
      canvas_overlays:clear()
    end

    if game.superfreeze_time > 0 then camera:scale(0.5, 0.5) end

    camera:set(0.5, 1)
    love.graphics.draw(canvas_background)
    camera:unset()

    camera:set(1, 1)
    love.graphics.draw(canvas_sprites)
    if debug.boxes then drawDebugHurtboxes() end 
    if debug.sprites then drawDebugSprites() end 
    camera:unset()

    camera:set(0, 0)
    love.graphics.draw(canvas_overlays)
    if debug.midpoints then drawMidPoints() end
    camera:unset()      

    if game.superfreeze_time > 0 then camera:scale(2, 2) end

    if debug.camera then print(unpack(camera_xy)) end
    if debug.keybuffer then print(unpack(keybuffer[frame])) end
  end

  if game.current_screen == "charselect" then
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
  end

  if game.current_screen == "match_end" then
    love.graphics.draw(bkmatchend, 0, 0) -- background

    love.graphics.push("all")
      love.graphics.setFont(gameoverFont)
      love.graphics.draw(game.match_winner.win_portrait, 100, 50)
      love.graphics.setColor(31, 39, 84)
      love.graphics.printf(game.match_winner.win_quote, 50, 470, 700)
      love.graphics.setColor(31, 39, 84) -- placeholder
      love.graphics.setFont(charSelectorFont) -- placeholder
      love.graphics.printf("Press return/enter please", 600, 540, 190) -- placeholder
    love.graphics.pop()

    -- fade in for match end
    frame = frame + 1
    local fadein = 255 - ((frame - frame0) * 255 / 60)
    if frame - frame0 < 60 then
      love.graphics.push("all") 
        love.graphics.setColor(0, 0, 0, fadein)
        love.graphics.rectangle("fill", 0, 0, stage.width, stage.height) 
      love.graphics.pop()
    end
  end

  if game.current_screen == "title" then love.graphics.draw(titlescreen, 0, 0, 0) end

  local cur_time = love.timer.getTime() -- time after drawing all the stuff
  if cur_time - next_time >= 0 then
    next_time = cur_time -- time needed to sleep until the next frame (?)
  end

  love.timer.sleep(next_time - cur_time) -- advance time to next frame (?)
end

function love.update(dt)
  if game.current_screen == "maingame" then
    if game.superfreeze_time == 0 then
      local h_midpoint = (p1:getCenter() + p2:getCenter()) / 2
      local highest_sprite = math.min(p1.pos[2] + p1.sprite_size[2], p2.pos[2] + p2.sprite_size[2])
      local screen_bottom = stage.height - window.height

      camera_xy = {clamp(h_midpoint - window.center, 0, stage.width - window.width),
        screen_bottom - (stage.floor - highest_sprite) / 8 }
    
      camera:setPosition(unpack(camera_xy))
    else
      game.superfreeze_time = game.superfreeze_time - 1
      local h_position = game.superfreeze_player:getCenter()
      camera:setPosition(h_position - 0.5 * window.center, game.superfreeze_player.pos[2])
    end

    frame = frame + 1

    -- count down timer if not in some kind of freeze
    if not round_ended and not (p1.frozen > 0 and p2.frozen > 0) then
      round_timer = round_timer - 1
    end


    -- get button press state, and write to keybuffer table
    keybuffer[frame] = {
    love.keyboard.isDown(buttons.p1jump),
    love.keyboard.isDown(buttons.p1attack),
    love.keyboard.isDown(buttons.p2jump),
    love.keyboard.isDown(buttons.p2attack)}

    -- read keystate from keybuffer and call the associated functions
    -- only call if the key was pressed this frame, but not pressed last frame
    if not round_ended then
      if keybuffer[frame][1] and p1.frozen == 0 and not keybuffer[frame-1][1] then p1:jump_key_press() end
      if keybuffer[frame][2] and p1.frozen == 0 and not keybuffer[frame-1][2] then p1:attack_key_press() end
      if keybuffer[frame][3] and p2.frozen == 0 and not keybuffer[frame-1][3] then p2:jump_key_press() end
      if keybuffer[frame][4] and p2.frozen == 0 and not keybuffer[frame-1][4] then p2:attack_key_press() end
    end

    -- update character positions
    t0 = love.timer.getTime()
    p1:updatePos()
    p2:updatePos()
    t1 = love.timer.getTime()

    if soundbuffer[frame] then playSFX(soundbuffer[frame]) end

    -- check if anyone got hit
    if check_got_hit(p1, p2) and check_got_hit(p2, p1) then
      round_end_frame = frame
      round_ended = true
      p1:gotHit(p2.hit_type)
      p2:gotHit(p1.hit_type)

    elseif check_got_hit(p1, p2) then
      round_end_frame = frame
      round_ended = true
      p1:gotHit(p2.hit_type)
      p2:hitOpponent()

    elseif check_got_hit(p2, p1) then
      round_end_frame = frame
      round_ended = true
      p2:gotHit(p1.hit_type)
      p1:hitOpponent()
    end

    -- check if timeout
    if round_timer == 0 then
      round_end_frame = frame
      round_ended = true
      local p1_from_center = math.abs((stage.center) - p1:getCenter())
      local p2_from_center = math.abs((stage.center) - p2:getCenter())
      if p1_from_center < p2_from_center then
        p2:gotHit(p1.hit_type)
        p1:hitOpponent()
      elseif p2_from_center < p1_from_center then
        p1:gotHit(p2.hit_type)
        p2:hitOpponent()
      else
        p1:gotHit(p2.hit_type)
        p2:gotHit(p1.hit_type)
      end 
    end  

    -- after round ended and drew end round stuff, start new round
    if frame - round_end_frame == 144 then
      for p, _ in pairs(PLAYERS) do
        if p.won then p:addScore() end
        if p.score == game.best_to_x then game.match_winner = p end
      end
      
      if not game.match_winner then newRound()
      else -- match end
        frame = 0
        frame0 = 0
        setBGM("GameOver.ogg")
        game.current_screen = "match_end" 
        keybuffer = {}
      end
    end

    -- advance time (?)
    next_time = next_time + min_dt
  end
end

function newRound()

  p1:initialize(1, p2, p1.super, p1.hit_flag.Mugshot, p1.score)
  p2:initialize(2, p1, p2.super, p2.hit_flag.Mugshot, p2.score)

  frame = 0
  frame0 = 0
  round_timer = init_round_timer
  round_ended = false
  round_end_frame = 100000 -- arbitrary number, larger than total round time
  p1.frozen = 90
  p2.frozen = 90
  game.current_round = game.current_round + 1
  keybuffer = {false, false, false, false}
  soundbuffer = {} -- pre-load sound effects into future frames

  if p1.score == game.best_to_x - 1 and p2.score == game.best_to_x - 1 then
    setBGMspeed(2 ^ (4/12))
  end
end

function startGame()
  game.current_screen = "maingame"

  p1 = available_chars[p1_char](1, p2, 0, false, 0)
  p2 = available_chars[p2_char](2, p1, 0, false, 0)

  -- put the move/flip/offset stuff for draw operations in p1/p2
  --p1_flags = {move = -1, flip = 1, offset = 0}
  --p2_flags = {move = 1, flip = -1, offset = 1}
  PLAYERS = { [p1] = {
                      move = -1,
                      flip = 1,
                      offset = 0},
              [p2] = {
                      move = 1,
                      flip = -1,
                      offset = 1} } -- can add score here

  THINGS = {[p1] = {p2, p2.things}, [p2] = {p1, p1.things}, [p1.things] = {p2, p2.things}, [p2.things] = {p1, p1.things}} 

  setBGM(p2.BGM)
  newRound()
end

function charSelect()
  setBGM("CharSelect.ogg")
  available_chars = {Konrad, Jean, Sun}
  char_text = {
    {"Hyper Jump", "Hyper Kick", "+40%", "Double Jump"},
    {"Wire Sea", "Frog On Land", "+20%, Wire Ocean", "Dandy Frog (Wire Sea OK)\n— Pile Bonquer (Wire Sea OK)"},
    {"Hotflame (Wire Sea OK)", "Riot Kick", "Frog Install", "Small Head"}
    }
  total_chars = #available_chars
  p1_char = 1 -- default to first character
  p2_char = 2 -- default to second character
  game.current_screen = "charselect"
end

function love.keypressed(key, isrepeat)
  if key == buttons.quit then love.event.quit() end

  -- Get keys when at title stage
  if game.current_screen == "title" then
    if key ==  buttons.start then
      charSelect()
    end
  end

  -- Get keys when at character select stage
  if game.current_screen == "charselect" then
    if key == buttons.p1attack or key == buttons.p2attack then
      playSFX(charselected_sfx)
      startGame()
    end

    if key == buttons.p1jump then
      if p1_char == total_chars then p1_char = 1 else p1_char = p1_char + 1 end
      portraitsQuad = love.graphics.newQuad(0, (p1_char - 1) * 140, 200, 140, portraits:getDimensions())
      playSFX(charselect_sfx)
    end

    if key == buttons.p2jump then
      if p2_char == total_chars then p2_char = 1 else p2_char = p2_char + 1 end
      playSFX(charselect_sfx)
    end
  end

  if game.current_screen == "match_end" then
    if key ==  buttons.start then
      love.load()
      charSelect()
    end
  end

  if game.current_screen == "maingame" then
    -- debug keys
    if key == '1' then debug.boxes = not debug.boxes end
    if key == '2' then debug.sprites = not debug.sprites end
    if key == '3' then debug.midpoints = not debug.midpoints end
    if key == '4' then debug.camera = not debug.camera end
    if key == '5' then debug.keybuffer = not debug.keybuffer end
  end
end

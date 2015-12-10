local class = require 'middleclass'
local screen = require 'screen' -- for checking floor/walls
local buttons = require 'controls' -- mapping of keyboard controls
local music = require 'music' -- background music
require 'utilities'

--[[---------------------------------------------------------------------------
                                FIGHTER SUPERCLASS
-----------------------------------------------------------------------------]]   

Fighter = class('Fighter')    
function Fighter:initialize(init_facing)
  initpic = love.graphics.newImage('images/init.png')
  self.player = init_facing -- 1 for player 1, -1 for player 2
  self.opponent = -self.player
  self.frozen = 0 -- only update sprite if this is 0. Used for e.g. super freeze
  self.score = 0
  self.in_air = false
  self.ko = false
  self.won = false
  self.attacking = false
  self.specialing = false
  self.headfrogged = 0 -- frames the character is headfrogged for
  self.hit_type = "" -- type of hit, passed through to gotHit(). E.g. for wall splat
  self.super = 0 -- max 96
  self.super_on = false -- trigger super mode
  self.super_drainspeed = 0.1 -- how fast super meter drains away. 
  self.start_pos = {1, 1} -- Starting position at beginning of round
  self.pos = {1, 1} -- Top left corner of sprite
  self.icon = initpic -- corner icon
  self.win_portrait = initpic -- win screen large portrait
  self.win_quote = "Win Quote"
  self.image = initpic -- Entire tiled image
  self.image_size = {2, 2}
  self.image_index = 0 -- Horizontal offset starting at 0
  self.sprite_size = {1, 1}
  self.sprite_wallspace = 0 -- how many pixels to reduce when checking against stage wall
  self.vel = {0, 0}
  self.default_gravity = 0.25
  self.friction = 0.9 -- horizontal velocity multiplied each frame
  self.friction_on = false
  self.vel_multiple = 1.0
  self.vel_multiple_super = 1.4 -- default is 1.4 for Frog Factor, 0.6 for Headfrogged
  self.hit_wall = false -- if player has hit wall or not. Used for wallsplat and some special moves
  self.hurtboxes = {{0, 0, 0, 0}}
  self.headboxes = {{0, 0, 0, 0}}
  self.hitboxes = {{0, 0, 0, 0}}
  self.drawfx = {} -- particles to draw
  self.opp_center = 400 -- center of opponent's sprite
  self.waiting = 0 -- number of frames to wait. used for pre-jump frames etc.
  self.waiting_state = "" -- buffer the action that will be executed if special isn't pressed

  -- lists of hitboxes and hurtboxes for the relevant sprites. format is LEFT, TOP, RIGHT, BOTTOM, relative to top left corner of sprite.
  self.hurtboxes_standing = {{0, 0, 0, 0}}
  self.hurtboxes_jumping  = {{0, 0, 0, 0}}
  self.hurtboxes_falling = {{0, 0, 0, 0}}
  self.hurtboxes_attacking  = {{0, 0, 0, 0}}
  self.hurtboxes_kickback  = {{0, 0, 0, 0}}
  self.hurtboxes_ko  = {{0, 0, 0, 0}}
  self.headboxes_standing = {{0, 0, 0, 0}}
  self.headboxes_jumping  = {{0, 0, 0, 0}}
  self.headboxes_falling = {{0, 0, 0, 0}}
  self.headboxes_attacking  = {{0, 0, 0, 0}}
  self.headboxes_kickback  = {{0, 0, 0, 0}}
  self.headboxes_ko  = {{0, 0, 0, 0}}
  self.hitboxes_attacking = {{0, 0, 0, 0}}

  -- sound effects
  self.jump_sfx = "dummy.mp3"
  self.attack_sfx = "dummy.mp3"
  self.got_hit_sfx = "dummy.mp3"
  self.hit_sound_sfx = "dummy.mp3"
  self.ground_special_sfx = "dummy.mp3"
  self.air_special_sfx = "dummy.mp3"

  -- Copy the below stuff after the new initialization variables for each new character
  self.sprite = love.graphics.newQuad(self.image_index * self.sprite_size[1], 0, self.sprite_size[1], self.sprite_size[2], self.image_size[1], self.image_size[2])
  self.facing = init_facing -- 1 for facing right, -1 for facing left
  if init_facing == 1 then self.start_pos[1] = screen.widthPx / 2 - (screen.widthPx / 5) - (self.sprite_size[1] / 2) -- the last item is to adjust for whitespace in image tile
  else self.start_pos[1] = screen.widthPx / 2 + (screen.widthPx / 5) - (self.sprite_size[1] / 2) end
  self.start_pos[2] = screen.heightPx - (screen.heightPx / 12) - (self.sprite_size[2] / 2)
  self.my_center = self.pos[1] + self.sprite_size[1]
  self.gravity = self.default_gravity
  self.current_hurtboxes = self.hurtboxes_standing
  self.current_headboxes = self.headboxes_standing
  self.current_hitboxes = self.hitboxes_attacking
end

  function Fighter:jump_key_press()

    -- check special move
    local attack_not_down = true -- check if attack key was down on (frame - 3)
    local attack_within2_down = false -- check if attack key is down from (frame - 2) to frame
   
    for bufferframe = 0, 2 do -- check for attack key down from (frames - 2) to frame
      if self.player == 1 then
        if keybuffer[(frame - bufferframe)][2] then attack_within2_down = true end
      elseif self.player == -1 then
        if keybuffer[(frame - bufferframe)][4] then attack_within2_down = true end
      end
      if self.player == 1 then -- check for attack key down at (frame - 3)
        if keybuffer[(frame - 3)][2] then attack_not_down = false end
      elseif self.player == -1 then
        if keybuffer[(frame - 3)][4] then attack_not_down = false end
      end
    end

    if attack_within2_down and attack_not_down and self.in_air then
      self:air_special()
    elseif attack_within2_down and attack_not_down and not self.in_air then
      self:ground_special()
    end

    --[[ Default jump action. Replace with character-specific jump velocity
    if not self.in_air then
      self.waiting = 3
      self.waiting_state = "Jump"
    end --]]

  end

  function Fighter:attack_key_press()
    -- check special move
    local jump_not_down = true -- check if jump key was down on (frame - 3)
    local jump_within2_down = false -- check if jump key is down from (frame - 2) to frame

    for bufferframe = 0, 2 do -- check for jump key down from (frames - 2) to frame
      if self.player == 1 then
        if keybuffer[(frame - bufferframe)][1] then jump_within2_down = true end
      elseif self.player == -1 then
        if keybuffer[(frame - bufferframe)][3] then jump_within2_down = true end
      end
      if self.player == 1 then -- check for jump key down at (frame - 3)
        if keybuffer[(frame - 3)][1] then jump_not_down = false end
      elseif self.player == -1 then
        if keybuffer[(frame - 3)][3] then jump_not_down = false end
      end
    end

    if jump_within2_down and jump_not_down and self.in_air then
      self:air_special()
    elseif jump_within2_down and not jump_not_down and not self.in_air then
      self:ground_special()
    end
    
    --[[ Default attack action. Replace with character-specific attack/kickback actions
    
    -- attack if in air and not already attacking and going up and more than 50 pixels above the ground.
    if self.in_air and not self.attacking and 
      (self.pos[2] + self.sprite_size[2] < screen.floor - 50 or
      (self.vel[2] > 0 and self.pos[2] + self.sprite_size[2] < screen.floor - 30)) then
        self.waiting = 3
        self.waiting_state = "Attack"
        
    -- If on ground, kickback
    elseif not self.in_air then
      self.waiting = 3
      self.waiting_state = "Kickback"
    end
    --]]
  end

  -- all these methods should only be called internally

  function Fighter:jump(h_vel, v_vel)
    self.in_air = true
    self.gravity = self.default_gravity
    self.vel = {h_vel * self.facing, -v_vel}
    self:updateImage(1)
    self.current_hurtboxes = self.hurtboxes_jumping
    self.current_headboxes = self.headboxes_jumping
  end

  function Fighter:kickback(h_vel, v_vel)
    self.in_air = true
    self.gravity = self.default_gravity
    self.vel = {h_vel * self.facing, -v_vel}
    self:updateImage(3)
    self.current_hurtboxes = self.hurtboxes_kickback
    self.current_headboxes = self.headboxes_kickback
  end

  function Fighter:land() -- called when character lands on floor
    self.in_air = false
    self.attacking = false
    self.specialing = false
    self.hit_wall = false
    if not self.ko then
      self.vel = {0, 0}
      self:updateImage(0)
      self.current_hurtboxes = self.hurtboxes_standing
      self.current_headboxes = self.headboxes_standing
    end
  end

  function Fighter:attack(h_vel, v_vel)
    self.vel = {h_vel * self.facing, v_vel}
    self.attacking = true
    self:updateImage(4)
    self.gravity = 0
    self.current_hurtboxes = self.hurtboxes_attacking
    self.current_headboxes = self.headboxes_attacking
    if self.super < 96 and not self.super_on then 
      self.super = math.min(self.super + 8, 96)
      if self.super == 96 then playSFX1(super_sfx) end
    end
  end

  function Fighter:air_special()
    if self.super >= 16 and not self.super_on and not self.specialing then
      self.super = self.super - 16
      self.specialing = true
      self.waiting_state = ""
      playSFX1(self.air_special_sfx)
    end
  end

  function Fighter:ground_special()
    if self.super >= 16 and not self.super_on and not self.specialing then
      self.super = self.super - 16
      self.specialing = true
      self.waiting_state = ""
      playSFX1(self.ground_special_sfx)
    end
  end

function Fighter:gotHit(type) -- execute this one time, when character gets hit
  if type == "Headshot" then
    -- headshot code
  end

  if type == "Wallsplat" then
    -- wallsplat code
  end
  self.vel_multiple = 1.0
  self.ko = true 
  self.attacking = false -- stops calling gotHit, since the hitbox check is now false
  playSFX1(self.hit_sound_sfx)
end

function Fighter:koRoutine() -- keep calling koRoutine() until self.ko is false
  if frame - round_end_frame < 60 then    
    self.vel = {0, 0}
    self.gravity = 0
  end
  if frame - round_end_frame == 60 then
    if self.facing == 1 then self.vel[1] = -10 else self.vel[1] = 10 end
    playSFX2(self.got_hit_sfx) 
  end
  if frame - round_end_frame > 60 then
    self.gravity = 2
    self.friction_on = true
    self:updateImage(5)
    self.current_hurtboxes = self.hurtboxes_ko
    self.current_headboxes = self.headboxes_ko
  end
end

function Fighter:hitOpponent() -- execute this one time, when you hit the opponent
  self.vel_multiple = 1.0
  self.won = true
  self.attacking = false -- stops calling hitOpponent, since the hitbox check is now false
  currentBGM:pause()
end

function Fighter:wonRoundRoutine() -- keep calling this if self.won is true
  if frame - round_end_frame < 60 then
    self.vel = {0, 0}
    self.gravity = 0
  end

  if frame - round_end_frame == 60 then
    currentBGM:play()
  end

  if frame - round_end_frame > 60 then
    self.gravity = 1
    self.attacking = false
    if self.in_air then
      self:updateImage(2)
    else
      self:updateImage(0)
    end
    self.current_hurtboxes = self.hurtboxes_standing 
    self.current_headboxes = self.headboxes_standing 
  end
end

function Fighter:getStart_Pos() return self.start_pos end
function Fighter:getPos_h() return self.pos[1] end
function Fighter:getPos_v() return self.pos[2] end
function Fighter:getSprite_Width() return self.sprite_size[1] end
function Fighter:getFacing() return self.facing end
function Fighter:getImage_Size() return unpack(self.image_size) end
function Fighter:getHurtboxes() return self.hurtboxes end
function Fighter:getHeadboxes() return self.headboxes end
function Fighter:getHitboxes() return self.hitboxes end
function Fighter:getWon() return self.won end
function Fighter:getKO() return self.ko end
function Fighter:getScore() return self.score end
function Fighter:getFighter_Name() return self.fighter_name end
function Fighter:get_Center() return self.pos[1] + 0.5 * self.sprite_size[1] end
function Fighter:getIcon_Image() return self.icon end
function Fighter:getIcon_Width() return self.icon:getWidth() end
function Fighter:getWin_Portrait() return self.win_portrait end
function Fighter:getWin_Quote() return self.win_quote end
function Fighter:getAttacking() return self.attacking end
function Fighter:getSuper() return self.super end
function Fighter:getSuperOn() return self.super_on end
function Fighter:getHit_Wall() return self.hit_wall end
function Fighter:getHit_Type() return self.hit_type end
function Fighter:getFrozen() if self.frozen > 0 then return true else return false end end

function Fighter:gotKO() return self.ko end
function Fighter:addScore() self.score = self.score + 1 end
function Fighter:setPos(pos) self.pos = {pos[1], pos[2]} end
function Fighter:setFacing(facing) self.facing = facing end
function Fighter:setFrozen(frames) self.frozen = frames end
function Fighter:setNewRound()
  self.in_air = false
  self.ko = false
  self.won = false
  self.attacking = false
  self.super_on = false
  self.hit_wall = false
  self.image_index = 0 -- Horizontal offset starting at 0
  self.vel = {0, 0}
  self.vel_multiple = 1.0
  self.gravity = self.default_gravity
  self.opp_center = 400 -- center of opponent's sprite
  self.my_center = self.pos[1] + self.sprite_size[1]
  self:updateImage(self.image_index)
  self.current_hurtboxes = self.hurtboxes_standing
  self.current_headboxes = self.headboxes_standing
  self.current_hitboxes = self.hitboxes_attacking
end

function Fighter:updateImage(image_index)
  self.sprite = love.graphics.newQuad(image_index * self.sprite_size[1], 0, self.sprite_size[1], self.sprite_size[2], self.image_size[1], self.image_size[2])
  return self.sprite
end

function Fighter:fix_Facing() -- change character facing if over center of opponent
  if not self.in_air then
    if self.facing == 1 and self.my_center > self.opp_center then
      self.facing = -1
    elseif self.facing == -1 and self.my_center < self.opp_center then
      self.facing = 1
    end
  end
end

function Fighter:updateBoxes()
  -- initialize temp variable to hold hurtbox/hitbox quads

  local temp_hurtbox = {}
  for i = 1, #self.current_hurtboxes do
    temp_hurtbox[i] = {0, 0, 0, 0}
  end

  local temp_headbox = {}
  for i = 1, #self.current_headboxes do
    temp_headbox[i] = {0, 0, 0, 0}
  end

  local temp_hitbox = {}
  for i = 1, #self.current_hitboxes do
    temp_hitbox[i] = {0, 0, 0, 0}
  end

  -- add hurtbox sides to self.pos for updated sides
  if self.facing == 1 then
    for i = 1, #self.current_hurtboxes do
      temp_hurtbox[i][1] = self.current_hurtboxes[i][1] + self.pos[1] -- left
      temp_hurtbox[i][2] = self.current_hurtboxes[i][2] + self.pos[2] -- top
      temp_hurtbox[i][3] = self.current_hurtboxes[i][3] + self.pos[1] -- right
      temp_hurtbox[i][4] = self.current_hurtboxes[i][4] + self.pos[2] -- bottom
    end
    for i = 1, #self.current_headboxes do
      temp_headbox[i][1] = self.current_headboxes[i][1] + self.pos[1] -- left
      temp_headbox[i][2] = self.current_headboxes[i][2] + self.pos[2] -- top
      temp_headbox[i][3] = self.current_headboxes[i][3] + self.pos[1] -- right
      temp_headbox[i][4] = self.current_headboxes[i][4] + self.pos[2] -- bottom
    end

  elseif self.facing == -1 then
    for i = 1, #self.current_hurtboxes do
      temp_hurtbox[i][1] = self.pos[1] - self.current_hurtboxes[i][3] + self.sprite_size[1] -- left
      temp_hurtbox[i][2] = self.current_hurtboxes[i][2] + self.pos[2] -- top
      temp_hurtbox[i][3] = self.pos[1] - self.current_hurtboxes[i][1] + self.sprite_size[1] -- right
      temp_hurtbox[i][4] = self.current_hurtboxes[i][4] + self.pos[2] -- bottom
    end
    for i = 1, #self.current_headboxes do
      temp_headbox[i][1] = self.pos[1] - self.current_headboxes[i][3] + self.sprite_size[1] -- left
      temp_headbox[i][2] = self.current_headboxes[i][2] + self.pos[2] -- top
      temp_headbox[i][3] = self.pos[1] - self.current_headboxes[i][1] + self.sprite_size[1] -- right
      temp_headbox[i][4] = self.current_headboxes[i][4] + self.pos[2] -- bottom
    end
  end


  -- add hitbox sides to self.pos for updated sides
  if self.attacking and self.facing == 1 then
    for i = 1, #self.current_hitboxes do
      temp_hitbox[i][1] = self.current_hitboxes[i][1] + self.pos[1] -- left
      temp_hitbox[i][2] = self.current_hitboxes[i][2] + self.pos[2] -- top
      temp_hitbox[i][3] = self.current_hitboxes[i][3] + self.pos[1] -- right
      temp_hitbox[i][4] = self.current_hitboxes[i][4] + self.pos[2] -- bottometc.
    end
  elseif self.attacking and self.facing == -1 then
    for i = 1, #self.current_hitboxes do
      temp_hitbox[i][1] = self.pos[1] - self.current_hitboxes[i][3] + self.sprite_size[1] -- left
      temp_hitbox[i][2] = self.current_hitboxes[i][2] + self.pos[2] -- top
      temp_hitbox[i][3] = self.pos[1] - self.current_hitboxes[i][1] + self.sprite_size[1] -- right
      temp_hitbox[i][4] = self.current_hitboxes[i][4] + self.pos[2] -- bottom        
    end
  end
  
  self.hurtboxes = temp_hurtbox
  self.headboxes = temp_headbox
  self.hitboxes = temp_hitbox
end

function Fighter:updatePos(opp_center)
  if self.frozen == 0 then
    if self.ko then self:koRoutine() end
    if self.won then self:wonRoundRoutine() end

    -- check if headfrogged. If so, set slowdown and reduce counter
    if self.headfrogged > 0 then
      self.vel_multiple = 0.6
      self.headfrogged = self.headfrogged - 1
      if self.headfrogged == 0 then self.vel_multiple = 1.0 end
    end

    -- update position with velocity, then apply gravity if airborne, then apply inertia
    self.pos[1] = self.pos[1] + (self.vel[1] * self.vel_multiple)
    self.pos[2] = self.pos[2] + (self.vel[2] * self.vel_multiple)

    if self.in_air then self.vel[2] = self.vel[2] + (self.gravity * self.vel_multiple) end

    if not self.in_air and math.abs(self.vel[1]) > 1 and self.friction_on then
      self.vel[1] = self.vel[1] * self.friction
    elseif not self.in_air and self.vel[1] <= 1 and self.friction_on then
      self.vel[1] = 0
    end  
     
    -- check if character has landed
    if self.pos[2] + self.sprite_size[2] > screen.floor then 
      self.pos[2] = screen.floor - self.sprite_size[2]
      self:land()
    end

    -- check if character is at left or right edges of playing field
    if self.pos[1] < screen.left - self.sprite_wallspace then
      self.pos[1] = screen.left - self.sprite_wallspace
      self.hit_wall = true
    end
    if self.pos[1] + self.sprite_size[1] > screen.right + self.sprite_wallspace then
      self.pos[1] = screen.right - self.sprite_size[1] + self.sprite_wallspace
      self.hit_wall = true
    end

    -- get opponent's horizontal center point, in order to adjust facing
    self.opp_center = opp_center
    self.my_center = self.pos[1] + 0.5 * self.sprite_size[1]

    self:fix_Facing()
    self:updateBoxes()

    -- update image if falling
    if self.in_air and self.vel[2] > 0 and not self.attacking and not self.ko then
      self:updateImage(2)
    end 
    
    -- code to handle super meter on/off
    if self.super == 96 then
      self.super_on = true
      self.vel_multiple = self.vel_multiple_super
      -- extra code for camera zoom in on character
      p1:setFrozen(30)
      p2:setFrozen(30)
      -- extra code for background palette greying out
    end
    if self.super_on and not (self.ko or self.won) then self.super = self.super - self.super_drainspeed end
    if self.super <= 0 then
      self.super_on = false
      self.vel_multipler = 1.0
    end
    self:extraStuff() -- any character-specific routines
    return self.pos
  elseif self.frozen > 0 then
    self.frozen = self.frozen - 1
  end
end

function Fighter:extraStuff()
--[[ Replace with character-specific states
  if self.waiting > 0 then
    self.waiting = self.waiting - 1
    if self.waiting == 0 and self.waiting_state == "Jump" then
      self.waiting_state = ""
      self:jump(0, 12)
      playSFX1(self.jump_sfx)
    end
    if self.waiting == 0 and self.waiting_state == "Attack" then 
      self.waiting_state = ""
      self:attack(6, 8) end
      playSFX1(self.attack_sfx)
    end
    if self.waiting == 0 and self.waiting_state == "Kickback" then
      self.waiting_state = ""
      self:kickback(-6, 6)
      playSFX1(self.jump_sfx)
    end
  end
--]]
end

--[[---------------------------------------------------------------------------
                                      KONRAD 
-----------------------------------------------------------------------------]]                            

Konrad = class('Konrad', Fighter)
function Konrad:initialize(init_facing)
  Fighter.initialize(self, init_facing)
  self.fighter_name = "Konrad"
  self.icon = love.graphics.newImage('images/KonradIcon.png')
  self.win_portrait = love.graphics.newImage('images/KonradPortrait.png')
  self.win_quote = "You have been defeated by Konrad the talking frog with a cape who plays poker."
  self.image = love.graphics.newImage('images/KonradTiles.png')
  self.image_size = {1200, 200}
  self.sprite_size = {200, 200}
  self.sprite_wallspace = 50 -- how many pixels to reduce when checking against stage wall
  self.default_gravity = 0.25
  self.double_jump = false
  self.sprite = love.graphics.newQuad(self.image_index * self.sprite_size[1], 0, self.sprite_size[1], self.sprite_size[2], self.image_size[1], self.image_size[2])

  if init_facing == 1 then self.start_pos[1] = screen.widthPx / 2 - (screen.widthPx / 5) - (self.sprite_size[1] / 2) -- the last item is to adjust for whitespace in image tile
  else self.start_pos[1] = screen.widthPx / 2 + (screen.widthPx / 5) - (self.sprite_size[1] / 2) end
  self.start_pos[2] = screen.heightPx - (screen.heightPx / 12) - (self.sprite_size[2] / 2)

  self.pos[1] = self.start_pos[1]
  self.pos[2] = self.start_pos[2]
  
  self.my_center = self.pos[1] + self.sprite_size[1]
  
  --lists of hitboxes and hurtboxes for the relevant sprites. format is LEFT, TOP, RIGHT, BOTTOM, relative to top left corner of sprite.
  self.hurtboxes_standing = {{69, 51, 127, 79}, {76, 85, 120, 101}, {70, 105, 129, 142}, {75, 143, 124, 172}, {82, 173, 120, 190}}
  self.hurtboxes_jumping  = {{69, 51, 127, 79}, {76, 85, 120, 101}, {70, 105, 129, 142}, {75, 143, 124, 172}, {82, 173, 120, 190}}
  self.hurtboxes_falling = {{69, 51, 127, 79}, {76, 85, 120, 101}, {70, 105, 129, 142}, {75, 143, 124, 172}, {82, 173, 120, 190}}
  self.hurtboxes_attacking  = {{67, 35, 108, 54}, {75, 55, 104, 103}, {68, 104, 91, 135}, {100, 105, 114, 136}, {111, 137, 128, 157}, {125, 158, 138, 183}}
  self.hurtboxes_kickback  = {{67, 41, 128, 64}, {70, 65, 110, 165}, {72, 166, 111, 182}}
  self.hurtboxes_ko  = {{0, 0, 0, 0}}

  self.headboxes_standing = {{78, 33, 116, 50}, {83, 16, 114, 33}}
  self.headboxes_jumping  = {{78, 33, 116, 50}, {83, 16, 114, 33}}
  self.headboxes_falling = {{78, 33, 116, 50}, {83, 16, 114, 33}}
  self.headboxes_attacking  = {{66, 9, 96, 34}}
  self.headboxes_kickback  = {{83, 14, 119, 40}}
  self.headboxes_ko  = {{0, 0, 0, 0}}

  self.hitboxes_attacking = {{119, 166, 135, 183}}

  self.current_hurtboxes = self.hurtboxes_standing
  self.current_headboxes = self.headboxes_standing
  self.current_hitboxes = self.hitboxes_attacking

  -- sound effects
  self.jump_sfx = "KonradJump.mp3"
  self.jump2_sfx = "KonradJump2.mp3"
  self.attack_sfx = "KonradAttack.mp3"
  self.got_hit_sfx = "KonradKO.mp3"
  self.hit_sound_sfx = "Potatoes.mp3"
  self.ground_special_sfx = "KonradGroundSpecial.mp3"
  self.air_special_sfx = "KonradAirSpecial.mp3"

end


  function Konrad:jump_key_press()
    -- only jump if not already in air
    if not self.in_air then
      self.waiting = 3
      self.waiting_state = "Jump"
    elseif not self.attacking and not self.double_jump then
      self.waiting = 3
      self.waiting_state = "DoubleJump"
      self.double_jump = true
    end
    Fighter.jump_key_press(self) -- check for special move
  end

  function Konrad:attack_key_press()
    -- attack if in air and not already attacking and either: >50 above floor, or landing and >30 above.
    if self.in_air and not self.attacking and 
      (self.pos[2] + self.sprite_size[2] < screen.floor - 50 or
      (self.vel[2] > 0 and self.pos[2] + self.sprite_size[2] < screen.floor - 30)) then
        self.waiting = 3
        self.waiting_state = "Attack"
    -- if on ground, kickback
    elseif not self.in_air then
      self.waiting = 3
      self.waiting_state = "Kickback"
    end
    Fighter.attack_key_press(self) -- check for special move
  end

  function Konrad:air_special()
    if self.super >= 16 and not self.attacking and not self.super_on and not self.specialing then
      self.super = self.super - 16
      self.waiting_state = ""
      self.specialing = true
      playSFX1(self.air_special_sfx)
      self:attack(10, 12)
    end
  end

  function Konrad:ground_special()
    if self.super >= 16 and not self.super_on and not self.specialing then
      self.super = self.super - 16
      self.waiting_state = ""
      self.specialing = true
      playSFX1(self.ground_special_sfx)
      self:jump(0, 24, 1.0)
    end
  end

  function Konrad:jump(h_vel, v_vel, gravity)
    self.in_air = true
    self.gravity = gravity
    self.vel = {h_vel * self.facing, -v_vel}
    self:updateImage(1)
    self.current_hurtboxes = self.hurtboxes_jumping
    self.current_headboxes = self.headboxes_jumping
  end


  function Konrad:land() -- called when character lands on floor
    self.in_air = false
    self.attacking = false
    self.specialing = false
    self.double_jump = false
    if not self.ko then
      self.vel = {0, 0}
      self:updateImage(0)
      self.current_hurtboxes = self.hurtboxes_standing
      self.current_headboxes = self.headboxes_standing
    end
  end

  function Konrad:extraStuff()
    if self.waiting > 0 then
      self.waiting = self.waiting - 1
      if self.waiting == 0 and self.waiting_state == "Jump" then
        self.waiting_state = ""
        self:jump(0, 12, self.default_gravity)
        playSFX1(self.jump_sfx)
      --[[elseif self.waiting == 0 and self.waiting_state == "Jump" and self.super_on then
        self.waiting_state = ""
        self:jump(0, 18, 0.5)
        playSFX1(self.jump_sfx)--]]
      end
      if self.waiting == 0 and self.waiting_state == "DoubleJump" then
        self.waiting_state = ""
        self:jump(4, 4, self.default_gravity)
        playSFX1(self.jump_sfx)
      --[[elseif self.waiting == 0 and self.waiting_state == "DoubleJump" and self.super_on then
        self.waiting_state = ""
        self:jump(6, 6, 0.4)
        playSFX1(self.jump_sfx)--]]
      end
      if self.waiting == 0 and self.waiting_state == "Attack" then 
        self.waiting_state = ""
        self:attack(6, 8)
        playSFX1(self.attack_sfx)
      --[[elseif self.waiting == 0 and self.waiting_state == "Attack" and self.super_on then 
        self.waiting_state = ""
        self:attack(7.8, 10.4)
        playSFX1(self.attack_sfx)--]]
      end
      if self.waiting == 0 and self.waiting_state == "Kickback" then
        self.waiting_state = ""
        self:kickback(-6, 6)
        playSFX1(self.jump_sfx)
      --[[elseif self.waiting == 0 and self.waiting_state == "Kickback" and self.super_on then
        self.waiting_state = ""
        self:kickback(-9, 6)
        playSFX1(self.jump_sfx)-]]
      end
    end
  end


--[[---------------------------------------------------------------------------
                                MUSTACHIOED JEAN
-----------------------------------------------------------------------------]]   

Jean = class('Jean', Fighter)
function Jean:initialize(init_facing)
  Fighter.initialize(self, init_facing)
  self.icon = love.graphics.newImage('images/JeanIcon.png')
  self.win_portrait = love.graphics.newImage('images/JeanPortrait.png')
  self.win_quote = 'You must defeat "Wampire" to stand a chance.'
  self.fighter_name = "Mustachioed Jean"
  self.image = love.graphics.newImage('images/JeanTiles.png')
  self.image_size = {1200, 200}
  self.vel_multiple_super = 1.2
  self.sprite_size = {150, 200}
  self.default_gravity = 0.35
  self.sprite_wallspace = 25 -- how many pixels to reduce when checking against stage wall

  self.sprite = love.graphics.newQuad(self.image_index * self.sprite_size[1], 0, self.sprite_size[1], self.sprite_size[2], self.image_size[1], self.image_size[2])
  self.my_center = self.pos[1] + self.sprite_size[1]
  self.dandy = false
  self.pilebunk_ok = false
  self.pilebunking = false
  
  if init_facing == 1 then self.start_pos[1] = screen.widthPx / 2 - (screen.widthPx / 5) - (self.sprite_size[1] / 2)
  else self.start_pos[1] = screen.widthPx / 2 + (screen.widthPx / 5) - (self.sprite_size[1] / 2) end
  self.start_pos[2] = screen.heightPx - (screen.heightPx / 12) - self.sprite_size[2] 

  self.pos[1] = self.start_pos[1]
  self.pos[2] = self.start_pos[2]
  
  self.sprite = love.graphics.newQuad(self.image_index * self.sprite_size[1], 0, self.sprite_size[1], self.sprite_size[2], self.image_size[1], self.image_size[2])
  self.my_center = self.pos[1] + self.sprite_size[1]

  -- sound effects
  self.jump_sfx = "JeanJump.mp3"
  self.attack_sfx = "JeanAttack.mp3"
  self.got_hit_sfx = "JeanKO.mp3"
  self.hit_sound_sfx = "Potatoes.mp3"
  self.dandy_sfx = "JeanDandy.mp3"
  self.pilebunker_sfx = "JeanBunker.mp3"
  self.ground_special_sfx = "JeanGroundSpecial.mp3"
  self.air_special_sfx = "JeanAirSpecial.mp3"

  --lists of hitboxes and hurtboxes for the relevant sprites. format is LEFT, TOP, RIGHT, BOTTOM, relative to top left corner of sprite.
  self.hurtboxes_standing = {{44, 51, 102, 79}, {51, 85, 95, 101}, {45, 105, 104, 142}, {50, 143, 99, 172}, {57, 173, 95, 190}}
  self.hurtboxes_jumping  = {{44, 51, 102, 79}, {51, 85, 95, 101}, {45, 105, 104, 142}, {50, 143, 99, 172}, {57, 173, 95, 190}}
  self.hurtboxes_falling = {{44, 51, 102, 79}, {51, 85, 95, 101}, {45, 105, 104, 142}, {50, 143, 99, 172}, {57, 173, 95, 190}}
  self.hurtboxes_attacking  = {{10, 26, 58, 69}, {61, 58, 77, 69}, {31, 72, 83, 109}, {42, 110, 93, 126}, {61, 129, 116, 149}, {118, 138, 131, 149}, {62, 151, 145, 172}}
  self.hurtboxes_dandy  = {{15, 82, 45, 129}, {24, 131, 61, 151}, {62, 142, 73, 151}, {33, 152, 82, 166}, {47, 167, 95, 186}}
  self.hurtboxes_ko  = {{0, 0, 0, 0,}}
  self.hurtboxes_pilebunker = {{17, 68, 71, 137}, {73, 128, 100, 137}, {42, 140, 108, 187}, {110, 152, 118, 187}}
  self.hurtboxes_pilebunkerB = {{17, 68, 71, 137}, {73, 128, 83, 137}, {42, 140, 98, 187}, {100, 165, 113, 180}}

  self.headboxes_standing = {{53, 33, 95, 50}, {58, 16, 89, 33}}
  self.headboxes_jumping  = {{53, 33, 95, 50}, {58, 16, 89, 33}}
  self.headboxes_falling = {{53, 33, 95, 50}, {58, 16, 89, 33}}
  self.headboxes_attacking  = {{7, 9, 35, 23}}
  self.headboxes_dandy  = {{11, 4, 37, 76}}
  self.headboxes_ko  = {{0, 0, 0, 0,}}
  self.headboxes_pilebunker = {{6, 32, 37, 71}}
  self.headboxes_pilebunkerB = {{15, 32, 46, 71}}

  self.hitboxes_attacking = {{130, 154, 147, 172}}
  self.hitboxes_pilebunker = {{86, 85, 148, 92}}

  self.current_hurtboxes = self.hurtboxes_standing
  self.current_headboxes = self.headboxes_standing
  self.current_hitboxes = self.hitboxes_attacking

  
end

  function Jean:attack_key_press()
    -- attack if in air and not already attacking.
    if self.in_air and not self.attacking and 
      (self.pos[2] + self.sprite_size[2] < screen.floor - 50 or
      (self.vel[2] > 0 and self.pos[2] + self.sprite_size[2] < screen.floor - 30)) then
        self.waiting = 3
        self.waiting_state = "Attack"
    -- dandy step replaces kickback, only do if in neutral state
    elseif not self.in_air and not self.dandy and not self.pilebunking then
      self.waiting = 3
      self.waiting_state = "Dandy"
    -- pilebunk only if allowed conditions met
    elseif not self.in_air and self.dandy and self.pilebunk_ok then
      self.waiting = 3
      self.waiting_state = "Pilebunker"
    end  
    Fighter.attack_key_press(self) -- check for special move
  end

  function Jean:jump_key_press()
    -- only jump if not already in air
    if not self.in_air and not self.dandy and not self.pilebunking then
      self.waiting = 3
      self.waiting_state = "Jump"
    end
    Fighter.jump_key_press(self) -- check for special move
  end

  function Jean:attack(h_vel, v_vel)
    self.vel = {h_vel * self.facing, v_vel}
    self.attacking = true
    self:updateImage(4)
    self.gravity = 0
    self.current_hurtboxes = self.hurtboxes_attacking
    self.current_headboxes = self.headboxes_attacking    
    self.current_hitboxes = self.hitboxes_attacking
    if self.super < 96 and not self.super_on then 
      self.super = math.min(self.super + 8, 96)
      if self.super == 96 then playSFX1(super_sfx) end
    end
  end


  function Jean:dandyStep(h_vel)
    -- self.dandy is a backstep
    self.dandy = true
    self.vel[1] = h_vel * self.facing
    self:updateImage(3)
    self.current_hurtboxes = self.hurtboxes_dandy
    self.current_headboxes = self.headboxes_dandy    
    self.friction_on = false
    if self.super < 96 and not self.super_on then 
      self.super = math.min(self.super + 4, 96)
      if self.super == 96 then playSFX1(super_sfx) end
    end
  end

  function Jean:pilebunk(h_vel)
    self.pilebunk_ok = false
    self.dandy = false
    self.pilebunking = true -- to prevent dandy step or pilebunker while pilebunking
    self.attacking = true -- needed to activate hitboxes
    self.hit_type = "Wallsplat"

    self.vel[1] = h_vel * self.facing
    self:updateImage(6)
    self.current_hurtboxes = self.hurtboxes_pilebunker
    self.current_headboxes = self.headboxes_pilebunker    
    self.current_hitboxes = self.hitboxes_pilebunker
    if self.super < 96 and not self.super_on then 
      self.super = math.min(self.super + 16, 96)
      if self.super == 96 then playSFX1(super_sfx) end
    end
  end

  function Jean:air_special()
    if self.super_on and not self.specialing then
      self.waiting_state = ""
      self.specialing = true
      playSFX1(self.air_special_sfx)
      self:jump(0, -30)
    elseif self.super >= 8 and not self.attacking and not self.specialing then
      self.super = self.super - 8
      self.waiting_state = ""
      self.specialing = true
      playSFX1(self.air_special_sfx)
      self:jump(0, -30)
    end
  end    

  function Jean:ground_special()
    if self.super_on and (self.dandy or self.pilebunking) and math.abs(self.vel[1]) < 18 then
      self.waiting_state = ""
      self.hit_type = ""
      playSFX1(self.ground_special_sfx)
      self:land()
      p1:setFrozen(15)
      p2:setFrozen(15)
    elseif self.super >= 16 and (self.dandy or self.pilebunking) and math.abs(self.vel[1]) < 18 then
      self.super = self.super - 16
      self.waiting_state = ""
      playSFX1(self.ground_special_sfx)
      self:land()
      p1:setFrozen(15)
      p2:setFrozen(15)
    end
  end

  function Jean:extraStuff()
    if self.dandy or self.pilebunking then self.vel[1] = self.vel[1] * 0.8 end -- custom friction
    -- during dandy step's slowing end part, allow pilebunker
    if self.dandy and math.abs(self.vel[1]) >= 0.1 and math.abs(self.vel[1]) < 3 then
      self.pilebunk_ok = true
    else self.pilebunk_ok = false 
    end 
    
    -- when dandy step is almost stopped, return to neutral
    if self.dandy and math.abs(self.vel[1]) < 0.02 then
      self.dandy = false
      self.pilebunk_ok = false
      self.friction_on = false
      self.vel[1] = 0
      self:updateImage(0)
      self.current_hurtboxes = self.hurtboxes_standing
      self.current_headboxes = self.headboxes_standing      
    end

    -- stop pilebunking, and change to recovery frames
    if self.pilebunking and math.abs(self.vel[1]) >= 0.001 and math.abs(self.vel[1]) < 1 then
      self.attacking = false
      self.hit_type = ""
      self:updateImage(7)
      self.current_hurtboxes = self.hurtboxes_pilebunkerB
      self.current_headboxes = self.headboxes_pilebunkerB      
    end

    -- change from recovery to neutral
    if self.pilebunking and math.abs(self.vel[1]) < 0.001 and not self.won then
      self.pilebunking = false
      self.dandy = false
      self.friction_on = false
      self.vel[1] = 0
      --self.pilebunk_ok = false
      self:updateImage(0)
      self.current_hurtboxes = self.hurtboxes_standing
      self.current_headboxes = self.headboxes_standing      
    end

    if self.waiting > 0 then
      self.waiting = self.waiting - 1
      if self.waiting == 0 and self.waiting_state == "Attack" then 
      self.waiting_state = ""
        self:attack(8, 8)
        playSFX1(self.attack_sfx)
      end
      if self.waiting == 0 and self.waiting_state == "Dandy" then
        self.waiting_state = ""
        self:dandyStep(-25)        
        playSFX1(self.dandy_sfx)
      end
      if self.waiting == 0 and self.waiting_state == "Pilebunker" then
        self.waiting_state = ""
        self:pilebunk(36)        
        playSFX1(self.pilebunker_sfx)
      end
      if self.waiting == 0 and self.waiting_state == "Jump" then
        self.waiting_state = ""
        self:jump(0, 12)
        playSFX1(self.jump_sfx)
      end      
    end


  end

function Jean:setNewRound()
  Fighter.setNewRound(self)
  self.pilebunking = false
  self.dandy = false
  self.friction_on = false
  self.hit_type = ""
end

function Jean:gotHit()
  Fighter.gotHit(self)
  self.pilebunking = false
  self.dandy = false
  self.friction_on = true
end



--[[---------------------------------------------------------------------------
                                      M. FROGSON
-----------------------------------------------------------------------------]]   

--[[

Wears M. Bison uniform, but has white face
 Kickback is replaced by moonwalk

Moonwalk: plays 4 notes from Billie Jean bassline. Changes stance. Next moonwalk plays the next 4 notes, and changes stance again

Stance changes jump height and kick angle

Special: M. Bison headstomp/devil's reverse]]


--[[---------------------------------------------------------------------------
                                      SUN BADFROG
-----------------------------------------------------------------------------]]   

--[[

Ground Special: Sunflame (Wire Sea OK)
Air Special: Riot Frog [Quick back jump, then slow horizontal forward kick]
Super: 50%, Frog Install
  [Frog Install: life counts down (same level as super meter). Lifebar changes too
  Lose round if super = 0]
]]--
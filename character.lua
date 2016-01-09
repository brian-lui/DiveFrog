local class = require 'middleclass'
local stage = require 'stage' -- for checking floor/walls
local window = require 'window'
local music = require 'music' -- background music
require 'utilities'
require 'particles'

--[[---------------------------------------------------------------------------
                                FIGHTER SUPERCLASS
-----------------------------------------------------------------------------]]   
Fighter = class('Fighter')    
function Fighter:initialize(init_player, init_foe, init_super, init_dizzy, init_score)
  --[[-------------------------------------------------------------------------
                              NO NEED TO MODIFY THESE
  ---------------------------------------------------------------------------]]
  
  dummypic = love.graphics.newImage('images/dummy.png')
  self.player = init_player 
  self.foe = init_foe
  self.frozenFrames = 90 
  self.score = init_score
  self.isInAir = false
  self.life = 280 -- 280 pixels in the life bar
  self.isKO = false
  self.hasWon = false
  self.isAttacking = false
  self.color = nil
  self.mugshotFrames = 0
  self.hit_type = {} -- passed through to gotHit()
  self.super = init_super -- max 96
  self.isSupering = false 
  self.super_drainspeed = 0.3 -- per frame 
  self.start_pos = {1, 1}
  self.pos = {1, 1} -- Top left corner of sprite
  self.vel = {0, 0}
  self.friction = 0.96 -- horizontal velocity is multiplied by this each frame
  self.isFrictionOn = false
  self.vel_multiple = 1.0
  self.recovery = 0 -- number of frames of recovery for some special moves
  self.hasHitWall = false -- Used for wallsplat and some special moves
  self.hurtboxes = {{L = 0, U = 0, R = 0, D = 0}}
  self.hitboxes = {{L = 0, U = 0, R = 0, D = 0}}
  self.waiting = 0 -- number of frames to wait. used for pre-jump frames etc.
  self.waiting_state = "" -- buffer the action that will be executed if special isn't pressed
  self.hitflag = {Mugshot = init_dizzy} -- for KO animations
  if self.hitflag.Mugshot then
    self.mugshotFrames = 240 -- add 90 frames to this, because of round start fade-in
    self.super = math.max(self.super - 24, 0)
    self.hitflag.Mugshot = false
  end

  --[[-------------------------------------------------------------------------
                            MAY NEED TO MODIFY THESE
  ---------------------------------------------------------------------------]]
  self.fighter_name = "Dummy"
  self.win_quote = "Win Quote"
  -- images
  self.icon = dummypic -- corner portrait icon
  self.win_portrait = dummypic -- win stage large portrait
  self.stage_background = dummypic
  self.image = dummypic -- Entire tiled image
  self.image_size = {2, 2}
  self.image_index = 0 -- Horizontal offset starting at 0
  self.sprite_size = {1, 1}
  self.sprite_wallspace = 0 -- how many pixels to reduce when checking against stage wall
  
  -- character variables
  self.default_gravity = 0.3
  self.vel_multiple_super = 1.4 -- default is 1.4 for Frog Factor, 0.7 for Mugshotted

  -- hitboxes
  self.hurtboxes_standing = {{L = 0, U = 0, R = 0, D = 0, Flag1 = "Mugshot"}}
  self.hurtboxes_jumping  = {{L = 0, U = 0, R = 0, D = 0}}
  self.hurtboxes_falling = {{L = 0, U = 0, R = 0, D = 0}}
  self.hurtboxes_attacking  = {{L = 0, U = 0, R = 0, D = 0}}
  self.hurtboxes_kickback  = {{L = 0, U = 0, R = 0, D = 0}}
  self.hurtboxes_ko  = {{L = 0, U = 0, R = 0, D = 0}}
  self.hitboxes_neutral = {{L = 0, U = 0, R = 0, D = 0}}
  self.hitboxes_attacking = {{L = 0, U = 0, R = 0, D = 0}}

  -- sound effects
  self.BGM = "dummy.ogg"
  self.jump_sfx = "dummy.ogg"
  self.attack_sfx = "dummy.ogg"
  self.got_hit_sfx = "dummy.ogg"
  self.hit_sound_sfx = "dummy.ogg"
  self.ground_special_sfx = "dummy.ogg"
  self.air_special_sfx = "dummy.ogg"
end

function Fighter:init2(init_player, init_foe, init_super, init_dizzy, init_score)
  -- Run this at the end of each character's init
  self.sprite = love.graphics.newQuad(self.image_index * self.sprite_size[1], 0, self.sprite_size[1], self.sprite_size[2], self.image_size[1], self.image_size[2])
  if init_player == 1 then 
    self.facing = 1
    self.shift = 0
    self.shift_amount = 0
  elseif init_player == 2 then
    self.facing = -1
    self.shift = 1
    self.shift_amount = self.sprite_size[1]
  end
  self.start_pos[1] = stage.center - (self.facing * window.width / 5) - (self.sprite_size[1] / 2)
  self.start_pos[2] = stage.floor - self.sprite_size[2]
  self.gravity = self.default_gravity
  self.current_hurtboxes = self.hurtboxes_standing
  self.current_hitboxes = self.hitboxes_attacking
  self.pos[1] = self.start_pos[1]
  self.pos[2] = self.start_pos[2]
  self.center = self.pos[1] + 0.5 * self.sprite_size[1]
  self.width = self.sprite_size[1]
  self.height = self.sprite_size[2]
  self.h_mid = self.sprite_size[1] / 2
  self.v_mid = self.sprite_size[2] / 2
end

function Fighter:jump_key_press()
  if not self.isInAir and self:getNeutral() then
    self.waiting = 3
    self.waiting_state = "Jump"
  end
  -- check special move
  local both_keys_down = false
  for bufferframe = 0, 2 do
    if self.player == 1 then
      local p1_frame_attack = keybuffer[frame - bufferframe][2]
      local p1_prev_frame_attack = keybuffer[frame - bufferframe - 1][2]
      if p1_frame_attack and not p1_prev_frame_attack then both_keys_down = true end
    elseif self.player == 2 then
      local p2_frame_attack = keybuffer[frame - bufferframe][4]
      local p2_prev_frame_attack = keybuffer[frame - bufferframe - 1][4]
      if p2_frame_attack and not p2_prev_frame_attack then both_keys_down = true end
    end
  end
  if both_keys_down and self.isInAir then
    self:air_special()
  elseif both_keys_down and not self.isInAir then
    self:ground_special()
  end
end

function Fighter:attack_key_press()
  -- check special move
  local both_keys_down = false

  for bufferframe = 0, 2 do
    if self.player == 1 then
      local p1_frame_jump = keybuffer[frame - bufferframe][1]
      local p1_prev_frame_jump = keybuffer[frame - bufferframe - 1][1]
      if p1_frame_jump and not p1_prev_frame_jump then both_keys_down = true end
    elseif self.player == 2 then
      local p2_frame_jump = keybuffer[frame - bufferframe][3]
      local p2_prev_frame_jump = keybuffer[frame - bufferframe - 1][3]
      if p2_frame_jump and not p2_prev_frame_jump then both_keys_down = true end
    end      
  end

  if both_keys_down and self.isInAir then
    self:air_special()
  elseif both_keys_down and not self.isInAir then
    self:ground_special()
  end

  --[[ Default attack action. Replace with character-specific attack/kickback actions
  
  -- attack if in air and not already attacking and going up and more than 50 pixels above the ground.
  if self.isInAir and not selfhitflag and self.recovery == 0 and 
    (self.pos[2] + self.sprite_size[2] < stage.floor - 50 or
    (self.vel[2] > 0 and self.pos[2] + self.sprite_size[2] < stage.floor - 30)) then
      self.waiting = 3
      self.waiting_state = "Attack"
      
  -- If on ground, kickback
  elseif not self.isInAir and self.recovery == 0 then
    self.waiting = 3
    self.waiting_state = "Kickback"
  end
  --]]
end

function Fighter:jump(h_vel, v_vel)
  self.isInAir = true
  self.gravity = self.default_gravity
  self.vel = {h_vel * self.facing, -v_vel}
  self:updateImage(1)
  self.current_hurtboxes = self.hurtboxes_jumping
  JumpDust:postLoadFX(self.center,
   self.pos[2], 0, self.sprite_size[2] - JumpDust.height, self.facing)
end

function Fighter:kickback(h_vel, v_vel)
  self.isInAir = true
  self.gravity = self.default_gravity
  self.vel = {h_vel * self.facing, -v_vel}
  self:updateImage(3)
  self.current_hurtboxes = self.hurtboxes_kickback
  KickbackDust:postLoadFX(self.center,
    self.pos[2], 0, self.sprite_size[2] - KickbackDust.height, self.facing)
end

function Fighter:land()
  self.isInAir = false
  self.isAttacking = false
  self.hasHitWall = false
  if not self.isKO then
    self.vel = {0, 0}
    self:updateImage(0)
    self.current_hurtboxes = self.hurtboxes_standing
    self.current_hitboxes = self.hitboxes_neutral
  end
end

function Fighter:attack(h_vel, v_vel)
  self.vel = {h_vel * self.facing, v_vel}
  self.isAttacking = true
  self:updateImage(4)
  self.gravity = 0
  self.current_hurtboxes = self.hurtboxes_attacking
  self.current_hitboxes = self.hitboxes_attacking
  if self.super < 96 and not self.isSupering then 
    self.super = math.min(self.super + 8, 96)
    if self.super == 96 then writeSound(super_sfx) end
  end
end

function Fighter:air_special()
  if self.super >= 16 and not self.isSupering then
    self.super = self.super - 16
    self.waiting_state = ""
    writeSound(self.air_special_sfx)
  end
end

function Fighter:ground_special()
  if self.super >= 16 and not self.isSupering then
    self.super = self.super - 16
    self.waiting_state = ""
    writeSound(self.ground_special_sfx)
  end
end

function Fighter:gotHit(type_table) -- execute this one time, when character gets hit
  if type_table.Mugshot and not type_table.Projectile then
    self.hitflag.Mugshot = true
    Mugshot:postLoadFX(camera_xy[1], camera_xy[2], 400, 200, 1, 20, true)
    game.isScreenShaking = true
  end

  if type_table.Wallsplat then
    self.hitflag.Wallsplat = true
  end

  if type_table.Projectile then
    self.hitflag.Projectile = true
  end

  if type_table.Fire then
    self.hitflag.Fire = true
    self.color = {255, 0, 0, 255}
  end

  self.vel_multiple = 1.0
  self.isKO = true 
  self.isAttacking = false -- stops calling gotHit, since the hitbox check is now false
  writeSound(self.hit_sound_sfx)
end

function Fighter:gotKOed() -- keep calling this until self.isKO is false
  if frame - round_end_frame < 60 then    
    self.vel = {0, 0}
    self.gravity = 0
    if self.life > 0 then self.life = math.max(self.life - 6, 0) end
  end

  if frame - round_end_frame == 60 then
    game.isScreenShaking = false
    self.gravity = 2
    if self.facing == 1 then self.vel[1] = -10 else self.vel[1] = 10 end
    writeSound(self.got_hit_sfx) 

    if self.hitflag.Wallsplat then
      self.vel[1] = self.facing * -40
      self.vel[2] = 0
      self.pos[2] = self.pos[2] - 1
      self.gravity = 0
      self.isInAir = true
    end
  end

  if frame - round_end_frame > 60 then
    if self.hitflag.Fire then
      OnFire:postRepeatFX(self.center, self.pos[2], 0, 0, self.facing)
    end
    if self.hitflag.Wallsplat then
      if self.hasHitWall then
        self.vel[1] = -self.vel[1]
        self.vel[2] = -20
        self.isInAir = true
        self.hasHitWall = false
        self.gravity = 1
        self.isFrictionOn = true
        self:updateImage(5)
        self.current_hurtboxes = self.hurtboxes_ko
        self.current_hitboxes = self.hitboxes_neutral
        game.isScreenShaking = true
      end
      if frame % 4 == 0 then
        local i = math.floor((frame % (12 * 4)) / 4) + 1
        Explosion1:postLoadFX(self.center,
          self.pos[2],
          self.facing * (self.vel[1] + (i - 6) * 3),
          self.vel[2] + (i - 6) * 3,
          self.facing * 4, 0, true)
        Explosion2:postLoadFX(self.center,
          self.pos[2],
          self.facing * (self.vel[1] / 2 + (i - 6) * 6),
          self.vel[2] + (i - 6) * 6,
          self.facing * 3, 1, false)        
        Explosion3:postLoadFX(self.center,
          self.pos[2],
          self.facing * ((i - 6) * 10),
          self.vel[2] + (i - 6) * 10,
          self.facing * 2, 2, false)        
      end
    else
      self.isFrictionOn = true
      self:updateImage(5)
      self.current_hurtboxes = self.hurtboxes_ko
      self.current_hitboxes = self.hitboxes_neutral
    end
  end
end

function Fighter:hitOpponent() -- execute this one time, when you hit the opponent
  self.vel_multiple = 1.0
  self.hasWon = true
  self.isAttacking = false -- stops calling hitOpponent, since the hitbox check is now false
  currentBGM:pause()
  if currentBGM2:isPlaying() then currentBGM2:pause() end
end

function Fighter:victoryPose() -- keep calling this if self.hasWon is true
  if frame - round_end_frame < 60 then
    self.vel = {0, 0}
    self.gravity = 0
  end

  if frame - round_end_frame == 60 then
    if currentBGM2:isPaused() then currentBGM2:play() else currentBGM:play() end
  end

  if frame - round_end_frame > 60 then
    self.gravity = 1
    self.isAttacking = false
    if self.isInAir then
      self:updateImage(2)
    else
      self:updateImage(0)
    end
    self.current_hurtboxes = self.hurtboxes_standing 
  end
end

function Fighter:getNeutral()
  return not self.isKO and not self.isAttacking and self.recovery == 0
end
function Fighter:getCenter() return self.pos[1] + 0.5 * self.sprite_size[1] end
function Fighter:addScore() self.score = self.score + 1 end
function Fighter:setFrozen(frames) self.frozenFrames = frames end

function Fighter:updateImage(image_index)
  self.sprite = love.graphics.newQuad(image_index * self.sprite_size[1], 0,
    self.sprite_size[1], self.sprite_size[2],
    self.image_size[1], self.image_size[2])
end

function Fighter:fixFacing() -- change character facing if over center of opponent
  self.center = self:getCenter()
  self.foe.center = self.foe:getCenter()
  if self:getNeutral() and not self.isInAir then
    if self.facing == 1 and self.center > self.foe.center then
      self.facing = -1
      self.shift = 1
      self.shift_amount = self.sprite_size[1]
    elseif self.facing == -1 and self.center < self.foe.center then
      self.facing = 1
      self.shift = 0
      self.shift_amount = 0
    end
  end
end

function Fighter:updateBoxes()
  -- initialize temp variable to hold hurtbox/hitbox quads
  local temp_hurtbox = {}
  for i = 1, #self.current_hurtboxes do
    temp_hurtbox[i] = {L = 0, U = 0, R = 0, D = 0}
  end
  local temp_hitbox = {}
  for i = 1, #self.current_hitboxes do
    temp_hitbox[i] = {L = 0, U = 0, R = 0, D = 0}
  end
  -- iterate over the current hurtboxes/hitboxes list
  if self.facing == 1 then
    for i = 1, #self.current_hurtboxes do
      temp_hurtbox[i].L = self.current_hurtboxes[i].L + self.pos[1]
      temp_hurtbox[i].U = self.current_hurtboxes[i].U + self.pos[2]
      temp_hurtbox[i].R = self.current_hurtboxes[i].R + self.pos[1]
      temp_hurtbox[i].D = self.current_hurtboxes[i].D + self.pos[2]
      temp_hurtbox[i].Flag1 = self.current_hurtboxes[i].Flag1
    end
  elseif self.facing == -1 then
    for i = 1, #self.current_hurtboxes do
      temp_hurtbox[i].L = - self.current_hurtboxes[i].R + self.pos[1] + self.sprite_size[1]
      temp_hurtbox[i].U = self.current_hurtboxes[i].U + self.pos[2]
      temp_hurtbox[i].R = - self.current_hurtboxes[i].L + self.pos[1] + self.sprite_size[1]
      temp_hurtbox[i].D = self.current_hurtboxes[i].D + self.pos[2]
      temp_hurtbox[i].Flag1 = self.current_hurtboxes[i].Flag1
    end
  end

  if self.isAttacking and self.facing == 1 then
    for i = 1, #self.current_hitboxes do
      temp_hitbox[i].L = self.current_hitboxes[i].L + self.pos[1]
      temp_hitbox[i].U = self.current_hitboxes[i].U + self.pos[2]
      temp_hitbox[i].R = self.current_hitboxes[i].R + self.pos[1]
      temp_hitbox[i].D = self.current_hitboxes[i].D + self.pos[2]
      temp_hitbox[i].Flag1 = self.current_hitboxes[i].Flag1
      temp_hitbox[i].Flag2 = self.current_hitboxes[i].Flag2
    end
  elseif self.isAttacking and self.facing == -1 then
    for i = 1, #self.current_hitboxes do
      temp_hitbox[i].L = self.pos[1] - self.current_hitboxes[i].R + self.sprite_size[1]
      temp_hitbox[i].U = self.current_hitboxes[i].U + self.pos[2]
      temp_hitbox[i].R = self.pos[1] - self.current_hitboxes[i].L + self.sprite_size[1]
      temp_hitbox[i].D = self.current_hitboxes[i].D + self.pos[2]
      temp_hitbox[i].Flag1 = self.current_hitboxes[i].Flag1
      temp_hitbox[i].Flag2 = self.current_hitboxes[i].Flag2
    end
  end

  self.hurtboxes = temp_hurtbox
  self.hitboxes = temp_hitbox
end

function Fighter:updatePos()
  if self.mugshotFrames > 0 then
    self.vel_multiple = 0.7
    self.mugshotFrames = self.mugshotFrames - 1
    Dizzy:postRepeatFX(self.center, self.pos[2], 0, 0, self.facing)
    if self.mugshotFrames == 0 then self.vel_multiple = 1.0 end
  end

  if self.frozenFrames == 0 then
    if self.isKO then self:gotKOed() end
    if self.hasWon then self:victoryPose() end

    -- reduce recovery time
    if self.recovery > 0 then
      self.recovery = math.max(0, self.recovery - 1)
      if self.recovery == 0 and self.isInAir then
        self.current_hurtboxes = self.hurtboxes_falling
        self:updateImage(2)
      elseif self.recovery == 0 and not self.isInAir then
        self:land()
      end
    end

    -- update position with velocity, then apply gravity if airborne, then apply inertia
    self.pos[1] = self.pos[1] + (self.vel[1] * self.vel_multiple)
    self.pos[2] = self.pos[2] + (self.vel[2] * self.vel_multiple)

    if self.isInAir then self.vel[2] = self.vel[2] + (self.gravity * self.vel_multiple) end

    if math.abs(self.vel[1]) > 0.1 and self.isFrictionOn then
      self.vel[1] = self.vel[1] * self.friction
    elseif self.vel[1] <= 0.1 and self.isFrictionOn then
      self.vel[1] = 0
    end  
     
    -- check if character has landed
    if self.pos[2] + self.sprite_size[2] > stage.floor then 
      self.pos[2] = stage.floor - self.sprite_size[2]
      self:land()
    end

    -- check if character is at left or right edges of playing field
    if self.pos[1] < leftEdge() - self.sprite_wallspace then
      self.pos[1] = leftEdge() - self.sprite_wallspace
      self.hasHitWall = true
    end
    if self.pos[1] + self.sprite_size[1] > rightEdge() + self.sprite_wallspace then
      self.pos[1] = rightEdge() - self.sprite_size[1] + self.sprite_wallspace
      self.hasHitWall = true
    end

    self:fixFacing()
    self:updateBoxes()

    -- update image if falling
    if self.isInAir and self.vel[2] > 0 and not self.isAttacking and not self.isKO then
      self.current_hurtboxes = self.hurtboxes_falling
      self:updateImage(2)
    end 
    
    self:updateSuper() -- Frog Factor related logic
    self:stateCheck() -- check for button presses and change actions
    self:extraStuff() -- any character-specific routines
    return self.pos
  elseif self.frozenFrames > 0 then
    self.frozenFrames = self.frozenFrames - 1
  end
end

function Fighter:updateSuper()
  if self.super >= 96 then
    self.super = 95.999
    writeSound(super_sfx)
    self.isSupering = true
    self.vel_multiple = self.vel_multiple_super
    game.superfreeze_time = 60
    game.superfreeze_player = self
    p1:setFrozen(60)
    p2:setFrozen(60)
  end

  if self.isSupering and not (self.isKO or self.hasWon) then
    self.super = self.super - self.super_drainspeed
    -- after-images
    local shadow = AfterImage(self.image, self.image_size, self.sprite_size, 1)
    shadow:loadFX(self.pos[1], self.pos[2], self.sprite, self.facing, self.shift_amount)
  end

  if self.super <= 0 then -- turn off Frog Factor
    self.isSupering = false
    self.vel_multiple = 1.0
  end  
end

function Fighter:stateCheck()
  --[[ Replace with character-specific states
  if self.waiting > 0 then
    self.waiting = self.waiting - 1
    if self.waiting == 0 and self.waiting_state == "Jump" then
      self.waiting_state = ""
      self:jump(0, 12)
      writeSound(self.jump_sfx)
    end
    if self.waiting == 0 and self.waiting_state == "Attack" then 
      self.waiting_state = ""
      self:attack(6, 8)
      writeSound(self.attack_sfx)
    end
    if self.waiting == 0 and self.waiting_state == "Kickback" then
      self.waiting_state = ""
      self:kickback(-6, 6)
      writeSound(self.jump_sfx)
    end
  end
--]]
end

function Fighter:extraStuff()
  -- character-specific routines
end

--[[---------------------------------------------------------------------------
                                      BEDFROG
-----------------------------------------------------------------------------]]   

--[[A large sprite character to test the particle offsets to make sure that they're coded well
Air Special: Has Vlad's jetpack, which costs a lot of meter to use
Ground Special: Bedman's Deja Vu, he can kick from the same place as the last kick

Idea for win quote: "Go home and be a family frog."
]]
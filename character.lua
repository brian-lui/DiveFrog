local class = require 'middleclass'
local stage = require 'stage' -- for checking floor/walls
local window = require 'window'
local buttons = require 'controls' -- mapping of keyboard controls
local music = require 'music' -- background music
require 'utilities'
require 'particles'

--[[---------------------------------------------------------------------------
                                FIGHTER SUPERCLASS
-----------------------------------------------------------------------------]]   

Fighter = class('Fighter')    
function Fighter:initialize(init_player, init_super, init_dizzy, init_score)
  --[[-------------------------------------------------------------------------
                              NO NEED TO MODIFY THESE
  ---------------------------------------------------------------------------]]
  
  dummypic = love.graphics.newImage('images/dummy.png')
  self.player = init_player 
  self.frozen = 0 -- only update sprite if this is 0. Used for e.g. super freeze
  self.score = init_score
  self.in_air = false
  self.life = 280 -- 280 pixels in the life bar
  self.ko = false
  self.won = false
  self.attacking = false
  self.mugshotted = 0 -- frames the character is mugshotted for
  self.hit_type = {} -- type of hit, passed through to gotHit(). E.g. for wall splat
  self.super = init_super -- max 96
  self.super_on = false 
  self.super_drainspeed = 0.2 -- per frame 
  self.start_pos = {1, 1}
  self.pos = {1, 1} -- Top left corner of sprite
  self.vel = {0, 0}
  self.friction = 0.95 -- horizontal velocity is multiplied by this each frame
  self.friction_on = false
  self.vel_multiple = 1.0
  self.hit_wall = false -- Used for wallsplat and some special moves
  self.hurtboxes = {{L = 0, U = 0, R = 0, D = 0}}
  self.hitboxes = {{L = 0, U = 0, R = 0, D = 0}}
  self.opp_center = stage.center -- center of opponent's sprite
  self.waiting = 0 -- number of frames to wait. used for pre-jump frames etc.
  self.waiting_state = "" -- buffer the action that will be executed if special isn't pressed
  self.hit_flag = {Mugshot = init_dizzy} -- for KO animations
  self.things = {} -- projectiles, etc.
  self.things.attacking = false
  if self.hit_flag.Mugshot then
    self.mugshotted = 240 -- add 90 frames to this, because of round start fade-in
    self.super = math.max(self.super - 24, 0)
    self.hit_flag.Mugshot = false
  end

  --[[-------------------------------------------------------------------------
                            MAY NEED TO MODIFY THESE
  ---------------------------------------------------------------------------]]

  -- images
  self.icon = dummypic -- corner portrait icon
  self.win_portrait = dummypic -- win stage large portrait
  self.win_quote = "Win Quote"
  self.stage_background = dummypic
  self.image = dummypic -- Entire tiled image
  self.image_size = {2, 2}
  self.image_index = 0 -- Horizontal offset starting at 0
  self.sprite_size = {1, 1}
  self.sprite_wallspace = 0 -- how many pixels to reduce when checking against stage wall
  
  -- character variables
  self.default_gravity = 0.25
  self.vel_multiple_super = 1.4 -- default is 1.4 for Frog Factor, 0.7 for Mugshotted

  -- hitboxes. Flags must correspond to a particle class.
  self.hurtboxes_standing = {{L = 0, U = 0, R = 0, D = 0, Flag1 = Mugshot}}
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

  -- Copy the below stuff after the new initialization variables for each new character
  self.sprite = love.graphics.newQuad(self.image_index * self.sprite_size[1], 0, self.sprite_size[1], self.sprite_size[2], self.image_size[1], self.image_size[2])
  if init_player == 1 then self.facing = 1 elseif init_player == 2 then self.facing = -1 end
  self.start_pos[1] = stage.center - (self.facing * window.width / 5) - (self.sprite_size[1] / 2)
  self.start_pos[2] = stage.floor - self.sprite_size[2]
  self.my_center = self.pos[1] + self.sprite_size[1]
  self.gravity = self.default_gravity
  self.current_hurtboxes = self.hurtboxes_standing
  self.current_hitboxes = self.hitboxes_attacking
end

  function Fighter:jump_key_press()
    if not self.in_air then
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
    if both_keys_down and self.in_air then
      self:air_special()
    elseif both_keys_down and not self.in_air then
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

    if both_keys_down and self.in_air then
      self:air_special()
    elseif both_keys_down and not self.in_air then
      self:ground_special()
    end

    --[[ Default attack action. Replace with character-specific attack/kickback actions
    
    -- attack if in air and not already attacking and going up and more than 50 pixels above the ground.
    if self.in_air and not self.attacking and 
      (self.pos[2] + self.sprite_size[2] < stage.floor - 50 or
      (self.vel[2] > 0 and self.pos[2] + self.sprite_size[2] < stage.floor - 30)) then
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
    local shift = (self.facing - 1) * -0.5 -- 1 -> 0; -1 -> 1
    JumpDust:loadFX(self.pos[1] + self.sprite_size[1] / 2, self.pos[2] + self.sprite_size[2] - 40, self.facing, shift)
  end

  function Fighter:kickback(h_vel, v_vel)
    self.in_air = true
    self.gravity = self.default_gravity
    self.vel = {h_vel * self.facing, -v_vel}
    self:updateImage(3)
    self.current_hurtboxes = self.hurtboxes_kickback
    local shift = (self.facing - 1) * -0.5 -- 1 -> 0; -1 -> 1
    KickbackDust:loadFX(self.pos[1] + self.sprite_size[1] / 2, self.pos[2] + self.sprite_size[2] - 54, self.facing, shift)
  end

  function Fighter:land()
    self.in_air = false
    self.attacking = false
    self.hit_wall = false
    if not self.ko then
      self.vel = {0, 0}
      self:updateImage(0)
      self.current_hurtboxes = self.hurtboxes_standing
      self.current_hitboxes = self.hitboxes_neutral
    end
  end

  function Fighter:attack(h_vel, v_vel)
    self.vel = {h_vel * self.facing, v_vel}
    self.attacking = true
    self:updateImage(4)
    self.gravity = 0
    self.current_hurtboxes = self.hurtboxes_attacking
    self.current_hitboxes = self.hitboxes_attacking
    if self.super < 96 and not self.super_on then 
      self.super = math.min(self.super + 8, 96)
      if self.super == 96 then playSFX1(super_sfx) end
    end
  end

  function Fighter:air_special()
    if self.super >= 16 and not self.super_on then
      self.super = self.super - 16
      self.waiting_state = ""
      playSFX1(self.air_special_sfx)
    end
  end

  function Fighter:ground_special()
    if self.super >= 16 and not self.super_on then
      self.super = self.super - 16
      self.waiting_state = ""
      playSFX1(self.ground_special_sfx)
    end
  end

function Fighter:gotHit(type_table) -- execute this one time, when character gets hit
  if type_table[Mugshot] then
    Mugshot:loadFX()
    self.hit_flag.Mugshot = true
  end

  if type_table[Wallsplat] then
    self.hit_flag.Wallsplat = true
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
    if self.life > 0 then self.life = math.max(self.life - 6, 0) end
  end

  if frame - round_end_frame == 30 and self.hit_flag.Mugshot then playSFX1(mugshot_sfx) end -- put into soundbuffer sometime
  if frame - round_end_frame == 60 then
    self.gravity = 2
    if self.facing == 1 then self.vel[1] = -10 else self.vel[1] = 10 end
    playSFX2(self.got_hit_sfx) 

    if self.hit_flag.Wallsplat then
      self.vel[1] = self.facing * -50
      self.vel[2] = -5
      self.pos[2] = self.pos[2] - 30
      self.gravity = 0.2
      self.in_air = true
    end
  end

  if frame - round_end_frame > 60 then
    self.friction_on = true
    self:updateImage(5)
    self.current_hurtboxes = self.hurtboxes_ko
    self.current_hitboxes = self.hitboxes_neutral

    if self.hit_flag.Wallsplat and self.hit_wall then
      self.vel[1] = -self.vel[1] * 0.4
      self.hit_wall = false
      Wallsplat:loadFX(self.pos[1], self.pos[2])
      playSFX2(explosion_sfx)
    end
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
  end
end

function Fighter:getSelfNeutral()
  return not self.in_air and not self.ko and not self.attacking
end
function Fighter:getPos_h() return self.pos[1] end
function Fighter:getPos_v() return self.pos[2] end
function Fighter:getSprite_Width() return self.sprite_size[1] end
function Fighter:getImage_Size() return unpack(self.image_size) end
function Fighter:get_Center() return self.pos[1] + 0.5 * self.sprite_size[1] end
function Fighter:getIcon_Width() return self.icon:getWidth() end
function Fighter:getFrozen() if self.frozen > 0 then return true else return false end end
function Fighter:addScore() self.score = self.score + 1 end
function Fighter:setPos(pos) self.pos = {pos[1], pos[2]} end
function Fighter:setFacing(facing) self.facing = facing end
function Fighter:setFrozen(frames) self.frozen = frames end

function Fighter:updateImage(image_index)
  self.sprite = love.graphics.newQuad(image_index * self.sprite_size[1], 0, self.sprite_size[1], self.sprite_size[2], self.image_size[1], self.image_size[2])
  return self.sprite
end

function Fighter:fix_Facing() -- change character facing if over center of opponent
  if self:getSelfNeutral() then
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

  if self.attacking and self.facing == 1 then
    for i = 1, #self.current_hitboxes do
      temp_hitbox[i].L = self.current_hitboxes[i].L + self.pos[1]
      temp_hitbox[i].U = self.current_hitboxes[i].U + self.pos[2]
      temp_hitbox[i].R = self.current_hitboxes[i].R + self.pos[1]
      temp_hitbox[i].D = self.current_hitboxes[i].D + self.pos[2]
      temp_hitbox[i].Flag1 = self.current_hitboxes[i].Flag1
      temp_hitbox[i].Flag2 = self.current_hitboxes[i].Flag2

    end
  elseif self.attacking and self.facing == -1 then
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

function Fighter:updatePos(opp_center)
  if self.frozen == 0 then
    if self.ko then self:koRoutine() end
    if self.won then self:wonRoundRoutine() end

    -- check if mugshotted. If so, set slowdown and reduce counter
    if self.mugshotted > 0 then
      self.vel_multiple = 0.7
      self.mugshotted = self.mugshotted - 1
      Dizzy:loadFX(self.pos[1] + self.sprite_size[1] / 2, self.pos[2])
      if self.mugshotted == 0 then self.vel_multiple = 1.0 end
    end

    -- update position with velocity, then apply gravity if airborne, then apply inertia
    self.pos[1] = self.pos[1] + (self.vel[1] * self.vel_multiple)
    self.pos[2] = self.pos[2] + (self.vel[2] * self.vel_multiple)

    if self.in_air then self.vel[2] = self.vel[2] + (self.gravity * self.vel_multiple) end

    if math.abs(self.vel[1]) > 0.1 and self.friction_on then
      self.vel[1] = self.vel[1] * self.friction
    elseif self.vel[1] <= 0.1 and self.friction_on then
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
      self.hit_wall = true
    end
    if self.pos[1] + self.sprite_size[1] > rightEdge() + self.sprite_wallspace then
      self.pos[1] = rightEdge() - self.sprite_size[1] + self.sprite_wallspace
      self.hit_wall = true
    end

    -- get opponent's horizontal center point, in order to adjust facing
    self.opp_center = opp_center
    self.my_center = self.pos[1] + 0.5 * self.sprite_size[1]

    self:fix_Facing()
    self:updateBoxes()

    -- update image if falling
    if self.in_air and self.vel[2] > 0 and not self.attacking and not self.ko then
      self.current_hurtboxes = self.hurtboxes_standing
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

    if self.super_on and not (self.ko or self.won) then
      self.super = self.super - self.super_drainspeed
      -- after-images
      local shadow = AfterImage(self.image, self.image_size, self.sprite_size)
      local shift = 0
      if self.facing == -1 then shift = self:getSprite_Width() end
      shadow:loadFX(self.pos[1], self.pos[2], self.sprite, self.facing, shift)
    end

    if self.super <= 0 then
      self.super_on = false
      self.vel_multiple = 1.0
    end

    self:stateCheck() -- check for button presses and change actions
    self:extraStuff() -- any character-specific routines
    return self.pos
  elseif self.frozen > 0 then
    self.frozen = self.frozen - 1
  end
end

function Fighter:stateCheck()
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

function Fighter:extraStuff()
  -- character-specific routines
end

--[[---------------------------------------------------------------------------
                                      KONRAD 
-----------------------------------------------------------------------------]]                            

Konrad = class('Konrad', Fighter)
function Konrad:initialize(init_player, init_super, init_dizzy, init_score)
  Fighter.initialize(self, init_player, init_super, init_dizzy, init_score)
  self.fighter_name = "Konrad"
  self.icon = love.graphics.newImage('images/Konrad/KonradIcon.png')
  self.win_portrait = love.graphics.newImage('images/Konrad/KonradPortrait.png')
  self.win_quote = "You have been defeated by Konrad the talking frog with a cape who plays poker."
  self.stage_background = love.graphics.newImage('images/Konrad/KonradBackground.jpg')
  self.BGM = "KonradTheme.ogg"
  self.image = love.graphics.newImage('images/Konrad/KonradTiles.png')
  self.image_size = {1200, 200}
  self.sprite_size = {200, 200}
  self.sprite_wallspace = 50 -- how many pixels to reduce when checking against stage wall
  self.default_gravity = 0.25
  self.double_jump = false
  self.sprite = love.graphics.newQuad(self.image_index * self.sprite_size[1], 0, self.sprite_size[1], self.sprite_size[2], self.image_size[1], self.image_size[2])
  if init_player == 1 then self.facing = 1 elseif init_player == 2 then self.facing = -1 end
  self.start_pos[1] = stage.center - (self.facing * window.width / 5) - (self.sprite_size[1] / 2)
  self.start_pos[2] = stage.floor - self.sprite_size[2]

  self.pos[1] = self.start_pos[1]
  self.pos[2] = self.start_pos[2]
  
  self.my_center = self.pos[1] + self.sprite_size[1]
  
  --lists of hitboxes and hurtboxes for the relevant sprites. format is LEFT, TOP, RIGHT, BOTTOM, relative to top left corner of sprite.
  self.hurtboxes_standing = {
    {L = 78, U = 28, R = 119, D = 50, Flag1 = Mugshot},
    {L = 69, U = 51, R = 124, D = 79, Flag1 = Mugshot},
    {L = 76, U = 85, R = 120, D = 101},
    {L = 70, U = 105, R = 129, D = 142},
    {L = 75, U = 143, R = 124, D = 172},
    {L = 82, U = 173, R = 120, D = 190}}
  self.hurtboxes_jumping  = {
    {L = 78, U = 28, R = 119, D = 50, Flag1 = Mugshot},
    {L = 69, U = 51, R = 124, D = 79, Flag1 = Mugshot},
    {L = 76, U = 85, R = 120, D = 101},
    {L = 70, U = 105, R = 129, D = 142},
    {L = 75, U = 143, R = 124, D = 172},
    {L = 82, U = 173, R = 120, D = 190}}
  self.hurtboxes_falling = {
    {L = 78, U = 28, R = 119, D = 50, Flag1 = Mugshot},
    {L = 69, U = 51, R = 124, D = 79, Flag1 = Mugshot},
    {L = 76, U = 85, R = 120, D = 101},
    {L = 70, U = 105, R = 129, D = 142},
    {L = 75, U = 143, R = 124, D = 172},
    {L = 82, U = 173, R = 120, D = 190}}
  self.hurtboxes_attacking  = {
    {L = 67, U = 20, R = 109, D = 59, Flag1 = Mugshot},
    {L = 75, U = 60, R = 104, D = 103},
    {L = 68, U = 104, R = 91, D = 135},
    {L = 100, U = 105, R = 114, D = 136},
    {L = 111, U = 137, R = 128, D = 157},
    {L = 125, U = 158, R = 138, D = 183}}
  self.hurtboxes_kickback  = {
    {L = 82, U = 25, R = 123, D = 71, Flag1 = Mugshot},
    {L = 71, U = 41, R = 128, D = 72, Flag1 = Mugshot},
    {L = 70, U = 73, R = 119, D = 165},
    {L = 72, U = 166, R = 111, D = 182}}

  self.hitboxes_attacking = {{L = 119, U = 166, R = 137, D = 183}}
  self.hitboxes_hyperkick = {{L = 119, U = 166, R = 137, D = 183, Flag1 = Fire}}

  self.current_hurtboxes = self.hurtboxes_standing
  self.current_hitboxes = self.hitboxes_attacking

  -- sound effects
  self.jump_sfx = "Konrad/KonradJump.ogg"
  self.doublejump_sfx = "Konrad/KonradDoubleJump.ogg"
  self.attack_sfx = "Konrad/KonradAttack.ogg"
  self.got_hit_sfx = "Konrad/KonradKO.ogg"
  self.hit_sound_sfx = "Potatoes.ogg"
  self.ground_special_sfx = "Konrad/KonradHyperJump.ogg"
  self.air_special_sfx = "Konrad/KonradHyperKick.ogg"

end


  function Konrad:jump_key_press()
    if self.in_air and not self.attacking and not self.double_jump then
      self.waiting = 3
      self.waiting_state = "DoubleJump"
      self.double_jump = true
    end
    Fighter.jump_key_press(self) -- check for ground jump or special move
  end

  function Konrad:attack_key_press()
    -- attack if in air and not already attacking and either: >50 above floor, or landing and >30 above.
    if self.in_air and not self.attacking and 
      (self.pos[2] + self.sprite_size[2] < stage.floor - 50 or
      (self.vel[2] > 0 and self.pos[2] + self.sprite_size[2] < stage.floor - 30)) then
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
    if self.super >= 16 and not self.attacking and not self.super_on and
    self.pos[2] + self.sprite_size[2] < stage.floor - 50 then
      self.super = self.super - 16
      self.waiting_state = ""
      playSFX1(self.air_special_sfx)
      --self:attack, but with flame flag
      self.vel = {12 * self.facing, 16}
      self.attacking = true  
      self:updateImage(4)
      self.gravity = 0
      self.current_hurtboxes = self.hurtboxes_attacking
      self.current_hitboxes = self.hitboxes_hyperkick
    end
  end

  function Konrad:ground_special()
    if self.super >= 16 and not self.super_on then
      self.super = self.super - 16
      self.waiting_state = ""
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
  end


  function Konrad:land() -- called when character lands on floor
    self.in_air = false
    self.attacking = false
    self.double_jump = false
    if not self.ko then
      self.vel = {0, 0}
      self:updateImage(0)
      self.current_hurtboxes = self.hurtboxes_standing
    end
  end

  function Konrad:stateCheck()
    if self.waiting > 0 then
      self.waiting = self.waiting - 1
      if self.waiting == 0 and self.waiting_state == "Jump" then
        self.waiting_state = ""
        self:jump(0, 12, self.default_gravity)
        playSFX1(self.jump_sfx)
        local shift = (self.facing - 1) * -0.5 -- 1 -> 0; -1 -> 1
        JumpDust:loadFX(self.pos[1] + self.sprite_size[1] / 2, self.pos[2] + self.sprite_size[2] - 40, self.facing, shift)
      end
      if self.waiting == 0 and self.waiting_state == "DoubleJump" then
        self.waiting_state = ""
        self:jump(4, 4, self.default_gravity)
        playSFX1(self.doublejump_sfx)
        local shift = (self.facing - 1) * -0.5 -- 1 -> 0; -1 -> 1
        DoubleJumpDust:loadFX(self.pos[1] + self.sprite_size[1] / 2 , self.pos[2] + self.sprite_size[2] - 40, self.facing, shift)
      end
      if self.waiting == 0 and self.waiting_state == "Attack" then 
        self.waiting_state = ""
        self:attack(6, 8)
        playSFX1(self.attack_sfx)
      end
      if self.waiting == 0 and self.waiting_state == "Kickback" then
        self.waiting_state = ""
        self:kickback(-6, 6)
        playSFX1(self.jump_sfx)
      end
    end
  end
  function Konrad:extraStuff()
    -- low quality code to check for hyperkick and apply flames
    if math.abs(self.vel[1]) == 12 and self.vel[2] == 16 then
      local shift = (self.facing - 1) * -0.5 -- 1 -> 0; -1 -> 1

      -- I hard coded the position ok. sorry
      HyperKickFlames:loadFX(self.pos[1] + (self.sprite_size[1] - self.sprite_wallspace * 2) * self.facing + 5,
       self.pos[2] + self.sprite_size[2], self.facing, shift * (self.sprite_size[1] + 80))

    end
  end


--[[---------------------------------------------------------------------------
                                MUSTACHIOED JEAN
-----------------------------------------------------------------------------]]   

Jean = class('Jean', Fighter)
function Jean:initialize(init_player, init_super, init_dizzy, init_score)
  Fighter.initialize(self, init_player, init_super, init_dizzy, init_score)
  self.icon = love.graphics.newImage('images/Jean/JeanIcon.png')
  self.win_portrait = love.graphics.newImage('images/Jean/JeanPortrait.png')
  self.win_quote = 'You must defeat "Wampire" to stand a chance.'
  self.fighter_name = "Mustachioed Jean"
  self.BGM = "JeanTheme.ogg"
  self.stage_background = love.graphics.newImage('images/Jean/JeanBackground.jpg')
  self.image = love.graphics.newImage('images/Jean/JeanTiles.png')
  self.image_size = {1200, 200}
  self.vel_multiple_super = 1.3
  self.sprite_size = {150, 200}
  self.default_gravity = 0.35
  self.sprite_wallspace = 25 -- how many pixels to reduce when checking against stage wall
  if init_player == 1 then self.facing = 1 elseif init_player == 2 then self.facing = -1 end
  self.sprite = love.graphics.newQuad(self.image_index * self.sprite_size[1], 0, self.sprite_size[1], self.sprite_size[2], self.image_size[1], self.image_size[2])
  self.my_center = self.pos[1] + self.sprite_size[1]
  self.dandy = false
  self.pilebunk_ok = false
  self.pilebunking = false

  self.start_pos[1] = stage.center - (self.facing * window.width / 5) - (self.sprite_size[1] / 2)  
  self.start_pos[2] = stage.floor - self.sprite_size[2]

  self.pos[1] = self.start_pos[1]
  self.pos[2] = self.start_pos[2]
  
  self.sprite = love.graphics.newQuad(self.image_index * self.sprite_size[1], 0, self.sprite_size[1], self.sprite_size[2], self.image_size[1], self.image_size[2])
  self.my_center = self.pos[1] + self.sprite_size[1]

  -- sound effects
  self.jump_sfx = "Jean/JeanJump.ogg"
  self.attack_sfx = "Jean/JeanAttack.ogg"
  self.got_hit_sfx = "Jean/JeanKO.ogg"
  self.hit_sound_sfx = "Potatoes.ogg"
  self.dandy_sfx = "Jean/JeanDandy.ogg"
  self.pilebunker_sfx = "Jean/JeanBunker.ogg"
  self.ground_special_sfx = "WireSea.ogg"
  self.air_special_sfx = "Jean/JeanAirSpecial.ogg"

  self.hurtboxes_standing = {
    {L = 53, U = 27, R = 95, D = 50, Flag1 = Mugshot},
    {L = 44, U = 51, R = 102, D = 79, Flag1 = Mugshot},
    {L = 51, U = 85, R = 95, D = 101},
    {L = 45, U = 105, R = 104, D = 142},
    {L = 50, U = 143, R = 99, D = 172},
    {L = 57, U = 173, R = 95, D = 190}}
  self.hurtboxes_jumping  = {
    {L = 53, U = 27, R = 95, D = 50, Flag1 = Mugshot},
    {L = 44, U = 51, R = 102, D = 79, Flag1 = Mugshot},
    {L = 51, U = 85, R = 95, D = 101},
    {L = 45, U = 105, R = 104, D = 142},
    {L = 50, U = 143, R = 99, D = 172},
    {L = 57, U = 173, R = 95, D = 190}}
  self.hurtboxes_falling = {
    {L = 53, U = 27, R = 95, D = 50, Flag1 = Mugshot},
    {L = 44, U = 51, R = 102, D = 79, Flag1 = Mugshot},
    {L = 51, U = 85, R = 95, D = 101},
    {L = 45, U = 105, R = 104, D = 142},
    {L = 50, U = 143, R = 99, D = 172},
    {L = 57, U = 173, R = 95, D = 190}}
  self.hurtboxes_attacking  = {
    {L = 10, U = 24, R = 57, D = 69, Flag1 = Mugshot},
    {L = 61, U = 58, R = 77, D = 69},
    {L = 31, U = 72, R = 83, D = 109},
    {L = 42, U = 110, R = 93, D = 126},
    {L = 61, U = 129, R = 116, D = 149},
    {L = 118, U = 138, R = 131, D = 149},
    {L = 62, U = 151, R = 145, D = 172}}
  self.hurtboxes_dandy  = {
    {L = 11, U = 33, R = 39, D = 76, Flag1 = Mugshot},
    {L = 15, U = 82, R = 45, D = 129},
    {L = 24, U = 131, R = 61, D = 151},
    {L = 62, U = 142, R = 73, D = 151},
    {L = 33, U = 152, R = 82, D = 166},
    {L = 47, U = 167, R = 95, D = 186}}
  self.hurtboxes_pilebunker = {
    {L = 6, U = 36, R = 37, D = 71, Flag1 = Mugshot},
    {L = 17, U = 68, R = 71, D = 137},
    {L = 72, U = 87, R = 130, D = 92},
    {L = 73, U = 128, R = 100, D = 137},
    {L = 42, U = 140, R = 108, D = 187},
    {L = 110, U = 152, R = 118, D = 187}}
  self.hurtboxes_pilebunkerB = {
    {L = 15, U = 36, R = 46, D = 71, Flag1 = Mugshot},
    {L = 17, U = 68, R = 71, D = 137},
    {L = 73, U = 128, R = 83, D = 137},
    {L = 42, U = 140, R = 98, D = 187},
    {L = 100, U = 165, R = 113, D = 180}}

  self.hitboxes_attacking = {{L = 130, U = 154, R = 147, D = 172}}
  self.hitboxes_pilebunker = {{L = 86, U = 85, R = 148, D = 92, Flag1 = Wallsplat}}

  self.current_hurtboxes = self.hurtboxes_standing
  self.current_hitboxes = self.hitboxes_attacking

  
end

  function Jean:attack_key_press()
    -- attack if in air and not already attacking.
    if self.in_air and not self.attacking and 
      (self.pos[2] + self.sprite_size[2] < stage.floor - 50 or
      (self.vel[2] > 0 and self.pos[2] + self.sprite_size[2] < stage.floor - 30)) then
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

  function Jean:attack(h_vel, v_vel)
    self.vel = {h_vel * self.facing, v_vel}
    self.attacking = true
    self:updateImage(4)
    self.gravity = 0
    self.current_hurtboxes = self.hurtboxes_attacking
    self.current_hitboxes = self.hitboxes_attacking
    if self.super < 96 and not self.super_on then 
      self.super = math.min(self.super + 8, 96)
      if self.super == 96 then playSFX1(super_sfx) end
    end
  end


  function Jean:dandyStep(h_vel) -- self.dandy is a backstep
    self.dandy = true
    self.vel[1] = h_vel * self.facing
    self:updateImage(3)
    self.current_hurtboxes = self.hurtboxes_dandy
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

    Explosion:loadFX(self.pos[1] + self.sprite_wallspace + 100 * self.facing, self.pos[2] + 86, h_vel * self.facing, 0, 0.9, 0)
    self.vel[1] = h_vel * self.facing
    self:updateImage(6)
    self.current_hurtboxes = self.hurtboxes_pilebunker
    self.current_hitboxes = self.hitboxes_pilebunker
    if self.super < 96 and not self.super_on then 
      self.super = math.min(self.super + 10, 96)
      if self.super == 96 then playSFX1(super_sfx) end
    end
  end

  function Jean:air_special()
    if self.super_on then
      self.waiting_state = ""
      playSFX1(self.air_special_sfx)
      self:jump(0, -30)
    elseif self.super >= 8 and not self.attacking then
      self.super = self.super - 8
      self.waiting_state = ""
      playSFX1(self.air_special_sfx)
      self:jump(0, -30)
    end
  end    

  function Jean:ground_special()
    if self.super_on and (self.dandy or self.pilebunking) and math.abs(self.vel[1]) < 18 then
      self.super = self.super - 8
      self.waiting_state = ""
      playSFX1(self.ground_special_sfx)
      WireSea:loadFX(self.pos[1] + self.sprite_size[1] / 2, self.pos[2] + self.sprite_size[2] / 2)
      self:land()
      p1:setFrozen(10)
      p2:setFrozen(10)
    elseif self.super >= 16 and (self.dandy or self.pilebunking) and math.abs(self.vel[1]) < 18 then
      self.super = self.super - 16
      self.waiting_state = ""
      playSFX1(self.ground_special_sfx)
      WireSea:loadFX(self.pos[1] + self.sprite_size[1] / 2, self.pos[2] + self.sprite_size[2] / 2)
      self:land()
      p1:setFrozen(10)
      p2:setFrozen(10)
    end
  end

  function Jean:stateCheck()
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
    end

    -- stop pilebunking, and change to recovery frames
    if self.pilebunking and math.abs(self.vel[1]) >= 0.001 and math.abs(self.vel[1]) < 1 then
      self.attacking = false
      self:updateImage(7)
      self.current_hurtboxes = self.hurtboxes_pilebunkerB
      self.current_hitboxes = self.hitboxes_neutral
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
    end
  end

function Jean:gotHit(type)
  Fighter.gotHit(self, type)
  self.pilebunking = false
  self.dandy = false
  self.friction_on = true
end

function Jean:getSelfNeutral() -- don't check for facing if in dandy/pilebunker
  return not self.in_air and not self.ko and not self.attacking and not self.dandy and not self.pilebunking
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
Winquote: Robert De Niro called.
]]--

--[[---------------------------------------------------------------------------
                                      BEDFROG
-----------------------------------------------------------------------------]]   

--[[A large sprite character to test the particle offsets to make sure that they're coded well
Air Special: Has Vlad's jetpack, which costs a lot of meter to use
Ground Special: Bedman's Deja Vu, he can kick from the same place as the last kick
]]
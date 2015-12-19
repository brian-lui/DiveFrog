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
function Fighter:initialize(init_facing)
  --[[-------------------------------------------------------------------------
                              NO NEED TO MODIFY THESE
  ---------------------------------------------------------------------------]]
  
  dummypic = love.graphics.newImage('images/dummy.png')
  self.player = init_facing -- 1 for player 1, -1 for player 2
  self.frozen = 0 -- only update sprite if this is 0. Used for e.g. super freeze
  self.score = 0
  self.in_air = false
  self.life = 280 -- 280 pixels in the life bar
  self.ko = false
  self.won = false
  self.attacking = false
  self.mugshotted = 0 -- frames the character is mugshotted for
  self.hit_type = {} -- type of hit, passed through to gotHit(). E.g. for wall splat
  self.super = 0 -- max 96
  self.super_on = false -- trigger super mode
  self.super_drainspeed = 0.2 -- how fast super meter drains away. 
  self.start_pos = {1, 1} -- Starting position at beginning of round
  self.pos = {1, 1} -- Top left corner of sprite
  self.vel = {0, 0}
  self.friction = 0.95 -- horizontal velocity multiplied each frame
  self.friction_on = false
  self.vel_multiple = 1.0
  self.hit_wall = false -- if player has hit wall or not. Used for wallsplat and some special moves
  self.hurtboxes = {{0, 0, 0, 0}}
  self.hitboxes = {{0, 0, 0, 0}}
  self.opp_center = stage.center -- center of opponent's sprite
  self.waiting = 0 -- number of frames to wait. used for pre-jump frames etc.
  self.waiting_state = "" -- buffer the action that will be executed if special isn't pressed
  self.hit_flag = {} -- for KO animations
  self.things = {} -- projectiles, etc.
  self.things.attacking = false

  --[[-------------------------------------------------------------------------
                            MAY NEED TO MODIFY THESE
  ---------------------------------------------------------------------------]]

  -- images
  self.icon = dummypic -- corner icon
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

  -- lists of hitboxes and hurtboxes for the relevant sprites. format is LEFT, TOP, RIGHT, BOTTOM, relative to top left corner of sprite.
  self.hurtboxes_standing = {{0, 0, 0, 0}}
  self.hurtboxes_jumping  = {{0, 0, 0, 0}}
  self.hurtboxes_falling = {{0, 0, 0, 0}}
  self.hurtboxes_attacking  = {{0, 0, 0, 0}}
  self.hurtboxes_kickback  = {{0, 0, 0, 0}}
  self.hurtboxes_ko  = {{0, 0, 0, 0}}
  self.hitboxes_attacking = {{0, 0, 0, 0}}

  -- sound effects
  self.BGM = "dummy.mp3"
  self.jump_sfx = "dummy.mp3"
  self.attack_sfx = "dummy.mp3"
  self.got_hit_sfx = "dummy.mp3"
  self.hit_sound_sfx = "dummy.mp3"
  self.ground_special_sfx = "dummy.mp3"
  self.air_special_sfx = "dummy.mp3"

  -- Copy the below stuff after the new initialization variables for each new character
  self.sprite = love.graphics.newQuad(self.image_index * self.sprite_size[1], 0, self.sprite_size[1], self.sprite_size[2], self.image_size[1], self.image_size[2])
  self.facing = init_facing -- 1 for facing right, -1 for facing left
  self.start_pos[1] = stage.center - (init_facing * window.width / 5) - (self.sprite_size[1] / 2)
  self.start_pos[2] = stage.floor - self.sprite_size[2]
  self.my_center = self.pos[1] + self.sprite_size[1]
  self.gravity = self.default_gravity
  self.current_hurtboxes = self.hurtboxes_standing
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
    local shift = 0
      if self.facing == -1 then shift = 1 end
    JumpDust:loadFX(self.pos[1] + self.sprite_size[1] / 2, self.pos[2] + self.sprite_size[2] - 40, self.facing, shift)
  end

  function Fighter:kickback(h_vel, v_vel)
    self.in_air = true
    self.gravity = self.default_gravity
    self.vel = {h_vel * self.facing, -v_vel}
    self:updateImage(3)
    self.current_hurtboxes = self.hurtboxes_kickback
    local shift = 0
      if self.facing == -1 then shift = 1 end
    KickbackDust:loadFX(self.pos[1] + self.sprite_size[1], self.pos[2] + self.sprite_size[2] - 54, self.facing, shift)
  end

  function Fighter:land() -- called when character lands on floor
    self.in_air = false
    self.attacking = false
    self.hit_wall = false
    if not self.ko then
      self.vel = {0, 0}
      self:updateImage(0)
      self.current_hurtboxes = self.hurtboxes_standing
    end
  end

  function Fighter:attack(h_vel, v_vel)
    self.vel = {h_vel * self.facing, v_vel}
    self.attacking = true
    self:updateImage(4)
    self.gravity = 0
    self.current_hurtboxes = self.hurtboxes_attacking
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
    Mugshot:loadFX() -- display Mugshot graphic
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
      self.current_hurtboxes = self.hurtboxes_ko
    end
  end

  if frame - round_end_frame > 60 then
    self.friction_on = true
    self:updateImage(5)
    if self.hit_flag.Wallsplat and self.hit_wall then
      self.vel[1] = -self.vel[1] * 0.4
      self.hit_wall = false
      WallExplosion:loadFX(self.pos[1], self.pos[2])
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
  if not self.in_air and not self.ko and not self.attacking then
    return true
  else
    return false
  end
end

function Fighter:getStart_Pos() return self.start_pos end
function Fighter:getPos_h() return self.pos[1] end
function Fighter:getPos_v() return self.pos[2] end
function Fighter:getSprite_Width() return self.sprite_size[1] end
function Fighter:getFacing() return self.facing end
function Fighter:getImage_Size() return unpack(self.image_size) end
--function Fighter:getHurtboxes() return self.hurtboxes end
--function Fighter:getHitboxes() return self.hitboxes end
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
  self.life = 280
  self.won = false
  self.attacking = false
  self.super_on = false
  self.hit_wall = false
  self.friction_on = false
  self.image_index = 0 -- Horizontal offset starting at 0
  self.vel = {0, 0}
  self.vel_multiple = 1.0
  self.gravity = self.default_gravity
  self.opp_center = 400 -- center of opponent's sprite
  self.my_center = self.pos[1] + self.sprite_size[1]
  self:updateImage(self.image_index)
  self.current_hurtboxes = self.hurtboxes_standing
  self.current_hitboxes = self.hitboxes_attacking
  if self.hit_flag.Mugshot then
    self.mugshotted = 270 -- add 90 frames to this, because of round start fade-in
  end
  self.hit_flag = {}
end

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
    temp_hurtbox[i] = {0, 0, 0, 0}
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
      temp_hurtbox[i][5] = self.current_hurtboxes[i][5] -- flag 1
    end

  elseif self.facing == -1 then
    for i = 1, #self.current_hurtboxes do
      temp_hurtbox[i][1] = - self.current_hurtboxes[i][3] + self.pos[1] + self.sprite_size[1] -- left
      temp_hurtbox[i][2] = self.current_hurtboxes[i][2] + self.pos[2] -- top
      temp_hurtbox[i][3] = - self.current_hurtboxes[i][1] + self.pos[1] + self.sprite_size[1] -- right
      temp_hurtbox[i][4] = self.current_hurtboxes[i][4] + self.pos[2] -- bottom
      temp_hurtbox[i][5] = self.current_hurtboxes[i][5] -- flag 1
    end
  end

  -- add hitbox sides to self.pos for updated sides
  if self.attacking and self.facing == 1 then
    for i = 1, #self.current_hitboxes do
      temp_hitbox[i][1] = self.current_hitboxes[i][1] + self.pos[1] -- left
      temp_hitbox[i][2] = self.current_hitboxes[i][2] + self.pos[2] -- top
      temp_hitbox[i][3] = self.current_hitboxes[i][3] + self.pos[1] -- right
      temp_hitbox[i][4] = self.current_hitboxes[i][4] + self.pos[2] -- bottom
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
  self.start_pos[1] = stage.center - (init_facing * window.width / 5) - (self.sprite_size[1] / 2)
  self.start_pos[2] = stage.floor - self.sprite_size[2]

  self.pos[1] = self.start_pos[1]
  self.pos[2] = self.start_pos[2]
  
  self.my_center = self.pos[1] + self.sprite_size[1]
  
  --lists of hitboxes and hurtboxes for the relevant sprites. format is LEFT, TOP, RIGHT, BOTTOM, relative to top left corner of sprite.
  self.hurtboxes_standing = {{78, 33, 116, 50, Mugshot}, {69, 51, 124, 79, Mugshot}, {76, 85, 120, 101}, {70, 105, 129, 142}, {75, 143, 124, 172}, {82, 173, 120, 190}}
  self.hurtboxes_jumping  = {{78, 33, 116, 50, Mugshot}, {69, 51, 124, 79, Mugshot}, {76, 85, 120, 101}, {70, 105, 129, 142}, {75, 143, 124, 172}, {82, 173, 120, 190}}
  self.hurtboxes_falling = {{78, 33, 116, 50, Mugshot}, {69, 51, 124, 79, Mugshot}, {76, 85, 120, 101}, {70, 105, 129, 142}, {75, 143, 124, 172}, {82, 173, 120, 190}}
  self.hurtboxes_attacking  = {{67, 30, 108, 59, Mugshot}, {75, 60, 104, 103}, {68, 104, 91, 135}, {100, 105, 114, 136}, {111, 137, 128, 157}, {125, 158, 138, 183}}
  self.hurtboxes_kickback  = {{67, 41, 128, 72, Mugshot}, {70, 73, 119, 165}, {72, 166, 111, 182}}
  self.hurtboxes_ko  = {{0, 0, 0, 0}}

  self.hitboxes_attacking = {{119, 166, 137, 183}}

  self.current_hurtboxes = self.hurtboxes_standing
  self.current_hitboxes = self.hitboxes_attacking

  -- sound effects
  self.jump_sfx = "Konrad/KonradJump.mp3"
  self.jump2_sfx = "Konrad/KonradJump2.mp3"
  self.attack_sfx = "Konrad/KonradAttack.mp3"
  self.got_hit_sfx = "Konrad/KonradKO.mp3"
  self.hit_sound_sfx = "Potatoes.mp3"
  self.ground_special_sfx = "Konrad/KonradGroundSpecial.mp3"
  self.air_special_sfx = "Konrad/KonradAirSpecial.mp3"

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
      self:attack(12, 16)
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

  function Konrad:extraStuff()
    if self.waiting > 0 then
      self.waiting = self.waiting - 1
      if self.waiting == 0 and self.waiting_state == "Jump" then
        self.waiting_state = ""
        self:jump(0, 12, self.default_gravity)
        playSFX1(self.jump_sfx)
        local shift = 0
        if self.facing == -1 then shift = 1 end
        print(shift)
        JumpDust:loadFX(self.pos[1] + self.sprite_size[1] / 2, self.pos[2] + self.sprite_size[2] - 40, self.facing, shift)
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

  self.sprite = love.graphics.newQuad(self.image_index * self.sprite_size[1], 0, self.sprite_size[1], self.sprite_size[2], self.image_size[1], self.image_size[2])
  self.my_center = self.pos[1] + self.sprite_size[1]
  self.dandy = false
  self.pilebunk_ok = false
  self.pilebunking = false

  self.start_pos[1] = stage.center - (init_facing * window.width / 5) - (self.sprite_size[1] / 2)  
  self.start_pos[2] = stage.floor - self.sprite_size[2]

  self.pos[1] = self.start_pos[1]
  self.pos[2] = self.start_pos[2]
  
  self.sprite = love.graphics.newQuad(self.image_index * self.sprite_size[1], 0, self.sprite_size[1], self.sprite_size[2], self.image_size[1], self.image_size[2])
  self.my_center = self.pos[1] + self.sprite_size[1]

  -- sound effects
  self.jump_sfx = "Jean/JeanJump.mp3"
  self.attack_sfx = "Jean/JeanAttack.mp3"
  self.got_hit_sfx = "Jean/JeanKO.mp3"
  self.hit_sound_sfx = "Potatoes.mp3"
  self.dandy_sfx = "Jean/JeanDandy.mp3"
  self.pilebunker_sfx = "Jean/JeanBunker.mp3"
  self.ground_special_sfx = "Jean/JeanGroundSpecial.mp3"
  self.air_special_sfx = "Jean/JeanAirSpecial.mp3"

  self.hurtboxes_standing = {{53, 33, 95, 50, Mugshot}, {44, 51, 102, 79, Mugshot}, {51, 85, 95, 101}, {45, 105, 104, 142}, {50, 143, 99, 172}, {57, 173, 95, 190}}
  self.hurtboxes_jumping  = {{53, 33, 95, 50, Mugshot}, {44, 51, 102, 79, Mugshot}, {51, 85, 95, 101}, {45, 105, 104, 142}, {50, 143, 99, 172}, {57, 173, 95, 190}}
  self.hurtboxes_falling = {{53, 33, 95, 50, Mugshot}, {44, 51, 102, 79, Mugshot}, {51, 85, 95, 101}, {45, 105, 104, 142}, {50, 143, 99, 172}, {57, 173, 95, 190}}
  self.hurtboxes_attacking  = {{10, 26, 58, 69, Mugshot}, {61, 58, 77, 69}, {31, 72, 83, 109}, {42, 110, 93, 126}, {61, 129, 116, 149}, {118, 138, 131, 149}, {62, 151, 145, 172}}
  self.hurtboxes_dandy  = {{11, 32, 37, 76, Mugshot}, {15, 82, 45, 129}, {24, 131, 61, 151}, {62, 142, 73, 151}, {33, 152, 82, 166}, {47, 167, 95, 186}}
  self.hurtboxes_ko  = {{0, 0, 0, 0,}}
  self.hurtboxes_pilebunker = {{6, 32, 37, 71, Mugshot}, {17, 68, 71, 137}, {73, 128, 100, 137}, {42, 140, 108, 187}, {110, 152, 118, 187}}
  self.hurtboxes_pilebunkerB = {{15, 32, 46, 71, Mugshot}, {17, 68, 71, 137}, {73, 128, 83, 137}, {42, 140, 98, 187}, {100, 165, 113, 180}}

  self.hitboxes_attacking = {{130, 154, 147, 172}}
  self.hitboxes_pilebunker = {{86, 85, 148, 92, Wallsplat}}

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
    self.current_hitboxes = self.hitboxes_attacking
    self.hit_type = {}
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
    self.hit_type = {Wallsplat = true}

    Explosion:loadFX(self.pos[1] + 75 + 150 * self.facing, self.pos[2] + 86, h_vel * self.facing, 0, 0.9, 0)
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
      self.super = self.super - 10
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
end

function Jean:gotHit(type)
  Fighter.gotHit(self, type)
  self.pilebunking = false
  self.dandy = false
  self.friction_on = true
end

function Jean:getSelfNeutral() -- don't check for facing if in dandy/pilebunker
  if not self.in_air and not self.ko and not self.attacking and not self.dandy and not self.pilebunking then
    return true
  else
    return false
  end
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
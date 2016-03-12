local class = require 'middleclass'
local stage = require 'stage' -- for checking floor/walls
local window = require 'window'
local music = require 'music' -- background music
require 'character'
require 'utilities'
require 'particles'

Konrad = class('Konrad', Fighter)
function Konrad:initialize(init_player, init_foe, init_super, init_dizzy, init_score)
  Fighter.initialize(self, init_player, init_foe, init_super, init_dizzy, init_score)
  self.fighter_name = "Konrad"
  self.icon = love.graphics.newImage('images/Konrad/KonradIcon.png')
  self.win_portrait = love.graphics.newImage('images/Konrad/KonradPortrait.png')
  self.win_quote = "You have been defeated by Konrad the \ntalking frog with a cape who plays poker."
  self.stage_background = love.graphics.newImage('images/Konrad/KonradBackground.jpg')
  self.BGM = "KonradTheme.ogg"
  self.image = love.graphics.newImage('images/Konrad/KonradTiles.png')
  self.image_size = {1200, 200}
  self.sprite_size = {200, 200}
  self.sprite_wallspace = 50 -- how many pixels to reduce when checking against stage wall
  self.default_gravity = 0.36
  self.double_jump = false
  
  --lists of hitboxes and hurtboxes for the relevant sprites. format is LEFT, TOP, RIGHT, BOTTOM, relative to top left corner of sprite.
  self.hurtboxes_standing = {
    {L = 78, U = 28, R = 119, D = 50, Flag1 = "Mugshot"},
    {L = 69, U = 51, R = 124, D = 79, Flag1 = "Mugshot"},
    {L = 76, U = 85, R = 120, D = 101},
    {L = 70, U = 105, R = 129, D = 142},
    {L = 75, U = 143, R = 124, D = 172},
    {L = 82, U = 173, R = 120, D = 190}}
  self.hurtboxes_jumping  = {
    {L = 78, U = 28, R = 119, D = 50, Flag1 = "Mugshot"},
    {L = 69, U = 51, R = 124, D = 79, Flag1 = "Mugshot"},
    {L = 76, U = 85, R = 120, D = 101},
    {L = 70, U = 105, R = 129, D = 142},
    {L = 75, U = 143, R = 124, D = 172},
    {L = 82, U = 173, R = 120, D = 190}}
  self.hurtboxes_falling = {
    {L = 78, U = 28, R = 119, D = 50, Flag1 = "Mugshot"},
    {L = 69, U = 51, R = 124, D = 79, Flag1 = "Mugshot"},
    {L = 76, U = 85, R = 120, D = 101},
    {L = 70, U = 105, R = 129, D = 142},
    {L = 75, U = 143, R = 124, D = 172},
    {L = 82, U = 173, R = 120, D = 190}}
  self.hurtboxes_attacking  = {
    {L = 67, U = 20, R = 109, D = 59, Flag1 = "Mugshot"},
    {L = 75, U = 60, R = 104, D = 103},
    {L = 68, U = 104, R = 91, D = 135},
    {L = 100, U = 105, R = 114, D = 136},
    {L = 111, U = 137, R = 128, D = 157},
    {L = 125, U = 158, R = 138, D = 183}}
  self.hurtboxes_kickback  = {
    {L = 82, U = 25, R = 123, D = 71, Flag1 = "Mugshot"},
    {L = 71, U = 41, R = 128, D = 72, Flag1 = "Mugshot"},
    {L = 70, U = 73, R = 119, D = 165},
    {L = 72, U = 166, R = 111, D = 182}}

  self.hitboxes_attacking = {{L = 119, U = 166, R = 137, D = 183}}
  self.hitboxes_hyperkick = {{L = 119, U = 166, R = 137, D = 183, Flag1 = "Fire"}}

  self.hyperkicking = false

  -- sound effects
  self.jump_sfx = "Konrad/KonradJump.ogg"
  self.attack_sfx = "Konrad/KonradAttack.ogg"
  self.got_hit_sfx = "Konrad/KonradKO.ogg"
  self.hit_sound_sfx = "Potatoes.ogg"
  self.ground_special_sfx = "Konrad/KonradHyperJump.ogg"

  self:init2(init_player, init_foe, init_super, init_dizzy, init_score)
end

  function Konrad:jump_key_press()
    if self.isInAir and not self.isAttacking and not self.double_jump then
      self.waiting = 3
      self.waiting_state = "DoubleJump"
      self.double_jump = true
    end
    Fighter.jump_key_press(self) -- check for ground jump or special move
  end

  function Konrad:attack_key_press()
    -- attack if in air and not already attacking and either: >50 above floor, or landing and >30 above.
    if self.isInAir and not self.isAttacking and 
      (self.pos[2] + self.sprite_size[2] < stage.floor - 50 or
      (self.vel[2] > 0 and self.pos[2] + self.sprite_size[2] < stage.floor - 30)) then
        self.waiting = 3
        self.waiting_state = "Attack"
    -- if on ground, kickback
    elseif not self.isInAir then
      self.waiting = 3
      self.waiting_state = "Kickback"
    end
    Fighter.attack_key_press(self) -- check for special move
  end

  function Konrad:air_special()
    if self.super >= 16 and not self.isAttacking and not self.isSupering and
    self.pos[2] + self.sprite_size[2] < stage.floor - 50 then
      self.super = self.super - 16
      self.waiting_state = ""
      HyperKickFlames:playSound()
      self.vel = {14 * self.facing, 19}
      self.isAttacking = true  
      self.hyperkicking = true
      self:updateImage(4)
      self.gravity = 0
      self.current_hurtboxes = self.hurtboxes_attacking
      self.current_hitboxes = self.hitboxes_hyperkick
    end
  end

  function Konrad:ground_special()
    if self.super >= 16 and not self.isSupering then
      self.super = self.super - 16
      self.waiting_state = ""
      writeSound(self.ground_special_sfx)
      self:jump(0, 29, 1.2)
    end
  end

  function Konrad:jump(h_vel, v_vel, gravity)
    self.isInAir = true
    self.gravity = gravity
    self.vel = {h_vel * self.facing, -v_vel}
    self:updateImage(1)
    self.current_hurtboxes = self.hurtboxes_jumping
  end

  function Konrad:land() -- called when character lands on floor
    self.isInAir = false
    self.isAttacking = false
    self.double_jump = false
    self.hyperkicking = false
    if not self.isKO then
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
        self:jump(0, 14, self.default_gravity)
        writeSound(self.jump_sfx)
        JumpDust:singleLoad(self.center, self.pos[2], 0, self.sprite_size[2] - JumpDust.height, self.facing)
      end
      if self.waiting == 0 and self.waiting_state == "DoubleJump" then
        self.waiting_state = ""
        self:jump(4.8, 4.8, self.default_gravity)
        DoubleJumpDust:singleLoad(self.center, self.pos[2], -30, self.sprite_size[2] - DoubleJumpDust.height, self.facing)
        DoubleJumpDust:playSound()
      end
      if self.waiting == 0 and self.waiting_state == "Attack" then 
        self.waiting_state = ""
        self:attack(7.2, 9.6)
        writeSound(self.attack_sfx)
      end
      if self.waiting == 0 and self.waiting_state == "Kickback" then
        self.waiting_state = ""
        self:kickback(-7.2, 7.2)
        writeSound(self.jump_sfx)
      end
    end
  end

  function Konrad:getNeutral()
    return not self.isKO and not self.isAttacking and self.recovery == 0
  end

  function Konrad:victoryPose()
    if frame - round_end_frame == 60 then self.hyperkicking = false end
    Fighter.victoryPose(self)
  end

  function Konrad:extraStuff()
    if self.hyperkicking and not self.isKO then
      HyperKickFlames:repeatLoad(self.center, self.pos[2], 0, 0, self.facing)
    end
  end


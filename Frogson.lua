local class = require 'middleclass'
local stage = require 'stage' -- for checking floor/walls
local window = require 'window'
local music = require 'music' -- background music
require 'character'
require 'utilities'
require 'particles'

Frogson = class('Frogson', Fighter)
function Frogson:initialize(init_player, init_foe, init_super, init_dizzy, init_score)
  Fighter.initialize(self, init_player, init_foe, init_super, init_dizzy, init_score)
  self.fighter_name = "M. Frogson"
  self.icon = love.graphics.newImage('images/Frogson/FrogsonIcon.png')
  self.win_portrait = love.graphics.newImage('images/Frogson/FrogsonPortrait.png')
  self.win_quote = "Thanks."
  self.stage_background = love.graphics.newImage('images/Frogson/FrogsonBackground.jpg')
  self.BGM = "FrogsonTheme.ogg"
  self.image = love.graphics.newImage('images/Frogson/FrogsonTiles.png')
  self.image_size = {1600, 400}
  self.sprite_size = {200, 200}
  self.sprite_wallspace = 60 -- how many pixels to reduce when checking against stage wall
  self.default_gravity = 0.36
  self.jackson_stance = false

  self.hurtboxes_standing = {
    {L = 80, U = 39, R = 129, D = 85, Flag1 = "Mugshot"},
    {L = 70, U = 90, R = 127, D = 138},
    {L = 71, U = 139, R = 122, D = 158},
    {L = 72, U = 159, R = 114, D = 192}}
	self.hurtboxes_jumping = {
    {L = 80, U = 39, R = 129, D = 85, Flag1 = "Mugshot"},
    {L = 70, U = 90, R = 127, D = 138},
    {L = 71, U = 139, R = 122, D = 158},
    {L = 72, U = 159, R = 114, D = 192}}
	self.hurtboxes_falling = {
    {L = 80, U = 39, R = 129, D = 85, Flag1 = "Mugshot"},
    {L = 70, U = 90, R = 127, D = 138},
    {L = 71, U = 139, R = 122, D = 158},
    {L = 72, U = 159, R = 114, D = 192}}
	self.hurtboxes_moonwalk = {
    {L = 85, U = 43, R = 127, D = 66, Flag1 = "Mugshot"},
    {L = 101, U = 67, R = 120, D = 78, Flag1 = "Mugshot"},
    {L = 86, U = 25, R = 117, D = 42},
    {L = 62, U = 58, R = 86, D = 186},
    {L = 87, U = 177, R = 97, D = 186},
    {L = 37, U = 153, R = 167, D = 187}}
  self.hurtboxes_attacking_bison  = {
    {L = 80, U = 39, R = 129, D = 85, Flag1 = "Mugshot"},
    {L = 70, U = 90, R = 127, D = 138},
    {L = 71, U = 139, R = 122, D = 158},
    {L = 72, U = 159, R = 114, D = 192}}
  self.hurtboxes_attacking_jackson  = {
    {L = 98, U = 94, R = 148, D = 153, Flag1 = "Mugshot"},
    {L = 10, U = 47, R = 97, D = 123},
    {L = 100, U = 70, R = 148, D = 91},
    {L = 149, U = 94, R = 187, D = 112}}
  self.hurtboxes_antigravity  = {
    {L = 145, U = 57, R = 185, D = 96, Flag1 = "Mugshot"},
    {L = 127, U = 83, R = 146, D = 118},
    {L = 97, U = 116, R = 126, D = 138},
    {L = 66, U = 142, R = 86, D = 185}}
  self.hurtboxes_wow  = {
    {L = 72, U = 41, R = 129, D = 90, Flag1 = "Mugshot"},
    {L = 72, U = 92, R = 126, D = 1156},
    {L = 52, U = 162, R = 73, D = 182},
    {L = 112, U = 162, R = 143, D = 186}}

  self.hitboxes_attacking_bison = {{L = 78, U = 187, R = 114, D = 195}}
  self.hitboxes_attacking_jackson = {{L = 184, U = 107, R = 198, D = 119}}
  self.hitboxes_antigravity = {{L = 167, U = 71, R = 183, D = 91}}
  
  -- sound effects
  --self.jump_sfx = "Konrad/KonradJump.ogg"
  --self.attack_sfx = "Konrad/KonradAttack.ogg"
  --self.got_hit_sfx = "Konrad/KonradKO.ogg"
  self.hit_sound_sfx = "Potatoes.ogg"
  self.moonwalk1_sfx = "Frogson/Moonwalk1.ogg"
  self.moonwalk2_sfx = "Frogson/Moonwalk2.ogg"
  self.wow_sfx = "Frogson/Thriller.ogg"
  self.antigravity_sfx = "Frogson/BeatIt.ogg"

  self:init2(init_player, init_foe, init_super, init_dizzy, init_score)
end

    --[[Currently edited up to HERE
  Moonwalk should have blue shadows behind it.
  Make theme song more Michael Jacksony and/or with M. Bison bells
  --]]    

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

  function Konrad:victoryPose()
    if frame - round_end_frame == 60 then self.hyperkicking = false end
    Fighter.victoryPose(self)
  end

  function Konrad:extraStuff()
    if self.hyperkicking and not self.isKO then
      HyperKickFlames:repeatLoad(self.center, self.pos[2], 0, 0, self.facing)
    end
  end


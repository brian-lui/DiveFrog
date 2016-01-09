local class = require 'middleclass'
local stage = require 'stage' -- for checking floor/walls
local window = require 'window'
local music = require 'music' -- background music
require 'utilities'
require 'particles'
require 'character'

Jean = class('Jean', Fighter)
function Jean:initialize(init_player, init_foe, init_super, init_dizzy, init_score)
  Fighter.initialize(self, init_player, init_foe, init_super, init_dizzy, init_score)
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
  self.default_gravity = 0.42
  self.sprite_wallspace = 25 -- how many pixels to reduce when checking against stage wall
  self.dandy = false
  self.pilebunk_ok = false
  self.pilebunking = false

  -- sound effects
  self.jump_sfx = "Jean/JeanJump.ogg"
  self.attack_sfx = "Jean/JeanAttack.ogg"
  self.got_hit_sfx = "Jean/JeanKO.ogg"
  self.hit_sound_sfx = "Potatoes.ogg"
  self.dandy_sfx = "Jean/JeanDandy.ogg"
  self.pilebunker_sfx = "Jean/JeanBunker.ogg"
  self.air_special_sfx = "Jean/JeanAirSpecial.ogg"

  self.hurtboxes_standing = {
    {L = 53, U = 27, R = 95, D = 50, Flag1 = "Mugshot"},
    {L = 44, U = 51, R = 102, D = 79, Flag1 = "Mugshot"},
    {L = 51, U = 85, R = 95, D = 101},
    {L = 45, U = 105, R = 104, D = 142},
    {L = 50, U = 143, R = 99, D = 172},
    {L = 57, U = 173, R = 95, D = 190}}
  self.hurtboxes_jumping  = {
    {L = 53, U = 27, R = 95, D = 50, Flag1 = "Mugshot"},
    {L = 44, U = 51, R = 102, D = 79, Flag1 = "Mugshot"},
    {L = 51, U = 85, R = 95, D = 101},
    {L = 45, U = 105, R = 104, D = 142},
    {L = 50, U = 143, R = 99, D = 172},
    {L = 57, U = 173, R = 95, D = 190}}
  self.hurtboxes_falling = {
    {L = 53, U = 27, R = 95, D = 50, Flag1 = "Mugshot"},
    {L = 44, U = 51, R = 102, D = 79, Flag1 = "Mugshot"},
    {L = 51, U = 85, R = 95, D = 101},
    {L = 45, U = 105, R = 104, D = 142},
    {L = 50, U = 143, R = 99, D = 172},
    {L = 57, U = 173, R = 95, D = 190}}
  self.hurtboxes_attacking  = {
    {L = 10, U = 24, R = 57, D = 69, Flag1 = "Mugshot"},
    {L = 61, U = 58, R = 77, D = 69},
    {L = 31, U = 72, R = 83, D = 109},
    {L = 42, U = 110, R = 93, D = 126},
    {L = 61, U = 129, R = 116, D = 149},
    {L = 118, U = 138, R = 131, D = 149},
    {L = 62, U = 151, R = 145, D = 172}}
  self.hurtboxes_dandy  = {
    {L = 11, U = 33, R = 39, D = 76, Flag1 = "Mugshot"},
    {L = 15, U = 82, R = 45, D = 129},
    {L = 24, U = 131, R = 61, D = 151},
    {L = 62, U = 142, R = 73, D = 151},
    {L = 33, U = 152, R = 82, D = 166},
    {L = 47, U = 167, R = 95, D = 186}}
  self.hurtboxes_pilebunker = {
    {L = 6, U = 36, R = 37, D = 71, Flag1 = "Mugshot"},
    {L = 17, U = 68, R = 71, D = 137},
    {L = 72, U = 87, R = 130, D = 92},
    {L = 73, U = 128, R = 100, D = 137},
    {L = 42, U = 140, R = 108, D = 187},
    {L = 110, U = 152, R = 118, D = 187}}
  self.hurtboxes_pilebunkerB = {
    {L = 15, U = 36, R = 46, D = 71, Flag1 = "Mugshot"},
    {L = 17, U = 68, R = 71, D = 137},
    {L = 73, U = 128, R = 83, D = 137},
    {L = 42, U = 140, R = 98, D = 187},
    {L = 100, U = 165, R = 113, D = 180}}

  self.hitboxes_attacking = {{L = 130, U = 154, R = 147, D = 172}}
  self.hitboxes_pilebunker = {{L = 86, U = 85, R = 148, D = 92, Flag1 = "Wallsplat"}}

  self:init2(init_player, init_foe, init_super, init_dizzy, init_score)
end

  function Jean:attack_key_press()
    -- attack if in air and not already attacking.
    if self.isInAir and not self.isAttacking and not self.dandy and not self.pilebunking and
      (self.pos[2] + self.sprite_size[2] < stage.floor - 50 or
      (self.vel[2] > 0 and self.pos[2] + self.sprite_size[2] < stage.floor - 30)) then
        self.waiting = 3
        self.waiting_state = "Attack"
    -- dandy step replaces kickback, only do if in neutral state
    elseif not self.isInAir and not self.dandy and not self.pilebunking then
      self.waiting = 3
      self.waiting_state = "Dandy"
    -- pilebunk only if allowed conditions met
    elseif not self.isInAir and self.dandy and self.pilebunk_ok then
      self.waiting = 3
      self.waiting_state = "Pilebunker"
    end  
    Fighter.attack_key_press(self) -- check for special move
  end

  function Jean:attack(h_vel, v_vel)
    self.vel = {h_vel * self.facing, v_vel}
    self.isAttacking = true
    self:updateImage(4)
    self.gravity = 0
    self.current_hurtboxes = self.hurtboxes_attacking
    self.current_hitboxes = self.hitboxes_attacking
    if not self.isSupering then self.super = math.min(self.super + 8, 96) end
  end


  function Jean:dandyStep(h_vel) -- self.dandy is a backstep
    self.dandy = true
    self.vel[1] = h_vel * self.facing
    self:updateImage(3)
    self.current_hurtboxes = self.hurtboxes_dandy
    self.isFrictionOn = false
    if not self.isSupering then self.super = math.min(self.super + 4, 96) end
  end

  function Jean:pilebunk(h_vel)
    self.pilebunk_ok = false
    self.dandy = false
    self.pilebunking = true -- to prevent dandy step or pilebunker while pilebunking
    self.isAttacking = true -- needed to activate hitboxes

    Explosion1:singleLoad(self.center, self.pos[2], 60, 50, self.facing * 2, 0)
    Explosion2:singleLoad(self.center, self.pos[2], 50, 70, self.facing * 2, 5, "pre")
    Explosion3:singleLoad(self.center, self.pos[2], 100, 30, self.facing * 2, 10)
    Explosion1:singleLoad(self.center, self.pos[2], 40, 20, self.facing * 2, 13, "pre")
    Explosion2:singleLoad(self.center, self.pos[2], 70, 80, self.facing * 2, 15)
    Explosion3:singleLoad(self.center, self.pos[2], 90, 5, self.facing * 2, 17, "pre")
    Explosion1:playSound(0)
    Explosion2:playSound(5)
    Explosion3:playSound(15)

    self.vel[1] = h_vel * self.facing
    self:updateImage(6)
    self.current_hurtboxes = self.hurtboxes_pilebunker
    self.current_hitboxes = self.hitboxes_pilebunker
    if not self.isSupering then self.super = math.min(self.super + 10, 96) end
  end

  function Jean:air_special()
    if self.isSupering then
      self.waiting_state = ""
      writeSound(self.air_special_sfx)
      self:jump(0, -36)
    elseif self.super >= 8 and not self.isAttacking then
      self.super = self.super - 8
      self.waiting_state = ""
      writeSound(self.air_special_sfx)
      self:jump(0, -36)
    end
  end    

  function Jean:ground_special()
    if self.isSupering and (self.dandy or self.pilebunking) and math.abs(self.vel[1]) < 18 then
      self.super = self.super - 8
      self.waiting_state = ""
      WireSea:singleLoad(self.center, self.pos[2], 0, 0, self.facing, 0)
      WireSea:playSound()
      self:land()
      self:setFrozen(10)
      self.foe:setFrozen(10)
    elseif self.super >= 16 and (self.dandy or self.pilebunking) and math.abs(self.vel[1]) < 18 then
      self.super = self.super - 16
      self.waiting_state = ""
      WireSea:singleLoad(self.center, self.pos[2], 0, 0, self.facing, 0)
      WireSea:playSound()
      self:land()
      self:setFrozen(10)
      self.foe:setFrozen(10)
    end
  end

  function Jean:stateCheck()
    if self.waiting > 0 then
      self.waiting = self.waiting - 1
      if self.waiting == 0 and self.waiting_state == "Attack" then 
      self.waiting_state = ""
        self:attack(9.6, 9.6)
        writeSound(self.attack_sfx)
      end
      if self.waiting == 0 and self.waiting_state == "Dandy" then
        self.waiting_state = ""
        self:dandyStep(-36)        
        writeSound(self.dandy_sfx)
      end
      if self.waiting == 0 and self.waiting_state == "Pilebunker" then
        self.waiting_state = ""
        self:pilebunk(56)        
        writeSound(self.pilebunker_sfx)
      end
      if self.waiting == 0 and self.waiting_state == "Jump" then
        self.waiting_state = ""
        self:jump(0, 14)
        writeSound(self.jump_sfx)
      end      
    end
  end

  function Jean:extraStuff()
    if self.dandy or self.pilebunking then self.vel[1] = self.vel[1] * 0.77 end -- custom friction
    -- during dandy step's slowing end part, allow pilebunker
    if self.dandy and math.abs(self.vel[1]) >= 0.1 and math.abs(self.vel[1]) < 3.6 then
      self.pilebunk_ok = true
    else self.pilebunk_ok = false 
    end 
    
    -- when dandy step is almost stopped, return to neutral
    if self.dandy and math.abs(self.vel[1]) < 0.02 then
      self.dandy = false
      self.pilebunk_ok = false
      self.isFrictionOn = false
      self.vel[1] = 0
      self:updateImage(0)
      self.current_hurtboxes = self.hurtboxes_standing
    end

    -- stop pilebunking, and change to recovery frames
    if self.pilebunking and math.abs(self.vel[1]) >= 0.001 and math.abs(self.vel[1]) < 1.2 then
      self.isAttacking = false
      self:updateImage(7)
      self.current_hurtboxes = self.hurtboxes_pilebunkerB
      self.current_hitboxes = self.hitboxes_neutral
    end

    -- change from recovery to neutral
    if self.pilebunking and math.abs(self.vel[1]) < 0.001 and not self.hasWon then
      self.pilebunking = false
      self.dandy = false
      self.isFrictionOn = false
      self.vel[1] = 0
      self:updateImage(0)
      self.current_hurtboxes = self.hurtboxes_standing
    end
  end

function Jean:gotHit(type)
  Fighter.gotHit(self, type)
  self.pilebunking = false
  self.dandy = false
  self.isFrictionOn = true
end

function Jean:getNeutral() -- don't check for facing if in dandy/pilebunker
  return not self.isKO and not self.isAttacking and not self.dandy and not self.pilebunking
end

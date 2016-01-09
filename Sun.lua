local class = require 'middleclass'
local stage = require 'stage' -- for checking floor/walls
local window = require 'window'
local music = require 'music' -- background music
require 'utilities'
require 'particles'
require 'character'

Sun = class('Sun', Fighter)
function Sun:initialize(init_player, init_foe, init_super, init_dizzy, init_score)
  if self.isSupering then -- if super was still on during previous round
    stopBGM2()
    resumeBGM()
  end
  Fighter.initialize(self, init_player, init_foe, init_super, init_dizzy, init_score)

  self.win_quote = "Robert de Niro called."
  self.fighter_name = "Sun Badfrog"
  self.super_drainspeed = 0.25 -- per frame 

  -- images
  self.icon = love.graphics.newImage('images/Sun/SunIcon.png')
  self.win_portrait = love.graphics.newImage('images/Sun/SunPortrait.png')
  self.stage_background = love.graphics.newImage('images/Sun/SunBackground.jpg')
  self.image = love.graphics.newImage('images/Sun/SunTiles.png')
  self.image_size = {1600, 200}
  self.image_index = 0
  self.sprite_size = {200, 200}
  self.sprite_wallspace = 50
  
  -- character variables
  self.default_gravity = 0.4
  self.vel_multiple_super = 1.5

  -- hitboxes. Flags must correspond to a particle class.
  self.hurtboxes_standing = {
    {L = 87, U = 19, R = 117, D = 47, Flag1 = "Mugshot"},
    {L = 83, U = 51, R = 120, D = 108},
    {L = 82, U = 109, R = 122, D = 139},
    {L = 77, U = 140, R = 125, D = 169},
    {L = 72, U = 170, R = 131, D = 198}}
  self.hurtboxes_jumping  = {
    {L = 87, U = 19, R = 117, D = 47, Flag1 = "Mugshot"},
    {L = 83, U = 51, R = 119, D = 108},
    {L = 82, U = 109, R = 121, D = 139},
    {L = 77, U = 140, R = 123, D = 167}}
  self.hurtboxes_falling = {
    {L = 87, U = 19, R = 117, D = 47, Flag1 = "Mugshot"},
    {L = 83, U = 51, R = 120, D = 108},
    {L = 82, U = 109, R = 122, D = 139},
    {L = 77, U = 140, R = 125, D = 198}}
  self.hurtboxes_attacking  = {
    {L = 75, U = 30, R = 101, D = 50, Flag1 = "Mugshot"},
    {L = 74, U = 45, R = 122, D = 65},
    {L = 73, U = 66, R = 104, D = 80},
    {L = 73, U = 81, R = 158, D = 100},
    {L = 78, U = 101, R = 130, D = 114},
    {L = 88, U = 115, R = 156, D = 128},
    {L = 141, U = 129, R = 150, D = 142}}
  self.hurtboxes_kickback  = {
    {L = 87, U = 19, R = 117, D = 47, Flag1 = "Mugshot"},
    {L = 83, U = 51, R = 119, D = 108},
    {L = 82, U = 109, R = 121, D = 139},
    {L = 77, U = 140, R = 123, D = 167}}
  self.hurtboxes_ko  = {{L = 0, U = 0, R = 0, D = 0}}
  self.hurtboxes_hotflame  = {
    {L = 83, U = 12, R = 131, D = 52, Flag1 = "Mugshot"},
    {L = 85, U = 59, R = 116, D = 140},
    {L = 117, U = 73, R = 131, D = 111},
    {L = 73, U = 141, R = 131, D = 152},
    {L = 131, U = 153, R = 143, D = 183},
    {L = 136, U = 184, R = 152, D = 198},
    {L = 27, U = 162, R = 79, D = 174}}
  self.hurtboxes_riotkick  = {
    {L = 74, U = 19, R = 106, D = 50, Flag1 = "Mugshot"},
    {L = 62, U = 55, R = 103, D = 114},
    {L = 56, U = 135, R = 116, D = 155},
    {L = 26, U = 91, R = 65, D = 106},
    {L = 125, U = 35, R = 134, D = 70},
    {L = 110, U = 83, R = 196, D = 105}}
  self.hitboxes_neutral = {{L = 0, U = 0, R = 0, D = 0}}
  self.hitboxes_attacking = {{L = 129, U = 120, R = 151, D = 162},
    {L = 129, U = 100, R = 139, D = 119}}
  self.hitboxes_riotkick = {{L = 189, U = 64, R = 199, D = 109, Flag1 = "Wallsplat"}}
  self.hitboxes_hotflame = {{L = 0, U = 0, R = 0, D = 0}}

  -- sound effects
  self.BGM = "SunTheme.ogg"
  self.aura_BGM = "SunAuraCrackle.ogg"
  self.jump_sfx = "Sun/SunJump.ogg"
  self.got_hit_sfx = "Sun/SolKO.ogg"
  self.hit_sound_sfx = "Potatoes.ogg"
  self.hotflame_sfx = "Sun/HotflameVocals.ogg"
  self.hotterflame_sfx = "Sun/HotterflameVocals.ogg"
  self.radio_sfx = "Sun/SolDragonInstall.ogg"

  self.hotflametime = {0, 0, 0, 0, 0}
  self.hotterflametime = 0
  self.hotflaming_pos = {0, 0}
  self.riotbackdash = false
  self.riotkick = false
  self.kicking = false -- self.isAttacking is overloaded by hotflame

  self:init2(init_player, init_foe, init_super, init_dizzy, init_score)
end

function Sun:getHotflame()
  local flame_on_screen = false
  for i = 1, 4 do
    if self.hotflametime[i] ~= 0 then flame_on_screen = true end
  end
  return flame_on_screen
end

function Sun:getNeutral()
  return not self.isKO and not self.riotbackdash and not self.riotkick and not self.kicking and self.recovery == 0
end

function Sun:attack(h_vel, v_vel)
  self.kicking = true
  Fighter.attack(self, h_vel, v_vel)
end

function Sun:land()
  self.kicking = false
  Fighter.land(self)
end

function Sun:attack_key_press()
    -- attack if in air and not riotkick/attack and either: >50 above floor, or landing and >30 above.
  if self.isInAir and self:getNeutral() and
    (self.pos[2] + self.sprite_size[2] < stage.floor - 50 or
    (self.vel[2] > 0 and self.pos[2] + self.sprite_size[2] < stage.floor - 30)) then
      self.waiting = 3
      self.waiting_state = "Attack"
  elseif not self.isInAir and self:getNeutral() then
    self.waiting = 3
    self.waiting_state = "Kickback"
  end
  Fighter.attack_key_press(self) -- check for special move
end

function Sun:ground_special()
  -- Hotflame
  if self.super >= 8 and self:getNeutral() and not self:getHotflame() then
    self.waiting_state = ""
    self:updateImage(6)
    self.current_hurtboxes = self.hurtboxes_hotflame
    self.current_hitboxes = self.hitboxes_neutral
    self.hotflaming_pos[1] = self.pos[1]
    self.hotflaming_pos[2] = self.pos[2]

    if not self.isSupering then
      self.super = self.super - 8
      self.hotflametime = {50, 0, 0, 0, 0} -- "low quality" way to implement (50 - 30) frame delay
      Hotflame:playSound() -- flamey sounds
      writeSound(self.hotflame_sfx)
      self.recovery = 45
    elseif self.isSupering and self.life > 25 then
      self.life = self.life - 20
      self.hotterflametime = 40
      Hotterflame:playSound() -- big flamey sound
      writeSound(self.hotterflame_sfx)
      self.recovery = 15
    end
  end

  -- Wire Sea
  if self.super >= 16 and self.recovery > 15 and self.recovery < 40 then
    if self.isSupering and self.life > 25 then
      self.life = self.life - 20
    elseif not self.isSupering then
      self.super = self.super - 16
    end
    self.recovery = 0
    self.waiting_state = ""
    WireSea:postLoadFXCorrect2(self.center, self.pos[2], 0, 0, self.facing, 0, true)
    self:land()
    p1:setFrozen(10)
    p2:setFrozen(10)
  end
end

function Sun:air_special()
  local v_distance = stage.floor - (self.pos[2] + self.sprite_size[2])

  if self.super >= 8 and self:getNeutral() and v_distance > 100 then
    if not self.isSupering then self.super = self.super - 8 end
    self.waiting_state = ""
    --writeSound(self.air_special_sfx)
    self.gravity = 0
    self.vel[1] = -60 * self.facing
    self.vel[2] = v_distance / 30
    self.riotbackdash = true
  end
end

function Sun:stateCheck()
  if self.waiting > 0 then
    self.waiting = self.waiting - 1
    if self.waiting == 0 and self.waiting_state == "Jump" then
      self.waiting_state = ""
      self:jump(0, 15)
      writeSound(self.jump_sfx)
    end
    if self.waiting == 0 and self.waiting_state == "Attack" then 
      self.waiting_state = ""
      self:attack(5, 11)
    end
    if self.waiting == 0 and self.waiting_state == "Kickback" then
      self.waiting_state = ""
      self:kickback(-4, 7)
      writeSound(self.jump_sfx)
    end
  end
end

function Sun:extraStuff()
  --[[-------------------------------------------------------------------------
                            HOTFLAME/HOTTERFLAME LOGIC
  -------------------------------------------------------------------------]]--        
  for i = 1, 4 do
    if self.hotflametime[i] > 0 then
      self.isAttacking = true
      
      if self.frozenFrames == 0 and not self.foe.hitflag.Projectile then 
        self.hotflametime[i] = self.hotflametime[i] - 1
        if self.hotflametime[i] == 15 then
          self.hotflametime[i + 1] = 30
          Hotflame:playSound()
        end
        if self.hotflametime[i] <= 30 then -- low quality way to implement startup
          self.hitboxes_hotflame[#self.hitboxes_hotflame + 1] = {
            L = self.sprite_size[1] + (45 * (i - 1)) + 20,
            U = self.sprite_size[2] - 110, 
            R = self.sprite_size[1] + (45 * (i - 1)) + 30 , 
            D = self.sprite_size[2],
            Flag1 = "Fire",
            Flag2 = "Projectile"} 
        end
      end

      if self.hotflametime[i] <= 35 then -- low quality way to implmement startup
        Hotflame:postRepeatFXCorrect2(self.hotflaming_pos[1] + self.sprite_size[1] / 2,
          self.hotflaming_pos[2],
          self.sprite_size[1] / 2 + Hotflame.sprite_size[1] / 2 + 45 * (i - 1),
          self.sprite_size[2] - Hotflame.sprite_size[2],
          self.facing)
      end
    end
  end

  if self.hotterflametime > 0 then
    self.isAttacking = true

    Hotterflame:postLoadFXCorrect2(self.hotflaming_pos[1] + self.sprite_size[1] / 2,
      self.hotflaming_pos[2],
      self.sprite_size[1] / 2,
      self.sprite_size[2] - Hotterflame.sprite_size[2],
      self.facing)

    if self.frozenFrames == 0 and not self.foe.hitflag.Projectile then
      self.hotterflametime = self.hotterflametime - 1
      self.hitboxes_hotflame[1] = {
        L = self.sprite_size[1] - self.sprite_wallspace,
        U = self.sprite_size[2] - 120,
        R = self.sprite_size[1] - self.sprite_wallspace + 126,
        D = self.sprite_size[2],
        Flag1 = "Fire",
        Flag2 = "Projectile"}
    end
  end  

  local temp_hotflame = {}
  for i = 1, #self.hitboxes_hotflame do
    temp_hotflame[i] = {L = 0, U = 0, R = 0, D = 0}
  end

  if self.isAttacking and not self.hasWon and not self.foe.hasWon and self.facing == 1 then
    for i = 1, #self.hitboxes_hotflame do
      temp_hotflame[i].L = self.hitboxes_hotflame[i].L + self.hotflaming_pos[1]
      temp_hotflame[i].U = self.hitboxes_hotflame[i].U + self.hotflaming_pos[2]
      temp_hotflame[i].R = self.hitboxes_hotflame[i].R + self.hotflaming_pos[1]
      temp_hotflame[i].D = self.hitboxes_hotflame[i].D + self.hotflaming_pos[2]
      temp_hotflame[i].Flag1 = self.hitboxes_hotflame[i].Flag1
      temp_hotflame[i].Flag2 = self.hitboxes_hotflame[i].Flag2
    end
  elseif self.isAttacking and not self.hasWon and not self.foe.hasWon and self.facing == -1 then
    for i = 1, #self.hitboxes_hotflame do
      temp_hotflame[i].L = self.hotflaming_pos[1] - self.hitboxes_hotflame[i].R + self.sprite_size[1]
      temp_hotflame[i].U = self.hitboxes_hotflame[i].U + self.hotflaming_pos[2]
      temp_hotflame[i].R = self.hotflaming_pos[1] - self.hitboxes_hotflame[i].L + self.sprite_size[1]
      temp_hotflame[i].D = self.hitboxes_hotflame[i].D + self.hotflaming_pos[2]
      temp_hotflame[i].Flag1 = self.hitboxes_hotflame[i].Flag1
      temp_hotflame[i].Flag2 = self.hitboxes_hotflame[i].Flag2
    end
  end

  for i = 1, #temp_hotflame do
    self.hitboxes[#self.hitboxes+1] = temp_hotflame[i]
  end

  self.hitboxes_hotflame = {{L = 0, U = 0, R = 0, D = 0}}

  --------------------------------RIOT KICK -----------------------------------
  if self.riotbackdash then
    local v_distance = stage.floor - (self.pos[2] + self.sprite_size[2])
    if v_distance < 10 and self.hasHitWall then
      self.vel[1] = 12 * self.facing
      self.vel[2] = 0
      self.hasHitWall = false
      self.riotbackdash = false
      self.riotkick = true
      self.isAttacking = true
    end
  end
  if self.riotkick then
    self:updateImage(7)
    self.current_hurtboxes = self.hurtboxes_riotkick
    self.current_hitboxes = self.hitboxes_riotkick
    if self.hasHitWall then
      self.riotkick = false
      self.isAttacking = false
      self.gravity = self.default_gravity
      self.vel[1] = 0
      self.vel[2] = 0
    end
  end
end

function Sun:gotHit(type_table)
  self.riotkick = false
  self.riotbackdash = false
  self.hitboxes = self.hitboxes_neutral
  Fighter.gotHit(self, type_table)
end

function Sun:hitOpponent()
  self.hitboxes = self.hitboxes_neutral
  Fighter.hitOpponent(self)
end

function Sun:victoryPose()
  if frame - round_end_frame == 60 then
    self.hotflametime = {0, 0, 0, 0, 0}
    self.riotkick = false
    self.riotbackdash = false
  end
  Fighter.victoryPose(self)
end

function Sun:updateSuper()
  if self.super >= 96 then
    self.super = 95.999
    writeSound(super_sfx)
    self.isSupering = true
    self.vel_multiple = self.vel_multiple_super
    game.superfreeze_time = 60
    game.superfreeze_player = self
    p1:setFrozen(100)
    p2:setFrozen(100)
    pauseBGM()
    setBGM2(self.aura_BGM)
    writeSound(self.radio_sfx)
    game.background_color = {255, 128, 128, 255}
  end

  if self.isSupering then
    SunAura:preRepeatFXCorrect2(self.center, self.pos[2], 0, self.sprite_size[2] - SunAura.sprite_size[2], self.facing)

    if not (self.isKO or self.hasWon) then
      self.super = self.super - self.super_drainspeed
      self.life = math.max(self.life - 0.75, 0)
      if self.life == 0 then
        round_end_frame = frame
        round_ended = true
        self:gotHit(self.foe.hit_type)
        self.foe:hitOpponent()
      end
    end
  end

  if self.super < 0 then -- turn off Frog Factor
    self.super = 0
    self.isSupering = false
    self.vel_multiple = 1.0
    stopBGM2()
    resumeBGM()
    game.background_color = {255, 128, 128, 255}
  end  
end

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
	self.wow = false
	self.lean_frames = 0
	self.moonwalk_frames = 0

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
    {L = 37, U = 153, R = 67, D = 187}}
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
  self.jump_sfx = "Frogson/FrogsonJump.ogg" -- placeholder
  self.attack_sfx = "Frogson/FrogsonAttack.ogg" -- placeholder
  self.got_hit_sfx = "Frogson/FrogsonKO.ogg" -- placeholder
  self.hit_sound_sfx = "Potatoes.ogg"
  self.moonwalk1_sfx = "Frogson/Moonwalk1.ogg"
  self.moonwalk2_sfx = "Frogson/Moonwalk2.ogg"
  self.wow_sfx = "Frogson/Thriller.ogg"
  self.antigravity_sfx = "Frogson/BeatIt.ogg"

  self:init2(init_player, init_foe, init_super, init_dizzy, init_score)
end



  function Frogson:attack_key_press()
    -- attack if in air and not already attacking and either: >50 above floor, or landing and >30 above.
    if self.isInAir and not self.isAttacking and not self.wow and
      (self.pos[2] + self.sprite_size[2] < stage.floor - 50 or
      (self.vel[2] > 0 and self.pos[2] + self.sprite_size[2] < stage.floor - 30)) then
        self.waiting = 3
        self.waiting_state = "Attack"
    -- if on ground, kickback
    elseif not self.isInAir and self.moonwalk_frames == 0 then
      self.waiting = 3
      self.waiting_state = "Kickback"
    end
    Fighter.attack_key_press(self) -- check for special move
  end

  function Frogson:air_special()
    if self.super >= 16 and not self.isAttacking and
    self.pos[2] + self.sprite_size[2] < stage.floor - 50 then
      self.super = self.super - 16
      self.waiting_state = ""
      --HyperKickFlames:playSound()
      self.vel = {0, 0}
      self.wow = true
      self:updateImage(7)
      self.gravity = 0
      self.current_hurtboxes = self.hurtboxes_attacking
      self.current_hitboxes = self.hitboxes_hyperkick
    end
  end

  function Frogson:ground_special()
    if self.super >= 8 then
      self.super = self.super - 8
      self.waiting_state = ""
      --writeSound(self.ground_special_sfx)
      self:updateImage(6)
      self.current_hurtboxes = self.hurtboxes_antigravity
      self.current_hitboxes = self.hitboxes_antigravity
      self.lean_frames = 20
      self.jackson_stance = not self.jackson_stance
      self.isAttacking = true
    end
  end

  function Frogson:jump(h_vel, v_vel, gravity)
    self.isInAir = true
    self.gravity = gravity
    self.vel = {h_vel * self.facing, -v_vel}
    self:updateImage(1)
    self.current_hurtboxes = self.hurtboxes_jumping
  end

  function Frogson:land() -- called when character lands on floor
    self.isInAir = false
    self.isAttacking = false
    self.wow = false
    if not self.isKO then
      self.vel = {0, 0}
      self:updateImage(0)
      self.current_hurtboxes = self.hurtboxes_standing
    end
  end

  function Frogson:stateCheck()
    if self.waiting > 0 then
      self.waiting = self.waiting - 1
      if self.waiting == 0 and self.waiting_state == "Jump" then
        self.waiting_state = ""
        writeSound(self.jump_sfx)
        JumpDust:singleLoad(self.center, self.pos[2], 0, self.sprite_size[2] - JumpDust.height, self.facing)
        
        if self.jackson_stance then
        	self:jump(0, 8, self.default_gravity * 0.5)
        else
        	self:jump(0, 14, self.default_gravity)
        end
      end
			if self.waiting == 0 and self.waiting_state == "Attack" then 
        self.waiting_state = ""
        writeSound(self.attack_sfx)
        
        if self.jackson_stance then
        	self:attack_jackson(7, 3.2)
        else
        	self:attack_bison(7.5, 11)
        end
      end

      if self.waiting == 0 and self.waiting_state == "Kickback" then
        self.waiting_state = ""
        self:moonwalk(30, 4)
        self.jackson_stance = not self.jackson_stance
        writeSound(self.jump_sfx)
      end
    end
  end

	function Frogson:updateImage(image_index)
		local stance = 0
		if self.jackson_stance then stance = 1 end
	  self.sprite = love.graphics.newQuad(image_index * self.sprite_size[1], stance * 200,
	    self.sprite_size[1], self.sprite_size[2],
	    self.image_size[1], self.image_size[2])
	end

	function Frogson:attack_bison(h_vel, v_vel)
	  self.vel = {h_vel * self.facing, v_vel}
	  self.isAttacking = true
	  self:updateImage(4)
	  self.gravity = 0
	  self.current_hurtboxes = self.hurtboxes_attacking_bison
	  self.current_hitboxes = self.hitboxes_attacking_bison
	  if self.super < 96 and not self.isSupering then 
	    self.super = math.min(self.super + 8, 96)
	    if self.super == 96 then writeSound(super_sfx) end
	  end
	end

	function Frogson:attack_jackson(h_vel, v_vel)
	  self.vel = {h_vel * self.facing, v_vel}
	  self.isAttacking = true
	  self:updateImage(4)
	  self.gravity = 0
	  self.current_hurtboxes = self.hurtboxes_attacking_jackson
	  self.current_hitboxes = self.hitboxes_attacking_jackson
	  if self.super < 96 and not self.isSupering then 
	    self.super = math.min(self.super + 8, 96)
	    if self.super == 96 then writeSound(super_sfx) end
	  end
	end

	function Frogson:moonwalk(frames, h_vel)
		self.moonwalk_frames = frames
		self.vel = {-h_vel * self.facing, 0}
		self:updateImage(3)
		self.current_hurtboxes = self.hurtboxes_moonwalk
		KickbackDust:singleLoad(self.center,
    self.pos[2], 0, self.sprite_size[2] - KickbackDust.height, self.facing)
	end

  function Frogson:extraStuff()
  	if self.moonwalk_frames > 0 then
  		self.moonwalk_frames = math.max(self.moonwalk_frames - 1, 0)
  		self.super = self.super + 0.25
  		if self.moonwalk_frames <= 0 then
  			self:land()
  		end
  	end

  	if self.lean_frames > 0 and not self.hasWon then
  		self.lean_frames = math.max(self.lean_frames - 1, 0)
  		if self.lean_frames <= 0 then
  			self:land()
  		end
  	end
  end

	function Fighter:getNeutral()
	  return not self.isKO and not self.isAttacking and self.recovery == 0 and self.moonwalk_frames == 0
	end

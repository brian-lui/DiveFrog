local class = require 'middleclass'
require 'utilities'
draw_count = 0 -- each object gets a new index number, to prevent overwriting

--[[---------------------------------------------------------------------------
                              PARTICLE / FX CLASS
-----------------------------------------------------------------------------]]   
Particle = class('Particle')
function Particle:initialize(image, image_size, sprite_size, time_per_frame, sound, h_center, v_center)
  self.image = image
  self.image_size = {image:getDimensions()}
  self.sprite_size = sprite_size
  self.width = sprite_size[1]
  self.height = sprite_size[2]
  self.center = sprite_size[1] / 2
  self.hitbox = hitbox_table
  self.sound = sound
  self.total_frames = image_size[1] / sprite_size[1]
  self.time_per_frame = time_per_frame
  self.total_time = time_per_frame * self.total_frames
  if h_center then self.h_adjust = self.width / 2 else self.h_adjust = 0 end
  if v_center then self.v_adjust = self.height / 2 else self.v_adjust = 0 end
end

function Particle:getDrawable(image_index, pos_h, pos_v, scale_x, scale_y, shift, RGBTable)
  local quad = love.graphics.newQuad(image_index * self.width, 0,
    self.width, self.height, self.image_size[1], self.image_size[2])
  return {self.image, 
    quad, 
    pos_h - self.h_adjust,
    pos_v - self.v_adjust,
    0, -- rotation
    scale_x, -- scale_x: 1 is default, -1 for flip
    scale_y, -- scale_y: 1 is default, 1 for flip
    shift, -- offset_x
    0, -- offset_y: 0
    0, -- shear_x: 0
    0} -- shear_y: 0
    -- RGBTable not supported yet
end

-- called each frame while condition is valid
function Particle:preRepeatFX(pos_h, pos_v, facing, shift, delay_time) 
  draw_count = draw_count + 1
  local delay = delay_time or 0
  local current_anim = math.floor((frame + delay) % (self.total_time) / self.time_per_frame)
  prebuffer[frame + delay] = prebuffer[frame + delay] or {}
  prebuffer[frame + delay][draw_count] = self:getDrawable(current_anim,
    pos_h,
    pos_v,
    facing, math.abs(facing), shift)
end

 -- called each frame while condition is valid
function Particle:postRepeatFX(pos_h, pos_v, facing, shift, delay_time)
  draw_count = draw_count + 1
  local delay = delay_time or 0
  local current_anim = math.floor((frame + delay) % (self.total_time) / self.time_per_frame)
  postbuffer[frame + delay] = postbuffer[frame + delay] or {}
  postbuffer[frame + delay][draw_count] = self:getDrawable(current_anim,
    pos_h,
    pos_v,
    facing, math.abs(facing), shift)
end

-- called once, loads entire anim
function Particle:preLoadFX(pos_h, pos_v, facing, shift, delay_time)
  draw_count = draw_count + 1
  local delay = delay_time or 0
  for i = (frame + delay), (frame + delay + self.total_time) do
    local current_anim = math.floor((i - (frame + delay)) / self.time_per_frame)
    prebuffer[i] = prebuffer[i] or {}
    prebuffer[i][draw_count] = self:getDrawable(current_anim,
      pos_h,
      pos_v,
      facing, math.abs(facing), shift)
  end
end

-- called once, loads entire anim
function Particle:postLoadFX(pos_h, pos_v, facing, shift, delay_time)
  draw_count = draw_count + 1
  local delay = delay_time or 0
  for i = (frame + delay), (frame + delay + self.total_time) do
    local current_anim = math.floor((i - (frame + delay)) / self.time_per_frame)
    postbuffer[i] = postbuffer[i] or {}
    postbuffer[i][draw_count] = self:getDrawable(current_anim,
      pos_h,
      pos_v,
      facing, math.abs(facing), shift)
  end
end

function Particle:playSound(delay_time)
  writeSound(self.sound, delay_time)
end

--[[---------------------------------------------------------------------------
                            AFTERIMAGES SUB-CLASS
-----------------------------------------------------------------------------]]   
AfterImage = class('AfterImage', Particle)
function AfterImage:initialize(image, image_size, sprite_size, time_per_frame, sound)
  Particle.initialize(self, image, image_size, sprite_size, time_per_frame, sound)
end

function AfterImage:loadFX(pos_h, pos_v, quad, facing, shift)
  local shadow = {
    [8] = {255, 180, 0, 200},
    [16] = {255, 180, 0, 150}, 
    [24] = {255, 180, 0, 100}
  }
  for s_frame, color in pairs(shadow) do
    draw_count = draw_count + 1
    prebuffer[frame + s_frame] = prebuffer[frame + s_frame] or {}
    prebuffer[frame + s_frame][draw_count] = {self.image, quad, pos_h, pos_v, 0, facing, 1, shift, 0, 0, 0, color}
  end
end
  
------------------------------ COMMON PARTICLES -------------------------------
Mugshot = Particle:new(love.graphics.newImage('images/Mugshot.png'),
  {600, 140}, {600, 140}, 60, "Mugshot.ogg", true, true)
Dizzy = Particle:new(love.graphics.newImage('images/Dizzy.png'),
  {70, 50}, {70, 50}, 1, true)
OnFire = Particle:new(love.graphics.newImage('images/OnFire.png'),
  {800, 200}, {200, 200}, 3)
JumpDust = Particle:new(love.graphics.newImage('images/JumpDust.png'), 
  {528, 60}, {132, 60}, 4, "dummy.ogg", true, true)
KickbackDust = Particle:new(love.graphics.newImage('images/KickbackDust.png'), 
  {162, 42}, {54, 42}, 4)
WireSea = Particle:new(love.graphics.newImage('images/WireSea.png'),
  {1600, 220}, {200, 220}, 2, "WireSea.ogg", true, true)
--Wallsplat = Particle:new(love.graphics.newImage('images/Wallsplat.png'),
--  {3072, 128}, {128, 128}, 3, "Explosion.ogg")
Explosion1 = Particle:new(love.graphics.newImage('images/Explosion1.png'),
  {800, 80}, {80, 80}, 3, "Explosion.ogg", true, true)
Explosion2 = Particle:new(love.graphics.newImage('images/Explosion2.png'),
  {880, 80}, {80, 80}, 3, "dummy.ogg", true, true)
Explosion3 = Particle:new(love.graphics.newImage('images/Explosion3.png'),
  {880, 80}, {80, 80}, 3, "dummy.ogg", true, true)


----------------------------------- KONRAD ------------------------------------
HyperKickFlames = Particle:new(love.graphics.newImage('images/Konrad/HyperKickFlames.png'),
  {800, 200}, {200, 200}, 2, "Konrad/KonradHyperKick.ogg")
DoubleJumpDust = Particle:new(love.graphics.newImage('images/Konrad/DoubleJumpDust.png'),
  {162, 43}, {54, 43}, 4, "Konrad/KonradDoubleJump.ogg")

-------------------------------- SUN BADFROG ----------------------------------
SunAura = Particle:new(love.graphics.newImage('images/Sun/Aura.png'),
  {800, 250}, {200, 250}, 6)
Hotflame = Particle:new(love.graphics.newImage('images/Sun/HotflameFX.png'),
  {120, 195}, {60, 195}, 4, "Sun/Hotflame.ogg")
Hotterflame = Particle:new(love.graphics.newImage('images/Sun/HotterflameFX.png'),
  {300, 252}, {150, 252}, 4, "Sun/Hotterflame.ogg")
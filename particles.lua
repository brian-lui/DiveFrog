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
  self.sprite_center = sprite_size[1] / 2
  self.hitbox = hitbox_table
  self.sound = sound
  self.total_frames = image_size[1] / sprite_size[1]
  self.time_per_frame = time_per_frame
  self.total_time = time_per_frame * self.total_frames
  if h_center then self.h_adjust = self.sprite_size[1] / 2 else self.h_adjust = 0 end
  if v_center then self.v_adjust = self.sprite_size[2] / 2 else self.v_adjust = 0 end

end

-- not centered
function Particle:getDrawable(image_index, pos_h, pos_v, scale_x, scale_y, shift, RGBTable)
  local quad = love.graphics.newQuad(image_index * self.sprite_size[1], 0,
    self.sprite_size[1], self.sprite_size[2], self.image_size[1], self.image_size[2])
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
function Particle:preRepeatFX(pos_h, pos_v, facing, shift) 
  draw_count = draw_count + 1
  local current_anim = math.floor(frame % (self.total_time) / self.time_per_frame)
  prebuffer[frame] = prebuffer[frame] or {}
  prebuffer[frame][draw_count] = self:getDrawable(current_anim,
    pos_h,
    pos_v,
    facing, math.abs(facing), shift)
end

 -- called each frame while condition is valid
function Particle:postRepeatFX(pos_h, pos_v, facing, shift)
  draw_count = draw_count + 1

  local current_anim = math.floor(frame % (self.total_time) / self.time_per_frame)
  postbuffer[frame] = postbuffer[frsame] or {}
  postbuffer[frame][draw_count] = self:getDrawable(current_anim,
    pos_h,
    pos_v,
    facing, math.abs(facing), shift)
end

-- called once, loads entire anim
function Particle:postLoadFX(pos_h, pos_v, facing, shift, time_to_display)
  draw_count = draw_count + 1
  local duration = time_to_display or self.total_time - 1
  for i = frame, (frame + duration) do
    local current_anim = math.floor((i - frame) / self.time_per_frame)

    postbuffer[i] = postbuffer[i] or {}
    postbuffer[i][draw_count] = self:getDrawable(current_anim,
      pos_h,
      pos_v,
      facing, math.abs(facing), shift)
  end
end

function Particle:playSound()
  playSFX(self.sound)
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
  {610, 122}, {122, 122}, 3, "WireSea.ogg", true, true)
Wallsplat = Particle:new(love.graphics.newImage('images/Wallsplat.png'),
  {3072, 128}, {128, 128}, 3, "Explosion.ogg")

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



---------------------------- EXPLOSION ----------------------------------------
Explosion = Particle:new(love.graphics.newImage('images/Explosion.png'), {768, 64}, {64, 64}, 2)

function Explosion:loadFX(pos_h, pos_v, vel_h, vel_v, friction, gravity)
  draw_count = draw_count + 1

  local TIME_DIV = 2 -- advance the animation every TIME_DIV frames
  for i = frame, (frame + 23) do
    local index = math.floor((i - frame) / TIME_DIV) -- get the animation frame
    local h_displacement = (vel_h / (friction - 1)) * math.exp((friction - 1) * index / TIME_DIV) - vel_h / (friction - 1)

    -- write the animation frames to postbuffer
    postbuffer[i] = postbuffer[i] or {}
    postbuffer[i][draw_count] = Explosion:getDrawable(index, pos_h + h_displacement - self.sprite_size[1] / 2, pos_v + (vel_v * index) - self.sprite_size[2] / 2, 2, 1, 0)
  end
end



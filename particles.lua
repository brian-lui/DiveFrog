local class = require 'middleclass'
require 'utilities'
draw_count = 0 -- each object gets a new index number, to prevent overwriting

--[[---------------------------------------------------------------------------
                              PARTICLE / FX CLASS
-----------------------------------------------------------------------------]]   
Particle = class('Particle')
function Particle:initialize(image, image_size, sprite_size)
  self.image = image
  self.image_size = {image:getDimensions()}
  self.sprite_size = sprite_size
  self.hitbox = {}
end

function Particle:getDrawable(image_index, pos_h, pos_v, scale_x, scale_y, shift)
  local quad = love.graphics.newQuad(image_index * self.sprite_size[1], 0,
   self.sprite_size[1], self.sprite_size[2], self.image_size[1], self.image_size[2])
  return {self.image, 
    quad, 
    pos_h - self.sprite_size[1] / 2, -- returns horizontal CENTER of sprite
    pos_v - self.sprite_size[2] / 2, -- returns vertical CENTER of sprite
    0, -- rotation
    scale_x, -- scale_x: 1 is default, -1 for flip
    scale_y, -- scale_y: 1 is default, 1 for flip
    shift, -- offset_x
    0, -- offset_y: 0
    0, -- shear_x: 0
    0} -- shear_y: 0
end

--[[---------------------------------------------------------------------------
                            AFTERIMAGES SUB-CLASS
-----------------------------------------------------------------------------]]   
AfterImage = class('AfterImage', Particle)
function AfterImage:initialize(image, image_size, sprite_size)
  Particle.initialize(self, image, image_size, sprite_size)
end

function AfterImage:loadFX(pos_h, pos_v, quad, facing, shift, RGBTable)
  draw_count = draw_count + 1
  prebuffer[frame + 10] = prebuffer[frame + 10] or {}
  prebuffer[frame + 10][draw_count] = {self.image, quad, pos_h, pos_v, 0, facing, 1, shift, 0, 0, 0, {255, 180, 0, 200}}
  draw_count = draw_count + 1
  prebuffer[frame + 20] = prebuffer[frame + 20] or {}
  prebuffer[frame + 20][draw_count] = {self.image, quad, pos_h, pos_v, 0, facing, 1, shift, 0, 0, 0, {255, 180, 0, 120}}
end

--------------------------------- MUGSHOTTED ----------------------------------
-- example for a single-image particle, with no need to cycle through
-- called once
Mugshot = Particle:new(love.graphics.newImage('images/Mugshot.png'), {600, 140}, {600, 140})
function Mugshot:loadFX()
  draw_count = draw_count + 1
  
  for i = (frame + 20), (frame + 90) do
    postbuffer[i] = postbuffer[i] or {}
    postbuffer[i][draw_count] = Mugshot:getDrawable(0, 400 + camera_xy[1], 200 + camera_xy[2], 1, 1, 0)
  end
end
  
----------------------------------- DIZZY -------------------------------------
-- example for a single-image particle, with no need to cycle through
-- called repeatedly while character is dizzy
Dizzy = Particle:new(love.graphics.newImage('images/Dizzy.png'), {70, 50}, {70, 50})
function Dizzy:loadFX(pos_h, pos_v)
  draw_count = draw_count + 1

  -- write the animation frames to postbuffer
  postbuffer[frame] = postbuffer[frame] or {}
  postbuffer[frame][draw_count] = Dizzy:getDrawable(0, pos_h, pos_v, 1, 1, 0)
end

-------------------------- KONRAD HYPER KICK FLAMES ---------------------------
-- example for a cycling particle, that's only called if Konrad is still in hyper kick
-- this example doesn't care about the start frame. We need another variable if we care

HyperKickFlames = Particle:new(love.graphics.newImage('images/Konrad/HyperKickFlames.png'), {360, 160}, {90, 160})

function HyperKickFlames:loadFX(pos_h, pos_v, facing, shift)
  draw_count = draw_count + 1
  local TIME_DIV = 2 -- advance the animation every TIME_DIV frames
  local current_anim_frame = math.floor((frame % 8) / TIME_DIV)

  postbuffer[frame] = postbuffer[frame] or {}
  postbuffer[frame][draw_count] = HyperKickFlames:getDrawable(current_anim_frame,
    pos_h, -- we want the corner, not the center for this anim
    pos_v - self.sprite_size[2] / 2, -- ditto
    facing, 1, shift) -- hard coded variables ok. I don't want to think too hard for this
  print(current_anim_frame, pos_h, pos_v, facing, 1, shift)
end

------------------------------- KICKBACK DUST ---------------------------------
KickbackDust = Particle:new(love.graphics.newImage('images/KickbackDust.png'), {162, 42}, {54, 42})

function KickbackDust:loadFX(pos_h, pos_v, facing, shift)
  draw_count = draw_count + 1

  local TIME_DIV = 4 -- advance the animation every TIME_DIV frames
  for i = frame, (frame + 11) do
    local index = math.floor((i - frame) / TIME_DIV) -- get the animation frame

    -- write the animation frames to postbuffer
    postbuffer[i] = postbuffer[i] or {}
    postbuffer[i][draw_count] = KickbackDust:getDrawable(index, pos_h, pos_v, facing, 1, shift * 54)
  end
end


--------------------------------- JUMP DUST -----------------------------------
JumpDust = Particle:new(love.graphics.newImage('images/JumpDust.png'), {528, 60}, {132, 60})

function JumpDust:loadFX(pos_h, pos_v, facing, shift)
  draw_count = draw_count + 1

  local TIME_DIV = 4 -- advance the animation every TIME_DIV frames
  for i = frame, (frame + 15) do
    local index = math.floor((i - frame) / TIME_DIV) -- get the animation frame

    -- write the animation frames to postbuffer
    postbuffer[i] = postbuffer[i] or {}
    postbuffer[i][draw_count] = JumpDust:getDrawable(index, pos_h, pos_v, facing, 1, shift * 132)
  end
end

-------------------------- KONRAD DOUBLE-JUMP DUST ----------------------------
DoubleJumpDust = Particle:new(love.graphics.newImage('images/Konrad/DoubleJumpDust.png'), {162, 43}, {54, 43})

function DoubleJumpDust:loadFX(pos_h, pos_v, facing, shift)
  draw_count = draw_count + 1

  local TIME_DIV = 4 -- advance the animation every TIME_DIV frames
  for i = frame, (frame + 11) do
    local index = math.floor((i - frame) / TIME_DIV) -- get the animation frame

    -- write the animation frames to postbuffer
    postbuffer[i] = postbuffer[i] or {}
    postbuffer[i][draw_count] = DoubleJumpDust:getDrawable(index, pos_h, pos_v, facing, 1, shift * 54)
  end
end



--------------------------------- WALLSPLAT -----------------------------------
Wallsplat = Particle:new(love.graphics.newImage('images/Wallsplat.png'), {3072, 128}, {128, 128})

function Wallsplat:loadFX(pos_h, pos_v)
  draw_count = draw_count + 1

  local TIME_DIV = 3 -- advance the animation every TIME_DIV frames
  for i = frame, (frame + 71) do
    local index = math.floor((i - frame) / TIME_DIV) -- get the animation frame

    -- write the animation frames to postbuffer
    postbuffer[i] = postbuffer[i] or {}
    postbuffer[i][draw_count] = Wallsplat:getDrawable(index, pos_h - 20, pos_v - 20, 3, 3, 0)
  end
end

---------------------------------- WIRE SEA -----------------------------------
WireSea = Particle:new(love.graphics.newImage('images/WireSea.png'), {610, 122}, {122, 122})

function WireSea:loadFX(pos_h, pos_v)
  draw_count = draw_count + 1

  local TIME_DIV = 3 -- advance the animation every TIME_DIV frames
  for i = frame, (frame + 14) do
    local index = math.floor((i - frame) / TIME_DIV) -- get the animation frame

    -- write the animation frames to postbuffer
    postbuffer[i] = postbuffer[i] or {}
    postbuffer[i][draw_count] = WireSea:getDrawable(index, pos_h, pos_v, 1, 1, 0)
  end
end

--------------------------------- EXPLOSION -----------------------------------
Explosion = Particle:new(love.graphics.newImage('images/Explosion.png'), {768, 64}, {64, 64})

function Explosion:loadFX(pos_h, pos_v, vel_h, vel_v, friction, gravity)
  draw_count = draw_count + 1

  local TIME_DIV = 2 -- advance the animation every TIME_DIV frames
  for i = frame, (frame + 23) do
    local index = math.floor((i - frame) / TIME_DIV) -- get the animation frame
    local h_displacement = (vel_h / (friction - 1)) * math.exp((friction - 1) * index / TIME_DIV) - vel_h / (friction - 1)

    -- write the animation frames to postbuffer
    postbuffer[i] = postbuffer[i] or {}
    postbuffer[i][draw_count] = Explosion:getDrawable(index, pos_h + h_displacement, pos_v + (vel_v * index), 2, 1, 0)
  end
end


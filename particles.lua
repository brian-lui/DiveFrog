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

function Particle:getDrawable(image_index, pos_h, pos_v)
  local quad = love.graphics.newQuad(image_index * self.sprite_size[1], 0,
   self.sprite_size[1], self.sprite_size[2], self.image_size[1], self.image_size[2])
  return {self.image, quad, pos_h - self.sprite_size[1] / 2, pos_v - self.sprite_size[2] / 2}
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
  -- 'more solid' afterimage
  if not drawprebuffer[frame + 10] then drawprebuffer[frame + 10] = {} end
  drawprebuffer[frame + 10][draw_count] = {self.image, quad, pos_h, pos_v, 0, facing, 1, shift, 0, 0, 0, {255, 180, 0, 200}}

  draw_count = draw_count + 1
  -- 'less solid' afterimage  
  if not drawprebuffer[frame + 20] then drawprebuffer[frame + 20] = {} end
  drawprebuffer[frame + 20][draw_count] = {self.image, quad, pos_h, pos_v, 0, facing, 1, shift, 0, 0, 0, {255, 180, 0, 120}}
end

--------------------------------- MUGSHOTTED ----------------------------------
-- example for a single-image particle, with no need to cycle through
-- called once
Mugshot = Particle:new(love.graphics.newImage('images/Mugshot.png'), {600, 140}, {600, 140})
function Mugshot:loadFX()
  draw_count = draw_count + 1
  
  for i = (frame + 20), (frame + 90) do
    if not drawbuffer[i] then drawbuffer[i] = {} end
    drawbuffer[i][draw_count] = Mugshot:getDrawable(0, 400, 200)
  end
end
  

----------------------------------- DIZZY -------------------------------------
-- example for a single-image particle, with no need to cycle through
-- called repeatedly while character is dizzy
Dizzy = Particle:new(love.graphics.newImage('images/Dizzy.png'), {70, 50}, {70, 50})
function Dizzy:loadFX(pos_h, pos_v)
  draw_count = draw_count + 1

  -- write the animation frames to drawbuffer
  if not drawbuffer[frame] then drawbuffer[frame] = {} end
  drawbuffer[frame][draw_count] = Dizzy:getDrawable(0, pos_h, pos_v)
end





---------------------------------- WIRE SEA -----------------------------------
WireSea = Particle:new(love.graphics.newImage('images/WireSea.png'), {610, 122}, {122, 122})

function WireSea:loadFX(pos_h, pos_v)
  draw_count = draw_count + 1

  local TIME_DIV = 3 -- advance the animation every TIME_DIV frames
  for i = frame, (frame + 14) do
    local index = math.floor((i - frame) / TIME_DIV) -- get the animation frame

    -- write the animation frames to drawbuffer
    if not drawbuffer[i] then drawbuffer[i] = {} end
    drawbuffer[i][draw_count] = WireSea:getDrawable(index, pos_h, pos_v)
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

    -- write the animation frames to drawbuffer
    if not drawbuffer[i] then drawbuffer[i] = {} end
    drawbuffer[i][draw_count] = Explosion:getDrawable(index, pos_h + h_displacement, pos_v + (vel_v * index))
  end
end


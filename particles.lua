local class = require 'middleclass'
--local screen = require 'screen' -- for checking floor/walls
--local buttons = require 'controls' -- mapping of keyboard controls
require 'utilities'

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


-------------------------------- WIRE SEA -------------------------------------
WireSea = Particle:new(love.graphics.newImage('images/WireSea.png'), {610, 122}, {122, 122})

function WireSea:loadFX(pos_h, pos_v)
  for i = frame, (frame + 14) do
    local index = math.floor((i - frame) / 3)
    drawbuffer[i] = WireSea:getDrawable(index, pos_h, pos_v)
  end
end

-------------------------------- EXPLOSION ------------------------------------

Explosion = Particle:new(love.graphics.newImage('images/Explosion.png'), {768, 64}, {64, 64})

function Explosion:loadFX(pos_h, pos_v, vel_h, vel_v, friction, gravity)
  for i = frame, (frame + 23) do
    local index = math.floor((i - frame) / 2)
    local h_displacement = pos_h + (vel_h * index) -- so much for calculus!
    drawbuffer[i] = Explosion:getDrawable(index, pos_h + (vel_h * index), pos_v + (vel_v * index))
  end
end

require 'utilities'
local screen = require 'screen'

local Camera = {}
Camera.__index = Camera

Camera.margin = 0

function Camera.new()
  return setmetatable({
    x = 0,
    y = 0
  }, Camera)
end

local cam = Camera.new()
cam.margin = 0

-- this updated the camera position (?)
function Camera.update(c, p)
  local px, py = p:pixel()

  local targetX = clamp(
    -c.margin,
    math.floor(px - screen.widthPx / 2),
    map:widthPx() - screen.widthPx + c.margin
  )

  local targetY = clamp(
    -c.margin,
    math.floor(py - 5 - screen.heightPx / 2),
    map:heightPx() - screen.heightPx + c.margin
  )

  if math.abs(targetX - c.x) > 10 then
    c.x = c.x + (targetX - c.x) / 3
  else
    c.x = targetX
  end

  if math.abs(targetY - c.y) > 10 then
    c.y = c.y + (targetY - c.y) / 3
  else
    c.y = targetY
  end
end

function Camera.render(c, canvas, fun)
  love.graphics.push()
  love.graphics.translate(-c.x, -c.y)
  canvas:renderTo(fun)
  love.graphics.pop()
end

return cam

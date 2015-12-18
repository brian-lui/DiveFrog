local stage = require 'stage'
local window = require 'window'

function clamp(x, min, max)
  if x < min then
    return min
  elseif x > max then
    return max
  else
    return x
  end
end

function leftEdge() -- get temp left edge based on camera and window position
  return math.max(window.left + camera_xy[1], stage.left)
end

function rightEdge() -- get temp right edge based on camera and window position
  return math.min(window.right + camera_xy[1], stage.right)
end

function quadOverlap(quad1, quad2)
  left1, top1, right1, bottom1 = unpack(quad1)
  left2, top2, right2, bottom2 = unpack(quad2)

  if right1 > left2 and right2 > left1 and bottom1 > top2 and top1 < bottom2 then
    return true
  else
    return false
  end
end    

function check_got_hit(getting_hit, attacker) -- also applies Mugshot flag for headshots
  local gothit = false
  if attacker:getAttacking() then
    local hurt = getting_hit:getHurtboxes()
    local head = getting_hit:getHeadboxes()
    local hit = attacker:getHitboxes()
    for i = 1, #hurt do
      for j = 1, #hit do
        if(quadOverlap(hurt[i], hit[j])) then gothit = true end
      end
    end
    for i = 1, #head do
      for j = 1, #hit do
        if(quadOverlap(head[i], hit[j])) then
          attacker.hit_type.Mugshot = true
          gothit = true
        end
      end
    end
  end
  return gothit
end

function drawDebugSprites()
  love.graphics.line(p1.my_center, 0, p1.my_center, stage.height)
  love.graphics.line(p1.my_center, 190, p1.my_center + 30 * p1.facing, 190)
  love.graphics.line(p2.my_center, 0, p2.my_center, stage.height)
  love.graphics.line(p2.my_center, 200, p2.my_center + 30 * p2.facing, 200)
  love.graphics.rectangle("line", p1.pos[1], p1.pos[2], p1.sprite_size[1], p1.sprite_size[2])
  love.graphics.rectangle("line", p2.pos[1], p2.pos[2], p2.sprite_size[1], p2.sprite_size[2])
end      

function drawMidLines()
  love.graphics.push("all")
    love.graphics.setLineWidth(10)
    love.graphics.line(stage.center - 5, stage.height / 2, stage.center + 5, stage.height / 2)
    love.graphics.setLineWidth(20)
    love.graphics.line(window.center - 10, window.height / 2, window.center + 10, window.height / 2)
  love.graphics.pop()
end

function drawDebugHurtboxes()
  love.graphics.push("all")

  local dog = p1:getHurtboxes()
  love.graphics.setColor(255, 255, 255)
  for i = 1, #dog do
    love.graphics.line(dog[i][1], dog[i][2], dog[i][3], dog[i][2], dog[i][3], dog[i][4], dog[i][1], dog[i][4], dog[i][1], dog[i][2])
  end

  local blog = p2:getHurtboxes()
  for i = 1, #blog do
    love.graphics.line(blog[i][1], blog[i][2], blog[i][3], blog[i][2], blog[i][3], blog[i][4], blog[i][1], blog[i][4], blog[i][1], blog[i][2])
  end
  
  local rat = p1:getHitboxes()
  love.graphics.setColor(255, 0, 0)
  for i = 1, #rat do
    love.graphics.line(rat[i][1], rat[i][2], rat[i][3], rat[i][2], rat[i][3], rat[i][4], rat[i][1], rat[i][4], rat[i][1], rat[i][2])
  end

  local bob = p2:getHitboxes()
  for i = 1, #bob do
    love.graphics.line(bob[i][1], bob[i][2], bob[i][3], bob[i][2], bob[i][3], bob[i][4], bob[i][1], bob[i][4], bob[i][1], bob[i][2])
  end

  local poo = p1:getHeadboxes()
  love.graphics.setColor(0, 0, 255)
  for i = 1, #poo do
    love.graphics.line(poo[i][1], poo[i][2], poo[i][3], poo[i][2], poo[i][3], poo[i][4], poo[i][1], poo[i][4], poo[i][1], poo[i][2])
  end

  local pee = p2:getHeadboxes()
  for i = 1, #pee do
    love.graphics.line(pee[i][1], pee[i][2], pee[i][3], pee[i][2], pee[i][3], pee[i][4], pee[i][1], pee[i][4], pee[i][1], pee[i][2])
  end

  love.graphics.pop()
end

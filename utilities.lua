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

function quadOverlap(q1, q2)
  return q1.R > q2.L and q2.R > q1.L and q1.D > q2.U and q2.D > q1.U
end    

function check_got_hit(getting_hit, attacker)
  local gothit = false
  if attacker.isAttacking then
    local hurt = getting_hit.hurtboxes
    local hit = attacker.hitboxes
    for i = 1, #hurt do
      for j = 1, #hit do
        if(quadOverlap(hurt[i], hit[j])) then
          gothit = true
          local flag_list = {hurt[i].Flag1, hit[j].Flag1, hit[j].Flag2}
          for _, flag in pairs(flag_list) do
            if flag then attacker.hit_type[flag] = true end
          end
        end
      end
    end
  end
  return gothit
end

function writeSound(SFX, delay_time)
  local delay = delay_time or 0
  local write_frame = frame + delay
  while soundbuffer[write_frame] do
    write_frame = write_frame + 1
  end
  soundbuffer[write_frame] = SFX
end

function drawDebugSprites()
  for side, op in pairs(Players) do
    love.graphics.line(side.center, 0, side.center, stage.height)
    love.graphics.line(side.center, 200, side.center + op.flip * 30, 200)
    love.graphics.rectangle("line", side.pos[1], side.pos[2], side.sprite_size[1], side.sprite_size[2])
  end

  -- delete prebuffer[frame] = nil if using this. Draws unflipped, unshifted position.
  if prebuffer[frame] then 
    for index, _ in pairs(prebuffer[frame]) do
      local a, b, l, u = unpack(prebuffer[frame][index])
      love.graphics.line(l + 50, u, l - 50, u)
      love.graphics.line(l, u + 50, l, u - 50)
    end
  end
  -- delete postbuffer[frame] = nil if using this. Draws unflipped, unshifted position.
  if postbuffer[frame] then
    for index, _ in pairs(postbuffer[frame]) do
      local a, b, l, u = unpack(postbuffer[frame][index])
      love.graphics.line(l + 50, u, l - 50, u)
      love.graphics.line(l, u + 50, l, u - 50)
    end
  end


end      

function drawMidPoints()
  love.graphics.push("all")
    love.graphics.setLineWidth(10)
    love.graphics.line(stage.center - 5, stage.height / 2, stage.center + 5, stage.height / 2)
    love.graphics.setLineWidth(20)
    love.graphics.line(window.center - 10, window.height / 2, window.center + 10, window.height / 2)
  love.graphics.pop()
end

function drawDebugHurtboxes()
  love.graphics.push("all")
    local todraw = {p1.hurtboxes, p1.hitboxes, p2.hurtboxes, p2.hitboxes}
    local color = {{255, 255, 255, 192}, {255, 0, 0, 255}, {255, 255, 255, 192}, {255, 0, 0, 255}}
    for num, drawboxes in pairs(todraw) do
      local dog = drawboxes
      for i = 1, #dog do
        if dog[i].Flag1 == Mugshot then
          love.graphics.setColor({0, 0, 255, 160})
        else
          love.graphics.setColor(color[num])
        end
        local draw_width = dog[i].R - dog[i].L
        local draw_height = dog[i].D - dog[i].U
        love.graphics.rectangle("fill", dog[i].L, dog[i].U, draw_width, draw_height)
      end
    end
  love.graphics.pop()
end

local stage = require 'stage'
AI = {}

-- angle of attack, expressed as h_vel / v_vel. Lower = steeper angle 
AI.KillAngle = { 
  Konrad = 0.75,
  Jean = 1,
  Sun = 5 / 11,
  FrogsonB = 6 / 11,
  FrogsonJ = 1.5
	}

function AI.Action(player, foe)
	local sendjump = false
	local sendattack = false
  local myfrog = ""

  if player.fighter_name == "Konrad" then
    myfrog = AI.Konrad
  elseif player.fighter_name == "Mustachioed Jean" then
    myfrog = AI.Konrad
  elseif player.fighter_name == "Sun Badfrog" then
    myfrog = AI.Konrad
  elseif player.fighter_name == "M. Frogson" then
    myfrog = AI.Konrad
  else
    print("AI module not found for this character")
  end

  if frame % 6 == 0 then -- don't ask too often
    if player.isInAir then
      sendjump, sendattack = myfrog.inAir(player, foe)
    else
      sendjump, sendattack = myfrog.onGround(player, foe)
    end
  end

  return sendjump, sendattack
end

function AI._inKillRange(player, foe, killangle, variance)
  local v_adjust = math.random(-variance, variance)

  local player_foot = {player.center, player.pos[2] + player.sprite_size[2]}
  local foe_target = {foe.center, foe.pos[2] + v_adjust}

  local h_dist = math.abs(player_foot[1] - foe_target[1]) - 0.5 * player.sprite_size[1] - 0.5 * foe.sprite_size[1]
  local v_dist = math.abs(player_foot[2] - foe_target[2])

  local angle = h_dist / v_dist
  local player_above = player.pos[2] < foe.pos[2]

  return (angle < killangle) and player_above
end

function AI._isClose(player, foe, required_dist, variance)
  local dist_adjust = math.random(-variance, variance)

  local player_foot_h = player.pos[1] + player.sprite_size[1]
  if player.facing == -1 then
    player_foot_h = player.pos[1]
  end

  -- foe's closest side, top of sprite
  local foe_target_h = foe.pos[1]
  if foe.facing == -1 then
    foe_target_h = foe.pos[1] + foe.sprite_size[1]
  end

  local h_distance = math.abs(player_foot_h - foe_target_h)

  return h_distance < required_dist + dist_adjust
end

------------------------------------KONRAD-------------------------------------
AI.Konrad = {
  -- max height reached = v^2 / 2a (gives pixels above stage floor)
  MAX_JUMP_HEIGHT = 544,
  MAX_SUPERJUMP_HEIGHT = 700,
  MIN_KICK_HEIGHT = stage.floor - 50,

  FAR_JUMP = 0.7, -- otherwise kickback
  FAR_DOUBLEJUMP = 0.2,
  DOUBLEJUMP_LOWEST = 650,
  DOUBLEJUMP_HIGHEST = 400,

  NEAR_SUPERJUMP = 0.7,

  KILL_SUPERKICK = 0.7,

  HORIZONTAL_CLOSE = 175, -- pixels apart to go for kill
  CLOSE_VARIANCE = 25, -- +/- X pixels from actual close

  GAIN_METER = 0.9, -- every 6 frames, how often to kick for meter if conditions fulfilled

  GO_FOR_KILL = 0.7, -- how often to go for kill
  KILL_VARIANCE = 40, -- +/- X pixels from actual kill distance

  DO_SOMETHING = 0.6,

  GoForKill = false,
  DoDoublejump = false
  DoubleJumpHeight = 400, -- initialize
}

function AI.Konrad.onGround(player, foe)
  local near = AI._isClose(player, foe, AI.Konrad.HORIZONTAL_CLOSE, AI.Konrad.CLOSE_VARIANCE)

  local rand = math.random()
  if rand < AI.Konrad.DO_SOMETHING then
    if near then
      return AI.Konrad._nearGround(player, foe)
    else
      return AI.Konrad._farGround(player, foe)
    end
  else
    return false, false
  end
end

function AI.Konrad.inAir(player, foe)
  local jump = false
  local attack = false

  if AI.Konrad.GoForKill then
    return AI.Konrad._airKill(player, foe)
  elseif AI.Konrad.DoDoublejump then
    return AI.Konrad._doublejump(player, foe)
  else
    return AI.Konrad._gainMeter(player, foe)
  end
end

function AI.Konrad._nearGround(player, foe)
  local rand1 = math.random()
  if rand1 < AI.Konrad.GO_FOR_KILL then
    AI.Konrad.GoForKill = true

    local rand2 = math.random()
    if rand2 < AI.Konrad.NEAR_SUPERJUMP and player.super >= 16 then
      return true, true
    else
      return true, false
    end
  else
    return true, false
  end
end

function AI.Konrad._farGround(player, foe)
  AI.Konrad.GoForKill = false

  local rand = math.random()    
  if rand < AI.Konrad.FAR_JUMP then
    if math.random() < AI.Konrad.FAR_DOUBLEJUMP then -- queue a double jump
      AI.Konrad.DoDoublejump = true
      AI.Konrad.DoubleJumpHeight = math.random(AI.Konrad.DOUBLEJUMP_LOWEST, AI.Konrad.DOUBLEJUMP_HIGHEST)
    end

    return true, false
  else -- kickback
    return false, true
  end
end

function AI.Konrad._airKill(player, foe)
  local inrange = AI._inKillRange(player, foe, AI.KillAngle.Konrad, AI.Konrad.KILL_VARIANCE)
  local rand = math.random()

  if inrange then
    AI.Konrad.GoForKill = false
    AI.Konrad.DoDoublejump = false

    if player.super >= 16 and rand < AI.Konrad.KILL_SUPERKICK then
      return true, true
    else
      return false, true
    end
  else
    return false, false
  end  
end

function AI.Konrad._doublejump(player, foe)
  local abovejumpheight = player.pos[2] + player.sprite_size[2] < AI.Konrad.DoubleJumpHeight 

  if abovejumpheight then
    AI.Konrad.GoForKill = false
    AI.Konrad.DoDoublejump = false
    return true, false
  else
    return false, false
  end
end

function AI.Konrad._gainMeter(player, foe)
  local rand = math.random()
  local abovekickheight = player.pos[2] + player.sprite_size[2] < AI.Konrad.MIN_KICK_HEIGHT

  if abovekickheight and rand < AI.Konrad.GAIN_METER then
    AI.Konrad.GoForKill = false
    AI.Konrad.DoDoublejump = false
    return false, true
  else
    return false, false
  end
end


--Something to check if the opponent is attacking at "will hit me" angle, then kick if so


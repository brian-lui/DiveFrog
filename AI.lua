AI = {
	Konrad = {},
	Jean = {},
	Sun = {},
	Frogson = {}
}

-- angle of attack, expressed as h_vel / v_vel. Lower = steeper angle 
AI.KillAngle = { 
  Konrad = 0.75,
  Jean = 1,
  Sun = 5 / 11,
  FrogsonB = 6 / 11,
  FrogsonJ = 1.5
	}





------------------------------------KONRAD-------------------------------------

-- placeholder function
function AI.Action(player, foe)
	local sendjump = false
	local sendattack = false

	if frame % 7 == 0 then
		sendjump = true
	end

	if frame % 13 == 0 then
		sendattack = true
	end
	--print(AI.Konrad.inKillRange(player, foe))
  print(AI.Konrad.inClose(player, foe))

	return sendjump, sendattack
end


AI.Konrad = {
  -- max height reached = v^2 / 2a (gives pixels above stage floor)
  MAX_JUMP_HEIGHT = 544,
  MAX_SUPERJUMP_HEIGHT = 700,

  MIN_KICK_HEIGHT = 50,

  FAR_JUMP = 0.8, -- frequency

  FAR_DOUBLEJUMP = 0.2, -- frequency
  FAR_DOUBLEJUMP_LOWEST = 100,
  FAR_DOUBLEJUMP_HIGHEST = 500,
  
  NEAR_SUPERJUMP = 0.8, -- frequency
}

AI.Konrad = {
  FAR_KICKBACK = 1 - AI.Konrad.FAR_JUMP,
  NEAR_JUMP = 1 - AI.Konrad.NEAR_SUPERJUMP,
  HORIZONTAL_CLOSE = AI.Konrad.MAX_JUMP_HEIGHT * AI.KillAngle.Konrad

  GoForKill = false
  DoDoublejump = false
  DoublejumpHeight = math.random(FAR_DOUBLEJUMP_LOWEST, FAR_DOUBLEJUMP_HIGHEST)
}

function AI.Konrad.inKillRange(player, foe)
	-- Konrad's foot  
  local player_foot = {player.pos[1] + player.sprite_size[1], player.pos[2] + player.sprite_size[2]}
  if player.facing == -1 then
    player_foot[1] = player.pos[1]
  end

  -- foe's closest side, top of sprite
  local foe_target = foe.pos
  if foe.facing == -1 then
    foe_target[1] = foe.pos[1] + foe.sprite_size[1]
  end

  -- calculate current angle
	local h_dist = (player_foot[1] - foe_target[1]) * -player.facing
	local v_dist = player_foot[2] - foe_target[2]

  -- compare angle with kill angle, and check for height
	local angle = h_dist / v_dist
	local killangle = AI.KillAngle.Konrad
  local Konrad_above = player.pos[2] < foe.pos[2]

  return (angle < killangle) and Konrad_above
end

function AI.Konrad.inClose(player, foe)
  -- Konrad's foot  
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

  return h_distance < AI.Konrad.HORIZONTAL_CLOSE
end

function AI.Konrad.onGround(player, foe)
  local jump = false
  local attack = false

  local near = AI.Konrad.inClose(player, foe)
  local num = math.random()
  
  if near then
    AI.Konrad.GoForKill = true
    if num < AI.Konrad.NEAR_SUPERJUMP then
      jump = true
      attack = true
    else
      jump = true
    end
  else
    AI.Konrad.GoForKill = false
    if num < AI.Konrad.FAR_JUMP then
      jump = true
      if math.random() < AI.Konrad.FAR_DOUBLEJUMP then
        AI.Konrad.DoDoublejump = true
        AI.Konrad.DoublejumpHeight = math.random(FAR_DOUBLEJUMP_LOWEST, FAR_DOUBLEJUMP_HIGHEST)
      end
    else
      attack = true -- kickback
    end
  end

  return jump, attack
end


function AI.Konrad.inAir(player, foe)
  local jump = false
  local attack = false

  local num = math.random()
--[[

In air? Check horizontal distance
  If flag "go for kill":
    Calculate required headshot height (using top + closest corner of opponent and jump angle)
    Check if angle is at headshot height or higher:
      If yes - Superkick if available, otherwise kick
      If no - do nothing
  Else if not doublejump:
    If above minimum kick height:
      If yes - Kick
      If no - do nothing *
  Else if doublejump:
    If at headshot height or higher: superkick or kick
    Elseif at or above doublejump height - Kick
    Otherwise do nothing *
  

*Something to check if the opponent is attacking at "will hit me" angle, then kick if so

--]]
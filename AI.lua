AI = {
	Konrad = {},
	Jean = {},
	Sun = {},
	Frogson = {}
}

-- angle of attack, expressed as h_vel / v_vel. Lower = steeper angle 
AI.KillAngles = { 
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
	local bath = AI.Konrad.inKillRange(player, foe)

	return sendjump, sendattack
end


AI.Konrad = {
  -- max height reached = v^2 / 2a (gives pixels above stage floor)
  MAX_JUMP_HEIGHT = 544,
  MAX_SUPERJUMP_HEIGHT = 700,

  MIN_KICK_HEIGHT = 50,

  -- neutral state percentages
  NEUTRAL_JUMP = 0.8,
  NEUTRAL_KICKBACK = 0.2,

	-- doublejump frequency and height
  NEUTRAL_DOUBLEJUMP = 0.2,
  NEUTRAL_DOUBLEJUMP_LOWEST = 100,
  NEUTRAL_DOUBLEJUMP_HIGHEST = 500,

  -- action percentages when in kill range
  KILL_SUPERJUMP = 0.8,
  KILL_JUMP = 0.2
}

function AI.Konrad.inKillRange(player, foe)
	local inRange = false

	-- Konrad's foot  
  local player_foot = {player.pos[1] + player.sprite_size[1], player.pos[2] + player.sprite_size[2]}
  if player.facing == -1 then
    player_foot = {player.pos[1], player.pos[2] + player.sprite_size[2]}
  end

  -- foe's closest side, top of sprite
  local foe_target = foe.pos
  if foe.facing == -1 then
    foe_target = {foe.pos[1] + foe.sprite_size[1], foe.pos[2]}
  end
 
 	-- line of Konrad's foot at Konrad's Kill Angle

 	-- check if foe_target is at or above line
 		-- if so, inRange == true
  return inRange
end

--[[
Calculate optimal distance:
  Get opponent position (mid h, mid v)
  Calculate difference between (v and Konrad max jump height), multiplied by jump angle

On ground? Check horizontal distance
  Far:      NEUTRAL_JUMP% jump, NEUTRAL_KICKBACK% kickback
  Optimal or closer:  KILL_SUPERJUMP% Superjump if available, KILL_JUMP% jump. Set flag "go for kill"

  After a jump, NEUTRAL_DOUBLEJUMP% of the time, set "do doublejump" flag and "what height to do doublejump"

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
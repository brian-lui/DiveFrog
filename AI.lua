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
		myfrog = AI.Jean
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

function AI._inPlayersKillRange(player, foe, killangle, variance)
	local v_adjust = math.random(-variance, variance)

	local foe_foot = {foe.center, foe.pos[2] + foe.sprite_size[2]}
	local player_target = {player.center, player.pos[2] + v_adjust}

	local h_dist = math.abs(foe_foot[1] - player_target[1]) - 0.5 * player.sprite_size[1] - 0.5 * foe.sprite_size[1]
	local v_dist = math.abs(foe_foot[2] - player_target[2])

	local angle = h_dist / v_dist
	local foe_above = foe.pos[2] < player.pos[2]

	return (angle < killangle) and foe_above
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

function AI._checkFoeAngle(foe) -- pass foe.fighter_name
	local foekillangle = ""

	if foe.fighter_name == "Konrad" then
		foekillangle = AI.KillAngle.Konrad
	elseif foe.fighter_name == "Mustachioed Jean" then
		foekillangle = AI.KillAngle.Jean
	elseif foe.fighter_name == "Sun Badfrog" then
		foekillangle = AI.KillAngle.Sun
	elseif foe.fighter_name == "M. Frogson" and not foe.jackson_stance then
		foekillangle = AI.KillAngle.FrogsonB
	elseif foe.fighter_name == "M. Frogson" and foe.jackson_stance then
		foekillangle = AI.KillAngle.FrogsonJ
	else
		print("Enemy AI module not found") 
	end

	return foekillangle
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
	DoDoublejump = false,
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

-------------------------------MUSTACHIOED JEAN--------------------------------
AI.Jean = {
	-- max height reached = v^2 / 2a (gives pixels above stage floor)
	MAX_JUMP_HEIGHT = 466,
	MIN_KICK_HEIGHT = stage.floor - 50,

	FAR_JUMP = 0.85, -- otherwise dandy

	HORIZONTAL_CLOSE = 150, -- pixels apart to go for kill
	CLOSE_VARIANCE = 25, -- +/- X pixels from actual close

	GAIN_METER = 0.9, -- every 6 frames, how often to kick for meter if conditions fulfilled

	GO_FOR_KILL = 0.7, -- how often to go for kill
	KILL_VARIANCE = 40, -- +/- X pixels from actual kill distance

	DO_SOMETHING = 0.7,

	DANDY_WHEN_CLOSE = 0.6, -- if not going for kill

	MAX_DANDY_VEL = 18, -- don't pilebunker if horizontal velocity is higher than this
	MAX_PILEBUNK_VEL = 18, -- don't YRC if horizontal velocity is higher than this

	RANDOMLY_PILEBUNK = 0.07, -- chance to pilebunk regardless during dandy

	AVOID_KILLRANGE = 0.65, -- chance to dandy (or YRC if dandying/pilebunking) if within enemy's kill range

	GoForKill = false
}

function AI.Jean.onGround(player, foe)
	local near = AI._isClose(player, foe, AI.Jean.HORIZONTAL_CLOSE, AI.Jean.CLOSE_VARIANCE)

	local rand = math.random()

	if rand < AI.Jean.DO_SOMETHING then
		if player.dandy then
			return AI.Jean._dandying(player, foe)
		elseif player.pilebunking then
			return AI.Jean._pilebunking(player, foe)
		elseif near then
			return AI.Jean._nearGround(player, foe)
		else
			return AI.Jean._farGround(player, foe)
		end
	else
		return false, false
	end
end

function AI.Jean.inAir(player, foe)
	local jump = false
	local attack = false

	if AI.Jean.GoForKill then
		return AI.Jean._airKill(player, foe)
	else
		return AI.Jean._gainMeter(player, foe)
	end
end

function AI.Jean._nearGround(player, foe)
	local rand1 = math.random()
	local rand2 = math.random()
	local enemyangle = AI._checkFoeAngle(foe)
	local inenemyrange = AI._inPlayersKillRange(player, foe, enemyangle, AI.Jean.KILL_VARIANCE)

	if inenemyrange then
		return AI.Jean._underPressure(player, foe)
	elseif rand1 < AI.Jean.GO_FOR_KILL then
		AI.Jean.GoForKill = true
		return true, false
	elseif rand2 < AI.Jean.DANDY_WHEN_CLOSE then
		return false, true
	else
		return true, false
	end
end

function AI.Jean._farGround(player, foe)
	AI.Jean.GoForKill = false
	local rand = math.random()
	local enemyangle = AI._checkFoeAngle(foe)
	local inenemyrange = AI._inPlayersKillRange(player, foe, enemyangle, AI.Jean.KILL_VARIANCE)

	if inenemyrange then
		return AI.Jean._underPressure(player, foe)
	elseif rand < AI.Jean.FAR_JUMP then
		return true, false
	else -- dandy
		return false, true
	end
end

function AI.Jean._airKill(player, foe)
	local inrange = AI._inKillRange(player, foe, AI.KillAngle.Jean, AI.Jean.KILL_VARIANCE)
	local rand = math.random()

	if inrange then
		AI.Jean.GoForKill = false
		return false, true
	else
		return false, false
	end
end

function AI.Jean._gainMeter(player, foe)
	local rand = math.random()
	local abovekickheight = player.pos[2] + player.sprite_size[2] < AI.Jean.MIN_KICK_HEIGHT

	if abovekickheight and rand < AI.Jean.GAIN_METER then
		AI.Jean.GoForKill = false
		return false, true
	else
		return false, false
	end
end

function AI.Jean._underPressure(player, foe)
	local rand = math.random()
	local enemyangle = AI._checkFoeAngle(foe)
	local inenemyrange = AI._inPlayersKillRange(player, foe, enemyangle, AI.Jean.KILL_VARIANCE)

	if inenemyrange and rand < AI.Jean.AVOID_KILLRANGE then
		return false, true
	else
		return false, false
	end
end

function AI.Jean._dandying(player, foe)
	local rand = math.random()
	local rand2 = math.random()
	local enemyangle = AI._checkFoeAngle(foe)
	local inenemyrange = AI._inPlayersKillRange(player, foe, enemyangle, AI.Jean.KILL_VARIANCE)

	if inenemyrange then
		if rand < AI.Jean.AVOID_KILLRANGE then
			return true, true
		end
	else
		if foe.pos[2] + foe.sprite_size[2] > stage.floor - 150 then
			return false, true
		elseif rand2 < AI.Jean.RANDOMLY_PILEBUNK then
			return false, true
		else
			return false, false
		end
	end
end

function AI.Jean._pilebunking(player, foe)
	local rand = math.random()
	local enemyangle = AI._checkFoeAngle(foe)
	local inenemyrange = AI._inPlayersKillRange(player, foe, enemyangle, AI.Jean.KILL_VARIANCE)

	if inenemyrange and math.abs(player.vel[1]) < AI.Jean.MAX_DANDY_VEL and rand < AI.Jean.AVOID_KILLRANGE then
		return true, true -- will do nothing if insufficient super meter
	else
		return false, false
	end
end

particles = require 'particles'

-- load images
replaysscreen = love.graphics.newImage('images/Replays.jpg')
charselectscreen = love.graphics.newImage('images/CharSelect.jpg')
bkmatchend = love.graphics.newImage('images/MatchEndBackground.png')
hpbar = love.graphics.newImage('images/HPBar.png')
portraits = love.graphics.newImage('images/Portraits.png')
greenlight = love.graphics.newImage('images/GreenLight.png')
portraitsQuad = love.graphics.newQuad(0, 0, 200, 140,portraits:getDimensions())

FONT = {
	ROUND_START = love.graphics.newFont('/fonts/Comic.otf', 60),
	ROUND_START_COUNTDOWN = love.graphics.newFont('/fonts/Comic.otf', 20),
	ROUND_START_FLAVOR = love.graphics.newFont('/fonts/Comic.otf', 20),
	ROUND_END = love.graphics.newFont('/fonts/ComicItalic.otf', 42),
	CHAR_INFO = love.graphics.newFont('/fonts/CharSelect.ttf', 21),
	CHAR_SELECTOR = love.graphics.newFont('/fonts/GoodDog.otf', 18),
	TIMER = love.graphics.newFont('/fonts/Comic.otf', 40),
	GAME_OVER = love.graphics.newFont('/fonts/ComicItalic.otf', 24),
	GAME_OVER_HELP = love.graphics.newFont('/fonts/ComicItalic.otf', 16)
}

ROUND_START_FLAVOR = {
	{TOP = "Kill each other,", BOTTOM = "But it's good [INVERSES]"},
	{TOP = "Heaven or hell!", BOTTOM = "Let's ROCK!"},
	{TOP = "This battle is about to explode", BOTTOM = "Fight!"},
	{TOP = "The wheel of fate is turning", BOTTOM = "ACTION!"},
	{TOP = "THE TIME OF RETRIBUTION", BOTTOM = "DECIDE THE DESTINY"},
	{TOP = "Death from above!", BOTTOM = "Divekick!"},
	{TOP = "Welcome back to the stage of history", BOTTOM = "But the soul still burns."},
	{TOP = "It all depends on your skill!", BOTTOM = "Ain't there somebody who can stop this fighting machine?"},
	{TOP = "You can't give it up!", BOTTOM = "Triumph or die!"},
	{TOP = "Welcome to the world of Divefrog...", BOTTOM = "Prepare for battle!"},
	{TOP = "Fighters ready...", BOTTOM = "Engage!"},
	{TOP = "Fists will fly at this location!", BOTTOM = "The stage of battle is set!"},
	{TOP = "Let's get started!", BOTTOM = "And the battle begins!"},
	{TOP = "Let the madness begin!", BOTTOM = "It's all or nothing!"}
}

flavor_rand = {top = 1, bottom = 1}

COLOR = {
	WHITE = {255, 255, 255, 1},
	OFF_WHITE = {255, 255, 255, 0.63},
	DULL_ORANGE = {195, 160, 0, 0.82},
	ORANGE = {255, 215, 0, 1},
	DARK_ORANGE = {230, 147, 0, 1},
	LIGHT_GREEN = {128, 255, 128, 1},
	GRAY = {96, 96, 96, 1},
	BLACK = {0, 0, 0, 1},
	SHADOW = {0, 0, 0, 0.38},
	RED = {220, 0, 0, 1},
	BLUE = {14, 28, 232, 1},
	GREEN = {14, 232, 54, 1},
	PALE_BLUE = {164, 164, 255, 1},
	PALE_GREEN = {164, 255, 164, 1}
}

speechbubbles = {
	SpeechBubblePow,
	SpeechBubbleBiff,
	SpeechBubbleWham,
	SpeechBubbleZap,
	SpeechBubbleJeb,
	SpeechBubbleBath,
	SpeechBubbleBop,
	SpeechBubbleSmack,
	SpeechBubbleThump,
	SpeechBubbleZwapp,
	SpeechBubbleClunk
}

function drawBackground()
	love.graphics.clear()

	local temp_color = COLOR.WHITE

	if game.background_color then
		temp_color = game.background_color
	elseif game.superfreeze_time > 0 then
		temp_color = COLOR.GRAY
	elseif p1.frozenFrames > 0 and p2.frozenFrames > 0 and frame > 90 then
		temp_color = COLOR.BLACK
	end

	love.graphics.push("all")
		love.graphics.setColor(temp_color)
		love.graphics.draw(p2.stage_background, 0, 0)
	love.graphics.pop()
end

function drawMidline() -- when low on time
	if round_timer <= 180 and round_timer > 0 and not round_ended then
		love.graphics.push("all")
			love.graphics.setColor(100 + (180 - round_timer) / 2, 0, 0, 0.78)
			love.graphics.setLineWidth(12)
			love.graphics.line(stage.center, 0, stage.center, stage.height)

			love.graphics.setLineWidth(1)
			local alpha = ((180 - round_timer) / 2 + 90) / 256
			local lines = {
				{shift = 2 * round_timer, color = {255, 0, 0, alpha}},
				{shift = 4 * round_timer, color = {220, 220, 0, alpha}},
				{shift = 6 * round_timer, color = {220, 220, 220, alpha}},
				{shift = 12 * round_timer, color = {255, 255, 255, alpha}}
				}

			for _, line in pairs(lines) do
				love.graphics.setColor(line.color)
				love.graphics.line(stage.center - line.shift, 0, stage.center - line.shift, stage.height)
				love.graphics.line(stage.center + line.shift, 0, stage.center + line.shift, stage.height)
			end
		love.graphics.pop()
	end
end

function drawPost2Buffer()
	if post2buffer[frame] then
		love.graphics.push("all")
			for index, _ in pairs(post2buffer[frame]) do
				post2buffer[frame][index][12] = post2buffer[frame][index][12] or COLOR.WHITE
				love.graphics.setColor(post2buffer[frame][index][12]) -- 12 is RGB table
				love.graphics.draw(unpack(post2buffer[frame][index]))
			end
		love.graphics.pop()
	end
	post2buffer[frame] = nil
end

function drawPost3Buffer()
	if post3buffer[frame] then
		love.graphics.push("all")
			for index, _ in pairs(post3buffer[frame]) do
				post3buffer[frame][index][12] = post3buffer[frame][index][12] or COLOR.WHITE
				love.graphics.setColor(post3buffer[frame][index][12]) -- 12 is RGB table
				love.graphics.draw(unpack(post3buffer[frame][index]))
			end
		love.graphics.pop()
	end
	post2buffer[frame] = nil
end

function drawPrebuffer()
	if prebuffer[frame] then
		love.graphics.push("all")
			for index, _ in pairs(prebuffer[frame]) do
				prebuffer[frame][index][12] = prebuffer[frame][index][12] or COLOR.WHITE
				love.graphics.setColor(prebuffer[frame][index][12]) -- 12 is RGB table
				love.graphics.draw(unpack(prebuffer[frame][index]))
			end
		love.graphics.pop()
	end
	prebuffer[frame] = nil
end

function drawSprites()
	for side, op in pairs(Players) do
		love.graphics.push("all")

			-- Ground shadow for sprites
			love.graphics.setColor(COLOR.SHADOW)
			love.graphics.ellipse("fill", side:getCenter(), stage.floor - 5, 50, 20)

			-- Sprites
			local temp_color = {255, 255, 255, 1}

			if side.color then
				for i = 1, 4 do temp_color[i] = side.color[i] end
			end

			if game.identical_players and side == p2 then
				temp_color[1] = temp_color[1] * 0.7
				temp_color[2] = temp_color[2] * 0.85
				temp_color[3] = temp_color[3] * 0.7
			end

			love.graphics.setColor(temp_color)

			love.graphics.draw(side.image, side.sprite,
				side.pos[1] + side.h_mid, side.pos[2] + side.v_mid, 0, side.facing, 1, side.h_mid, side.v_mid)

		love.graphics.pop()
	end
end

function drawPostbuffer()
	if postbuffer[frame] then
		love.graphics.push("all")
			for index, _ in pairs(postbuffer[frame]) do
				postbuffer[frame][index][12] = postbuffer[frame][index][12] or COLOR.WHITE
				love.graphics.setColor(postbuffer[frame][index][12]) -- 12 is RGB table
				love.graphics.draw(unpack(postbuffer[frame][index]))
			end
		love.graphics.pop()
	end
	postbuffer[frame] = nil
end

function drawMain()
	love.graphics.clear()

	drawMidline()
	drawPrebuffer()
	drawSprites()
	drawPostbuffer()
end

function _drawOverlayTimer()
	-- timer
	love.graphics.push("all")
		local displayed_time = math.ceil(round_timer * min_dt)
		love.graphics.setColor(COLOR.DARK_ORANGE)
		love.graphics.setFont(FONT.TIMER)
		love.graphics.printf(displayed_time, 0, 6, window.width, "center")
	love.graphics.pop()
end

function _drawOverlayHPbars(side, op)
	-- HP bars
	love.graphics.draw(hpbar, window.center + (op.move * 337), 18, 0, op.flip, 1)
	-- ornament
	local pos = (frame % 180) * 8
	if side.life > pos then
		h_loc = window.center + (op.move * 53) + (op.move * pos)
		love.graphics.push("all")
			love.graphics.setColor(COLOR.OFF_WHITE)
			love.graphics.setLineWidth(1)
			love.graphics.line(h_loc, 22, h_loc, 44)
		love.graphics.pop()
	end
	-- life depleted
	if side.life < 280 then
		love.graphics.push("all")
			love.graphics.setColor(COLOR.RED)
			love.graphics.setLineWidth(23)
			love.graphics.line(window.center + (op.move * 333), 34, window.center + (op.move * 333) - op.move * (280 - side.life), 34)
		love.graphics.pop()
	end
end

function _drawOverlayWinPoints(side, op)
	for i = 1, game.best_to_x do
		if side.score >= i then
			love.graphics.draw(greenlight, window.center + (op.move * 354) - op.move * (20 * i),
			52, 0, 1, 1, op.offset * greenlight:getWidth())
		end
	end
end

function _drawOverlayPlayerIcons(side, op)
	love.graphics.draw(side.icon, window.center + (op.move * 390), 10, 0, op.flip, 1, 0)
end

function _drawOverlaySuperBars(side, op)
	love.graphics.push("all")
		if not side.isSupering then
			-- super bar base
			love.graphics.setColor(COLOR.OFF_WHITE)
			love.graphics.draw(SuperBarBase.image, window.center + (op.move * 375), window.height - 35,
				0, 1, 1, op.offset * SuperBarBase.width)

			-- super meter
			local index = math.floor((frame % 64) / 8)
			local Quad = love.graphics.newQuad(0, index * SuperMeter.height,
				SuperMeter.width * (side.super / 96), SuperMeter.height,
				SuperMeter.image_size[1], SuperMeter.image_size[2])
			local supermeterColor = {0, 32 + side.super * 2, 0, 1}
			if side.super >= 32 and side.super < 64 then
				supermeterColor = {80 + side.super, 80 + side.super, 160 + side.super, 255}
			elseif side.super >= 64 then
				supermeterColor = {159 + side.super, 159 + side.super, 0, 255}
			end
			love.graphics.setColor(supermeterColor)
			love.graphics.draw(SuperMeter.image, Quad, window.center + (op.move * 373),
				window.height - 33, 0, op.flip, 1, 0)

		else -- if super full, draw frog factor
			local index = math.floor((frame % FrogFactor.total_time) / FrogFactor.time_per_frame)
			local Quad = love.graphics.newQuad(index * FrogFactor.width, 0,
				FrogFactor.width * (side.super / 96), FrogFactor.height,
				FrogFactor.image_size[1], FrogFactor.image_size[2])
			love.graphics.setColor(COLOR.WHITE)
			love.graphics.draw(FrogFactor.image, Quad, window.center + (op.move * 390),
				window.height - FrogFactor.height - 10, 0, op.flip, 1, 0)
		end
	love.graphics.pop()
end

function drawOverlays()
	love.graphics.clear()

	_drawOverlayTimer()

	for side, op in pairs(Players) do
		_drawOverlayHPbars(side, op)
		_drawOverlayWinPoints(side, op)
		_drawOverlayPlayerIcons(side, op)
		_drawOverlaySuperBars(side, op)
	end

end

function drawOverlays2()
	love.graphics.clear()

	drawPost2Buffer()
	drawPost3Buffer()
end


function drawRoundStart() -- start of round overlays
	local frames_elapsed = frame - frame0

	if frames_elapsed == 10 then -- select which quote text to show
		flavor_rand.top = math.random(#ROUND_START_FLAVOR)
		flavor_rand.bottom = math.random(#ROUND_START_FLAVOR)
		if flavor_rand.top == flavor_rand.bottom then -- don't match quotes
			flavor_rand.bottom = math.random(#ROUND_START_FLAVOR - 1)
			if flavor_rand.bottom >= flavor_rand.top then
				flavor_rand.bottom = flavor_rand.bottom + 1
			end
		end
	end

	if frames_elapsed < 60 then
		love.graphics.push("all") 
			love.graphics.setColor(0, 0, 0, (1 - frames_elapsed / 60))
			love.graphics.rectangle("fill", 0, 0, stage.width, stage.height)
		love.graphics.pop()
	end

	if frames_elapsed > 15 and frames_elapsed <= 90 then
		love.graphics.push("all")
			love.graphics.setColor(COLOR.ORANGE)

			-- round
			love.graphics.setFont(FONT.ROUND_START)
			if frames_elapsed > 80 then
				local transparency = 1 - (frames_elapsed - 81) * 0.1
				love.graphics.setColor(255, 215, 0, transparency)
			end
			if p1.score == game.best_to_x - 1 and p2.score == game.best_to_x - 1 then
				love.graphics.printf("FINAL", 0, 220, window.width, "center")
			else
				love.graphics.printf("Round " .. game.current_round, 0, 220, window.width, "center")
			end

			-- flavor text
			love.graphics.setFont(FONT.ROUND_START_FLAVOR)
			love.graphics.setColor(COLOR.WHITE)
			if frames_elapsed > 80 then
				local transparency = 1 - (frames_elapsed - 81) * 0.1
				love.graphics.setColor(255, 255, 255, transparency)
			end

			local h_offset = math.tan((frames_elapsed - 53) / 24) -- tangent from -1.5 to 1.5
			local h_text1 = h_offset * 12
			local h_text2 = -h_offset * 12


			local top_text = ROUND_START_FLAVOR[flavor_rand.top].TOP
			local bottom_text = ROUND_START_FLAVOR[flavor_rand.bottom].BOTTOM
			love.graphics.printf(top_text, h_text1, 205, window.width, "center")
			love.graphics.printf(bottom_text, h_text2, 290, window.width, "center")
			
		love.graphics.pop()
	end
end

function drawRoundEnd() -- end of round overlays
	if round_end_frame > 0 then
		-- end of round win message
		if frame - round_end_frame > 60 and frame - round_end_frame < 150 then
			love.graphics.push("all")
				love.graphics.setFont(FONT.ROUND_END)
				love.graphics.setColor(COLOR.ORANGE)
				if p1.hasWon then love.graphics.printf(p1.fighter_name .. " wins!", 0, 200, window.width, "center")
				elseif p2.hasWon then love.graphics.printf(p2.fighter_name .. " wins!", 0, 200, window.width, "center")
				else love.graphics.printf("Double K.O. !!", 0, 200, window.width, "center")
				end
			love.graphics.pop()
		end

		-- end of round fade out
		if frame - round_end_frame > 120 and frame - round_end_frame < 150 then
			local light = 1 / 30 * (frame - round_end_frame - 120) -- 0 at 120 frames, 1 at 150
			love.graphics.push("all")
				love.graphics.setColor(0, 0, 0, light)
				love.graphics.rectangle("fill", 0, 0, stage.width, stage.height)
			love.graphics.pop()
		end
	end
end

function drawCharSelect()
	love.graphics.draw(charselectscreen, 0, 0, 0) -- background
	love.graphics.draw(portraits, portraitsQuad, 473, 130) -- character portrait
	love.graphics.push("all")
		love.graphics.setColor(COLOR.BLACK)
		love.graphics.setFont(FONT.CHAR_INFO)
		love.graphics.print(char_text[p1_char][1], 516, 350) -- character movelist
		love.graphics.print(char_text[p1_char][2], 516, 384)
		love.graphics.print(char_text[p1_char][3], 513, 425)
		love.graphics.print(char_text[p1_char][4], 430, 469)

		--p1 rectangle
		love.graphics.setFont(FONT.CHAR_SELECTOR)
		love.graphics.setLineWidth(2)
		love.graphics.setColor(COLOR.BLUE)
		love.graphics.print("P1", 42, 20 + (p1_char * 70)) -- helptext
		if frame % 60 < 7 then 
			love.graphics.setColor(COLOR.PALE_BLUE) -- flashing rectangle
		end
		love.graphics.rectangle("line", 60, 30 + (p1_char * 70), 290, 40)
		
		--p2 rectangle
		love.graphics.setColor(COLOR.GREEN)
		love.graphics.print("P2", 355, 20 + (p2_char * 70))
		if (frame + 45) % 60 < 7 then
			love.graphics.setColor(COLOR.PALE_GREEN)
		end
		love.graphics.rectangle("line", 61, 31 + (p2_char * 70), 289, 39)
	love.graphics.pop()
end

function drawMatchEnd() -- end of the match (not end of the round)
	love.graphics.draw(bkmatchend, 0, 0) -- background

	love.graphics.push("all")
		love.graphics.setFont(FONT.GAME_OVER)
		love.graphics.draw(game.match_winner.win_portrait, 100, 50)
		love.graphics.setColor(COLOR.BLACK)
		love.graphics.printf(game.match_winner.win_quote, 0, 470, window.width, "center")
		love.graphics.setFont(FONT.GAME_OVER_HELP)
		love.graphics.setColor(0, 0, 0, (frame / 128) % 1)
		love.graphics.print("Press enter", 650, 540)
	love.graphics.pop()

	-- fade in for match end
	local fadein = 1 - (frame - frame0)/ 60
	if frame - frame0 < 60 then
		love.graphics.push("all") 
			love.graphics.setColor(0, 0, 0, fadein)
			love.graphics.rectangle("fill", 0, 0, stage.width, stage.height)
		love.graphics.pop()
	end
end

function drawSuperOverlays(facing, frogface)
	for i = 0, 44 do
		local h_shift = -200 + math.sin(i / 38) * 400
		SuperProfile:repeatLoad(window.center, 200, h_shift, 0, facing, i, "post2")
		local frog_shift = -400 + math.sin(i / 38) * 400
		frogface:repeatLoad(window.center, 200, frog_shift, 0, facing, i, "post3")
	end
end
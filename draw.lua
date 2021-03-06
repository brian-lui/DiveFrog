local love = _G.love

local camera = require 'camera'
local colors = require 'colors'
local fonts = require 'fonts'
local images = require 'images'
local settings = require 'settings'
local stage = require 'stage'
local particles = require 'particles'
local title = require 'title'
local window = require 'window'

local ROUND_START_FLAVOR = {
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

local function main_background()
	love.graphics.clear()

	local temp_color = colors.WHITE

	if game.background_color then
		temp_color = game.background_color
	elseif game.superfreeze_time > 0 then
		temp_color = colors.GRAY
	elseif p1.frozenFrames > 0 and p2.frozenFrames > 0 and frame > 90 then
		temp_color = colors.BLACK
	end

	love.graphics.push("all")
		love.graphics.setColor(temp_color)
		love.graphics.draw(p2.stage_background, 0, 0)
	love.graphics.pop()
end

local function main_items()
	love.graphics.clear()

	-- draw midline
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

	-- draw prebuffer

	local prebuffer_frame = particles.get_frame("pre", frame)
	if prebuffer_frame then
		love.graphics.push("all")
			for index, _ in pairs(prebuffer_frame) do
				love.graphics.setColor(prebuffer_frame[index][12] or colors.WHITE) -- 12 is RGB table
				love.graphics.draw(unpack(prebuffer_frame[index]))
			end
		love.graphics.pop()
	end
	particles.clear_frame("pre", frame)

	-- draw sprites
	for side, op in pairs(Players) do
		love.graphics.push("all")

			-- Ground shadow for sprites
			love.graphics.setColor(colors.SHADOW)
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

	-- draw postbuffer
	local postbuffer_frame = particles.get_frame("post", frame)
	if postbuffer_frame then
		love.graphics.push("all")
			for index, _ in pairs(postbuffer_frame) do
				love.graphics.setColor(postbuffer_frame[index][12] or colors.WHITE) -- 12 is RGB table
				love.graphics.draw(unpack(postbuffer_frame[index]))
			end
		love.graphics.pop()
	end
	particles.clear_frame("post", frame)
end

-- draw the main screen overlay items
local function main_overlays()
	love.graphics.clear()

	-- timer
	love.graphics.push("all")
		local displayed_time = math.ceil(round_timer * min_dt)
		love.graphics.setColor(colors.DARK_ORANGE)
		love.graphics.setFont(fonts.timer)
		love.graphics.printf(displayed_time, 0, 6, window.width, "center")
	love.graphics.pop()

	for side, op in pairs(Players) do
		-- HP bar
		love.graphics.draw(images.hpbar, window.center + (op.move * 337), 18, 0, op.flip, 1)

		-- HP bar ornamental vertical line
		local pos = (frame % 180) * 8
		if side.life > pos then
			h_loc = window.center + (op.move * 53) + (op.move * pos)
			love.graphics.push("all")
				love.graphics.setColor(colors.OFF_WHITE)
				love.graphics.setLineWidth(1)
				love.graphics.line(h_loc, 22, h_loc, 44)
			love.graphics.pop()
		end

		-- HP bar life depleted
		if side.life < 280 then
			love.graphics.push("all")
				love.graphics.setColor(colors.RED)
				love.graphics.setLineWidth(23)
				love.graphics.line(window.center + (op.move * 333), 34, window.center + (op.move * 333) - op.move * (280 - side.life), 34)
			love.graphics.pop()
		end

		-- Win points
		for i = 1, game.best_to_x do
			if side.score >= i then
				love.graphics.draw(images.greenlight, window.center + (op.move * 354) - op.move * (20 * i),
				52, 0, 1, 1, op.offset * images.greenlight:getWidth())
			end
		end

		-- Player icon
		love.graphics.draw(side.icon, window.center + (op.move * 390), 10, 0, op.flip, 1, 0)

		-- Super bars
		love.graphics.push("all")
			if not side.isSupering then
				-- super bar base
				love.graphics.setColor(colors.OFF_WHITE)
				love.graphics.draw(
					particles.overlays.super_bar_base.image,
					window.center + (op.move * 375),
					window.height - 35,
					0,
					1,
					1,
					op.offset * particles.overlays.super_bar_base.width
				)

				-- super meter
				local index = math.floor((frame % 64) / 8)
				local Quad = love.graphics.newQuad(
					0,
					index * particles.overlays.super_meter.height,
					particles.overlays.super_meter.width * (side.super / 96),
					particles.overlays.super_meter.height,
					particles.overlays.super_meter.image_size[1],
					particles.overlays.super_meter.image_size[2]
				)
				local supermeterColor = {0, 32 + side.super * 2, 0, 1}
				if side.super >= 32 and side.super < 64 then
					supermeterColor = {80 + side.super, 80 + side.super, 160 + side.super, 255}
				elseif side.super >= 64 then
					supermeterColor = {159 + side.super, 159 + side.super, 0, 255}
				end
				love.graphics.setColor(supermeterColor)
				love.graphics.draw(
					particles.overlays.super_meter.image,
					Quad,
					window.center + (op.move * 373),
					window.height - 33,
					0,
					op.flip,
					1,
					0
				)

			else -- if super full, draw frog factor
				local index = math.floor(
					(frame % particles.overlays.frog_factor.total_time) /
					particles.overlays.frog_factor.time_per_frame
				)
				local Quad = love.graphics.newQuad(
					index * particles.overlays.frog_factor.width,
					0,
					particles.overlays.frog_factor.width * (side.super / 96),
					particles.overlays.frog_factor.height,
					particles.overlays.frog_factor.image_size[1],
					particles.overlays.frog_factor.image_size[2]
				)
				love.graphics.setColor(colors.WHITE)
				love.graphics.draw(
					particles.overlays.frog_factor.image,
					Quad,
					window.center + (op.move * 390),
					window.height - particles.overlays.frog_factor.height - 10,
					0,
					op.flip,
					1,
					0
				)
			end
		love.graphics.pop()
	end
end

local flavor_rand = {top = 1, bottom = 1}
local function main_roundstart_items()
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
			love.graphics.setColor(colors.ORANGE)

			-- round
			love.graphics.setFont(fonts.round_start)
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
			love.graphics.setFont(fonts.round_start_flavor)
			love.graphics.setColor(colors.WHITE)
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

local function main_roundend_items()
	if round_end_frame > 0 then

		-- end of round win message
		if frame - round_end_frame > 60 and frame - round_end_frame < 150 then
			love.graphics.push("all")
				love.graphics.setFont(fonts.round_end)
				love.graphics.setColor(colors.ORANGE)
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

local function main_overlays2()
	love.graphics.clear()

	local post2buffer_frame = particles.get_frame("post2", frame)
	if post2buffer_frame then
		love.graphics.push("all")
			for index, _ in pairs(post2buffer_frame) do
				love.graphics.setColor(post2buffer_frame[index][12] or colors.WHITE) -- 12 is RGB table
				love.graphics.draw(unpack(post2buffer_frame[index]))
			end
		love.graphics.pop()
	end
	particles.clear_frame("post2", frame)

	local post3buffer_frame = particles.get_frame("post3", frame)
	if post3buffer_frame then
		love.graphics.push("all")
			for index, _ in pairs(post3buffer_frame) do
				love.graphics.setColor(post3buffer_frame[index][12] or colors.WHITE) -- 12 is RGB table
				love.graphics.draw(unpack(post3buffer_frame[index]))
			end
		love.graphics.pop()
	end
	particles.clear_frame("post3", frame)
end

local debug_funcs = {
	draw_midpoints = function()
		love.graphics.push("all")
			love.graphics.setLineWidth(10)
			love.graphics.line(stage.center - 5, stage.height / 2, stage.center + 5, stage.height / 2)
			love.graphics.setLineWidth(20)
			love.graphics.line(window.center - 10, window.height / 2, window.center + 10, window.height / 2)
		love.graphics.pop()
	end,
	draw_hurtboxes = function(p1, p2)
		love.graphics.push("all")
			local todraw = {
				p1.hurtboxes,
				p1.hitboxes,
				p2.hurtboxes,
				p2.hitboxes,
			}
			local color = {
				{255, 255, 255, 192},
				{255, 0, 0, 255},
				{255, 255, 255, 192},
				{255, 0, 0, 255},
			}

			for num, drawboxes in pairs(todraw) do
				local dog = drawboxes

				for i = 1, #dog do
					if dog[i].Flag1 == "Mugshot" then
						love.graphics.setColor({0, 0, 255, 160/255})
					else
						love.graphics.setColor(color[num])
					end

					love.graphics.rectangle(
						"fill",
						dog[i].L,
						dog[i].U,
						dog[i].R - dog[i].L,
						dog[i].D - dog[i].U
					)
				end
			end
		love.graphics.pop()
	end,
	draw_sprites = function()
		for side, op in pairs(Players) do
			love.graphics.line(side.center, 0, side.center, stage.height)
			love.graphics.line(side.center, 200, side.center + op.flip * 30, 200)
			love.graphics.rectangle(
				"line",
				side.pos[1],
				side.pos[2],
				side.sprite_size[1],
				side.sprite_size[2]
			)
		end

		-- delete prebuffer[frame] = nil if using this. Draws unflipped, unshifted position.
		local prebuffer_frame = particles.get_frame("pre", frame)
		if prebuffer_frame then
			for index, _ in pairs(prebuffer_frame) do
				local a, b, l, u = unpack(prebuffer_frame[index])
				love.graphics.line(l + 50, u, l - 50, u)
				love.graphics.line(l, u + 50, l, u - 50)
			end
		end

		-- delete particles.postbuffer[frame] = nil if using this. Draws unflipped, unshifted position.
		local postbuffer_frame = particles.get_frame("post", frame)
		if postbuffer_frame then
			for index, _ in pairs(postbuffer_frame) do
				local a, b, l, u = unpack(postbuffer_frame[index])
				love.graphics.line(l + 50, u, l - 50, u)
				love.graphics.line(l, u + 50, l, u - 50)
			end
		end
	end,
}

local canvas_overlays = love.graphics.newCanvas(stage.width, stage.height)
local canvas_sprites = love.graphics.newCanvas(stage.width, stage.height)
local canvas_background = love.graphics.newCanvas(stage.width, stage.height)
local canvas_super = love.graphics.newCanvas(stage.width, stage.height)

local draw = {}

draw.portraitsQuad = love.graphics.newQuad(0, 0, 200, 140, images.portraits:getDimensions())

function draw.draw_main()
	canvas_background:renderTo(main_background)
	canvas_sprites:renderTo(main_items)
	canvas_overlays:renderTo(main_overlays)
	canvas_overlays:renderTo(main_roundstart_items)
	canvas_overlays:renderTo(main_roundend_items)
	canvas_super:renderTo(main_overlays2)

	camera:set(0.5, 1)
	love.graphics.draw(canvas_background)
	camera:unset()
	camera:set(1, 1)
	love.graphics.draw(canvas_sprites)

	if debug.boxes then debug_funcs.draw_hurtboxes(p1, p2) end
	if debug.sprites then debug_funcs.draw_sprites() end
	camera:unset()
	camera:set(0, 0)
	love.graphics.draw(canvas_overlays)
	love.graphics.draw(canvas_super)
	if debug.midpoints then debug_funcs.draw_midpoints() end
	camera:unset()
	if debug.camera then print(unpack(camera.camera_xy)) end
	if debug.keybuffer then print(unpack(keybuffer[frame])) end
end


local char_text = {
	{"Hyper Jump", "Hyper Kick", "+40%", "Double Jump"},
	{"Wire Sea", "Frog On Land", "+20%, Wire Ocean", "Dandy Frog (Wire Sea OK)\n— Pile Bonquer (Wire Sea OK)"},
	{"Hotflame (Wire Sea OK)", "Riot Kick", "Frog Install", "Small Head"},
	{"Anti-Gravity Frog", "Wow!", "+40%", "Jackson/Bison Stances"},
}

function draw.draw_charselect()
	love.graphics.draw(images.charselectscreen, 0, 0, 0) -- background
	love.graphics.draw(images.portraits, draw.portraitsQuad, 473, 130) -- character portrait
	love.graphics.push("all")
		love.graphics.setColor(colors.BLACK)
		love.graphics.setFont(fonts.char_info)
		love.graphics.print(char_text[p1_char][1], 516, 350) -- character movelist
		love.graphics.print(char_text[p1_char][2], 516, 384)
		love.graphics.print(char_text[p1_char][3], 513, 425)
		love.graphics.print(char_text[p1_char][4], 430, 469)

		--p1 rectangle
		love.graphics.setFont(fonts.char_selector)
		love.graphics.setLineWidth(2)
		love.graphics.setColor(colors.BLUE)
		love.graphics.print("P1", 42, 20 + (p1_char * 70)) -- helptext
		if frame % 60 < 7 then 
			love.graphics.setColor(colors.PALE_BLUE) -- flashing rectangle
		end
		love.graphics.rectangle("line", 60, 30 + (p1_char * 70), 290, 40)

		--p2 rectangle
		love.graphics.setColor(colors.GREEN)
		love.graphics.print("P2", 355, 20 + (p2_char * 70))
		if (frame + 45) % 60 < 7 then
			love.graphics.setColor(colors.PALE_GREEN)
		end
		love.graphics.rectangle("line", 61, 31 + (p2_char * 70), 289, 39)
	love.graphics.pop()
end

function draw.draw_matchend() -- end of the match (not end of the round)
	love.graphics.draw(images.bkmatchend, 0, 0) -- background

	love.graphics.push("all")
		love.graphics.setFont(fonts.game_over)
		love.graphics.draw(game.match_winner.win_portrait, 100, 50)
		love.graphics.setColor(colors.BLACK)
		love.graphics.printf(game.match_winner.win_quote, 0, 470, window.width, "center")
		love.graphics.setFont(fonts.game_over_help)
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

function draw.draw_title()
	love.graphics.push("all")
		love.graphics.draw(images.title.screen, 0, 0)
		love.graphics.draw(images.title.logo, 165, 30)

		love.graphics.setColor(colors.OFF_WHITE)
		love.graphics.draw(images.title.select_background, 100, 385)
		love.graphics.draw(images.title.controls_background, 400, 380)

		love.graphics.setLineWidth(3)
		love.graphics.setColor(colors.ORANGE)
		if frame % 60 > 50 then
			love.graphics.setColor(colors.WHITE)
		end
		love.graphics.rectangle("line", 120, 375 + 35 * title.choices.option, 110, 35)

		love.graphics.setColor(colors.ORANGE)
		love.graphics.setFont(fonts.title)

		local toprint = {
			{"P1 Jump:", settings.buttons.p1jump},
			{"P1 Attack:", settings.buttons.p1attack},
			{"P2 Jump:", settings.buttons.p2jump},
			{"P2 Attack:", settings.buttons.p2attack},
		}
		for i = 1, #toprint do
			love.graphics.push("all")
				love.graphics.print(toprint[i][1], 410, 370 + (30 * i))
				love.graphics.setColor(colors.LIGHT_GREEN)
				love.graphics.print(toprint[i][2], 540, 370 + (30 * i))
			love.graphics.pop()
		end

		for i = 1, #title.choices.menu do
			love.graphics.print(title.choices.menu[i], 130, 375  + (35 * i))
		end
	love.graphics.pop()
end

local settings_backgrounds = {
	rounds = love.graphics.newQuad(
		0,
		0,
		60,
		60,
		love.graphics.getWidth(images.settings.texture),
		love.graphics.getHeight(images.settings.texture)
	),
	timer = love.graphics.newQuad(
		0,
		0,
		70,
		60,
		love.graphics.getWidth(images.settings.texture),
		love.graphics.getHeight(images.settings.texture)
	),
	speed = love.graphics.newQuad(
		0,
		0,
		130,
		60,
		love.graphics.getWidth(images.settings.texture),
		love.graphics.getHeight(images.settings.texture)
	),
	music = love.graphics.newQuad(
		0,
		0,
		90,
		60,
		love.graphics.getWidth(images.settings.texture),
		love.graphics.getHeight(images.settings.texture)
	),
	sound = love.graphics.newQuad(
		0,
		0,
		90,
		60,
		love.graphics.getWidth(images.settings.texture),
		love.graphics.getHeight(images.settings.texture)
	),
	controls = love.graphics.newQuad(
		0,
		0,
		210,
		225,
		love.graphics.getWidth(images.settings.texture),
		love.graphics.getHeight(images.settings.texture)
	),
}

function draw.draw_settings()
	love.graphics.push("all")
		love.graphics.draw(images.settings.background, 0, 0, 0)
		love.graphics.draw(images.settings.logo, 232, 60)

		love.graphics.setColor(colors.OFF_WHITE)
		love.graphics.draw(images.settings.texture, 280, 260)

		love.graphics.setLineWidth(3)
		if settings.popup_window == "" then
			love.graphics.setColor(colors.ORANGE)
			if frame % 60 > 50 then
				love.graphics.setColor(colors.WHITE)
			end
		else
			love.graphics.setColor(colors.DULL_ORANGE)
		end

		love.graphics.rectangle("line", 290, 238 + 35 * settings.choices.option, 200, 34)

		if settings.popup_window == "" then
			love.graphics.setColor(colors.ORANGE)
		else
			love.graphics.setColor(colors.DULL_ORANGE)
		end

		love.graphics.setFont(fonts.settings)
		for i = 1, #settings.choices.menu do
			love.graphics.print(settings.choices.menu[i], 300, 240 + (35 * i))
		end

		-- draw popups
		if settings.popup_window == "Rounds" then
			love.graphics.setColor(colors.OFF_WHITE)
			love.graphics.draw(
				images.settings.texture,
				settings_backgrounds.rounds,
				510,
				260
			)
			love.graphics.setColor(colors.ORANGE)
			love.graphics.setFont(fonts.settings_options_big)
			love.graphics.printf(
				settings.data.Rounds[settings.options.Rounds][1],
				508,
				252,
				60,
				"center"
			)
		elseif settings.popup_window == "Timer" then
			love.graphics.setColor(colors.OFF_WHITE)
			love.graphics.draw(
				images.settings.texture,
				settings_backgrounds.timer,
				510,
				295
			)
			love.graphics.setColor(colors.ORANGE)
			love .graphics.setFont(fonts.settings_options_big)
			love.graphics.printf(
				settings.data.Timer[settings.options.Timer][1],
				510,
				290,
				70,
				"center"
			)
		elseif settings.popup_window == "Speed" then
			love.graphics.setColor(colors.OFF_WHITE)
			love.graphics.draw(
				images.settings.texture,
				settings_backgrounds.speed,
				510,
				330
			)
			love.graphics.setColor(colors.ORANGE)
			love.graphics.setFont(fonts.settings_options_small)
			love.graphics.printf(
				settings.data.Speed[settings.options.Speed][1],
				510,
				333,
				130,
				"center"
			)
		elseif settings.popup_window == "Music" then
			love.graphics.setColor(colors.OFF_WHITE)
			love.graphics.draw(
				images.settings.texture,
				settings_backgrounds.music,
				510,
				365
			)
			love.graphics.setColor(colors.ORANGE)
			love.graphics.setFont(fonts.settings_options_small)
			love.graphics.printf(
				settings.data.Music[settings.options.Music][1],
				510,
				368,
				90,
				"center"
			)
		elseif settings.popup_window == "Sound" then
			love.graphics.setColor(colors.OFF_WHITE)
			love.graphics.draw(
				images.settings.texture,
				settings_backgrounds.sound,
				510,
				400
			)
			love.graphics.setColor(colors.ORANGE)
			love.graphics.setFont(fonts.settings_options_small)
			love.graphics.printf(
				settings.data.Sound[settings.options.Sound][1],
				510,
				403,
				90,
				"center"
			)
		elseif settings.popup_window == "Controls" then
			love.graphics.setColor(colors.OFF_WHITE)
			love.graphics.draw(
				images.settings.texture,
				settings_backgrounds.controls,
				510,
				245
			)

			local toprint = {
				{"P1 Jump", settings.buttons.p1jump},
				{"P1 Attack", settings.buttons.p1attack},
				{"P2 Jump", settings.buttons.p2jump},
				{"P2 Attack", settings.buttons.p2attack},
				{"Start", settings.buttons.start},
				{"Back", ""}
			}

			if settings.controls.assigning then
				toprint[settings.controls.option][2] = "[      ]"
			end

			love.graphics.setFont(fonts.settings)

			for i = 1, #toprint do
				love.graphics.setColor(colors.ORANGE)
				love.graphics.print(toprint[i][1], 525, 220 + 35 * i)

				love.graphics.setColor(colors.GREEN)
				love.graphics.print(toprint[i][2], 640, 220 + 35 * i)
			end

			love.graphics.setLineWidth(3)
			love.graphics.setColor(colors.ORANGE)
			love.graphics.rectangle(
				"line",
				520,
				220 + 35 * settings.controls.option,
				190,
				34
			)
		end

	love.graphics.pop()
end

function draw.draw_super_overlays(facing, frogface)
	for i = 0, 44 do
		local h_shift = -200 + math.sin(i / 38) * 400
		particles.overlays.super_profile:repeatLoad(
			window.center,
			200,
			h_shift,
			0,
			facing,
			i,
			"post2"
		)

		local frog_shift = -400 + math.sin(i / 38) * 400
		frogface:repeatLoad(
			window.center,
			200,
			frog_shift,
			0,
			facing,
			i,
			"post3"
		)
	end
end

return draw
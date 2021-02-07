require 'lovedebug'
require 'utilities' -- helper functions
require 'camera'
require 'draw'
json = require 'dkjson'
class = require 'middleclass' -- class support
local stage = require 'stage'  -- total playing field area
window = require 'window'  -- current view of stage
music = require 'music'
character = require 'character'
particles = require 'particles'
require 'Konrad'
require 'Jean'
require 'Sun'
require 'Frogson'
require 'AI'
require 'settings'
require 'title'


sound = require 'sound'

math.randomseed(os.time())
math.random(); math.random(); math.random()

checkVersion()


-- build screen
love.window.setMode(window.width, window.height)
love.window.setTitle("Divefrog the fighting game sensation")

-- build canvas layers
canvas_overlays = love.graphics.newCanvas(stage.width, stage.height)
canvas_sprites = love.graphics.newCanvas(stage.width, stage.height)
canvas_background = love.graphics.newCanvas(stage.width, stage.height)
canvas_super = love.graphics.newCanvas(stage.width, stage.height)

function love.load()
  game = {
	current_screen = "title",
	best_to_x = Params.Rounds,
	speed = Params.Speed,
	current_round = 0,
	match_winner = false,
	superfreeze_time = 0,
	superfreeze_player = nil,
	BGM = nil,
	background_color = nil,
	isScreenShaking = false,
	identical_players = false,
	format = ""
	}
  setBGM("Intro.ogg")
  min_dt = 1/60 -- frames per second
  next_time = love.timer.getTime()
  frame = 0 -- framecount
  frame0 = 0 -- timer for start of round fade in
  init_round_timer = Params.Timer * 60 -- round time in frames
  round_timer = init_round_timer
  round_end_frame = 0
  round_ended = false
  keybuffer = {false, false, false, false} -- log of all keystates during the round. Useful for netplay!
  prebuffer = {} -- pre-load draw instruction into future frames behind sprite
  postbuffer = {} -- pre-load draw instructions into future frames over sprite
  post2buffer = {}
  post3buffer = {}
  camera_xy = {} -- top left window corner for camera and window drawing
  debug = {boxes = false, sprites = false, midpoints = false, camera = false,	keybuffer = false}
end

function love.draw()
  if game.current_screen == "maingame" then
		test.t0 = love.timer.getTime()
	canvas_background:renderTo(drawBackground)

		test.t1 = love.timer.getTime()
	canvas_sprites:renderTo(drawMain)

		test.t2 = love.timer.getTime()
	canvas_overlays:renderTo(drawOverlays)
	canvas_overlays:renderTo(drawRoundStart)
	canvas_overlays:renderTo(drawRoundEnd)

	canvas_super:renderTo(drawOverlays2)

		test.t3 = love.timer.getTime()
	--camera:scale(1 / camera_scale_factor, 1 / camera_scale_factor)

	camera:set(0.5, 1)
	love.graphics.draw(canvas_background)
	camera:unset()

		test.t4 = love.timer.getTime()
	camera:set(1, 1)
	love.graphics.draw(canvas_sprites)

	if debug.boxes then drawDebugHurtboxes() end 
	if debug.sprites then drawDebugSprites() end 
	camera:unset()

		test.t5 = love.timer.getTime()
	camera:set(0, 0)

	love.graphics.draw(canvas_overlays)

	love.graphics.draw(canvas_super)

	if debug.midpoints then drawMidPoints() end
	camera:unset()

		test.t6 = love.timer.getTime()
	--camera:scale(camera_scale_factor, camera_scale_factor)

	if debug.camera then print(unpack(camera_xy)) end
	if debug.keybuffer then print(unpack(keybuffer[frame])) end

  elseif game.current_screen == "charselect" then
	drawCharSelect()

  elseif game.current_screen == "match_end" then
	drawMatchEnd()

  elseif game.current_screen == "title" then
	drawTitle()

	elseif game.current_screen == "settings" then
		drawSettingsMain()
		drawSettingsPopup()

	elseif game.current_screen == "replays" then
		love.graphics.draw(replaysscreen, 0, 0, 0)

  end

  local cur_time = love.timer.getTime() -- time after drawing all the stuff

  if cur_time - next_time >= 0 then
	next_time = cur_time -- time needed to sleep until the next frame (?)
  end

	test.t7 = love.timer.getTime()
  love.timer.sleep(next_time - cur_time) -- advance time to next frame (?)

	test.t8 = love.timer.getTime()
end

function love.update(dt)
  frame = frame + 1
  if game.current_screen == "maingame" then

	if game.superfreeze_time == 0 then
	  local h_midpoint = (p1:getCenter() + p2:getCenter()) / 2
	  local highest_sprite = math.min(p1.pos[2] + p1.sprite_size[2], p2.pos[2] + p2.sprite_size[2])
	  local screen_bottom = stage.height - window.height

	  camera_xy = {clamp(h_midpoint - window.center, 0, stage.width - window.width),
		screen_bottom - (stage.floor - highest_sprite) / 8 }

			-- screen shake
		local h_displacement = 0
		local v_displacement = 0

		if game.isScreenShaking then
			h_displacement = (frame % 7 * 6 + frame % 13 * 3 + frame % 23 * 2 - 60) / 2
			v_displacement = (frame % 5 * 8 + frame % 11 * 3 + frame % 17 * 2 - 30) / 2
		end
	  camera:setPosition(camera_xy[1] + h_displacement, camera_xy[2] - v_displacement)

	-- tweening for scale and camera position
	else
	  game.superfreeze_time = game.superfreeze_time - 1
	end

	if not round_ended and not (p1.frozenFrames > 0 and p2.frozenFrames > 0) then
	  round_timer = math.max(round_timer - (1 * game.speed), 0)
	end

	-- get button press state, and write to keybuffer table
	if game.format == "2P" then
	  keybuffer[frame] = {
	  love.keyboard.isDown(buttons.p1jump),
	  love.keyboard.isDown(buttons.p1attack),
	  love.keyboard.isDown(buttons.p2jump),
	  love.keyboard.isDown(buttons.p2attack)}
	elseif game.format == "1P" then
	  local AIjump, AIattack = AI.Action(p2, p1)
	  keybuffer[frame] = {
	  love.keyboard.isDown(buttons.p1jump),
	  love.keyboard.isDown(buttons.p1attack),
	  AIjump,
	  AIattack}
	elseif game.format == "Netplay1P" then
	  keybuffer[frame] = {
	  love.keyboard.isDown(buttons.p1jump),
	  love.keyboard.isDown(buttons.p1attack),
	  love.keyboard.isDown(buttons.p2jump),   -- get netplay data here
	  love.keyboard.isDown(buttons.p2attack)} -- get netplay data here
	elseif game.format == "Netplay2P" then
	  keybuffer[frame] = {
	  love.keyboard.isDown(buttons.p1jump),   -- get netplay data here
	  love.keyboard.isDown(buttons.p1attack), -- get netplay data here
	  love.keyboard.isDown(buttons.p2jump),   
	  love.keyboard.isDown(buttons.p2attack)}
	end


	-- read keystate from keybuffer and call the associated functions
	if not round_ended then
	  if keybuffer[frame][1] and p1.frozenFrames == 0 and not keybuffer[frame-1][1] then p1:jump_key_press() end
	  if keybuffer[frame][2] and p1.frozenFrames == 0 and not keybuffer[frame-1][2] then p1:attack_key_press() end
	  if keybuffer[frame][3] and p2.frozenFrames == 0 and not keybuffer[frame-1][3] then p2:jump_key_press() end
	  if keybuffer[frame][4] and p2.frozenFrames == 0 and not keybuffer[frame-1][4] then p2:attack_key_press() end
	end

	-- update character positions
	p1:updatePos()
	p2:updatePos()

	-- check if anyone got hit
	if check_got_hit(p1, p2) and check_got_hit(p2, p1) then
	  round_end_frame = frame
	  round_ended = true
	  p1:gotHit(p2.hit_type)
	  p2:gotHit(p1.hit_type)

	elseif check_got_hit(p1, p2) then
	  round_end_frame = frame
	  round_ended = true
	  p1:gotHit(p2.hit_type)
	  p2:hitOpponent()

	elseif check_got_hit(p2, p1) then
	  round_end_frame = frame
	  round_ended = true
	  p2:gotHit(p1.hit_type)
	  p1:hitOpponent()
	end

	-- check if timeout
	if round_timer == 0 and not round_ended then
	  round_end_frame = frame
	  round_ended = true
	  local p1_from_center = math.abs((stage.center) - p1:getCenter())
	  local p2_from_center = math.abs((stage.center) - p2:getCenter())
	  if p1_from_center < p2_from_center then
		p2:gotHit(p1.hit_type)
		p1:hitOpponent()
	  elseif p2_from_center < p1_from_center then
		p1:gotHit(p2.hit_type)
		p2:hitOpponent()
	  else
		p1:gotHit(p2.hit_type)
		p2:gotHit(p1.hit_type)
	  end 
	end  

	sound.update()

	-- after round ended and displayed round end stuff, start new round
	if frame - round_end_frame == 144 then
	  for p, _ in pairs(Players) do
		if p.hasWon then p:addScore() end
		if p.score == game.best_to_x then game.match_winner = p end
	  end

	  if not game.match_winner then newRound()
	  else -- match end
		frame = 0
		frame0 = 0
		setBGM("GameOver.ogg")
		game.current_screen = "match_end" 
		keybuffer = {}
	  end
	end

	-- advance time (?)
	next_time = next_time + min_dt
  end
end

function newRound()

  --Uncomment this for replays later. Too annoying atm sorry
	--local keybuffer_string = json.encode(keybuffer)
	--local filename = "saves/" .. os.date("%m%d%H%M") .. p1_char .. "v" ..
	--	p2_char .. "R" .. game.current_round .. ".txt" -- need to modify this later if 10+ chars
	--love.filesystem.write(filename, keybuffer_string)

  p1:initialize(1, p2, p1.super, p1.hitflag.Mugshot, p1.score)
  p2:initialize(2, p1, p2.super, p2.hitflag.Mugshot, p2.score)

  frame = 0
  frame0 = 0
  round_timer = init_round_timer
  round_ended = false
  round_end_frame = 100000 -- arbitrary number, larger than total round time
  game.current_round = game.current_round + 1
  game.background_color = nil
  game.isScreenShaking = false
  keybuffer = {false, false, false, false}
  prebuffer = {}
  postbuffer = {}
  post2buffer = {}
  post3buffer = {}
  sound.reset()
	camera_xy_temp = nil
	camera_scale_factor = 1
  if p1.score == game.best_to_x - 1 and p2.score == game.best_to_x - 1 then
	setBGMspeed(2 ^ (4/12))
  end
end

function startGame()

  if game.format == "1P" then
	default_selections.player1P = p1_char
	default_selections.AI1P = p2_char
  elseif game.format == "2P" then
	default_selections.player12P = p1_char
	default_selections.player22P = p2_char
  end
  love.filesystem.write("choices.txt", json.encode(default_selections)) 

  game.current_screen = "maingame"

  p1 = available_chars[p1_char](1, p2, 0, false, 0)
  p2 = available_chars[p2_char](2, p1, 0, false, 0)
  if p1_char == p2_char then game.identical_players = true end

  Players = { [p1] = {move = -1, flip = 1, offset = 0},
			  [p2] = {move = 1, flip = -1, offset = 1}}
  game.BGM = p2.BGM
  setBGM(game.BGM)
  newRound()
end

test = {}

function love.keypressed(key)
  if key == "escape" then love.event.quit() end

  if game.current_screen == "title" then
	if key == buttons.p1attack or key == buttons.start then
		sound.playCharSelectedSFX()
		title_choices.action[title_choices.option]()

	elseif key == buttons.p1jump or key == "down" then
		sound.playCharSelectSFX()
		title_choices.option = title_choices.option % #title_choices.menu + 1

	elseif key == "up" then
	  sound.playCharSelectSFX()
	  title_choices.option = (title_choices.option - 2) % #title_choices.menu + 1
	end

  elseif game.current_screen == "charselect" then
	if key == buttons.p1attack or key == buttons.p2attack then
	  sound.playCharSelectedSFX()
	  startGame()
	end

	if key == buttons.p1jump then
		p1_char = p1_char % #available_chars + 1
	  portraitsQuad = love.graphics.newQuad(0, (p1_char - 1) * 140, 200, 140, portraits:getDimensions())
	  sound.playCharSelectSFX()
	end

	if key == buttons.p2jump then
		p2_char = p2_char % #available_chars + 1
	  sound.playCharSelectSFX()
	end

  elseif game.current_screen == "settings" then
	setupReceiveKeypress(key)

  elseif game.current_screen == "replays" then
	if key == buttons.start then
		sound.playCharSelectSFX()
		game.current_screen = "title"
	end

  elseif game.current_screen == "match_end" then
	if key ==  buttons.start then
	  love.load()
	  game.current_screen = "title"
	end
  end

  if key == '`' then p1.super = 90 p2.super = 90 end
  if key == '1' then debug.boxes = not debug.boxes end
  if key == '2' then debug.sprites = not debug.sprites end
  if key == '3' then debug.midpoints = not debug.midpoints end
  if key == '4' then debug.camera = not debug.camera end
  if key == '5' then debug.keybuffer = not debug.keybuffer end
  if key == '6' then print(love.filesystem.getSaveDirectory()) end
  if key == '7' then 
	local output_keybuffer = json.encode(keybuffer)
	local filename = os.date("%Y.%m.%d.%H%M") .. " Keybuffer.txt"
	success = love.filesystem.write(filename, output_keybuffer)
  end
  if key == '8' then
	local calc_background = (test.t1 - test.t0) * 100 / min_dt
	local calc_sprites = (test.t2 - test.t1) * 100 / min_dt
	local calc_overlays = (test.t3 - test.t2) * 100 / min_dt
	local draw_background = (test.t4 - test.t3) * 100 / min_dt
	local draw_sprites = (test.t5 - test.t4) * 100 / min_dt
	local draw_overlays = (test.t6 - test.t5) * 100 / min_dt
	local sleep = (test.t8 - test.t7) * 100 / min_dt
	print("Calculate background % of CPU:", calc_background)
	print("Calculate sprites    % of CPU:", calc_sprites)
	print("Calculate overlays   % of CPU:", calc_overlays)
	print("Draw background      % of CPU:", draw_background)
	print("Draw sprites         % of CPU:", draw_sprites)
	print("Draw overlays        % of CPU:", draw_overlays)
	print("Sleep:", sleep)
  end
  if key == '9' then
	local globaltable = {}
	local num = 1
	for k, v in pairs(_G) do
		globaltable[num] = k
		num = num + 1
	end
	local output_globals = json.encode(globaltable)
	local filename = os.date("%Y.%m.%d.%H%M") .. " globals.txt"
	love.filesystem.write(filename, output_globals)
	print("Globals written to file")
  end
end

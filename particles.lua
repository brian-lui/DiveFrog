local love = _G.love

local class = require 'middleclass'
local images = require 'images'
local sounds = require 'sounds'
require 'utilities'

--[[
	Example:repeatLoad(
	self.center, -- no need to change
	self.pos[2], -- no need to change
	-100, -- horizontal shift
	self.sprite_size[2], -- vertical shift
	self.facing) -- no need to change
]]


--[[---------------------------------------------------------------------------
								PARTICLE / FX CLASS
-----------------------------------------------------------------------------]]
local draw_count = 0 -- each object gets a new index number, to prevent overwriting

local Particle = class('Particle')
function Particle:initialize(image, image_size, sprite_size, time_per_frame, sound, color)
	self.image = image
	self.image_size = {image:getDimensions()}
	self.sprite_size = sprite_size
	self.width = sprite_size[1]
	self.height = sprite_size[2]
	self.center = sprite_size[1] / 2
	self.sound = sound
	self.total_frames = image_size[1] / sprite_size[1]
	self.time_per_frame = time_per_frame
	self.total_time = time_per_frame * self.total_frames
	self.color = color
end

function Particle:_getDrawable(image_index, pos_h, pos_v, scale_x, scale_y, RGBTable)
	local quad = love.graphics.newQuad(image_index * self.width, 0,
	self.width, self.height, self.image_size[1], self.image_size[2])
	return {self.image,
	quad,
	pos_h + self.center,
	pos_v,
	0,
	scale_x, -- scale_x: 1 is default, -1 for flip
	scale_y,
	self.center, -- anchor_x
	0, -- anchor_y
	0,
	0,
	RGBTable or self.color}
end

function Particle:playSound(delay_time)
	sounds.writeSound(self.sound, delay_time)
end

-- called each frame while condition is valid
function Particle:repeatLoad(sprite_center_h, sprite_v, h_shift, v_shift, facing, delay_time, layer, RGBTable)
	draw_count = draw_count + 1
	local delay = delay_time or 0
	local buffer = postbuffer
	if layer == "pre" then
	buffer = prebuffer
	elseif layer == "post2" then
	buffer = post2buffer
	elseif layer == "post3" then
	buffer = post3buffer
	end

	local current_anim = math.floor((frame + delay) % self.total_time / self.time_per_frame)
	buffer[frame + delay] = buffer[frame + delay] or {}
	buffer[frame + delay][draw_count] = self:_getDrawable(current_anim,
	sprite_center_h - self.center + (facing * h_shift),
	sprite_v + v_shift,
	facing, math.abs(facing), RGBTable)
end

-- called once, loads entire anim
function Particle:singleLoad(sprite_center_h, sprite_v, h_shift, v_shift, facing, delay_time, layer, RGBTable)
	draw_count = draw_count + 1
	local delay = delay_time or 0
	local buffer = postbuffer
	if layer == "pre" then
	buffer = prebuffer
	elseif layer == "post2" then
	buffer = post2buffer
	elseif layer == "post3" then
	buffer = post3buffer
	end

	for i = (frame + delay), (frame + delay + self.total_time) do
	local current_anim = math.floor((i - (frame + delay)) / self.time_per_frame)
	buffer[i] = buffer[i] or {}
	buffer[i][draw_count] = self:_getDrawable(current_anim,
		sprite_center_h - self.center + (facing * h_shift),
		sprite_v + v_shift,
		facing, math.abs(facing), RGBTable)
	end
end


-- when super is active
local AfterImage = class('AfterImage', Particle)
function AfterImage:initialize(image, image_size, sprite_size, time_per_frame, sound)
	Particle.initialize(self, image, image_size, sprite_size, time_per_frame, sound)
end

function AfterImage:loadFX(sprite_center_h, sprite_v, h_shift, v_shift, facing)
	local shadow = {
	[8] = {255, 180, 0, 200},
	[16] = {255, 180, 0, 150}, 
	[24] = {255, 180, 0, 100}
	}
	for s_frame, color in pairs(shadow) do
	draw_count = draw_count + 1
	prebuffer[frame + s_frame] = prebuffer[frame + s_frame] or {}
	prebuffer[frame + s_frame][draw_count] = self:_getDrawable(0,
		sprite_center_h - self.center + (facing * h_shift),
		sprite_v + v_shift,
		facing, math.abs(facing), color)
	end
end

local particles = {}

particles.AfterImage = AfterImage

particles.overlays = {
	frog_factor = Particle:new(
		images.particles.overlays.frog_factor,
		{1176, 130},
		{168, 130},
		4
	),
	super_bar_base = Particle:new(
		images.particles.overlays.super_bar_base,
		{196, 19},
		{196, 19},
		1
	),
	super_meter = Particle:new(
		images.particles.overlays.super_meter,
		{192, 120},
		{192, 15},
		8
	),
	super_profile = Particle:new(
		images.particles.overlays.super_profile,
		{1200, 200},
		{1200, 200},
		1
	),
}

particles.common = {
	mugshot = Particle:new(
		images.particles.common.mugshot,
		{600, 140},
		{600, 140},
		60,
		"Mugshot.ogg"
	),
	dizzy = Particle:new(
		images.particles.common.dizzy,
		{67, 50},
		{67, 50},
		1,
		true
	),
	on_fire = Particle:new(
		images.particles.common.on_fire,
		{800, 200},
		{200, 200},
		3
	),
	jump_dust = Particle:new(
		images.particles.common.jump_dust,
		{528, 60},
		{132, 60},
		4,
		"dummy.ogg",
		{255, 255, 255, 0.76}
	),
	kickback_dust = Particle:new(
		images.particles.common.kickback_dust,
		{162, 42},
		{54, 42},
		4,
		"dummy.ogg",
		{255, 255, 255, 0.76}
	),
	explosion1 = Particle:new(
		images.particles.common.explosion1,
		{800, 80},
		{80, 80},
		3,
		"Explosion.ogg"
	),
	explosion2 = Particle:new(
		images.particles.common.explosion2,
		{880, 80},
		{80, 80},
		3,
		"Explosion2.ogg"
	),
	explosion3 = Particle:new(
		images.particles.common.explosion3,
		{880, 80},
		{80, 80},
		3,
		"Explosion3.ogg"
	),
	wire_sea = Particle:new(
		images.particles.common.wire_sea,
		{1600, 220},
		{200, 220},
		2,
		"WireSea.ogg"
	),
}

particles.speech_bubbles = {
	pow = Particle:new(
		images.particles.speech_bubbles.pow,
		{160, 120},
		{160, 120},
		1,
		"SpeechBubble.ogg"
	),
	biff = Particle:new(
		images.particles.speech_bubbles.biff,
		{160, 120},
		{160, 120},
		1,
		"SpeechBubble.ogg"
	),
	wham = Particle:new(
		images.particles.speech_bubbles.wham,
		{160, 120},
		{160, 120},
		1,
		"SpeechBubble.ogg"
	),
	zap = Particle:new(
		images.particles.speech_bubbles.zap,
		{160, 120},
		{160, 120},
		1,
		"SpeechBubble.ogg"
	),
	jeb = Particle:new(
		images.particles.speech_bubbles.jeb,
		{160, 120},
		{160, 120},
		1,
		"SpeechBubble.ogg"
	),
	bath = Particle:new(
		images.particles.speech_bubbles.bath,
		{160, 120},
		{160, 120},
		1,
		"SpeechBubble.ogg"
	),
	bop = Particle:new(
		images.particles.speech_bubbles.bop,
		{160, 120},
		{160, 120},
		1,
		"SpeechBubble.ogg"
	),
	smack = Particle:new(
		images.particles.speech_bubbles.smack,
		{160, 120},
		{160, 120},
		1,
		"SpeechBubble.ogg"
	),
	thump = Particle:new(
		images.particles.speech_bubbles.thump,
		{160, 120},
		{160, 120},
		1,
		"SpeechBubble.ogg"
	),
	zwapp = Particle:new(
		images.particles.speech_bubbles.zwapp,
		{160, 120},
		{160, 120},
		1,
		"SpeechBubble.ogg"
	),
	clunk = Particle:new(
		images.particles.speech_bubbles.clunk,
		{160, 120},
		{160, 120},
		1,
		"SpeechBubble.ogg"
	),
}

particles.konrad = {
	super_face = Particle:new(
		images.characters.konrad.super_face,
		{275, 200},
		{275, 200},
		1
	),
	hyperkick_flames = Particle:new(
		images.characters.konrad.hyperkick_flames,
		{800, 200},
		{200, 200},
		2,
		"Konrad/KonradHyperKick.ogg"
	),
	doublejump_dust = Particle:new(
		images.characters.konrad.doublejump_dust,
		{162, 43},
		{54, 43},
		4,
		"Konrad/KonradDoubleJump.ogg",
		{255, 255, 255, 0.76}
	),
}

particles.sun = {
	super_face = Particle:new(
		images.characters.sun.super_face,
		{275, 200},
		{275, 200},
		1
	),
	aura = Particle:new(
		images.characters.sun.aura,
		{800, 250},
		{200, 250},
		6
	),
	hotflame = Particle:new(
		images.characters.sun.hotflame,
		{120, 195},
		{60, 195},
		4,
		"Sun/Hotflame.ogg"
	),
	hotterflame = Particle:new(
		images.characters.sun.hotterflame,
		{300, 252},
		{150, 252},
		4,
		"Sun/Hotterflame.ogg"
	),
}

particles.frogson = {
	super_face = Particle:new(
		images.characters.frogson.super_face,
		{275, 200},
		{275, 200},
		1
	),
	screen_flash = Particle:new(
		images.characters.frogson.screen_flash,
		{1200, 800},
		{1200, 800},
		4
	),
}

particles.jean = {
	super_face = Particle:new(
		images.characters.jean.super_face,
		{275, 200},
		{275, 200},
		1
	),
}

return particles
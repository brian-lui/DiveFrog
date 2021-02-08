local images = {}

images.replaysscreen = love.graphics.newImage('images/Replays.jpg')
images.charselectscreen = love.graphics.newImage('images/CharSelect.jpg')
images.bkmatchend = love.graphics.newImage('images/MatchEndBackground.png')
images.hpbar = love.graphics.newImage('images/HPBar.png')
images.portraits = love.graphics.newImage('images/Portraits.png')
images.greenlight = love.graphics.newImage('images/GreenLight.png')
images.dummy = love.graphics.newImage('images/dummy.png')

images.characters = {
	konrad = {
		icon = love.graphics.newImage('images/Konrad/KonradIcon.png'),
		win_portrait = love.graphics.newImage('images/Konrad/KonradPortrait.png'),
		stage_background = love.graphics.newImage('images/Konrad/KonradBackground.jpg'),
		image = love.graphics.newImage('images/Konrad/KonradTiles.png'),
		super_face = love.graphics.newImage('images/Konrad/KonradSuperface.png'),

		hyperkick_flames = love.graphics.newImage('images/Konrad/HyperKickFlames.png'), 
		doublejump_dust = love.graphics.newImage('images/Konrad/DoubleJumpDust.png'),
	},
	jean = {
		icon = love.graphics.newImage('images/Jean/JeanIcon.png'),
		win_portrait = love.graphics.newImage('images/Jean/JeanPortrait.png'),
		stage_background = love.graphics.newImage('images/Jean/JeanBackground.jpg'),
		image = love.graphics.newImage('images/Jean/JeanTiles.png'),
		super_face = love.graphics.newImage('images/Jean/JeanSuperface.png'), 
	},
	sun = {
		icon = love.graphics.newImage('images/Sun/SunIcon.png'),
		win_portrait = love.graphics.newImage('images/Sun/SunPortrait.png'),
		stage_background = love.graphics.newImage('images/Sun/SunBackground.jpg'),
		image = love.graphics.newImage('images/Sun/SunTiles.png'),
		super_face = love.graphics.newImage('images/Sun/SunSuperface.png'),

		aura = love.graphics.newImage('images/Sun/Aura.png'),
		hotflame = love.graphics.newImage('images/Sun/HotflameFX.png'),
		hotterflame = love.graphics.newImage('images/Sun/HotterflameFX.png'),
	},
	frogson = {
		icon = love.graphics.newImage('images/Frogson/FrogsonIcon.png'),
		win_portrait = love.graphics.newImage('images/Frogson/FrogsonPortrait.png'),
		stage_background = love.graphics.newImage('images/Frogson/FrogsonBackground.jpg'),
		image = love.graphics.newImage('images/Frogson/FrogsonTiles.png'),
		super_face = love.graphics.newImage('images/Frogson/FrogsonSuperface.png'),

		screen_flash = love.graphics.newImage('images/Frogson/Flash.png'),
	},
}

images.particles = {
	common = {
		mugshot = love.graphics.newImage('images/Mugshot.png'),
		dizzy = love.graphics.newImage('images/Dizzy.png'),
		on_fire = love.graphics.newImage('images/OnFire.png'),
		jump_dust = love.graphics.newImage('images/JumpDust.png'),
		kickback_dust = love.graphics.newImage('images/KickbackDust.png'),
		wire_sea = love.graphics.newImage('images/WireSea.png'),
		explosion1 = love.graphics.newImage('images/Explosion1.png'),
		explosion2 = love.graphics.newImage('images/Explosion2.png'),
		explosion3 = love.graphics.newImage('images/Explosion3.png'),
	},
	overlays = {
		frog_factor = love.graphics.newImage('images/FrogFactor.png'),
		super_bar_base = love.graphics.newImage('images/SuperBarBase.png'),
		super_meter = love.graphics.newImage('images/SuperMeter.png'),
		super_profile = love.graphics.newImage('images/SuperProfile.png'),
	},
	speech_bubbles = {
		pow = love.graphics.newImage('images/SpeechBubbles/Pow.png'),
		biff = love.graphics.newImage('images/SpeechBubbles/Biff.png'),
		wham = love.graphics.newImage('images/SpeechBubbles/Wham.png'),
		zap = love.graphics.newImage('images/SpeechBubbles/Zap.png'),
		jeb = love.graphics.newImage('images/SpeechBubbles/Jeb.png'),
		bath = love.graphics.newImage('images/SpeechBubbles/Bath.png'),
		bop = love.graphics.newImage('images/SpeechBubbles/Bop.png'),
		smack = love.graphics.newImage('images/SpeechBubbles/Smack.png'),
		thump = love.graphics.newImage('images/SpeechBubbles/Thump.png'),
		zwapp = love.graphics.newImage('images/SpeechBubbles/Zwapp.png'),
		clunk = love.graphics.newImage('images/SpeechBubbles/Clunk.png'),
	},
}

images.settings = {
	background = love.graphics.newImage('images/Settings/SettingsBackground.jpg'),
	logo = love.graphics.newImage('images/Settings/SettingsLogo.png'),
	texture = love.graphics.newImage('images/Settings/SettingsMenuBk.jpg'),
}

images.title = {
	screen = love.graphics.newImage('images/Title/TitleBackground.jpg'),
	select_background = love.graphics.newImage('images/Title/TitleSelect.png'),
	logo = love.graphics.newImage('images/Title/TitleLogo.png'),
	controls_background = love.graphics.newImage('images/Title/TitleControlsBk.png'),
}







return images


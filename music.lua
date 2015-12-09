currentBGM = nil
function setBGM(filename)
  if currentBGM then currentBGM:stop() end
  currentBGM = love.audio.newSource("music/" .. filename, "stream")
  currentBGM:setVolume(0.6)
  currentBGM:setLooping(true)
  currentBGM:rewind()
  currentBGM:play()
end

function setBGMspeed(speed)
	currentBGM:setPitch(speed)
end
currentSFX1 = nil
function playSFX1(filename)
	currentSFX1 = love.audio.newSource("sounds/" .. filename)
	currentSFX1:setVolume(0.7)
	--currentSFX1:rewind()
	currentSFX1:play()
end

currentSFX2 = nil
function playSFX2(filename)
	currentSFX2 = love.audio.newSource("sounds/" .. filename)
	currentSFX2:setVolume(0.7)
	--currentSFX2:rewind()
	currentSFX2:play()
end
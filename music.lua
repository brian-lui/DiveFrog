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

currentSFX = nil
function playSFX(filename)
	currentSFX = love.audio.newSource("sounds/" .. filename)
	currentSFX:setVolume(0.7)
	currentSFX:play()
end


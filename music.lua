currentBGM = love.audio.newSource("sounds/dummy.ogg")
currentBGM2 = love.audio.newSource("sounds/dummy.ogg")

function setBGM(filename)
  if currentBGM then currentBGM:stop() end
  currentBGM = love.audio.newSource("music/" .. filename, "stream")
  currentBGM:setVolume(0.6)
  currentBGM:setLooping(true)
  currentBGM:rewind()
  currentBGM:play()
end

function pauseBGM()
  currentBGM:pause()
end

function stopBGM()
  currentBGM:stop()
end

function resumeBGM()
  currentBGM:resume()
end

function setBGMspeed(speed)
	currentBGM:setPitch(speed)
end


function setBGM2(filename)
  if currentBGM2 then currentBGM2:stop() end
  currentBGM2 = love.audio.newSource("music/" .. filename, "stream")
  currentBGM2:setVolume(0.6)
  currentBGM2:setLooping(true)
  currentBGM2:rewind()
  currentBGM2:play()
end

function pauseBGM2()
  currentBGM2:pause()
end

function stopBGM2()
  currentBGM2:stop()
end

function resumeBGM2()
  currentBGM2:resume()
end

function setBGM2speed(speed)
  currentBGM2:setPitch(speed)
end

currentSFX = nil
function playSFX(filename)
	currentSFX = love.audio.newSource("sounds/" .. filename)
	currentSFX:setVolume(0.7)
	currentSFX:play()
end


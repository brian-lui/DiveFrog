local love = _G.love

local music = {}

music.currentBGM = love.audio.newSource("sounds/dummy.ogg", "stream")
music.currentBGM2 = love.audio.newSource("sounds/dummy.ogg", "stream")

function music.setBGM(filename)
  if music.currentBGM then music.currentBGM:stop() end
  music.currentBGM = love.audio.newSource("music/" .. filename, "stream")
  music.currentBGM:setVolume(0.9 * Params.Music)
  music.currentBGM:setLooping(true)
  music.currentBGM:stop()
  music.currentBGM:play()
end

function music.pauseBGM()
  music.currentBGM:pause()
end

function music.stopBGM()
  music.currentBGM:stop()
end

function music.resumeBGM()
  music.currentBGM:play()
end

function music.setBGMspeed(speed)
  music.currentBGM:setPitch(speed)
end

function music.setBGM2(filename)
  if music.currentBGM2 then music.currentBGM2:stop() end
  music.currentBGM2 = love.audio.newSource("music/" .. filename, "stream")
  music.currentBGM2:setVolume(0.9 * Params.Music)
  music.currentBGM2:setLooping(true)
  music.currentBGM2:stop()
  music.currentBGM2:play()
end

function music.pauseBGM2()
  music.currentBGM2:pause()
end

function music.stopBGM2()
  music.currentBGM2:stop()
end

function music.resumeBGM2()
  music.currentBGM2:resume()
end

function music.setBGM2speed(speed)
  music.currentBGM2:setPitch(speed)
end

return music
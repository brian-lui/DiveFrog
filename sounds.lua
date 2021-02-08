local sounds = {}

sounds.soundbuffer = {}

sounds.currentSFX = nil

function sounds.writeSound(SFX, delay_time)
  local delay = delay_time or 0
  local write_frame = frame + delay
  while sounds.soundbuffer[write_frame] do
    write_frame = write_frame + 1
  end
  sounds.soundbuffer[write_frame] = SFX
end

function sounds._playSFX(filename)
  sounds.currentSFX = love.audio.newSource("sounds/" .. filename, "static")
  sounds.currentSFX:setVolume(Params.Sound)
  sounds.currentSFX:play()
end 

function sounds.playCharSelectSFX()
    sounds._playSFX("CharSelectSFX.ogg")
end

function sounds.playCharSelectedSFX()
    sounds._playSFX("CharSelectedSFX.ogg")
end

function sounds.playSuperSFX()
  sounds._playSFX("SuperFull.ogg")
end

function sounds.update()
  if sounds.soundbuffer[frame] then
    sounds._playSFX(sounds.soundbuffer[frame])
    print("sound played on frame", frame)
  end
end

function sounds.reset()
  sounds.soundbuffer = {}
end

return sounds
local sound = {}

sound.soundbuffer = {}

sound.currentSFX = nil

function sound.writeSound(SFX, delay_time)
  local delay = delay_time or 0
  local write_frame = frame + delay
  while sound.soundbuffer[write_frame] do
    write_frame = write_frame + 1
  end
  sound.soundbuffer[write_frame] = SFX
end

function sound._playSFX(filename)
  sound.currentSFX = love.audio.newSource("sounds/" .. filename, "static")
  sound.currentSFX:setVolume(Params.Sound)
  sound.currentSFX:play()
end 

function sound.playCharSelectSFX()
    sound._playSFX("CharSelectSFX.ogg")
end

function sound.playCharSelectedSFX()
    sound._playSFX("CharSelectedSFX.ogg")
end

function sound.playSuperSFX()
  sound._playSFX("SuperFull.ogg")
end

function sound.update()
  if sound.soundbuffer[frame] then
    sound._playSFX(sound.soundbuffer[frame])
    print("sound played on frame", frame)
  end
end

function sound.reset()
  sound.soundbuffer = {}
end
return sound
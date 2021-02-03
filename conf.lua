function love.conf(t)
    t.modules.joystick = false
    t.modules.physics = false
    t.console = true
end
print(love.filesystem.getSaveDirectory())

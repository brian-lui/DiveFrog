local screen = require 'screen'
local window = {}
window.scale = 1
window.width = screen.widthPx * window.scale
window.height = screen.heightPx * window.scale
return window

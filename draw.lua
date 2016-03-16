require 'lovedebug'
require 'utilities' -- helper functions
require 'camera'
local json = require 'dkjson'
local class = require 'middleclass' -- class support
local stage = require 'stage'  -- total playing field area
local window = require 'window'  -- current view of stage
local music = require 'music'
local character = require 'character'
require 'Konrad'
require 'Jean'
require 'Sun'
require 'Frogson'
require 'AI'
require 'settings'
require 'title'
local particles = require 'particles'

-- load images
local replaysscreen = love.graphics.newImage('images/Replays.jpg')
local charselectscreen = love.graphics.newImage('images/CharSelect.jpg')
local bkmatchend = love.graphics.newImage('images/MatchEndBackground.png')
local hpbar = love.graphics.newImage('images/HPBar.png')
local portraits = love.graphics.newImage('images/Portraits.png')
local greenlight = love.graphics.newImage('images/GreenLight.png')
local portraitsQuad = love.graphics.newQuad(0, 0, 200, 140,portraits:getDimensions())

-- load fonts
local roundStartFont = love.graphics.newFont('/fonts/Comic.otf', 60)
local roundCountdownFont = love.graphics.newFont('/fonts/Comic.otf', 20)
local roundEndFont = love.graphics.newFont('/fonts/ComicItalic.otf', 42)
local charInfoFont = love.graphics.newFont('/fonts/CharSelect.ttf', 21)
local charSelectorFont = love.graphics.newFont('/fonts/GoodDog.otf', 18)
local timerFont = love.graphics.newFont('/fonts/Comic.otf', 40)
local gameoverFont = love.graphics.newFont('/fonts/ComicItalic.otf', 24)
local gameoverHelpFont = love.graphics.newFont('/fonts/ComicItalic.otf', 16)

-- color presets
COLOR = {
  WHITE = {255, 255, 255, 255},
  OFF_WHITE = {255, 255, 255, 160},
  DULL_ORANGE = {195, 160, 0, 210},
  ORANGE = {255, 215, 0, 255},
  DARK_ORANGE = {230, 147, 0, 255},
  LIGHT_GREEN = {128, 255, 128, 255},
  GRAY = {96, 96, 96, 255},
  BLACK = {0, 0, 0, 255},
  SHADOW = {0, 0, 0, 96},
  RED = {220, 0, 0, 255},
  BLUE = {14, 28, 232, 255},
  GREEN = {14, 232, 54, 255},
  PALE_BLUE = {164, 164, 255, 255},
  PALE_GREEN = {164, 255, 164, 255}
}

function drawBackground()
  love.graphics.clear()
  
  local temp_color = COLOR.WHITE

  if game.background_color then
  	temp_color = game.background_color
  elseif game.superfreeze_time > 0 then
  	temp_color = COLOR.GRAY
  elseif p1.frozenFrames > 0 and p2.frozenFrames > 0 and frame > 90 then
    temp_color = COLOR.BLACK
  end

  love.graphics.push("all")
    love.graphics.setColor(temp_color)
    love.graphics.draw(p2.stage_background, 0, 0) 
  love.graphics.pop()
end

function drawMidline() -- draw if low on time
  if round_timer <= 180 and round_timer > 0 then
    love.graphics.push("all")
      love.graphics.setColor(100 + (180 - round_timer) / 2, 0, 0, 200)
      love.graphics.setLineWidth(12)
      love.graphics.line(stage.center, 0, stage.center, stage.height)

      love.graphics.setLineWidth(1)
      local alpha = (180 - round_timer) / 2 + 90
      local lines = {
        {shift = 2 * round_timer, color = {255, 0, 0, alpha}},
        {shift = 4 * round_timer, color = {220, 220, 0, alpha}},
        {shift = 6 * round_timer, color = {220, 220, 220, alpha}},
        {shift = 12 * round_timer, color = {255, 255, 255, alpha}}
        }

      for _, line in pairs(lines) do
        love.graphics.setColor(line.color)
        love.graphics.line(stage.center - line.shift, 0, stage.center - line.shift, stage.height)
        love.graphics.line(stage.center + line.shift, 0, stage.center + line.shift, stage.height)
      end
    love.graphics.pop()
  end
end

function drawPrebuffer()
  if prebuffer[frame] then
    love.graphics.push("all")
      for index, _ in pairs(prebuffer[frame]) do
        prebuffer[frame][index][12] = prebuffer[frame][index][12] or COLOR.WHITE
        love.graphics.setColor(prebuffer[frame][index][12]) -- 12 is RGB table
        love.graphics.draw(unpack(prebuffer[frame][index]))
      end
    love.graphics.pop()
  end
  prebuffer[frame] = nil
end

function drawPostbuffer()
  if postbuffer[frame] then
    love.graphics.push("all")
      for index, _ in pairs(postbuffer[frame]) do
        postbuffer[frame][index][12] = postbuffer[frame][index][12] or COLOR.WHITE
        love.graphics.setColor(postbuffer[frame][index][12]) -- 12 is RGB table
        love.graphics.draw(unpack(postbuffer[frame][index]))
      end
    love.graphics.pop()
  end
  postbuffer[frame] = nil
end


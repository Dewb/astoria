local Display = {}

local framerate = 24
local dirty = true
local state = {}

local tab = require "tabutil"


function Display.init(app_state)

  print("screen initialized")
  tab.print(app_state)
  screen.aa(0)
  state = app_state

  local refresh_timer = metro.init()
  refresh_timer.event = function()
    update()
    if dirty then
      dirty = false
      redraw()
    end
  end
  refresh_timer:start(1 / framerate)

end

function update()
  dirty = true
end

local buf = ""
local buf_a = ""
local buf_b = ""

function redraw()
  screen.clear()
  -- screen.blend_mode('multiply')
  -- screen.level(1)
  -- screen.rect(0,0,128,64)
  -- screen.fill()
  screen.poke(0,1,128,63,buf)
  if math.random() < 0.2 then
    screen.poke(1,1,127,62,buf)
  end
  screen.blend_mode('xor')
  screen.level(2)
  for k, dot in pairs(state.dots) do
    if dot.active then
      screen.circle((dot.x - 0.25) * 2.5 * 128, 16 + (1 - dot.y) * 48, dot.r * 10)
    end
    screen.stroke()
  end
  buf = buf_a
  buf_b = buf_a
  buf_a = screen.peek(0,0,128,63)
  
  screen.aa(1)
  screen.blend_mode('add')
  screen.level(15)
  for k, dot in pairs(state.dots) do
    if dot.active then
      screen.circle((dot.x - 0.25) * 2.5 * 128, 16 + (1 - dot.y) * 48, dot.r * 10)
    end
    screen.stroke()
  end
  screen.aa(0)


  screen.update()
end

return Display

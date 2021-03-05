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

function redraw()
  screen.clear()
  -- screen.blend_mode('multiply')
  -- screen.level(1)
  -- screen.rect(0,0,128,64)
  -- screen.fill()
  offset = 0
  shift = false
  if shift then
    for k, dot in pairs(state.dots) do
      if dot.ended == true then
        dot.ended = false
        offset = offset + 1
      end
    end
  end
  screen.poke(offset,1,128,63,buf)
  screen.blend_mode('xor')
  screen.level(math.random(2,3))
  for k, dot in pairs(state.dots) do
    if dot.active then
      screen.circle((dot.x_coarse + 0.2 * dot.x_fine - 0.25) * 2.5 * 128, 16 + (1 - dot.y) * 48, dot.r * 10)
    end
    screen.stroke()
  end
  buf = buf_a
  buf_a = screen.peek(0,0,128,63)
  
  screen.aa(1)
  screen.blend_mode('add')
  screen.level(math.random(13,15))
  for k, dot in pairs(state.dots) do
    if dot.active then
      screen.circle((dot.x_coarse + 0.2 * dot.x_fine - 0.25) * 2.5 * 128, 16 + (1 - dot.y) * 48, dot.r * 10)
    end
    screen.stroke()
  end
  screen.aa(0)


  screen.update()
end

return Display

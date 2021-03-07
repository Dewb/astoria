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
  mode = params:get("display_mode")
  if mode == 1 then 
    draw_ripples()
  elseif mode == 2 then
    draw_debug()
  end
  draw_params()
  screen.update()
end

function draw_debug()
  local active_voices = {}
  for voice, data in pairs(state.notes) do
    if data.active == true then
      table.insert(active_voices, {voice, data.onset_time})
    end
  end
  -- todo: sort by onset_time?
  h = 11
  for k, entry in pairs(active_voices) do
    voice = entry[1]
    data = state.notes[voice]
    str = voice .. "." .. 
      string.format("%02x",data.raw_note) .. ".".. 
      string.format("%02x",data.raw_x) .. "." .. 
      string.format("%02x",data.raw_y) .. "." .. 
      string.format("%02x",data.raw_z)
    screen.move(0,h)
    screen.font_face(67)
    screen.text(str)
    h = h + 8
  end
end

function draw_ripples()
  screen.aa(0)
  -- screen.blend_mode('multiply')
  -- screen.level(1)
  -- screen.rect(0,0,128,64)
  -- screen.fill()
  offset = 0
  shift = false
  if shift then
    for k, dot in pairs(state.notes) do
      if dot.ended == true then
        dot.ended = false
        offset = offset + 1
      end
    end
  end
  screen.poke(offset,1,128,63,buf)
  screen.blend_mode('xor')
  screen.line_width(1)
  screen.level(math.random(2,3))
  for k, dot in pairs(state.notes) do
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
  for k, dot in pairs(state.notes) do
    if dot.active then
      screen.circle((dot.x_coarse + 0.2 * dot.x_fine - 0.25) * 2.5 * 128, 16 + (1 - dot.y) * 48, dot.r * 10)
    end
    screen.stroke()
  end
end

function draw_params()
  screen.move(0,0)
  screen.line(41,0)
  screen.move(43,0)
  screen.line(84,0)
  screen.move(86,0)
  screen.line(127,0)
  screen.line_width(1)
  screen.level(3)
  screen.stroke()

  screen.move(0,1)
  screen.line(0 + state.params[1] * 41, 1)
  screen.move(43,1)
  screen.line(43 + state.params[2] * 41, 1)
  screen.move(86,1)
  screen.line(86 + state.params[3] * 41, 1)
  screen.line_width(2)
  screen.level(6)
  screen.stroke()

end

return Display

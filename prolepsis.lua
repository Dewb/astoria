-- Prolepsis
-- 1.0.0 @dewb
--
-- MPE wavetable synth
--
-- e1,e2,e3: change synth parameters
-- k2,k3: swap parameter pages
--
-- k2 hold +
-- e1: norns engine volume
-- e2: change synth preset
-- e3:
--
-- k3 hold +
-- e2: scroll through parameter pages
-- e3: change display mode
--

local Prolepsis = include("prolepsis/lib/prolepsis_engine")
local Display = include("prolepsis/lib/display")

local ControlSpec = require 'controlspec'
local Formatters = require 'formatters'
local MusicUtil = require "musicutil"
local tab = require "tabutil"

engine.name = "Prolepsis"

local specs = {}

specs.test1 = ControlSpec.new(0, 1, "lin", 0, 0.5, "")
specs.test2 = ControlSpec.new(0, 1, "lin", 0, 0.5, "")
specs.test3 = ControlSpec.new(0, 1, "lin", 0, 0.5, "")

local state = {}
state.dots = {}
state.params = { 0.5, 0.5, 0.5 }
for i=1,Prolepsis.voiceCount do
  state.dots[i] = { x_coarse = 0, x_fine = 0, y = 0, r = 0, raw_note = 0, raw_x = 0, raw_y = 0, raw_z = 0, raw_vel = 0, active = false }
end

local key_is_held = {0,0,0}
function key(n, z)
  key_is_held[n] = z
end

function enc(n, delta)
  local kh = table.concat(key_is_held)
  if kh == "000" then
    if n == 1 then
      params:delta("test1", delta)
    elseif n == 2 then
      params:delta("test2", delta)
    elseif n == 3 then
      params:delta("test3", delta)
    end
  elseif kh == "001" then
    if n == 3 then
      params:delta("display_mode", delta)
    end
  end
end

local function note_on(voice, note_num, vel)
  engine.noteOn(voice, note_num, MusicUtil.note_num_to_freq(note_num), vel/127)
  state.dots[voice].x_coarse = note_num/127
  state.dots[voice].y = 0
  state.dots[voice].r = vel/127
  state.dots[voice].active = true
  state.dots[voice].onset_time = util.time()
  state.dots[voice].raw_note = note_num
  state.dots[voice].raw_vel = vel  
end

local function note_off(voice, note_num, vel)
  engine.noteOff(voice, note_num, vel/127)
  state.dots[voice].active = false
  state.dots[voice].ended = true
  state.dots[voice].raw_vel = vel
end

local function modulator_z(voice, raw, scaled)
  engine.pressure(voice, scaled)
  state.dots[voice].r = scaled
  state.dots[voice].raw_z = raw
end

local function modulator_x(voice, raw, scaled)
  engine.pitchbend(voice, scaled)
  state.dots[voice].x_fine = scaled
  state.dots[voice].raw_x = raw
end

local function modulator_y(voice, raw, scaled)
  engine.timbre(voice, scaled)
  state.dots[voice].y = scaled
  state.dots[voice].raw_y = raw
end

local function midi_event(data)
  
    local channel = (data[1] & 0x0f) + 1
    
    if data[1] & 0xf0 == 0x80 then
      note_off(channel, data[2], data[3])
    
    elseif data[1] & 0xf0 == 0x90 then
      if data[3] == 0 then
        note_off(channel, data[2], data[3])
      else 
        note_on(channel, data[2], data[3])
      end

    elseif data[1] & 0xf0 == 0xd0 then
      -- msg.type == "channel_pressure" 
      modulator_z(channel, data[2], data[2] / 127)

    elseif data[1] & 0xf0 == 0xe0 then
      -- msg.type == "pitchbend" 
      val = data[2] + (data[3] << 7)
      modulator_x(channel, val, (val - 8192) / 8192)

    elseif data[1] & 0xf0 == 0xb0 then 
      -- msg.type == "cc" 
      if data[2] == 74 then
        modulator_y(channel, data[3], data[3] / 127)
      end
    end

end


function init()

  engine.loadTable(0);

  Display.init(state)

  midi_in_device = midi.connect(1)
  midi_in_device.event = midi_event

  params:add_separator("input")

  params:add{type = "number", id = "midi_device", name = "midi device", min = 1, max = 4, default = 1, action = function(value)
    midi_in_device.event = nil
    midi_in_device = midi.connect(value)
    midi_in_device.event = midi_event
  end}

  channel_mode_list = {"MPE low zone", "MPE high zone", "rotating", "omni"}
  for i = 1,16 do
    table.insert(channel_mode_list, "channel "..i)
  end
  params:add{type = "option", id = "channel_mode", name = "channel mode", default = 1, options = channel_mode_list}

  modulator_list = {"MPE pitchbend", "MPE timbre", "MPE pressure", "poly pressure", "channel pressure", "pitchbend",}
  for i = 2,120 do
    table.insert(modulator_list,"CC "..i)
  end
  params:add{type = "option", id = "mod_x", name = "mod X", options = modulator_list, default = 1}
  params:add{type = "option", id = "mod_y", name = "mod Y", options = modulator_list, default = 2}
  params:add{type = "option", id = "mod_z", name = "mod Z", options = modulator_list, default = 3}

  params:add_separator("output")

  params:add{type = "option", id = "output_internal", name = "internal synth", options = {"off", "on"}, default = 2}
  params:add{type = "option", id = "output_crow", name = "crow", options = {"off", "on"}, default = 1}
  params:add{type = "option", id = "output_jf", name = "just friends", options = {"off", "on"}, default = 1}
  params:add{type = "option", id = "output_wsyn", name = "w/syn", options = {"off", "on"}, default = 1}

  params:add_separator("sound")

  params:add{type = "control", id = "test1", name = "test 1", controlspec = specs.test1, action = function(val) state.params[1] = val end}
  params:add{type = "control", id = "test2", name = "test 2", controlspec = specs.test2, action = function(val) state.params[2] = val end}
  params:add{type = "control", id = "test3", name = "test 3", controlspec = specs.test3, action = function(val) state.params[3] = val end}

  params:add_separator("display")

  params:add{type = "option", id = "display_mode", name = "mode", options = {"ripples", "debug"}, default = 1}
  params:add{type = "option", id = "display_enc_show_values", name = "show enc values", options = {"always", "after change", "never"}, default = 1}
  params:add{type = "option", id = "display_enc_show_names", name = "show enc names", options = {"always", "after change", "never"}, default = 1}
  params:add{type = "number", id = "display_enc_show_duration", name = "time after change", min = 0.1, max = 8.0, default = 3}

end


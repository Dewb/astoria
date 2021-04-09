-- Astoria
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

local Astoria = include("astoria/lib/astoria_engine")
local Display = include("astoria/lib/display")

local ControlSpec = require 'controlspec'
local Formatters = require 'formatters'
local MusicUtil = require "musicutil"
local tab = require "tabutil"

engine.name = "Astoria"

local specs = {}

specs.test1 = ControlSpec.new(0, 1, "lin", 0, 0.5, "")
specs.test2 = ControlSpec.new(0, 1, "lin", 0, 0.5, "")
specs.test3 = ControlSpec.new(0, 1, "lin", 0, 0.5, "")

local state = {}
state.notes = {}
state.params = { 0.5, 0.5, 0.5 }


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

local function note_on(channel, note_num, vel)
  if params:get("velocity_as_pressure") == 2 then
    engine.pressure(channel, vel/127)
  end
  engine.noteOn(channel, note_num, MusicUtil.note_num_to_freq(note_num), vel/127)
  state.notes[channel].x_coarse = note_num/127
  state.notes[channel].y = 0
  state.notes[channel].r = vel/127
  state.notes[channel].active = true
  state.notes[channel].onset_time = util.time()
  state.notes[channel].raw_note = note_num
  state.notes[channel].raw_vel = vel  
end

local function note_off(channel, note_num, vel)
  engine.noteOff(channel, note_num, vel/127)
  state.notes[channel].active = false
  state.notes[channel].raw_vel = vel
end

local function modulator_z(channel, raw, scaled)
  engine.pressure(channel, scaled)
  state.notes[channel].r = scaled
  state.notes[channel].raw_z = raw
end

local function modulator_x(channel, raw, scaled)
  engine.pitchbend(channel, scaled)
  state.notes[channel].x_fine = scaled
  state.notes[channel].raw_x = raw
end

local function modulator_y(channel, raw, scaled)
  engine.timbre(channel, scaled)
  state.notes[channel].y = scaled
  state.notes[channel].raw_y = raw
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
      deadzone = params:get("pitchbend_deadzone") 
      local semitones
      if deadzone >= math.abs(0x2000 - val) then
        val = 0x2000
        semitones = 0
      elseif val < 0x2000 then 
        val = val + deadzone
        semitones = params:get("pitchbend_sensitivity") * -((0x2000 - val) / (0x2000 - deadzone))
      else
        val = val - deadzone
        semitones = params:get("pitchbend_sensitivity") * ((val - 0x2000) / (0x1FFF - deadzone))
      end
      modulator_x(channel, val, semitones)

    elseif data[1] & 0xf0 == 0xb0 then 
      -- msg.type == "cc" 
      if data[2] == 74 then
        modulator_y(channel, data[3], data[3] / 127)
      elseif data[2] == 1 then
        modulator_z(channel, data[3], data[3] / 127)
      end
    end

end

function setup_midi()
  if midi_in_device then
    midi_in_device.event = nil
  end

  for i=1,Astoria.voiceCount do
    engine.pitchbend(i, 0.0)
    engine.pressure(i, 0.0)
    engine.timbre(i, 0.0)
    state.notes[i] = { x_coarse = 0, x_fine = 0, y = 0, r = 0, raw_note = 0, raw_x = 0, raw_y = 0, raw_z = 0, raw_vel = 0, active = false }
  end

  midi_in_device = midi.connect(params:get("midi_device"))
  midi_in_device.event = midi_event

end

function init()

  --engine.loadTableFromFolder(0);
  engine.loadTableFromWaveEditFile(0, "~/dust/code/astoria/lib/wavetables/astoria/bees.wav");
  
  print("setting up params")
  setup_params()
  print("setting up midi")
  setup_midi()
  print("starting display")
  Display.init(state)

end

function setup_params()

  params:add_separator("input")

  params:add{type = "number", id = "midi_device", name = "midi device", min = 1, max = 4, default = 1, action = function(value)
    setup_midi()
  end}

  channel_mode_list = {"mpe low zone", "mpe high zone", "omni"}
  for i = 1,16 do
    table.insert(channel_mode_list, "channel "..i)
  end
  params:add{type = "option", id = "channel_mode", name = "channel mode", default = 1, options = channel_mode_list}

  modulator_list = {"off", "channel pitchbend", "channel timbre", "channel pressure", "poly pressure"}
  for i = 1,127 do
    table.insert(modulator_list,"CC "..i)
  end
  params:add{type = "option", id = "pitchbend_poly_source", name = "pitchbend", options = modulator_list, default = 1}
  params:add{type = "option", id = "timbre_poly_source", name = "timbre", options = modulator_list, default = 2}
  params:add{type = "option", id = "pressure_poly_source", name = "pressure", options = modulator_list, default = 3}
  params:add{type = "number", id = "pitchbend_sensitivity", name = "pitch bend semitones", min = 1, max = 96, default = 2}
  params:add{type = "number", id = "pitchbend_deadzone", name = "pitch bend deadzone", min = 0, max = 512, default = 0}
  params:add{type = "option", id = "velocity_as_pressure", name = "velocity is init pressure", options = {"off", "on"}, default = 1}

  params:add{type = "option", id = "pitchbend_global_source", name = "global pitchbend", options = modulator_list, default = 1}
  params:add{type = "option", id = "timbre_global_source", name = "global timbre", options = modulator_list, default = 2}
  params:add{type = "option", id = "pressure_global_source", name = "global pressure", options = modulator_list, default = 3}


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


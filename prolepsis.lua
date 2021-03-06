-- Prolepsis
-- 1.0.0 @dewb
--
-- MPE wavetable synth
--
-- E1:
-- E2:
-- E3:
-- K1:
-- K2:
-- K3:

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
  state.dots[i] = { x_coarse = 0, x_fine = 0, y = 0, r = 0, active = false }
end

function enc(n, delta)
  if n == 1 then
    params:delta("test1", delta)
  elseif n == 2 then
    params:delta("test2", delta)
  elseif n == 3 then
    params:delta("test3", delta)
  end
end

function key(n, z)
end

local function note_on(voice, note_num, vel)
  engine.noteOn(voice, note_num, MusicUtil.note_num_to_freq(note_num), vel)
  state.dots[voice].x_coarse = note_num/127
  state.dots[voice].y = 0
  state.dots[voice].r = vel
  state.dots[voice].active = true
end

local function note_off(voice, note_num, vel)
  engine.noteOff(voice, note_num, vel)
  state.dots[voice].active = false
  state.dots[voice].ended = true
end

local function modulator_z(voice, val)
  engine.pressure(voice, val)
  state.dots[voice].r = val
end

local function modulator_x(voice, val)
  engine.pitchbend(voice, val)
  state.dots[voice].x_fine = val
end

local function modulator_y(voice, val)
  engine.timbre(voice, val)
  state.dots[voice].y = val
end

local function midi_event(data)
  local msg = midi.to_msg(data)
  local voice = msg.ch - 1
       
    if msg.type == "note_off" then
      note_off(voice, msg.note, msg.vel / 127)
    
    elseif msg.type == "note_on" then
      note_on(voice, msg.note, msg.vel / 127)
      
    elseif msg.type == "channel_pressure" then
      modulator_z(voice, msg.val / 127)

    elseif msg.type == "pitchbend" then
      modulator_x(voice, (msg.val - 8192) / 8192)

    elseif msg.type == "cc" then
      if msg.cc == 74 then
        modulator_y(voice, msg.val / 127)
      end
    end

end


function init()

  engine.loadTable();

  Display.init(state)

  midi_in_device = midi.connect(1)
  midi_in_device.event = midi_event

  params:add_separator("input")

  params:add{type = "number", id = "midi_device", name = "midi device", min = 1, max = 4, default = 1, action = function(value)
    midi_in_device.event = nil
    midi_in_device = midi.connect(value)
    midi_in_device.event = midi_event
  end}

  params:add{type = "number", id = "midi_mode", name = "midi mode", min = 0, max = 17, default = 0, formatter = function(param)
    value = param:get()
    if value == 0 then 
      return "MPE low zone"
    elseif value == 17 
      then return "MPE high zone"
    else 
      return "channel "..value
    end
  end}

  modulator_list = {"MPE pitchbend", "MPE timbre", "MPE pressure", "poly pressure", "channel pressure", "pitchbend", "modwheel"}
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

  params:add{type = "option", id = "display_mode", name = "mode", options = {"circles", "wavetables"}, default = 1}
  params:add{type = "option", id = "display_enc_show_values", name = "show enc values", options = {"always", "after change", "never"}, default = 1}
  params:add{type = "option", id = "display_enc_show_names", name = "show enc names", options = {"always", "after change", "never"}, default = 1}
  params:add{type = "number", id = "display_enc_show_duration", name = "time after change", min = 0.1, max = 8.0, default = 3}

end


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

local MusicUtil = require "musicutil"
local tab = require "tabutil"

engine.name = "Prolepsis"


local state = {}
state.dots = {}
for i=1,Prolepsis.voiceCount do
  state.dots[i] = { x_coarse = 0, x_fine = 0, y = 0, r = 0, active = false }
end

function enc(n, delta)

end

function key(n, z)

end

local function note_on(chan, note_num, vel)
  engine.noteOn(chan, note_num, MusicUtil.note_num_to_freq(note_num), vel)
  state.dots[chan].x_coarse = note_num/127
  state.dots[chan].y = 0
  state.dots[chan].r = vel
  state.dots[chan].active = true
end

local function note_off(chan, note_num, vel)
  engine.noteOff(chan, note_num, vel)
  state.dots[chan].active = false
  state.dots[chan].ended = true
end

local function mpe_pressure(chan, val)
  state.dots[chan].r = val/127
end

local function mpe_pitch(chan, val)
  st = (val - 8192)/4096 -- range -2 to 2 semitones
  state.dots[chan].x_fine = st
end

local function mpe_timbre(chan, val)
  t = val/127
  engine.timbre(t)
  state.dots[chan].y = t
end

local function midi_event(data)
  local msg = midi.to_msg(data)
  local voice = msg.ch - 1
       
    if msg.type == "note_off" then
      note_off(voice, msg.note, msg.vel / 127)
    
    elseif msg.type == "note_on" then
      note_on(voice, msg.note, msg.vel / 127)
      
    elseif msg.type == "channel_pressure" then
      mpe_pressure(voice, msg.val)
    elseif msg.type == "pitchbend" then
      mpe_pitch(voice, msg.val)
    elseif msg.type == "cc" then
      if msg.cc == 74 then
        mpe_timbre(voice, msg.val)
      end
    end

end


local function grid_key(x, y, z)


end


function init()

  engine.loadTable();

  Display.init(state)

  midi_in_device = midi.connect(1)
  midi_in_device.event = midi_event

  grid_device = grid.connect(1)
  grid_device.key = grid_key

  params:add{type = "number", id = "midi_device", name = "midi device", min = 1, max = 4, default = 1, action = function(value)
    midi_in_device.event = nil
    midi_in_device = midi.connect(value)
    midi_in_device.event = midi_event
  end}


end


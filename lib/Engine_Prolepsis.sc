// CroneEngine_Prolepsis
// Wavetable synth designed for MPE
// v1.0.0 Dewb

Engine_Prolepsis : CroneEngine {

  var voiceGroup;
  var numChannels = 8;
  var channelGroups;
  var channelControlBuses;

  var wavetableBuffers;


  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    voiceGroup = ParGroup.tail(context.xg);
    channelGroups = numChannels collect: { Group.tail(voiceGroup) };
    channelControlBuses = numChannels collect: {
      #[
        timbre,
        pressure,
        pitchbend,
        release
      ].collect { |sym|
          var bus = Bus.control;
          bus.set(0);
          sym -> bus
      }.asDict
    };
        
    SynthDef("wave", {|gate, out, table_min, table_max, freq, vel, pan, timbre, pressure, pitchbend, release|

      var lagAmount = 0.001;
      var t0 = table_min+0.1;
      var t1 = table_max-0.1;
      var oscA, oscB, env, amp, signal, mix;
  
      timbre = Lag.kr(timbre, lagAmount);
      pressure = Lag.kr(pressure, lagAmount);
      pitchbend = Lag.kr(pitchbend, lagAmount);

      oscA = VOsc.ar(
        bufpos: Clip.ar(timbre, 0.0, 1.0).range(t0, t1), 
        freq: freq
      );
      // oscB = VOsc.ar(
      //   bufpos: Clip.ar(timbre, 0.0, 1.0).range(t0 + 0.2, t1 - 0.2), 
      //   freq: freq + 0.5
      // );
      env = Env.adsr(
        attackTime: vel.linexp(0, 1.0, 0.25, 0.05), 
        decayTime: vel.linexp(0, 1.0, 0.125, 0.05), 
        sustainLevel: vel.linexp(0, 1.0, 1.0, 0.7), 
        releaseTime: release
      );
      amp = EnvGen.kr(
        envelope: env, 
        gate: gate, 
        levelScale: vel.linexp(0, 1.0, 1.0, 1.3),
        doneAction: Done.freeSelf
      );
      signal = oscA; // 0.75 * oscA + 0.25 * oscB;
      mix = Pan2.ar(
        in: tanh(signal * amp.dbamp * (0.15 + 0.85 * pressure)).softclip, 
        pos: pan
      );
      Out.ar(
        bus: out, 
        channelsArray: mix
      );
    }).add;

    this.addCommand("noteOn", "iiff", { |msg|
      var channelnum = msg[1];
      var note = msg[2];
      var freq = msg[3];
      var vel = msg[4];

      // initial args for this note
      var synthArgs = [
        \gate, 1,
        \out, context.out_b,
        \table_min, wavetableBuffers.first.bufnum,
        \table_max, wavetableBuffers.last.bufnum,
        \freq, freq,
        \vel, vel,
        \pan, 0.0,
      ];
      
      var synth = Synth.new(
        "wave", 
        synthArgs, 
        target: channelGroups[channelnum]
      );

      // attach MPE channel continuous control buses
      channelControlBuses[channelnum].keysValuesDo({|key, value|
        synth.map(key, value);
			});
    });

    this.addCommand("noteOff", "iif", { |msg|
      var channelnum = msg[1];
      var note = msg[2];
      var release = msg[3];
      channelControlBuses[channelnum][\release].setSynchronous(release.linexp(0, 1.0, 7.0, 0.05));
      channelGroups[channelnum].set(\gate, 0);
    });

    this.addCommand("timbre", "if", { |msg|
      var channelnum = msg[1];
      var value = msg[2];
      channelControlBuses[channelnum][\timbre].set(value);
    });

    this.addCommand("pressure", "if", { |msg|
      var channelnum = msg[1];
      var value = msg[2];
      channelControlBuses[channelnum][\pressure].set(value);
    });

    this.addCommand("pitchbend", "if", { |msg|
      var channelnum = msg[1];
      var value = msg[2];
      channelControlBuses[channelnum][\pitchbend].set(value);
    });

    this.addCommand("loadTable", "i", { |msg|
      var tableSize = 16;
      var wavetableArrays = Array.fill(tableSize, {arg i; 
        var inst = "hvoice";
        var root = this.class.filenameSymbol.asString.dirname ++ "/wavetables";
        var wavePath = (root ++ "/AKWF_" ++ inst ++ "/AKWF_" ++ inst ++ "_" ++ ((i+1).asStringToBase(10, 4)) ++ ".wav").standardizePath;
        var f = SoundFile.openRead(wavePath);
        if (f.notNil) {
          var a = FloatArray.newClear(f.numFrames);
          f.readData(a);
          f.close;
          a = a.resamp1(1024);
          a = a.as(Signal).asWavetable();
          "Loaded wave %".format(wavePath).postln;
          a;
        } {
          "Failed to open %".format(wavePath).warn;
          nil;
        }
      });

      wavetableBuffers = Buffer.allocConsecutive(tableSize, context.server, 2048, 1, { |buf, i|
        buf.sendCollection(wavetableArrays[i], 0, 0, { |buf|
          buf.query.postln;
          wavetableArrays[i].free;
        });
      });

      "loaded tables".postln;
    });

  }

  free {
    voiceGroup.free;
    wavetableBuffers.do(_.free);
    channelGroups.do(_.free);
    channelControlBuses.do({|dict| dict do: _.free });
  }
}

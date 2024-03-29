// CroneEngine_Astoria
// Wavetable synth designed for MPE
// v1.0.0 Dewb

Engine_Astoria : CroneEngine {

  var numVoices = 30;
  var voiceGroup;
  var voiceList;
  var channelControlBuses;
  var mixerBus;

  var wavetableBuffers;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    voiceGroup = ParGroup.tail(context.xg);
    voiceList = Array.fill(numVoices, {|i| nil});
    channelControlBuses = 16 collect: {
      #[
        timbre,
        pressure,
        pitchbend,
      ].collect { |sym|
          var bus = Bus.control;
          bus.set(0);
          sym -> bus
      }.asDict
    };
    mixerBus = Bus.audio(context.server, 2);
        
    SynthDef("wave", {|gate, out, table_min, table_max, freq, vel, pan, timbre, pressure, pitchbend, release|
      var lagAmount = 0.001;
      var t0 = table_min+0.1;
      var t1 = table_max-0.1;
      var oscA, oscB, ring, noise, env, amp, signal, mix;
  
      timbre = Lag.kr(timbre, lagAmount);
      pressure = Lag.kr(pressure, lagAmount);
      freq = Lag.kr(freq * (1 + pitchbend), lagAmount);

      oscA = VOsc.ar(
        bufpos: Clip.ar(timbre, 0.0, 1.0).range(t0, t1), 
        freq: freq
      );
      // oscB = VOsc.ar(
      //   bufpos: Clip.ar(timbre, 0.0, 1.0).range(t0 + 0.2, t1 - 0.2), 
      //   freq: freq + 0.5
      // );
      // ring = oscA * oscB;
      // noise = PinkNoise.ar();
      env = Env.adsr(
        attackTime: vel.linexp(0, 1.0, 0.25, 0.08), 
        decayTime: vel.linexp(0, 1.0, 0.125, 0.08), 
        sustainLevel: vel.linexp(0, 1.0, 1.0, 0.7), 
        releaseTime: release
      );
      amp = EnvGen.ar(
        envelope: env, 
        gate: gate, 
        levelScale: vel.linexp(0, 1.0, 0.7, 1.0),
        doneAction: Done.freeSelf
      );
      signal = 0.5 * oscA; // + 0.5 * oscB;
      mix = Pan2.ar(
        in: tanh(signal * amp * (0.15 + 0.85 * pressure)).softclip, 
        pos: pan
      );
      Out.ar(
        bus: out, 
        channelsArray: mix
      );
    }).add;

    SynthDef("mixer", {
			arg in, out, amp = 0.5;
			var signal;

			signal = In.ar(in, 2) * 0.4 * amp;
			signal = tanh(signal).softclip;

			Out.ar(bus: out, channelsArray: signal);

		}).play(target:context.xg, args: [\in, mixerBus, \out, context.out_b], addAction: \addToTail);

    this.addCommand("noteOn", "iiff", { |msg|
      var channelnum = msg[1];
      var note = msg[2];
      var freq = msg[3];
      var vel = msg[4];

      // initial args for this note
      var synthArgs = [
        \gate, 1,
        \out, mixerBus,
        \table_min, wavetableBuffers.first.bufnum,
        \table_max, wavetableBuffers.last.bufnum,
        \freq, freq,
        \vel, vel,
        \pan, 0.0,
      ];
      
      var synth = Synth.new(
        "wave", 
        synthArgs, 
        target: voiceGroup
      ).onFree({ 
        voiceList.remove(synth); 
      });

      if(voiceList[channelnum].notNil, {
        voiceList[channelnum].set(\gate, 0);
        voiceList[channelnum] = nil;
      });

      voiceList[channelnum] = synth;

      // attach MPE channel continuous control buses
      channelControlBuses[channelnum].keysValuesDo({|key, value|
        synth.map(key, value);
			});
    });

    this.addCommand("noteOff", "iif", { |msg|
      var channelnum = msg[1];
      var note = msg[2];
      var release = msg[3];
      var synth = voiceList[channelnum];
      if(synth.notNil, {
        synth.set(\release, release.linexp(0, 1.0, 7.0, 0.05));
        channelControlBuses[channelnum].keysValuesDo({|key, bus|
          synth.set(key, bus.getSynchronous()) // detach the bus, but keep the value
			  });
        synth.set(\gate, 0);
        voiceList[channelnum] = nil;
      });
    });

    this.addCommand("noteOffAll", "", { |msg|
			voiceGroup.set(\gate, 0);
			voiceList.do({|v| v.gate = 0; });
		});

    this.addCommand("timbre", "if", { |msg|
      var channelnum = msg[1];
      var value = msg[2];
      channelControlBuses[channelnum][\timbre].set(value);
    });

    this.addCommand("timbreAll", "f", { |msg|
      var value = msg[1];
      channelControlBuses.do({|b| b[\timbre].set(value); });
    });

    this.addCommand("pressure", "if", { |msg|
      var channelnum = msg[1];
      var value = msg[2];
      channelControlBuses[channelnum][\pressure].set(value);
    });

    this.addCommand("pressureAll", "f", { |msg|
      var value = msg[1];
      channelControlBuses.do({|b| b[\pressure].set(value); });
    });

    this.addCommand("pitchbend", "if", { |msg|
      var channelnum = msg[1];
      var value = msg[2];
      channelControlBuses[channelnum][\pitchbend].set(2 ** (value/12));
    });

    this.addCommand("pitchbendAll", "f", { |msg|
      var value = msg[1];
      channelControlBuses.do({|b| b[\pitchbend].set(2 ** (value/12)); });
    });

    this.addCommand("loadTableFromFolder", "i", { |msg|
      var tableSize = 24;
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

    this.addCommand("loadTableFromWaveEditFile", "is", { |msg|
      var tableSize = 64;
      var waveFrames = 256;
      var wavePath = msg[2].asString.standardizePath;
      //var inst = "bees";
      //var root = this.class.filenameSymbol.asString.dirname ++ "/wavetables";
      //var wavePath = (root ++ "/astoria/" ++ inst ++ ".wav").standardizePath;
      var f = SoundFile.openRead(wavePath);
      if (f.notNil) {
        var wavetableArrays = Array.fill(tableSize, {arg i; 
            var a = FloatArray.newClear(waveFrames);
            f.readData(a);
            //a = a.resamp1(256); // should already be 256 samples
            a = a.as(Signal).asWavetable(); // this doubles the size
            a;
        });
        "Loaded wave %".format(wavePath).postln;
        f.close;
        wavetableBuffers = Buffer.allocConsecutive(tableSize, context.server, waveFrames * 2, 1, { |buf, i|
          buf.sendCollection(wavetableArrays[i], 0, 0, { |buf|
            buf.query.postln;
            wavetableArrays[i].free;
          });
        });
        "loaded tables".postln;

      } {
        "Failed to open %".format(wavePath).warn;
        nil;
      }
    });

  }

  free {
    voiceGroup.free;
    wavetableBuffers.do(_.free);
    channelControlBuses.do({|dict| dict do: _.free });
  }
}

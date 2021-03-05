// CroneEngine_Prolepsis
// Wavetable synth designed for MPE
// v1.0.0 Dewb

Engine_Prolepsis : CroneEngine {

  var voiceGroup;
  var numChannels = 8;
  var channelGroups;
  var channelControlBusses;

  var wavetableArrays; // todo: eliminate this
  var wavetableBuffers;


  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    voiceGroup = ParGroup.tail(context.xg);
    channelGroups = numChannels collect: { Group.tail(voiceGroup) };
    channelControlBusses = numChannels collect: {
      #[
        timbre,
        pressure,
        pitchbend
      ].collect { |sym|
          var bus = Bus.control;
          bus.set(0);
          sym -> bus
      }.asDict
    };
        
    SynthDef("wave", {|gate, out, table_min, table_max, freq, vel, pan, timbre, pressure, pitchbend|
      var t0 = table_min+0.1;
      var t1 = table_max-0.1;
      var snd = VOsc.ar(Wrap.ar(timbre, 0.0, 1.0).range(t0, t1), freq);
      var env = Env.perc(level: 1.0, releaseTime: vel).kr(2);
      Out.ar(out, Pan2.ar((snd * env), 0.0));
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
      ];
      
      var s = Synth.new(
        "wave", 
        synthArgs, 
        target: channelGroups[channelnum]
      );

      s.map(\timbre, channelControlBusses[channelnum][\timbre]);
    });

    this.addCommand("noteOff", "iif", { |msg|
      var channelnum = msg[1];
      var note = msg[2];
      var releasevel = msg[3];
      channelGroups[channelnum].set(\gate, 0);
    });

    this.addCommand("timbre", "if", { |msg|
      var channelnum = msg[1];
      var value = msg[2];
      channelControlBusses[channelnum][\timbre].set(value);
    });

    this.addCommand("pressure", "if", { |msg|
      var channelnum = msg[1];
      var value = msg[2];
      channelControlBusses[channelnum][\pressure].set(value);
    });

    this.addCommand("pitchbend", "if", { |msg|
      var channelnum = msg[1];
      var value = msg[2];
      channelControlBusses[channelnum][\pitchbend].set(value);
    });

    this.addCommand("loadTable", "i", {arg msg;
      var tableSize = 12;
      wavetableArrays = Array.fill(tableSize, {arg i; 
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
        });
      });

      "loaded tables".postln;
    });

  }

  free {
    voiceGroup.free;
    wavetableArrays.do(_.free);
    wavetableBuffers.do(_.free);
    channelGroups.do(_.free);
    channelControlBusses.do({|dict| dict do: _.free });
  }
}

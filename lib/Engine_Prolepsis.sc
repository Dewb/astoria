// CroneEngine_Prolepsis
// Wavetable synth designed for MPE
// v1.0.0 Dewb

Engine_Prolepsis : CroneEngine {

  var pg;
  var wavetable_arrays;
  var wavetable_buffers;
  var amp=0.3;
  var release=0.5;
  var pan=0;
  var timbre=0;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    pg = ParGroup.tail(context.xg);
        
    SynthDef("wave", {
      arg out, table, table_min, table_max, freq = 440, amp=amp, release=release, pan=pan;
      //var snd = VOsc.ar(SinOsc.kr(0.125,0).range(table_min+0.1,table_max-0.1), freq);
      var snd = VOsc.ar(table, freq);
      var env = Env.perc(level: amp, releaseTime: release).kr(2);
      Out.ar(out, Pan2.ar((snd * env), pan));
    }).add;

    this.addCommand("noteOn", "iiff", { arg msg;
      var freq = msg[3];
      var vel = msg[4];
      Synth("wave", [
          \out, context.out_b, 
          \table_min, wavetable_buffers.first.bufnum, 
          \table_max, wavetable_buffers.last.bufnum,
          \table, (wavetable_buffers.last.bufnum - wavetable_buffers.first.bufnum) * timbre,
          \freq, freq,
          \amp, amp, \release, vel, \pan, pan
        ], 
        target:pg
      );
    });

    this.addCommand("noteOff", "iif", { arg msg;
    });

    this.addCommand("amp", "f", { arg msg;
      amp = msg[1];
    });
    this.addCommand("release", "f", { arg msg;
      release = msg[1];
    });
    this.addCommand("pan", "f", { arg msg;
      pan = msg[1];
    });
    this.addCommand("timbre", "f", { arg msg;
      timbre = msg[1];
    });


    this.addCommand("loadTable", "i", {arg msg;
    
      wavetable_arrays = Array.fill(14, {arg i; 
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

      wavetable_buffers = Buffer.allocConsecutive(14, context.server, 2048, 1, { |buf, i|
        buf.sendCollection(wavetable_arrays[i], 0, 0, { |buf|
          buf.query.postln;
        });
      });

      "loaded tables".postln;
    });

  }

  free {
    pg.free;
    wavetable_buffers.do(_.free);
  }
}

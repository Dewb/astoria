prolepsis
=========

wavetable synth engine for the [monome norns](https://monome.org/norns/) with [MIDI Polyphonic Expression](https://d30pueezughrda.cloudfront.net/campaigns/mpe/mpespec.pdf) control capability
march 2021

## WARNINGS:
* ~ *work in progress* ~
* first supercollider project, expect nonsense
* name not final

### todo

* hook up pitchbend
* implement rest of synth architecture (2x wavetable osc, sub osc, 2x filter + chorus per voice)
* implement synth parameters and mod matrix, expose to norns knobs/params
* load new wavetables from params menu
* make everything work with non-MPE voice allocation
* move MPE logic out of main script into a lua library
* crow

### project core goals
* an expressively playable self-contained polysynth 
   * with heavy inspiration from the [MWII/XT/XTk](https://www.waldorfmusic.com/phocadownload/Microwave%202%20Downloads/Documentation/mw2_XT_XTk_eng.pdf) architecture
   * supporting [MPE](https://d30pueezughrda.cloudfront.net/campaigns/mpe/mpespec.pdf) and non-MPE capable MIDI controllers
      * test hardware includes the [Sensel Morph](https://morph.sensel.com), [ExpressiveE Touché](https://www.expressivee.com/1-touche), and [Arturia Keystep Pro](https://www.arturia.com/products/hybrid-synths/keystep-pro/overview)
* with flexible wavetable sourcing
   * a small curated set of algorithmically generated and file-based wavetables based on my personal sensibilities
   * also allow users to self-install arbitrary single-cycle wavetable collections
* MPE > CV via [crow]()

### project probable eventual goals
* drive synthesis modes of [Just Friends](https://www.whimsicalraps.com/products/just-friends) and [W/Syn](https://llllllll.co/t/mannequins-w-2-beta-testing/34091) via crow i2c
* arc parameter control, LFOs
* will think of some grid sequencing capabilities eventually

### references/thanks
* wavetables
   * [Adventure Kid Waveform Pack](https://github.com/KristofferKarlAxelEkstrand/AKWF-FREE) (CC0)
* videos
    * Eli Fieldsteel's SuperCollider Tutorials [23: Wavetable Synthesis, Part I](https://youtu.be/8EK9sq_9gFI) and [24: Wavetable Synthesis, Part II](https://www.youtube.com/watch?v=7nrUBbmY1hE)
* norns engines studied as reference
   * [Molly the Polly](https://llllllll.co/t/molly-the-poly/21090) from @markwheeler 
   * [ack](https://github.com/antonhornquist/ack) from @antonhornquist
   * [PolyPerc](https://github.com/monome/norns/blob/8047a363a28759cd4fa2c94f3c7e4b78f01eec88/crone/classes/engines/CroneEngine_PolyPerc.sc) from @tehn
* threads/gists/examples
   * https://llllllll.co/t/norns-mpe/17320
   * https://llllllll.co/t/norns-crone-supercollider/14616/120
   * https://gist.github.com/xavriley/ce1becd7f2d97d93aced74e88ae7ba54
   * https://github.com/vagost/HybFMSynth/blob/master/PolySynths.sc
   * https://github.com/baruchtomer/MegazordSynth/blob/master/megazord-synth.scd


### license

[GPLv3](LICENSE.txt)
astoria
=========

wavetable synth engine for the [monome norns](https://monome.org/norns/) with [MIDI Polyphonic Expression](https://d30pueezughrda.cloudfront.net/campaigns/mpe/mpespec.pdf) control capability

march 2021<br>
Medford, MA, USA

## WARNINGS:

* ~ *work in progress* ~
* first supercollider project, expect nonsense
* name not final

## todo

* ~~change name~~
* ~~fix danging synth voices~~
* ~~hook up pitchbend~~
* ~~support WaveEdit wavetables ~~
* ~~support AKWF wavetables ~~
* support Serum wavetables (mostly done?)
* load wavetables from params menu / file browser/importer (may need to specify format)
* implement initial mvp synth architecture and basic controlspecs/params (osc, filter, chorus)
* make everything also work with regular MIDI controllers with non-MPE voice allocation
* move MPE logic out of main script into a lua library
* prepare preview release
* implement rest of synth architecture (2x wavetable osc, sub osc, 2x filter + chorus per voice)
* implement full synth parameters and mod matrix, expose to norns knobs/params
* implement anti-aliasing
* fix dropped note offs with sensel morph (probably requires norns core changes, 5 touch bottleneck at 1000 Hz)
* crow outputs

## project core goals

* an expressively playable self-contained polysynth 
   * supporting both [MPE](https://d30pueezughrda.cloudfront.net/campaigns/mpe/mpespec.pdf) and non-MPE MIDI controllers
* a simple but rich wavetable synthesis engine
   * sound and parameterization inspired by the architecture of classic wavetable hardware synthesizers from the 1990s
   * a modest built-in set of algorithmically generated and file-based wavetables 
   * plus, allow users to self-install their own single-cycle wavetable collections
* convert MPE expression to control voltage via [crow]()

## project probable eventual goals

* drive synthesis modes of [Just Friends](https://www.whimsicalraps.com/products/just-friends) and [W/Syn](https://llllllll.co/t/mannequins-w-2-beta-testing/34091) via crow i2c
* arc parameter control, LFOs
* will think of some grid sequencing capabilities eventually
* contribute MPE implementation to other polysynths

## references/thanks

* wavetables
   * [Adventure Kid Waveform Pack](https://github.com/KristofferKarlAxelEkstrand/AKWF-FREE) (CC0)
* videos
    * Eli Fieldsteel's SuperCollider Tutorials [23: Wavetable Synthesis, Part I](https://youtu.be/8EK9sq_9gFI) and [24: Wavetable Synthesis, Part II](https://www.youtube.com/watch?v=7nrUBbmY1hE)
* norns engines studied 
   * [Molly the Polly](https://llllllll.co/t/molly-the-poly/21090) from @markwheeler 
   * [ack](https://github.com/antonhornquist/ack) from @antonhornquist
   * [PolyPerc](https://github.com/monome/norns/blob/8047a363a28759cd4fa2c94f3c7e4b78f01eec88/crone/classes/engines/CroneEngine_PolyPerc.sc) from @tehn
* threads/gists/examples
   * https://llllllll.co/t/norns-mpe/17320
   * https://llllllll.co/t/norns-crone-supercollider/14616/120
   * https://gist.github.com/xavriley/ce1becd7f2d97d93aced74e88ae7ba54
   * https://github.com/vagost/HybFMSynth/blob/master/PolySynths.sc
   * https://github.com/baruchtomer/MegazordSynth/blob/master/megazord-synth.scd
   * https://gist.github.com/catfact/ac108ff6f08306bad4f81c376572b8b3
* conversations on the norns study group discord

## q&a

Q. *Where did the name come from*?<br/>
A. The [houseboat](https://en.wikipedia.org/wiki/Astoria_(recording_studio)), or the [muppet](https://muppet.fandom.com/wiki/Astoria).

Q. *what/why is the norns sound computer?*<br/>
A. [Some good non-exhaustive answers here](https://github.com/p3r7/awesome-monome-norns#what--why-is-norns).

Q. *what hardware has this been tested with?*<br/>
A. planned support matrix so far looks like:
   * norns
      * norns retail (stock Pi CM3)
      * norns retail (Pi CM3+ upgrade) [TODO]
      * norns DIY shield with Pi 3B+ [TODO]
   * controllers:
      * [Sensel Morph](https://morph.sensel.com)
      * [Keith McMillen QuNexus](https://www.keithmcmillen.com/products/qunexus/) [TODO]
      * [ExpressiveE Touché](https://www.expressivee.com/1-touche) [TODO]
      * [Arturia Keystep Pro](https://www.arturia.com/products/hybrid-synths/keystep-pro/overview) [TODO]
      * [Nord Electro 2](https://www.nordkeyboards.com/products/nord-electro-2) [TODO]

## license

[GPLv3](LICENSE.txt)

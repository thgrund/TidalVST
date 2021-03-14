

# TidalVST

Using Supercolliders VSTPluginController to control VST plugins with TidalCycles.

This can currently be understood as a proof of concept. It certainly cannot do everything that one would like to have in terms of features. What you can do, however, is to: 

- Use the VSTPluginController to make a VST plugin accesible for TidalCycles
- Control VST parameters with TidalCycles pattern. You can use simple functions or even control busses!
-  Apply global effects from SuperDirt 

## Requirements

- TidalCycles v1.7.1+
- [SuperDirt](https://github.com/musikinformatik/SuperDirt) v1.7.1+
- [VSTPlugin](https://github.com/Spacechild1/vstplugin) 0.4.0+

## TidalCycles

### Installation

Create a new control bus target in your `BootTidal.hs`:

```Haskell
let vstTarget = Target {oName = "hydra", oAddress = "127.0.0.1", oHandshake = True, oPort = 3337, oBusPort = Just 3338, oLatency = 0.1, oSchedule = Pre BundleStamp, oWindow = Nothing}

tidal <- startStream (defaultConfig {cFrameTimespan = 1/20}) [(superdirtTarget {oLatency = 0.1}, [superdirtShape]),(vstTarget, [superdirtShape]) ]
```

And you need to add the content from  `newFunction.hs` in this repo to your `BootTidal.hs` too.

## How to use it

One simple approach is to play notes withouth controlling any other parameter:

```haskell
d1 $ n (scale "major" "0 5 ~7") # vst "zebralette" -- this is the name of your vst plugin
```

 But you can use the functions `varg1` .. `varg100` from `newFunction.hs`. The parameter mapping depends on the plugin. I prefer to create a more semantically meaning for a specific vst plugin parameter like `oscrate = varg23`. 

```haskell
d1 $ n (scale "major" "0 5 ~7")
   # vst "zebralette"
   # varg34 (
      "[0.25 <0.5 0.75> <0.75 0>]"
   )
```

You can control  the vst parameter with control busses too! Like the functions you can access the control busses with `varg1bus` .. `varg100bus`.

```haskell
d1 $ n "0/2"
   # vst "zebralette"
   # varg34bus 1 (
      segment "<4 256>"
      $ ( isaw * "<0.25 0.25 0.5>") + 0.25
   ) # legato 2
```

And you can add global effects from SuperDirt 

```haskell
d1 $ n (scale "major" "0 5 ~7")
   # vst "zebralette"
   # room 0.2 # sz 0.4
   # delay 1
   # delaytime 0.2 # delayfeedback 0.2
   # leslie 1
   # lsize 2.8 # lrate 6.7
   # legato 0.1
```

## SuperCollider

For adding or removing a VST plugins you need to do the following changes in `TidalVST.scd`:

1. Add something like `VSTPlugin.ar(sound, ~dirt.numChannels, id: \myVstId);` to the "VST" SynthDef
2. Add `\myVstId -> Synth("VST", [id: \myVstId, outBus: 76, dryBus: 78]),`to the synths Dictionary
3. Add `\myVstId -> VSTPluginController(synths.at(\zebralette2), id: \zebralette2).open("Zebralette", editor: true, verbose: false),`to the instruments Dictionary.

I think not every parameter should be necessary and it should be clean up soon. But to be unsure everything is working you should do it this way.

The `VSTPluginController` should looks into your VST and VST3 folder for the file names. These names should be the same for the `open` method. 

## Known issues

- You will receive an error message that the vst instrument is unknown. In fact I do not fully understand how the effect busses and diversion in SuperDirt are working. You can delete the every occurence of `diversions[~vstName].value;`. Then you will no longer have the error message but the downside of it is that you can not use the global effects anymore.
- You can not use local effects from SuperDirt yet.
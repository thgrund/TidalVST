SynthDef("vst_instrument", { |out, dryBus, pan = 0, n = 0, id, sustain = 1, gate, attack = 0, hold = 0, release = inf, bypass = 0 |
	var sound, sound2, in, env;
	//env = EnvGen.ar(Env.linen(attack, hold, release, 1, curve: -3), doneAction: 0);
	//env = EnvGen.ar(Env.asr(0.1, 1, 0.1, -3), timeScale:sustain, gate: 1, doneAction:2);
	//var env = EnvGen.ar(Env.asr(0.1, 1, 0.1), timeScale: sustain, gate: 1, doneAction:2);
	// env = EnvGen.kr(Env.linen(0.002, 0.996, 0.002, 1,-3), timeScale:1, doneAction:0);
	// These are vst instruments
	//sound = In.ar(out, ~dirt.numChannels);
	sound = VSTPlugin.ar(nil, numOut: 2, id: id, bypass: bypass);
	//sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \zebralette2);
	// Here you could define more instruments
	Out.ar(out, DirtPan.ar(sound, 2, pan) );
}).add;

/*SynthDef("vst_moderndrum", { |id, kickOut, cymbalOut, snareOut, tomOut, kickPan, cymbalPan, snarePan, tomPan, bypass = 0|
	//var sig = VSTPlugin.ar(nil, numOut: `[10,14]);
	var pluginBus = VSTPlugin.ar(nil, numOut: 18, id: id, bypass: bypass);
	var kickSound = Select.ar(10, pluginBus);
	var cymbalSound1 = Select.ar(16, pluginBus);
	var cymbalSound2 = Select.ar(17, pluginBus);
	var snareSound1 = Select.ar(12, pluginBus);
	var snareSound2 = Select.ar(13, pluginBus);
	var tomSound1 = Select.ar(14, pluginBus);
	var tomSound2 = Select.ar(15, pluginBus);

	Out.ar(kickOut, DirtPan.ar(kickSound, 2, kickPan));
	Out.ar(cymbalOut, DirtPan.ar([cymbalSound1, cymbalSound2], 2, cymbalPan));
	Out.ar(snareOut, DirtPan.ar([snareSound1, snareSound2], 2, snarePan));
	Out.ar(tomOut, DirtPan.ar([tomSound1, tomSound2], 2, tomPan));
}).add;*/

SynthDef("vst_moderndrum", { |id, kickOut, kickMonitor = 36, cymbalOut, cymbalMonitor = 36, snareOut,snareMonitor = 36, tomOut, tomMonitor = 36, kickPan, cymbalPan, snarePan, tomPan, bypass = 0|
	//var sig = VSTPlugin.ar(nil, numOut: `[10,14]);
	var pluginBus = VSTPlugin.ar(nil, numOut: 18, id: id, bypass: bypass);
	var kickSound = Select.ar(10, pluginBus);
	var cymbalSound1 = Select.ar(16, pluginBus);
	var cymbalSound2 = Select.ar(17, pluginBus);
	var snareSound1 = Select.ar(12, pluginBus);
	var snareSound2 = Select.ar(13, pluginBus);
	var tomSound1 = Select.ar(14, pluginBus);
	var tomSound2 = Select.ar(15, pluginBus);

	Out.ar(kickOut, DirtPan.ar(kickSound, 2, kickPan));
	Out.ar(kickMonitor, DirtPan.ar(kickSound, 2, kickPan));
	Out.ar(cymbalOut, DirtPan.ar([cymbalSound1, cymbalSound2], 2, cymbalPan));
	Out.ar(cymbalMonitor, DirtPan.ar([cymbalSound1, cymbalSound2], 2, cymbalPan));
	Out.ar(snareOut, DirtPan.ar([snareSound1, snareSound2], 2, snarePan));
	Out.ar(snareMonitor, DirtPan.ar([snareSound1, snareSound2], 2, snarePan));
	Out.ar(tomOut, DirtPan.ar([tomSound1, tomSound2], 2, tomPan));
	Out.ar(tomMonitor, DirtPan.ar([tomSound1, tomSound2], 2, tomPan));
}).add;


/*
SynthDef("vst_moderndrum", { |out, dryBus, pan = 0, id|
	var sound = VSTPlugin.ar(nil, numOut: `[2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2], id: id);

	Out.ar(out, sound.flat);
}).add;
*/

/*
SynthDef("vst_effect", { |dryBus, id, wildcard = 1,  wet = 1, gate = 1 |
		var sound;
		var in = In.ar(dryBus, numChannels);
		// Dry/Wet
	    // TODO: disable if no value was received
	    sound = VSTPlugin.ar(in, ~dirt.numChannels, id: id);

		sound = sound * EnvGen.kr(Env.asr, gate, doneAction:2);
		DirtPause.ar(sound, graceTime:4);

		ReplaceOut.ar(dryBus, (in * (1 - wet)) + (sound * wet ));

}, [\ir]).add;*/


/*SynthDef("vst", {|out, sustain=1, pan, accelerate, freq, detune=0.2, speed=1, id|
		var env = EnvGen.ar(Env.adsr(1, 1.399, 0.7, 0.003, 1,-3), timeScale:sustain, doneAction:2);
		var sound = In.ar(out, ~dirt.numChannels);
	    sound = VSTPlugin.ar(sound, numOut: 2, id: id);

		Out.ar(out, DirtPan.ar(sound * env, ~dirt.numChannels, pan, env))
	}).add*/
(
SynthDef("dexed", { |out, pan = 0, n = 0, id = \dexed1|
	var sound;

	var env = EnvGen.kr(Env.asr(0.1, 1, 0.1), gate: 1, doneAction:2);
    // env = EnvGen.kr(Env.linen(0.002, 0.996, 0.002, 1,-3), timeScale:1, doneAction:0);
	sound = In.ar(out, ~dirt.numChannels) * env;

	// These are vst instruments
	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: id);

	//sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \zebralette2);
	// Here you could define more instruments
	Out.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan)
	)
}).add;

)

(
var diversions = ();
var vstControlBus = ();
var vstControlBusses = ();
var synths = Dictionary [
	\dexed1 -> Synth("dexed", [id: \dexed1]),
	\dexed2 -> Synth("dexed", [id: \dexed2]),
	\dexed3 -> Synth("dexed", [id: \dexed3]),
	\dexed4 -> Synth("dexed", [id: \dexed4]),
	\dexed5 -> Synth("dexed", [id: \dexed5]),
	\dexed6 -> Synth("dexed", [id: \dexed6]),
	\dexed7 -> Synth("dexed", [id: \dexed7]),
];
var instrument;
var instrumentSynths= ();
var instruments = Dictionary[
	\dexed1 -> VSTPluginController(synths.at(\dexed1)),
	\dexed2 -> VSTPluginController(synths.at(\dexed2)),
	\dexed3 -> VSTPluginController(synths.at(\dexed3)),
	\dexed4 -> VSTPluginController(synths.at(\dexed4)),
	\dexed5 -> VSTPluginController(synths.at(\dexed5)),
	\dexed6 -> VSTPluginController(synths.at(\dexed6)),
	\dexed7 -> VSTPluginController(synths.at(\dexed7)),
];
/*var instruments = ~instruments;
var synths = ~synths;*/

var triggerFunc = { |vstName|
	var lag = ~lag + (~latency ? 0);
	var latency = lag; // for now
	var sustain = ~sustain = ~sustain.value;
	var freq = ~freq.value;
	var note = (~freq.cpsmidi).round(1).asInteger;
	//var velocity = (~amp.value* pow(~gain.min(2) + ~overgain, 4)).linlin(0,1,0,127).asInteger;
	var velocity = ~gain.linlin(0,1,0,127).asInteger;

	~gain = ~gain * 1.4;

			synths.at(vstName).set(
				\out, ~out,
				\pan, currentEnvironment.at(\pan),
			);

	thisThread.clock.sched(latency, {
		instruments[vstName].midi.noteOn(0, note, velocity);
	});

	thisThread.clock.sched(sustain + latency, {
	    instruments[vstName].midi.noteOff(0, note, velocity);
	});
};

var serverMessage = { |synth|
	//var args =[\out, ~out, \sustain, ~sustain, \pan, ~pan, \freq, ~freq, \speed, ~speed, synth];
	var	args = SynthDescLib.global.at(synth.asSymbol).msgFunc.valueEnvir;

	args.asControlInput.flop.do { |each|
		~dirt.server.sendMsg(\s_new,
			synth,
			-1, // no id
			1, // add action: addToTail
			~synthGroup, // send to group
			*each.asOSCArgArray // append all other args
		)
	}
};

~dirt.soundLibrary.addSynth(\key,(playInside: { |e|triggerFunc.value(\dexed1);}));
~dirt.soundLibrary.addSynth(\pad,(playInside: { |e|triggerFunc.value(\dexed2);}));
~dirt.soundLibrary.addSynth(\lead,(playInside: { |e|triggerFunc.value(\dexed3);}));
~dirt.soundLibrary.addSynth(\bass,(playInside: { |e|triggerFunc.value(\dexed4);}));
~dirt.soundLibrary.addSynth(\fx,(playInside: { |e|triggerFunc.value(\dexed5);}));
~dirt.soundLibrary.addSynth(\string,(playInside: { |e|triggerFunc.value(\dexed6);}));
~dirt.soundLibrary.addSynth(\melody,(playInside: { |e|triggerFunc.value(\dexed7);}));



/*
~dirt.soundLibrary.addSynth(\dexed1,
	(playInside: { |e|
	//serverMessage.value("dexed");
	triggerFunc.value(\dexed1);
  })
);*/

~instruments = instruments;
instruments.at(\dexed1).open("Dexed.vst3");
instruments.at(\dexed2).open("Dexed.vst3");
instruments.at(\dexed3).open("Dexed.vst3");
instruments.at(\dexed4).open("Dexed.vst3");
instruments.at(\dexed5).open("Dexed.vst3");
instruments.at(\dexed6).open("Dexed.vst3");
instruments.at(\dexed7).open("Dexed.vst3");


)

(
// key
~instruments.at(\dexed1).readProgram(thisProcess.nowExecutingPath.dirname +/+ "Dexed/epiano.vstpreset");
// pad
~instruments.at(\dexed2).readProgram(thisProcess.nowExecutingPath.dirname +/+ "Dexed/prophet.vstpreset");

~instruments.at(\dexed3).readProgram(thisProcess.nowExecutingPath.dirname +/+ "Dexed/eharp.vstpreset");

~instruments.at(\dexed4).readProgram(thisProcess.nowExecutingPath.dirname +/+ "Dexed/fretless.vstpreset");

~instruments.at(\dexed5).readProgram(thisProcess.nowExecutingPath.dirname +/+ "Dexed/shimmer.vstpreset");

~instruments.at(\dexed6).readProgram(thisProcess.nowExecutingPath.dirname +/+ "Dexed/string.vstpreset");

~instruments.at(\dexed7).readProgram(thisProcess.nowExecutingPath.dirname +/+ "Dexed/marimba.vstpreset");

)

~instruments.at(\dexed7).writeProgram(thisProcess.nowExecutingPath.dirname +/+ "Dexed/marimba.vstpreset");


~instruments.at(\dexed3).editor;


~dirt.orbits[0].synthBus
~dirt.orbits[0].synthBus.index

~dirt.orbits[0].set(\fadeTime, 0.02);
~dirt.orbits[1].set(\fadeTime, 0.01);
~dirt.orbits[2].set(\fadeTime, 0.01);
~dirt.orbits[3].set(\fadeTime, 0.01);
~dirt.orbits[4].set(\fadeTime, 0.01);
~dirt.orbits[5].set(\fadeTime, 0.01);
~dirt.orbits[6].set(\fadeTime, 0.01);

~instruments.at(\dexed7).editor


~dirt.orbits[0].set(\fadeInTime, 0.4);


~dirt.orbits[0].get(\fadeTime)
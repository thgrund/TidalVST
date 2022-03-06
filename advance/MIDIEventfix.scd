(
SynthDef("Odin", { |out, pan = 0, n = 0, id = \odin, sustain|
	var sound;

	//var env = EnvGen.kr(Env.asr(0.01, 1, 0.1), gate: gate, doneAction:2);

	//var env = EnvGen.ar(Env.linen(0.002, 0.996, 0.002, 1,-3), timeScale:sustain, doneAction:2);

	sound = In.ar(out, ~dirt.numChannels);

	// These are vst instruments
	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \odin);

	//sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \zebralette2);
	// Here you could define more instruments
	Out.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan);
	)
}).add;
)

(
var diversions = ();
var vstControlBus = ();
var vstControlBusses = ();
var synths = Dictionary [
	\odin-> Synth("Odin", [id: \odin])
];
var instrument;
var instrumentSynths= ();
var instruments = Dictionary[
	\odin -> VSTPluginController(synths.at(\odin), id: \odin)
];


var triggerFunc = { |vstName|
	var lag = ~lag + (~latency ? 0);
	var latency = lag; // for now
	var sustain = ~sustain = ~sustain.value;
	var freq = ~freq.value;
	var note = (~freq.cpsmidi).round(1).asInteger;
	var velocity = (~amp.value * pow(~gain.min(2) + ~overgain, 4);).linlin(0,1,0,127).asInteger;

	synths.at(vstName).set(
		\out, ~out,
		\pan, currentEnvironment.at(\pan),
		\id, vstName.asSymbol
	);


	thisThread.clock.sched(latency, {
		//instruments[vstName].set(\sustain, sustain);
	    instruments[vstName].midi.noteOn(0, note, velocity);
		//~midiInternalOut.noteOn(0, note, velocity);
	});

	thisThread.clock.sched(sustain + latency, {
		instruments[vstName].midi.noteOff(0, note, velocity);

		//~midiInternalOut.noteOff(0, note, velocity);

	});

};

var serverMessage = { |synth|
	[\out, ~out, \sustain, ~sustain].asControlInput.flop.do { |each|
		~dirt.server.sendMsg(\s_new,
			synth,
			-1, // no id
			1, // add action: addToTail
			currentEnvironment.at(\synthGroup), // send to group
			*each.asOSCArgArray // append all other args
		)
	}
};


~dirt.soundLibrary.addSynth(\odin,
	(playInside: { |e|
		triggerFunc.value(\odin);
		serverMessage.value(\Odin);
	})
);

~dirt.soundLibrary.addSynth(\prep,
	(playInside: { |e|
		instruments.at(\odin).readProgram("/Users/tgrund/Development/tidalcycles/TidalVST/advance/Odin/bass-crusher.vstpreset");
		["Empty preparation event", e].postln;
	})
);

instruments.at(\odin).open("Odin2.vst3", verbose: false);

//instruments.at(\odin).open("Odin2.vst3");

~instruments = instruments;

)

~instruments.at(\odin).editor();


~instruments.at(\odin).writeProgram(thisProcess.nowExecutingPath.dirname +/+ "Odin/bass-crusher.vstpreset");

~instruments.at(\odin).readProgram(thisProcess.nowExecutingPath.dirname +/+ "Odin/bass-crusher.vstpreset");

// DirtSoundLibrary


~instruments


VSTPlugin.pluginList.detect {|desc| desc.name.containsi("Odin")}.key

SynthDef(\vstplugin2, {|out, gate = 1|
	var sig = VSTPlugin.ar(numOut: 2);
	var eg = EnvGen.kr(Env.asr(0.01, 1, 0.1), gate, doneAction: 2);
	Out.ar(out, sig * eg);
}).add;

a = Synth(\vstplugin2)

c = VSTPluginController(a);
c.open("Dexed.vst3");

c.editor

VSTPlugin.search

(
p = Pbind(
	\type, \vst_midi,
	\vst, c,
	\degree, Pn(Pseries(-7, Pwhite(1,3,inf), {rrand(4,9)}), inf),
	\dur, 0.15,
	\legato, Pwrand ([0.4, 1.01], [0.8, 0.2], inf);
	\amp, 0.5
).play;

)


(
p = Pbind(
    \type, \vst_midi,
    \vst, c, // the VSTPluginController instance
    \midicmd, \noteOn, // the default, can be omitted
    \chan, 0, // MIDI channel (default: 0)
    \midinote, Pseq(#[0, 2, 4, 7], inf) + Pwhite(-12, 12).stutter(Pwhite(4, 16)) + 60,
    \dur, Prand(#[0.125, 0.25, 0.5], inf),
    \legato, Pexprand(0.5, 1.0, inf),
    \amp, Pexprand(0.5, 1.0, inf)
).play(quant: 1);
)


c.readProgram(thisProcess.nowExecutingPath.dirname +/+ "Odin/bass-crusher.vstpreset");

c.writeProgram(thisProcess.nowExecutingPath.dirname +/+ "Odin/bass-crusher.vstpreset");


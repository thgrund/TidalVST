(
SynthDef("Dexed", { |out, pan = 0, n = 0, id = \dexed1|
	var sound;

	var env = EnvGen.kr(Env.asr(0.8, 1, 0.1), gate: 1, doneAction:2);

	sound = In.ar(out, ~dirt.numChannels);

	// These are vst instruments
	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \dexed1) * env;

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
	\dexed1 -> Synth("Dexed", [id: \dexed1]),
];
var instrument
;
var instrumentSynths= ();
var instruments = Dictionary[
	\dexed1 -> VSTPluginController(synths.at(\dexed1), id: \dexed1).open("Dexed.vst3", editor: true, verbose: false),
];


var triggerFunc = { |vstName|
	var lag = ~lag + (~latency ? 0);
	var latency = lag; // for now
	var sustain = ~sustain = ~sustain.value;
	var freq = ~freq.value;
	var note = (~freq.cpsmidi).round(1).asInteger;
	var velocity = (~amp.value * pow(~gain.min(2) + ~overgain, 4);).linlin(0,1,0,127).asInteger;

	synths.at(\dexed1).set(
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


~dirt.soundLibrary.addSynth(\dexed1,
	(playInside: { |e|
		triggerFunc.value(\dexed1);
		serverMessage.value(\Dexed);
	})
);

~dirt.soundLibrary.addSynth(\prep,
	(playInside: { |e|
		["Empty preparation event", e].postln;
	})
);


~instruments = instruments;

)

VST

VSTPluginController.browse


~instruments.at(\dexed1).editor

// .addSynth(name, event, appendToExisting: false, useSynthDefSustain: false, metaData)

// DirtSoundLibrary

        addMIDI { |name, device, event, appendToExisting = false, metaData|
                 var midiEvent = DirtEventTypes.midiEvent.copy.put(\midiout, device);
                 if(event.notNil) { midiEvent.putAll(event) };
                 this.addSynth(name, midiEvent, appendToExisting, false, metaData)
        }

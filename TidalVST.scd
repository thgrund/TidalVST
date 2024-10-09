(
SynthDef("VST", { |out, pan = 0, n = 0, id = \dexed|
	var sound;

	var env = EnvGen.kr(Env.asr(0.1, 1, 0.1), gate: 1, doneAction:2);

	sound = In.ar(out, ~dirt.numChannels);

	// These are vst instruments
	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \dexed) * env;

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
	\dexed -> Synth("VST", [id: \dexed]),
	//\zebralette2 -> Synth("VST", [id: \zebralette2])
];
var instrument;
var instrumentSynths= ();
var instruments = Dictionary[
	\dexed -> VSTPluginController(synths.at(\dexed), id: \dexed).open("Odin2.vst3", editor: true, verbose: false),
	//\zebralette2 -> VSTPluginController(synths.at(\zebralette2), id: \zebralette2).open("Zebralette", editor: true, verbose: false)
];


var triggerFunc = { |vstName|
	var oldBusses = Set[];
	var newBusses = Set[];
	var busId;

	var lag = ~lag + (~latency ? 0);
	var latency = lag; // for now
	var sustain = ~sustain = ~sustain.value;
	var freq = ~freq.value;
	var note = (~freq.cpsmidi).round(1).asInteger;
	var velocity = (~amp.value * pow(~gain.min(2) + ~overgain, 4);).linlin(0,1,0,127).asInteger;

	instrument = instruments[vstName];

	// Switch to the current orbit
			synths.at(vstName).set(
				\out, ~out,
				\pan, currentEnvironment.at(\pan),
			);

		~dirt.server.makeBundle(~latency, {

		currentEnvironment.keysDo { |key|

			if (key.asString.contains("varg"), {

				busId = currentEnvironment.at(key);

				if (busId.asString.contains("c"), {

					if (vstControlBusses.at(busId).isNil, {
						vstControlBusses.put(busId, Set[]);
					});

					vstControlBusses.at(busId).add(vstName);
					vstControlBus.put(currentEnvironment.at(key), key.asString.replace("varg", ""));
					newBusses.add(currentEnvironment.at(key));
				}, {
					instrument.set(key.asString.replace("varg", "").asInteger, currentEnvironment.at(key));
				});
			});

			vstControlBusses.keysDo {|bus|
				if (vstControlBusses.at(bus).includes(vstName), {
					oldBusses.add(bus)
				});
			};
		};

			(newBusses -- oldBusses).do{ |deleteBus|
				vstControlBusses.at(deleteBus).remove(vstName);
			};

		});

	    thisThread.clock.sched(latency, {
	        instruments[vstName].midi.noteOn(0, note, velocity);
	    });

	    thisThread.clock.sched(sustain + latency, {
		    instruments[vstName].midi.noteOff(0, note, velocity);
	    });

		/* This is plugin specific to switch the presets
	      if (~preset.notNil, {
		  (\type: \vst_midi,
			\vst: instruments[~vstName],
			\midicmd: \control,
			\chan: 0,\ctlNum: 0,\control: 1
		  ).play;

		  (\type: \vst_midi,
			\vst: instruments[~vstName],
			\midicmd: \program,
			\chan: 0,\progNum: ~preset
		  ).play;
		});*/
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

~dirt.soundLibrary.addSynth(\vst,
	(playInside: { |e|
		triggerFunc.value(\dexed);
		serverMessage.value(\VST);
	})
);

~instruments = instruments;

)

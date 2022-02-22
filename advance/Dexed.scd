(
SynthDef("Dexed", { |out, pan = 0, n = 0, id = \dexed1|
	var sound;
	//var env = EnvGen.ar(Env.linen(0.002, 0.996, 0.002, 1,-3), timeScale:1, doneAction:0);

	sound = In.ar(out, ~dirt.numChannels);

	// These are vst instruments
	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \dexed1);
	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \dexed2);
	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \dexed3);
	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \dexed4);
	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \dexed5);
	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \dexed6);
	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \dexed7);

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
	\dexed2 -> Synth("Dexed", [id: \dexed2]),
	\dexed3 -> Synth("Dexed", [id: \dexed3]),
	\dexed4 -> Synth("Dexed", [id: \dexed4]),
	\dexed5 -> Synth("Dexed", [id: \dexed5]),
	\dexed6 -> Synth("Dexed", [id: \dexed6]),
	\dexed7 -> Synth("Dexed", [id: \dexed7]),
];
var instrument;
var instrumentSynths= ();
var instruments = Dictionary[
	\dexed1 -> VSTPluginController(synths.at(\dexed1), id: \dexed1).open("Dexed.vst3", editor: true, verbose: false),
	\dexed2 -> VSTPluginController(synths.at(\dexed2), id: \dexed1).open("Dexed.vst3", editor: true, verbose: false),
	\dexed3 -> VSTPluginController(synths.at(\dexed3), id: \dexed1).open("Dexed.vst3", editor: true, verbose: false),
	\dexed4 -> VSTPluginController(synths.at(\dexed4), id: \dexed1).open("Dexed.vst3", editor: true, verbose: false),
	\dexed5 -> VSTPluginController(synths.at(\dexed5), id: \dexed1).open("Dexed.vst3", editor: true, verbose: false),
	\dexed6 -> VSTPluginController(synths.at(\dexed6), id: \dexed1).open("Dexed.vst3", editor: true, verbose: false),
	\dexed7 -> VSTPluginController(synths.at(\dexed7), id: \dexed1).open("Dexed.vst3", editor: true, verbose: false),
];


var triggerFunc = { |vstName, pan|
	var oldBusses = Set[];
	var newBusses = Set[];
	var busId;

	if (~legato.value.isNil, {~legato = 1.0});
	if (~vstName.value.isNil, {~vstName = "dexed1".asSymbol});
	if (vstName.notNil, {~vstName = vstName.asSymbol});
	if (~n.isNil, {~n = 0});
	if (~pan.isNil, {~pan = 0});
	if (~gain.isNil, {~gain = 1});
	if (~orbit.isNil, {~orbit = 0});

		~dirt.server.makeBundle(~latency, {

		instrument = instruments[~vstName];

		currentEnvironment.keysDo { |key|

			// Switch to the current orbit
			synths.at(~vstName).set(
				\out, ~out,
				\pan, ~pan,
			);

			if (key.asString.contains("varg"), {

				busId = currentEnvironment.at(key);

				if (busId.asString.contains("c"), {

					if (vstControlBusses.at(busId).isNil, {
						vstControlBusses.put(busId, Set[]);
					});

					vstControlBusses.at(busId).add(~vstName);
					vstControlBus.put(currentEnvironment.at(key), key.asString.replace("varg", ""));
					newBusses.add(currentEnvironment.at(key));
				}, {
					instrument.set(key.asString.replace("varg", "").asInteger, currentEnvironment.at(key));
				});
			});

			vstControlBusses.keysDo {|bus|
				if (vstControlBusses.at(bus).includes(~vstName), {
					oldBusses.add(bus)
				});
			};
		};

			(newBusses -- oldBusses).do{ |deleteBus|
				vstControlBusses.at(deleteBus).remove(~vstName);
			};

			(\type: \vst_midi,
				\vst: instruments[~vstName],
				\midicmd: \noteOn,
				\chan: 0,
				\dur: ~delta.value,
				\legato: ~legato,
				\hasGate: true,
				\amp: ~gain,
				\midinote: ~n + 60,
				\progNum: ~progNum,
		    ).play(~synthGroup);
		});


};

var serverMessage = { |synth|
	[\out, ~out, \sustain, ~sustain].asControlInput.flop.do { |each|
		~dirt.server.sendMsg(\s_new,
			synth,
			-1, // no id
			1, // add action: addToTail
			~synthGroup, // send to group
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

~dirt.soundLibrary.addSynth(\dexed2,
	(playInside: { |e|
		triggerFunc.value(\dexed2);
		serverMessage.value(\Dexed);
	})
);


~dirt.soundLibrary.addSynth(\dexed3,
	(playInside: { |e|
		triggerFunc.value(\dexed3);
		serverMessage.value(\Dexed);
	})
);


~dirt.soundLibrary.addSynth(\dexed4,
	(playInside: { |e|
		triggerFunc.value(\dexed4);
		serverMessage.value(\Dexed);
	})
);


~dirt.soundLibrary.addSynth(\dexed5,
	(playInside: { |e|
		triggerFunc.value(\dexed5);
		serverMessage.value(\Dexed);
	})
);


~dirt.soundLibrary.addSynth(\dexed6,
	(playInside: { |e|
		triggerFunc.value(\dexed6);
		serverMessage.value(\Dexed);
	})
);


~dirt.soundLibrary.addSynth(\dexed7,
	(playInside: { |e|
		triggerFunc.value(\dexed7);
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

VSTPluginController.browse


~instruments.at(\dexed3).editor

~instruments


VSTPlugin.search(s)
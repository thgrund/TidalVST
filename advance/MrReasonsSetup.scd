(
SynthDef("Zebralette", { |out, pan = 0, n = 0|
	var sound;
	//var env = EnvGen.ar(Env.linen(0.002, 0.996, 0.002, 1,-3), timeScale:1, doneAction:0);

	sound = In.ar(out, ~dirt.numChannels);

	// These are vst instruments
	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \zebralette);

	//sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \zebralette2);
	// Here you could define more instruments
	Out.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan)
	)
}).add;
)

(
SynthDef("Zebralette2", { |out, pan = 0, n = 0|
	var sound = In.ar(out, ~dirt.numChannels);

	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \zebralette2);

	Out.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan)
	)
}).add;
)

(
SynthDef("Zebralette3", { |out, pan = 0, n = 0|
	var sound = In.ar(out, ~dirt.numChannels);

	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \zebralette3);

	Out.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan)
	)
}).add;
)

/*(

SynthDef("Labs", { |out, pan = 0, n = 0, id = \labs|
	var sound;

	sound = In.ar(out, ~dirt.numChannels);
	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \labs);
	Out.ar(out,
		DirtPan.ar(sound, ~dirt.numChannels, pan)
	)
}).add;
)*/


(
var diversions = ();
var vstControlBus = ();
var vstControlBusses = ();
var synths = Dictionary [
	\zebralette -> Synth("Zebralette", []),
	\zebralette2 -> Synth("Zebralette2", []),
	\zebralette3 -> Synth("Zebralette3", []),
	//\labs -> Synth("Labs", [])
];
var instrument;
var instrumentSynths= ();
var instruments = Dictionary[
	\zebralette -> VSTPluginController(synths.at(\zebralette), id: \zebralette).open("Zebralette", editor: true, verbose: false),
	\zebralette2 -> VSTPluginController(synths.at(\zebralette2), id: \zebralette2).open("Zebralette", editor: true, verbose: false),
	\zebralette3 -> VSTPluginController(synths.at(\zebralette3), id: \zebralette3).open("Zebralette", editor: true, verbose: false),
	//\labs -> VSTPluginController(synths.at(\labs), id: \labs).open("LABS", editor: true, verbose: false)
];


var triggerFunc = { |vstName, pan|
	var oldBusses = Set[];
	var newBusses = Set[];
	var busId;

	if (~legato.value.isNil, {~legato = 1.0});
	if (~vstName.value.isNil, {~vstName = "zebralette".asSymbol});
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

var changeZebraPreset = { |control, vstName|
	var controlNr;

	if (~control.notNil, {controlNr = ~control}, {controlNr = control});

	if (~preset.notNil, {
	  (\type: \vst_midi,
		\vst: instruments[vstName],
		\midicmd: \control,
		\chan: 0,\ctlNum: 0,\control: controlNr
	  ).play;

		(\type: \vst_midi,
		 \vst: instruments[vstName],
		 \midicmd: \program,
		 \chan: 0,\progNum: ~preset
	  ).play;
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

~dirt.soundLibrary.addSynth(\zpad,
	(playInside: { |e|
	   var zebralette = ();
	   var pan = currentEnvironment.at(\pan);

	   currentEnvironment.add(\pan -> ((pan * 0.5) + 0.5));

	   zebralette.putAll((\type: \dirt, \dirt: ~dirt), currentEnvironment);
	   zebralette.add(\s -> \pad);
	   zebralette.add(\resonance -> 0.1);
	   zebralette.add(\midfreq -> 264);
	   zebralette.add(\middb -> 10.5);
	   zebralette.add(\midrq -> 0.1);
	   zebralette.play;
	})
);

~dirt.soundLibrary.addSynth(\pad,
	(playInside: { |e|
		triggerFunc.value(\zebralette);
		serverMessage.value(\Zebralette);
		changeZebraPreset.value(1, \zebralette);
	})
);

~dirt.soundLibrary.addSynth(\zlead,
	(playInside: { |e|
		triggerFunc.value(\zebralette2);
		serverMessage.value(\Zebralette2);
		changeZebraPreset.value(2, \zebralette2);
	})
);

~dirt.soundLibrary.addSynth(\zkey,
	(playInside: { |e|
		triggerFunc.value(\zebralette3);
		serverMessage.value(\Zebralette3);
		changeZebraPreset.value(3, \zebralette3);
	})
);

~dirt.soundLibrary.addSynth(\prep,
	(playInside: { |e|
		["Empty preparation event", e].postln;
	})
);



/*~dirt.soundLibrary.addSynth(\labs,
	(playInside: { |e|
		triggerFunc.value(\labs);
		serverMessage.value(\Labs);
	})
);


~dirt.soundLibrary.addSynth(\pad,
	(playInside: { |e|
		var zebralette = (), labs = ();
		var pan = currentEnvironment.at(\pan);

		currentEnvironment.add(\pan -> ((pan * 0.5) + 0.5));

	   zebralette.putAll((\type: \dirt, \dirt: ~dirt), currentEnvironment);
	   zebralette.add(\s -> \zpad);
	   zebralette.add(\hcutoff -> 220);
	   zebralette.add(\midfreq -> 245);
	   zebralette.add(\middb -> 15);
	   zebralette.add(\midrq -> 0.1);
	   zebralette.play;

	   labs.putAll((\type: \dirt, \dirt: ~dirt), currentEnvironment);
	   labs.add(\s -> \labs);
	   labs.add(\midfreq -> 135);
	   labs.add(\middb -> 2.1);
	   labs.add(\midrq -> 0.4);
	   labs.play;
	})
);*/


~instruments = instruments;

)

VSTPluginController.browse


(

var numChannels =  ~dirt.numChannels;

SynthDef("dirt_mideq" ++ numChannels, { |out, midfreq = 440, midrq = 0, middb = 0|
	var signal = In.ar(out, numChannels);
	signal = MidEQ.ar(signal, midfreq.abs.clip(20, SampleRate.ir / 2), midrq.linexp(0, 1, 1, 0.001), middb);
	ReplaceOut.ar(out, signal)
}, [\ir, \kr, \kr, \kr]).add;
)

(
~dirt.addModule('mideq',
	{ |dirtEvent|
		dirtEvent.sendSynth("dirt_mideq" ++ ~dirt.numChannels,
			[
				midfreq: ~midfreq,
				midrq: ~midrq,
				middb: ~middb,
				out: ~out
		])

}, { ~midfreq.notNil });
)


~instruments.at(\zebralette).editor

~instruments


~dirt.orbits[0.asInteger].group

~dirt.server.latency


(
~dirt.soundLibrary.addSynth(\prep,
	(playInside: { |e|
		["Empty event", e].postln;
	})
);

)

thisProcess.nowExecutingPath.dirname

c.readProgram(thisProcess.nowExecutingPath.dirname +/+ "Odin/bass-crusher.vstpreset");

c.writeProgram(thisProcess.nowExecutingPath.dirname +/+ "Odin/bass-crusher.vstpreset");
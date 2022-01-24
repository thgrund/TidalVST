(
SynthDef("VST", { |out, pan = 0, n = 0, id = \zebralette1|
	var sound;

	sound = In.ar(out, ~dirt.numChannels);

	// These are vst instruments
	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \zebralette1);
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
	\zebralette1 -> Synth("VST", [id: \zebralette1]),
	//\zebralette2 -> Synth("VST", [id: \zebralette2])
];
var instrument;
var instrumentSynths= ();
var instruments = Dictionary[
	\zebralette1 -> VSTPluginController(synths.at(\zebralette1), id: \zebralette1).open("Zebralette", editor: true, verbose: false),
	//\zebralette2 -> VSTPluginController(synths.at(\zebralette2), id: \zebralette2).open("Zebralette", editor: true, verbose: false)
];


var triggerFunc = {
	var oldBusses = Set[];
	var newBusses = Set[];
	var busId;

	if (~legato.value.isNil, {~legato = 1.0});
	if (~vstName.value.isNil, {~vstName = "zebralette1".asSymbol});
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


~dirt.soundLibrary.addSynth(\vst,
	(playInside: { |e|
		triggerFunc.value;

		[\out, ~out, \sustain, ~sustain].asControlInput.flop.do { |each|
			~dirt.server.sendMsg(\s_new,
				"VST",
				-1, // no id
				1, // add action: addToTail
				~synthGroup, // send to group
				*each.asOSCArgArray // append all other args
			)
		}

	})
);

~instruments = instruments;

)

~instruments.at(\zebralette1).editor


(
SynthDef("VST", { |pan = 0, n = 0, id = \vk1, dryBus = 78|
	var sound;

	sound = In.ar(dryBus, ~dirt.numChannels);

	// These are vst instruments
	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \vk1);
	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \vk2);
	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \zebralette1);
	sound = VSTPlugin.ar(sound, ~dirt.numChannels, id: \zebralette2);
	// Here you could define more instruments

	Out.ar(dryBus,
		DirtPan.ar(sound, ~dirt.numChannels, pan)
	)
}).add;
)

(
var diversions = ();
var vstControlBus = ();
var vstControlBusses = ();
var synths = Dictionary [
	\vk1 -> Synth("VST", [id: \vk1, outBus: 76, dryBus: 78]),
	\vk2 -> Synth("VST", [id: \vk2, outBus: 76, dryBus: 78]),
	\zebralette1 -> Synth("VST", [id: \zebralette1, outBus: 76, dryBus: 78]),
	\zebralette2 -> Synth("VST", [id: \zebralette2, outBus: 76, dryBus: 78]),
];
var instrument;
var instrumentSynths= ();
var instruments = Dictionary[
	\vk1 -> VSTPluginController(synths.at(\vk1), id: \vk1).open("VK-1", editor: true, verbose: true),
	\vk2 -> VSTPluginController(synths.at(\vk2), id: \vk2).open("VK-1", editor: true, verbose: true),
	\zebralette1 -> VSTPluginController(synths.at(\zebralette1), id: \zebralette1).open("Zebralette", editor: true, verbose: false),
	\zebralette2 -> VSTPluginController(synths.at(\zebralette2), id: \zebralette2).open("Zebralette", editor: true, verbose: false),
	//... Define your vst instruments here
];

// Just to make instrument accessible from outside
// to use ~instrument.editor
~instruments = instruments;

~vstControlBus = vstControlBus;
~vstControlBusses = vstControlBusses;

~diversions = diversions;
~d1.defaultParentEvent[\diversion] = { |dirtEvent|
	diversions[~s].value;
	diversions[~vstName].value;
};
~d2.defaultParentEvent[\diversion] = { |dirtEvent|diversions[~s].value; diversions[~vstName].value;
};
~d3.defaultParentEvent[\diversion] = { |dirtEvent|diversions[~s].value;	diversions[~vstName].value;
};
~d4.defaultParentEvent[\diversion] = { |dirtEvent|diversions[~s].value;	diversions[~vstName].value;
};
~d5.defaultParentEvent[\diversion] = { |dirtEvent|diversions[~s].value;	diversions[~vstName].value;
};

~diversions[\vst]  = {
	var oldBusses = Set[];
	var newBusses = Set[];
	var busId;

	if (~legato.value.isNil, {~legato = 1.0});
	if (~vstName.value.isNil, {~vstName = "vk1".asSymbol});
	if (~n.isNil, {~n = 0});
	if (~pan.isNil, {~pan = 0});

		~dirt.server.makeBundle(~latency, {

		instrument = instruments[~vstName];

		currentEnvironment.keysDo { |key|

			// Switch to the current orbit
			synths.at(~vstName).set(
				\dryBus, ~dirt.orbits[currentEnvironment.at(\orbit).asInteger].dryBus,
				\outBus, ~dirt.orbits[currentEnvironment.at(\orbit).asInteger].outBus,
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
			\amp: 0.5,
			\midinote: ~n + 60,
			\dur: ~delta.value * ~legato,
			\progNum: ~progNum,
		).play;
	})
};

// This is a custom control bus listener
// To use it you need to add a new target with a control bus listening on 3338
a = OSCFunc({ |msg, time, tidalAddr|
	var busid = ("c" ++ msg[1]).asSymbol;
	var busnr = msg[1];
	var instruments = ~vstControlBusses.at(busid);

	instruments.do {|instrument|
		~instruments.at(instrument).set(~vstControlBus.at(busid).asInteger , msg[2]);
	};
}, '/c_set', NetAddr("127.0.0.1"), recvPort: 3338)
)

~instruments.at(\vk1).editor

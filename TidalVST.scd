(
SynthDef("VST", { |pan = 0, n = 0, id = \zebralette1, dryBus = 78|
	var sound;

	sound = In.ar(dryBus, ~dirt.numChannels);

	// These are vst instruments
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
	\zebralette1 -> Synth("VST", [id: \zebralette1, outBus: 76, dryBus: 78]),
	\zebralette2 -> Synth("VST", [id: \zebralette2, outBus: 76, dryBus: 78])
];
var instrument;
var instrumentSynths= ();
var instruments = Dictionary[
	\zebralette1 -> VSTPluginController(synths.at(\zebralette1), id: \zebralette1).open("Zebralette", editor: true, verbose: false),
	\zebralette2 -> VSTPluginController(synths.at(\zebralette2), id: \zebralette2).open("Zebralette", editor: true, verbose: false)
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

	//["cycles", ~cycle, "gain", ~gain, "n", ~n, "vst", ~vstName].postln;


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
				\dur: ~delta.value,
				\legato: ~legato,
				\hasGate: true,
				\amp: ~gain,
				\midinote: ~n + 60,
				\progNum: ~progNum,
			).play;
		});
};


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
~d5.defaultParentEvent[\diversion] = { |dirtEvent|diversions[~s].value; diversions[~vstName].value;
};



~diversions[\vst]  = {
	if (~vstName.value.isNil, {~vstName = "zebralette1".asSymbol});
	if (~n.isNil, {~n = 0});

	triggerFunc.value;

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
}, '/c_set', NetAddr("127.0.0.1"), recvPort: 3338);

)

~instruments.at(\zebralette2).editor


TidalVST {
	var dirt;

	var <>synths;
	var <>envelops;
	var <>instruments;
	var <>fxs;
	var <>presetPath;
	var <>enabledEffectSynths;
	var <>bus;
	var <>receiveEvent;

	*new { |dirt|
		^super.newCopyArgs(dirt).init
	}

	init {
		synths = Dictionary.new;
		envelops = Dictionary.new;
		instruments = Dictionary.new;
		fxs = Dictionary.new;
		enabledEffectSynths = Set.new;
		bus = Bus.new;
		presetPath = "/Users/mrreason/Development/tidalcycles/TidalVST/dexed/presets/";

		this.loadSynthDefs;

		~dirt.server.sync;
	}

	loadSynthDefs { |path|
		var filePaths;
		path = path ?? { "../synths".resolveRelative };
		filePaths = pathMatch(standardizePath(path +/+ "*"));
		filePaths.do { |filepath|
			if(filepath.splitext.last == "scd") {
				(dirt:this).use { filepath.load }; "loading synthdefs in %\n".postf(filepath)
			}
		}
	}

	loadPreset { |vstName, preset|
		var inst = instruments[vstName.asSymbol];

		if (preset.notNil && vstName.notNil, {
			inst.readProgram(presetPath ++ preset ++ ".vstpreset");
		});
	}

	savePreset { |vstName, preset|
		var inst = instruments[vstName.asSymbol];

		if (preset.notNil && vstName.notNil, {
			inst.writeProgram(presetPath ++ preset ++ ".vstpreset");
		});
	}

	triggerFunc {
		var lag = ~lag + (~latency ? 0);
		var latency = lag; // for now
		var hasGate;
		var sustain = ~sustain.value;
		var freq = ~freq.value;
		var note = (~freq.cpsmidi).round(1).asInteger;
		var velocity = ( 127 * ((~amp.value * (~gain.min(2).pow(4))) + ~overgain) ).min(127).asInteger;
		var vstName = ~s;
		var currentEnv = currentEnvironment;

		var moderndrumFunc = {|orbitNumber, prefix|
			synths.at(vstName).set((prefix).asSymbol, (
				if (enabledEffectSynths.includes(vstName), {~dirt.orbits[orbitNumber].synthBus}, {~dirt.orbits[orbitNumber].dryBus}));
			);

			if (currentEnv.at(\orbit) === orbitNumber, {
				synths.at(vstName).set((prefix ++ "Pan").asSymbol,
					if (currentEnv.at(\pan).isNil.not, {
						currentEnv.at(\pan)
					}, {
						(~dirt.orbits[orbitNumber].defaultParentEvent.at(\pan).linlin(0,1,-1,1))
					})
				);
			});
		};

		if (currentEnv.at(\gm).isNil.not, {note = (currentEnv.at(\gm) + 36)});

		receiveEvent.value(this, vstName, velocity, currentEnv);

		currentEnvironment.keysDo { |key|
			if (key.asString.contains("varg"), {
				instruments[vstName].set(key.asString.replace("varg", "").asInteger, currentEnvironment.at(key));
			});
		};



		if (currentEnvironment.at(\drumBank) == 3 , {
			moderndrumFunc.value(10, "kickOut");
			moderndrumFunc.value(11, "cymbalOut");
			moderndrumFunc.value(12, "snareOut");
			moderndrumFunc.value(13, "tomOut");
		});

		synths.at(vstName).set(
				\out, (if (enabledEffectSynths.includes(vstName), {~out}, {~dryBus} )),
			    \dryBus, ~dryBus,
			    \effectBus, ~effectBus,
			    \sustain, sustain,
                \pan, currentEnv.at(\pan)
			);

		thisThread.clock.sched(latency, {
			instruments[vstName].midi.noteOn(0, note, velocity);
		});

		thisThread.clock.sched(sustain + latency, {
			instruments[vstName].midi.noteOff(0, note, 0);
		});
	}

	midiNoteOn { |vstName, velocity, note, bus|
		synths.at(vstName).set(
				\out, bus,
		);

		instruments[vstName].midi.noteOn(0, note, velocity);
	}

	midiNoteOff {|vstName, note|
		instruments[vstName].midi.noteOff(0, note, 0);
	}

	eventmapper {
		var event = ();
		var pan = (currentEnvironment.at(\pan));
		var finalSoundName;
		var soundName = ~s;

		event.putAll((\type: \dirt, \dirt: ~dirt), currentEnvironment);

		if (event.at('note').isNil, {event.add(\note -> 0.0)});

		if (currentEnvironment.at(\chiptune) == 1, {
			finalSoundName = 'bit' ++ soundName;
		});

		event.add(\pan -> ((pan + 1) / 2));
		event.add(\type-> \dirt);
		event.add(\dirt-> ~dirt);
		event.add(\s -> (finalSoundName).asSymbol);
		//event.add(\amp -> ~gain);
		event.add(\freq -> (event.at('note') + 60).midicps );

		event.play;
	}

	serverMessage { |synth|
		//var args =[\out, ~out, \sustain, ~sustain, \pan, ~pan, \freq, ~freq, \speed, ~speed, synth, \cutoff, ~cutoff];
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
	}

	addVSTInstrument { |key, vst, adsr, synth = "vst_instrument", target = 1, isMultiThreading = false|
		synths.put(key.asSymbol, Synth(synth, [id: key.asSymbol], target));

		envelops.put(key.asSymbol, Dictionary.newFrom(adsr ?? [\attack: nil, \hold: nil, \release: nil]));

		dirt.soundLibrary.addSynth(key.asSymbol, (playInside: { |e|
			// if it's key only
			// then map + global add

		if (currentEnvironment.at(\chiptune) == 1, {
				this.eventmapper.value();
			}, {
				~attack = envelops.at(~s.asSymbol)[\attack];
				~hold = envelops.at(~s.asSymbol)[\hold] * (~sustain.value);
				~release = envelops.at(~s.asSymbol)[\release];
				// if it's key + prefix
				this.triggerFunc.value();
			});
		}));

		// Add prefix
		instruments.put(key.asSymbol, VSTPluginController(synths.at(key.asSymbol)),);

		instruments.at(key.asSymbol).open(vst, multiThreading: isMultiThreading);

		Server.default.sync;

	}

}


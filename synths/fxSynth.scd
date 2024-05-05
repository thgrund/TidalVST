var numChannels = ~dirt.numChannels;

SynthDef(\pliniRhytm, {|out, dryBus, bypass = 1, pan = 0|
	var sound = In.ar(dryBus, 2);
    sound = VSTPlugin.ar(sound, numOut: 2, id: \pliniRhytm, bypass: bypass);

	//DirtPause.ar(sound, graceTime:4);

    // out should be a global fx bus for reverb.
    // With this you could add more of these fx busses without affecting other audio busses.
    ReplaceOut.ar(out,  DirtPan.ar(sound, 2, pan) );
}).add;

SynthDef(\pliniLead, {|out, dryBus, bypass = 1, pan = 0|
	var sound = In.ar(dryBus, 2);

    sound = VSTPlugin.ar(sound, numOut: 2, id: \pliniLead, bypass: bypass);

	//DirtPause.ar(sound, graceTime:4);

    // out should be a global fx bus for reverb.
    // With this you could add more of these fx busses without affecting other audio busses.
    ReplaceOut.ar(out,  DirtPan.ar(sound, 2, pan) );
}).add;

SynthDef(\pliniInLead, {|out, in = 1, bypass = 1|
	var sound = SoundIn.ar(in, 1);
	var resultSound;
    resultSound = VSTPlugin.ar(sound, numOut: 2, id: \pliniInLead, bypass: bypass);

    ReplaceOut.ar(out, resultSound);
}).add;

SynthDef(\pliniInLead2, {|out, in = 1, bypass = 0|
	var sound = SoundIn.ar(in, 1);
	var resultSound;
    resultSound = VSTPlugin.ar(sound, numOut: 2, id: \pliniInLead2, bypass: bypass);

	ReplaceOut.ar(out, resultSound);
    ReplaceOut.ar(0, resultSound);
}).add;


SynthDef(\valhalla, {|out|
	var size = 14;
	var dryBusses = NamedControl.kr(\dryBusses, (0 ! size ));
	var wetReverbs = NamedControl.kr(\wetReverbs, (0 ! size));
	var fxSound = size.collect({arg i; In.ar(dryBusses[i], 2) * wetReverbs[i]}).sum;

	fxSound = VSTPlugin.ar(fxSound, numOut: 2, id: \valhalla);

	Out.ar(out ,fxSound);

}).add;

SynthDef(\valhallaDelay, {|out|
	var size = 14;
	var dryBusses = NamedControl.kr(\dryBusses, (0 ! size ));
	var wetDelay = NamedControl.kr(\wetDelays, (0 ! size));
	var fxSound = size.collect({arg i; In.ar(dryBusses[i], 2) * wetDelay[i]}).sum;

	fxSound = VSTPlugin.ar(fxSound, numOut: 2, id: \valhallaDelay);

	Out.ar(out ,fxSound);

}).add;

SynthDef(\masterSynth, { |out, monitorBus, fxBus|
	var size = 14;
	var wetSound = In.ar(fxBus, 2);
	var dryBusses = NamedControl.kr(\dryBusses, (0 ! size ));
	var wetSums = NamedControl.kr(\wetSums, (0 ! size));

	var drySound = size.collect({
		arg i;
		ReplaceOut.ar (dryBusses[i], In.ar(dryBusses[i], 2) * (1/(wetSums[i] +1) ));
	});

	Out.ar(out, wetSound);
	Out.ar(monitorBus, wetSound * 1.5);
}).add;


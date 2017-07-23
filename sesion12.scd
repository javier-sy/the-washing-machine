/*
Esta sesión emplea como entrada los canales 1/2, 3/4, 5/6, 7/8,  de Soundflower de 64ch
La salida la envía a los canales 8/9, 10/11, 12/13, 14/15
*/

~initServer.();
~oscStart.();

// Servicio
//
(
~initServer = {
	s.quit;

	Server.local.options.memSize = 1024 * 1024;
	Server.local.options.hardwareBufferSize = 1024;

	Server.local.options.maxSynthDefs = 2048;
	Server.local.options.maxNodes = 2048;
	Server.local.options.numBuffers = 2048;
	Server.local.options.numWireBufs = 2048;
	Server.local.options.numAudioBusChannels = 4096;

	Server.local.options.inDevice = "Soundflower (64ch)";
	Server.local.options.numInputBusChannels = 64;

	Server.local.options.outDevice = "Soundflower (64ch)";
	Server.local.options.numOutputBusChannels = 64;

	Server.local.options.sampleRate = 96000;

	Server.default = s = Server.local.boot;

	s.waitForBoot {
		"Server: OK".postln;
	}
};

~out = [10, 12, 14, 16, 18, 20, 22, 24, 26, 28];
~in = [64, 66, 68, 70, 72, 74, 76, 78, 80, 82];

~mainmul = 0.dbamp;

~exp2 = {
	| baseLevel = 0, baseSemitones = 0, semitones, steps, val |

	var step = semitones / (steps - 1);

	 (2 ** (baseSemitones / 12)) * (2 ** ( (val - baseLevel) * step / 12));
};

~init = {
	| voices |

	s.freeAll;

	~channels = voices;

	~innode = ~channels collect: { | c | NodeProxy.audio(s, 2); };

	~outnode =  ~out.size collect: { | c | NodeProxy.audio(s, 2); };
	~outnode.size do: { |i| { Out.ar(bus: ~out[i], channelsArray: ~outnode[i].ar) }.play; };

	~wsize = ~channels collect: { | c | var node = NodeProxy.audio(s, 2); node.fadeTime = 0.1; node; };

	~mul = ~channels collect: { var node = NodeProxy.control(s, 1); node.source = 0; node.fadeTime = 0.05; node; };
	~rate = ~channels collect: { var node = NodeProxy.control(s, 1); node.source = 1.0; node.fadeTime = 0.05; node; };

	~channels do: { | i | ~selcontroller.(index: i, source: 0); };
	~channels do: { | i | ~outcontroller.(index: i, output_channel: 0); };
	~channels do: { | i | ~ratecontroller.(index: i, pitchexp: 0); };
	~channels do: { | i | ~mulcontroller.(index: i, val: 0); };

	["INIT", "VOICES", voices].postln;
};

~selcontroller = {
	|index, source|

	["INPUT_CHANNEL", "INDEX", index, "SOURCE", source].postln;

	~innode[index].source = { DelayN.ar(in: In.ar(bus: ~in[source], numChannels: 2), maxdelaytime: 0.350, delaytime: 0.350) };
};

~outcontroller = {
	|index, output_channel|

	["OUTPUT_CHANNEL", "INDEX", index, "OUTPUT CHANNEL", output_channel].postln;

	~outnode[output_channel].source = ~wsize[index];
};

~ratecontroller = {
	|index, pitchexp|

	var pitch = 2.0 ** pitchexp;

	// ["RATE", "INDEX", index, "PITCHEXP", pitchexp, "PITCH", pitch].postln;

	~rate[index].source = pitch;
};

~wsizecontroller = {
	|index, wsize|

	["WSIZE", "INDEX", index, "WSIZE", wsize].postln;

	~wsize[index].source = { PitchShift.ar(
		in: ~innode[index],
		windowSize: wsize,
		timeDispersion: 0,
		pitchDispersion: 0,
		pitchRatio: ~rate[index].kr,
		mul: ~mainmul * ~mul[index].kr) };
};

~mulcontroller = {
	|index, val|

	// ["MUL", "INDEX", index, "VAL", val].postln;

	~mul[index].source = val.dbamp;
};

~oscStart = {
	OSCdef(\init, { | msg, time, addr, recvPort | ~init.(voices: msg[1]) }, "/init");
	OSCdef(\sel, { | msg, time, addr, recvPort | ~selcontroller.(msg[1], msg[2]) }, "/input_channel");
	OSCdef(\out, { | msg, time, addr, recvPort | ~outcontroller.(msg[1], msg[2]) }, "/output_channel");

	OSCdef(\vol, { | msg, time, addr, recvPort | ~mulcontroller.(msg[1], msg[2]) }, "/vol");
	OSCdef(\wsize, { | msg, time, addr, recvPort | ~wsizecontroller.(msg[1], msg[2]) }, "/wsize");
	OSCdef(\rate, { | msg, time, addr, recvPort | ~ratecontroller.(msg[1], msg[2]) }, "/rate");

	"oscStart: OK";
};

"OK";
)

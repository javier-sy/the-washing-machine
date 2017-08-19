require 'musa-dsl'
require 'pp'

require_relative 'abstraction'

# Sincronización: En SuperCollider, DelayN.ar de entrada de 350 ms
# Sincronización: En Live, Output MIDI Ruby Clock Sync Delay 170 ms

include Musa::Series

puts "Score loaded: file loaded"

class Theme_1 < Musa::Theme
	
	def initialize(context, voice:, pitch:)
		super context

		@voice = voice
		@pitch = pitch
	end

	def run(till:)
		move_pitch_and_return @voice, to: @pitch, till: till
	end
end

class Theme_2 < Musa::Theme
	def initialize(context, voice_1:, voice_2:, pre_offset_1:, post_offset_1:, pre_offset_2:, post_offset_2:)
		super context

		@voice_1 = voice_1
		@voice_2 = voice_2
		@pre_offset_1 = pre_offset_1
		@pre_offset_2 = pre_offset_2
		@post_offset_1 = post_offset_1
		@post_offset_2 = post_offset_2
	end

	def at_position(p, **parameters)
		p - @pre_offset_1
	end

	def run(till:, wait_duration:, pitch_1:, pitch_2:, enable_2:, next_position:)
		log "Theme_2: running till #{till} pitch_1: #{pitch_1} pitch_2: #{pitch_2} enable_2: #{enable_2} next_position: #{next_position}"

		@voice_1.pitch = s(pitch_1)
		
		move_vol_twice @voice_1, to: -15, duration: t(1,14), wait_duration: wait_duration, to_2: -40, till_2: till + @post_offset_1

		if next_position && enable_2
			at till - @pre_offset_2, debug: @debug_at do
				@voice_2.pitch = s(pitch_2)
				move_vol_twice @voice_2, to: 6, duration: t(1,0), wait_duration: wait_duration, to_2: -40, till_2: next_position + @pre_offset_1 + @post_offset_2
			end
		end
	end
end

class Theme_3 < Musa::Theme

	@@OFFSET = t(1,0)

	def initialize(context, voice:, voice_2:)
		super context
		@voice = voice
		@voice_2 = voice_2
	end

	def at_position(p, **parameters)
		p - @@OFFSET
	end

	def run(at:, pitch:, vol:, pitch_2:, till:, next_position:)
		log "Theme_3: running at: #{at} till: #{till} pitch: #{pitch} vol: #{vol} pitch_2: #{pitch_2} next_position: #{next_position}"

		@voice.pitch = s(24 - pitch)

		third = (till - at) / 3

		move_vol_twice @voice, to: vol, till: at + third, wait_duration: third, to_2: -40, till_2: till + @@OFFSET

		if next_position
			delta = (next_position - till)/8
			self.at till - delta do
				@voice_2.pitch = s(24 - pitch_2)
				move_vol_twice @voice_2, to: 15, till: next_position - delta, wait_till: next_position + 2*delta, to_2: -40, till_2: next_position + delta*3
			end
		end
	end
end

def score
	puts "Score loaded: defining score"

	ts = @transport.sequencer

	@debug_at = true

	ts.with @voices do |voices|

		voices.reset

		@voice_low = []
		@voice_mid = []
		@voice_high = []
		
		@voice_low << voices.voice(name: "low 0", index: 0, input_channel: 0, output_channel: 0, midi_channel: 0, cc_vol: 8, cc_wsize: 4, cc_pitch: 0)
		@voice_low << voices.voice(name: "low 1", index: 1, input_channel: 0, output_channel: 1, midi_channel: 0, cc_vol: 9, cc_wsize: 5, cc_pitch: 1)

		@voice_mid << voices.voice(name: "mid 0", index: 2, input_channel: 0, output_channel: 2, midi_channel: 3, cc_vol: 8, cc_wsize: 4, cc_pitch: 0)
		@voice_mid << voices.voice(name: "mid 1", index: 3, input_channel: 0, output_channel: 3, midi_channel: 3, cc_vol: 9, cc_wsize: 5, cc_pitch: 1)
		@voice_mid << voices.voice(name: "mid 2", index: 4, input_channel: 0, output_channel: 4, midi_channel: 3, cc_vol: 10, cc_wsize: 6, cc_pitch: 2)
		@voice_mid << voices.voice(name: "mid 3",index: 5, input_channel: 0, output_channel: 5, midi_channel: 3, cc_vol: 11, cc_wsize: 7, cc_pitch: 3)

		@voice_high << voices.voice(name: "high 0", index: 6, input_channel: 0, output_channel: 6, midi_channel: 5, cc_vol: 8, cc_wsize: 4, cc_pitch: 0)
		@voice_high << voices.voice(name: "high 1", index: 7, input_channel: 0, output_channel: 7, midi_channel: 5, cc_vol: 9, cc_wsize: 5, cc_pitch: 1)
		@voice_high << voices.voice(name: "high 2", index: 8, input_channel: 0, output_channel: 8, midi_channel: 5, cc_vol: 10, cc_wsize: 6, cc_pitch: 2)
		@voice_high << voices.voice(name: "high 3", index: 9, input_channel: 0, output_channel: 9, midi_channel: 5, cc_vol: 11, cc_wsize: 7, cc_pitch: 3)

		@all_voices = @voice_low + @voice_mid + @voice_high

		# wsize_low <> wsize_mid = 1 oct + 10 st = 1 oct + 7ªdim
		# wsize_mid <> wsize_high = 1 oct + 3 st = 1 oct + 3ªmin

		@wsize_low = Rational(7, 12)
		@wsize_mid = Rational(15, 12)
		@wsize_high = Rational(30, 12)

		@voice_low.apply :wsize=, @wsize_low
		@voice_mid.apply :wsize=, @wsize_mid
		@voice_high.apply :wsize=, @wsize_high

		@all_voices.apply :vol=, -40
		@all_voices.apply :pitch=, 0

		@scale = Musa::Scales.get(:major).based_on_pitch 3
	end

	ts.with do
		every 1/8.0 do
			#puts "#{@voice[0].to_s}"
			@all_voices.each do |v|
				#puts "#{v.to_s}"
			end
			#puts
		end

		at 1, debug: @debug_at do
			@all_voices.apply :pitch=, s(24)

			@voice_low[0].vol = 0

			@voice_mid[0].vol = -3
			@voice_mid[1].vol = 6

			@voice_high[0].vol = 0
		end

		at 2, debug: @debug_at do
			move_vol @voice_low[0], till: 3, to: -40
		end

		theme 	Theme_1, 
		voice: @voice_mid[1], pitch: s(22),
		at:		S(4, 	t(6,4), 	t(8,4), 	t(9,0), 	t(9,8)),
		till:	S(t(5,0), t(7,5), 	t(8,14), 	t(9,6), 	t(9,13))

		at t(9,15), debug: @debug_at do
			move_vol @voice_high[0], to: 12, till: 11
			move_pitch @voice_high[0], to: s(11), till: t(11,12)
		end

		at t(12,8), debug: @debug_at do
			@voice_mid[0].vol = -20

			@voice_mid[1].vol = -40

			@voice_high[0].vol = -40
		end

		at t(12,10), debug: @debug_at do
			@voice_mid[0].pitch = 0
			move_vol @voice_mid[0], to: 3, duration: c(2)
		end

		at t(17,2), debug: @debug_at do 
			move_vol @voice_mid[0], to: -40, duration: c(4)
		end

		at t(17,10), debug: @debug_at do
			move_vol @voice_low[0], to: 0, duration: c(4)
		end


		at t(19,2), debug: @debug_at do
			move_vol @voice_low[0], till: 28, to: -12

			@voice_mid[0].pitch = s(24)

			@pitches = @all_voices.get(:pitch)

			move_pitch_sin @voice_low[0], till: t(34,12), center_add: -s(1),	amplitude: s(1), 	frequency: 0.02

			move_pitch_sin @voice_mid[0], till: t(34,12), center_add: -s(0.9),	amplitude: s(0.9), 	frequency: 0.065
			move_pitch_sin @voice_mid[1], till: t(34,12), center_add: -s(0.3), 	amplitude: s(0.3), 	frequency: 0.192

			move_pitch_sin @voice_high[0], till: t(34,12), 						amplitude: s(0.7), 	frequency: 0.128
			move_pitch_sin @voice_high[1], till: t(34,12), center_add: -s(0.1), amplitude: s(0.1), 	frequency: 0.32
			move_pitch_sin @voice_high[2], till: t(34,12), center_add: -s(0.05), amplitude: s(0.05), frequency: 0.448
		end

		at 20, debug: @debug_at do
			move_vol @voice_high[1], till: 22, to: -3
		end

		at 23, debug: @debug_at do
			move_vol @voice_mid[0], till: 26, to: -6
		end

		at 27, debug: @debug_at do
			move_vol @voice_mid[1], till: 30, to: 0
		end

		at 31, debug: @debug_at do
			@voice_high[0].pitch = s(16)
			move_vol @voice_high[0], till: 34, to: 3
		end

		at 34.75, debug: @debug_at do
			move_vol @voice_high[0], till: 37, to: 0

			move_vol @voice_low[0], till: 37, to: -40
			move_vol @voice_high[0], till: 37, to: -3

			move_pitches @all_voices, till: 37, to: @pitches
		end

		at 37, debug: @debug_at do
			@voice_mid[0].vol += 3
			move_pitch_and_return @voice_mid[0], to: s(11), till: 38, return_at: t(40,0)
		end

		at t(40,0), debug: @debug_at do
			@voice_mid[1].pitch = s(16)
			move_pitch_and_return @voice_mid[1], to: s(22), till: t(41,11), return_at: t(42,12)
		end

		at t(42,12), debug: @debug_at do
			@voice_high[0].pitch = s(12)
			move_pitch_forth_and_back @voice_high[0], to: s(16), till: t(46,4), back_at: t(47,12)

			move_vol @voice_high[1], to: -3, till: t(51,13)
		end

		at t(49,13), debug: @debug_at do
			@voice_high[0].pitch = s(11)
		end

		# TODO hasta 51 ha subido varios tonos, que no se han bajado... puedo usarlos para repetir y rebajar tensión después

		at t(50,12), debug: @debug_at do
			move_pitch_and_return @voice_high[1], to: s(14), till: t(54,12), return_at: t(55,14)
		end

		at t(57,6), debug: @debug_at do
			move_pitch_and_return @voice_high[0], to: s(22), till: t(61,6), return_at: t(63,3)
		end

		at t(65,3), debug: @debug_at do
			@voice_mid[0].pitch = s(16)
			@voice_mid[1].pitch = s(14)
			@voice_high[1].pitch = s(18)
		end

		at t(65,4), debug: @debug_at do
			move_vol @voice_mid[0], to: 6, till: t(66,8)
			move_vol @voice_mid[1], to: 6, till: t(66,8)
			
			move_vol @voice_high[1], to: 6, till: t(66,8)
		end

		at t(66,8), debug: @debug_at do

			@voice_mid[0].vol = -40
			@voice_mid[1].vol = -40

			@voice_high[0].vol = -40
			@voice_high[1].vol = -40
		end

		#
		# Zona de "repeticiones con parada"
		#

		at t(61,15), debug: @debug_at do
			move_vol_twice @voice_low[0], to: 6, till: t(66,8), wait_duration: -t(2,8), to_2: -40, till_2: t(69,14)
		end

		theme Theme_2,
		at:		S(t(69,14),	t(82,11), 	t(90,11), 	t(103,7), 	t(111,7), 	t(124,3), 	t(132,3), 	t(145,0), 	t(153,15)), 
		till: 	S(t(78,12),	t(87,11), 	t(99,10),	t(108,8),	t(120,6),	t(129,3),	t(141,3),	t(150,0),	t(158,15)),
		wait_duration:
			  	S(-t(1,8),	-t(1,8),	-t(1,4),	-t(1,4),	-t(1,0),	-t(1,0),	-t(0,8),	-t(0,8),	-t(1,8)),

		voice_1: @voice_low[1], 
		pitch_1: S(-48, -46, -44, -42).repeat,

		voice_2: @voice_low[0],
		pitch_2: S(24, 23, 22, 21).repeat,
		enable_2: S(true).repeat(3).after(S(false).repeat),

		pre_offset_1: t(1,8),
		post_offset_1: t(0,8),
		pre_offset_2: t(0,0),
		post_offset_2: t(0,4)

		at 80 do

			log

			4.times do |i|
				@voice_mid[i].input_channel = @voice_high[i].input_channel = i + 1
			end

			chords = S(
				Musa::Chord(:II, 				scale: @scale, 				duplicate: 	{ position: 0, octave: 1 } ),
				Musa::Chord(:VI, 				scale: @scale,	octave: -1, duplicate: 	{ position: 0, octave: 1 } ),
				Musa::Chord(:III,				scale: @scale, 				duplicate: 	{ position: 0, octave: 2 },
																				move:   { voice: 2, octave: 0 } ),
				Musa::Chord(:IV,	grades: 4,	scale: @scale, 	octave: -1,		move: [ { voice: 0, octave: 1 },
																						{ voice: 2, octave: 1 } ]),


				Musa::Chord(:II,	grades: 4,	scale: @scale, 					move: [ { voice: 0, octave: 2 },
																						{ voice: 3, octave: -1 } ] ),
				Musa::Chord(:VII,	grades: 4,	scale: @scale, 	octave: -1,		move:   { voice: 1, octave: 1 } ),
				Musa::Chord(:V,		grades: 4,	scale: @scale, 	octave: -1, 	move: [ { voice: 0, octave: 1 },
																						{ voice: 3, octave: 0 } ] ),
				Musa::Chord(:I, 				scale: @scale, 				duplicate: 	{ position: 0, octave: 2 }) ).eval { |chord| chord.pitches }

			# pp chords.to_a; chords.restart
			
			hash_chords = chords.hashify :a, :b, :c, :d

			@series = hash_chords.split master: :d
			@series_2 = hash_chords.duplicate.shift(-1).split master: :d

			theme Theme_3,
			at:		S(	t(82,7), 	t(94,13), 	t(102,12), 	t(112,7), 	t(120,6), 	t(130,2), 	t(138,1), 	t(147,13)),
			till: 	S(	t(90,16), 	t(99,13),	t(108,11),	t(117,7),	t(126,5),	t(135,3),	t(143,15),	t(152,13)),
			voice: 	@voice_high[0],
			voice_2: @voice_mid[0],
			pitch: 	 @series[:d],
			pitch_2: @series_2[:d],
			vol:   	 FOR(from: -10.0, to: 6.0, step: 2.0)

			theme Theme_3,
			at:  	S(	t(90,8),	t(98,7),	t(108,1),	t(116,2),	t(125,14), 	t(133,13), 	t(143,8), 	t(151,7)),
			till: 	S(	t(95,13),	t(104,6),	t(113,2),	t(122,1),	t(130,13), 	t(139,11), 	t(148,8), 	t(157,5)),
			voice: 	@voice_high[1],
			voice_2: @voice_mid[1],
			pitch: 	 @series[:c],
			pitch_2: @series_2[:c],
			vol:   	 FOR(from: -10.0, to: 6.0, step: 2.0)

			theme Theme_3,
			at:		S(	t(96,8),	t(106,3),	t(114,2),	t(123,14),	t(131,13),	t(141,8)),
			till: 	S(	t(102,7),	t(111,4),	t(120,2),	t(128,15),	t(137,12),	t(146,10)),
			voice: 	@voice_high[2],
			voice_2: @voice_mid[2],
			pitch: 	 @series[:b],
			pitch_2: @series_2[:b],
			vol:   	 FOR(from: -6.0, to: 6.0, step: 2.0)


			theme Theme_3,
			at:		S(	t(100,10),	t(110,5),	t(118,4),	t(128,0),	t(135,15),	t(145,11)),
			till: 	S(	t(106,9),	t(115,6),	t(124,4),	t(133,1),	t(141,14),	t(150,12)),
			voice: 	@voice_high[3],
			voice_2: @voice_mid[3],
			pitch: 	 @series[:a],
			pitch_2: @series_2[:a],
			vol:   	 FOR(from: -6.0, to: 6.0, step: 2.0)
		end

		#
		# Centrifugado
		#

		at t(159,8), debug: @debug_at do

			@all_voices.apply :vol=, -40

			@end_voices = [ @voice_low[1], @voice_mid[0], @voice_mid[1], @voice_high[0], @voice_high[1] ]

			@end_voices.each { |v| v.input_channel = 0 }
			@voice_mid[2].input_channel = 0


			# tramo A

			@start = t(159,8)
			finish = t(177,15)
			duration =  finish - @start 
			@lapsus = duration / 8

			@end_voices.each_index do |i| 
				at(@start + i * @lapsus) { move_vol @end_voices[i], to: -3, till: @start + (i+2) * @lapsus }
			end

											  @end_voices.apply :pitch=, [24, 24, 24, 24, 24].collect { |p| s(p) }		# ok
			# tramo B
			at(t(178,0), debug: @debug_at)	{ @end_voices.apply :pitch=, [24, 24, 17, 24, 17].collect { |p| s(p) } }	# ok -
			# tramo C
			at(t(194,0), debug: @debug_at) 	{ @end_voices.apply :pitch=, [22, 24, 20, 24, 20].collect { |p| s(p) } }	# ok
			at(t(201,0), debug: @debug_at) 	{ @end_voices.apply :pitch=, [22, 22, 20, 22, 20].collect { |p| s(p) } }	# ok
			# tramo D
			at(t(205,0), debug: @debug_at) 	{ @end_voices.apply :pitch=, [22, 20, 20, 20, 20].collect { |p| s(p) } }	# ok +
			# tramo E 
			at(t(215,0), debug: @debug_at) 	{ @end_voices.apply :pitch=, [24, 24, 24, 24, 24].collect { |p| s(p) } }	# 
			at(t(218,0), debug: @debug_at) 	{ @end_voices.apply :pitch=, [22, 20, 20, 20, 20].collect { |p| s(p) } }	# 
			at(t(221,0), debug: @debug_at) 	{ @end_voices.apply :pitch=, [24, 24, 24, 24, 24].collect { |p| s(p) } }	# 
			at(t(224,0), debug: @debug_at) 	{ @end_voices.apply :pitch=, [20, 20, 20, 20, 20].collect { |p| s(p) } }
			# tramo F
			at(t(227,0), debug: @debug_at) 	{ @end_voices.apply :pitch=, [22, 20, 20, 20, 20].collect { |p| s(p) } }
			at(t(233,0), debug: @debug_at) 	{ @end_voices.apply :pitch=, [24, 24, 17, 24, 17].collect { |p| s(p) } }
			at(t(238,0), debug: @debug_at) 	{ @end_voices.apply :pitch=, [24, 24, 24, 24, 24].collect { |p| s(p) } }
		end

		at t(230,0), debug: @debug_at do
			@voice_low[0].input_channel = 1
			@voice_low[0].output_channel = 1
			@voice_low[0].pitch = s(-48)

			move_vol @voice_low[0], to: -3, till: t(247,0)
		end

		at t(253,0), debug: @debug_at do
			move_vol @voice_low[0], to: 3, till: t(261,0)
		end

		#
		# Pitidos de finalización
		#

		at t(257,0) do
			@end_voices.apply :vol=, -40
			@voice_mid[2].pitch = 0
			@voice_mid[2].vol = -3
		end

		at t(261,8) do
			@voice_low[0].vol = -40
		end

		at(t(265,0), debug: @debug_at) do
			@all_voices.each do |v|
				move_vol v, to: -40, duration: t(1,0)
			end
		end
	end
end
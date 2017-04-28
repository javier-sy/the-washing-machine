require 'musa-dsl'

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

		puts "\nposition = #{position} till = #{till}"
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

	def run(till:, wait_duration:, pitch_1:, pitch_2:, next_position:)
		log "Theme_2: running till #{till} pitch_1: #{pitch_1} pitch_2: #{pitch_2} next_position: #{next_position}"

		@voice_1.pitch = pitch_1
		
		move_vol_twice @voice_1, to: -15, duration: t(1,14), wait_duration: wait_duration, to_2: -40, till_2: till + @post_offset_1

		if next_position
			at till - @pre_offset_2, debug: @debug_at do
				@voice_2.pitch = pitch_2
				move_vol_twice @voice_2, to: 6, duration: t(1,0), wait_duration: wait_duration, to_2: -40, till_2: next_position + @pre_offset_1 + @post_offset_2
			end
		end
	end
end

class Theme_3 < Musa::Theme
	def initialize(context, voice:, pre_offset:, post_offset:)
		super context

		@voice = voice
		@pre_offset = pre_offset
		@post_offset = post_offset
	end

	def at_position(p, **parameters)
		p - @pre_offset
	end

	def run(pitch:, frequency:, till:, next_position:)

		log "Theme_3: running till: #{till} pitch: #{pitch} frequency: #{frequency} next_position: #{next_position}"

		original_pitch = @voice.pitch

		move_vol_forth_and_back @voice, to: -3, till: (position + till) / 2, back_at: till + @post_offset

		@voice.pitch = pitch
		m = move_pitch_sin @voice, frequency: frequency, amplitude: s(Rational(1,3)), till: till + @post_offset

		m.after do
			@voice.pitch = original_pitch
		end
	end
end

class Theme_3_A < Musa::Theme
	def initialize(context, voice:, pre_offset:, post_offset:)
		super context

		@voice = voice
		@pre_offset = pre_offset
		@post_offset = post_offset
	end

	def at_position(p, **parameters)
		p - @pre_offset
	end

	def run(pitch:, frequency:, till:, next_position:)

		log "Theme_3: running till: #{till} pitch: #{pitch} frequency: #{frequency} next_position: #{next_position}"

		original_pitch = @voice.pitch

		move_vol_forth_and_back @voice, to: -3, till: (position + till) / 2, back_at: till + @post_offset

		@voice.pitch = pitch
		m = move_pitch_sin @voice, frequency: frequency, amplitude: s(Rational(1,3)), till: till + @post_offset

		m.after do
			@voice.pitch = original_pitch
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
		
		@voice_low << voices.voice(index: 0, input_channel: 0, output_channel: 0, midi_channel: 0, cc_vol: 8, cc_wsize: 4, cc_pitch: 0)
		@voice_low << voices.voice(index: 1, input_channel: 0, output_channel: 1, midi_channel: 0, cc_vol: 9, cc_wsize: 5, cc_pitch: 1)

		@voice_mid << voices.voice(index: 2, input_channel: 0, output_channel: 2, midi_channel: 3, cc_vol: 8, cc_wsize: 4, cc_pitch: 0)
		@voice_mid << voices.voice(index: 3, input_channel: 0, output_channel: 3, midi_channel: 3, cc_vol: 9, cc_wsize: 5, cc_pitch: 1)
		@voice_mid << voices.voice(index: 4, input_channel: 0, output_channel: 4, midi_channel: 3, cc_vol: 10, cc_wsize: 6, cc_pitch: 2)
		@voice_mid << voices.voice(index: 5, input_channel: 0, output_channel: 5, midi_channel: 3, cc_vol: 11, cc_wsize: 7, cc_pitch: 3)

		@voice_high << voices.voice(index: 6, input_channel: 0, output_channel: 6, midi_channel: 5, cc_vol: 8, cc_wsize: 4, cc_pitch: 0)
		@voice_high << voices.voice(index: 7, input_channel: 0, output_channel: 7, midi_channel: 5, cc_vol: 9, cc_wsize: 5, cc_pitch: 1)
		@voice_high << voices.voice(index: 8, input_channel: 0, output_channel: 8, midi_channel: 5, cc_vol: 10, cc_wsize: 6, cc_pitch: 2)
		@voice_high << voices.voice(index: 9, input_channel: 0, output_channel: 9, midi_channel: 5, cc_vol: 11, cc_wsize: 7, cc_pitch: 3)

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
			@voice_mid[1].vol = 0

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
			move_vol @voice_high[0], to: 0, till: 11
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
			move_vol @voice_mid[1], till: 30, to: -3
		end

		at 31, debug: @debug_at do
			@voice_high[0].pitch = s(16)
			move_vol @voice_high[0], till: 34, to: 0
		end

		at 34.75, debug: @debug_at do
			move_vol @voice_low[0], till: 37, to: -40
			move_vol @voice_high[0], till: 37, to: -3

			move_pitches @all_voices, till: 37, to: @pitches
		end

		at 37, debug: @debug_at do
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
		#
		#

		at t(61,15), debug: @debug_at do
			move_vol_twice @voice_low[0], to: 6, till: t(66,8), wait_duration: -t(2,8), to_2: -40, till_2: t(69,14)
		end

		# TODO revisar wait_duration
		theme Theme_2,
		at:		S(t(69,14),	t(82,11), 	t(90,11), 	t(103,7), 	t(111,7), 	t(124,3), 	t(132,3), 	t(145,0), 	t(152,15), 	t(165,12), 	t(178,1), 	t(186,0), 	t(195,12), 	t(203,11), 	t(213,6), 	t(221,5), 	t(231,1), 	t(239,0), 	t(248,11), 	t(256,11)), 
		till: 	S(t(78,12),	t(87,11), 	t(99,10),	t(108,8),	t(120,6),	t(129,3),	t(141,3),	t(150,0),	t(161,15),	t(174,4),	t(183,1), 	t(191,15), 	t(200,13), 	t(209,10), 	t(218,7), 	t(227,4), 	t(236,2), 	t(244,15), 	t(253,12), 	t(262,14)),
		wait_duration:
			  	S(-t(1,8),	-t(1,8),	-t(1,4),	-t(1,4),	-t(1,0),	-t(1,0),	-t(0,8),	-t(0,8),	-t(1,8),	-t(1,8),  	-t(1,8),  	-t(1,8),  	-t(1,8),  	-t(1,8),  	-t(1,8),  	-t(1,8),  	-t(1,8),  	-t(1,8),  	-t(1,8),  	-t(1,8)),

		voice_1: @voice_low[1], 
		pitch_1: E { |i| s(-48 + 2 * (i % 5)) },

		voice_2: @voice_low[0],
		pitch_2: E { |i| s(24 - (Rational(i + 1, 3) % 5)) },

		pre_offset_1: t(1,8),
		post_offset_1: t(0,8),
		pre_offset_2: t(0,0),
		post_offset_2: t(0,4)

		at 82 do
			log
			@voice_mid[1].input_channel = 1
			@voice_high[1].input_channel = 1
		end

		theme Theme_3,
		at:		S(t(82,7), 	t(94,13), 	t(102,12), 	t(112,7), 	t(120,6), 	t(130,2), 	t(138,1), 	t(147,13), 	t(155,11), 	t(165,7), t(173,6), t(183,2), t(191,1), t(200,12), t(208,11), t(218,7), t(226,6), t(236,1), t(244,1), t(253,12), t(261,11),	t(271,7),	t(279,6)),
		till: 	S(t(90,15), t(99,13),	t(106,10),	t(117,7),	t(126,5),	t(135,3),	t(143,15),	t(152,13),	t(161,10),	t(170,7), t(179,4), t(188,3), t(197,0), t(205,13), t(214,11), t(223,8), t(232,5), t(241,3), t(250,0), t(258,13), t(267,11),	t(276,8),	t(285,5)),
		voice: @voice_high[1],
		pitch: E { |i| s(22 - (Rational(i + 1, 3) % 5)) },
		frequency: SIN(start_value: 28.0, steps: 11, period: 1, amplitude: 15.0, center: 28.0),
		pre_offset: t(1,0),
		post_offset: t(1,0)

		at 118 do
			log
			@voice_mid[2].input_channel = 2
			@voice_high[2].input_channel = 2
		end

		theme Theme_3,
		at:		S(t(118,9), t(128,5),	t(136,4),	t(145,15),	t(153,14),	t(162,10),	t(171,9),	t(181,4),	t(189,4),	t(198,15),	t(206,14),	t(216,10),	t(224,9),	t(234,4),	t(242,3),	t(251,15),	t(259,14),	t(269,9),	t(277,9),	t(287,4),	t(295,3),	t(304,15),	t(312,14)),
		till: 	S(t(124,7), t(133,5), 	t(142,2),	t(150,15),	t(159,12),	t(168,10),	t(177,7),	t(186,5),	t(195,3),	t(203,15),	t(212,13),	t(221,11),	t(230,8),	t(239,5),	t(248,3),	t(256,16),	t(265,13), 	t(274,10),	t(283,8),	t(292,5),	t(301,3),	t(309,16),	t(318,13)),
		voice: @voice_high[2],
		pitch: E { |i| s(18 - (Rational(i + 1, 3) % 3)) },
		frequency: R(S(28)),
		pre_offset: t(1,0),
		post_offset: t(1,0)

		at 149 do
			log
			@voice_mid[3].input_channel = 3
			@voice_high[3].input_channel = 3
		end

		theme Theme_3,
		at:		S(t(149,9),	t(159,4),	t(167,4),	t(176,15),	t(194,10), 	t(202,9), 	t(212,4), 	t(220,3), 	t(229,15), 	t(237,14), 	t(247,10), 	t(255,4), 	t(265,4), 	t(273,3), 	t(282,15),	t(290,14),	t(300,9),	t(308,9),	t(318,4),	t(326,3),	t(353,15),	t(343,14)),
		till: 	S(t(155,7),	t(164,4),	t(173,2),	t(181,15),	t(199,11), 	t(208,7), 	t(217,5), 	t(226,2), 	t(234,16), 	t(243,13), 	t(252,10), 	t(261,8), 	t(270,5), 	t(279,2), 	t(287,16),	t(296,13),	t(305,10),	t(314,7),	t(323,5),	t(332,13),	t(340,16),	t(349,13)),
		voice: @voice_high[3],
		pitch: E { |i| s(14 - (Rational(i + 1, 3) % 7)) },
		frequency: R(S(28)),
		pre_offset: t(1,0),
		post_offset: t(1,0)
	end
end
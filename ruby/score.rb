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

	@@OFFSET = t(1,0)

	def initialize(context, voice:, voice_2:)
		super context
		@voice = voice
		@voice_2 = voice_2
	end

	def at_position(p, **parameters)
		p - @@OFFSET
	end

	def run(at:, pitch:, mid_pitch_offset:, till:, next_position:)
		log "Theme_3: running at: #{at} till: #{till} pitch: #{pitch} mid_pitch_offset: #{mid_pitch_offset} next_position: #{next_position}"

		@voice.pitch = pitch

		third = (till - at) / 3

		move_vol_twice @voice, to: -3, till: at + third, wait_duration: third, to_2: -40, till_2: till + @@OFFSET

		self.at at + third do
			move_pitch_forth_and_back @voice, to: pitch + mid_pitch_offset, till: at + 2*third, back_at: at + 2*third + t(0,8)
			#move_pitch_and_return @voice, to: pitch + mid_pitch_offset, till: at + 2*third, return_at: at + 2*third + t(0,8)
		end

		if next_position
			delta = (next_position - till)/8
			self.at till - delta do
				@voice_2.pitch = s(24) + mid_pitch_offset
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
		at:		S(t(69,14),	t(82,11), 	t(90,11), 	t(103,7), 	t(111,7), 	t(124,3), 	t(132,3), 	t(145,0), 	t(152,15), 	t(165,12), 	t(178,1)), 
		till: 	S(t(78,12),	t(87,11), 	t(99,10),	t(108,8),	t(120,6),	t(129,3),	t(141,3),	t(150,0),	t(161,15),	t(174,4),	t(183,1)),
		wait_duration:
			  	S(-t(1,8),	-t(1,8),	-t(1,4),	-t(1,4),	-t(1,0),	-t(1,0),	-t(0,8),	-t(0,8),	-t(1,8),	-t(1,8),  	-t(1,8)),

		voice_1: @voice_low[1], 
		pitch_1: E { |i| s(-48 + 2 * (i % 5)) },

		voice_2: @voice_low[0],
		pitch_2: E { |i| s(24 - (Rational(i + 1, 3) % 5)) },

		pre_offset_1: t(1,8),
		post_offset_1: t(0,8),
		pre_offset_2: t(0,0),
		post_offset_2: t(0,4)


		# poner 4 voces: B, C, D, E; 1º B en coincidencia con Corpus metal de A; luego C en oposición a B, luego D y E entre B y C
		# al comenzar C (quizás D y E) desactivar en Theme 2 la parte sin corpus


		at 80 do
			log

			@voice_mid[0].input_channel = 1
			@voice_high[0].input_channel = 1

			@voice_mid[1].input_channel = 2
			@voice_high[1].input_channel = 2

			@voice_mid[2].input_channel = 3
			@voice_high[2].input_channel = 3

			@voice_mid[3].input_channel = 4
			@voice_high[3].input_channel = 4
		end

		# TODO en theme3 poner algo más entre medio de lo silencios

		theme Theme_3,
		at:		S(	t(82,7), 	t(94,13), 	t(102,12), 	t(112,7), 	t(120,6), 	t(130,2), 	t(138,1), 	t(147,13), 	t(155,11), 	t(165,7), t(173,6), t(183,2)),
		till: 	S(	t(90,16), 	t(99,13),	t(108,11),	t(117,7),	t(126,5),	t(135,3),	t(143,15),	t(152,13),	t(161,10),	t(170,7), t(179,4), t(188,3)),
		voice: 	@voice_high[0],
		voice_2: @voice_mid[0],
		pitch: 	E(R(S(4,3, 2, 1,-1))) { |i| s(22 - i) },
		mid_pitch_offset: R(S(s(-2), s(-1), s(-1)))

		theme Theme_3,
		at:  	S(	t(116,2),	t(125,14), 	t(133,13), 	t(143,8), 	t(151,7), 	t(160,3), 	t(169,2), 	t(178,13)),
		till: 	S(	t(122,1),	t(130,13), 	t(139,11), 	t(148,8), 	t(157,5), 	t(166,3), 	t(175,0), 	t(183,14)),
		voice: 	@voice_high[1],
		voice_2: @voice_mid[1],
		pitch: 	E(R(S(4,3,2,1,-1))) { |i| s(18 - i) },
		mid_pitch_offset: R(S(s(-2), s(-1), s(0), s(-1)))

		theme Theme_3,
		at:		S(	t(149,8),	t(159,3),	t(167,3),	t(176,14)),
		till: 	S(	t(155,7),	t(164,3),	t(173,1),	t(181,14)),
		voice: 	@voice_high[2],
		voice_2: @voice_mid[2],
		pitch: 	E(R(S(4,3,2,1,-1))) { |i| s(14 - i) },
		mid_pitch_offset: R(S(s(-1), s(-3)))

		theme Theme_3,
		at:		S(	t(153,10),	t(163,5), 	t(171,5), 	t(181,0)),
		till: 	S(	t(159,9), 	t(168,5), 	t(177,3), 	t(186,0)),
		voice: 	@voice_high[3],
		voice_2: @voice_mid[3],
		pitch: 	E(R(REV(S(3,2,1,-1)))) { |i| s(16 - i) },
		mid_pitch_offset: R(S(s(-5), s(-3), s(-1)))

		# TODO recortar centrifugado

	end
end
require 'musa-dsl'

require_relative '../abstraction'

include Musa::Series

puts "Score loaded: file loaded"

def score
	puts "Score loaded: defining score"


	scale = Musa::Scales.get(:major).based_on_pitch 65

	s = @transport.sequencer

	@debug_at = true

	s.with @voices do |voices|

		voices.reset

		@voice_low = []
		@voice_mid = []
		@voice_high = []
		
		@voice_low << voices.voice(0)
		@voice_low << voices.voice(1)

		@voice_mid << voices.voice(2)

		@voice_high << voices.voice(3)

		@voice_low[0].name = "LOW 0"
		@voice_low[1].name = "LOW 1"

		@voice_mid[0].name = "MID 0"

		@voice_high[0].name = "HIGH 0"

		@all_voices = @voice_low + @voice_mid + @voice_high
	end

	s.with do

=begin
		at 4, debug: @debug_at do
			@voice_low[0].note 62, duration: Rational(1, s.ticks_per_bar)
			v = @voice_low[0].note 65, duration: t(1,0)

			v.after do
				@voice_low[0].note 66, duration: t(1,0)
			end
		end
=end
		at [1, 2, 3], debug: true do

			puts "Hola"
		end

		at 1, debug: @debug_at do
			serie = R(S(
				{ pitch: 34, duration: t(0,8), velocity: 70 }, 
				{ pitch: [33, 35, 37], duration: t(0,4), velocity: 70 },
				{ pitch: [33, 35, 37], duration: 1, velocity: 110 }, 
				{ pitch: :silence, duration: t(0,8), velocity: 100}, 
				{ pitch: [34, 38, 28], duration: t(0,8), velocity: 50 }))

			serie2 = H(
				pitch: R(S(32,33, :silence, 35, 31)), 
				duration: R(S(t(0,4), t(0,3), t(0,9))), 
				velocity: R(S(50, 60, 70)))

			serie3 = H(
				pitch: R(S(65,67,68,45, 59, :silence, 53)), 
				duration: R(S(t(0,2), t(0,6), t(0,18))), 
				velocity: R(S(50, 60, 65, 70)))
			
			#serie4 = H( pitch: SEL(R(S(:a,:b,:c), times: 2), a: R(S(30,31,32), times: 2), b: R(S(50,51,52), times: 2), c: R(S(70,71,72), times: 2)), duration: R(S(t(0,8)) ) )
			serie4 = H( pitch: SEQ(R(S(30,31,32), times: 2), R(S(50,51,52), times: 2), R(S(70,71,72), times: 2)), duration: R(S(t(0,8)) ) )

			#serie5 = H( pitch: RND(from: 65, to: 82), duration: R(S(t(0,8))))
			#serie5 = H( pitch: RND(from: 60, to: 63, step: 0.31), duration: R(S(t(0,8))))
			serie5 = H( pitch: RND(65, 66, 67, 70..73, 78), duration: R(S(t(0,8))))

			serieX = R(FOR(from: 2, to: 5))
			serie6 = H( pitch: E(RND(:I, :IV, :VI, :V, :III)) { |grade| Musa::Chord(grade, scale: scale, grades: serieX.next_value).pitches }, duration: RND(from: t(0,2), to: t(1), step: t(0,1)) )

			serieZ = RND(from: t(0,2), to: t(1), step: t(0,1))


			maxi = S(serie, serie2, serie3)

			serie7 = SEQ(*maxi.as_array)

			play(serie) { |n| @voice_low[0].note **n }

			play(serie2) { |n| @voice_low[0].note **n }
			play(serie3) { |n| @voice_low[1].note **n }
			
			play(serie4) { |n| @voice_low[0].note **n }


			play(serie5) { |n| @voice_low[0].note **n }
			play(serie6) { |n| @voice_low[0].note **n }

			#play(serie7) { |n| @voice_low[0].note **n }
		end
	end
end


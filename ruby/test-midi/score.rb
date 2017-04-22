require_relative '../music/music'
require_relative '../abstraction'

include Series

puts "Score loaded: file loaded"

def score
	puts "Score loaded: defining score"

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
		at 1, debug: @debug_at do
			serie = S([
				{ pitch: 33, duration: 1 }, 
				{ pitch: 34, duration: t(0,8) }, 
				{ pitch: nil, duration: t(0,8)}, 
				{ pitch: 34, duration: t(0,8) }
				])

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

			play(serie2) { |n| @voice_low[0].note **n }
			play(serie3) { |n| @voice_low[1].note **n }
			
			play(serie4) { |n| @voice_low[0].note **n }
		end
	end
end


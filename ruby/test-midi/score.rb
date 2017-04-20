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
		at 1, debug: @debug_at do
			@voice_low[0].note 62, duration: Rational(1, s.ticks_per_bar)
			v = @voice_low[0].note 65, duration: t(1,0)

			v.after do
				@voice_low[0].note 66, duration: t(1,0)
			end
		end
	end
end
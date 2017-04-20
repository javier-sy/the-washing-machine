
require_relative 'music/music'

Scales.register :major_1, 
	ScaleDef("Major 100 cents", Rational(1),
		symbols: { I: 0, II: 1, III: 2, IV: 3, V: 4, VI: 5, VII: 6, VIII: 7, IX: 8, X: 9, XI: 10 },
		offsets: [ Rational(0), Rational(2,12), Rational(4,12), Rational(5,12), Rational(7,12), Rational(9,12), Rational(11,12)])

Scales.register :minor_1, 
	ScaleDef("Minor 100 cents", Rational(1),
		symbols: { I: 0, II: 1, III: 2, IV: 3, V: 4, VI: 5, VII: 6, VIII: 7, IX: 8, X: 9, XI: 10 },
		offsets: [ Rational(0), Rational(2,12), Rational(3,12), Rational(5,12), Rational(7,12), Rational(8,12), Rational(10,12)])

Scales.register :major_20c, 
	ScaleDef("Major 20 cents", 12 * 5,
		symbols: { I: 0, II: 1, III: 2, IV: 3, V: 4, VI: 5, VII: 6, VIII: 7, IX: 8, X: 9, XI: 10 },
		offsets: [ 0, 2 * 5, 4 * 5, 5 * 5, 7 * 5, 9 * 5, 11 * 5])

Scales.register :minor_20c, 
	ScaleDef("Minor 20 cents", 12 * 5,
		symbols: { I: 0, II: 1, III: 2, IV: 3, V: 4, VI: 5, VII: 6, VIII: 7, IX: 8, X: 9, XI: 10 },
		offsets: [ 0, 2 * 5, 3 * 5, 5 * 5, 7 * 5, 8 * 5, 10 * 5])


def score
	ts = @transport.sequencer

	ts.with @voices do |voices|

		@voice = []
		
		@voice << voices.voice(index: 0, channel: 0, cc_vol: 8, cc_wsize: 4, cc_pitch: 0)
		@voice << voices.voice(index: 1, channel: 0, cc_vol: 9, cc_wsize: 5, cc_pitch: 1)
		@voice << voices.voice(index: 2, channel: 0, cc_vol: 10, cc_wsize: 6, cc_pitch: 2)
		@voice << voices.voice(index: 3, channel: 0, cc_vol: 11, cc_wsize: 7, cc_pitch: 3)

		@voice.each do |v| 
			v.sel = 0
			v.set vol: -60, wsize: 0, pitch: 0 
		end
	end

	ts.with do
	
		@scale1 = Scales.get(:minor_1).based_on_pitch 1

		@I_i1_1 	= Chord :I,		scale: @scale1, 	inversion: 1,				duplicate: { position: 2, octaves: -1 }
		@I_i1_1b 	= Chord :I,		scale: @scale1, 	inversion: 1,				duplicate: { position: 2, octaves: 0 }, sort: true

		@IV_i1_1 	= Chord :IV,	scale: @scale1, 	inversion: 1,				duplicate: { position: 1, octaves: 0, to_voice: 0 }
		@V_i1_1 	= Chord :V,		scale: @scale1, 	inversion: 1, 	octave: -1,	duplicate: { position: 1, octaves: -1, to_voice: 0 }

		puts "@I_i1_1     = #{@I_i1_1}"
		puts "@I_i1_1b    = #{@I_i1_1b}"
		puts "@IV_i1_1    = #{@IV_i1_1}"
		puts "@V_i1_1     = #{@V_i1_1}"
		
		@scale20c = Scales.get(:minor_20c).based_on_pitch 75

		@I_i1_20c	= Chord :I, 	scale: @scale20c,	inversion: 1,	duplicate: { position: 0, octaves: -2, to_voice: 0 }
		@III_20c 	= Chord :III, 	scale: @scale20c,					duplicate: { position: 0, octaves: -1, to_voice: 0 }

		puts "@I_i1_20c   = #{@I_i1_20c}"
		puts "@III_20c    = #{@III_20c}"


		at 1 do 
			puts "En #{position.to_f}"
			@voice.apply :wsize=, @I_i1_20c.pitches
			@voice.apply :pitch=, @scale1.pitch_of_grade(:I, octave: 1)

			move(till: 1.25, from: @voice.get(:vol), to: 0) { |v| @voice.apply :vol=, v }
		end

		at 5 do 
			puts "En #{position.to_f}"
			move(till: 9 + Rational(15,16), 
				from: @voice.get(:wsize), 
				to: @III_20c.pitches) { |pitches| @voice.apply :wsize=, pitches }
		end

		at 9 + Rational(15,16) do
			puts "En #{position.to_f}"
			move(till: 12 + Rational(9, 16), 
				from: @voice.get(:pitch), 
				to: @I_i1_1.pitches, 
				step: Rational(1,96)) { | rates | @voice.apply :pitch=, rates }
		end

		at 12 + Rational(9, 16) do
			puts "En #{position.to_f}"

			@pitches = @voice.get :pitch
			puts "@pitches = #{@pitches}"

			@voice[0].pitch = @scale1.pitch_of_grade :I, octave: -1

			@voice[0].vol = 6
			@voice[1].vol = @voice[2].vol = @voice[3].vol = -40
		end

		at 17.25 do 
			@voice.apply :pitch=, @pitches

			puts "En #{position.to_f}"
			puts "Desde pitch: #{@pitches} hasta 34.75 con sin"

			move(          till: 21.0, from: @voice[0].vol, to: 0) {|v| @voice[0].vol = v}
			move(at: 18.0, till: 19.0, from: @voice[3].vol, to: 0) {|v| @voice[3].vol = v}
			move(at: 19.0, till: 21.0, from: @voice[2].vol, to: 0) {|v| @voice[2].vol = v}
			move(at: 21.0, till: 23.0, from: @voice[1].vol, to: 0) {|v| @voice[1].vol = v}
		end

		at 19.125 do

			@mul = [2, 2, 1, 4]
			@cycles = [1.1, 0.5, 2.9, 2]


			move till: 34.75, from: @pitches, 
				using_init: ->(steps:) {
					@sin = @mul.each_index.collect { |i| 
						Sin(start_value: @pitches[i], 
							steps: steps, 
							cycles: @cycles[i], 
							mul: Rational(@mul[i],12), 
							add: @pitches[i] - (@pitches[i] > 1.9 ? Rational(@mul[i], 12) : 0)) } },

				using: ->() { @sin.get :value } do |p|

				@voice.apply :pitch=, p 
			end
		end

		at 34.75 do

			every 1, till: 50 do

			end
		end
	end
end
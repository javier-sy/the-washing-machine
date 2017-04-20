
require_relative 'music/music'


Scales.register :major_1, 
	ScaleDef("Major 100 cents", Rational(1),
		symbols: { I: 0, II: 1, III: 2, IV: 3, V: 4, VI: 5, VII: 6, VIII: 7, IX: 8, X: 9, XI: 10 },
		offsets: [ Rational(0), Rational(2,12), Rational(4,12), Rational(5,12), Rational(7,12), Rational(9,12), Rational(11,12)])


def score
	ts = @transport.sequencer

	ts.with @voices do |voices|

		@voice = []
		
		@voice << voices.voice(index: 0, input_channel: 0, output_channel: 0, midi_channel: 0, cc_vol: 8, cc_wsize: 4, cc_pitch: 0)
		@voice << voices.voice(index: 1, input_channel: 0, output_channel: 1, midi_channel: 0, cc_vol: 9, cc_wsize: 5, cc_pitch: 1)
		@voice << voices.voice(index: 2, input_channel: 0, output_channel: 2, midi_channel: 0, cc_vol: 10, cc_wsize: 6, cc_pitch: 2)
		@voice << voices.voice(index: 3, input_channel: 0, output_channel: 3, midi_channel: 0, cc_vol: 11, cc_wsize: 7, cc_pitch: 3)

		@voice2 = voices.voice(index: 4, input_channel: 0, output_channel: 4, midi_channel: 3, cc_vol: 8, cc_wsize: 4, cc_pitch: 0)
		@voice3 = voices.voice(index: 5, input_channel: 0, output_channel: 5, midi_channel: 3, cc_vol: 9, cc_wsize: 5, cc_pitch: 1)

		@voice2.vol = @voice3.vol = -120

		@sw_low = Scales.get(:major_1).based_on_pitch Rational(8,12)
		@sw = @sw_low.based_on :IV, octave: 0

		puts "sw_low :I = #{@sw_low.pitch_of_grade(:I).to_f}"
		puts "sw_low :VIII = #{@sw_low.pitch_of_grade(:VIII).to_f}"
		puts "sw_low :V octave 1 = #{@sw_low.pitch_of_grade(:V, octave: 1).to_f}"
		puts "sw_low :VI octave 1 = #{@sw_low.pitch_of_grade(:VI, octave: 1).to_f}"
		puts "sw_low :VII octave 1 = #{@sw_low.pitch_of_grade(:VII, octave: 1).to_f}"
		puts "sw_low :VIII octave 1 = #{@sw_low.pitch_of_grade(:VIII, octave: 1).to_f}"
		puts "sw :I = #{@sw.pitch_of_grade(:I).to_f}"
		puts "sw :VIII = #{@sw.pitch_of_grade(:VIII).to_f}"


		@wI = 		Chord :I, 	scale: @sw, 							duplicate: { position: 0, octaves: 1 }, 	sort: true
		@wVI_i2 = 	Chord :VI, 	scale: @sw, octave: -1,	inversion: 2, 	duplicate: { position: 1, octaves: -1 }, 	sort: true
		@wII7 = 	Chord :II, 	scale: @sw, grades: 4, 																sort: true

		@wVI = 		Chord :VI, 	scale: @sw, 							duplicate: { position: 2, octaves: -1 },	sort: true

		puts "@wI = #{@wI.voices.sort}"
		puts "@wVI_i2 = #{@wVI_i2.voices.sort}"
		puts "@wII7 = #{@wII7.voices.sort}"

		puts "@wVI = #{@wVI.voices.sort}"

		@sp = Scales.get(:major_1).based_on_pitch Rational(8,12)

		@pI = 		Chord :I, 	scale: @sp, 							duplicate: { position: 0, octaves: 1 }, 	sort: true

		@pIV = 		Chord :IV,	scale: @sp, 							duplicate: { position: 2, octaves: -1 }, 	sort: true
		@pV = 		Chord :V,	scale: @sp, 							duplicate: { position: 2, octaves: -1 }, 	sort: true
		@pVI = 		Chord :VI, 	scale: @sp, 							duplicate: { position: 2, octaves: -1 }, 	sort: true

		@pIII_i2 =	Chord :III,	scale: @sp, octave: 0, 	inversion: 1, 	duplicate: { position: 2, octaves: -1 }, 	sort: true
		@pIV_i2 = 	Chord :IV, 	scale: @sp, octave: 0,	inversion: 0,	duplicate: { position: 2, octaves: -1 }, 	sort: true
		@pV_i2 = 	Chord :V, 	scale: @sp, octave: 0,	inversion: 0, 	duplicate: { position: 2, octaves: -1 }, 	sort: true
		@pVI_i2 = 	Chord :VI, 	scale: @sp, octave: -1, inversion: 2, 	duplicate: { position: 1, octaves: -1 }, 	sort: true

		@pII7 = 	Chord :II, 	scale: @sp, grades: 4, 																sort: true

		puts "@pI = #{@pI.pitches.sort.get :to_1s}"
		puts "@pIV = #{@pIV.pitches.sort.get :to_1s}"
		puts "@pV = #{@pV.pitches.sort.get :to_1s}"
		puts "@pVI = #{@pVI.pitches.sort.get :to_1s}"

		puts "@pII7 = #{@pII7.pitches.sort.get :to_1s}"

		puts "@pIII_i2 = #{@pIII_i2.pitches.sort.get :to_1s}"
		puts "@pIV_i2 = #{@pIV_i2.pitches.sort.get :to_1s}"
		puts "@pV_i2 = #{@pV_i2.pitches.sort.get :to_1s}"
		puts "@pVI_i2 = #{@pVI_i2.pitches.sort.get :to_1s}"


	end

	ts.with do
		every 1/8.0 do
			@voice.each do |v|
				#puts "#{v.to_s}"
			end
		end

		at 1 do
			log
			@voice.apply :wsize=, @wI.pitches
			@voice.apply :pitch=, @pI.pitches
		end

		at 5 do 
			log
			move(till: 9 + Rational(13, 16), from: @voice.get(:pitch), to: @pVI_i2.pitches, step: Rational(1,84)) { |p| @voice.apply :pitch=, p }
		end

		at 9 + Rational(13,16) do
			log
			move(till: 11 + Rational(7, 16), from: @voice.get(:pitch), to: @pII7.pitches, step: Rational(1,84)) { | p | @voice.apply :pitch=, p }
		end

		at 11 + Rational(7,16) do
			log
			move(till: 12 + Rational(10, 16), from: @voice.get(:pitch), to: @pIV.pitches, step: Rational(1,84)) { | p | @voice.apply :pitch=, p }
		end


		at 12 + Rational(10, 16) do
			log

			@pitches = @voice.get :pitch

			@voice[0].pitch = @sp.pitch_of_grade :III, octave: -1
			@voice[0].vol = 3

			@voice[1].vol = @voice[2].vol = @voice[3].vol = -40
		end

		at 16 do
			log
			@voice2.set vol: -120, wsize: @sw_low.pitch_of_grade(:I), pitch: @sp.pitch_of_grade(:III, octave: 1)
		end

		at 17.25 do 
			log

			move(duration: 0.5, from: @voice2.vol, to: 0) { |v| @voice2.vol = v }

			@voice.apply :pitch=, @pitches

			move(          till: 25.0, from: @voice[0].vol, to: -6)	{|v| @voice[0].vol = v}
			move(at: 20.0, till: 27.0, from: @voice[3].vol, to: 0) 	{|v| @voice[3].vol = v}
			move(at: 25.0, till: 32.0, from: @voice[2].vol, to: 0) 	{|v| @voice[2].vol = v}
			move(at: 30.0, till: 37.0, from: @voice[1].vol, to: -3)	{|v| @voice[1].vol = v}
		end

		at 19.125 do
			log

			move(duration: 14, from: @voice2.vol, to: -12) { |v| @voice2.vol = v }

			@mul = [0.9, 0.3, 0.7, 0.1]
			@cycles = [1, 3, 2, 5]

			move till: 34.75, 
				from: @pitches, 
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
			log
			move(till: 35, from: @voice2.vol, 			to: -120) 		{ |v| @voice2.vol = v }
			move(till: 35, from: @voice.get(:pitch), 	to: @pitches) 	{ |p| @voice.apply :pitch=, p }
		end

		at 37 do
			log
			@voice.apply :pitch=, @pV_i2.pitches
		end

		at 39 do
			log
			@voice.apply :pitch=, @pVI_i2.pitches
		end

		at 41 do
			log
			@voice.apply :pitch=, @pIV_i2.pitches
		end

		at 43 do
			log
			@voice.apply :pitch=, @pV_i2.pitches
		end

		at 45 do
			log
			@voice.apply :pitch=, @pVI_i2.pitches
		end

		at 47 do
			log
			@voice.apply :pitch=, @pII7.pitches
		end

		at 49 do
			log
			@voice.apply :pitch=, @pIII_i2.pitches
		end

		at 51 do
			log
			@voice.apply :pitch=, @pV_i2.pitches
		end

		at 53 do
			log
			@voice.apply :pitch=, @pVI_i2.pitches
		end

		at 55 do
			log
			@voice.apply :pitch=, @pIV_i2.pitches
		end

		at 57 do
			log
			@voice.apply :pitch=, @pV_i2.pitches
		end

		at 59 do
			log
			@voice.apply :pitch=, @pI.pitches
		end









		at 82 do
			log
			@voice[1].input_channel = 1
		end

		at 118 do
			log
			@voice[2].input_channel = 2
		end

		at 149 do
			log
			@voice[3].input_channel = 3
		end
	end
end
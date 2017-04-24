require 'musa-dsl'

class Voices

	def initialize(mirror_in: nil, mirror_out: nil, output:, voices: 4, wsize_base: 1/20.0, wsize_semitones: 24)

		@mirror_in = mirror_in
		@mirror_out = mirror_out

		@output = output

		@voice_count = voices

		@wsize_base = wsize_base.to_f
		@wsize_semitones = wsize_semitones.to_i

		@output.send OSC::Message.new("/init", @voice_count)

		reset
	end

	def reset
		@mirror_thread.exit if @mirror_thread

		@voices = []
		@cc_setter = {}

		if @mirror_in
			@mirror_thread = Thread.new do

				nibbler = Nibbler.new

				@mirror_in.open do |input|
					while true do
						input.gets.each do |m|

							if m[:data].size > 0

								message = nibbler.parse(*m[:data])

								if message && message.kind_of?(MIDIMessage::ControlChange)
									setter = @cc_setter.dig message.channel, message.index
									setter.call message.value if setter
								end
							end
						end
					end
				end
			end
		end
	end

	def voice(index:, midi_channel:, input_channel: 0, output_channel: 0, cc_vol:, cc_wsize:, cc_pitch:, silence_offset: -40)

		voice = 
			Voice.new(
				mirror_out: @mirror_out, output: @output, 
				index: index, midi_channel: midi_channel, input_channel: input_channel, output_channel: output_channel, 
				cc_vol: cc_vol, cc_wsize: cc_wsize, cc_pitch: cc_pitch, 
				wsize_base: @wsize_base, wsize_semitones: @wsize_semitones,
				silence_offset: silence_offset)
		
		@voices << voice

		@cc_setter[midi_channel] ||= {}
		@cc_setter[midi_channel][cc_vol] = ->(v){ voice.vol127 = v }
		@cc_setter[midi_channel][cc_wsize] = ->(v){ voice.wsize127 = v }
		@cc_setter[midi_channel][cc_pitch] = ->(v){ voice.pitch127 = v }

		voice
	end

	def fast_forward=(enabled)
		@voices.apply :fast_forward=, enabled
	end
end

private

class Voice

	attr_reader :index, :midi_channel, :input_channel, :output_channel, :wsize, :pitch, :silence_offset

	def initialize(mirror_out: nil, output:, index:, midi_channel:, input_channel:, output_channel:, cc_vol:, cc_wsize:, cc_pitch:, wsize_base:, wsize_semitones:, silence_offset: -120)

		@mirror_out = mirror_out
		@output = output

		@index = index

		@midi_channel = midi_channel

		@cc_vol = cc_vol
		@cc_wsize = cc_wsize
		@cc_pitch = cc_pitch

		@mutex_vol = Thread::Mutex.new
		@mutex_wsize = Thread::Mutex.new
		@mutex_pitch = Thread::Mutex.new

		@wsize_base = wsize_base
		@wsize_semitones = wsize_semitones

		@silence_offset = silence_offset

		self.input_channel = input_channel
		self.output_channel = output_channel

		self.vol = 0
		self.wsize = 0
		self.pitch = 0

		self
	end

	def fast_forward=(enabled)
		if @fast_forward && !enabled
			@output.send OSC::Message.new("/input_channel", @index, @input_channel)
			@output.send OSC::Message.new("/output_channel", @index, @output_channel)

			@output.send OSC::Message.new("/vol", @index, @vol)
			@output.send OSC::Message.new("/wsize", @index, @wsize_base / (2.0 ** @wsize))
			@output.send OSC::Message.new("/rate", @index, @pitch)

			@mirror_out.puts MIDIMessage::Controller.new(@midi_channel, @cc_vol, self.vol127).to_bytes if @mirror_out
			@mirror_out.puts MIDIMessage::Controller.new(@midi_channel, @cc_wsize, self.wsize127).to_bytes if @mirror_out
			@mirror_out.puts MIDIMessage::Controller.new(@midi_channel, @cc_pitch, self.pitch127).to_bytes if @mirror_out
		end

		@fast_forward = enabled
	end

 	def input_channel=(val)
 		if val
	 		@input_channel = val.to_i

			@output.send OSC::Message.new("/input_channel", @index, @input_channel) unless @fast_forward
		end

		@input_channel
 	end

 	def output_channel=(val)
 		if val
	 		@output_channel = val.to_i
			@output.send OSC::Message.new("/output_channel", @index, @output_channel) unless @fast_forward
		end

		@output_channel
 	end

 	def vol=(val)
 		if val

 			val = -120 if  val <= @silence_offset

	 		@vol = val.to_f
			
			@output.send OSC::Message.new("/vol", @index, @vol) unless @fast_forward
			@mirror_out.puts MIDIMessage::Controller.new(@midi_channel, @cc_vol, self.vol127).to_bytes if @mirror_out && !@mutex_vol.locked? && !@fast_forward
		end

		@vol
 	end

 	def vol
 		if @vol <= @silence_offset
 			@silence_offset
 		else
 			@vol
 		end
 	end

	def vol127=(val)
		@mutex_vol.synchronize do
			self.vol = (val - 127) / 2.0
		end

		self.vol127
	end

	def vol127
		(self.vol * 2.0).to_i + 127
	end

 	def wsize=(val)
 		if val
	 		@wsize = val.to_f

			@output.send OSC::Message.new("/wsize", @index, @wsize_base / (2.0 ** @wsize)) unless @fast_forward
			@mirror_out.puts MIDIMessage::Controller.new(@midi_channel, @cc_wsize, self.wsize127).to_bytes if @mirror_out && !@mutex_wsize.locked? && !@fast_forward
		end

		@wsize
 	end

	def wsize127=(val)
		@mutex_wsize.synchronize do
			self.wsize = Rational(val, 127) * Rational(@wsize_semitones, 12)
		end

		self.wsize127
	end

	def wsize127
		(Rational(self.wsize, Rational(@wsize_semitones, 12)) * 127).to_i
	end

 	def pitch=(val)
 		if val
	 		@pitch = val.to_f

	 		puts "Voice: #{@index} exceeded pitch #{@pitch}" if @pitch > 2.0

			@output.send OSC::Message.new("/rate", @index, @pitch) unless @fast_forward
			@mirror_out.puts MIDIMessage::Controller.new(@midi_channel, @cc_pitch, self.pitch127).to_bytes if @mirror_out && !@mutex_pitch.locked? && !@fast_forward
		end

		@pitch
 	end

 	def pitch127=(val)
 		@mutex_pitch.synchronize do
 			self.pitch = (Rational(val, 127) * Rational(24, 12)).to_f
 		end

 		self.pitch127
 	end

 	def pitch127
 		((self.pitch / Rational(24, 12)) * 127.0).to_i
 	end

 	def set(vol: nil, wsize: nil, pitch: nil)
 		self.pitch = pitch if pitch
 		self.wsize = wsize if wsize
 		self.vol = vol if vol

 		[vol: vol, wsize: wsize, pitch: pitch]
 	end

 	def to_s
 		"voice #{@index} input: #{@input_channel} output: #{@output_channel} pitch: #{(self.pitch / (1.0 / 12.0)).round(2)} wsize: #{(self.wsize / (1.0 / 12.0)).round(2)} vol: #{self.vol.round(2)}"
 	end
end

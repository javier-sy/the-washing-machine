require 'midi-message'

class MIDIVoices

	def initialize(sequencer:, output:, channels:)
		@sequencer = sequencer
		@output = output
		@channels = channels

		reset
	end

	def reset
		@voices = @channels.collect { |channel| MIDIVoice.new sequencer: @sequencer, output: @output, channel: channel }
	end

	def voice(index)
		@voices[index]
	end

	def fast_forward=(enabled)
		@voices.apply :fast_forward=, enabled
	end
end

private

class MIDIVoice

	attr_accessor :name
	attr_reader :sequencer, :output, :channel, :used_pitches, :tick_duration

	def initialize(sequencer:, output:, channel:, name: nil)
		@sequencer = sequencer
		@output = output
		@channel = channel
		@name = name

		@tick_duration = Rational(1, @sequencer.ticks_per_bar)

		@used_pitches = []
		
		(1..127).each do |pitch|
			@used_pitches[pitch] = { counter: 0, velocity: 0 }
		end

		self
	end

	def fast_forward=(enabled)
		if @fast_forward && !enabled
			(1..127).each do |pitch|
				@output.puts MIDIMessage::NoteOn @channel, pitch, @used_pitches[pitch][:velocity] if @used_pitches[pitch][:counter] > 0
			end
		end

		@fast_forward = enabled
	end

	def fast_forward?
		@fast_forward
	end

	def note(pitchvalue = nil, pitch: nil, velocity: 100, duration: nil, velocity_off: 100)
		pitch ||= pitchvalue
		NoteOnControl.new self, pitch: pitch, velocity: velocity, duration: duration, velocity_off: velocity_off
	end

 	def to_s
 		"voice #{@name} output: #{@output} channel: #{@channel}"
 	end

	class NoteOnControl
		
		def initialize(voice, pitch:, velocity:, duration:, velocity_off:)
			@voice = voice
			@pitch = pitch

			@do_on_stop = []
			@do_after = []

			@voice.used_pitches[pitch][:counter] += 1
			@voice.used_pitches[pitch][:velocity] = velocity

			msg = MIDIMessage::NoteOn.new(@voice.channel, pitch, velocity)
			@voice.sequencer.log "#{@voice.name} #{msg.verbose_name}"
			@voice.output.puts MIDIMessage::NoteOn.new(@voice.channel, pitch, velocity) if !@voice.fast_forward?

			if duration
				this = self
				@voice.sequencer.wait duration - @voice.tick_duration do
					this.note_off velocity: velocity_off
				end
			end

		end

		def note_off(velocity: 100)
			@voice.used_pitches[@pitch][:counter] -= 1
			@voice.used_pitches[@pitch][:counter] = 0 if @voice.used_pitches[@pitch][:counter] < 0

			if @voice.used_pitches[@pitch][:counter] == 0
				msg = MIDIMessage::NoteOff.new(@voice.channel, @pitch, velocity)
				@voice.sequencer.log "#{@voice.name} #{msg.verbose_name}"
				@voice.output.puts msg if !@voice.fast_forward?
			end

			@do_on_stop.each do |do_on_stop|
				@voice.sequencer.wait 0, &do_on_stop
			end

			@do_after.each do |do_after|
				@voice.sequencer.wait @voice.tick_duration + do_after[:bars], &do_after[:block]
			end

		end

		def on_stop(&block)
			@do_on_stop << block
		end

		def after(bars = 0, &block)
			@do_after << { bars: bars.rationalize, block: block }
		end
	end
end

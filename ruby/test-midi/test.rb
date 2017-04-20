require 'unimidi'

require_relative '../midi-voices'
require_relative '../sequencer/transport'

@input = UniMIDI::Input.all.select { |x| x.name == 'Apple Inc. Driver IAC' }[1]
@output = UniMIDI::Output.all.select { |x| x.name == 'Apple Inc. Driver IAC' }[1]

@transport = Transport.new @input, 4, 24, before_begin: ->{ puts "Begin..."; load "./score.rb"; score }, after_stop: ->{ puts "The End!" }

@transport.sequencer.debug = false

@transport.sequencer.on_debug_at do
	#log
	#log "vols = #{@all_voices.get(:vol)}"
	#log "pitches = #{@all_voices.get(:pitch)}"
end 

@transport.sequencer.on_fast_forward do |enabled|
	@voices.fast_forward = enabled
end

@voices = MIDIVoices.new sequencer: @transport.sequencer, output: @output, channels: [0, 1, 2, 3]

@transport.start
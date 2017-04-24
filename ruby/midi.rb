require 'musa-dsl'
require 'osc-ruby'

require_relative 'voices'

@input = UniMIDI::Input.all.select { |x| x.name == 'Apple Inc. Driver IAC' }[1]
@output = OSC::Client.new 'localhost', 57120

@twister_input = UniMIDI::Input.find_by_name 'DJ Tech Tools Midi Fighter Twister'
@twister_output = UniMIDI::Output.find_by_name 'DJ Tech Tools Midi Fighter Twister'

@voices = Voices.new(
	output: @output, 
	mirror_in: @twister_input, mirror_out: @twister_output, 
	voices: 10, 
	wsize_base: 1/5.0, wsize_semitones: 36)

@transport = Musa::Transport.new @input, 4, 24, before_begin: ->{ puts "Begin..."; load "./score.rb"; score }, after_stop: ->{ puts "The End!" }

@transport.sequencer.debug = false

@transport.sequencer.on_debug_at do
	#log
	#log "vols = #{@all_voices.get(:vol)}"
	#log "pitches = #{@all_voices.get(:pitch)}"
end 

@transport.sequencer.on_fast_forward do |enabled|
	@voices.fast_forward = enabled
end


@transport.start
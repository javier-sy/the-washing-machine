require 'osc-ruby'


@client = OSC::Client.new( 'localhost', 57120 )

@client.send( OSC::Message.new( "/holaxxx" , "hullo!" ))




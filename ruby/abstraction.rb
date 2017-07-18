def c(note_length_in_16)
	Rational(note_length_in_16, 16)
end

def cc(note_length_in_32)
	Rational(note_length_in_32, 32)
end

def t(bars, note_length_in_16th = 0)
	bars + Rational(note_length_in_16th, 16)
end

def tt(bars, note_length_in_32th = 0)
	bars + Rational(note_length_in_32th, 32)
end

def s(semitones)
	Rational(semitones, 12)
end

def move_vol(voice, to:, till: nil, duration: nil)
	opt = ''
	opt += "till #{till}" if till
	opt += "duration #{duration}" if duration

	log "voice #{voice.name}: moving vol from #{voice.vol.to_f.round(2)} to #{to.to_f.round(2)} #{opt}"

	m = move from: voice.vol, to: to, till: till, duration: duration do |v|
		voice.vol = v
	end

	m.after do
		log "voice #{voice.name}: vol arrived to #{to.to_f.round(2)}"
	end

	m
end

def move_vol_twice(voice, to:, till: nil, duration: nil, wait_till: nil, wait_duration: nil, to_2:, till_2: nil, duration_2: nil)

	m = move_vol voice, to: to, till: till, duration: duration

	if wait_till
		at wait_till do
			move_vol voice, to: to_2, till: till_2, duration: duration_2
		end
	end

	if wait_duration
		if wait_duration >= 0
			m.after wait_duration do
				move_vol voice, to: to_2, till: till_2, duration: duration_2
			end
		else
			at till_2 + wait_duration do
				move_vol voice, to: to_2, till: till_2, duration: duration_2
			end
		end
	end

	nil # TODO interesaría obtener el 2º move_vol, pero no existe hasta un tiempo después
end

def move_vol_forth_and_back(voice, to:, till: nil, duration: nil, back_at: nil, back_after: nil)
	
	vol = voice.vol
	start_at = position

	opt = ''
	opt += "till #{till}" if till
	opt += "duration #{duration}" if duration
	opt += " with back at #{back_at}" if back_at
	opt += " with back after #{back_after}" if back_after

	log "voice #{voice.name}: moving vol forth and back from #{vol.to_f.round(2)} to #{to.to_f.round(2)} #{opt}"

	m = move till: till, duration: duration, from: vol, to: to do |v| 
		voice.vol = v
	end

	if back_at || back_after
		m.after do
			log "voice #{voice.name}: vol going back to #{vol.to_f.round(2)}"

			m = move till: back_at, duration: back_after, from: voice.vol, to: vol do |v| 
				voice.vol = v
			end

			m.after do
				log "voice #{voice.name}: vol gone back to #{vol.to_f.round(2)}"
			end
		end
	end

	m
end

def move_pitch(voice, to:, till: nil, duration: nil)
	opt = ''
	opt += "till #{till}" if till
	opt += "duration #{duration}" if duration

	log "voice #{voice.name}: moving pitch from #{voice.pitch.to_f.round(3)} to #{to.to_f.round(3)} #{opt}"

	m = move till: till, duration: duration, from: voice.pitch, to: to do |p| 
		voice.pitch = p
	end

	m.after do
		log "voice #{voice.name}: pitch arrived to #{to.to_f.round(3)}"
	end

	m
end

def move_pitch_and_return(voice, to:, till: nil, duration: nil, return_at: nil, return_after: nil)
	
	pitch = voice.pitch
	start_at = position


	opt = ''
	opt += "till #{till}" if till
	opt += "duration #{duration}" if duration
	opt += " with return at #{return_at}" if return_at
	opt += " with return after #{return_after}" if return_after

	log "voice #{voice.name}: moving pitch from #{pitch.to_f.round(3)} to #{to.to_f.round(3)} #{opt}"
	
	m = move till: till, duration: duration, from: voice.pitch, to: to do |p| 
		voice.pitch = p
	end

	if return_at
		at return_at do
			log "voice #{voice.name}: pitch returned to #{pitch.to_f.round(3)}"
			voice.pitch = pitch
		end
	end

	return_after ||= 0 unless return_at

	if return_after
		m.after return_after do
			log "voice #{voice.name}: pitch returned to #{pitch.to_f.round(3)}"
			voice.pitch = pitch
		end
	end

	m
end

def move_pitch_forth_and_back(voice, to:, till: nil, duration: nil, back_at: nil, back_after: nil)
	
	pitch = voice.pitch
	start_at = position

	opt = ''
	opt += "till #{till}" if till
	opt += "duration #{duration}" if duration
	opt += " with back at #{back_at}" if back_at
	opt += " with back after #{back_after}" if back_after

	log "voice #{voice.name}: moving pitch forth and back from #{pitch.to_f.round(3)} to #{to.to_f.round(3)} #{opt}"

	m = move till: till, duration: duration, from: pitch, to: to do |p| 
		voice.pitch = p
	end

	if back_at || back_after
		m.after do
			log "voice #{voice.name}: pitch going back to #{pitch.to_f.round(3)}"

			m = move till: back_at, duration: back_after, from: voice.pitch, to: pitch do |p| 
				voice.pitch = p
			end

			m.after do
				log "voice #{voice.name}: pitch gone back to #{pitch.to_f.round(3)}"
			end
		end
	end

	m
end

def move_pitch_sin(voice, period: nil, frequency: nil, amplitude:, center: nil, center_add: nil, till: nil, duration: nil)
	
	pitch = voice.pitch

	opt = ''
	opt += "till #{till}" if till
	opt += "duration #{duration}" if duration

	center_add ||= 0
	center ||= pitch + center_add
	
	duration ||= till - position
	add ||= 0

	sin = SIN start_value: pitch, steps: ticks_per_bar, frequency: frequency, amplitude: amplitude, center: center

	log "voice #{voice.name}: moving pitch with sin form from pitch #{pitch.to_f.round(3)} center = #{center.to_f.round(3)} #{opt}"

	sin.next_value # descartamos el primer valor, porque cuando comenzamos ya estamos en él
	
	m = move till: till, duration: duration, from: pitch, using: ->() { sin.next_value } do |p|
		voice.pitch = p
	end

	m.after do
		log "voice #{voice.name}: pitch moved with sin form to #{pitch.to_f.round(3)}"
	end

	m
end

def move_pitches(voices, to:, till: nil, duration: nil)

	# TODO logar

	move till: till, duration: duration, from: voices.get(:pitch), to: to do |p| 
		voices.apply :pitch=, p
	end
end



require 'musa-dsl'
require 'pp'

include Musa::Series

@variatio = Musa::Variatio.new :chord_combination do

	constructor { Array.new }

	scale = Musa::Scales.get(:major).based_on_pitch 60

	fieldset :root_and_grades do

		field :duplicate_position, 0..3
		field :duplicate_to_octave, [-2, -1, 1, 2]
		
		with_attributes do |chord_combination:, root_and_grades:, duplicate_position:, duplicate_to_octave:|

			if root_and_grades.first[1][1] == 3
				duplicates = { position: duplicate_position, octave: duplicate_to_octave, to_voice: 0 }
			else
				duplicates = nil
			end

			chord_combination[root_and_grades.first[0]] = Musa::Chord root_and_grades.first[1][0], grades: root_and_grades.first[1][1], scale: scale, duplicate: duplicates
		end

		fieldset :move_voice, 0..3 do
			field :moved_octave, [-2, -1, 1, 2]

			with_attributes do |chord_combination:, root_and_grades:, move_voice:, moved_octave:|
				chord_combination[root_and_grades.first[0]].move move_voice, octave: moved_octave
			end
		end

	end

	finalize do |chord_combination:|
		chord_combination.each { |chord| chord.sort_voices! }
	end
end

@selector = Musa::Darwin.new do

	measures do |chord_set|

		voice_leading_index = 1
		distance_index = 1
		
		chord_set.each { |chord| die if chord.pitches.uniq.size != 4 }

		(chord_set.size - 1).times do |i| 

			distance_index *= 1 + (chord_set[i].distance - chord_set[i+1].distance).abs

			chord_set[i].voices.size.times do |j|
				voice_leading_index *= 1 + (chord_set[i].pitches[j] - chord_set[i+1].pitches[j]).abs
			end
		end

		dimension :distance_index, -distance_index
		dimension :voice_leading_index, -voice_leading_index
	end

	weight voice_leading_index: 1, distance_index: 0.5
end

variations = @variatio.on root_and_grades: 
			[	{ 0 => 	[:II, 	3] }, 
				{ 1 => 	[:III, 	3] }, 
				{ 2 => 	[:VI, 	3] }, 
				{ 3 => 	[:III, 	 4] }, 
				{ 4 => 	[:IV, 	 4] }, 
				{ 5 => 	[:III, 	3] }, 
				{ 6 => 	[:II, 	3] }, 
				{ 7 => 	[:VI, 	 4] }, 
				{ 8 =>	[:III, 	 4] }, 
				{ 9 => 	[:II, 	 4] }, 
				{ 10 =>	[:V, 	 4] }, 
				{ 11 => [:I, 	3] }	]


puts "variations.size = #{variations.size}"

winner = @selector.select(variations).first

puts "WINNER"
pp winner

winner.each do |chord|
	puts "#{chord.root_grade}: #{chord.pitches}"
end



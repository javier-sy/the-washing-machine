require_relative 'music/music'

sd = Scales.get(:major)

s = Scales.get(:major).based_on_pitch 65

puts "0, 1, :V -> #{s.pitch_of [0, 1, :V]}"
puts ":I -> #{s.pitch_of :I}"


s2 = s.based_on :V

puts ":I -> #{s2.pitch_of :I}"








c = Chord3 :I, scale: sd
# c = Chord3.new :I, grades: 3, inversion: 0, scale: sd

# @base = :I 
# @grades = { :I => [ 0 ], :III => [ 2 ], :V => [ 4 ] }
# @voices = [ [ :symbol => :I, :value => 0 ], [ :symbol => :III, :value => 2 ], [ :symbol => :V, :value => 4 ] ]


puts "c.base = #{c.base}" # => :I

puts "c.grades = #{c.grades}" # => [0, 2, 4] / [:I, :III, :V] # keys de @grades
puts "c.notes = #{c.notes}" # => [0, 2, 4] / [:I, :III, :V] # values de @grades este es necesario?????
puts "c.voices = #{c.voices}" # =>  [0, 2, 4] / [:I, :III, :V] # values de los elementos de la lista de @voices

puts "c = #{c}"
puts "c.voices = #{c.voices}"
puts "c.invert..."

c.invert! 1

puts "c = #{c}"
puts "c.voices = #{c.voices}"



d = c.copy
puts "d = #{d}"
puts "d.voices = #{d.voices}"
puts "d.duplicate..."
d.duplicate! position: 0, octaves: 1, to_voice: 0

puts "d = #{d}"
puts "d.voices = #{d.voices}"

d.sort_voices!

puts "d.sort_voices!"
puts "d.voices = #{d.voices}"
puts "d.pitches = #{d.pitches}"

e = Chord3 :V, scale: s, inversion: 2, duplicate: { position: 0, octaves: [-1, -2], to_voice: 0 }, sort_voices: true

puts "e = #{e}"
puts "e.pitches = #{e.pitches}"
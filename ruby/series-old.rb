module Music

	class Serie

		def self.create
		end

		def next_value
		end

		def restart
		end
	end


	class Sin < Serie

		def self.create(**arguments)

			length = 1
			return_array = false
			extended = {}

			arguments.each do |argument|
				if (a1 = argument[1]).is_a? Array
					extended[argument[0]] = argument[1]
					
					length = a1.length if a1.length > length
					return_array = true
				else
					extended[argument[0]] = [ argument[1] ]
				end
			end

			to_return = length.times.collect do |i|
				Sin.new arguments.each.collect { 
						|argument|
						{ argument[0] => extended[argument[0]][i % extended[argument[0]].length] } 
					}.reduce({}, :update)
			end

			if return_array
				to_return
			else
				to_return[0]
			end
		end

		def initialize(start_value: 0.0, cycle_length: nil, steps: nil, cycles: nil, amplitude: 1, center: 0)

			start_value = start_value.to_f

			cycles ||= 1
			cycle_length ||= (steps.to_f - 1.0) / cycles.to_f if steps

			raise ArgumentError, 'cycle_length: or steps: are mandatory' unless cycle_length

			@length = cycle_length.to_f

			@amplitude = amplitude.to_f
			@center = center.to_f

			y = (start_value - @center) / @amplitude
			puts "WARNING: value for offset calc #{y} is outside asin range" if y < -1 || y > 1
			y = 1.0 if y > 1.0 # por los errores de precisión infinitesimal en el cálculo de y cuando es muy próximo a 1.0
			y = -1.0 if y < -1.0

			@offset = Math::asin(y)

			@step_size = 2.0 * Math::PI / @length

			restart
		end

		def next_value
			v = Math::sin(@offset + @step_size * @position) * @amplitude + @center
			@position += 1
			v
		end

		def restart
			@position = 0
		end

		def to_s
			"offset: #{@offset.round(3)}rd amplitude: #{@amplitude.round(3)} center: #{@center.round(3)} length: #{@length} step_size: #{@step_size.round(6)}"
		end
	end


end

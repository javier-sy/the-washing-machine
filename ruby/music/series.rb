require_relative '../sequencer/series'

module Series
	def SIN(start_value: 0.0, steps:, frequency: nil, period: nil, amplitude: 1, center: 0)
		Serie.new BasicSerieSinFunction.new start_value: start_value, steps: steps, period: period || Rational(1, frequency), amplitude: amplitude, center: center
	end
	
	class BasicSerieSinFunction
		include BasicSerie

		def initialize(start_value:, steps:, period:, amplitude:, center:)

			start_value = start_value.to_f unless start_value.is_a? Float

			@length = (steps * period).to_f if period

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

		def infinite?
			true
		end

		def to_s
			"offset: #{@offset.round(3)}rd amplitude: #{@amplitude.round(3)} center: #{@center.round(3)} length: #{@length} step_size: #{@step_size.round(6)}"
		end
	end

	private_constant :BasicSerieSinFunction
end

module BasicSerie
	def restart
	end

	def next_value
	end

	def infinite?
		false
	end
end

class Serie
	include BasicSerie

	def initialize(basic_serie)
		@serie = basic_serie
	end

	def restart
		@have_peeked_next_value = false
		@peeked_next_value = nil
		@serie.restart
	end

	def next_value
		if @have_peeked_next_value
			@have_peeked_next_value = false
			@peeked_next_value
		else
			@serie.next_value
		end
	end

	def peek_next_value
		if @have_peeked_next_value
			@peeked_next_value
		else
			@have_peeked_next_value = true
			@peeked_next_value = @serie.next_value
		end
	end

	def infinite?
		@serie.infinite?
	end
end

module Series

	def S(*values)
		Serie.new BasicSerieFromArray.new(values)
	end

	def FOR(from: 0, to:, step: 1)
		Serie.new ForLoopBasicSerie.new(from: from, to: to, step: step)
	end

	def H(**series_hash)
		Serie.new BasicSerieFromHash.new(series_hash)
	end

	def R(serie, times: nil, &condition_block)
		if times || condition_block
			Serie.new BasicSerieRepeater.new(serie, times: times, &condition_block)
		else
			Serie.new BasicSerieInfiniteRepeater.new(serie)
		end
	end

	def F(serie)
		Serie.new BasicSerieFreezer.new(serie)
	end

	def REV(serie)
		Serie.new BasicSerieReverser.new(serie)
	end

	def SEL(selector, *indexed_series, **hash_series)
		Serie.new SelectorBasicSerie.new(selector, indexed_series, hash_series)
	end

	def SEL_F(selector, *indexed_series, **hash_series)
		Serie.new SelectorFullSerieBasicSerie.new(selector, indexed_series, hash_series)
	end

	def SEQ(*series)
		Serie.new SequenceBasicSerie.new(series)
	end

	def E(serie = nil, start: nil, with: nil, &block)
		raise ArgumentError, "only serie or start can be defined" if serie && start

		if start
			Serie.new BasicSerieFromAutoEvalBlockOnSeed.new(start: start, &block)
		elsif serie
			Serie.new BasicSerieFromEvalBlockOnSerie.new(serie, with: with, &block)
		else
			Serie.new BasicSerieFromEvalBlock.new(&block)
		end
	end

	###
	###
	###

	class SequenceBasicSerie
		include BasicSerie
	
		def initialize(series)
			@series = series
			restart
		end

		def restart
			@series.each { |serie| serie.restart }
			@index = 0
		end

		def next_value
			value = @series[@index].next_value

			if value.nil?
				@index += 1
				value = next_value if @index < @series.size
			
			end

			value
		end

		def infinite?
			!!@series.find { |serie| serie.infinite? }
		end
	end

	private_constant :SequenceBasicSerie

	class SelectorBasicSerie
		include BasicSerie
	
		def initialize(selector, indexed_series, hash_series)
			@selector = selector

			if indexed_series && !indexed_series.empty?
				@series = indexed_series
			elsif hash_series && !hash_series.empty?
				@series = hash_series
			end

			restart
		end

		def restart
			@selector.restart
			@series.each { |serie| serie.restart } if @series.is_a? Array
			@series.each { |key, serie| serie.restart } if @series.is_a? Hash
		end

		def next_value
			value = nil

			index_or_key = @selector.next_value

			if !index_or_key.nil?
				value = @series[index_or_key].next_value
			end

			value
		end

		def infinite?
			!!( @selector.infinite? && !(@series.find { |serie| !serie.infinite? }) )
		end
	end

	private_constant :SelectorBasicSerie

	class SelectorFullSerieBasicSerie
		include BasicSerie
	
		def initialize(selector, indexed_series, hash_series)
			@selector = selector

			if indexed_series && !indexed_series.empty?
				@series = indexed_series
			elsif hash_series && !hash_series.empty?
				@series = hash_series
			end

			restart
		end

		def restart
			@selector.restart
			@series.each { |serie| serie.restart }
		end

		def next_value
			value = nil

			if !@index_or_key.nil?
				value = @series[@index_or_key].next_value
			end

			if value.nil?
				@index_or_key = @selector.next_value

				value = next_value unless @index_or_key.nil?
			end

			value
		end

		def infinite?
			!!(@selector.infinite? || (@series.find { |serie| serie.infinite? }))
		end
	end

	private_constant :SelectorFullSerieBasicSerie

	class BasicSerieInfiniteRepeater
		include BasicSerie

		def initialize(serie)
			@serie = serie
			restart
		end

		def restart
			@serie.restart
		end

		def next_value
			value = @serie.next_value
			
			if value.nil?
				@serie.restart
				value = @serie.next_value
			end

			value
		end

		def infinite?
			true
		end
	end	

	private_constant :BasicSerieInfiniteRepeater

	class BasicSerieRepeater
		include BasicSerie

		def initialize(serie, times: nil, &condition_block)
			@serie = serie
			
			@condition_block = condition_block
			@condition_block ||= ->() { @count < times } if times

			raise ArgumentError, "times or condition block are mandatory" unless @condition_block

			restart
		end

		def restart
			@serie.restart
			@count = 0
		end

		def next_value
			value = @serie.next_value

			if value.nil?
				@count += 1

				if @condition_block.call
					@serie.restart
					value = @serie.next_value
				end
			end

			value
		end
	end	

	private_constant :BasicSerieRepeater

	class ForLoopBasicSerie
		def initialize(from:, to:, step:)
			@from = from
			@to = to
			@step = step

			restart
		end

		def restart
			@value = @from 
		end

		def next_value
			value = @value if @value

			@value = @value + @step

			@value = nil if @value > @to && @step.positive? || @value < @to && @step.negative?

			value
		end
	end

	private_constant :ForLoopBasicSerie

	class BasicSerieFreezer
		def initialize(serie)
			@serie = serie
			@values = []

			@first_round = true

			restart
		end

		def restart
			@index = 0
		end

		def next_value
			if @first_round
				value = @serie.next_value

				if value.nil?
					@first_round = false
				end
			else
				if @index < @values.size
					value = @values[@index]
					@index += 1
				else
					value = nil
				end
			end

			value
		end
	end

	private_constant :BasicSerieFreezer

	class BasicSerieReverser
		include BasicSerie

		def initialize(serie)
			raise ArgumentError, "cannot reverse an infinite serie #{serie}"
			@serie = serie
			restart
		end

		def restart
			@serie.restart
			@reversed = BasicSerieFromArray.new next_values_array_of(@serie).reverse
		end

		def next_value
			@reversed.next_value
		end

		private

		def next_values_array_of(serie)
			array = []

			while !(value = serie.next_value).nil? do
				array << value
			end

			array
		end
	end

	private_constant :BasicSerieReverser

	class BasicSerieFromArray
		include BasicSerie

		def initialize(array)
			@array = array.clone
			@index = 0
		end

		def restart
			@index = 0
		end

		def next_value
			if @index < @array.size
				value = @array[@index]
				@index += 1
			else
				value = nil
			end

			value
		end
	end

	private_constant :BasicSerieFromArray

	class BasicSerieFromAutoEvalBlockOnSeed
		include BasicSerie

		def initialize(start:, &block)
			@value = start
			@block = block

			@current = nil
			@first = true
		end

		def restart
			@current = nil
		end

		def next_value
			if @first
				@first = false
				@current = @value
			else
				@current = @block.call @current
			end

			@current
		end
	end

	private_constant :BasicSerieFromAutoEvalBlockOnSeed

	class BasicSerieFromEvalBlockOnSerie
		include BasicSerie

		def initialize(serie, with: nil, &block)
			
			if serie.is_a? Array
				@serie = BasicSerieFromArray.new serie
			elsif serie.is_a? Serie
				@serie = serie
			else
				raise ArgumentError, "serie is not an Array nor a Serie: #{serie}"
			end

			if with
				if with.is_a? Array
					@with_serie = BasicSerieFromArray.new with
				elsif with.is_a? Serie
					@with_serie = with
				else
					raise ArgumentError, "with_serie is not an Array nor a Serie: #{with_serie}"
				end
			end

			@block = block
		end

		def restart
			@serie.restart
			@with_serie.restart if @with_serie
		end

		def next_value
			next_value = @serie.next_value

			if @block && !next_value.nil?
				next_with = @with_serie.next_value if @with_serie

				if next_with
					@block.call next_value, next_with
				else
					@block.call next_value
				end
			else
				next_value
			end
		end
	end

	private_constant :BasicSerieFromEvalBlockOnSerie

	class BasicSerieFromEvalBlock
		include BasicSerie

		def initialize(&block)
			@block = block
			restart
		end

		def restart
			@index = 0
		end

		def next_value
			if @have_peeked_next_value
				@have_peeked_next_value = false
				value = @peek_next_value
			else
				value = @block.call @index
				@index += 1
			end

			value
		end
	end

	private_constant :BasicSerieFromEvalBlock

	class BasicSerieFromHash
		include BasicSerie

		def initialize(series)
			@series = {}
			
			series.each do |key, serie|
				if serie.is_a? Array
					@series[key] = BasicSerieFromArray.new serie
				elsif serie.is_a? Serie
					@series[key] = serie
				elsif serie.nil?
					# ignorarlo
				else
					raise ArgumentError, "Serie element #{key} is not an Array nor a Serie: #{serie}"
				end
			end
		end

		def restart
			@series.each_value do |value|
				value.restart
			end
		end

		def next_value
			value = @series.collect { |key, value| [ key, value.next_value ] }.to_h

			if value.find { |key, value| value.nil? }
				nil
			else
				value
			end
		end
	end

	private_constant :BasicSerieFromHash
end
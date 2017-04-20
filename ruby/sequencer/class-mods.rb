class Array
	def apply(method_name, source)
	
		source = [source] unless source.is_a? Array
		
		self.each_with_index do |o, i|
			o.send method_name, source[i % source.length]
		end
	end

	def get(method_name)
		self.collect { |o| o.send method_name }
	end
end

class Rational
	def inspect
		d = self - self.to_i
		if d != 0
			"#{self.to_i}(#{d.numerator}/#{d.denominator})"
		else
			"#{self.to_i}"
		end
	end

	alias to_s inspect
end

class BasicObject
	def instance_exec_nice(value_args, key_args, &block)
		if block.lambda?
			if !value_args.nil? && !value_args.empty?
				if !key_args.nil? && !key_args.empty?
					block.call *value_args, **key_args
				else
					block.call *value_args
				end
			else
				if !key_args.nil? && !key_args.empty?
					block.call **key_args
				else
					block.call
				end
			end
		else
			if !value_args.nil? && !value_args.empty?
				if !key_args.nil? && !key_args.empty?
					instance_exec *value_args, **key_args, &block
				else
					instance_exec *value_args, &block
				end
			else
				if !key_args.nil? && !key_args.empty?
					instance_exec **key_args, &block
				else
					instance_eval &block
				end
			end
		end
	end
end

class Object
	def send_nice(method_name, *args, **key_args, &block)
		if args && args.size > 0
			if key_args && key_args.size > 0
				send method_name, *args, **key_args, &block
			else
				send method_name, *args, &block
			end
		else
			if key_args && key_args.size > 0
				send method_name, **key_args, &block
			else
				send method_name, &block
			end
		end
	end
end
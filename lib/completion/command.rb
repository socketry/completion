# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Completion
	module Command
		def self.call(input = ARGV, output: $stderr, **options)
			if input.first == "--help" || input.first == "-h"
				Top.new(nil, output: output).print_usage(output: output)
				return true
			end
			
			Top.call(input, output: output, **options)
		end
	end
end

require_relative "command/top"

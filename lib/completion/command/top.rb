# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "samovar"

require_relative "completion"

module Completion
	module Command
		def self.call(...)
			Top.call(...)
		end
		
		# The completion command-line interface.
		class Top < Samovar::Command
			self.description = "Install and generate shell completion adapter scripts."
			
			options do
				option "-h/--help", "Print out help information."
			end
			
			nested :command, {
				"completion" => Completion,
			}, default: "completion"
			
			def call
				@command.call
			end
		end
	end
end

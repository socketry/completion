# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Completion
	# Command-line entry points for the completion executable.
	module Command
		# Parse and execute the top-level completion command.
		# 
		# @parameter arguments [Array] The arguments to forward to the top-level command.
		# @returns [Object | Nil] The command result.
		def self.call(...)
			Top.call(...)
		end
		
		# Complete the top-level completion command.
		# 
		# @parameter arguments [Array] The arguments to forward to the top-level command.
		# @returns [Samovar::Completion::Result] The completion result.
		def self.complete(...)
			Top.complete(...)
		end
	end
end

require_relative "command/top"

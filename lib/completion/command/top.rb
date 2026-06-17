# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "samovar"

unless defined?(Completion::Command) && Completion::Command.respond_to?(:call)
	require_relative "../command"
end

require_relative "generate"
require_relative "install"

module Completion
	module Command
		# The completion command-line interface.
		class Top < Samovar::Command
			self.description = "Install and generate shell completion adapter scripts."
			
			options do
				option "-h/--help", "Print out help information."
			end
			
			nested :command, {
				"install" => Install,
				"generate" => Generate,
			}, default: "generate"
			
			# Execute the selected completion sub-command.
			# 
			# @returns [Object | Nil] The sub-command result.
			def call
				if @options[:help]
					self.print_usage
				else
					@command.call
				end
			end
		end
	end
end

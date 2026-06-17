# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "samovar"

require_relative "../shell"
require_relative "../shell/bash"
require_relative "../shell/fish"
require_relative "../shell/zsh"

module Completion
	module Command
		# Generate shell completion adapter scripts.
		class Generate < Samovar::Command
			self.description = "Generate shell completion adapter scripts."
			
			options do
				option "--shell <name>", "The shell to generate completions for.", default: Shell.method(:default_shell), completions: ["bash", "zsh", "fish"]
				option "--command <name>", "The command executable to complete."
			end
			
			# Print the generated shell adapter script.
			# 
			# @returns [void]
			def call
				output.puts Shell.script(shell: @options[:shell], executable: @options[:command])
			end
		end
	end
end

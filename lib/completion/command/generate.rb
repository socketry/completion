# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "samovar"

require_relative "../shell"
require_relative "../shell/bash"
require_relative "../shell/fish"
require_relative "../shell/zsh"

module Completion
	class Command
		# Generate shell completion adapter scripts.
		class Generate < Samovar::Command
			self.description = "Generate shell completion adapter scripts."
			
			options do
				option "--shell <name>", "The shell to generate completions for.", default: Command.method(:default_shell), completions: ["bash", "zsh", "fish"]
				option "--command <name>", "The command executable to complete.", required: true
			end
			
			def call
				output.puts Shell.script(shell: @options[:shell].to_sym, executable: @options[:command])
			end
		end
	end
end

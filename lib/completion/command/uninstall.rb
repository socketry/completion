# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "samovar"

require_relative "../shell"

module Completion
	module Command
		# Uninstall a shell completion adapter script from a user-local completion directory.
		class Uninstall < Samovar::Command
			self.description = "Uninstall a shell completion adapter script."
			
			options do
				option "--shell <name>", "The shell to uninstall completions for.", default: Shell.method(:default_shell), completions: ["bash", "zsh", "fish"]
				option "--directory <path>", "The completion directory to uninstall from."
				option "--command <name>", "The command executable to stop completing."
			end
			
			# Remove the installed shell adapter script.
			# 
			# @returns [void]
			def call
				shell = @options[:shell]
				directory = Shell.adapter_directory(shell, @options[:command], directory: @options[:directory])
				path = File.join(directory, Shell.file_name(shell, @options[:command]))
				
				File.delete(path) if File.exist?(path)
				
				output.puts path
			end
		end
	end
end

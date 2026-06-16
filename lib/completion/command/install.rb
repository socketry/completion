# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "fileutils"
require "samovar"

require_relative "../shell"
require_relative "../shell/bash"
require_relative "../shell/fish"
require_relative "../shell/zsh"

module Completion
	module Command
		# Install a shell completion adapter script to a user-local completion directory.
		class Install < Samovar::Command
			self.description = "Install a shell completion adapter script."
			
			options do
				option "--shell <name>", "The shell to install completions for.", default: Shell.method(:default_shell), completions: ["bash", "zsh", "fish"]
				option "--directory <path>", "The completion directory to install into."
				option "--command <name>", "The command executable to complete."
			end
			
			def call
				raise Samovar::MissingValueError.new(self, :command) unless @options[:command]
				
				shell = @options[:shell]
				directory = @options[:directory] || Shell.default_directory(shell)
				path = File.join(directory, Shell.file_name(shell, @options[:command]))
				script = Shell.script(shell: shell.to_sym, executable: @options[:command])
				
				FileUtils.mkdir_p(directory)
				File.write(path, script)
				
				output.puts path
			end
		end
	end
end

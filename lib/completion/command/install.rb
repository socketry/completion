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
				option "--shell <name>", "The shell to install completions for.", default: Command.method(:default_shell), completions: ["bash", "zsh", "fish"]
				option "--directory <path>", "The completion directory to install into."
				option "--command <name>", "The command executable to complete.", required: true
			end
			
			def call
				shell = @options[:shell]
				directory = @options[:directory] || Command.default_directory(shell)
				path = File.join(directory, Command.file_name(shell, @options[:command]))
				script = Shell.script(shell: shell.to_sym, executable: @options[:command])
				
				FileUtils.mkdir_p(directory)
				File.write(path, script)
				
				output.puts path
			end
		end
	end
end

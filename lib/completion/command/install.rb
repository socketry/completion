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
			
			# Install the generated shell adapter script.
			# 
			# @returns [void]
			def call
				shell = @options[:shell]
				directory = Shell.adapter_directory(shell, @options[:command], directory: @options[:directory])
				path = File.join(directory, Shell.file_name(shell, @options[:command]))
				script = Shell.script(shell: shell, executable: @options[:command])
				
				FileUtils.mkdir_p(directory)
				shared_paths = install_shared(shell, directory)
				File.write(path, script)
				
				output.puts(shared_paths)
				output.puts path
			end
			
			private
			
			def install_shared(shell, directory)
				if shell == "fish"
					return install_fish_function(Shell.default_function_directory)
				end
				
				shared_path = File.join(directory, Shell.shared_file_name(shell))
				
				File.write(shared_path, Shell.shared_script(shell: shell))
				
				return [shared_path]
			end
			
			def install_fish_function(directory)
				FileUtils.mkdir_p(directory)
				
				return Shell::Fish.shared_functions.collect do |file_name, script|
					path = File.join(directory, file_name)
					File.write(path, script)
					path
				end
			end
		end
	end
end

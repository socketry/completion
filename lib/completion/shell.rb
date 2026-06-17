# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Completion
	# Shell adapter generation helpers.
	module Shell
		# Extract a shell name from a path.
		# 
		# @parameter path [String | Nil] The shell path.
		# @returns [String] The shell name.
		def self.shell_name(path)
			File.basename(path.to_s)
		end
		
		# Detect the current shell from the environment.
		# 
		# @returns [String] The detected shell name.
		def self.default_shell
			shell_name(ENV["SHELL"])
		end
		
		# Get the default completion directory for a shell.
		# 
		# @parameter shell [String] The shell name.
		# @returns [String] The default completion directory.
		def self.default_directory(shell)
			case shell
			when "bash"
				File.expand_path("~/.local/share/bash-completion/completions")
			when "fish"
				File.expand_path("~/.config/fish/completions")
			when "zsh"
				File.expand_path("~/.zsh/completions")
			else
				raise ArgumentError, "Unsupported shell: #{shell.inspect}"
			end
		end
		
		# Get the default Fish function directory.
		# 
		# @returns [String] The default Fish function directory.
		def self.default_function_directory
			File.expand_path("~/.config/fish/functions")
		end
		
		# Get the default Fish configuration directory.
		# 
		# @returns [String] The default Fish configuration directory.
		def self.default_configuration_directory
			File.expand_path("~/.config/fish/conf.d")
		end
		
		# Get the installed adapter file name for a shell.
		# 
		# @parameter shell [String] The shell name.
		# @parameter executable [String | Nil] The command executable, or nil for the generic adapter.
		# @returns [String] The adapter file name.
		def self.file_name(shell, executable = nil)
			command = executable || "completion"
			
			case shell
			when "bash"
				command
			when "fish"
				"#{command}.fish"
			when "zsh"
				"_#{command}"
			else
				raise ArgumentError, "Unsupported shell: #{shell.inspect}"
			end
		end
		
		# Get the installed shared helper file name for a shell.
		# 
		# @parameter shell [String] The shell name.
		# @returns [String] The shared helper file name.
		def self.shared_file_name(shell)
			case shell
			when "bash"
				"completion.bash"
			when "zsh"
				"completion.zsh"
			else
				raise ArgumentError, "Unsupported shell: #{shell.inspect}"
			end
		end
		
		# Generate a shell adapter script.
		# 
		# @parameter shell [String | Symbol] The shell name.
		# @parameter executable [String | Nil] The command executable, or nil for the generic adapter.
		# @returns [String] The generated adapter script.
		def self.script(shell:, executable: nil)
			case shell.to_sym
			when :bash
				Bash.script(executable)
			when :fish
				Fish.script(executable)
			when :zsh
				Zsh.script(executable)
			else
				raise ArgumentError, "Unsupported shell: #{shell.inspect}"
			end
		end
		
		# Generate a shared shell helper script.
		# 
		# @parameter shell [String | Symbol] The shell name.
		# @returns [String] The generated shared helper script.
		def self.shared_script(shell:)
			case shell.to_sym
			when :bash
				Bash.shared_script
			when :zsh
				Zsh.shared_script
			else
				raise ArgumentError, "Unsupported shell: #{shell.inspect}"
			end
		end
		
		# Get the command name from an executable path.
		# 
		# @parameter executable [String | Nil] The executable path, or nil for the generic adapter.
		# @returns [String] The command name.
		def self.command_name(executable)
			File.basename(executable || "completion")
		end
	end
end

# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "json"

module Completion
	# Shell adapter generation helpers.
	module Shell
		MARKER_PREFIX = "# Auto-generated completion: "
		
		# Generate a managed-file metadata marker.
		# 
		# @parameter kind [String] The generated file kind.
		# @parameter shell [String | Symbol] The shell name.
		# @parameter executable [String | Nil] The command executable, or nil for the generic adapter.
		# @returns [String] The generated metadata marker.
		def self.marker(kind:, shell:, executable: nil)
			metadata = {
				managed: true,
				kind: kind,
				shell: shell.to_s,
			}
			
			if executable
				metadata[:command] = command_name(executable)
			end
			
			return "#{MARKER_PREFIX}#{JSON.generate(metadata)}"
		end
		
		# Add a managed-file metadata marker to a generated script.
		# 
		# @parameter script [String] The generated script.
		# @parameter kind [String] The generated file kind.
		# @parameter shell [String | Symbol] The shell name.
		# @parameter executable [String | Nil] The command executable, or nil for the generic adapter.
		# @returns [String] The annotated script.
		def self.annotate(script, kind:, shell:, executable: nil)
			return "#{marker(kind: kind, shell: shell, executable: executable)}\n#{script}"
		end
		
		# Add a managed-file metadata marker after the first line of a generated script.
		# 
		# @parameter script [String] The generated script.
		# @parameter kind [String] The generated file kind.
		# @parameter shell [String | Symbol] The shell name.
		# @parameter executable [String | Nil] The command executable, or nil for the generic adapter.
		# @returns [String] The annotated script.
		def self.annotate_after_first_line(script, kind:, shell:, executable: nil)
			first, rest = script.split("\n", 2)
			
			return "#{first}\n#{marker(kind: kind, shell: shell, executable: executable)}\n#{rest}"
		end
		
		# Extract managed-file metadata from a generated script.
		# 
		# @parameter path [String] The script path to inspect.
		# @returns [Hash | Nil] The parsed metadata, if present.
		def self.metadata(path)
			return nil unless File.file?(path)
			
			File.open(path) do |file|
				2.times do
					line = file.gets
					break unless line
					
					if line.start_with?(MARKER_PREFIX)
						return JSON.parse(line.delete_prefix(MARKER_PREFIX))
					end
				end
			end
			
			return nil
		rescue JSON::ParserError
			return nil
		end
		
		# Check whether a script is managed by completion.
		# 
		# @parameter path [String] The script path to inspect.
		# @returns [Boolean] Whether the script is managed by completion.
		def self.managed?(path)
			metadata = self.metadata(path)
			
			return metadata && metadata["managed"] == true || false
		end
		
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
		
		# Get the adapter directory for a shell and executable.
		# 
		# @parameter shell [String] The shell name.
		# @parameter executable [String | Nil] The command executable, or nil for the generic adapter.
		# @parameter directory [String | Nil] The explicit adapter directory.
		# @returns [String] The adapter directory.
		def self.adapter_directory(shell, executable = nil, directory: nil)
			return directory if directory
			
			if shell == "fish" && !executable
				return default_configuration_directory
			end
			
			return default_directory(shell)
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

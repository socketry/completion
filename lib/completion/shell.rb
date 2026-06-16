# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Completion
	module Shell
		def self.shell_name(path)
			File.basename(path.to_s)
		end
		
		def self.default_shell
			shell_name(ENV["SHELL"])
		end
		
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
		
		def self.file_name(shell, executable)
			case shell
			when "bash"
				executable
			when "fish"
				"#{executable}.fish"
			when "zsh"
				"_#{executable}"
			else
				raise ArgumentError, "Unsupported shell: #{shell.inspect}"
			end
		end
		
		def self.script(shell:, executable:)
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
		
		def self.function_name(executable)
			"_#{command_name(executable).gsub(/[^a-zA-Z0-9_]/, "_")}_completion"
		end
		
		def self.command_name(executable)
			File.basename(executable)
		end
	end
end

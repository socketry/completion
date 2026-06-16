# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Completion
	module Shell
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

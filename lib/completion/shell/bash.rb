# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Completion
	module Shell
		# Bash completion adapter generation.
		module Bash
			def self.script(executable)
				function = Shell.function_name(executable)
				command = Shell.command_name(executable)
				
				<<~SCRIPT
					#{function}() {
						local command="completion-#{command}"
						local argv=("${COMP_WORDS[@]:1:COMP_CWORD}")
						COMPREPLY=()

						while IFS=$'\\t' read -r value description type; do
							COMPREPLY+=("$value")
						done < <("$command" "${argv[@]}")
					}

					complete -F #{function} #{command}
				SCRIPT
			end
		end
	end
end

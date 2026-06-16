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
						local index=$((COMP_CWORD - 1))
						local command="${COMP_WORDS[0]}"
						local argv=("${COMP_WORDS[@]:1}")
						COMPREPLY=()

						while IFS=$'\\t' read -r value description type; do
							COMPREPLY+=("$value")
						done < <(#{Protocol::Completion::Index::VARIABLE}="$index" "$command" "${argv[@]}")
					}

					complete -F #{function} #{command}
				SCRIPT
			end
		end
	end
end

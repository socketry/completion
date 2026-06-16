# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Completion
	module Shell
		# Zsh completion adapter generation.
		module Zsh
			def self.script(executable)
				function = Shell.function_name(executable)
				command = Shell.command_name(executable)
				
				<<~SCRIPT
					#compdef #{command}

					#{function}() {
						local command="completion-#{command}"
						local -a argv
						argv=("${(@)words[2,CURRENT]}")

						local -a completions
						while IFS=$'\\t' read -r value description type; do
							completions+=("${value}:${description}")
						done < <("$command" "${argv[@]}")

						_describe '#{Shell.command_name(executable)}' completions
					}

					#{function}
				SCRIPT
			end
		end
	end
end

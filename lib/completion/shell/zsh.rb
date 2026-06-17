# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Completion
	module Shell
		# Zsh completion adapter generation.
		module Zsh
			# Generate a Zsh completion adapter script.
			# 
			# @parameter executable [String | Nil] The command executable, or nil for the generic adapter.
			# @returns [String] The generated Zsh script.
			def self.script(executable)
				command = Shell.command_name(executable)
				
				if executable
					return <<~SCRIPT
						#compdef #{command}
						
						local _completion_source="${(%):-%x}"
						local _completion_directory="${_completion_source:h}"
						source "${_completion_directory}/completion.zsh"
						__completion_complete "$@"
					SCRIPT
				end
				
				<<~SCRIPT
					#compdef -default-
					
					local _completion_source="${(%):-%x}"
					local _completion_directory="${_completion_source:h}"
					source "${_completion_directory}/completion.zsh"
					__completion_register_default
					__completion_complete default "$@"
				SCRIPT
			end
			
			# Generate the shared Zsh helper script.
			# 
			# @returns [String] The generated Zsh helper script.
			def self.shared_script
				<<~SCRIPT
					__completion_resolve() {
						local command="$1"
						local basename="${command:t}"
						
						if [[ "$command" == */* ]]; then
							printf "%s\\n" "${command:h}/completion-${basename}"
						else
							printf "%s\\n" "completion-${basename}"
						fi
					}
					
					__completion_complete() {
						local fallback="$1"
						if [[ "$fallback" == "default" ]]; then
							shift
						else
							fallback=""
						fi
						
						local command="${words[1]}"
						local completer="$(__completion_resolve "$command")"
						
						if [[ ! -x "$completer" ]]; then
							if [[ "$fallback" == "default" ]]; then
								_default "$@"
							fi
							
							return
						fi
						
						local -a argv
						argv=("${(@)words[2,CURRENT]}")
						
						local -a completions
						local paths=false
						local directories=false
						local executables=false
						while IFS=$'\\t' read -r type value description metadata; do
							case "$type" in
								path)
									paths=true
									;;
								directory)
									directories=true
									;;
								executable)
									executables=true
									;;
								delegate)
									if [[ "$metadata" == *index=* ]]; then
										local index="${metadata##*index=}"
										index="${index%%$'\\t'*}"
										words=("${(@)words[$((index + 2)),-1]}")
										CURRENT=$((CURRENT - index - 1))
										_normal
										return
									fi
									;;
								*)
									completions+=("${value}:${description}")
									;;
							esac
						done < <("$completer" "${argv[@]}")
						
						if [[ "$paths" == true ]]; then
							_path_files
						fi
						
						if [[ "$directories" == true ]]; then
							_files -/
						fi
						
						if [[ "$executables" == true ]]; then
							_path_commands
						fi
						
						_describe 'completion' completions
					}
					
					__completion_register_default() {
						(( $+functions[compdef] )) && compdef _completion -default-
					}
				SCRIPT
			end
		end
	end
end

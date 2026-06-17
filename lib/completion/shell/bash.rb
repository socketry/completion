# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Completion
	module Shell
		# Bash completion adapter generation.
		module Bash
			# Generate a Bash completion adapter script.
			# 
			# @parameter executable [String | Nil] The command executable, or nil for the generic adapter.
			# @returns [String] The generated Bash script.
			def self.script(executable)
				command = Shell.command_name(executable)
				
				if executable
					return Shell.annotate(<<~SCRIPT, kind: "adapter", shell: "bash", executable: executable)
						_completion_source="${BASH_SOURCE[0]}"
						if [[ "$_completion_source" == */* ]]; then
							_completion_directory="${_completion_source%/*}"
						else
							_completion_directory="."
						fi
						source "${_completion_directory}/completion.bash"
						__completion_register #{command}
					SCRIPT
				end
				
				Shell.annotate(<<~SCRIPT, kind: "adapter", shell: "bash")
					_completion_source="${BASH_SOURCE[0]}"
					if [[ "$_completion_source" == */* ]]; then
						_completion_directory="${_completion_source%/*}"
					else
						_completion_directory="."
					fi
					source "${_completion_directory}/completion.bash"
					__completion_register_default
				SCRIPT
			end
			
			# Generate the shared Bash helper script.
			# 
			# @returns [String] The generated Bash helper script.
			def self.shared_script
				Shell.annotate(<<~SCRIPT, kind: "helper", shell: "bash")
					__completion_resolve() {
						local command="$1"
						local basename="${command##*/}"
						
						if [[ "$command" == */* ]]; then
							printf "%s\\n" "${command%/*}/completion-${basename}"
						else
							printf "%s\\n" "completion-${basename}"
						fi
					}
					
					__completion_complete() {
						local command="${COMP_WORDS[0]}"
						local completer="$(__completion_resolve "$command")"
						
						[[ -x "$completer" ]] || return 0
						
						local argv=("${COMP_WORDS[@]:1:COMP_CWORD}")
						COMPREPLY=()
						
						while IFS=$'\\t' read -r type value description metadata; do
							case "$type" in
								path)
									while IFS= read -r completion; do
										COMPREPLY+=("$completion")
									done < <(compgen -f -- "$value")
									;;
								directory)
									while IFS= read -r completion; do
										COMPREPLY+=("$completion")
									done < <(compgen -d -- "$value")
									;;
								executable)
									while IFS= read -r completion; do
										COMPREPLY+=("$completion")
									done < <(compgen -c -- "$value")
									;;
								delegate)
									if [[ "$metadata" == *index=* ]]; then
										local index="${metadata##*index=}"
										index="${index%%$'\\t'*}"
										local offset=$((index + 1))
										COMP_WORDS=("${COMP_WORDS[@]:$offset}")
										COMP_CWORD=$((COMP_CWORD - offset))
										
										if declare -F _completion_loader >/dev/null; then
											_completion_loader "${COMP_WORDS[0]}" >/dev/null 2>&1 || true
										fi
										
										local specification
										specification="$(complete -p "${COMP_WORDS[0]}" 2>/dev/null || true)"
										
										if [[ "$specification" =~ -F[[:space:]]+([^[:space:]]+) ]]; then
											"${BASH_REMATCH[1]}"
										fi
									fi
									;;
								*)
									COMPREPLY+=("$value")
									;;
							esac
						done < <("$completer" "${argv[@]}")
					}
					
					__completion_register() {
						complete -F __completion_complete "$1"
					}
					
					__completion_register_default() {
						complete -D -o bashdefault -o default -F __completion_complete 2>/dev/null || true
					}
				SCRIPT
			end
		end
	end
end

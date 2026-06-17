# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Completion
	module Shell
		# Fish completion adapter generation.
		module Fish
			# Generate a Fish completion adapter script.
			# 
			# @parameter executable [String | Nil] The command executable, or nil for the generic adapter.
			# @returns [String] The generated Fish script.
			def self.script(executable)
				command = Shell.command_name(executable)
				
				if executable
					return Shell.annotate(<<~SCRIPT, kind: "adapter", shell: "fish", executable: executable)
						__completion_register #{command}
					SCRIPT
				end
				
				Shell.annotate(<<~SCRIPT, kind: "adapter", shell: "fish")
					__completion_register_default
				SCRIPT
			end
			
			# Get the shared Fish helper function files.
			# 
			# @returns [Hash] The helper file names and scripts.
			def self.shared_functions
				{
					"__completion_complete.fish" => complete_function,
					"__completion_register.fish" => register_function,
					"__completion_register_default.fish" => register_default_function,
					"__completion_resolve.fish" => resolve_function,
					"__completion_supported.fish" => supported_function,
				}
			end
			
			# Generate the Fish completion function.
			# 
			# @returns [String] The generated Fish function script.
			def self.complete_function
				Shell.annotate(<<~SCRIPT, kind: "helper", shell: "fish")
					function __completion_complete --description 'Complete commands with adjacent completion executables'
						set -l argv (commandline -opc)
						set -e argv[1]
						set -l current (commandline -ct)
						
						if test -n "$current"
							set -a argv $current
						else
							set -a argv ""
						end
						
						set -l completer (__completion_resolve)
						$completer $argv | while read -l line
							set -l fields (string split (printf "\\t") -- $line)
							set -l type $fields[1]
							set -l value $fields[2]
							set -l description $fields[3]
							set -l metadata $fields[4..-1]
							
							switch "$type"
								case path
									__fish_complete_path "$value"
								case directory
									__fish_complete_directories "$value"
								case executable
									complete -C "$value"
								case delegate
									set -l index
									for field in $metadata
										switch "$field"
											case "index=*"
												set index (string replace "index=" "" -- "$field")
										end
									end
									
									if test -n "$index"
										set -l start (math $index + 1)
										set -l delegated $argv[$start..-1]
										complete -C (string join " " -- (string escape -- $delegated))
									end
								case "*"
									echo "$value	$description"
							end
						end
					end
				SCRIPT
			end
			
			# Generate the Fish command registration function.
			# 
			# @returns [String] The generated Fish function script.
			def self.register_function
				Shell.annotate(<<~SCRIPT, kind: "helper", shell: "fish")
					function __completion_register --description 'Register command completion'
						complete -c $argv[1] -f -a "(__completion_complete)"
					end
				SCRIPT
			end
			
			# Generate the Fish generic registration function.
			# 
			# @returns [String] The generated Fish function script.
			def self.register_default_function
				Shell.annotate(<<~SCRIPT, kind: "helper", shell: "fish")
					function __completion_register_default --description 'Register generic completion'
						complete -c "*" -n "__completion_supported" -f -a "(__completion_complete)"
					end
				SCRIPT
			end
			
			# Generate the Fish completion command resolver function.
			# 
			# @returns [String] The generated Fish function script.
			def self.resolve_function
				Shell.annotate(<<~SCRIPT, kind: "helper", shell: "fish")
					function __completion_resolve --description 'Resolve completion command'
						set -l argv (commandline -opc)
						set -l command $argv[1]
						set -l basename (basename "$command")
						
						if string match -q "*/*" "$command"
							echo (dirname "$command")/completion-$basename
						else
							echo completion-$basename
						end
					end
				SCRIPT
			end
			
			# Generate the Fish support detection function.
			# 
			# @returns [String] The generated Fish function script.
			def self.supported_function
				Shell.annotate(<<~SCRIPT, kind: "helper", shell: "fish")
					function __completion_supported --description 'Check completion support'
						set -l completer (__completion_resolve)
						
						if string match -q "*/*" "$completer"
							test -x "$completer"
						else
							type -q "$completer"
						end
					end
				SCRIPT
			end
		end
	end
end

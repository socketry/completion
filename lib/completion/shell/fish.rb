# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

module Completion
	module Shell
		# Fish completion adapter generation.
		module Fish
			def self.script(executable)
				function = Shell.function_name(executable)
				command = Shell.command_name(executable)
				
				<<~SCRIPT
					function #{function} --description 'Complete #{command}'
						set -l argv (commandline -opc)
						set -l command completion-#{command}
						set -e argv[1]
						set -l current (commandline -ct)
						
						if test -n "$current"
							set -a argv $current
						else
							set -a argv ""
						end

						$command $argv | while read -l line
							echo $line
						end
					end

					complete -c #{command} -f -a "(#{function})"
				SCRIPT
			end
		end
	end
end

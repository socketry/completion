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
						set -l command $argv[1]
						set -e argv[1]
						set -l current (commandline -ct)
						set -l index
						
						if test -n "$current"
							set -a argv $current
							set index (math (count $argv) - 1)
						else
							set index (count $argv)
						end

						begin
							set -lx #{Protocol::Completion::Index::VARIABLE} "$index"
							$command $argv
						end | while read -l line
							echo $line
						end
					end

					complete -c #{command} -f -a "(#{function})"
				SCRIPT
			end
		end
	end
end

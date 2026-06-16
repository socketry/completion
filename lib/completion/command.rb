# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "samovar"
require "samovar/failure"

module Completion
	module Command
		def self.call(...)
			Top.call(...)
		end
		
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
				raise Samovar::Failure, "Unsupported shell: #{shell.inspect}"
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
				raise Samovar::Failure, "Unsupported shell: #{shell.inspect}"
			end
		end
		
	end
end

require_relative "command/top"

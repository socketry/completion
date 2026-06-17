# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "samovar"

require_relative "../shell"

module Completion
	module Command
		# Uninstall a shell completion adapter script from a user-local completion directory.
		class Uninstall < Samovar::Command
			self.description = "Uninstall a shell completion adapter script."
			
			options do
				option "--shell <name>", "The shell to uninstall completions for.", default: Shell.method(:default_shell), completions: ["bash", "zsh", "fish"]
				option "--directory <path>", "The completion directory to uninstall from."
				option "--command <name>", "The command executable to stop completing."
				option "--all", "Remove all managed completion scripts for the selected shell."
			end
			
			# Remove the installed shell adapter script.
			# 
			# @returns [void]
			def call
				shell = @options[:shell]
				
				if @options[:all]
					return uninstall_all(shell)
				end
				
				directory = Shell.adapter_directory(shell, @options[:command], directory: @options[:directory])
				path = File.join(directory, Shell.file_name(shell, @options[:command]))
				
				File.delete(path) if File.exist?(path)
				
				output.puts path
			end
			
			private
			
			def uninstall_all(shell)
				paths = managed_paths(shell, @options[:directory])
				
				paths.each do |path|
					File.delete(path)
					output.puts path
				end
				
				return paths
			end
			
			def managed_paths(shell, directory)
				directories = managed_directories(shell, directory)
				
				return directories.flat_map do |directory|
					Dir.children(directory).filter_map do |name|
						path = File.join(directory, name)
						
						path if Shell.managed?(path)
					end
				end
			end
			
			def managed_directories(shell, directory)
				if directory
					return [directory].select{|path| Dir.exist?(path)}
				end
				
				case shell
				when "fish"
					[
						Shell.default_directory(shell),
						Shell.default_configuration_directory,
						Shell.default_function_directory,
					].select{|path| Dir.exist?(path)}
				else
					[
						Shell.default_directory(shell),
					].select{|path| Dir.exist?(path)}
				end
			end
		end
	end
end

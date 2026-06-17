# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "completion/command/top"
require "sus/fixtures/temporary_directory_context"

describe Completion::Command::Top do
	include Sus::Fixtures::TemporaryDirectoryContext
	
	def complete(input, **options)
		Completion::Command::Top.complete(input, output: StringIO.new, **options)
	end
	
	it "shows top-level commands with help" do
		output = StringIO.new
		command = subject.new(["--help"], output: output)
		
		command.call
		
		expect(output.string).to be(:include?, "install")
		expect(output.string).to be(:include?, "generate")
	end
	
	it "generates a shell completion adapter script" do
		output = StringIO.new
		command = subject.new(["generate", "--shell", "zsh", "--command", "my-command"], output: output)
		
		command.call
		
		expect(output.string).to be(:include?, "#compdef my-command")
		expect(output.string).to be(:include?, "completion.zsh")
	end
	
	it "generates a generic shell completion adapter script when command is omitted" do
		output = StringIO.new
		command = subject.new(["generate", "--shell", "zsh"], output: output)
		
		command.call
		
		expect(output.string).to be(:include?, "#compdef -default-")
		expect(output.string).to be(:include?, "__completion_register_default")
	end
	
	it "generates a shell completion adapter script through the default command" do
		output = StringIO.new
		command = subject.new(["--shell", "zsh", "--command", "my-command"], output: output)
		
		command.call
		
		expect(output.string).to be(:include?, "#compdef my-command")
		expect(output.string).to be(:include?, "completion.zsh")
	end
	
	it "infers shell when generating" do
		output = StringIO.new
		shell = ENV["SHELL"]
		
		begin
			ENV["SHELL"] = "/bin/fish"
			
			command = subject.new(["--command", "my-command"], output: output)
			command.call
		ensure
			ENV["SHELL"] = shell
		end
		
		expect(output.string).to be(:include?, "__completion_register my-command")
	end
	
	it "installs a shell completion adapter script to an explicit directory" do
		output = StringIO.new
		directory = File.join(root, "zsh")
		command = subject.new(["install", "--shell", "zsh", "--directory", directory, "--command", "my-command"], output: output)
		
		command.call
		
		shared_path = File.join(directory, "completion.zsh")
		path = File.join(directory, "_my-command")
		expect(output.string).to be == "#{shared_path}\n#{path}\n"
		expect(File.read(shared_path)).to be(:include?, "completion-${basename}")
		expect(File.read(path)).to be(:include?, "#compdef my-command")
		expect(File.read(path)).to be(:include?, "completion.zsh")
	end
	
	it "infers shell and default directory when installing a command adapter" do
		output = StringIO.new
		shell = ENV["SHELL"]
		home = ENV["HOME"]
		
		begin
			ENV["SHELL"] = "/bin/fish"
			ENV["HOME"] = File.join(root, "home")
			
			command = subject.new(["install", "--command", "my-command"], output: output)
			command.call
		ensure
			ENV["SHELL"] = shell
			ENV["HOME"] = home
		end
		
		directory = File.join(root, "home", ".config", "fish")
		completion_directory = File.join(directory, "completions")
		function_directory = File.join(directory, "functions")
		function_paths = Completion::Shell::Fish.shared_functions.keys.collect{|file_name| File.join(function_directory, file_name)}
		path = File.join(completion_directory, "my-command.fish")
		
		expect(output.string).to be == "#{function_paths.join("\n")}\n#{File.join(completion_directory, "my-command.fish")}\n"
		expect(File.read(File.join(function_directory, "__completion_register_default.fish"))).to be(:include?, "complete -c \"*\"")
		expect(File.read(path)).to be(:include?, "__completion_register my-command")
	end
	
	it "installs a generic shell completion adapter when command is omitted" do
		output = StringIO.new
		home = ENV["HOME"]
		
		begin
			ENV["HOME"] = File.join(root, "home")
			
			command = subject.new(["install", "--shell", "fish"], output: output)
			command.call
		ensure
			ENV["HOME"] = home
		end
		
		directory = File.join(root, "home", ".config", "fish")
		function_directory = File.join(directory, "functions")
		configuration_directory = File.join(directory, "conf.d")
		function_paths = Completion::Shell::Fish.shared_functions.keys.collect{|file_name| File.join(function_directory, file_name)}
		path = File.join(configuration_directory, "completion.fish")
		expect(output.string).to be == "#{function_paths.join("\n")}\n#{path}\n"
		expect(File.read(File.join(function_directory, "__completion_register_default.fish"))).to be(:include?, 'complete -c "*"')
		expect(File.read(path)).to be(:include?, "__completion_register_default")
	end
	
	it "installs a generic fish completion adapter to an explicit directory" do
		output = StringIO.new
		directory = File.join(root, "fish")
		home = ENV["HOME"]
		
		begin
			ENV["HOME"] = File.join(root, "home")
			
			command = subject.new(["install", "--shell", "fish", "--directory", directory], output: output)
			command.call
		ensure
			ENV["HOME"] = home
		end
		
		function_directory = File.join(root, "home", ".config", "fish", "functions")
		function_paths = Completion::Shell::Fish.shared_functions.keys.collect{|file_name| File.join(function_directory, file_name)}
		path = File.join(directory, "completion.fish")
		expect(output.string).to be == "#{function_paths.join("\n")}\n#{path}\n"
		expect(File.read(path)).to be(:include?, "__completion_register_default")
	end
	
	it "can be invoked through the top-level command" do
		output = StringIO.new
		
		Completion::Command::Top.new(["--shell", "bash", "--command", "my-command"], output: output).call
		
		expect(output.string).to be(:include?, "__completion_register my-command")
	end
	
	it "can complete through the top-level command" do
		output = StringIO.new
		
		Completion::Command.complete(["ins"], output: output)
		
		expect(output.string).to be == "command\tinstall\tInstall a shell completion adapter script.\n"
	end
	
	it "can complete through the dedicated executable" do
		output = IO.popen(["ruby", "-Ilib", "bin/completion-completion", "ins"], &:read)
		
		expect(output).to be == "command\tinstall\tInstall a shell completion adapter script.\n"
	end
	
	it "can complete an empty token through the dedicated executable" do
		output = IO.popen(["ruby", "-Ilib", "bin/completion-completion"], &:read)
		
		expect(output).to be(:include?, "command\tinstall\tInstall a shell completion adapter script.\n")
		expect(output).to be(:include?, "command\tgenerate\tGenerate shell completion adapter scripts.\n")
	end
	
	it "completes shell names" do
		result = complete(["--shell", "z"])
		
		expect(result.collect(&:value)).to be == ["zsh"]
	end
	
	it "completes the detected shell before other shell names" do
		shell = ENV["SHELL"]
		
		begin
			ENV["SHELL"] = "/bin/fish"
			
			result = complete(["--shell", ""])
		ensure
			ENV["SHELL"] = shell
		end
		
		expect(result.collect(&:value)).to be == ["fish", "bash", "zsh"]
	end
	
	it "completes install shell option values" do
		result = complete(["install", "--shell", "f"])
		
		expect(result.collect(&:value)).to be == ["fish"]
	end
end

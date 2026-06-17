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
		expect(output.string).to be(:include?, "uninstall")
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
	
	it "uninstalls a shell completion adapter script from an explicit directory" do
		output = StringIO.new
		directory = File.join(root, "zsh")
		path = File.join(directory, "_my-command")
		
		FileUtils.mkdir_p(directory)
		File.write(path, "adapter")
		
		command = subject.new(["uninstall", "--shell", "zsh", "--directory", directory, "--command", "my-command"], output: output)
		command.call
		
		expect(output.string).to be == "#{path}\n"
		expect(File.exist?(path)).to be == false
	end
	
	it "uninstalls a generic fish completion adapter when command is omitted" do
		output = StringIO.new
		home = ENV["HOME"]
		
		begin
			ENV["HOME"] = File.join(root, "home")
			
			directory = File.join(ENV["HOME"], ".config", "fish", "conf.d")
			path = File.join(directory, "completion.fish")
			
			FileUtils.mkdir_p(directory)
			File.write(path, "adapter")
			
			command = subject.new(["uninstall", "--shell", "fish"], output: output)
			command.call
		ensure
			ENV["HOME"] = home
		end
		
		expect(output.string).to be == "#{path}\n"
		expect(File.exist?(path)).to be == false
	end
	
	it "uninstalls all managed fish completion scripts" do
		output = StringIO.new
		home = ENV["HOME"]
		
		begin
			ENV["HOME"] = File.join(root, "home")
			
			fish_directory = File.join(ENV["HOME"], ".config", "fish")
			completion_directory = File.join(fish_directory, "completions")
			configuration_directory = File.join(fish_directory, "conf.d")
			function_directory = File.join(fish_directory, "functions")
			
			managed_adapter = File.join(completion_directory, "my-command.fish")
			managed_configuration = File.join(configuration_directory, "completion.fish")
			managed_function = File.join(function_directory, "__completion_complete.fish")
			unmanaged_adapter = File.join(completion_directory, "other-command.fish")
			
			FileUtils.mkdir_p(completion_directory)
			FileUtils.mkdir_p(configuration_directory)
			FileUtils.mkdir_p(function_directory)
			
			File.write(managed_adapter, Completion::Shell.script(shell: "fish", executable: "my-command"))
			File.write(managed_configuration, Completion::Shell.script(shell: "fish"))
			File.write(managed_function, Completion::Shell::Fish.complete_function)
			File.write(unmanaged_adapter, "complete -c other-command -a custom\n")
			
			command = subject.new(["uninstall", "--shell", "fish", "--all"], output: output)
			command.call
		ensure
			ENV["HOME"] = home
		end
		
		expect(output.string).to be(:include?, "#{managed_adapter}\n")
		expect(output.string).to be(:include?, "#{managed_configuration}\n")
		expect(output.string).to be(:include?, "#{managed_function}\n")
		expect(File.exist?(managed_adapter)).to be == false
		expect(File.exist?(managed_configuration)).to be == false
		expect(File.exist?(managed_function)).to be == false
		expect(File.exist?(unmanaged_adapter)).to be == true
	end
	
	it "uninstalls all managed completion scripts from an explicit directory" do
		output = StringIO.new
		directory = File.join(root, "zsh")
		managed_adapter = File.join(directory, "_my-command")
		managed_helper = File.join(directory, "completion.zsh")
		unmanaged_adapter = File.join(directory, "_other-command")
		
		FileUtils.mkdir_p(directory)
		File.write(managed_adapter, Completion::Shell.script(shell: "zsh", executable: "my-command"))
		File.write(managed_helper, Completion::Shell.shared_script(shell: "zsh"))
		File.write(unmanaged_adapter, "#compdef other-command\n")
		
		command = subject.new(["uninstall", "--shell", "zsh", "--directory", directory, "--all"], output: output)
		command.call
		
		expect(output.string).to be(:include?, "#{managed_adapter}\n")
		expect(output.string).to be(:include?, "#{managed_helper}\n")
		expect(File.exist?(managed_adapter)).to be == false
		expect(File.exist?(managed_helper)).to be == false
		expect(File.exist?(unmanaged_adapter)).to be == true
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
		expect(output).to be(:include?, "command\tuninstall\tUninstall a shell completion adapter script.\n")
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

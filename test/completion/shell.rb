# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "completion"
require "sus/fixtures/temporary_directory_context"

describe Completion::Shell do
	include Sus::Fixtures::TemporaryDirectoryContext
	
	def write_adapter(name, shell: :fish, executable: "samovar")
		path = File.join(root, name)
		
		write_helper(shell)
		File.write(path, subject.script(shell: shell, executable: executable))
		
		return path
	end
	
	def write_helper(shell, directory = root)
		if shell == :fish
			return write_fish_function(directory)
		end
		
		path = File.join(directory, subject.shared_file_name(shell.to_s))
		
		File.write(path, subject.shared_script(shell: shell))
		
		return path
	end
	
	def write_fish_function(directory = root)
		subject::Fish.shared_functions.each do |file_name, script|
			File.write(File.join(directory, file_name), script)
		end
		
		return directory
	end
	
	it "generates shell completion scripts" do
		expect(subject.script(shell: :bash, executable: "samovar")).to be(:include?, "completion.bash")
		expect(subject.script(shell: :zsh, executable: "samovar")).to be(:include?, "#compdef samovar")
		expect(subject.script(shell: :fish, executable: "samovar")).to be(:include?, "__completion_register samovar")
	end
	
	it "generates generic shell completion scripts" do
		expect(subject.script(shell: :bash)).to be(:include?, "__completion_register_default")
		expect(subject.script(shell: :zsh)).to be(:include?, "__completion_register_default")
		expect(subject.script(shell: :fish)).to be(:include?, "__completion_register_default")
	end
	
	it "uses the basename when registering completion scripts" do
		zsh = subject.script(shell: :zsh, executable: "./samovar")
		bash = subject.script(shell: :bash, executable: "./samovar")
		fish = subject.script(shell: :fish, executable: "./samovar")
		
		expect(zsh).to be(:include?, "#compdef samovar")
		expect(bash).to be(:include?, "__completion_register samovar")
		expect(fish).to be(:include?, "__completion_register samovar")
	end
	
	it "uses the dedicated completion command as the executable" do
		bash = subject.shared_script(shell: :bash)
		zsh = subject.shared_script(shell: :zsh)
		fish = subject::Fish.resolve_function + subject::Fish.complete_function
		
		expect(bash).to be(:include?, 'printf "%s\n" "completion-${basename}"')
		expect(bash).to be(:include?, '"$completer" "${argv[@]}"')
		expect(zsh).to be(:include?, 'printf "%s\n" "completion-${basename}"')
		expect(zsh).to be(:include?, '"$completer" "${argv[@]}"')
		expect(fish).to be(:include?, "echo completion-$basename")
		expect(fish).to be(:include?, "$completer $argv")
	end
	
	it "uses an adjacent completion command for path executables" do
		bash = subject.shared_script(shell: :bash)
		zsh = subject.shared_script(shell: :zsh)
		fish = subject::Fish.resolve_function
		
		expect(bash).to be(:include?, 'printf "%s\n" "${command%/*}/completion-${basename}"')
		expect(zsh).to be(:include?, 'printf "%s\n" "${command:h}/completion-${basename}"')
		expect(fish).to be(:include?, 'echo (dirname "$command")/completion-$basename')
	end
	
	it "uses zsh array indexing to keep arguments up to the cursor" do
		script = subject.shared_script(shell: :zsh)
		
		expect(script).to be(:include?, 'argv=("${(@)words[2,CURRENT]}")')
	end
	
	it "uses native path completion for supported shells" do
		bash = subject.shared_script(shell: :bash)
		fish = subject::Fish.complete_function
		zsh = subject.shared_script(shell: :zsh)
		
		expect(bash).to be(:include?, 'compgen -f -- "$value"')
		expect(bash).to be(:include?, 'compgen -d -- "$value"')
		expect(bash).to be(:include?, 'compgen -c -- "$value"')
		expect(fish).to be(:include?, '__fish_complete_path "$value"')
		expect(fish).to be(:include?, '__fish_complete_directories "$value"')
		expect(fish).to be(:include?, 'complete -C "$value"')
		expect(zsh).to be(:include?, "_path_files")
		expect(zsh).to be(:include?, "_files -/")
		expect(zsh).to be(:include?, "_path_commands")
	end
	
	it "passes application arguments from bash completion" do
		skip "bash is not available" unless system("command -v bash >/dev/null")
		
		path = File.join(root, "bash-trace")
		adapter = File.join(root, "samovar.bash")
		executable = File.join(root, "samovar")
		completer = File.join(root, "completion-samovar")
		
		write_helper(:bash)
		File.write(adapter, subject.script(shell: :bash, executable: "samovar"))
		File.write(completer, <<~SCRIPT)
			#!/bin/sh
			printf "%s\\n" "$*" > "$TRACE"
			printf "command\\tcompletion\\tGenerate\\n"
		SCRIPT
		File.chmod(0o755, completer)
		
		system({"TRACE" => path, "ADAPTER" => adapter}, "bash", "-c", <<~SCRIPT)
			PATH="#{root}:$PATH"
			source "$ADAPTER"
			
			COMP_WORDS=(#{executable} completion --shell z)
			COMP_CWORD=3
			
			__completion_complete
		SCRIPT
		
		expect(File.read(path)).to be == "completion --shell z\n"
	end
	
	it "uses adjacent completion command from bash path completion" do
		skip "bash is not available" unless system("command -v bash >/dev/null")
		
		path = File.join(root, "bash-adjacent-trace")
		adapter = File.join(root, "samovar-adjacent.bash")
		directory = File.join(root, "bin")
		executable = File.join(directory, "samovar")
		completer = File.join(directory, "completion-samovar")
		
		Dir.mkdir(directory)
		write_helper(:bash)
		File.write(adapter, subject.script(shell: :bash, executable: "samovar"))
		File.write(completer, <<~SCRIPT)
			#!/bin/sh
			printf "%s\\n" "$*" > "$TRACE"
			printf "command\\tcompletion\\tGenerate\\n"
		SCRIPT
		File.chmod(0o755, completer)
		
		system({"TRACE" => path, "ADAPTER" => adapter}, "bash", "-c", <<~SCRIPT)
			PATH="#{root}:$PATH"
			source "$ADAPTER"
			
			COMP_WORDS=(#{executable} completion --shell z)
			COMP_CWORD=3
			
			__completion_complete
		SCRIPT
		
		expect(File.read(path)).to be == "completion --shell z\n"
	end
	
	it "passes an empty token from bash completion" do
		skip "bash is not available" unless system("command -v bash >/dev/null")
		
		path = File.join(root, "bash-empty-trace")
		adapter = File.join(root, "samovar-empty.bash")
		executable = File.join(root, "samovar-empty")
		completer = File.join(root, "completion-samovar-empty")
		
		write_helper(:bash)
		File.write(adapter, subject.script(shell: :bash, executable: "samovar"))
		File.write(completer, <<~SCRIPT)
			#!/bin/sh
			printf "%s\\n" "$*" > "$TRACE"
			printf "command\\tcompletion\\tGenerate\\n"
		SCRIPT
		File.chmod(0o755, completer)
		
		system({"TRACE" => path, "ADAPTER" => adapter}, "bash", "-c", <<~SCRIPT)
			PATH="#{root}:$PATH"
			source "$ADAPTER"
			
			COMP_WORDS=(#{executable} "")
			COMP_CWORD=1
			
			__completion_complete
		SCRIPT
		
		expect(File.read(path)).to be == "\n"
	end
	
	it "uses native path completion from bash completion" do
		skip "bash is not available" unless system("command -v bash >/dev/null")
		
		adapter = File.join(root, "samovar-path.bash")
		executable = File.join(root, "samovar-path")
		completer = File.join(root, "completion-samovar-path")
		path = File.join(root, "tmp-path")
		
		Dir.mkdir(path)
		File.write(File.join(path, "example.txt"), "")
		write_helper(:bash)
		File.write(adapter, subject.script(shell: :bash, executable: "samovar"))
		File.write(completer, <<~SCRIPT)
			#!/bin/sh
			printf "path\\t%s\\tPath\\n" "$2"
		SCRIPT
		File.chmod(0o755, completer)
		
		output = IO.popen({"ADAPTER" => adapter}, ["bash", "-c", <<~SCRIPT], &:read)
			PATH="#{root}:$PATH"
			source "$ADAPTER"
			
			COMP_WORDS=(#{executable} --output #{path}/ex)
			COMP_CWORD=2
			
			__completion_complete
			printf "%s\\n" "${COMPREPLY[@]}"
		SCRIPT
		
		expect(output).to be(:include?, "#{path}/example.txt\n")
	end
	
	it "uses native executable completion from bash completion" do
		skip "bash is not available" unless system("command -v bash >/dev/null")
		
		adapter = File.join(root, "samovar-executable.bash")
		executable = File.join(root, "samovar-executable")
		completer = File.join(root, "completion-samovar-executable")
		command = File.join(root, "run-target")
		
		File.write(command, "#!/bin/sh\n")
		File.chmod(0o755, command)
		write_helper(:bash)
		File.write(adapter, subject.script(shell: :bash, executable: "samovar"))
		File.write(completer, <<~SCRIPT)
			#!/bin/sh
			printf "executable\\t%s\\tExecutable\\n" "$2"
		SCRIPT
		File.chmod(0o755, completer)
		
		output = IO.popen({"ADAPTER" => adapter}, ["bash", "-c", <<~SCRIPT], &:read)
			PATH="#{root}:$PATH"
			source "$ADAPTER"
			
			COMP_WORDS=(#{executable} -- run-)
			COMP_CWORD=2
			
			__completion_complete
			printf "%s\\n" "${COMPREPLY[@]}"
		SCRIPT
		
		expect(output).to be(:include?, "run-target\n")
	end
	
	it "delegates bash completion to the executable after the split" do
		skip "bash is not available" unless system("command -v bash >/dev/null")
		
		path = File.join(root, "bash-delegate-trace")
		adapter = File.join(root, "samovar-delegate.bash")
		executable = File.join(root, "samovar-delegate")
		completer = File.join(root, "completion-samovar-delegate")
		
		write_helper(:bash)
		File.write(adapter, subject.script(shell: :bash, executable: "samovar"))
		File.write(completer, <<~SCRIPT)
			#!/bin/sh
			printf "delegate\\truby\\tDelegate completion\\tignored=true\\tindex=2\\n"
		SCRIPT
		File.chmod(0o755, completer)
		
		system({"TRACE" => path, "ADAPTER" => adapter}, "bash", "-c", <<~SCRIPT)
			PATH="#{root}:$PATH"
			source "$ADAPTER"
			
			_ruby_completion() {
				printf "words=%s current=%s\\n" "${COMP_WORDS[*]}" "$COMP_CWORD" > "$TRACE"
			}
			
			complete -F _ruby_completion ruby
			
			COMP_WORDS=(#{executable} exec -- ruby --ver)
			COMP_CWORD=4
			
			__completion_complete
		SCRIPT
		
		expect(File.read(path)).to be == "words=ruby --ver current=1\n"
	end
	
	it "passes application arguments from zsh completion" do
		skip "zsh is not available" unless system("command -v zsh >/dev/null")
		
		path = File.join(root, "trace")
		adapter = write_adapter("_samovar", shell: :zsh)
		executable = File.join(root, "samovar")
		completer = File.join(root, "completion-samovar")
		
		File.write(completer, <<~SCRIPT)
			#!/bin/sh
			printf "%s\\n" "$*" > "$TRACE"
			printf "command\\tcompletion\\tGenerate\\n"
		SCRIPT
		File.chmod(0o755, completer)
		
		system({"TRACE" => path}, "zsh", "-fc", <<~SCRIPT)
			PATH="#{root}:$PATH"
			
			_describe() { :; }
			
			words=(#{executable} completion --shell z)
			CURRENT=4
			
			source #{adapter}
		SCRIPT
		
		expect(File.read(path)).to be == "completion --shell z\n"
	end
	
	it "passes application arguments from generic zsh completion" do
		skip "zsh is not available" unless system("command -v zsh >/dev/null")
		
		path = File.join(root, "zsh-generic-trace")
		adapter = write_adapter("_completion", shell: :zsh, executable: nil)
		directory = File.join(root, "zsh-generic")
		executable = File.join(directory, "samovar")
		completer = File.join(directory, "completion-samovar")
		
		Dir.mkdir(directory)
		File.write(completer, <<~SCRIPT)
			#!/bin/sh
			printf "%s\\n" "$*" > "$TRACE"
			printf "command\\tcompletion\\tGenerate\\n"
		SCRIPT
		File.chmod(0o755, completer)
		
		system({"TRACE" => path}, "zsh", "-fc", <<~SCRIPT)
			PATH="#{root}:$PATH"
			
			_describe() { :; }
			
			words=(#{executable} completion --shell z)
			CURRENT=4
			
			source #{adapter}
		SCRIPT
		
		expect(File.read(path)).to be == "completion --shell z\n"
	end
	
	it "uses native executable completion from zsh completion" do
		skip "zsh is not available" unless system("command -v zsh >/dev/null")
		
		path = File.join(root, "zsh-executable-trace")
		adapter = write_adapter("_samovar-executable", shell: :zsh)
		executable = File.join(root, "samovar-executable")
		completer = File.join(root, "completion-samovar-executable")
		
		File.write(completer, <<~SCRIPT)
			#!/bin/sh
			printf "executable\\tr\\tExecutable\\n"
		SCRIPT
		File.chmod(0o755, completer)
		
		system({"TRACE" => path}, "zsh", "-fc", <<~SCRIPT)
			PATH="#{root}:$PATH"
			
			_path_commands() { printf "path-commands\\n" > "$TRACE"; }
			_describe() { :; }
			
			words=(#{executable} -- r)
			CURRENT=3
			
			source #{adapter}
		SCRIPT
		
		expect(File.read(path)).to be == "path-commands\n"
	end
	
	it "delegates zsh completion to the executable after the split" do
		skip "zsh is not available" unless system("command -v zsh >/dev/null")
		
		path = File.join(root, "zsh-delegate-trace")
		adapter = write_adapter("_samovar-delegate", shell: :zsh)
		executable = File.join(root, "samovar-delegate")
		completer = File.join(root, "completion-samovar-delegate")
		
		File.write(completer, <<~SCRIPT)
			#!/bin/sh
			printf "delegate\\truby\\tDelegate completion\\tignored=true\\tindex=2\\n"
		SCRIPT
		File.chmod(0o755, completer)
		
		system({"TRACE" => path}, "zsh", "-fc", <<~SCRIPT)
			PATH="#{root}:$PATH"
			
			_normal() { printf "words=%s current=%s\\n" "$words[*]" "$CURRENT" > "$TRACE"; }
			_describe() { :; }
			
			words=(#{executable} exec -- ruby --ver)
			CURRENT=5
			
			source #{adapter}
		SCRIPT
		
		expect(File.read(path)).to be == "words=ruby --ver current=2\n"
	end
	
	it "passes application arguments from fish completion" do
		skip "fish is not available" unless system("command -v fish >/dev/null")
		
		path = File.join(root, "fish-trace")
		adapter = write_adapter("samovar.fish")
		directory = File.join(root, "fish-command")
		executable = File.join(directory, "samovar")
		completer = File.join(directory, "completion-samovar")
		
		Dir.mkdir(directory)
		File.write(completer, <<~SCRIPT)
			#!/bin/sh
			printf "%s\\n" "$*" >> "$TRACE"
			printf "command\\tcompletion\\tGenerate\\n"
		SCRIPT
		File.chmod(0o755, completer)
		
		system({"TRACE" => path}, "fish", "--no-config", "-c", <<~SCRIPT)
			complete -e -c samovar
			set fish_function_path #{root} $fish_function_path
			source #{adapter}
			set PATH #{root} $PATH
			complete --do-complete "#{executable} completion --shell z" >/dev/null
		SCRIPT
		
		expect(File.readlines(path)).to be(:include?, "completion --shell z\n")
	end
	
	it "passes application arguments from fish completion using a relative executable path" do
		skip "fish is not available" unless system("command -v fish >/dev/null")
		
		path = File.join(root, "fish-relative-trace")
		adapter = write_adapter("samovar-relative.fish")
		directory = File.join(root, "bin")
		executable = File.join(directory, "samovar")
		completer = File.join(directory, "completion-samovar")
		
		Dir.mkdir(directory)
		File.write(completer, <<~SCRIPT)
			#!/bin/sh
			printf "%s\\n" "$*" >> "$TRACE"
			printf "command\\tcompletion\\tGenerate\\n"
		SCRIPT
		File.chmod(0o755, completer)
		
		system({"TRACE" => path}, "fish", "--no-config", "-c", <<~SCRIPT)
			cd #{root}
			complete -e -c samovar
			set fish_function_path #{root} $fish_function_path
			source #{adapter}
			set PATH #{root} $PATH
			complete --do-complete "bin/samovar completion --shell z" >/dev/null
		SCRIPT
		
		expect(File.readlines(path)).to be(:include?, "completion --shell z\n")
	end
	
	it "uses adjacent completion command from fish path completion" do
		skip "fish is not available" unless system("command -v fish >/dev/null")
		
		path = File.join(root, "fish-adjacent-trace")
		adapter = write_adapter("samovar-adjacent.fish")
		directory = File.join(root, "fish-adjacent")
		executable = File.join(directory, "samovar")
		completer = File.join(directory, "completion-samovar")
		
		Dir.mkdir(directory)
		File.write(completer, <<~SCRIPT)
			#!/bin/sh
			printf "%s\\n" "$*" >> "$TRACE"
			printf "command\\tcompletion\\tGenerate\\n"
		SCRIPT
		File.chmod(0o755, completer)
		
		system({"TRACE" => path}, "fish", "--no-config", "-c", <<~SCRIPT)
			complete -e -c samovar
			set fish_function_path #{root} $fish_function_path
			source #{adapter}
			set PATH #{root} $PATH
			complete --do-complete "#{executable} completion --shell z" >/dev/null
		SCRIPT
		
		expect(File.readlines(path)).to be(:include?, "completion --shell z\n")
	end
	
	it "passes an empty token from fish completion" do
		skip "fish is not available" unless system("command -v fish >/dev/null")
		
		path = File.join(root, "fish-empty-trace")
		adapter = write_adapter("samovar-empty.fish")
		directory = File.join(root, "fish-empty-command")
		executable = File.join(directory, "samovar")
		completer = File.join(directory, "completion-samovar")
		
		Dir.mkdir(directory)
		File.write(completer, <<~SCRIPT)
			#!/bin/sh
			printf "%s\\n" "$*" >> "$TRACE"
			printf "command\\tcompletion\\tGenerate\\n"
		SCRIPT
		File.chmod(0o755, completer)
		
		system({"TRACE" => path}, "fish", "--no-config", "-c", <<~SCRIPT)
			complete -e -c samovar
			set fish_function_path #{root} $fish_function_path
			source #{adapter}
			set PATH #{root} $PATH
			complete --do-complete "#{executable} " >/dev/null
		SCRIPT
		
		expect(File.readlines(path)).to be(:include?, "\n")
	end
	
	it "uses native path completion from fish completion" do
		skip "fish is not available" unless system("command -v fish >/dev/null")
		
		path = File.join(root, "fish-path")
		adapter = write_adapter("samovar-path.fish")
		executable = File.join(root, "samovar")
		completer = File.join(root, "completion-samovar")
		
		Dir.mkdir(path)
		File.write(File.join(path, "example.txt"), "")
		File.write(completer, <<~SCRIPT)
			#!/bin/sh
			printf "path\\t%s\\tPath\\n" "$2"
		SCRIPT
		File.chmod(0o755, completer)
		
		output = IO.popen(["fish", "--no-config", "-c", <<~SCRIPT], &:read)
			complete -e -c samovar
			set fish_function_path #{root} $fish_function_path
			source #{adapter}
			set PATH #{root} $PATH
			complete --do-complete "#{executable} --output #{path}/ex"
		SCRIPT
		
		expect(output).to be(:include?, "#{path}/example.txt")
	end
	
	it "uses native executable completion from fish completion" do
		skip "fish is not available" unless system("command -v fish >/dev/null")
		
		adapter = write_adapter("samovar-executable.fish")
		directory = File.join(root, "fish-executable")
		executable = File.join(directory, "samovar")
		completer = File.join(directory, "completion-samovar")
		command = File.join(root, "run-target")
		
		Dir.mkdir(directory)
		File.write(command, "#!/bin/sh\n")
		File.chmod(0o755, command)
		File.write(completer, <<~SCRIPT)
			#!/bin/sh
			printf "executable\\t%s\\tExecutable\\n" "$2"
		SCRIPT
		File.chmod(0o755, completer)
		
		output = IO.popen(["fish", "--no-config", "-c", <<~SCRIPT], &:read)
			complete -e -c samovar
			set fish_function_path #{root} $fish_function_path
			source #{adapter}
			set PATH #{root} $PATH
			complete --do-complete "#{executable} -- run-"
		SCRIPT
		
		expect(output).to be(:include?, "run-target")
	end
	
	it "delegates fish completion to the executable after the split" do
		skip "fish is not available" unless system("command -v fish >/dev/null")
		
		adapter = write_adapter("samovar-delegate.fish")
		directory = File.join(root, "fish-delegate")
		executable = File.join(directory, "samovar")
		completer = File.join(directory, "completion-samovar")
		
		Dir.mkdir(directory)
		File.write(completer, <<~SCRIPT)
			#!/bin/sh
			printf "delegate\\truby\\tDelegate completion\\tignored=true\\tindex=2\\n"
		SCRIPT
		File.chmod(0o755, completer)
		
		output = IO.popen(["fish", "--no-config", "-c", <<~SCRIPT], &:read)
			complete -e -c samovar
			complete -e -c ruby
			complete -c ruby -a delegated-option
			set fish_function_path #{root} $fish_function_path
			source #{adapter}
			set PATH #{root} $PATH
			complete --do-complete "#{executable} exec -- ruby delegated-"
		SCRIPT
		
		expect(output).to be(:include?, "delegated-option")
	end
	
	it "uses generic fish completion for commands with adjacent completers" do
		skip "fish is not available" unless system("command -v fish >/dev/null")
		
		path = File.join(root, "fish-generic-trace")
		adapter = write_adapter("generic.fish", executable: nil)
		directory = File.join(root, "generic-bin")
		executable = File.join(directory, "samovar")
		completer = File.join(directory, "completion-samovar")
		
		Dir.mkdir(directory)
		File.write(completer, <<~SCRIPT)
			#!/bin/sh
			printf "%s\\n" "$*" >> "$TRACE"
			printf "command\\tcompletion\\tGenerate\\n"
		SCRIPT
		File.chmod(0o755, completer)
		
		output = IO.popen({"TRACE" => path}, ["fish", "--no-config", "-c", <<~SCRIPT], &:read)
			set fish_function_path #{root} $fish_function_path
			source #{adapter}
			complete --do-complete "#{executable} "
		SCRIPT
		
		expect(File.readlines(path)).to be(:include?, "\n")
		expect(output).to be(:include?, "completion\tGenerate")
	end
	
	it "keeps fish file completion for commands without adjacent completers" do
		skip "fish is not available" unless system("command -v fish >/dev/null")
		
		path = File.join(root, "generic-file")
		adapter = write_adapter("generic-file.fish", executable: nil)
		File.write(path, "")
		
		output = IO.popen(["fish", "--no-config", "-c", <<~SCRIPT], &:read)
			cd #{root}
			set fish_function_path #{root} $fish_function_path
			source #{adapter}
			complete --do-complete "unknown-command generic-fi"
		SCRIPT
		
		expect(output).to be(:include?, "generic-file")
	end
	
end

# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "completion"
require "sus/fixtures/temporary_directory_context"

describe Completion::Shell do
	include Sus::Fixtures::TemporaryDirectoryContext
	
	it "generates shell completion scripts" do
		expect(subject.script(shell: :bash, executable: "samovar")).to be(:include?, "COMPLETION_INDEX")
		expect(subject.script(shell: :zsh, executable: "samovar")).to be(:include?, "#compdef samovar")
		expect(subject.script(shell: :fish, executable: "samovar")).to be(:include?, "complete -c samovar")
	end
	
	it "uses the basename when registering completion scripts" do
		zsh = subject.script(shell: :zsh, executable: "./samovar")
		bash = subject.script(shell: :bash, executable: "./samovar")
		fish = subject.script(shell: :fish, executable: "./samovar")
		
		expect(zsh).to be(:include?, "#compdef samovar")
		expect(zsh).to be(:include?, "_samovar_completion()")
		expect(bash).to be(:include?, "complete -F _samovar_completion samovar")
		expect(fish).to be(:include?, "complete -c samovar")
	end
	
	it "uses the completed command word as the executable" do
		bash = subject.script(shell: :bash, executable: "samovar")
		zsh = subject.script(shell: :zsh, executable: "samovar")
		fish = subject.script(shell: :fish, executable: "samovar")
		
		expect(bash).to be(:include?, 'local command="${COMP_WORDS[0]}"')
		expect(bash).to be(:include?, 'COMPLETION_INDEX="$index" "$command" "${argv[@]}"')
		expect(zsh).to be(:include?, 'COMPLETION_INDEX="$index" "$command" "${argv[@]}"')
		expect(fish).to be(:include?, "set -l command $argv[1]")
		expect(fish).to be(:include?, "$command $argv")
	end
	
	it "uses zsh array indexing to remove the command word" do
		script = subject.script(shell: :zsh, executable: "samovar")
		
		expect(script).to be(:include?, 'local command="${words[1]}"')
		expect(script).to be(:include?, 'argv=("${(@)words[2,-1]}")')
	end
	
	it "passes application arguments from bash completion" do
		skip "bash is not available" unless system("command -v bash >/dev/null")
		
		path = File.join(root, "bash-trace")
		adapter = File.join(root, "samovar.bash")
		executable = File.join(root, "samovar")
		
		File.write(adapter, subject.script(shell: :bash, executable: "samovar"))
		File.write(executable, <<~SCRIPT)
			#!/bin/sh
			printf "%s|%s\\n" "$COMPLETION_INDEX" "$*" > "$TRACE"
			printf "completion\\tGenerate\\tcommand\\n"
		SCRIPT
		File.chmod(0o755, executable)
		
		system({"TRACE" => path, "ADAPTER" => adapter}, "bash", "-c", <<~SCRIPT)
			source "$ADAPTER"
			
			COMP_WORDS=(#{executable} completion --shell z)
			COMP_CWORD=3
			
			_samovar_completion
		SCRIPT
		
		expect(File.read(path)).to be == "2|completion --shell z\n"
	end
	
	it "passes an empty token from bash completion" do
		skip "bash is not available" unless system("command -v bash >/dev/null")
		
		path = File.join(root, "bash-empty-trace")
		adapter = File.join(root, "samovar-empty.bash")
		executable = File.join(root, "samovar-empty")
		
		File.write(adapter, subject.script(shell: :bash, executable: "samovar"))
		File.write(executable, <<~SCRIPT)
			#!/bin/sh
			printf "%s|%s\\n" "$COMPLETION_INDEX" "$*" > "$TRACE"
			printf "completion\\tGenerate\\tcommand\\n"
		SCRIPT
		File.chmod(0o755, executable)
		
		system({"TRACE" => path, "ADAPTER" => adapter}, "bash", "-c", <<~SCRIPT)
			source "$ADAPTER"
			
			COMP_WORDS=(#{executable} "")
			COMP_CWORD=1
			
			_samovar_completion
		SCRIPT
		
		expect(File.read(path)).to be == "0|\n"
	end
	
	it "passes application arguments from zsh completion" do
		skip "zsh is not available" unless system("command -v zsh >/dev/null")
		
		path = File.join(root, "trace")
		executable = File.join(root, "samovar")
		
		File.write(executable, <<~SCRIPT)
			#!/bin/sh
			printf "%s|%s\\n" "$COMPLETION_INDEX" "$*" > "$TRACE"
			printf "completion\\tGenerate\\tcommand\\n"
		SCRIPT
		File.chmod(0o755, executable)
		
		system({"TRACE" => path}, "zsh", "-fc", <<~SCRIPT)
			
			_describe() { :; }
			
			words=(#{executable} completion --shell z)
			CURRENT=4
			
			source <(ruby -Ilib bin/completion --command samovar --shell zsh)
		SCRIPT
		
		expect(File.read(path)).to be == "2|completion --shell z\n"
	end
	
	it "passes application arguments from fish completion" do
		skip "fish is not available" unless system("command -v fish >/dev/null")
		
		path = File.join(root, "fish-trace")
		directory = File.join(root, "fish-command")
		executable = File.join(directory, "samovar")
		
		Dir.mkdir(directory)
		File.write(executable, <<~SCRIPT)
			#!/bin/sh
			printf "%s|%s\\n" "$COMPLETION_INDEX" "$*" >> "$TRACE"
			printf "completion\\tGenerate\\tcommand\\n"
		SCRIPT
		File.chmod(0o755, executable)
		
		system({"TRACE" => path}, "fish", "--no-config", "-c", <<~SCRIPT)
			complete -e -c samovar
			source (ruby -Ilib bin/completion --command samovar --shell fish | psub)
			set PATH #{root}
			complete --do-complete "#{executable} completion --shell z" >/dev/null
		SCRIPT
		
		expect(File.readlines(path)).to be(:include?, "2|completion --shell z\n")
	end
	
	it "passes application arguments from fish completion using a relative executable path" do
		skip "fish is not available" unless system("command -v fish >/dev/null")
		
		path = File.join(root, "fish-relative-trace")
		directory = File.join(root, "bin")
		executable = File.join(directory, "samovar")
		
		Dir.mkdir(directory)
		File.write(executable, <<~SCRIPT)
			#!/bin/sh
			printf "%s|%s\\n" "$COMPLETION_INDEX" "$*" >> "$TRACE"
			printf "completion\\tGenerate\\tcommand\\n"
		SCRIPT
		File.chmod(0o755, executable)
		
		system({"TRACE" => path}, "fish", "--no-config", "-c", <<~SCRIPT)
			cd #{root}
			complete -e -c samovar
			source (ruby -I#{Dir.pwd}/lib #{Dir.pwd}/bin/completion --command samovar --shell fish | psub)
			set PATH #{root}
			complete --do-complete "bin/samovar completion --shell z" >/dev/null
		SCRIPT
		
		expect(File.readlines(path)).to be(:include?, "2|completion --shell z\n")
	end
	
	it "passes an empty token from fish completion" do
		skip "fish is not available" unless system("command -v fish >/dev/null")
		
		path = File.join(root, "fish-empty-trace")
		directory = File.join(root, "fish-empty-command")
		executable = File.join(directory, "samovar")
		
		Dir.mkdir(directory)
		File.write(executable, <<~SCRIPT)
			#!/bin/sh
			printf "%s|%s\\n" "$COMPLETION_INDEX" "$*" >> "$TRACE"
			printf "completion\\tGenerate\\tcommand\\n"
		SCRIPT
		File.chmod(0o755, executable)
		
		system({"TRACE" => path}, "fish", "--no-config", "-c", <<~SCRIPT)
			complete -e -c samovar
			source (ruby -Ilib bin/completion --command samovar --shell fish | psub)
			set PATH #{root}
			complete --do-complete "#{executable} " >/dev/null
		SCRIPT
		
		expect(File.readlines(path)).to be(:include?, "0|\n")
	end
	
	it "prints candidates as TSV" do
		output = StringIO.new
		result = Protocol::Completion::Result.new([
			Protocol::Completion::Candidate.new(value: "serve", description: "Run the server.", type: :command)
		])
		
		result.print(output)
		
		expect(output.string).to be == "serve\tRun the server.\tcommand\n"
	end
	
	it "exposes candidates" do
		candidate = Protocol::Completion::Candidate.new(value: "serve")
		result = Protocol::Completion::Result.new([candidate])
		
		expect(result.candidates).to be == [candidate]
	end
end

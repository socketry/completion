# frozen_string_literal: true

require_relative "lib/completion/version"

Gem::Specification.new do |spec|
	spec.name = "completion"
	spec.version = Completion::VERSION
	
	spec.summary = "Command-line completion adapter installation."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.cert_chain  = ["release.cert"]
	spec.signing_key = File.expand_path("~/.gem/release.pem")
	
	spec.homepage = "https://github.com/socketry/completion"
	
	spec.metadata = {
		"documentation_uri" => "https://socketry.github.io/completion/",
		"source_code_uri" => "https://github.com/socketry/completion.git",
	}
	
	spec.files = Dir["{bin,guides,lib}/**/*", "*.md", base: __dir__]
	
	spec.executables = ["completion", "completion-completion"]
	
	spec.required_ruby_version = ">= 3.3"
	
	spec.add_dependency "samovar", "~> 2.5"
end

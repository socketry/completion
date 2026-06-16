# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/completion"

require_relative "completion/version"
require_relative "completion/shell"
require_relative "completion/shell/bash"
require_relative "completion/shell/fish"
require_relative "completion/shell/zsh"

module Completion
end

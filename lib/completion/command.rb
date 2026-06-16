# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "samovar"

module Completion
	module Command
		def self.call(...)
			Top.call(...)
		end
	end
end

require_relative "command/top"

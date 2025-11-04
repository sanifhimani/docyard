# frozen_string_literal: true

require_relative "docyard/version"
require_relative "docyard/cli"
require_relative "docyard/initializer"
require_relative "docyard/markdown"

module Docyard
  class Error < StandardError; end
end

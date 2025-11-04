# frozen_string_literal: true

require_relative "docyard/version"
require_relative "docyard/cli"
require_relative "docyard/initializer"
require_relative "docyard/markdown"
require_relative "docyard/router"
require_relative "docyard/renderer"
require_relative "docyard/asset_handler"
require_relative "docyard/server"

module Docyard
  class Error < StandardError; end
end

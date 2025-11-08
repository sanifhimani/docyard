# frozen_string_literal: true

# Core modules
require_relative "docyard/version"
require_relative "docyard/constants"
require_relative "docyard/errors"
require_relative "docyard/logging"

# Utilities
require_relative "docyard/utils/text_formatter"
require_relative "docyard/utils/path_resolver"

# Routing
require_relative "docyard/routing/resolution_result"
require_relative "docyard/router"

# Application components
require_relative "docyard/markdown"
require_relative "docyard/renderer"
require_relative "docyard/asset_handler"
require_relative "docyard/initializer"
require_relative "docyard/server"
require_relative "docyard/cli"

module Docyard
end

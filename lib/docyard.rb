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

# Build components
require_relative "docyard/builder"
require_relative "docyard/build/static_generator"
require_relative "docyard/build/asset_bundler"
require_relative "docyard/build/file_copier"
require_relative "docyard/build/sitemap_generator"
require_relative "docyard/preview_server"

module Docyard
end

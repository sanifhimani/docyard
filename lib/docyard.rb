# frozen_string_literal: true

require_relative "docyard/version"
require_relative "docyard/constants"
require_relative "docyard/errors"
require_relative "docyard/diagnostic"
require_relative "docyard/ui"
require_relative "docyard/utils/logging"

require_relative "docyard/utils/text_formatter"
require_relative "docyard/utils/path_resolver"
require_relative "docyard/utils/url_helpers"
require_relative "docyard/utils/html_helpers"

require_relative "docyard/server/resolution_result"
require_relative "docyard/server/router"
require_relative "docyard/server/asset_handler"
require_relative "docyard/server/dev_server"
require_relative "docyard/server/preview_server"

require_relative "docyard/rendering/markdown"
require_relative "docyard/rendering/renderer"

require_relative "docyard/navigation/sidebar_builder"
require_relative "docyard/navigation/prev_next_builder"

require_relative "docyard/config/branding_resolver"

require_relative "docyard/initializer"
require_relative "docyard/customizer"
require_relative "docyard/cli"

require_relative "docyard/search/pagefind_binary"
require_relative "docyard/search/pagefind_support"
require_relative "docyard/search/dev_indexer"
require_relative "docyard/search/build_indexer"

require_relative "docyard/builder"
require_relative "docyard/build/static_generator"
require_relative "docyard/build/asset_bundler"
require_relative "docyard/build/file_copier"
require_relative "docyard/build/sitemap_generator"

require_relative "docyard/doctor"

module Docyard
end

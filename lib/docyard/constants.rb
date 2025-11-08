# frozen_string_literal: true

module Docyard
  module Constants
    CONTENT_TYPE_HTML = "text/html; charset=utf-8"
    CONTENT_TYPE_JSON = "application/json; charset=utf-8"
    CONTENT_TYPE_CSS = "text/css; charset=utf-8"
    CONTENT_TYPE_JS = "application/javascript; charset=utf-8"

    RELOAD_ENDPOINT = "/_docyard/reload"
    ASSETS_PREFIX = "/assets/"

    INDEX_FILE = "index"
    INDEX_TITLE = "Home"

    MARKDOWN_EXTENSION = ".md"
    HTML_EXTENSION = ".html"

    STATUS_OK = 200
    STATUS_NOT_FOUND = 404
    STATUS_INTERNAL_ERROR = 500
  end
end

# frozen_string_literal: true

module Docyard
  module Constants
    CONTENT_TYPE_HTML = "text/html; charset=utf-8"
    CONTENT_TYPE_JSON = "application/json; charset=utf-8"
    CONTENT_TYPE_CSS = "text/css; charset=utf-8"
    CONTENT_TYPE_JS = "application/javascript; charset=utf-8"

    RELOAD_ENDPOINT = "/_docyard/reload"
    DOCYARD_ASSETS_PREFIX = "/_docyard/"
    PAGEFIND_PREFIX = "/pagefind/"
    PUBLIC_DIR = "docs/public"

    INDEX_FILE = "index"
    INDEX_TITLE = "Home"

    MARKDOWN_EXTENSION = ".md"
    HTML_EXTENSION = ".html"

    STATUS_OK = 200
    STATUS_REDIRECT = 302
    STATUS_NOT_FOUND = 404
    STATUS_INTERNAL_ERROR = 500

    DEFAULT_SITE_TITLE = "Documentation"
    DEFAULT_LOGO_PATH = "_docyard/logo.svg"
    DEFAULT_LOGO_DARK_PATH = "_docyard/logo-dark.svg"
    DEFAULT_FAVICON_PATH = "_docyard/favicon.svg"

    SOCIAL_ICON_MAP = {
      "x" => "x-logo", "twitter" => "x-logo", "discord" => "discord-logo",
      "linkedin" => "linkedin-logo", "youtube" => "youtube-logo", "instagram" => "instagram-logo",
      "facebook" => "facebook-logo", "tiktok" => "tiktok-logo", "twitch" => "twitch-logo",
      "reddit" => "reddit-logo", "mastodon" => "mastodon-logo", "threads" => "threads-logo",
      "pinterest" => "pinterest-logo", "medium" => "medium-logo", "slack" => "slack-logo",
      "gitlab" => "gitlab-logo"
    }.freeze
  end
end

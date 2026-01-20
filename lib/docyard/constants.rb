# frozen_string_literal: true

module Docyard
  module Constants
    CONTENT_TYPE_HTML = "text/html; charset=utf-8"

    DOCYARD_ASSETS_PREFIX = "/_docyard/"
    PAGEFIND_PREFIX = "/_docyard/pagefind/"

    INDEX_FILE = "index"
    MARKDOWN_EXTENSION = ".md"

    STATUS_OK = 200
    STATUS_REDIRECT = 302
    STATUS_NOT_FOUND = 404
    STATUS_INTERNAL_ERROR = 500

    DEFAULT_SITE_TITLE = "Documentation"
    DEFAULT_LOGO_PATH = "_docyard/logo.svg"
    DEFAULT_LOGO_DARK_PATH = "_docyard/logo-dark.svg"
    DEFAULT_FAVICON_PATH = "_docyard/favicon.svg"

    SOCIAL_ICON_MAP = {
      "github" => "github-logo",
      "x" => "x-logo",
      "twitter" => "x-logo",
      "discord" => "discord-logo",
      "slack" => "slack-logo",
      "linkedin" => "linkedin-logo",
      "youtube" => "youtube-logo",
      "twitch" => "twitch-logo",
      "instagram" => "instagram-logo",
      "facebook" => "facebook-logo",
      "tiktok" => "tiktok-logo",
      "reddit" => "reddit-logo",
      "mastodon" => "mastodon-logo",
      "threads" => "threads-logo",
      "pinterest" => "pinterest-logo",
      "medium" => "medium-logo",
      "gitlab" => "gitlab-logo",
      "figma" => "figma-logo",
      "dribbble" => "dribbble-logo",
      "behance" => "behance-logo",
      "codepen" => "codepen-logo",
      "codesandbox" => "codesandbox-logo",
      "notion" => "notion-logo",
      "spotify" => "spotify-logo",
      "soundcloud" => "soundcloud-logo",
      "whatsapp" => "whatsapp-logo",
      "telegram" => "telegram-logo",
      "snapchat" => "snapchat-logo",
      "patreon" => "patreon-logo",
      "paypal" => "paypal-logo",
      "stripe" => "stripe-logo",
      "google-podcasts" => "google-podcasts-logo",
      "apple-podcasts" => "apple-podcasts-logo"
    }.freeze
  end
end

# frozen_string_literal: true

module Docyard
  module LanguageMapping
    TERMINAL_LANGUAGES = %w[bash sh shell powershell].freeze

    LANGUAGE_TO_EXTENSION = {
      "js" => "js",
      "javascript" => "js",
      "ts" => "ts",
      "typescript" => "ts",
      "jsx" => "jsx",
      "tsx" => "tsx",
      "py" => "py",
      "python" => "py",
      "rb" => "rb",
      "ruby" => "rb",
      "go" => "go",
      "golang" => "go",
      "rs" => "rs",
      "rust" => "rs",
      "php" => "php",
      "html" => "html",
      "htm" => "html",
      "html5" => "html",
      "css" => "css",
      "json" => "json",
      "yaml" => "yaml",
      "yml" => "yaml",
      "toml" => "toml",
      "sql" => "sql",
      "mysql" => "mysql",
      "postgresql" => "pgsql",
      "postgres" => "pgsql",
      "pgsql" => "pgsql",
      "graphql" => "graphql",
      "gql" => "graphql",
      "vue" => "vue",
      "svelte" => "svelte",
      "proto" => "proto",
      "protobuf" => "proto"
    }.freeze

    def self.extension_for(language)
      LANGUAGE_TO_EXTENSION[language.to_s.downcase]
    end

    def self.terminal_language?(language)
      TERMINAL_LANGUAGES.include?(language.to_s.downcase)
    end
  end
end

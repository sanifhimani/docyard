# frozen_string_literal: true

require "kramdown"
require "kramdown-parser-gfm"
require "yaml"

module Docyard
  class Markdown
    FRONTMATTER_REGEX = /\A---\s*\n(.*?\n)---\s*\n/m

    attr_reader :raw

    def initialize(raw)
      @raw = raw.freeze
    end

    def frontmatter
      @frontmatter ||= parse_frontmatter
    end

    def content
      @content ||= extract_content
    end

    def html
      @html ||= render_html
    end

    def title
      frontmatter["title"]
    end

    def description
      frontmatter["description"]
    end

    private

    def parse_frontmatter
      match = raw.match(FRONTMATTER_REGEX)
      return {} unless match

      YAML.safe_load(match[1])
    rescue Psych::SyntaxError
      {}
    end

    def extract_content
      raw.sub(FRONTMATTER_REGEX, "").strip
    end

    def render_html
      Kramdown::Document.new(
        content,
        input: "GFM",
        hard_wrap: false,
        syntax_highlighter: nil
      ).to_html
    end
  end
end

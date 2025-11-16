# frozen_string_literal: true

require "kramdown"
require "kramdown-parser-gfm"
require "yaml"
require_relative "components/registry"
require_relative "components/base_processor"
require_relative "components/callout_processor"
require_relative "components/tabs_processor"
require_relative "components/icon_processor"
require_relative "components/code_block_processor"
require_relative "components/table_wrapper_processor"

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

    def sidebar_icon
      frontmatter.dig("sidebar", "icon")
    end

    def sidebar_text
      frontmatter.dig("sidebar", "text")
    end

    def sidebar_collapsed
      frontmatter.dig("sidebar", "collapsed")
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
      preprocessed_content = Components::Registry.run_preprocessors(content)

      raw_html = Kramdown::Document.new(
        preprocessed_content,
        input: "GFM",
        hard_wrap: false,
        syntax_highlighter: "rouge",
        parse_block_html: true
      ).to_html

      Components::Registry.run_postprocessors(raw_html)
    end
  end
end

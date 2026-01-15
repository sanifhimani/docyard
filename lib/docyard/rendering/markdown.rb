# frozen_string_literal: true

require "kramdown"
require "kramdown-parser-gfm"
require "yaml"
require_relative "../components/registry"
require_relative "../components/base_processor"
require_relative "../components/processors/callout_processor"
require_relative "../components/processors/accordion_processor"
require_relative "../components/processors/badge_processor"
require_relative "../components/processors/steps_processor"
require_relative "../components/processors/cards_processor"
require_relative "../components/processors/tabs_processor"
require_relative "../components/processors/icon_processor"
require_relative "../components/processors/code_block_processor"
require_relative "../components/processors/code_snippet_import_preprocessor"
require_relative "../components/processors/include_processor"
require_relative "../components/processors/code_block_options_preprocessor"
require_relative "../components/processors/code_block_diff_preprocessor"
require_relative "../components/processors/code_block_focus_preprocessor"
require_relative "../components/processors/table_wrapper_processor"
require_relative "../components/processors/heading_anchor_processor"
require_relative "../components/processors/custom_anchor_processor"
require_relative "../components/processors/image_caption_processor"
require_relative "../components/processors/video_embed_processor"
require_relative "../components/processors/table_of_contents_processor"
require_relative "../components/aliases"

module Docyard
  class Markdown
    FRONTMATTER_REGEX = /\A---\s*\n(.*?\n)---\s*\n/m

    attr_reader :raw, :config

    def initialize(raw, config: nil, file_path: nil)
      @raw = raw.freeze
      @config = config
      @file_path = file_path
      @context = {}
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

    def sidebar_order
      frontmatter.dig("sidebar", "order")
    end

    def sidebar_badge
      frontmatter.dig("sidebar", "badge")
    end

    def sidebar_badge_type
      frontmatter.dig("sidebar", "badge_type")
    end

    def toc
      @context[:toc] || []
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
      @context[:config] = config&.data
      @context[:current_file] = @file_path
      @context[:docs_root] = "docs"

      preprocessed_content = Components::Registry.run_preprocessors(content, @context)

      raw_html = Kramdown::Document.new(
        preprocessed_content,
        input: "GFM",
        hard_wrap: false,
        syntax_highlighter: "rouge",
        syntax_highlighter_opts: { guess_lang: true },
        parse_block_html: true
      ).to_html

      Components::Registry.run_postprocessors(raw_html, @context)
    end
  end
end

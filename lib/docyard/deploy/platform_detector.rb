# frozen_string_literal: true

module Docyard
  module Deploy
    class PlatformDetector
      DETECTION_RULES = [
        { files: ["vercel.json"], dirs: [".vercel"], platform: "vercel" },
        { files: ["netlify.toml"], dirs: [".netlify"], platform: "netlify" },
        { files: ["wrangler.toml", "wrangler.jsonc"], dirs: [], platform: "cloudflare" },
        { files: [], dirs: [".github/workflows"], platform: "github-pages" }
      ].freeze

      def initialize(project_root = Dir.pwd)
        @project_root = project_root
      end

      def detect
        DETECTION_RULES.each do |rule|
          return rule[:platform] if matches?(rule)
        end
        nil
      end

      private

      def matches?(rule)
        rule[:files].any? { |f| File.exist?(File.join(@project_root, f)) } ||
          rule[:dirs].any? { |d| Dir.exist?(File.join(@project_root, d)) }
      end
    end
  end
end

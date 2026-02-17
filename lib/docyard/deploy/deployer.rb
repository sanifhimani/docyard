# frozen_string_literal: true

require_relative "platform_detector"
require_relative "adapters/vercel"
require_relative "adapters/netlify"
require_relative "adapters/cloudflare"
require_relative "adapters/github_pages"

module Docyard
  module Deploy
    class Deployer
      ADAPTERS = {
        "vercel" => Adapters::Vercel,
        "netlify" => Adapters::Netlify,
        "cloudflare" => Adapters::Cloudflare,
        "github-pages" => Adapters::GithubPages
      }.freeze

      attr_reader :config, :platform, :production, :skip_build

      def initialize(to: nil, production: true, skip_build: false)
        @config = Config.new
        @platform = to
        @production = production
        @skip_build = skip_build
      end

      def deploy
        print_header
        ensure_build
        adapter = resolve_adapter
        print_deploy_info(adapter)
        url = adapter.deploy
        print_success(url)
        true
      rescue DeployError => e
        print_error(e)
        false
      end

      private

      def print_header
        puts
        puts "  #{UI.bold('Docyard')} v#{VERSION}"
        puts "  Deploying..."
        puts
      end

      def ensure_build
        return if skip_build

        require_relative "../builder"
        builder = Builder.new
        raise DeployError, "Build failed" unless builder.build
      end

      def resolve_adapter
        name = platform || detect_platform
        adapter_class = ADAPTERS[name]
        raise DeployError, "Unknown platform: #{name}. Valid options: #{ADAPTERS.keys.join(', ')}" unless adapter_class

        adapter_class.new(output_dir: config.build.output, production: production, config: config)
      end

      def detect_platform
        detected = PlatformDetector.new.detect
        return detected if detected

        raise DeployError,
              "Could not detect platform. Use --to to specify one: #{ADAPTERS.keys.join(', ')}"
      end

      def print_deploy_info(adapter)
        environment = production ? "production" : "preview"
        puts "  #{UI.dim('Platform')}        #{adapter.platform_name}"
        puts "  #{UI.dim('Environment')}     #{environment}"
        puts "  #{UI.dim('Directory')}       #{config.build.output}/"
        puts
      end

      def print_success(url)
        puts "  #{UI.success('Deployed successfully')}"
        puts "  #{url}" if url
        puts
      end

      def print_error(error)
        puts "  #{UI.error('Deploy failed')}"
        puts "  #{error.message}"
        puts
      end
    end
  end
end

# frozen_string_literal: true

require_relative "base"

module Docyard
  module Deploy
    module Adapters
      class Cloudflare < Base
        def platform_name
          "Cloudflare Pages"
        end

        private

        def cli_name
          "wrangler"
        end

        def cli_install_hint
          "npm i -g wrangler"
        end

        def run_deploy
          output = execute_command("wrangler", "pages", "deploy", output_dir, "--project-name=#{project_name}")
          extract_url(output)
        end

        def project_name
          config.title.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
        end

        def extract_url(output)
          output.match(%r{https://\S+\.pages\.dev\S*})&.to_s
        end
      end
    end
  end
end

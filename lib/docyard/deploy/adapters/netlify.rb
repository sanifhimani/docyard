# frozen_string_literal: true

require_relative "base"

module Docyard
  module Deploy
    module Adapters
      class Netlify < Base
        def platform_name
          "Netlify"
        end

        private

        def cli_name
          "netlify"
        end

        def cli_install_hint
          "npm i -g netlify-cli"
        end

        def run_deploy
          args = ["netlify", "deploy", "--dir=#{output_dir}"]
          args << "--prod" if production
          output = execute_command(*args)
          extract_url(output)
        end

        def extract_url(output)
          pattern = production ? /Website URL:\s+(\S+)/ : /Website draft URL:\s+(\S+)/
          output.match(pattern)&.captures&.first
        end
      end
    end
  end
end

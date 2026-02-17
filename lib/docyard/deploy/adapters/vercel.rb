# frozen_string_literal: true

require_relative "base"

module Docyard
  module Deploy
    module Adapters
      class Vercel < Base
        def platform_name
          "Vercel"
        end

        private

        def cli_name
          "vercel"
        end

        def cli_install_hint
          "npm i -g vercel"
        end

        def run_deploy
          args = ["vercel", output_dir, "--yes"]
          args << "--prod" if production
          output = execute_command(*args)
          extract_url(output)
        end

        def extract_url(output)
          output.strip.lines.last&.strip
        end
      end
    end
  end
end

# frozen_string_literal: true

require "open3"

module Docyard
  module Deploy
    module Adapters
      class Base
        attr_reader :output_dir, :production, :config

        def initialize(output_dir:, production:, config:)
          @output_dir = output_dir
          @production = production
          @config = config
        end

        def deploy
          check_cli_installed!
          run_deploy
        end

        def platform_name
          raise NotImplementedError
        end

        private

        def cli_name
          raise NotImplementedError
        end

        def cli_install_hint
          raise NotImplementedError
        end

        def run_deploy
          raise NotImplementedError
        end

        def check_cli_installed!
          _, _, status = Open3.capture3("which", cli_name)
          return if status.success?

          raise DeployError, "'#{cli_name}' CLI not found. Install it with: #{cli_install_hint}"
        end

        def execute_command(*)
          stdout, stderr, status = Open3.capture3(*)
          return stdout if status.success?

          raise DeployError, "Deploy command failed: #{stderr.strip.empty? ? stdout.strip : stderr.strip}"
        end
      end
    end
  end
end

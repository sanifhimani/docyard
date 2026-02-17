# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require_relative "base"

module Docyard
  module Deploy
    module Adapters
      class GithubPages < Base
        def platform_name
          "GitHub Pages"
        end

        private

        def cli_name
          "gh"
        end

        def cli_install_hint
          "https://cli.github.com"
        end

        def run_deploy
          remote_url = fetch_remote_url
          Dir.mktmpdir do |tmp|
            prepare_deploy_dir(tmp)
            push_to_gh_pages(tmp, remote_url)
          end
          build_pages_url(remote_url)
        end

        def fetch_remote_url
          execute_command("git", "remote", "get-url", "origin").strip
        end

        def prepare_deploy_dir(tmp)
          FileUtils.cp_r("#{output_dir}/.", tmp)
          execute_command("git", "-C", tmp, "init", "-b", "gh-pages")
          execute_command("git", "-C", tmp, "add", ".")
          execute_command("git", "-C", tmp, "commit", "-m", "Deploy via docyard")
        end

        def push_to_gh_pages(tmp, remote_url)
          execute_command("git", "-C", tmp, "remote", "add", "origin", remote_url)
          execute_command("git", "-C", tmp, "push", "--force", "origin", "gh-pages")
        end

        def build_pages_url(remote_url)
          match = remote_url.match(%r{github\.com[:/]([^/]+)/([^/.]+)})
          return nil unless match

          owner, repo = match.captures
          "https://#{owner}.github.io/#{repo}/"
        end
      end
    end
  end
end

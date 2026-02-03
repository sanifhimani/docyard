# frozen_string_literal: true

require "digest"
require "fileutils"
require "net/http"
require "open3"
require "rubygems/package"
require "zlib"

module Docyard
  module Search
    class PagefindBinary
      VERSION = "1.3.0"
      CACHE_DIR = File.join(Dir.home, ".docyard", "bin")
      DOWNLOAD_BASE = "https://github.com/CloudCannon/pagefind/releases/download"

      DOWNLOAD_TIMEOUT = 30
      MAX_REDIRECTS = 5

      PLATFORMS = {
        %w[darwin arm64] => "aarch64-apple-darwin",
        %w[darwin x86_64] => "x86_64-apple-darwin",
        %w[linux x86_64] => "x86_64-unknown-linux-musl",
        %w[linux aarch64] => "aarch64-unknown-linux-musl",
        %w[mingw x64] => "x86_64-pc-windows-msvc"
      }.freeze

      class << self
        def executable
          @executable ||= resolve_executable
        end

        def reset!
          @executable = nil
        end

        private

        def resolve_executable
          cached_path || download_binary || npx_fallback
        end

        def cached_path
          path = binary_path
          return path if path && File.executable?(path)

          nil
        end

        def binary_path
          platform = detect_platform
          return nil unless platform

          dir = File.join(CACHE_DIR, "pagefind-#{VERSION}-#{platform}")
          ext = platform.include?("windows") ? ".exe" : ""
          File.join(dir, "pagefind#{ext}")
        end

        def detect_platform
          os = normalize_os(RbConfig::CONFIG["host_os"])
          cpu = normalize_cpu(RbConfig::CONFIG["host_cpu"])
          PLATFORMS[[os, cpu]]
        end

        def normalize_os(host_os)
          case host_os
          when /darwin/i then "darwin"
          when /linux/i then "linux"
          when /mingw|mswin|cygwin/i then "mingw"
          end
        end

        def normalize_cpu(host_cpu)
          case host_cpu
          when /\Aarm64\z/i then "arm64"
          when /\Aaarch64\z/i then "aarch64"
          when /\Ax86_64\z/i, /\Aamd64\z/i then "x86_64"
          when /\Ax64\z/i then "x64"
          end
        end

        def download_binary
          platform = detect_platform
          return nil unless platform

          perform_download(platform)
        rescue StandardError => e
          Docyard.logger.debug("Failed to download Pagefind: #{e.message}")
          nil
        end

        def perform_download(platform)
          tar_url = build_tar_url(platform)
          sha_url = "#{tar_url}.sha256"

          expected_checksum = fetch_checksum(sha_url)
          return nil unless expected_checksum

          tar_data = download_file(tar_url)
          return nil unless tar_data

          return nil unless checksum_valid?(tar_data, expected_checksum)

          extract_binary(tar_data, platform)
        end

        def build_tar_url(platform)
          tar_filename = "pagefind-v#{VERSION}-#{platform}.tar.gz"
          "#{DOWNLOAD_BASE}/v#{VERSION}/#{tar_filename}"
        end

        def checksum_valid?(tar_data, expected_checksum)
          actual_checksum = Digest::SHA256.hexdigest(tar_data)
          return true if actual_checksum == expected_checksum

          Docyard.logger.warn("Pagefind checksum mismatch: expected #{expected_checksum}, got #{actual_checksum}")
          false
        end

        def fetch_checksum(url)
          response = download_file(url)
          return nil unless response

          response.split.first
        end

        def download_file(url, redirect_count = 0)
          return nil if redirect_count >= MAX_REDIRECTS

          uri = URI(url)
          response = http_get(uri)

          case response
          when Net::HTTPSuccess then response.body
          when Net::HTTPRedirection then download_file(response["location"], redirect_count + 1)
          end
        end

        def http_get(uri)
          Net::HTTP.start(
            uri.host, uri.port,
            use_ssl: uri.scheme == "https",
            open_timeout: DOWNLOAD_TIMEOUT,
            read_timeout: DOWNLOAD_TIMEOUT
          ) { |http| http.request(Net::HTTP::Get.new(uri)) }
        end

        def extract_binary(tar_data, platform)
          target_dir = File.join(CACHE_DIR, "pagefind-#{VERSION}-#{platform}")
          FileUtils.mkdir_p(target_dir)

          binary_name = platform.include?("windows") ? "pagefind.exe" : "pagefind"
          target_path = File.join(target_dir, binary_name)

          extract_from_tar(tar_data, binary_name, target_path)
        end

        def extract_from_tar(tar_data, binary_name, target_path)
          io = StringIO.new(tar_data)
          Zlib::GzipReader.wrap(io) do |gz|
            Gem::Package::TarReader.new(gz) do |tar|
              tar.each do |entry|
                next unless entry.file? && File.basename(entry.full_name) == binary_name

                File.binwrite(target_path, entry.read)
                File.chmod(0o755, target_path)
                return target_path
              end
            end
          end
          nil
        end

        def npx_fallback
          _, _, status = Open3.capture3("npx", "pagefind", "--version")
          return "npx" if status.success?

          nil
        rescue Errno::ENOENT
          nil
        end
      end
    end
  end
end

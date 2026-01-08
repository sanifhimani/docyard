# frozen_string_literal: true

module Docyard
  module Build
    class FileCopier
      DOCYARD_OUTPUT_DIR = "_docyard"

      attr_reader :config, :verbose

      def initialize(config, verbose: false)
        @config = config
        @verbose = verbose
      end

      def copy
        puts "\nCopying static assets..."

        count = 0
        count += copy_public_files
        count += copy_branding_assets

        log "[✓] Copied #{count} static files"
        count
      end

      private

      # Copy user's public files from docs/public/ to dist root
      def copy_public_files
        public_dir = Constants::PUBLIC_DIR
        return 0 unless Dir.exist?(public_dir)

        files = find_files_in_dir(public_dir)
        files.each { |file| copy_single_file(file, "#{public_dir}/", config.build.output_dir) }

        log "[✓] Copied #{files.size} public files from #{public_dir}/" if files.any?
        files.size
      end

      def find_files_in_dir(dir)
        Dir.glob(File.join(dir, "**", "*")).select { |f| File.file?(f) }
      end

      def copy_single_file(file, prefix, output_dir)
        relative_path = file.delete_prefix(prefix)
        dest_path = File.join(output_dir, relative_path)

        FileUtils.mkdir_p(File.dirname(dest_path))
        FileUtils.cp(file, dest_path)

        log "  Copied: #{relative_path}" if verbose
      end

      def copy_branding_assets
        count = 0
        count += copy_default_branding_assets
        count += copy_user_branding_assets
        log "[✓] Copied #{count} branding assets" if count.positive?
        count
      end

      # Copy default logos/favicon to dist/_docyard/
      def copy_default_branding_assets
        templates_assets = File.join(__dir__, "..", "templates", "assets")
        count = 0

        ["logo.svg", "logo-dark.svg", "favicon.svg"].each do |asset_file|
          source_path = File.join(templates_assets, asset_file)
          next unless File.exist?(source_path)

          dest_path = File.join(config.build.output_dir, DOCYARD_OUTPUT_DIR, asset_file)
          FileUtils.mkdir_p(File.dirname(dest_path))
          FileUtils.cp(source_path, dest_path)

          log "  Copied default branding: #{asset_file}" if verbose
          count += 1
        end

        count
      end

      def copy_user_branding_assets
        %w[logo logo_dark favicon].sum { |asset_key| copy_single_branding_asset(asset_key) }
      end

      def copy_single_branding_asset(asset_key)
        asset_path = config.branding.send(asset_key)
        return 0 if asset_path.nil? || asset_path.start_with?("http://", "https://")

        # User branding can be in docs/public/ or referenced with _docyard prefix
        full_path = File.join("docs", asset_path)
        return 0 unless File.exist?(full_path)

        dest_path = File.join(config.build.output_dir, asset_path)
        FileUtils.mkdir_p(File.dirname(dest_path))
        FileUtils.cp(full_path, dest_path)

        log "  Copied user branding: #{asset_path}" if verbose
        1
      end

      def log(message)
        puts message
      end
    end
  end
end

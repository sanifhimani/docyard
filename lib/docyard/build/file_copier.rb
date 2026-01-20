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
        Docyard.logger.info("\nCopying static assets...")

        count = 0
        count += copy_public_files
        count += copy_branding_assets

        log "[✓] Copied #{count} static files"
        count
      end

      private

      def copy_public_files
        public_dir = Constants::PUBLIC_DIR
        return 0 unless Dir.exist?(public_dir)

        files = find_files_in_dir(public_dir)
        files.each { |file| copy_single_file(file, "#{public_dir}/", config.build.output) }

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

      def copy_default_branding_assets
        templates_assets = templates_assets_path
        count = copy_branding_files(templates_assets)
        count + copy_fonts(templates_assets)
      end

      def templates_assets_path
        File.join(__dir__, "..", "templates", "assets")
      end

      def copy_branding_files(templates_assets)
        branding_files = %w[logo.svg logo-dark.svg favicon.svg]
        branding_files.sum { |asset_file| copy_asset_to_docyard(templates_assets, asset_file, "default branding") }
      end

      def copy_asset_to_docyard(source_dir, filename, label)
        source_path = File.join(source_dir, filename)
        return 0 unless File.exist?(source_path)

        dest_path = File.join(config.build.output, DOCYARD_OUTPUT_DIR, filename)
        FileUtils.mkdir_p(File.dirname(dest_path))
        FileUtils.cp(source_path, dest_path)
        log "  Copied #{label}: #{filename}" if verbose
        1
      end

      def copy_fonts(templates_assets)
        fonts_dir = File.join(templates_assets, "fonts")
        return 0 unless Dir.exist?(fonts_dir)

        font_files = Dir.glob(File.join(fonts_dir, "*")).select { |f| File.file?(f) }
        font_files.sum { |font_file| copy_single_font(font_file) }
      end

      def copy_single_font(font_file)
        dest_path = File.join(config.build.output, DOCYARD_OUTPUT_DIR, "fonts", File.basename(font_file))
        FileUtils.mkdir_p(File.dirname(dest_path))
        FileUtils.cp(font_file, dest_path)
        log "  Copied font: #{File.basename(font_file)}" if verbose
        1
      end

      def copy_user_branding_assets
        %w[logo favicon].sum { |asset_key| copy_single_branding_asset(asset_key) }
      end

      def branding_asset_path(asset_key)
        case asset_key
        when "logo" then config.branding.logo
        when "favicon" then config.branding.favicon
        end
      end

      def copy_single_branding_asset(asset_key)
        asset_path = branding_asset_path(asset_key)
        return 0 if asset_path.nil? || asset_path.start_with?("http://", "https://")

        full_path = File.join("docs", asset_path)
        return 0 unless File.exist?(full_path)

        dest_path = File.join(config.build.output, asset_path)
        FileUtils.mkdir_p(File.dirname(dest_path))
        FileUtils.cp(full_path, dest_path)

        log "  Copied user branding: #{asset_path}" if verbose
        1
      end

      def log(message)
        Docyard.logger.info(message)
      end
    end
  end
end

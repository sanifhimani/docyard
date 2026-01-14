# frozen_string_literal: true

module Docyard
  module LogoDetector
    module_function

    def auto_detect_logo
      detect_public_file("logo", %w[svg png])
    end

    def auto_detect_favicon
      detect_public_file("favicon", %w[ico svg png])
    end

    def detect_public_file(name, extensions)
      extensions.each do |ext|
        path = File.join(Constants::PUBLIC_DIR, "#{name}.#{ext}")
        return "#{name}.#{ext}" if File.exist?(path)
      end
      nil
    end

    def detect_dark_logo(logo)
      return nil unless logo

      ext = File.extname(logo)
      base = File.basename(logo, ext)
      dark_filename = "#{base}-dark#{ext}"

      if File.absolute_path?(logo)
        dark_path = File.join(File.dirname(logo), dark_filename)
        File.exist?(dark_path) ? dark_path : logo
      else
        dark_path = File.join("docs/public", dark_filename)
        File.exist?(dark_path) ? dark_filename : logo
      end
    end
  end
end

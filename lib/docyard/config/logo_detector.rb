# frozen_string_literal: true

module Docyard
  module LogoDetector
    module_function

    def auto_detect_logo(public_dir: "docs/public")
      detect_public_file("logo", %w[svg png], public_dir: public_dir)
    end

    def auto_detect_favicon(public_dir: "docs/public")
      detect_public_file("favicon", %w[ico svg png], public_dir: public_dir)
    end

    def detect_public_file(name, extensions, public_dir: "docs/public")
      extensions.each do |ext|
        path = File.join(public_dir, "#{name}.#{ext}")
        return "#{name}.#{ext}" if File.exist?(path)
      end
      nil
    end

    def detect_dark_logo(logo, public_dir: "docs/public")
      return nil unless logo

      ext = File.extname(logo)
      base = File.basename(logo, ext)
      dark_filename = "#{base}-dark#{ext}"

      if File.absolute_path?(logo)
        dark_path = File.join(File.dirname(logo), dark_filename)
        File.exist?(dark_path) ? dark_path : logo
      else
        dark_path = File.join(public_dir, dark_filename)
        File.exist?(dark_path) ? dark_filename : logo
      end
    end
  end
end

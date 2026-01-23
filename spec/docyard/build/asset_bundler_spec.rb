# frozen_string_literal: true

RSpec.describe Docyard::Build::AssetBundler do
  let(:temp_dir) { Dir.mktmpdir }
  let(:output_dir) { File.join(temp_dir, "dist") }
  let(:config) do
    Docyard::Config.load(temp_dir).tap do |c|
      c.data["build"]["output"] = output_dir
    end
  end

  before do
    FileUtils.mkdir_p(output_dir)

    File.write(File.join(output_dir, "index.html"), <<~HTML)
      <!DOCTYPE html>
      <html>
      <head>
        <link rel="stylesheet" href="/_docyard/css/main.css">
      </head>
      <body>
        <script src="/_docyard/js/theme.js"></script>
        <script src="/_docyard/js/components.js"></script>
        <script src="/_docyard/js/reload.js"></script>
      </body>
      </html>
    HTML
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#bundle" do
    it "creates bundled CSS and JS files", :aggregate_failures do
      bundler = described_class.new(config, verbose: false)
      bundler.bundle

      css_files = Dir.glob(File.join(output_dir, "_docyard", "bundle.*.css"))
      js_files = Dir.glob(File.join(output_dir, "_docyard", "bundle.*.js"))

      expect(css_files.size).to eq(1)
      expect(js_files.size).to eq(1)
    end

    it "generates content hashes in filenames", :aggregate_failures do
      bundler = described_class.new(config, verbose: false)
      bundler.bundle

      css_file = Dir.glob(File.join(output_dir, "_docyard", "bundle.*.css")).first
      js_file = Dir.glob(File.join(output_dir, "_docyard", "bundle.*.js")).first

      expect(File.basename(css_file)).to match(/^bundle\.[a-f0-9]{8}\.css$/)
      expect(File.basename(js_file)).to match(/^bundle\.[a-f0-9]{8}\.js$/)
    end

    it "minifies CSS content" do
      bundler = described_class.new(config, verbose: false)
      bundler.bundle

      css_file = Dir.glob(File.join(output_dir, "_docyard", "bundle.*.css")).first
      css_content = File.read(css_file)

      expect(css_content).not_to include("\n\n")
    end

    it "minifies JS content" do
      bundler = described_class.new(config, verbose: false)
      bundler.bundle

      js_file = Dir.glob(File.join(output_dir, "_docyard", "bundle.*.js")).first
      js_content = File.read(js_file)

      expect(js_content).not_to include("\n\n")
    end

    it "updates HTML references with hashed filenames", :aggregate_failures do
      bundler = described_class.new(config, verbose: false)
      bundler.bundle

      html_content = File.read(File.join(output_dir, "index.html"))

      expect(html_content).to match(%r{href="/_docyard/bundle\.[a-f0-9]{8}\.css"})
      expect(html_content).to match(%r{src="/_docyard/bundle\.[a-f0-9]{8}\.js"})
      expect(html_content).not_to include("/_docyard/css/main.css")
      expect(html_content).not_to include("/_docyard/js/theme.js")
    end

    it "removes reload.js from production build" do
      bundler = described_class.new(config, verbose: false)
      bundler.bundle

      html_content = File.read(File.join(output_dir, "index.html"))

      expect(html_content).not_to include("reload.js")
    end

    it "removes components.js reference" do
      bundler = described_class.new(config, verbose: false)
      bundler.bundle

      html_content = File.read(File.join(output_dir, "index.html"))

      expect(html_content).not_to include("/_docyard/js/components.js")
    end

    context "with base configuration" do
      before do
        config.data["build"]["base"] = "/my-docs/"
      end

      it "uses base in bundled asset paths", :aggregate_failures do
        bundler = described_class.new(config, verbose: false)
        bundler.bundle

        html_content = File.read(File.join(output_dir, "index.html"))

        expect(html_content).to match(%r{href="/my-docs/_docyard/bundle\.[a-f0-9]{8}\.css"})
        expect(html_content).to match(%r{src="/my-docs/_docyard/bundle\.[a-f0-9]{8}\.js"})
      end

      it "uses base in CSS font-face URLs", :aggregate_failures do
        bundler = described_class.new(config, verbose: false)
        bundler.bundle

        css_file = Dir.glob(File.join(output_dir, "_docyard", "bundle.*.css")).first
        css_content = File.read(css_file)

        expect(css_content).to include("/my-docs/_docyard/fonts/")
        expect(css_content).not_to match(%r{url\(['"]?/_docyard/fonts/})
      end

      it "uses base in JS pagefind import path", :aggregate_failures do
        bundler = described_class.new(config, verbose: false)
        bundler.bundle

        js_file = Dir.glob(File.join(output_dir, "_docyard", "bundle.*.js")).first
        js_content = File.read(js_file)

        expect(js_content).to include('"/my-docs/_docyard/pagefind/')
        expect(js_content).not_to include('"/_docyard/pagefind/')
      end

      it "uses base in JS pagefind baseUrl option", :aggregate_failures do
        bundler = described_class.new(config, verbose: false)
        bundler.bundle

        js_file = Dir.glob(File.join(output_dir, "_docyard", "bundle.*.js")).first
        js_content = File.read(js_file)

        expect(js_content).to include('baseUrl:"/my-docs/"')
        expect(js_content).not_to include('baseUrl:"/"')
      end

      it "uses base in content image paths", :aggregate_failures do
        File.write(File.join(output_dir, "page.html"), <<~HTML)
          <!DOCTYPE html>
          <html>
          <body>
            <img src="/images/photo.jpg" alt="Photo">
            <link rel="stylesheet" href="/_docyard/css/main.css">
          </body>
          </html>
        HTML

        bundler = described_class.new(config, verbose: false)
        bundler.bundle

        html_content = File.read(File.join(output_dir, "page.html"))

        expect(html_content).to include('src="/my-docs/images/photo.jpg"')
        expect(html_content).not_to include('src="/images/photo.jpg"')
      end
    end

    context "with root base" do
      before do
        config.data["build"]["base"] = "/"
      end

      it "uses absolute paths without subdirectory", :aggregate_failures do
        bundler = described_class.new(config, verbose: false)
        bundler.bundle

        html_content = File.read(File.join(output_dir, "index.html"))

        expect(html_content).to match(%r{href="/_docyard/bundle\.[a-f0-9]{8}\.css"})
        expect(html_content).to match(%r{src="/_docyard/bundle\.[a-f0-9]{8}\.js"})
      end
    end

    context "with verbose mode" do
      it "outputs bundling progress" do
        bundler = described_class.new(config, verbose: true)

        output = capture_logger_output { bundler.bundle }

        expect(output).to match(/Bundling CSS/)
      end
    end

    it "preserves whitespace around + in CSS calc expressions" do
      bundler = described_class.new(config, verbose: false)
      bundler.bundle

      css_file = Dir.glob(File.join(output_dir, "_docyard", "bundle.*.css")).first
      css_content = File.read(css_file)

      calc_matches = css_content.scan(/calc\([^)]+\)/)
      calc_with_plus = calc_matches.select { |c| c.include?("+") }

      expect(calc_with_plus).to all(match(/\s\+\s/))
    end
  end
end

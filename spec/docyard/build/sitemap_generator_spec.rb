# frozen_string_literal: true

RSpec.describe Docyard::Build::SitemapGenerator do
  let(:temp_dir) { Dir.mktmpdir }
  let(:output_dir) { File.join(temp_dir, "dist") }
  let(:config) do
    Docyard::Config.load(temp_dir).tap do |c|
      c.data["build"]["output"] = output_dir
    end
  end

  before do
    FileUtils.mkdir_p(output_dir)
    FileUtils.mkdir_p(File.join(output_dir, "getting-started"))

    File.write(File.join(output_dir, "index.html"), "<html></html>")
    File.write(File.join(output_dir, "getting-started", "index.html"), "<html></html>")
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#generate" do
    it "generates sitemap.xml file" do
      generator = described_class.new(config)
      generator.generate

      expect(File.exist?(File.join(output_dir, "sitemap.xml"))).to be true
    end

    it "includes all HTML pages in sitemap", :aggregate_failures do
      generator = described_class.new(config)
      generator.generate

      sitemap_content = File.read(File.join(output_dir, "sitemap.xml"))

      expect(sitemap_content).to include("<loc>/</loc>")
      expect(sitemap_content).to include("<loc>/getting-started</loc>")
    end

    it "includes XML declaration and urlset", :aggregate_failures do
      generator = described_class.new(config)
      generator.generate

      sitemap_content = File.read(File.join(output_dir, "sitemap.xml"))

      expect(sitemap_content).to include('<?xml version="1.0" encoding="UTF-8"?>')
      expect(sitemap_content).to include('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
    end

    it "includes lastmod timestamps", :aggregate_failures do
      generator = described_class.new(config)
      generator.generate

      sitemap_content = File.read(File.join(output_dir, "sitemap.xml"))

      expect(sitemap_content).to include("<lastmod>")
      expect(sitemap_content).to match(%r{<lastmod>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z</lastmod>})
    end

    it "returns the number of URLs generated" do
      generator = described_class.new(config)

      result = generator.generate

      expect(result).to eq(2)
    end

    context "with base configuration" do
      before do
        config.data["build"]["base"] = "/my-docs/"
      end

      it "uses base in sitemap URLs", :aggregate_failures do
        generator = described_class.new(config)
        generator.generate

        sitemap_content = File.read(File.join(output_dir, "sitemap.xml"))

        expect(sitemap_content).to include("<loc>/my-docs/</loc>")
        expect(sitemap_content).to include("<loc>/my-docs/getting-started</loc>")
      end
    end

    context "with root base" do
      before do
        config.data["build"]["base"] = "/"
      end

      it "uses absolute paths without subdirectory", :aggregate_failures do
        generator = described_class.new(config)
        generator.generate

        sitemap_content = File.read(File.join(output_dir, "sitemap.xml"))

        expect(sitemap_content).to include("<loc>/</loc>")
        expect(sitemap_content).to include("<loc>/getting-started</loc>")
      end
    end
  end
end

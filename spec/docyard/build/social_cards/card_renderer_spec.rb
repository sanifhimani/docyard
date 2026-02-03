# frozen_string_literal: true

require "docyard/build/social_cards/card_renderer"

RSpec.describe Docyard::Build::SocialCards::CardRenderer do
  let(:temp_dir) { Dir.mktmpdir }
  let(:output_dir) { File.join(temp_dir, "dist") }
  let(:config) do
    Docyard::Config.load(temp_dir).tap do |c|
      c.data["title"] = "Test Docs"
      c.data["build"]["output"] = output_dir
    end
  end

  let(:concrete_renderer) do
    Class.new(described_class) do
      def content_svg
        '<text x="100" y="100">Test Content</text>'
      end
    end
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "constants" do
    it "defines standard OG image dimensions", :aggregate_failures do
      expect(described_class::WIDTH).to eq(1200)
      expect(described_class::HEIGHT).to eq(630)
    end

    it "defines color constants", :aggregate_failures do
      expect(described_class::BACKGROUND_COLOR).to eq("#121212")
      expect(described_class::DEFAULT_BRAND_COLOR).to eq("#22D3EE")
      expect(described_class::WHITE).to eq("#FFFFFF")
      expect(described_class::GRAY).to eq("#71717A")
    end
  end

  describe "#render" do
    before do
      FileUtils.mkdir_p(output_dir)
    end

    it "creates a PNG file at the output path" do
      output_path = File.join(output_dir, "test.png")
      concrete_renderer.new(config).render(output_path)

      expect(File.exist?(output_path)).to be true
    end

    it "creates parent directories if needed" do
      nested_path = File.join(output_dir, "nested", "dir", "test.png")
      concrete_renderer.new(config).render(nested_path)

      expect(File.exist?(nested_path)).to be true
    end

    it "generates valid PNG file" do
      output_path = File.join(output_dir, "test.png")
      concrete_renderer.new(config).render(output_path)

      content = File.binread(output_path)
      png_signature = "\x89PNG\r\n\x1A\n".b
      expect(content[0, 8]).to eq(png_signature)
    end
  end

  describe "#brand_color" do
    context "with string color in config" do
      before do
        config.data["branding"] = { "color" => "#FF5733" }
      end

      it "returns the configured color" do
        renderer = concrete_renderer.new(config)

        expect(renderer.send(:brand_color)).to eq("#FF5733")
      end
    end

    context "with hash color in config" do
      before do
        config.data["branding"] = { "color" => { "dark" => "#60a5fa", "light" => "#3b82f6" } }
      end

      it "prefers dark color for social cards" do
        renderer = concrete_renderer.new(config)

        expect(renderer.send(:brand_color)).to eq("#60a5fa")
      end
    end

    context "with hash color having only light" do
      before do
        config.data["branding"] = { "color" => { "light" => "#3b82f6" } }
      end

      it "falls back to light color" do
        renderer = concrete_renderer.new(config)

        expect(renderer.send(:brand_color)).to eq("#3b82f6")
      end
    end

    context "without color configured" do
      it "returns default brand color" do
        renderer = concrete_renderer.new(config)

        expect(renderer.send(:brand_color)).to eq(described_class::DEFAULT_BRAND_COLOR)
      end
    end
  end

  describe "#escape_xml" do
    it "escapes ampersand" do
      renderer = concrete_renderer.new(config)
      expect(renderer.send(:escape_xml, "A & B")).to eq("A &amp; B")
    end

    it "escapes less than" do
      renderer = concrete_renderer.new(config)
      expect(renderer.send(:escape_xml, "A < B")).to eq("A &lt; B")
    end

    it "escapes greater than" do
      renderer = concrete_renderer.new(config)
      expect(renderer.send(:escape_xml, "A > B")).to eq("A &gt; B")
    end

    it "escapes double quotes" do
      renderer = concrete_renderer.new(config)
      expect(renderer.send(:escape_xml, 'A "B" C')).to eq("A &quot;B&quot; C")
    end

    it "escapes single quotes" do
      renderer = concrete_renderer.new(config)
      expect(renderer.send(:escape_xml, "A 'B' C")).to eq("A &apos;B&apos; C")
    end

    it "handles multiple special characters" do
      renderer = concrete_renderer.new(config)
      expect(renderer.send(:escape_xml, "<A & 'B'>")).to eq("&lt;A &amp; &apos;B&apos;&gt;")
    end
  end
end

# frozen_string_literal: true

require "docyard/build/social_cards/homepage_card"

RSpec.describe Docyard::Build::SocialCards::HomepageCard, skip: !VIPS_AVAILABLE && "libvips not installed" do
  let(:temp_dir) { Dir.mktmpdir }
  let(:output_dir) { File.join(temp_dir, "dist") }
  let(:config) do
    Docyard::Config.load(temp_dir).tap do |c|
      c.data["title"] = "My Documentation"
      c.data["build"]["output"] = output_dir
    end
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#render" do
    let(:output_path) { File.join(output_dir, "index.png") }

    before do
      FileUtils.mkdir_p(output_dir)
    end

    it "creates a PNG file" do
      card = described_class.new(config, title: "Welcome")
      card.render(output_path)

      expect(File.exist?(output_path)).to be true
    end

    it "generates valid PNG with correct aspect ratio" do
      card = described_class.new(config, title: "Welcome")
      card.render(output_path)

      image = Vips::Image.new_from_file(output_path)
      aspect_ratio = image.width.to_f / image.height
      expected_ratio = 1200.0 / 630
      expect(aspect_ratio).to be_within(0.01).of(expected_ratio)
    end
  end

  describe "#content_svg" do
    it "includes the title text" do
      card = described_class.new(config, title: "Welcome to Docs")
      svg = card.send(:content_svg)

      expect(svg).to include("Welcome to Docs")
    end

    it "includes background curves", :aggregate_failures do
      card = described_class.new(config, title: "Welcome")
      svg = card.send(:content_svg)

      expect(svg).to include("<ellipse")
      expect(svg).to include('stroke="#1f1f1f"')
    end

    it "escapes special characters in title" do
      card = described_class.new(config, title: "A & B <test>")
      svg = card.send(:content_svg)

      expect(svg).to include("A &amp; B &lt;test&gt;")
    end
  end

  describe "#background_curves" do
    it "renders multiple ellipses" do
      card = described_class.new(config, title: "Test")
      svg = card.send(:background_curves)

      expect(svg.scan("<ellipse").count).to be >= 5
    end

    it "uses correct stroke styling", :aggregate_failures do
      card = described_class.new(config, title: "Test")
      svg = card.send(:background_curves)

      expect(svg).to include('fill="none"')
      expect(svg).to include('stroke="#1f1f1f"')
      expect(svg).to include('stroke-width="4"')
    end
  end

  describe "#logo_position_and_anchor" do
    it "returns centered position for homepage", :aggregate_failures do
      card = described_class.new(config, title: "Test")
      x, anchor = card.send(:logo_position_and_anchor)

      expect(anchor).to eq("start")
      expect(x).to be_a(Numeric)
    end
  end

  describe "text wrapping" do
    it "wraps long titles into multiple lines" do
      long_title = "This is a very long title that should wrap to multiple lines"
      card = described_class.new(config, title: long_title)
      svg = card.send(:content_svg)

      expect(svg).to include("<tspan")
    end
  end
end

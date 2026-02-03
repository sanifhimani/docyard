# frozen_string_literal: true

require "docyard/build/social_cards/doc_card"

RSpec.describe Docyard::Build::SocialCards::DocCard do
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
    let(:output_path) { File.join(output_dir, "page.png") }

    before do
      FileUtils.mkdir_p(output_dir)
    end

    it "creates a PNG file" do
      card = described_class.new(config, title: "Getting Started")
      card.render(output_path)

      expect(File.exist?(output_path)).to be true
    end

    it "generates valid PNG with correct aspect ratio" do
      card = described_class.new(config, title: "Getting Started")
      card.render(output_path)

      image = Vips::Image.new_from_file(output_path)
      aspect_ratio = image.width.to_f / image.height
      expected_ratio = 1200.0 / 630
      expect(aspect_ratio).to be_within(0.01).of(expected_ratio)
    end
  end

  describe "#content_svg" do
    context "with title only" do
      it "includes the title text" do
        card = described_class.new(config, title: "Quick Start Guide")
        svg = card.send(:content_svg)

        expect(svg).to include("Quick Start Guide")
      end

      it "does not include section label" do
        card = described_class.new(config, title: "Quick Start")
        svg = card.send(:content_svg)

        expect(svg).not_to match(/font-size="#{described_class::SECTION_LABEL_SIZE}"/)
      end
    end

    context "with section" do
      it "includes uppercase section label" do
        card = described_class.new(config, title: "Quick Start", section: "Getting Started")
        svg = card.send(:content_svg)

        expect(svg).to include("GETTING STARTED")
      end

      it "renders section in brand color" do
        card = described_class.new(config, title: "Quick Start", section: "Guide")
        svg = card.send(:content_svg)

        expect(svg).to include("fill=\"#{described_class::DEFAULT_BRAND_COLOR}\"")
      end
    end

    context "with description" do
      it "includes description text" do
        card = described_class.new(config, title: "Quick Start", description: "Learn the basics")
        svg = card.send(:content_svg)

        expect(svg).to include("Learn the basics")
      end

      it "renders description in gray" do
        card = described_class.new(config, title: "Quick Start", description: "Learn the basics")
        svg = card.send(:content_svg)

        expect(svg).to include("fill=\"#{described_class::GRAY}\"")
      end
    end

    context "with all elements" do
      it "includes section, title, and description", :aggregate_failures do
        card = described_class.new(
          config,
          title: "Configuration",
          section: "Reference",
          description: "Configure your project"
        )
        svg = card.send(:content_svg)

        expect(svg).to include("REFERENCE")
        expect(svg).to include("Configuration")
        expect(svg).to include("Configure your project")
      end
    end

    it "escapes special characters", :aggregate_failures do
      card = described_class.new(
        config,
        title: "A & B",
        section: "C < D",
        description: "E > F"
      )
      svg = card.send(:content_svg)

      expect(svg).to include("A &amp; B")
      expect(svg).to include("C &lt; D")
      expect(svg).to include("E &gt; F")
    end
  end

  describe "vertical centering" do
    it "calculates content height correctly with all elements" do
      card = described_class.new(
        config,
        title: "Title",
        section: "Section",
        description: "Description"
      )
      height = card.send(:calculate_content_height)

      expected = described_class::TITLE_SIZE +
                 described_class::SECTION_LABEL_SIZE +
                 described_class::SECTION_TO_TITLE_GAP +
                 described_class::TITLE_TO_DESC_GAP +
                 described_class::DESCRIPTION_SIZE

      expect(height).to eq(expected)
    end

    it "calculates content height correctly with title only" do
      card = described_class.new(config, title: "Title")
      height = card.send(:calculate_content_height)

      expect(height).to eq(described_class::TITLE_SIZE)
    end
  end
end

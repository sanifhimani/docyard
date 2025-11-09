# frozen_string_literal: true

RSpec.describe Docyard::Icons do
  describe ".render" do
    context "with valid icon name" do
      it "renders heart icon with default weight", :aggregate_failures do
        result = described_class.render("heart")

        expect(result).to include('class="docyard-icon docyard-icon-heart"')
        expect(result).to include('aria-hidden="true"')
        expect(result).to include("<svg")
        expect(result).to include('viewBox="0 0 256 256"')
        expect(result).to include('fill="currentColor"')
      end

      it "renders check icon", :aggregate_failures do
        result = described_class.render("check")

        expect(result).to include("docyard-icon-check")
        expect(result).to include("<path")
      end
    end

    context "with different weights" do
      it "renders bold weight", :aggregate_failures do
        result = described_class.render("heart", "bold")

        expect(result).to include("docyard-icon-heart")
        expect(result).to include("<path")
      end

      it "renders fill weight", :aggregate_failures do
        result = described_class.render("heart", "fill")

        expect(result).to include("docyard-icon-heart")
        expect(result).to include("<path")
      end

      it "renders light weight", :aggregate_failures do
        result = described_class.render("heart", "light")

        expect(result).to include("docyard-icon-heart")
        expect(result).to include("<path")
      end

      it "renders thin weight", :aggregate_failures do
        result = described_class.render("heart", "thin")

        expect(result).to include("docyard-icon-heart")
        expect(result).to include("<path")
      end

      it "renders duotone weight", :aggregate_failures do
        result = described_class.render("heart", "duotone")

        expect(result).to include("docyard-icon-heart")
        expect(result).to include("<path")
      end
    end

    context "with single-letter icon" do
      it "renders x icon", :aggregate_failures do
        result = described_class.render("x")

        expect(result).to include("docyard-icon-x")
        expect(result).to include("<path")
      end
    end

    context "with hyphenated icon name" do
      it "renders arrow-right icon", :aggregate_failures do
        result = described_class.render("arrow-right")

        expect(result).to include("docyard-icon-arrow-right")
        expect(result).to include("<path")
      end

      it "renders rocket-launch icon", :aggregate_failures do
        result = described_class.render("rocket-launch")

        expect(result).to include("docyard-icon-rocket-launch")
        expect(result).to include("<path")
      end
    end

    context "with invalid icon name" do
      it "returns nil for unknown icon" do
        result = described_class.render("nonexistent")

        expect(result).to be_nil
      end

      it "returns nil for unknown weight" do
        result = described_class.render("heart", "invalid-weight")

        expect(result).to be_nil
      end
    end

    context "with library parameter" do
      it "uses default phosphor library" do
        result = described_class.render("heart", "regular", library: :phosphor)

        expect(result).to include("docyard-icon-heart")
      end

      it "returns nil for unknown library" do
        result = described_class.render("heart", "regular", library: :unknown)

        expect(result).to be_nil
      end
    end
  end
end

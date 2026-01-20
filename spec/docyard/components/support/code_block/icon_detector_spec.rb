# frozen_string_literal: true

RSpec.describe Docyard::Components::Support::CodeBlock::IconDetector do
  describe ".detect" do
    context "with nil title" do
      it "returns nil values" do
        result = described_class.detect(nil, "ruby")

        expect(result).to eq({ title: nil, icon: nil, icon_source: nil })
      end
    end

    context "with manual icon syntax" do
      it "extracts icon from :icon: prefix" do
        result = described_class.detect(":file-code: My Title", "ruby")

        expect(result[:icon]).to eq("file-code")
      end

      it "extracts title after icon syntax" do
        result = described_class.detect(":file-code: My Title", "ruby")

        expect(result[:title]).to eq("My Title")
      end

      it "sets icon_source to phosphor for manual icons" do
        result = described_class.detect(":file-code: My Title", "ruby")

        expect(result[:icon_source]).to eq("phosphor")
      end

      it "handles icon names with numbers" do
        result = described_class.detect(":icon-123: Title", "ruby")

        expect(result[:icon]).to eq("icon-123")
      end

      it "strips whitespace from title" do
        result = described_class.detect(":icon:   Spaced Title  ", "ruby")

        expect(result[:title]).to eq("Spaced Title")
      end
    end

    context "with plain title and language" do
      it "uses the language as icon", :aggregate_failures do
        result = described_class.detect("My Title", "ruby")

        expect(result[:icon]).to eq("ruby")
        expect(result[:icon_source]).to eq("language")
      end

      it "preserves original title" do
        result = described_class.detect("Original Title", "ruby")

        expect(result[:title]).to eq("Original Title")
      end

      it "handles bash language", :aggregate_failures do
        result = described_class.detect("Install", "bash")

        expect(result[:icon]).to eq("bash")
        expect(result[:icon_source]).to eq("language")
      end

      it "handles javascript language", :aggregate_failures do
        result = described_class.detect("Code", "javascript")

        expect(result[:icon]).to eq("javascript")
        expect(result[:icon_source]).to eq("language")
      end

      it "handles unknown language", :aggregate_failures do
        result = described_class.detect("Code", "unknown-lang")

        expect(result[:icon]).to eq("unknown-lang")
        expect(result[:icon_source]).to eq("language")
      end
    end

    context "when language is nil" do
      it "returns language icon with nil value", :aggregate_failures do
        result = described_class.detect("My Title", nil)

        expect(result[:icon]).to be_nil
        expect(result[:icon_source]).to eq("language")
      end
    end
  end

  describe ".render_icon" do
    context "with nil language" do
      it "returns empty string" do
        result = described_class.render_icon(nil)

        expect(result).to eq("")
      end
    end

    context "with empty language" do
      it "returns empty string" do
        result = described_class.render_icon("")

        expect(result).to eq("")
      end
    end

    context "with known language" do
      it "returns devicon HTML for ruby" do
        result = described_class.render_icon("ruby")

        expect(result).to include("devicon-ruby-plain")
      end

      it "returns devicon HTML for javascript" do
        result = described_class.render_icon("javascript")

        expect(result).to include("devicon-javascript-plain")
      end

      it "returns devicon HTML for bash" do
        result = described_class.render_icon("bash")

        expect(result).to include("devicon-bash-plain")
      end
    end

    context "with unknown language" do
      it "returns empty string" do
        result = described_class.render_icon("unknown-lang")

        expect(result).to eq("")
      end
    end
  end
end

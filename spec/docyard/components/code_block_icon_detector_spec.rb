# frozen_string_literal: true

RSpec.describe Docyard::Components::CodeBlockIconDetector do
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

    context "when language is a terminal language" do
      %w[bash sh shell powershell].each do |lang|
        it "uses terminal-window icon for #{lang}", :aggregate_failures do
          result = described_class.detect("My Title", lang)

          expect(result[:icon]).to eq("terminal-window")
          expect(result[:icon_source]).to eq("phosphor")
        end
      end
    end

    context "when language has a file extension mapping" do
      it "uses file extension icon for ruby", :aggregate_failures do
        result = described_class.detect("My Title", "ruby")

        expect(result[:icon]).to eq("rb")
        expect(result[:icon_source]).to eq("file-extension")
      end

      it "uses file extension icon for javascript", :aggregate_failures do
        result = described_class.detect("My Title", "javascript")

        expect(result[:icon]).to eq("js")
        expect(result[:icon_source]).to eq("file-extension")
      end

      it "uses file extension icon for typescript", :aggregate_failures do
        result = described_class.detect("My Title", "typescript")

        expect(result[:icon]).to eq("ts")
        expect(result[:icon_source]).to eq("file-extension")
      end

      it "uses file extension icon for python", :aggregate_failures do
        result = described_class.detect("My Title", "python")

        expect(result[:icon]).to eq("py")
        expect(result[:icon_source]).to eq("file-extension")
      end
    end

    context "when language has no mapping" do
      it "uses generic file icon", :aggregate_failures do
        result = described_class.detect("My Title", "unknown-lang")

        expect(result[:icon]).to eq("file")
        expect(result[:icon_source]).to eq("phosphor")
      end
    end

    context "when language is nil" do
      it "returns nil icon", :aggregate_failures do
        result = described_class.detect("My Title", nil)

        expect(result[:icon]).to be_nil
        expect(result[:icon_source]).to be_nil
      end
    end

    context "with plain title" do
      it "preserves original title when no manual icon" do
        result = described_class.detect("Original Title", "ruby")

        expect(result[:title]).to eq("Original Title")
      end
    end
  end

  describe ".auto_detect_icon" do
    context "with nil language" do
      it "returns nil values" do
        result = described_class.auto_detect_icon(nil)

        expect(result).to eq([nil, nil])
      end
    end

    context "with terminal language" do
      it "returns terminal-window icon" do
        result = described_class.auto_detect_icon("bash")

        expect(result).to eq(%w[terminal-window phosphor])
      end
    end

    context "with known language" do
      it "returns file extension icon" do
        result = described_class.auto_detect_icon("ruby")

        expect(result).to eq(%w[rb file-extension])
      end
    end

    context "with unknown language" do
      it "returns generic file icon" do
        result = described_class.auto_detect_icon("unknown")

        expect(result).to eq(%w[file phosphor])
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe Docyard::Components::Support::CodeBlock::LineNumberResolver do
  describe ".enabled?" do
    it "returns false for :no-line-numbers option" do
      expect(described_class.enabled?(":no-line-numbers")).to be false
    end

    it "returns true for :line-numbers option" do
      expect(described_class.enabled?(":line-numbers")).to be true
    end

    it "returns true for :line-numbers=5 option" do
      expect(described_class.enabled?(":line-numbers=5")).to be true
    end

    it "returns false by default when option is nil" do
      expect(described_class.enabled?(nil)).to be false
    end

    it "returns false by default for empty option" do
      expect(described_class.enabled?("")).to be false
    end

    it "returns global_default when option does not specify line numbers", :aggregate_failures do
      expect(described_class.enabled?(nil, global_default: true)).to be true
      expect(described_class.enabled?("", global_default: true)).to be true
    end

    it "overrides global_default when option specifies :no-line-numbers" do
      expect(described_class.enabled?(":no-line-numbers", global_default: true)).to be false
    end

    it "overrides global_default when option specifies :line-numbers" do
      expect(described_class.enabled?(":line-numbers", global_default: false)).to be true
    end
  end

  describe ".start_line" do
    it "returns 1 when option is nil" do
      expect(described_class.start_line(nil)).to eq(1)
    end

    it "returns 1 when option has no equals sign" do
      expect(described_class.start_line(":line-numbers")).to eq(1)
    end

    it "extracts start line from :line-numbers=N format", :aggregate_failures do
      expect(described_class.start_line(":line-numbers=5")).to eq(5)
      expect(described_class.start_line(":line-numbers=100")).to eq(100)
    end

    it "returns 1 for empty option" do
      expect(described_class.start_line("")).to eq(1)
    end
  end

  describe ".generate_numbers" do
    it "generates line numbers starting from 1 by default" do
      expect(described_class.generate_numbers("line1\nline2\nline3")).to eq([1, 2, 3])
    end

    it "generates line numbers starting from custom start" do
      expect(described_class.generate_numbers("line1\nline2\nline3", 5)).to eq([5, 6, 7])
    end

    it "returns at least one line number for empty code" do
      expect(described_class.generate_numbers("")).to eq([1])
    end

    it "handles single line code" do
      expect(described_class.generate_numbers("single line")).to eq([1])
    end

    it "handles code with trailing newline" do
      expect(described_class.generate_numbers("line1\nline2\n")).to eq([1, 2])
    end
  end
end

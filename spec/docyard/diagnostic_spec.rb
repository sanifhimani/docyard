# frozen_string_literal: true

RSpec.describe Docyard::Diagnostic do
  describe "initialization" do
    it "creates a diagnostic with required attributes", :aggregate_failures do
      diagnostic = described_class.new(
        severity: :error,
        category: :CONFIG,
        code: "CONFIG_UNKNOWN_KEY",
        message: "unknown key"
      )

      expect(diagnostic.severity).to eq(:error)
      expect(diagnostic.category).to eq(:CONFIG)
      expect(diagnostic.code).to eq("CONFIG_UNKNOWN_KEY")
      expect(diagnostic.message).to eq("unknown key")
    end

    it "creates a diagnostic with all attributes", :aggregate_failures do
      diagnostic = described_class.new(
        severity: :warning,
        category: :CONTENT,
        code: "INCLUDE_NOT_FOUND",
        message: "file not found",
        file: "docs/intro.md",
        line: 15,
        field: nil,
        details: { target: "shared/header.md" },
        fix: { type: :remove }
      )

      expect(diagnostic.file).to eq("docs/intro.md")
      expect(diagnostic.line).to eq(15)
      expect(diagnostic.details).to eq({ target: "shared/header.md" })
      expect(diagnostic.fix).to eq({ type: :remove })
    end

    it "freezes the object" do
      diagnostic = described_class.new(
        severity: :error,
        category: :CONFIG,
        code: "TEST",
        message: "test"
      )

      expect(diagnostic).to be_frozen
    end

    it "rejects invalid severity" do
      expect do
        described_class.new(
          severity: :critical,
          category: :CONFIG,
          code: "TEST",
          message: "test"
        )
      end.to raise_error(ArgumentError, /Invalid severity/)
    end

    it "rejects invalid category" do
      expect do
        described_class.new(
          severity: :error,
          category: :UNKNOWN,
          code: "TEST",
          message: "test"
        )
      end.to raise_error(ArgumentError, /Invalid category/)
    end

    it "accepts string severity and converts to symbol" do
      diagnostic = described_class.new(
        severity: "error",
        category: :CONFIG,
        code: "TEST",
        message: "test"
      )

      expect(diagnostic.severity).to eq(:error)
    end

    it "accepts string category and converts to symbol" do
      diagnostic = described_class.new(
        severity: :error,
        category: "CONFIG",
        code: "TEST",
        message: "test"
      )

      expect(diagnostic.category).to eq(:CONFIG)
    end
  end

  describe "#error?" do
    it "returns true for error severity", :aggregate_failures do
      diagnostic = described_class.new(
        severity: :error,
        category: :CONFIG,
        code: "TEST",
        message: "test"
      )

      expect(diagnostic.error?).to be true
      expect(diagnostic.warning?).to be false
    end
  end

  describe "#warning?" do
    it "returns true for warning severity", :aggregate_failures do
      diagnostic = described_class.new(
        severity: :warning,
        category: :CONFIG,
        code: "TEST",
        message: "test"
      )

      expect(diagnostic.warning?).to be true
      expect(diagnostic.error?).to be false
    end
  end

  describe "#fixable?" do
    it "returns true when fix has a type" do
      diagnostic = described_class.new(
        severity: :error,
        category: :CONFIG,
        code: "TEST",
        message: "test",
        fix: { type: :rename, from: "titl", to: "title" }
      )

      expect(diagnostic.fixable?).to be true
    end

    it "returns false when fix is nil" do
      diagnostic = described_class.new(
        severity: :error,
        category: :CONFIG,
        code: "TEST",
        message: "test"
      )

      expect(diagnostic.fixable?).to be false
    end

    it "returns false when fix has no type" do
      diagnostic = described_class.new(
        severity: :error,
        category: :CONFIG,
        code: "TEST",
        message: "test",
        fix: { suggestion: "something" }
      )

      expect(diagnostic.fixable?).to be false
    end
  end

  describe "#location" do
    it "returns field when present" do
      diagnostic = described_class.new(
        severity: :error,
        category: :CONFIG,
        code: "TEST",
        message: "test",
        field: "search.enabled"
      )

      expect(diagnostic.location).to eq("search.enabled")
    end

    it "returns file:line when both present" do
      diagnostic = described_class.new(
        severity: :error,
        category: :CONTENT,
        code: "TEST",
        message: "test",
        file: "docs/intro.md",
        line: 15
      )

      expect(diagnostic.location).to eq("docs/intro.md:15")
    end

    it "returns file when only file present" do
      diagnostic = described_class.new(
        severity: :warning,
        category: :ORPHAN,
        code: "TEST",
        message: "test",
        file: "docs/old-page.md"
      )

      expect(diagnostic.location).to eq("docs/old-page.md")
    end

    it "returns nil when no location info" do
      diagnostic = described_class.new(
        severity: :error,
        category: :CONFIG,
        code: "TEST",
        message: "test"
      )

      expect(diagnostic.location).to be_nil
    end
  end

  describe "#format_line" do
    it "formats error with location and message" do
      diagnostic = described_class.new(
        severity: :error,
        category: :CONFIG,
        code: "CONFIG_UNKNOWN_KEY",
        message: "unknown key, did you mean 'title'?",
        field: "titl"
      )

      expect(diagnostic.format_line).to eq("    error   titl                       unknown key, did you mean 'title'?")
    end

    it "formats warning with location and message" do
      diagnostic = described_class.new(
        severity: :warning,
        category: :COMPONENT,
        code: "COMPONENT_EMPTY_TABS",
        message: "empty tabs block",
        file: "tutorial.md",
        line: 45
      )

      expect(diagnostic.format_line).to eq("    warn    tutorial.md:45             empty tabs block")
    end

    it "includes [fixable] suffix when fixable" do
      diagnostic = described_class.new(
        severity: :error,
        category: :CONFIG,
        code: "CONFIG_UNKNOWN_KEY",
        message: "unknown key",
        field: "titl",
        fix: { type: :rename, to: "title" }
      )

      expect(diagnostic.format_line).to include("[fixable]")
    end
  end

  describe "#to_h" do
    it "returns hash with all present attributes", :aggregate_failures do
      diagnostic = described_class.new(
        severity: :error,
        category: :CONFIG,
        code: "CONFIG_UNKNOWN_KEY",
        message: "unknown key",
        field: "titl",
        fix: { type: :rename }
      )

      hash = diagnostic.to_h

      expect(hash[:severity]).to eq(:error)
      expect(hash[:category]).to eq(:CONFIG)
      expect(hash[:code]).to eq("CONFIG_UNKNOWN_KEY")
      expect(hash[:message]).to eq("unknown key")
      expect(hash[:field]).to eq("titl")
      expect(hash[:fix]).to eq({ type: :rename })
    end

    it "excludes nil attributes", :aggregate_failures do
      diagnostic = described_class.new(
        severity: :error,
        category: :CONFIG,
        code: "TEST",
        message: "test"
      )

      hash = diagnostic.to_h

      expect(hash).not_to have_key(:file)
      expect(hash).not_to have_key(:line)
      expect(hash).not_to have_key(:field)
      expect(hash).not_to have_key(:details)
      expect(hash).not_to have_key(:fix)
    end
  end
end

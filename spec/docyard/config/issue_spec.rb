# frozen_string_literal: true

RSpec.describe Docyard::Config::Issue do
  describe "#error?" do
    it "returns true for error severity" do
      issue = described_class.new(severity: :error, field: "title", message: "is required")
      expect(issue).to be_error
    end

    it "returns false for warning severity" do
      issue = described_class.new(severity: :warning, field: "title", message: "recommended")
      expect(issue).not_to be_error
    end
  end

  describe "#warning?" do
    it "returns true for warning severity" do
      issue = described_class.new(severity: :warning, field: "title", message: "recommended")
      expect(issue).to be_warning
    end

    it "returns false for error severity" do
      issue = described_class.new(severity: :error, field: "title", message: "is required")
      expect(issue).not_to be_warning
    end
  end

  describe "#fixable?" do
    it "returns true when fix has a type" do
      issue = described_class.new(
        severity: :error,
        field: "title",
        message: "typo",
        fix: { type: :replace, value: "correct" }
      )
      expect(issue).to be_fixable
    end

    it "returns false when fix is nil" do
      issue = described_class.new(severity: :error, field: "title", message: "error")
      expect(issue).not_to be_fixable
    end

    it "returns false when fix has no type" do
      issue = described_class.new(severity: :error, field: "title", message: "error", fix: {})
      expect(issue).not_to be_fixable
    end
  end

  describe "#format_short" do
    it "formats field and message", :aggregate_failures do
      issue = described_class.new(severity: :error, field: "title", message: "is required")
      expect(issue.format_short).to include("title")
      expect(issue.format_short).to include("is required")
    end

    it "adds [fixable] suffix when fixable" do
      issue = described_class.new(
        severity: :error,
        field: "base",
        message: "must start with /",
        fix: { type: :replace, value: "/docs" }
      )
      expect(issue.format_short).to include("[fixable]")
    end

    it "does not add [fixable] when not fixable" do
      issue = described_class.new(severity: :error, field: "title", message: "is required")
      expect(issue.format_short).not_to include("[fixable]")
    end
  end
end

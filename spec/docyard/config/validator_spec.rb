# frozen_string_literal: true

RSpec.describe Docyard::Config::Validator do
  let(:valid_data) { { "title" => "Test", "description" => "A description" } }
  let(:source_dir) { "docs" }

  def validator(data)
    described_class.new(data, source_dir: source_dir)
  end

  describe "#validate_all" do
    it "returns empty array when config is valid" do
      issues = validator(valid_data).validate_all
      expect(issues.select(&:error?)).to be_empty
    end

    it "collects all issues without raising" do
      data = { "title" => 123, "description" => "Test", "unknown_key" => "value" }
      issues = validator(data).validate_all
      expect(issues.count(&:error?)).to eq(2)
    end
  end

  describe "type validation" do
    it "validates string fields" do
      data = { "title" => 123, "description" => "Test" }
      issues = validator(data).validate_all
      error = issues.find { |i| i.field == "title" }
      expect(error.message).to include("must be a string")
    end

    it "validates boolean fields" do
      data = { "description" => "Test", "branding" => { "credits" => "yes" } }
      issues = validator(data).validate_all
      error = issues.find { |i| i.field == "branding.credits" }
      expect(error.message).to include("must be true or false")
    end

    it "validates url fields warn for non-http urls" do
      data = { "description" => "Test", "url" => "not-a-url" }
      issues = validator(data).validate_all
      warning = issues.find { |i| i.field == "url" }
      expect(warning.message).to include("valid URL")
    end

    it "validates enum fields with allowed values", :aggregate_failures do
      data = { "description" => "Test", "sidebar" => "invalid" }
      issues = validator(data).validate_all
      error = issues.find { |i| i.field == "sidebar" }
      expect(error.message).to include("invalid value")
      expect(error.details[:expected]).to include("config")
    end

    it "validates array max_items constraint", :aggregate_failures do
      data = { "description" => "Test", "navigation" => { "cta" => [{}, {}, {}] } }
      issues = validator(data).validate_all
      error = issues.find { |i| i.field == "navigation.cta" }
      expect(error.message).to include("too many items")
      expect(error.details[:expected]).to include("maximum 2")
    end
  end

  describe "unknown key detection" do
    it "reports unknown top-level keys" do
      data = { "description" => "Test", "unknown_key" => "value" }
      issues = validator(data).validate_all
      error = issues.find { |i| i.field == "unknown_key" }
      expect(error.message).to include("unknown key")
    end

    it "reports unknown nested keys" do
      data = { "description" => "Test", "branding" => { "unknown_nested" => "value" } }
      issues = validator(data).validate_all
      error = issues.find { |i| i.field == "branding.unknown_nested" }
      expect(error).not_to be_nil
    end

    it "suggests corrections for typos" do
      data = { "description" => "Test", "tittle" => "Test" }
      issues = validator(data).validate_all
      error = issues.find { |i| i.field == "tittle" }
      expect(error.message).to include("did you mean 'title'")
    end

    it "allows extra keys in socials section" do
      data = { "description" => "Test", "socials" => { "custom_social" => "https://example.com" } }
      issues = validator(data).validate_all
      expect(issues.select(&:error?)).to be_empty
    end
  end

  describe "format validation" do
    it "validates build.output cannot contain slashes" do
      data = { "description" => "Test", "build" => { "output" => "dist/foo" } }
      issues = validator(data).validate_all
      error = issues.find { |i| i.field == "build.output" }
      expect(error.message).to include("cannot contain slashes")
    end

    it "validates build.base must start with slash" do
      data = { "description" => "Test", "build" => { "base" => "docs" } }
      issues = validator(data).validate_all
      error = issues.find { |i| i.field == "build.base" }
      expect(error.message).to include("must start with /")
    end

    it "provides fix for missing leading slash" do
      data = { "description" => "Test", "build" => { "base" => "docs" } }
      issues = validator(data).validate_all
      error = issues.find { |i| i.field == "build.base" }
      expect(error.fix).to eq({ type: :replace, value: "/docs" })
    end
  end

  describe "cross-field validation" do
    it "requires analytics when feedback is enabled" do
      data = { "description" => "Test", "feedback" => { "enabled" => true } }
      issues = validator(data).validate_all
      error = issues.find { |i| i.field == "feedback.enabled" }
      expect(error.message).to include("requires analytics")
    end

    it "passes when feedback enabled with analytics configured" do
      data = {
        "description" => "Test",
        "feedback" => { "enabled" => true },
        "analytics" => { "google" => "G-123" }
      }
      issues = validator(data).validate_all
      expect(issues.select(&:error?)).to be_empty
    end
  end

  describe "fixable issues" do
    it "marks boolean typos as fixable", :aggregate_failures do
      data = { "description" => "Test", "branding" => { "credits" => "yes" } }
      issues = validator(data).validate_all
      error = issues.find { |i| i.field == "branding.credits" }
      expect(error).to be_fixable
      expect(error.fix[:value]).to be(true)
    end

    it "marks enum typos with suggestions as fixable", :aggregate_failures do
      data = { "description" => "Test", "sidebar" => "conifg" }
      issues = validator(data).validate_all
      error = issues.find { |i| i.field == "sidebar" }
      expect(error).to be_fixable
      expect(error.fix[:value]).to eq("config")
    end

    it "marks unknown key with suggestion as fixable", :aggregate_failures do
      data = { "description" => "Test", "tittle" => "Test" }
      issues = validator(data).validate_all
      error = issues.find { |i| i.field == "tittle" }
      expect(error).to be_fixable
      expect(error.fix[:type]).to eq(:rename)
    end
  end

  describe "#errors and #warnings" do
    it "separates errors from warnings", :aggregate_failures do
      data = { "title" => 123, "url" => "not-a-url" }
      v = validator(data)
      v.validate_all
      expect(v.errors.size).to eq(1)
      expect(v.warnings.size).to eq(1)
    end
  end
end

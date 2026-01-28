# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ConfigChecker do
  let(:valid_config_data) { { "title" => "Test", "description" => "A test site" } }

  def config_with(data)
    instance_double(Docyard::Config, data: data, source: "docs")
  end

  describe "#check" do
    it "returns empty array for valid config" do
      config = config_with(valid_config_data)
      checker = described_class.new(config)
      expect(checker.check).to be_empty
    end

    it "returns issues for invalid config", :aggregate_failures do
      config = config_with({ "title" => 123 })
      checker = described_class.new(config)
      issues = checker.check
      expect(issues).not_to be_empty
      expect(issues.first.field).to eq("title")
    end

    it "returns errors for unknown keys" do
      config = config_with({ "unknwon_key" => "value" })
      checker = described_class.new(config)
      issues = checker.check
      error = issues.find(&:error?)
      expect(error.message).to include("unknown key")
    end
  end
end

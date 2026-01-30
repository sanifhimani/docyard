# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docyard::Sidebar::LocalConfigLoader do
  let(:docs_path) { Dir.mktmpdir }
  let(:loader) { described_class.new(docs_path) }
  let(:config_file_path) { File.join(docs_path, "_sidebar.yml") }

  after do
    FileUtils.rm_rf(docs_path)
  end

  describe "#load" do
    context "when _sidebar.yml does not exist" do
      it "returns nil" do
        expect(loader.load).to be_nil
      end
    end

    context "when _sidebar.yml exists with array format" do
      before do
        File.write(config_file_path, <<~YAML)
          - introduction
          - getting-started
          - installation
        YAML
      end

      it "returns the items array" do
        result = loader.load
        expect(result).to eq(%w[introduction getting-started installation])
      end
    end

    context "when _sidebar.yml exists with hash format containing items key" do
      before do
        File.write(config_file_path, <<~YAML)
          items:
            - introduction
            - getting-started
        YAML
      end

      it "extracts items from hash" do
        result = loader.load
        expect(result).to eq(%w[introduction getting-started])
      end
    end

    context "when _sidebar.yml contains complex nested structure" do
      before do
        File.write(config_file_path, <<~YAML)
          - introduction
          - getting-started:
              text: "Getting Started"
              icon: "rocket-launch"
              items:
                - installation
                - configuration
          - link: "https://github.com/example"
            text: "GitHub"
            icon: "github-logo"
        YAML
      end

      it "returns the full structure", :aggregate_failures do
        result = loader.load
        expect(result).to be_an(Array)
        expect(result.length).to eq(3)
        expect(result[0]).to eq("introduction")
        expect(result[1]).to be_a(Hash)
        expect(result[2]).to include("link" => "https://github.com/example")
      end
    end

    context "when _sidebar.yml contains invalid YAML" do
      before do
        File.write(config_file_path, "invalid: yaml: content: [")
      end

      it "returns nil and logs warning", :aggregate_failures do
        output = capture_logger_output { loader.load }

        expect(output).to match(/Invalid YAML/)
        expect(loader.load).to be_nil
      end
    end

    context "when _sidebar.yml is empty" do
      before do
        File.write(config_file_path, "")
      end

      it "returns nil" do
        expect(loader.load).to be_nil
      end
    end
  end

  describe "#config_file_exists?" do
    context "when _sidebar.yml exists" do
      before do
        File.write(config_file_path, "- item")
      end

      it "returns true" do
        expect(loader.config_file_exists?).to be true
      end
    end

    context "when _sidebar.yml does not exist" do
      it "returns false" do
        expect(loader.config_file_exists?).to be false
      end
    end
  end

  describe "#key_errors" do
    let(:loader) { described_class.new(docs_path, validate: false) }

    context "when sidebar has invalid format" do
      before do
        File.write(config_file_path, <<~YAML)
          - text: Getting Started
            href: /getting-started
        YAML
      end

      it "reports invalid format error", :aggregate_failures do
        loader.load
        expect(loader.key_errors.size).to eq(1)
        expect(loader.key_errors.first[:message]).to include("invalid format")
      end
    end

    context "when sidebar has valid slug-based format" do
      before do
        File.write(config_file_path, <<~YAML)
          - getting-started:
              text: Getting Started
        YAML
      end

      it "reports no format errors" do
        loader.load
        expect(loader.key_errors).to be_empty
      end
    end
  end
end

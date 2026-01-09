# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe Docyard::Initializer do
  let(:temp_dir) { Dir.mktmpdir }
  let(:initializer) { described_class.new(temp_dir) }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#run" do
    before do
      allow($stdout).to receive(:puts)
    end

    it "creates docs directory" do
      initializer.run
      expect(File.directory?(File.join(temp_dir, "docs"))).to be true
    end

    it "creates index.md" do
      initializer.run
      expect(File.exist?(File.join(temp_dir, "docs", "index.md"))).to be true
    end

    it "creates index.md with frontmatter and content", :aggregate_failures do
      initializer.run
      content = File.read(File.join(temp_dir, "docs", "index.md"))
      expect(content).to include("title: Welcome")
      expect(content).to include("# Welcome to Your Documentation")
    end

    it "returns true on success" do
      expect(initializer.run).to be true
    end

    it "creates docyard.yml config file", :aggregate_failures do
      initializer.run

      config_path = File.join(temp_dir, "docyard.yml")
      expect(File.exist?(config_path)).to be true

      config_content = File.read(config_path)
      expect(config_content).to include("title:")
      expect(config_content).to include("build:")
      expect(config_content).to include("My Documentation")
    end

    it "does not overwrite existing docyard.yml" do
      existing_config = File.join(temp_dir, "docyard.yml")
      File.write(existing_config, "existing: config")

      initializer.run

      expect(File.read(existing_config)).to eq("existing: config")
    end

    context "when docs already exists" do
      before do
        FileUtils.mkdir_p(File.join(temp_dir, "docs"))
      end

      it "returns nil" do
        expect(initializer.run).to be_nil
      end

      it "does not overwrite existing files" do
        existing_file = File.join(temp_dir, "docs", "index.md")
        File.write(existing_file, "existing content")

        initializer.run

        expect(File.read(existing_file)).to eq("existing content")
      end
    end
  end
end

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

    it "creates getting-started.md" do
      initializer.run
      expect(File.exist?(File.join(temp_dir, "docs", "getting-started.md"))).to be true
    end

    it "returns true on success" do
      expect(initializer.run).to be true
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

# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe Docyard::Sidebar::FileSystemScanner do
  let(:docs_path) { Dir.mktmpdir }
  let(:scanner) { described_class.new(docs_path) }

  after { FileUtils.rm_rf(docs_path) }

  def create_file(path)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, "content")
  end

  describe "#scan" do
    context "with empty directory" do
      it "returns empty array" do
        expect(scanner.scan).to eq([])
      end
    end

    context "with non-existent directory" do
      let(:docs_path) { "/nonexistent" }

      it "returns empty array" do
        expect(scanner.scan).to eq([])
      end
    end

    context "with single file" do
      before { create_file("getting-started.md") }

      it "returns file metadata", :aggregate_failures do
        result = scanner.scan

        expect(result.length).to eq(1)
        expect(result[0][:type]).to eq(:file)
        expect(result[0][:name]).to eq("getting-started")
        expect(result[0][:path]).to eq("getting-started.md")
      end
    end

    context "with multiple files" do
      before do
        create_file("guide.md")
        create_file("api.md")
        create_file("getting-started.md")
      end

      it "returns all files in alphabetical order", :aggregate_failures do
        result = scanner.scan

        expect(result.length).to eq(3)
        expect(result.map { |r| r[:name] }).to eq(%w[api getting-started guide])
      end
    end

    context "with nested directories" do
      before do
        create_file("guide/setup.md")
        create_file("guide/advanced.md")
      end

      it "returns nested structure", :aggregate_failures do
        result = scanner.scan

        expect(result.length).to eq(1)

        guide = result.find { |r| r[:type] == :directory }
        expect(guide[:name]).to eq("guide")
        expect(guide[:children].length).to eq(2)
      end
    end

    context "with deeply nested structure" do
      before do
        create_file("guide/advanced/performance/caching.md")
      end

      it "scans recursively" do
        result = scanner.scan

        guide = result[0]
        advanced = guide[:children][0]
        performance = advanced[:children][0]
        caching = performance[:children][0]

        expect(caching[:name]).to eq("caching")
      end
    end

    context "with hidden files" do
      before do
        create_file(".hidden.md")
        create_file("visible.md")
      end

      it "ignores hidden files", :aggregate_failures do
        result = scanner.scan

        expect(result.length).to eq(1)
        expect(result[0][:name]).to eq("visible")
      end
    end

    context "with ignored directories" do
      before do
        create_file("_site/index.md")
        create_file("docs.md")
      end

      it "ignores directories starting with underscore", :aggregate_failures do
        result = scanner.scan

        expect(result.length).to eq(1)
        expect(result[0][:name]).to eq("docs")
      end
    end

    context "with non-markdown files" do
      before do
        create_file("readme.md")
        create_file("image.png")
        create_file("script.js")
      end

      it "only includes markdown files", :aggregate_failures do
        result = scanner.scan

        expect(result.length).to eq(1)
        expect(result[0][:name]).to eq("readme")
      end
    end
  end
end

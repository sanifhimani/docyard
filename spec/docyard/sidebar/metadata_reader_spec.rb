# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docyard::Sidebar::MetadataReader do
  let(:reader) { described_class.new }
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.rm_rf(docs_path) }

  def create_file(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end

  describe "#extract_file_metadata" do
    context "when file has full sidebar frontmatter" do
      it "extracts all metadata fields", :aggregate_failures do
        file_path = create_file("test.md", <<~MD)
          ---
          title: My Title
          sidebar:
            text: Custom Text
            icon: star
            collapsed: false
            order: 5
          ---
          # Content
        MD

        result = reader.extract_file_metadata(file_path)

        expect(result[:title]).to eq("Custom Text")
        expect(result[:icon]).to eq("star")
        expect(result[:collapsed]).to be false
        expect(result[:order]).to eq(5)
      end
    end

    context "when file has only title" do
      it "uses title when sidebar.text is not set" do
        file_path = create_file("test.md", <<~MD)
          ---
          title: Page Title
          ---
          # Content
        MD

        result = reader.extract_file_metadata(file_path)

        expect(result[:title]).to eq("Page Title")
      end
    end

    context "when file does not exist" do
      it "returns nil for all fields" do
        result = reader.extract_file_metadata("/nonexistent/path.md")

        expect(result).to eq({ title: nil, icon: nil, collapsed: nil, order: nil })
      end
    end

    context "when file has no frontmatter" do
      it "returns nil values", :aggregate_failures do
        file_path = create_file("test.md", "# Just Content")

        result = reader.extract_file_metadata(file_path)

        expect(result[:title]).to be_nil
        expect(result[:order]).to be_nil
      end
    end
  end

  describe "#extract_index_metadata" do
    context "when index has sidebar text" do
      it "extracts sidebar_text for Introduction override", :aggregate_failures do
        file_path = create_file("index.md", <<~MD)
          ---
          sidebar:
            text: Getting Started
            icon: rocket
            order: 1
          ---
          # Content
        MD

        result = reader.extract_index_metadata(file_path)

        expect(result[:sidebar_text]).to eq("Getting Started")
        expect(result[:icon]).to eq("rocket")
        expect(result[:order]).to eq(1)
      end
    end

    context "when index has no sidebar text" do
      it "returns nil for sidebar_text" do
        file_path = create_file("index.md", <<~MD)
          ---
          title: Introduction
          ---
          # Content
        MD

        result = reader.extract_index_metadata(file_path)

        expect(result[:sidebar_text]).to be_nil
      end
    end

    context "when file does not exist" do
      it "returns empty metadata hash", :aggregate_failures do
        result = reader.extract_index_metadata("/nonexistent/index.md")

        expect(result[:sidebar_text]).to be_nil
        expect(result[:icon]).to be_nil
        expect(result[:collapsed]).to be_nil
        expect(result[:order]).to be_nil
      end
    end
  end
end

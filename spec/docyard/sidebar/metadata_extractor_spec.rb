# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe Docyard::Sidebar::MetadataExtractor do
  let(:temp_dir) { Dir.mktmpdir }
  let(:docs_path) { File.join(temp_dir, "docs") }
  let(:title_extractor) { Docyard::Sidebar::TitleExtractor.new }
  let(:extractor) { described_class.new(docs_path: docs_path, title_extractor: title_extractor) }

  before { FileUtils.mkdir_p(docs_path) }
  after { FileUtils.rm_rf(temp_dir) }

  def create_file(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end

  describe "#extract_index_metadata" do
    it "extracts sidebar_text and icon from frontmatter", :aggregate_failures do
      file_path = create_file("index.md", <<~MD)
        ---
        sidebar:
          text: "Custom Sidebar Text"
          icon: "rocket-launch"
        ---
        # Index
      MD

      result = extractor.extract_index_metadata(file_path)

      expect(result[:sidebar_text]).to eq("Custom Sidebar Text")
      expect(result[:icon]).to eq("rocket-launch")
    end

    it "returns nil values when file does not exist" do
      result = extractor.extract_index_metadata("/nonexistent/path.md")

      expect(result).to eq({ sidebar_text: nil, icon: nil })
    end

    it "returns nil values when frontmatter has no sidebar config", :aggregate_failures do
      file_path = create_file("index.md", "# Just a heading")

      result = extractor.extract_index_metadata(file_path)

      expect(result[:sidebar_text]).to be_nil
      expect(result[:icon]).to be_nil
    end

    it "returns nil values on parse errors" do
      file_path = create_file("index.md", "---\ninvalid: yaml: content:\n---")

      result = extractor.extract_index_metadata(file_path)

      expect(result).to eq({ sidebar_text: nil, icon: nil })
    end
  end

  describe "#extract_frontmatter_metadata" do
    it "extracts sidebar_text as text when available" do
      file_path = create_file("page.md", <<~MD)
        ---
        sidebar:
          text: "Sidebar Override"
        title: "Page Title"
        ---
        # Content
      MD

      result = extractor.extract_frontmatter_metadata(file_path)

      expect(result[:text]).to eq("Sidebar Override")
    end

    it "falls back to title when sidebar_text is not set" do
      file_path = create_file("page.md", <<~MD)
        ---
        title: "Page Title"
        ---
        # Content
      MD

      result = extractor.extract_frontmatter_metadata(file_path)

      expect(result[:text]).to eq("Page Title")
    end

    it "extracts sidebar icon" do
      file_path = create_file("page.md", <<~MD)
        ---
        sidebar:
          icon: "star"
        ---
        # Content
      MD

      result = extractor.extract_frontmatter_metadata(file_path)

      expect(result[:icon]).to eq("star")
    end

    it "returns nil values when file does not exist" do
      result = extractor.extract_frontmatter_metadata("/nonexistent/path.md")

      expect(result).to eq({ text: nil, icon: nil, badge: nil, badge_type: nil })
    end
  end

  describe "#extract_file_title" do
    it "extracts title from file when it exists" do
      file_path = create_file("page.md", <<~MD)
        ---
        title: "Extracted Title"
        ---
        # Content
      MD

      result = extractor.extract_file_title(file_path, "page")

      expect(result).to eq("Extracted Title")
    end

    it "titleizes slug when file does not exist" do
      result = extractor.extract_file_title("/nonexistent/path.md", "quick-start")

      expect(result).to eq("Quick Start")
    end
  end

  describe "#extract_common_options" do
    it "extracts text, icon, and collapsed from string keys", :aggregate_failures do
      options = { "text" => "Custom Text", "icon" => "book", "collapsed" => true }

      result = extractor.extract_common_options(options)

      expect(result[:text]).to eq("Custom Text")
      expect(result[:icon]).to eq("book")
      expect(result[:collapsed]).to be true
    end

    it "extracts from symbol keys", :aggregate_failures do
      options = { text: "Symbol Text", icon: "star", collapsed: false }

      result = extractor.extract_common_options(options)

      expect(result[:text]).to eq("Symbol Text")
      expect(result[:icon]).to eq("star")
      expect(result[:collapsed]).to be false
    end

    it "prefers string keys over symbol keys" do
      options = { "text" => "String Text", text: "Symbol Text" }

      result = extractor.extract_common_options(options)

      expect(result[:text]).to eq("String Text")
    end

    it "returns nil for missing options", :aggregate_failures do
      result = extractor.extract_common_options({})

      expect(result[:text]).to be_nil
      expect(result[:icon]).to be_nil
      expect(result[:collapsed]).to be_nil
    end
  end

  describe "#resolve_item_text" do
    it "uses option text when provided (string key)" do
      result = extractor.resolve_item_text("slug", "/path.md", { "text" => "Option Text" }, "Frontmatter")

      expect(result).to eq("Option Text")
    end

    it "uses option text when provided (symbol key)" do
      result = extractor.resolve_item_text("slug", "/path.md", { text: "Option Text" }, "Frontmatter")

      expect(result).to eq("Option Text")
    end

    it "uses frontmatter text when option is not provided" do
      result = extractor.resolve_item_text("slug", "/path.md", {}, "Frontmatter Text")

      expect(result).to eq("Frontmatter Text")
    end

    it "extracts file title when both option and frontmatter are nil" do
      file_path = create_file("page.md", "---\ntitle: File Title\n---\n# File Title")

      result = extractor.resolve_item_text("page", file_path, {}, nil)

      expect(result).to eq("File Title")
    end

    it "titleizes slug when file does not exist and no text provided" do
      result = extractor.resolve_item_text("quick-start", "/nonexistent.md", {}, nil)

      expect(result).to eq("Quick Start")
    end
  end

  describe "#section_from_collapsible" do
    it "returns nil when collapsible is nil" do
      result = extractor.section_from_collapsible(nil)

      expect(result).to be_nil
    end

    it "returns false when collapsible is true" do
      result = extractor.section_from_collapsible(true)

      expect(result).to be false
    end

    it "returns true when collapsible is false" do
      result = extractor.section_from_collapsible(false)

      expect(result).to be true
    end
  end

  describe "#extract_common_options section handling" do
    it "returns section nil when collapsible not specified" do
      result = extractor.extract_common_options({})

      expect(result[:section]).to be_nil
    end

    it "returns section false when collapsible is true" do
      result = extractor.extract_common_options({ "collapsible" => true })

      expect(result[:section]).to be false
    end

    it "returns section true when collapsible is false" do
      result = extractor.extract_common_options({ "collapsible" => false })

      expect(result[:section]).to be true
    end

    it "infers collapsible true when collapsed is set" do
      result = extractor.extract_common_options({ "collapsed" => true })

      expect(result[:section]).to be false
    end
  end

  describe "#resolve_item_icon" do
    it "uses option icon when provided (string key)" do
      result = extractor.resolve_item_icon({ "icon" => "rocket" }, "star")

      expect(result).to eq("rocket")
    end

    it "uses option icon when provided (symbol key)" do
      result = extractor.resolve_item_icon({ icon: "rocket" }, "star")

      expect(result).to eq("rocket")
    end

    it "uses frontmatter icon when option is not provided" do
      result = extractor.resolve_item_icon({}, "star")

      expect(result).to eq("star")
    end

    it "returns nil when no icon is available" do
      result = extractor.resolve_item_icon({}, nil)

      expect(result).to be_nil
    end
  end
end

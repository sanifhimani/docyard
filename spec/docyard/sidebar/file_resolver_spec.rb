# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docyard::Sidebar::FileResolver do
  let(:docs_path) { Dir.mktmpdir }
  let(:current_path) { "/" }
  let(:metadata_extractor) do
    Docyard::Sidebar::MetadataExtractor.new(
      docs_path: docs_path,
      title_extractor: Docyard::Sidebar::TitleExtractor.new
    )
  end
  let(:resolver) do
    described_class.new(
      docs_path: docs_path,
      current_path: current_path,
      metadata_extractor: metadata_extractor
    )
  end

  after { FileUtils.rm_rf(docs_path) }

  def create_file(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  describe "#resolve" do
    context "when file has frontmatter" do
      before do
        create_file("intro.md", <<~MD)
          ---
          sidebar:
            text: Introduction Guide
            icon: book
          ---
          # Intro
        MD
      end

      it "creates item with frontmatter metadata", :aggregate_failures do
        item = resolver.resolve("intro", "")

        expect(item.text).to eq("Introduction Guide")
        expect(item.icon).to eq("book")
        expect(item.path).to eq("/intro")
        expect(item.type).to eq(:file)
      end

      it "sets section to false for regular files" do
        item = resolver.resolve("intro", "")

        expect(item.section).to be false
      end
    end

    context "when options override frontmatter" do
      before do
        create_file("intro.md", <<~MD)
          ---
          sidebar:
            text: From Frontmatter
          ---
          # Intro
        MD
      end

      it "uses options text over frontmatter" do
        item = resolver.resolve("intro", "", { "text" => "From Options" })

        expect(item.text).to eq("From Options")
      end
    end

    context "when file is in subdirectory" do
      before do
        create_file("guide/setup.md", "---\ntitle: Setup Guide\n---\n")
      end

      it "builds correct path" do
        item = resolver.resolve("setup", "guide")

        expect(item.path).to eq("/guide/setup")
      end
    end

    context "when current path matches item path" do
      let(:current_path) { "/intro" }

      before do
        create_file("intro.md", "---\ntitle: Intro\n---\n")
      end

      it "marks item as active" do
        item = resolver.resolve("intro", "")

        expect(item.active).to be true
      end
    end

    context "when current path does not match" do
      let(:current_path) { "/other" }

      before do
        create_file("intro.md", "---\ntitle: Intro\n---\n")
      end

      it "marks item as not active" do
        item = resolver.resolve("intro", "")

        expect(item.active).to be false
      end
    end
  end

  describe "#build_link_item" do
    it "creates external link item with string keys", :aggregate_failures do
      config = {
        "link" => "https://github.com/example",
        "text" => "GitHub",
        "icon" => "github-logo",
        "target" => "_blank"
      }

      item = resolver.build_link_item(config)

      expect(item.text).to eq("GitHub")
      expect(item.path).to eq("https://github.com/example")
      expect(item.icon).to eq("github-logo")
      expect(item.target).to eq("_blank")
      expect(item.type).to eq(:external)
    end

    it "creates external link item with symbol keys", :aggregate_failures do
      config = {
        link: "https://example.com",
        text: "Example",
        icon: "link"
      }

      item = resolver.build_link_item(config)

      expect(item.text).to eq("Example")
      expect(item.path).to eq("https://example.com")
      expect(item.icon).to eq("link")
    end

    it "defaults target to _blank" do
      config = { "link" => "https://example.com", "text" => "Link" }

      item = resolver.build_link_item(config)

      expect(item.target).to eq("_blank")
    end

    it "sets section to false for external links" do
      config = { "link" => "https://example.com", "text" => "Link" }

      item = resolver.build_link_item(config)

      expect(item.section).to be false
    end
  end

  describe "#build_file_with_children" do
    before do
      create_file("parent.md", <<~MD)
        ---
        title: Parent Page
        sidebar:
          icon: folder
        ---
        # Parent
      MD
    end

    let(:parsed_items) do
      [
        Docyard::Sidebar::Item.new(text: "Child 1", path: "/child1", type: :file),
        Docyard::Sidebar::Item.new(text: "Child 2", path: "/child2", type: :file)
      ]
    end

    it "creates section item by default at depth 1", :aggregate_failures do
      item = resolver.build_file_with_children(
        slug: "parent", options: { "icon" => "custom-icon" }, base_path: "", parsed_items: parsed_items, depth: 1
      )

      expect(item.text).to eq("Parent Page")
      expect(item.icon).to eq("custom-icon")
      expect(item.path).to be_nil
      expect(item.type).to eq(:section)
      expect(item.section).to be true
      expect(item.items.length).to eq(2)
    end

    it "creates collapsible file item by default at depth 2+", :aggregate_failures do
      item = resolver.build_file_with_children(
        slug: "parent", options: { "icon" => "custom-icon" }, base_path: "", parsed_items: parsed_items, depth: 2
      )

      expect(item.text).to eq("Parent Page")
      expect(item.icon).to eq("custom-icon")
      expect(item.path).to eq("/parent")
      expect(item.type).to eq(:file)
      expect(item.section).to be false
      expect(item.items.length).to eq(2)
    end

    it "creates section item when collapsible is explicitly false", :aggregate_failures do
      item = resolver.build_file_with_children(
        slug: "parent", options: { "icon" => "custom-icon", "collapsible" => false },
        base_path: "", parsed_items: parsed_items, depth: 2
      )

      expect(item.text).to eq("Parent Page")
      expect(item.icon).to eq("custom-icon")
      expect(item.path).to be_nil
      expect(item.type).to eq(:section)
      expect(item.section).to be true
      expect(item.items.length).to eq(2)
    end

    it "creates collapsible file item when collapsible is explicitly true at depth 1", :aggregate_failures do
      item = resolver.build_file_with_children(
        slug: "parent", options: { "icon" => "custom-icon", "collapsible" => true },
        base_path: "", parsed_items: parsed_items, depth: 1
      )

      expect(item.text).to eq("Parent Page")
      expect(item.icon).to eq("custom-icon")
      expect(item.path).to eq("/parent")
      expect(item.type).to eq(:file)
      expect(item.section).to be false
      expect(item.items.length).to eq(2)
    end

    context "when options provide text override" do
      it "uses options text" do
        item = resolver.build_file_with_children(
          slug: "parent",
          options: { "text" => "Custom Title" },
          base_path: "",
          parsed_items: []
        )

        expect(item.text).to eq("Custom Title")
      end
    end
  end
end

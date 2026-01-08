# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe Docyard::Routing::FallbackResolver do
  let(:docs_path) { Dir.mktmpdir }
  let(:sidebar_builder) { instance_double(Docyard::SidebarBuilder, tree: sidebar_tree) }
  let(:sidebar_tree) { [] }
  let(:resolver) { described_class.new(docs_path: docs_path, sidebar_builder: sidebar_builder) }

  after { FileUtils.rm_rf(docs_path) }

  def create_file(path, content = "# Content")
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  describe "#resolve_fallback" do
    context "when file exists" do
      it "returns nil for existing markdown file" do
        create_file("guide.md")

        result = resolver.resolve_fallback("/guide")

        expect(result).to be_nil
      end

      it "returns nil for existing index file in directory" do
        create_file("guide/index.md")

        result = resolver.resolve_fallback("/guide")

        expect(result).to be_nil
      end

      it "returns nil for root index" do
        create_file("index.md")

        result = resolver.resolve_fallback("/")

        expect(result).to be_nil
      end
    end

    context "when file does not exist at root path" do
      let(:sidebar_tree) do
        [
          { type: :file, title: "Getting Started", path: "/getting-started" },
          { type: :directory, title: "Guide", path: nil, children: [
            { type: :file, title: "Setup", path: "/guide/setup" }
          ] }
        ]
      end

      it "returns first navigable item from sidebar for root path" do
        result = resolver.resolve_fallback("/")

        expect(result).to eq("/getting-started")
      end

      it "returns first navigable item for empty path" do
        result = resolver.resolve_fallback("")

        expect(result).to eq("/getting-started")
      end

      it "returns first navigable item for nil path" do
        result = resolver.resolve_fallback(nil)

        expect(result).to eq("/getting-started")
      end
    end

    context "when navigating to section without index" do
      let(:sidebar_tree) do
        [
          { type: :file, title: "Home", path: "/" },
          { type: :directory, title: "Guide", path: nil, children: [
            { type: :file, title: "Introduction", path: "/guide/intro" },
            { type: :file, title: "Setup", path: "/guide/setup" }
          ] }
        ]
      end

      it "returns first item in section" do
        result = resolver.resolve_fallback("/guide")

        expect(result).to eq("/guide/intro")
      end

      it "handles trailing slash" do
        result = resolver.resolve_fallback("/guide/")

        expect(result).to eq("/guide/intro")
      end
    end

    context "with nested directories" do
      let(:sidebar_tree) do
        [
          { type: :directory, title: "API", path: nil, children: [
            { type: :directory, title: "Reference", path: nil, children: [
              { type: :file, title: "Methods", path: "/api/reference/methods" }
            ] }
          ] }
        ]
      end

      it "finds nested section" do
        result = resolver.resolve_fallback("/api")

        expect(result).to eq("/api/reference/methods")
      end
    end

    context "when section is not found" do
      let(:sidebar_tree) do
        [
          { type: :file, title: "Home", path: "/" }
        ]
      end

      it "returns nil for unknown section" do
        result = resolver.resolve_fallback("/unknown")

        expect(result).to be_nil
      end
    end

    context "with directories only (no navigable files)" do
      let(:sidebar_tree) do
        [
          { type: :directory, title: "Empty", path: nil, children: [] }
        ]
      end

      it "returns nil when no files in section" do
        result = resolver.resolve_fallback("/empty")

        expect(result).to be_nil
      end
    end

    context "with case sensitivity" do
      let(:sidebar_tree) do
        [
          { type: :directory, title: "Guide", path: nil, children: [
            { type: :file, title: "Setup", path: "/guide/setup" }
          ] }
        ]
      end

      it "matches section case-insensitively" do
        result = resolver.resolve_fallback("/GUIDE")

        expect(result).to eq("/guide/setup")
      end
    end

    context "with directory that has index" do
      let(:sidebar_tree) do
        [
          { type: :directory, title: "Guide", path: "/guide", has_index: true, children: [
            { type: :file, title: "Home", path: "/guide" },
            { type: :file, title: "Setup", path: "/guide/setup" }
          ] }
        ]
      end

      it "still returns nil when index file exists on disk" do
        create_file("guide/index.md")

        result = resolver.resolve_fallback("/guide")

        expect(result).to be_nil
      end
    end
  end
end

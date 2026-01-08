# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docyard::Sidebar::ChildrenDiscoverer do
  let(:docs_path) { Dir.mktmpdir }
  let(:discoverer) { described_class.new(docs_path: docs_path) }

  after { FileUtils.rm_rf(docs_path) }

  def create_file(path, content = "# Content")
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  def create_dir(path)
    FileUtils.mkdir_p(File.join(docs_path, path))
  end

  describe "#discover" do
    context "when directory does not exist" do
      it "returns empty array" do
        result = discoverer.discover("nonexistent", depth: 1) { |*_args| nil }

        expect(result).to eq([])
      end
    end

    context "when _sidebar.yml exists in directory" do
      before do
        create_dir("guide")
        File.write(File.join(docs_path, "guide", "_sidebar.yml"), <<~YAML)
          - intro
          - setup
        YAML
      end

      it "yields the config array to the block", :aggregate_failures do
        yielded = nil
        discoverer.discover("guide", depth: 2) do |config, path, depth|
          yielded = { config: config, path: path, depth: depth }
          []
        end

        expect(yielded[:config]).to eq(%w[intro setup])
        expect(yielded[:path]).to eq("guide")
        expect(yielded[:depth]).to eq(2)
      end
    end

    context "when discovering from filesystem" do
      before do
        create_file("guide/intro.md")
        create_file("guide/setup.md")
        create_dir("guide/advanced")
        create_file("guide/advanced/index.md")
      end

      it "yields file entries with :file type" do
        entries = []
        discoverer.discover("guide", depth: 1) do |type, slug, path, depth|
          entries << { type: type, slug: slug, path: path, depth: depth }
          { slug: slug }
        end

        file_entries = entries.select { |e| e[:type] == :file }
        expect(file_entries.map { |e| e[:slug] }).to contain_exactly("intro", "setup")
      end

      it "yields directory entries with :directory type" do
        entries = []
        discoverer.discover("guide", depth: 1) do |type, slug, _path, _depth|
          entries << { type: type, slug: slug }
          { slug: slug }
        end

        dir_entries = entries.select { |e| e[:type] == :directory }
        expect(dir_entries.map { |e| e[:slug] }).to eq(["advanced"])
      end
    end

    context "when filtering entries" do
      before do
        create_file("guide/visible.md")
        create_file("guide/.hidden.md")
        create_file("guide/_private.md")
        create_file("guide/index.md")
      end

      it "excludes hidden files starting with dot" do
        slugs = []
        discoverer.discover("guide", depth: 1) do |_, slug, _, _|
          slugs << slug
          {}
        end

        expect(slugs).not_to include(".hidden")
      end

      it "excludes files starting with underscore" do
        slugs = []
        discoverer.discover("guide", depth: 1) do |_, slug, _, _|
          slugs << slug
          {}
        end

        expect(slugs).not_to include("_private")
      end

      it "excludes index.md" do
        slugs = []
        discoverer.discover("guide", depth: 1) do |_, slug, _, _|
          slugs << slug
          {}
        end

        expect(slugs).not_to include("index")
      end

      it "includes only visible files" do
        slugs = []
        discoverer.discover("guide", depth: 1) do |_, slug, _, _|
          slugs << slug
          {}
        end

        expect(slugs).to eq(["visible"])
      end
    end

    context "when directory has mixed content" do
      before do
        create_file("docs/readme.md")
        create_file("docs/other.txt")
        create_dir("docs/subdir")
      end

      it "only processes .md files and directories" do
        entries = []
        discoverer.discover("docs", depth: 1) do |type, slug, _, _|
          entries << { type: type, slug: slug }
          {}
        end

        expect(entries).to contain_exactly(
          { type: :file, slug: "readme" },
          { type: :directory, slug: "subdir" }
        )
      end
    end
  end
end

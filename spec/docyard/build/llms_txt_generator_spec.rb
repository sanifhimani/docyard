# frozen_string_literal: true

require "spec_helper"
require "docyard/build/llms_txt_generator"
require "docyard/config"

RSpec.describe Docyard::Build::LlmsTxtGenerator do
  let(:temp_dir) { Dir.mktmpdir }
  let(:docs_dir) { File.join(temp_dir, "docs") }
  let(:output_dir) { File.join(temp_dir, "dist") }

  before do
    FileUtils.mkdir_p(docs_dir)
    FileUtils.mkdir_p(output_dir)

    File.write(File.join(temp_dir, "docyard.yml"), <<~YAML)
      title: "Test Docs"
      description: "Documentation for testing"
      source: "docs"
      build:
        output: "dist"
        base: "/"
    YAML
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  def create_page(path, title: nil, description: nil, content: "Page content")
    full_path = File.join(docs_dir, path)
    FileUtils.mkdir_p(File.dirname(full_path))

    frontmatter = []
    frontmatter << "title: #{title}" if title
    frontmatter << "description: #{description}" if description

    file_content = if frontmatter.any?
                     "---\n#{frontmatter.join("\n")}\n---\n\n#{content}"
                   else
                     content
                   end

    File.write(full_path, file_content)
  end

  describe "#generate" do
    let(:config) { Dir.chdir(temp_dir) { Docyard::Config.new } }
    let(:generator) { described_class.new(config) }

    before do
      create_page("index.md", title: "Home", description: "Welcome page", content: "# Welcome\n\nThis is home.")
      create_page("guide/intro.md", title: "Introduction", content: "# Intro\n\nGetting started.")
    end

    it "generates llms.txt file" do
      Dir.chdir(temp_dir) { generator.generate }

      expect(File.exist?(File.join(output_dir, "llms.txt"))).to be true
    end

    it "generates llms-full.txt file" do
      Dir.chdir(temp_dir) { generator.generate }

      expect(File.exist?(File.join(output_dir, "llms-full.txt"))).to be true
    end

    describe "llms.txt content" do
      before { Dir.chdir(temp_dir) { generator.generate } }

      def llms_txt
        File.read(File.join(output_dir, "llms.txt"))
      end

      it "starts with site title as H1" do
        expect(llms_txt).to start_with("# Test Docs")
      end

      it "includes site description as blockquote" do
        expect(llms_txt).to include("> Documentation for testing")
      end

      it "includes Docs section header" do
        expect(llms_txt).to include("## Docs")
      end

      it "includes links to all pages", :aggregate_failures do
        expect(llms_txt).to include("- [Home](/)")
        expect(llms_txt).to include("- [Introduction](/guide/intro)")
      end

      it "includes page descriptions when available" do
        expect(llms_txt).to include("[Home](/): Welcome page")
      end
    end

    describe "llms-full.txt content" do
      before { Dir.chdir(temp_dir) { generator.generate } }

      def llms_full_txt
        File.read(File.join(output_dir, "llms-full.txt"))
      end

      it "starts with site title as H1" do
        expect(llms_full_txt).to start_with("# Test Docs")
      end

      it "includes complete documentation notice" do
        expect(llms_full_txt).to include("This file contains the complete documentation content.")
      end

      it "includes page content for each page", :aggregate_failures do
        expect(llms_full_txt).to include("# Welcome")
        expect(llms_full_txt).to include("This is home.")
        expect(llms_full_txt).to include("# Intro")
        expect(llms_full_txt).to include("Getting started.")
      end

      it "includes page URLs", :aggregate_failures do
        expect(llms_full_txt).to include("URL: /")
        expect(llms_full_txt).to include("URL: /guide/intro")
      end

      it "strips frontmatter from content", :aggregate_failures do
        expect(llms_full_txt).not_to include("title: Home")
        expect(llms_full_txt).not_to include("description: Welcome page")
      end
    end

    context "with site URL configured" do
      before do
        File.write(File.join(temp_dir, "docyard.yml"), <<~YAML)
          title: "Test Docs"
          url: "https://docs.example.com"
          source: "docs"
          build:
            output: "dist"
            base: "/"
        YAML
      end

      it "uses site URL in links", :aggregate_failures do
        Dir.chdir(temp_dir) { generator.generate }
        content = File.read(File.join(output_dir, "llms.txt"))

        expect(content).to include("[Home](https://docs.example.com/)")
        expect(content).to include("[Introduction](https://docs.example.com/guide/intro)")
      end
    end

    context "without site description" do
      before do
        File.write(File.join(temp_dir, "docyard.yml"), <<~YAML)
          title: "Test Docs"
          source: "docs"
          build:
            output: "dist"
            base: "/"
        YAML
      end

      it "omits blockquote when no description" do
        Dir.chdir(temp_dir) { generator.generate }
        content = File.read(File.join(output_dir, "llms.txt"))

        expect(content).not_to include(">")
      end
    end
  end
end

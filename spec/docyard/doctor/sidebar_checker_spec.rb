# frozen_string_literal: true

RSpec.describe Docyard::Doctor::SidebarChecker do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_sidebar(content)
    File.write(File.join(docs_path, "_sidebar.yml"), content)
  end

  def write_page(path)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, "# Page")
  end

  describe "#check" do
    it "returns empty array when sidebar has no errors" do
      write_sidebar(<<~YAML)
        - getting-started:
            text: Get Started
            icon: rocket
      YAML
      write_page("getting-started.md")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    it "returns empty array when no sidebar file exists" do
      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    it "returns issues for unknown keys", :aggregate_failures do
      write_sidebar(<<~YAML)
        - getting-started:
            text: Get Started
            unknwon_key: value
      YAML
      write_page("getting-started.md")

      checker = described_class.new(docs_path)
      issues = checker.check
      expect(issues.size).to eq(1)
      expect(issues.first.message).to include("unknown key")
    end

    it "includes item name in field path" do
      write_sidebar(<<~YAML)
        - getting-started:
            textt: Get Started
      YAML
      write_page("getting-started.md")

      checker = described_class.new(docs_path)
      issues = checker.check
      expect(issues.first.field).to include("getting-started")
    end

    it "suggests corrections for typos" do
      write_sidebar(<<~YAML)
        - docs:
            textt: Documentation
      YAML
      write_page("docs.md")

      checker = described_class.new(docs_path)
      issues = checker.check
      expect(issues.first.message).to include("Did you mean 'text'")
    end

    it "validates nested items", :aggregate_failures do
      write_sidebar(<<~YAML)
        - parent:
            text: Parent
            items:
              - child:
                  unknwon: value
      YAML
      write_page("parent/child.md")

      checker = described_class.new(docs_path)
      issues = checker.check
      expect(issues.size).to eq(1)
      expect(issues.first.field).to include("child")
    end

    it "validates external links" do
      write_sidebar(<<~YAML)
        - link: https://example.com
          text: Example
          unknwon: value
      YAML

      checker = described_class.new(docs_path)
      issues = checker.check
      expect(issues.first.message).to include("unknown key")
    end

    it "detects missing files", :aggregate_failures do
      write_sidebar(<<~YAML)
        - existing-page:
            text: Exists
        - missing-page:
            text: Missing
      YAML
      write_page("existing-page.md")

      checker = described_class.new(docs_path)
      issues = checker.check
      expect(issues.size).to eq(1)
      expect(issues.first.code).to eq("SIDEBAR_MISSING_FILE")
      expect(issues.first.message).to include("missing file")
    end

    it "detects missing nested files", :aggregate_failures do
      write_sidebar(<<~YAML)
        - guide:
            text: Guide
            items:
              - intro
              - missing
      YAML
      write_page("guide/intro.md")

      checker = described_class.new(docs_path)
      issues = checker.check
      expect(issues.size).to eq(1)
      expect(issues.first.field).to include("guide/missing")
    end

    it "accepts index.md for directory paths" do
      write_sidebar(<<~YAML)
        - getting-started:
            text: Get Started
      YAML
      write_page("getting-started/index.md")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    it "does not require file for group-only items" do
      write_sidebar(<<~YAML)
        - section:
            text: Section
            items:
              - child
      YAML
      write_page("section/child.md")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    it "requires file for items with index: true", :aggregate_failures do
      write_sidebar(<<~YAML)
        - section:
            text: Section
            index: true
            items:
              - child
      YAML
      write_page("section/child.md")

      checker = described_class.new(docs_path)
      issues = checker.check
      expect(issues.size).to eq(1)
      expect(issues.first.code).to eq("SIDEBAR_MISSING_FILE")
    end
  end
end

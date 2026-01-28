# frozen_string_literal: true

RSpec.describe Docyard::Doctor::SidebarChecker do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_sidebar(content)
    File.write(File.join(docs_path, "_sidebar.yml"), content)
  end

  describe "#check" do
    it "returns empty array when sidebar has no errors" do
      write_sidebar(<<~YAML)
        - getting-started:
            text: Get Started
            icon: rocket
      YAML

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

      checker = described_class.new(docs_path)
      issues = checker.check
      expect(issues.first.field).to include("getting-started")
    end

    it "suggests corrections for typos" do
      write_sidebar(<<~YAML)
        - docs:
            textt: Documentation
      YAML

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
  end
end

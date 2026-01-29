# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentChecker do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_page(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  describe "callout validation" do
    it "returns empty array for valid callout" do
      write_page("guide.md", ":::note\nThis is a note.\n:::")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    it "detects unclosed callout block", :aggregate_failures do
      write_page("guide.md", ":::warning\nThis block is never closed.")

      checker = described_class.new(docs_path)
      diagnostics = checker.check

      expect(diagnostics.size).to eq(1)
      expect(diagnostics.first.code).to eq("CALLOUT_UNCLOSED")
      expect(diagnostics.first.message).to include("unclosed")
      expect(diagnostics.first.line).to eq(1)
    end

    it "detects empty callout block", :aggregate_failures do
      write_page("guide.md", ":::tip\n:::")

      checker = described_class.new(docs_path)
      diagnostics = checker.check

      expect(diagnostics.size).to eq(1)
      expect(diagnostics.first.code).to eq("CALLOUT_EMPTY")
      expect(diagnostics.first.message).to include("empty")
    end

    it "ignores callouts inside code blocks" do
      write_page("guide.md", "```markdown\n:::foobar\nExample.\n:::\n```")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    %w[note tip important warning danger].each do |type|
      it "accepts valid callout type '#{type}'" do
        write_page("guide.md", ":::#{type}\nContent.\n:::")

        checker = described_class.new(docs_path)
        expect(checker.check).to be_empty
      end
    end
  end

  describe "tabs validation" do
    it "returns empty array for valid tabs" do
      write_page("guide.md", ":::tabs\n== Tab 1\nContent\n== Tab 2\nMore content\n:::")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    it "detects empty tabs block", :aggregate_failures do
      write_page("guide.md", ":::tabs\n:::")

      checker = described_class.new(docs_path)
      diagnostics = checker.check

      expect(diagnostics.size).to eq(1)
      expect(diagnostics.first.code).to eq("TABS_EMPTY")
      expect(diagnostics.first.message).to include("Tab Name")
    end

    it "detects unclosed tabs block", :aggregate_failures do
      write_page("guide.md", ":::tabs\n== Tab 1\nContent")

      checker = described_class.new(docs_path)
      diagnostics = checker.check

      expect(diagnostics.size).to eq(1)
      expect(diagnostics.first.code).to eq("TABS_UNCLOSED")
      expect(diagnostics.first.message).to include("unclosed")
    end

    it "detects :::tab typo and suggests :::tabs", :aggregate_failures do
      write_page("guide.md", ":::tab\n== Tab 1\nContent\n:::")

      checker = described_class.new(docs_path)
      diagnostics = checker.check

      expect(diagnostics.size).to eq(1)
      expect(diagnostics.first.code).to eq("COMPONENT_UNKNOWN_TYPE")
      expect(diagnostics.first.message).to include("did you mean ':::tabs'")
    end
  end

  describe "unknown component detection" do
    it "detects unknown type with suggestion", :aggregate_failures do
      write_page("guide.md", ":::nite\nThis looks like a typo.\n:::")

      checker = described_class.new(docs_path)
      diagnostics = checker.check

      expect(diagnostics.size).to eq(1)
      expect(diagnostics.first.code).to eq("COMPONENT_UNKNOWN_TYPE")
      expect(diagnostics.first.message).to include("did you mean ':::note'")
    end

    it "detects unknown type without suggestion for unrecognizable type" do
      write_page("guide.md", ":::foobar\nUnknown type.\n:::")

      checker = described_class.new(docs_path)
      diagnostics = checker.check

      expect(diagnostics.first.message).to eq("unknown component ':::foobar'")
    end

    it "does not report known component types as unknown" do
      write_page("guide.md", ":::tabs\n== Tab 1\nContent\n:::")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end
  end
end

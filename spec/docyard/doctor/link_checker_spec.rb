# frozen_string_literal: true

RSpec.describe Docyard::Doctor::LinkChecker do
  let(:temp_dir) { Dir.mktmpdir }
  let(:checker) { described_class.new(temp_dir) }

  after { FileUtils.remove_entry(temp_dir) }

  describe "#check" do
    it "returns empty array when no markdown files exist" do
      expect(checker.check).to eq([])
    end

    it "returns empty array when all internal links are valid" do
      File.write(File.join(temp_dir, "index.md"), "[Link](/about)")
      File.write(File.join(temp_dir, "about.md"), "# About")

      expect(checker.check).to eq([])
    end

    it "detects broken internal links", :aggregate_failures do
      File.write(File.join(temp_dir, "index.md"), "[Link](/nonexistent)")

      issues = checker.check

      expect(issues.size).to eq(1)
      expect(issues.first.file).to eq("index.md")
      expect(issues.first.line).to eq(1)
      expect(issues.first.target).to eq("/nonexistent")
    end

    it "detects multiple broken links in same file", :aggregate_failures do
      content = <<~MD
        # Page
        [Link 1](/missing1)
        Some text
        [Link 2](/missing2)
      MD
      File.write(File.join(temp_dir, "page.md"), content)

      issues = checker.check

      expect(issues.size).to eq(2)
      expect(issues.map(&:target)).to contain_exactly("/missing1", "/missing2")
    end

    it "ignores external links" do
      File.write(File.join(temp_dir, "index.md"), "[External](https://example.com)")

      expect(checker.check).to eq([])
    end

    it "ignores image paths" do
      File.write(File.join(temp_dir, "index.md"), "[Screenshot](/images/shot.png)")

      expect(checker.check).to eq([])
    end

    it "validates links to index files in directories" do
      FileUtils.mkdir_p(File.join(temp_dir, "guide"))
      File.write(File.join(temp_dir, "index.md"), "[Guide](/guide)")
      File.write(File.join(temp_dir, "guide", "index.md"), "# Guide")

      expect(checker.check).to eq([])
    end

    it "handles anchor links by checking the file portion" do
      File.write(File.join(temp_dir, "index.md"), "[Section](/about#section)")
      File.write(File.join(temp_dir, "about.md"), "# About")

      expect(checker.check).to eq([])
    end

    it "reports correct line numbers" do
      content = <<~MD
        Line 1
        Line 2
        [Broken](/missing)
        Line 4
      MD
      File.write(File.join(temp_dir, "page.md"), content)

      issues = checker.check

      expect(issues.first.line).to eq(3)
    end

    it "ignores links inside fenced code blocks" do
      content = <<~MD
        # Example

        ```markdown
        [Link](/example)
        ```

        Real content here.
      MD
      File.write(File.join(temp_dir, "page.md"), content)

      expect(checker.check).to eq([])
    end

    it "ignores links inside tilde code blocks" do
      content = <<~MD
        ~~~markdown
        [Link](/example)
        ~~~
      MD
      File.write(File.join(temp_dir, "page.md"), content)

      expect(checker.check).to eq([])
    end
  end
end

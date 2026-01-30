# frozen_string_literal: true

RSpec.describe Docyard::Doctor::LinkChecker do
  let(:docs_path) { Dir.mktmpdir }
  let(:checker) { described_class.new(docs_path) }

  after { FileUtils.remove_entry(docs_path) }

  def check(content, file_path = "#{docs_path}/index.md")
    checker.check_file(content, file_path)
  end

  describe "#check_file" do
    it "returns empty array when no markdown files exist" do
      scanner = Docyard::Doctor::FileScanner.new(docs_path)
      expect(scanner.scan.select { |d| d.category == :LINK }).to eq([])
    end

    it "returns empty array when all internal links are valid" do
      File.write(File.join(docs_path, "about.md"), "# About")

      expect(check("[Link](/about)")).to eq([])
    end

    it "detects broken internal links", :aggregate_failures do
      issues = check("[Link](/nonexistent)")

      expect(issues.size).to eq(1)
      expect(issues.first.file).to eq("index.md")
      expect(issues.first.line).to eq(1)
      expect(issues.first.message).to eq("Broken link to '/nonexistent'")
      expect(issues.first.field).to eq("/nonexistent")
    end

    it "detects multiple broken links in same file", :aggregate_failures do
      content = <<~MD
        # Page
        [Link 1](/missing1)
        Some text
        [Link 2](/missing2)
      MD

      issues = check(content)

      expect(issues.size).to eq(2)
      expect(issues.map(&:field)).to contain_exactly("/missing1", "/missing2")
    end

    it "ignores external links" do
      expect(check("[External](https://example.com)")).to eq([])
    end

    it "ignores image paths" do
      expect(check("[Screenshot](/images/shot.png)")).to eq([])
    end

    it "validates links to index files in directories" do
      FileUtils.mkdir_p(File.join(docs_path, "guide"))
      File.write(File.join(docs_path, "guide", "index.md"), "# Guide")

      expect(check("[Guide](/guide)")).to eq([])
    end

    it "handles anchor links by checking the file portion" do
      File.write(File.join(docs_path, "about.md"), "# About")

      expect(check("[Section](/about#section)")).to eq([])
    end

    it "reports correct line numbers" do
      content = <<~MD
        Line 1
        Line 2
        [Broken](/missing)
        Line 4
      MD

      issues = check(content)

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

      expect(check(content)).to eq([])
    end

    it "ignores links inside tilde code blocks" do
      content = <<~MD
        ~~~markdown
        [Link](/example)
        ~~~
      MD

      expect(check(content)).to eq([])
    end
  end
end

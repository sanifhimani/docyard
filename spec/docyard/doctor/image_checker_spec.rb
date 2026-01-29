# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ImageChecker do
  let(:docs_path) { Dir.mktmpdir }
  let(:checker) { described_class.new(docs_path) }

  after { FileUtils.remove_entry(docs_path) }

  def check(content, file_path = "#{docs_path}/index.md")
    checker.check_file(content, file_path)
  end

  describe "#check_file" do
    it "returns empty array when no markdown files exist" do
      scanner = Docyard::Doctor::FileScanner.new(docs_path)
      expect(scanner.scan.select { |d| d.category == :IMAGE }).to eq([])
    end

    it "returns empty array when all images exist" do
      FileUtils.mkdir_p(File.join(docs_path, "public", "images"))
      File.write(File.join(docs_path, "public", "images", "logo.png"), "")

      expect(check("![Logo](/images/logo.png)")).to eq([])
    end

    it "detects missing images with absolute paths", :aggregate_failures do
      issues = check("![Missing](/images/missing.png)")

      expect(issues.size).to eq(1)
      expect(issues.first.message).to eq("/images/missing.png")
    end

    it "detects missing images with relative paths", :aggregate_failures do
      issues = check("![Missing](./missing.png)")

      expect(issues.size).to eq(1)
      expect(issues.first.message).to eq("./missing.png")
    end

    it "validates relative images correctly" do
      FileUtils.mkdir_p(File.join(docs_path, "guide"))
      File.write(File.join(docs_path, "guide", "image.png"), "")

      expect(check("![Image](./image.png)", "#{docs_path}/guide/page.md")).to eq([])
    end

    it "ignores external image URLs" do
      expect(check("![External](https://example.com/image.png)")).to eq([])
    end

    it "ignores protocol-relative URLs" do
      expect(check("![External](//example.com/image.png)")).to eq([])
    end

    it "detects missing images in HTML img tags", :aggregate_failures do
      issues = check('<img src="/missing.png" alt="Missing">')

      expect(issues.size).to eq(1)
      expect(issues.first.message).to eq("/missing.png")
    end

    it "reports correct file and line number", :aggregate_failures do
      content = <<~MD
        # Title
        Some text
        ![Missing](/missing.png)
      MD

      issues = check(content, "#{docs_path}/page.md")

      expect(issues.first.file).to eq("page.md")
      expect(issues.first.line).to eq(3)
    end

    it "ignores images inside fenced code blocks" do
      content = <<~MD
        # Example

        ```markdown
        ![Image](/example.png)
        ```
      MD

      expect(check(content)).to eq([])
    end

    it "ignores images inside tilde code blocks" do
      content = <<~MD
        ~~~html
        <img src="/example.png" alt="Example">
        ~~~
      MD

      expect(check(content)).to eq([])
    end
  end
end

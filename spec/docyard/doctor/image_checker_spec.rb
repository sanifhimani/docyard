# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ImageChecker do
  let(:temp_dir) { Dir.mktmpdir }
  let(:checker) { described_class.new(temp_dir) }

  after { FileUtils.remove_entry(temp_dir) }

  describe "#check" do
    it "returns empty array when no markdown files exist" do
      expect(checker.check).to eq([])
    end

    it "returns empty array when all images exist" do
      FileUtils.mkdir_p(File.join(temp_dir, "public", "images"))
      File.write(File.join(temp_dir, "public", "images", "logo.png"), "")
      File.write(File.join(temp_dir, "index.md"), "![Logo](/images/logo.png)")

      expect(checker.check).to eq([])
    end

    it "detects missing images with absolute paths", :aggregate_failures do
      File.write(File.join(temp_dir, "index.md"), "![Missing](/images/missing.png)")

      issues = checker.check

      expect(issues.size).to eq(1)
      expect(issues.first.target).to eq("/images/missing.png")
    end

    it "detects missing images with relative paths", :aggregate_failures do
      File.write(File.join(temp_dir, "index.md"), "![Missing](./missing.png)")

      issues = checker.check

      expect(issues.size).to eq(1)
      expect(issues.first.target).to eq("./missing.png")
    end

    it "validates relative images correctly" do
      FileUtils.mkdir_p(File.join(temp_dir, "guide"))
      File.write(File.join(temp_dir, "guide", "image.png"), "")
      File.write(File.join(temp_dir, "guide", "page.md"), "![Image](./image.png)")

      expect(checker.check).to eq([])
    end

    it "ignores external image URLs" do
      File.write(File.join(temp_dir, "index.md"), "![External](https://example.com/image.png)")

      expect(checker.check).to eq([])
    end

    it "ignores protocol-relative URLs" do
      File.write(File.join(temp_dir, "index.md"), "![External](//example.com/image.png)")

      expect(checker.check).to eq([])
    end

    it "detects missing images in HTML img tags", :aggregate_failures do
      File.write(File.join(temp_dir, "index.md"), '<img src="/missing.png" alt="Missing">')

      issues = checker.check

      expect(issues.size).to eq(1)
      expect(issues.first.target).to eq("/missing.png")
    end

    it "reports correct file and line number", :aggregate_failures do
      content = <<~MD
        # Title
        Some text
        ![Missing](/missing.png)
      MD
      File.write(File.join(temp_dir, "page.md"), content)

      issues = checker.check

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
      File.write(File.join(temp_dir, "page.md"), content)

      expect(checker.check).to eq([])
    end

    it "ignores images inside tilde code blocks" do
      content = <<~MD
        ~~~html
        <img src="/example.png" alt="Example">
        ~~~
      MD
      File.write(File.join(temp_dir, "page.md"), content)

      expect(checker.check).to eq([])
    end
  end
end

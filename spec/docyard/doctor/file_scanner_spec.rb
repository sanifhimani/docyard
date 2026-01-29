# frozen_string_literal: true

RSpec.describe Docyard::Doctor::FileScanner do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_page(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  describe "#scan" do
    it "returns empty array when no markdown files exist" do
      scanner = described_class.new(docs_path)
      expect(scanner.scan).to be_empty
    end

    it "scans all markdown files" do
      write_page("guide.md", "# Guide")
      write_page("nested/page.md", "# Page")
      write_page("deep/nested/doc.md", "# Doc")

      scanner = described_class.new(docs_path)
      scanner.scan

      expect(scanner.files_scanned).to eq(3)
    end

    it "collects diagnostics from all checkers", :aggregate_failures do
      write_page("guide.md", <<~MD)
        ---
        invalid: [yaml
        ---

        :::note
        :::

        [Link](/missing)
      MD

      scanner = described_class.new(docs_path)
      diagnostics = scanner.scan

      categories = diagnostics.map(&:category).uniq.sort
      expect(categories).to include(:COMPONENT, :CONTENT, :LINK)
    end

    it "tracks links checked" do
      write_page("guide.md", "[Link1](/about)\n[Link2](/contact)")

      scanner = described_class.new(docs_path)
      scanner.scan

      expect(scanner.links_checked).to eq(2)
    end

    it "tracks images checked" do
      write_page("guide.md", "![Img1](./img1.png)\n![Img2](./img2.png)")

      scanner = described_class.new(docs_path)
      scanner.scan

      expect(scanner.images_checked).to eq(2)
    end

    it "reads each file only once" do
      write_page("guide.md", "# Guide\n\n:::note\nNote\n:::")
      write_page("other.md", "# Other\n\n:::tip\nTip\n:::")

      read_count = 0
      allow(File).to receive(:read).and_wrap_original do |method, *args|
        read_count += 1 if args.first.end_with?(".md")
        method.call(*args)
      end

      scanner = described_class.new(docs_path)
      scanner.scan

      expect(read_count).to eq(2)
    end

    it "processes content through all checkers in single pass" do
      write_page("guide.md", <<~MD)
        :::note
        :::

        :::tabs
        :::

        :badge[Status]{type="invalid"}
      MD

      scanner = described_class.new(docs_path)
      diagnostics = scanner.scan

      codes = diagnostics.map(&:code)
      expect(codes).to include("CALLOUT_EMPTY", "TABS_EMPTY", "BADGE_UNKNOWN_TYPE")
    end
  end
end

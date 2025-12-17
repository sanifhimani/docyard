# frozen_string_literal: true

RSpec.describe Docyard::Components::CodeLineParser do
  describe "#parse" do
    it "splits content into lines" do
      content = "line1\nline2\nline3"

      lines = described_class.new(content).parse

      expect(lines).to eq(["line1\n", "line2\n", "line3"]) # rubocop:disable Style/WordArray
    end

    it "handles content with HTML tags" do
      content = '<span class="k">def</span> test'

      lines = described_class.new(content).parse

      expect(lines).to eq(['<span class="k">def</span> test'])
    end

    it "handles multiline content with tags" do
      content = "<span class=\"k\">def</span>\ntest"

      lines = described_class.new(content).parse

      expect(lines).to eq(["<span class=\"k\">def</span>\n", "test"])
    end

    it "handles spans containing newlines (like Rouge comments)", :aggregate_failures do
      content = "<span class=\"c1\"># comment\n</span>code"

      lines = described_class.new(content).parse

      expect(lines[0]).to eq("<span class=\"c1\"># comment</span>\n")
      expect(lines[1]).to eq("<span class=\"c1\"></span>code")
    end

    it "handles nested spans with newlines", :aggregate_failures do
      content = "<span class=\"outer\"><span class=\"inner\">text\n</span></span>more"

      lines = described_class.new(content).parse

      expect(lines[0]).to eq("<span class=\"outer\"><span class=\"inner\">text</span></span>\n")
      expect(lines[1]).to eq("<span class=\"outer\"><span class=\"inner\"></span></span>more")
    end

    it "handles self-closing tags" do
      content = "text<br/>more"

      lines = described_class.new(content).parse

      expect(lines).to eq(["text<br/>more"])
    end

    it "returns empty string array for empty content" do
      lines = described_class.new("").parse

      expect(lines).to eq([""])
    end

    it "handles content ending without newline" do
      content = "line1\nline2"

      lines = described_class.new(content).parse

      expect(lines).to eq(["line1\n", "line2"]) # rubocop:disable Style/WordArray
    end

    it "handles multiple spans on same line" do
      content = '<span class="k">def</span> <span class="nf">test</span>'

      lines = described_class.new(content).parse

      expect(lines).to eq(['<span class="k">def</span> <span class="nf">test</span>'])
    end
  end
end

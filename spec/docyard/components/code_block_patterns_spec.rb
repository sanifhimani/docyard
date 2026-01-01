# frozen_string_literal: true

RSpec.describe Docyard::Components::CodeBlockPatterns do
  describe "DIFF_MARKER_PATTERN" do
    subject(:pattern) { described_class::DIFF_MARKER_PATTERN }

    it "matches JS/TS style add marker" do
      expect(pattern).to match("// [!code ++]")
    end

    it "matches JS/TS style remove marker" do
      expect(pattern).to match("// [!code --]")
    end

    it "matches Ruby/Python style add marker" do
      expect(pattern).to match("# [!code ++]")
    end

    it "matches Ruby/Python style remove marker" do
      expect(pattern).to match("# [!code --]")
    end

    it "matches C-style block comment add marker" do
      expect(pattern).to match("/* [!code ++] */")
    end

    it "matches C-style block comment remove marker" do
      expect(pattern).to match("/* [!code --] */")
    end

    it "matches SQL style add marker" do
      expect(pattern).to match("-- [!code ++]")
    end

    it "matches SQL style remove marker" do
      expect(pattern).to match("-- [!code --]")
    end

    it "matches HTML comment add marker" do
      expect(pattern).to match("<!-- [!code ++] -->")
    end

    it "matches HTML comment remove marker" do
      expect(pattern).to match("<!-- [!code --] -->")
    end

    it "matches semicolon comment add marker" do
      expect(pattern).to match("; [!code ++]")
    end

    it "captures the diff type" do
      match = "// [!code ++]".match(pattern)

      expect(match.captures.compact.first).to eq("++")
    end

    it "does not match invalid single character markers", :aggregate_failures do
      expect(pattern).not_to match("// [!code +]")
      expect(pattern).not_to match("// [!code -]")
    end
  end

  describe "FOCUS_MARKER_PATTERN" do
    subject(:pattern) { described_class::FOCUS_MARKER_PATTERN }

    it "matches JS/TS style focus marker" do
      expect(pattern).to match("// [!code focus]")
    end

    it "matches Ruby/Python style focus marker" do
      expect(pattern).to match("# [!code focus]")
    end

    it "matches C-style block comment focus marker" do
      expect(pattern).to match("/* [!code focus] */")
    end

    it "matches SQL style focus marker" do
      expect(pattern).to match("-- [!code focus]")
    end

    it "matches HTML comment focus marker" do
      expect(pattern).to match("<!-- [!code focus] -->")
    end

    it "matches semicolon comment focus marker" do
      expect(pattern).to match("; [!code focus]")
    end

    it "does not match focus without space" do
      expect(pattern).not_to match("// [!codefocus]")
    end
  end

  describe "ERROR_MARKER_PATTERN" do
    subject(:pattern) { described_class::ERROR_MARKER_PATTERN }

    it "matches JS/TS style error marker" do
      expect(pattern).to match("// [!code error]")
    end

    it "matches Ruby/Python style error marker" do
      expect(pattern).to match("# [!code error]")
    end

    it "matches C-style block comment error marker" do
      expect(pattern).to match("/* [!code error] */")
    end

    it "matches SQL style error marker" do
      expect(pattern).to match("-- [!code error]")
    end

    it "matches HTML comment error marker" do
      expect(pattern).to match("<!-- [!code error] -->")
    end

    it "matches semicolon comment error marker" do
      expect(pattern).to match("; [!code error]")
    end
  end

  describe "WARNING_MARKER_PATTERN" do
    subject(:pattern) { described_class::WARNING_MARKER_PATTERN }

    it "matches JS/TS style warning marker" do
      expect(pattern).to match("// [!code warning]")
    end

    it "matches Ruby/Python style warning marker" do
      expect(pattern).to match("# [!code warning]")
    end

    it "matches C-style block comment warning marker" do
      expect(pattern).to match("/* [!code warning] */")
    end

    it "matches SQL style warning marker" do
      expect(pattern).to match("-- [!code warning]")
    end

    it "matches HTML comment warning marker" do
      expect(pattern).to match("<!-- [!code warning] -->")
    end

    it "matches semicolon comment warning marker" do
      expect(pattern).to match("; [!code warning]")
    end
  end

  describe "pattern consistency" do
    it "all patterns support the same comment styles", :aggregate_failures do
      comment_styles = [
        "// [!code %s]",
        "# [!code %s]",
        "/* [!code %s] */",
        "-- [!code %s]",
        "<!-- [!code %s] -->",
        "; [!code %s]"
      ]

      focus_tests = comment_styles.map { |style| format(style, "focus") }
      error_tests = comment_styles.map { |style| format(style, "error") }
      warning_tests = comment_styles.map { |style| format(style, "warning") }

      expect(focus_tests).to all(match(described_class::FOCUS_MARKER_PATTERN))
      expect(error_tests).to all(match(described_class::ERROR_MARKER_PATTERN))
      expect(warning_tests).to all(match(described_class::WARNING_MARKER_PATTERN))
    end
  end
end

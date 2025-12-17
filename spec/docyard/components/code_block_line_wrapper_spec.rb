# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docyard::Components::CodeBlockLineWrapper do
  describe ".wrap_code_block" do
    let(:basic_html) do
      '<div class="highlight"><pre><code>line1
line2
line3
</code></pre></div>'
    end

    it "wraps each line with span elements", :aggregate_failures do
      result = described_class.wrap_code_block(basic_html, [], {}, {}, 1)

      expect(result).to include('<span class="docyard-code-line">line1')
      expect(result).to include('<span class="docyard-code-line">line2')
      expect(result).to include('<span class="docyard-code-line">line3')
    end

    context "with highlights" do
      it "adds highlighted class to specified lines", :aggregate_failures do
        result = described_class.wrap_code_block(basic_html, [2], {}, {}, 1)

        expect(result).to include('<span class="docyard-code-line">line1')
        expect(result).to include('<span class="docyard-code-line docyard-code-line--highlighted">line2')
        expect(result).to include('<span class="docyard-code-line">line3')
      end

      it "handles multiple highlighted lines", :aggregate_failures do
        result = described_class.wrap_code_block(basic_html, [1, 3], {}, {}, 1)

        expect(result).to include('<span class="docyard-code-line docyard-code-line--highlighted">line1')
        expect(result).to include('<span class="docyard-code-line">line2')
        expect(result).to include('<span class="docyard-code-line docyard-code-line--highlighted">line3')
      end
    end

    context "with diff lines" do
      it "adds diff-add class for additions", :aggregate_failures do
        result = described_class.wrap_code_block(basic_html, [], { 2 => :addition }, {}, 1)

        expect(result).to include('<span class="docyard-code-line">line1')
        expect(result).to include('<span class="docyard-code-line docyard-code-line--diff-add">line2')
        expect(result).to include('<span class="docyard-code-line">line3')
      end

      it "adds diff-remove class for deletions" do
        result = described_class.wrap_code_block(basic_html, [], { 2 => :deletion }, {}, 1)

        expect(result).to include('<span class="docyard-code-line docyard-code-line--diff-remove">line2')
      end

      it "handles mixed additions and deletions", :aggregate_failures do
        result = described_class.wrap_code_block(basic_html, [], { 1 => :deletion, 3 => :addition }, {}, 1)

        expect(result).to include('<span class="docyard-code-line docyard-code-line--diff-remove">line1')
        expect(result).to include('<span class="docyard-code-line">line2')
        expect(result).to include('<span class="docyard-code-line docyard-code-line--diff-add">line3')
      end
    end

    context "with focus lines" do
      it "adds focus class to specified lines", :aggregate_failures do
        result = described_class.wrap_code_block(basic_html, [], {}, { 2 => true }, 1)

        expect(result).to include('<span class="docyard-code-line">line1')
        expect(result).to include('<span class="docyard-code-line docyard-code-line--focus">line2')
        expect(result).to include('<span class="docyard-code-line">line3')
      end

      it "handles multiple focus lines", :aggregate_failures do
        result = described_class.wrap_code_block(basic_html, [], {}, { 1 => true, 3 => true }, 1)

        expect(result).to include('<span class="docyard-code-line docyard-code-line--focus">line1')
        expect(result).to include('<span class="docyard-code-line">line2')
        expect(result).to include('<span class="docyard-code-line docyard-code-line--focus">line3')
      end
    end

    context "with combined features" do
      it "combines highlight and diff classes" do
        result = described_class.wrap_code_block(basic_html, [2], { 2 => :addition }, {}, 1)

        expect(result).to include("docyard-code-line docyard-code-line--highlighted docyard-code-line--diff-add")
      end

      it "combines all classes on one line", :aggregate_failures do
        result = described_class.wrap_code_block(basic_html, [2], { 2 => :addition }, { 2 => true }, 1)

        expect(result).to include("docyard-code-line--highlighted")
        expect(result).to include("docyard-code-line--diff-add")
        expect(result).to include("docyard-code-line--focus")
      end
    end

    context "with start line offset" do
      it "respects start line for highlights", :aggregate_failures do
        # highlights use display line numbers (10, 11, 12...)
        result = described_class.wrap_code_block(basic_html, [11], {}, {}, 10)

        expect(result).to include('<span class="docyard-code-line">line1')
        expect(result).to include('<span class="docyard-code-line docyard-code-line--highlighted">line2')
        expect(result).to include('<span class="docyard-code-line">line3')
      end

      it "uses source line numbers for diff and focus", :aggregate_failures do
        # diff/focus use source line numbers (1, 2, 3...) regardless of start_line
        result = described_class.wrap_code_block(basic_html, [], { 2 => :addition }, { 3 => true }, 10)

        expect(result).to include('<span class="docyard-code-line">line1')
        expect(result).to include('<span class="docyard-code-line docyard-code-line--diff-add">line2')
        expect(result).to include('<span class="docyard-code-line docyard-code-line--focus">line3')
      end
    end
  end

  describe ".build_line_classes" do
    # build_line_classes(source_line, display_line, highlights, diff_lines, focus_lines)
    # - source_line: used for diff_lines and focus_lines lookups
    # - display_line: used for highlights lookups

    it "returns base class for plain line" do
      result = described_class.build_line_classes(1, 1, [], {}, {})

      expect(result).to eq("docyard-code-line")
    end

    it "adds highlighted class when display line is in highlights" do
      result = described_class.build_line_classes(1, 1, [1], {}, {})

      expect(result).to eq("docyard-code-line docyard-code-line--highlighted")
    end

    it "adds diff-add class for addition based on source line" do
      result = described_class.build_line_classes(1, 10, [], { 1 => :addition }, {})

      expect(result).to eq("docyard-code-line docyard-code-line--diff-add")
    end

    it "adds diff-remove class for deletion based on source line" do
      result = described_class.build_line_classes(1, 10, [], { 1 => :deletion }, {})

      expect(result).to eq("docyard-code-line docyard-code-line--diff-remove")
    end

    it "adds focus class based on source line" do
      result = described_class.build_line_classes(1, 10, [], {}, { 1 => true })

      expect(result).to eq("docyard-code-line docyard-code-line--focus")
    end

    it "combines all applicable classes", :aggregate_failures do
      result = described_class.build_line_classes(1, 1, [1], { 1 => :addition }, { 1 => true })

      expect(result).to include("docyard-code-line")
      expect(result).to include("docyard-code-line--highlighted")
      expect(result).to include("docyard-code-line--diff-add")
      expect(result).to include("docyard-code-line--focus")
    end
  end
end

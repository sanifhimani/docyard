# frozen_string_literal: true

RSpec.describe Docyard::Components::TabsRangeFinder do
  describe ".find_ranges" do
    context "with no tabs" do
      it "returns empty array for plain HTML" do
        html = "<div>Content</div>"

        result = described_class.find_ranges(html)

        expect(result).to eq([])
      end

      it "returns empty array for empty string" do
        result = described_class.find_ranges("")

        expect(result).to eq([])
      end
    end

    context "with single tabs element" do
      it "returns range covering the tabs div", :aggregate_failures do
        html = '<div class="docyard-tabs"><div>Tab content</div></div>'

        result = described_class.find_ranges(html)

        expect(result.length).to eq(1)
        expect(result.first).to be_a(Range)
      end

      it "range starts at the opening tag" do
        html = 'prefix<div class="docyard-tabs"><div>Tab content</div></div>suffix'
        prefix_length = "prefix".length

        result = described_class.find_ranges(html)

        expect(result.first.begin).to eq(prefix_length)
      end

      it "range ends after the closing tag" do
        html = '<div class="docyard-tabs"><div>Tab content</div></div>'

        result = described_class.find_ranges(html)

        expect(result.first.end).to eq(html.length)
      end

      it "returns exclusive range" do
        html = '<div class="docyard-tabs"><div>Tab content</div></div>'

        result = described_class.find_ranges(html)

        expect(result.first.exclude_end?).to be true
      end
    end

    context "with multiple tabs elements" do
      it "returns multiple ranges" do
        html = <<~HTML.strip
          <div class="docyard-tabs"><div>First</div></div>
          <p>separator</p>
          <div class="docyard-tabs"><div>Second</div></div>
        HTML

        result = described_class.find_ranges(html)

        expect(result.length).to eq(2)
      end

      it "ranges do not overlap" do
        html = <<~HTML.strip
          <div class="docyard-tabs"><div>First</div></div>
          <p>separator</p>
          <div class="docyard-tabs"><div>Second</div></div>
        HTML

        result = described_class.find_ranges(html)

        expect(result.first.end).to be < result.last.begin
      end
    end

    context "with nested divs inside tabs" do
      it "correctly matches nested divs", :aggregate_failures do
        html = <<~HTML.strip
          <div class="docyard-tabs">
            <div class="tab">
              <div class="content">Nested content</div>
            </div>
          </div>
        HTML

        result = described_class.find_ranges(html)

        expect(result.length).to eq(1)
        expect(html[result.first]).to eq(html)
      end

      it "handles deeply nested divs", :aggregate_failures do
        html = '<div class="docyard-tabs"><div><div><div>Deep</div></div></div></div>'

        result = described_class.find_ranges(html)

        expect(result.length).to eq(1)
        expect(html[result.first]).to eq(html)
      end
    end

    context "with tabs and other divs" do
      it "only finds tabs divs, not other divs", :aggregate_failures do
        html = '<div class="other">Not tabs</div><div class="docyard-tabs"><div>Tabs</div></div>'

        result = described_class.find_ranges(html)

        expect(result.length).to eq(1)
        expect(html[result.first]).to include("docyard-tabs")
      end
    end

    context "with tabs class variations" do
      it "does not match when additional classes come before closing quote" do
        html = '<div class="docyard-tabs custom-class" id="tabs1"><div>Content</div></div>'

        result = described_class.find_ranges(html)

        expect(result.length).to eq(0)
      end

      it "matches tabs with data attributes after class" do
        html = '<div class="docyard-tabs" data-active="0"><div>Content</div></div>'

        result = described_class.find_ranges(html)

        expect(result.length).to eq(1)
      end
    end
  end

  describe ".find_matching_close_div" do
    it "finds closing div for simple case" do
      html = "<div>content</div>"

      result = described_class.find_matching_close_div(html, 0)

      expect(result).to eq(html.length)
    end

    it "returns nil if no closing div found" do
      html = "<div>unclosed"

      result = described_class.find_matching_close_div(html, 0)

      expect(result).to be_nil
    end

    it "handles nested divs correctly" do
      html = "<div><div>inner</div></div>extra"

      result = described_class.find_matching_close_div(html, 0)

      expect(html[0...result]).to eq("<div><div>inner</div></div>")
    end

    it "returns position after closing tag" do
      html = "<div></div>"

      result = described_class.find_matching_close_div(html, 0)

      expect(result).to eq(html.length)
    end
  end
end

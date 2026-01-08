# frozen_string_literal: true

RSpec.describe Docyard::Components::TableWrapperProcessor do
  let(:processor) { described_class.new }

  def simple_table
    <<~HTML
      <table>
        <thead>
          <tr><th>Name</th><th>Age</th></tr>
        </thead>
        <tbody>
          <tr><td>John</td><td>30</td></tr>
        </tbody>
      </table>
    HTML
  end

  describe "#postprocess" do
    context "with tables" do
      it "wraps table with div container" do
        result = processor.postprocess(simple_table)

        expect(result).to include('<div class="table-wrapper">')
      end

      it "closes wrapper after table", :aggregate_failures do
        result = processor.postprocess(simple_table)

        expect(result).to include("<table>")
        expect(result).to include("</table></div>")
        expect(result).to match(%r{<div class="table-wrapper"><table>.*</table></div>}m)
      end

      it "wraps multiple tables independently", :aggregate_failures do
        html = "<table><tr><td>First</td></tr></table><p>Text</p><table><tr><td>Second</td></tr></table>"

        result = processor.postprocess(html)

        expect(result.scan('<div class="table-wrapper">').count).to eq(2)
        expect(result.scan("</table></div>").count).to eq(2)
      end

      it "preserves table structure", :aggregate_failures do
        html = "<table><thead><tr><th>H</th></tr></thead><tbody><tr><td>D</td></tr></tbody></table>"

        result = processor.postprocess(html)

        expect(result).to include("<thead>")
        expect(result).to include("<tbody>")
      end

      it "preserves table content", :aggregate_failures do
        html = "<table><tr><td>Feature</td><td>Status</td></tr><tr><td>Dark Mode</td><td>Search</td></tr></table>"

        result = processor.postprocess(html)

        expect(result).to include("Feature")
        expect(result).to include("Status")
        expect(result).to include("Dark Mode")
        expect(result).to include("Search")
      end

      it "preserves table class attributes", :aggregate_failures do
        html = '<table class="custom-table"><tr><td>Content</td></tr></table>'

        result = processor.postprocess(html)

        expect(result).to include('<table class="custom-table">')
        expect(result).to include("Content")
      end

      it "preserves nested HTML elements", :aggregate_failures do
        html = "<table><tr><td><strong>Bold</strong></td><td><em>Italic</em></td></tr></table>"

        result = processor.postprocess(html)

        expect(result).to include("<strong>Bold</strong>")
        expect(result).to include("<em>Italic</em>")
      end
    end

    context "without tables" do
      it "returns HTML unchanged when no tables present" do
        html = <<~HTML
          <p>Just a paragraph</p>
          <div class="some-div">Content</div>
          <ul>
            <li>List item</li>
          </ul>
        HTML

        result = processor.postprocess(html)

        expect(result).to eq(html)
      end

      it "does not affect table-like text in content", :aggregate_failures do
        html = <<~HTML
          <p>This paragraph mentions a table but has no actual table element.</p>
        HTML

        result = processor.postprocess(html)

        expect(result).to eq(html)
        expect(result).not_to include("table-wrapper")
      end
    end
  end
end

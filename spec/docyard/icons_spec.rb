# frozen_string_literal: true

RSpec.describe Docyard::Icons do
  describe ".render_file_extension" do
    context "with known file extension" do
      it "renders file type icon for Ruby files", :aggregate_failures do
        result = described_class.render_file_extension("rb")

        expect(result).to include("docyard-icon-file-rb")
        expect(result).to include('aria-hidden="true"')
        expect(result).to include("<svg")
      end

      it "renders file type icon for JavaScript files", :aggregate_failures do
        result = described_class.render_file_extension("js")

        expect(result).to include("docyard-icon-file-js")
        expect(result).to include("<svg")
      end
    end

    context "with unknown file extension" do
      it "falls back to generic file icon", :aggregate_failures do
        result = described_class.render_file_extension("xyz")

        expect(result).to include("ph ph-file")
        expect(result).to include('aria-hidden="true"')
      end
    end
  end
end

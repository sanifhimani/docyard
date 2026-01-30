# frozen_string_literal: true

RSpec.describe Docyard::ErrorOverlay do
  describe ".render" do
    let(:error_diagnostic) do
      Docyard::Diagnostic.new(
        severity: :error,
        category: :CONFIG,
        code: "CONFIG_ERROR",
        message: "Configuration error",
        field: "title"
      )
    end

    let(:warning_diagnostic) do
      Docyard::Diagnostic.new(
        severity: :warning,
        category: :LINK,
        code: "BROKEN_LINK",
        message: "Broken link",
        file: "docs/intro.md",
        line: 10
      )
    end

    let(:page_diagnostic) do
      Docyard::Diagnostic.new(
        severity: :error,
        category: :COMPONENT,
        code: "COMPONENT_ERROR",
        message: "Invalid component",
        file: "docs/page.md",
        line: 5
      )
    end

    context "with no diagnostics" do
      it "returns empty string" do
        result = described_class.render(diagnostics: [], current_file: "test.md", sse_port: 4201)

        expect(result).to eq("")
      end
    end

    context "with diagnostics" do
      let(:diagnostics) { [error_diagnostic, warning_diagnostic] }

      before do
        allow(Docyard::EditorLauncher).to receive(:available?).and_return(true)
      end

      it "renders overlay container with data attributes", :aggregate_failures do
        result = described_class.render(
          diagnostics: diagnostics,
          current_file: "intro.md",
          sse_port: 4201
        )

        expect(result).to include('id="docyard-error-overlay"')
        expect(result).to include('class="docyard-error-overlay"')
        expect(result).to include('data-current-file="intro.md"')
        expect(result).to include('data-sse-port="4201"')
      end

      it "includes error and warning counts", :aggregate_failures do
        result = described_class.render(
          diagnostics: diagnostics,
          current_file: "intro.md",
          sse_port: 4201
        )

        expect(result).to include('data-error-count="1"')
        expect(result).to include('data-warning-count="1"')
      end

      it "calculates global and page counts", :aggregate_failures do
        diagnostics_with_page = [error_diagnostic, page_diagnostic]

        result = described_class.render(
          diagnostics: diagnostics_with_page,
          current_file: "page.md",
          sse_port: 4201
        )

        expect(result).to include('data-global-count="1"')
        expect(result).to include('data-page-count="1"')
      end

      it "serializes diagnostics as JSON", :aggregate_failures do
        result = described_class.render(
          diagnostics: [error_diagnostic],
          current_file: "test.md",
          sse_port: 4201
        )

        expect(result).to include("data-diagnostics='")
        expect(result).to include("CONFIG_ERROR")
        expect(result).to include("Configuration error")
      end

      it "escapes single quotes in JSON" do
        diag_with_quote = Docyard::Diagnostic.new(
          severity: :error,
          category: :CONFIG,
          code: "TEST",
          message: "Error with 'quotes'"
        )

        result = described_class.render(
          diagnostics: [diag_with_quote],
          current_file: "test.md",
          sse_port: 4201
        )

        expect(result).to include("&#39;")
      end

      it "escapes HTML in current file", :aggregate_failures do
        result = described_class.render(
          diagnostics: [error_diagnostic],
          current_file: "<script>alert('xss')</script>",
          sse_port: 4201
        )

        expect(result).to include("&lt;script&gt;")
        expect(result).not_to include("<script>")
      end

      it "includes CSS link" do
        result = described_class.render(
          diagnostics: [error_diagnostic],
          current_file: "test.md",
          sse_port: 4201
        )

        expect(result).to include('href="/_docyard/error-overlay.css"')
      end

      it "includes JS script" do
        result = described_class.render(
          diagnostics: [error_diagnostic],
          current_file: "test.md",
          sse_port: 4201
        )

        expect(result).to include('src="/_docyard/error-overlay.js"')
      end

      it "includes editor availability status" do
        allow(Docyard::EditorLauncher).to receive(:available?).and_return(true)

        result = described_class.render(
          diagnostics: [error_diagnostic],
          current_file: "test.md",
          sse_port: 4201
        )

        expect(result).to include('data-editor-available="true"')
      end

      it "reflects editor unavailability" do
        allow(Docyard::EditorLauncher).to receive(:available?).and_return(false)

        result = described_class.render(
          diagnostics: [error_diagnostic],
          current_file: "test.md",
          sse_port: 4201
        )

        expect(result).to include('data-editor-available="false"')
      end
    end

    describe "global category classification" do
      it "counts CONFIG as global", :aggregate_failures do
        diag = Docyard::Diagnostic.new(
          severity: :error, category: :CONFIG, code: "T", message: "t"
        )

        result = described_class.render(
          diagnostics: [diag], current_file: "test.md", sse_port: 4201
        )

        expect(result).to include('data-global-count="1"')
        expect(result).to include('data-page-count="0"')
      end

      it "counts SIDEBAR as global", :aggregate_failures do
        diag = Docyard::Diagnostic.new(
          severity: :error, category: :SIDEBAR, code: "T", message: "t"
        )

        result = described_class.render(
          diagnostics: [diag], current_file: "test.md", sse_port: 4201
        )

        expect(result).to include('data-global-count="1"')
        expect(result).to include('data-page-count="0"')
      end

      it "counts ORPHAN as global", :aggregate_failures do
        diag = Docyard::Diagnostic.new(
          severity: :warning, category: :ORPHAN, code: "T", message: "t"
        )

        result = described_class.render(
          diagnostics: [diag], current_file: "test.md", sse_port: 4201
        )

        expect(result).to include('data-global-count="1"')
        expect(result).to include('data-page-count="0"')
      end

      it "counts COMPONENT as page-level", :aggregate_failures do
        diag = Docyard::Diagnostic.new(
          severity: :error, category: :COMPONENT, code: "T", message: "t"
        )

        result = described_class.render(
          diagnostics: [diag], current_file: "test.md", sse_port: 4201
        )

        expect(result).to include('data-global-count="0"')
        expect(result).to include('data-page-count="1"')
      end

      it "counts LINK as page-level", :aggregate_failures do
        diag = Docyard::Diagnostic.new(
          severity: :error, category: :LINK, code: "T", message: "t"
        )

        result = described_class.render(
          diagnostics: [diag], current_file: "test.md", sse_port: 4201
        )

        expect(result).to include('data-global-count="0"')
        expect(result).to include('data-page-count="1"')
      end

      it "counts IMAGE as page-level", :aggregate_failures do
        diag = Docyard::Diagnostic.new(
          severity: :error, category: :IMAGE, code: "T", message: "t"
        )

        result = described_class.render(
          diagnostics: [diag], current_file: "test.md", sse_port: 4201
        )

        expect(result).to include('data-global-count="0"')
        expect(result).to include('data-page-count="1"')
      end
    end
  end
end

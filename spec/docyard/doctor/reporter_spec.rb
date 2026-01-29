# frozen_string_literal: true

RSpec.describe Docyard::Doctor::Reporter do
  def build_diagnostic(category:, severity: :error, message: "test", **attrs)
    Docyard::Diagnostic.new(
      severity: severity,
      category: category,
      code: "TEST_CODE",
      message: message,
      **attrs
    )
  end

  let(:empty_diagnostics) { [] }
  let(:stats) { { files: 10, links: 25, images: 5 } }

  describe "#exit_code" do
    it "returns 0 when no diagnostics" do
      reporter = described_class.new(empty_diagnostics)
      expect(reporter.exit_code).to eq(0)
    end

    it "returns 1 when errors exist" do
      diagnostics = [build_diagnostic(category: :LINK, file: "a.md", line: 1)]
      reporter = described_class.new(diagnostics)
      expect(reporter.exit_code).to eq(1)
    end

    it "returns 0 when only warnings exist" do
      diagnostics = [build_diagnostic(category: :ORPHAN, severity: :warning, file: "orphan.md")]
      reporter = described_class.new(diagnostics)
      expect(reporter.exit_code).to eq(0)
    end
  end

  describe "#print" do
    it "outputs stats and 'No issues found' when clean", :aggregate_failures do
      reporter = described_class.new(empty_diagnostics, stats)
      output = capture_stdout { reporter.print }

      expect(output).to include("Checked 10 files, 25 links, 5 images")
      expect(output).to include("No issues found")
    end

    it "outputs category section when diagnostics exist for that category" do
      diagnostics = [build_diagnostic(category: :LINK, file: "page.md", line: 5, message: "/missing")]
      reporter = described_class.new(diagnostics)
      output = capture_stdout { reporter.print }

      expect(output).to include("Broken links")
    end

    it "outputs file location and message for diagnostics" do
      diagnostics = [build_diagnostic(category: :LINK, file: "page.md", line: 5, message: "/missing")]
      reporter = described_class.new(diagnostics)
      output = capture_stdout { reporter.print }

      expect(output).to match(%r{page\.md:5.*/missing})
    end

    it "outputs error prefix for error diagnostics" do
      diagnostics = [build_diagnostic(category: :LINK, severity: :error, file: "a.md", line: 1)]
      reporter = described_class.new(diagnostics)
      output = capture_stdout { reporter.print }

      expect(output).to include("error")
    end

    it "outputs warn prefix for warning diagnostics" do
      diagnostics = [build_diagnostic(category: :ORPHAN, severity: :warning, file: "orphan.md")]
      reporter = described_class.new(diagnostics)
      output = capture_stdout { reporter.print }

      expect(output).to include("warn")
    end

    it "outputs [fixable] suffix for fixable diagnostics" do
      diagnostics = [
        build_diagnostic(
          category: :CONFIG,
          field: "titl",
          message: "unknown key",
          fix: { type: :rename, to: "title" }
        )
      ]
      reporter = described_class.new(diagnostics)
      output = capture_stdout { reporter.print }

      expect(output).to include("[fixable]")
    end

    it "outputs correct summary with singular error" do
      diagnostics = [build_diagnostic(category: :LINK, file: "a.md", line: 1)]
      reporter = described_class.new(diagnostics)
      output = capture_stdout { reporter.print }

      expect(output).to include("1 error")
    end

    it "outputs correct summary with plural errors" do
      diagnostics = [
        build_diagnostic(category: :LINK, file: "a.md", line: 1),
        build_diagnostic(category: :LINK, file: "b.md", line: 2)
      ]
      reporter = described_class.new(diagnostics)
      output = capture_stdout { reporter.print }

      expect(output).to include("2 errors")
    end

    it "outputs warnings count" do
      diagnostics = [
        build_diagnostic(category: :ORPHAN, severity: :warning, file: "a.md"),
        build_diagnostic(category: :ORPHAN, severity: :warning, file: "b.md")
      ]
      reporter = described_class.new(diagnostics)
      output = capture_stdout { reporter.print }

      expect(output).to include("2 warnings")
    end

    it "outputs fixable hint when fixable issues exist" do
      diagnostics = [
        build_diagnostic(category: :CONFIG, field: "titl", fix: { type: :rename })
      ]
      reporter = described_class.new(diagnostics)
      output = capture_stdout { reporter.print }

      expect(output).to include("Run with --fix to auto-fix 1 issue")
    end

    it "does not output fixable hint when fixed flag is true" do
      diagnostics = [
        build_diagnostic(category: :CONFIG, field: "titl", fix: { type: :rename })
      ]
      reporter = described_class.new(diagnostics, {}, fixed: true)
      output = capture_stdout { reporter.print }

      expect(output).not_to include("Run with --fix")
    end

    it "groups diagnostics by category", :aggregate_failures do
      diagnostics = [
        build_diagnostic(category: :CONFIG, field: "titl", message: "unknown key"),
        build_diagnostic(category: :LINK, file: "a.md", line: 1, message: "/missing"),
        build_diagnostic(category: :CONFIG, field: "foo", message: "invalid")
      ]
      reporter = described_class.new(diagnostics)
      output = capture_stdout { reporter.print }

      expect(output).to include("Configuration")
      expect(output).to include("Broken links")
      expect(output.index("Configuration")).to be < output.index("Broken links")
    end
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end
end

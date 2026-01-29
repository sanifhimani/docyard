# frozen_string_literal: true

RSpec.describe Docyard::Doctor::SidebarFixer do
  let(:tmpdir) { Dir.mktmpdir }
  let(:sidebar_path) { File.join(tmpdir, "_sidebar.yml") }

  after { FileUtils.remove_entry(tmpdir) }

  def write_sidebar(content)
    File.write(sidebar_path, content)
  end

  def read_sidebar
    File.read(sidebar_path)
  end

  def make_diagnostic(field:, fix:)
    Docyard::Diagnostic.new(
      severity: :error,
      category: :SIDEBAR,
      code: "SIDEBAR_VALIDATION",
      field: field,
      message: "test",
      fix: fix
    )
  end

  describe "#fix" do
    context "with rename fixes" do
      it "renames misspelled keys", :aggregate_failures do
        write_sidebar("- getting-started:\n    textt: Get Started\n")
        issue = make_diagnostic(
          field: "_sidebar.yml: getting-started",
          fix: { type: :rename, from: "textt", to: "text" }
        )

        fixer = described_class.new(tmpdir)
        fixer.fix([issue])

        expect(read_sidebar).to include("text: Get Started")
        expect(read_sidebar).not_to include("textt:")
        expect(fixer.fixed_count).to eq(1)
      end

      it "preserves indentation", :aggregate_failures do
        write_sidebar("- section:\n    items:\n      - page:\n          icoon: rocket\n")
        issue = make_diagnostic(
          field: "_sidebar.yml: section.page",
          fix: { type: :rename, from: "icoon", to: "icon" }
        )

        fixer = described_class.new(tmpdir)
        fixer.fix([issue])

        expect(read_sidebar).to include("icon: rocket")
        expect(read_sidebar).not_to include("icoon:")
      end
    end

    context "with multiple fixes" do
      it "applies all fixes", :aggregate_failures do
        write_sidebar("- getting-started:\n    textt: Start\n    icoon: rocket\n")
        issues = [
          make_diagnostic(field: "_sidebar.yml: getting-started", fix: { type: :rename, from: "textt", to: "text" }),
          make_diagnostic(field: "_sidebar.yml: getting-started", fix: { type: :rename, from: "icoon", to: "icon" })
        ]

        fixer = described_class.new(tmpdir)
        fixer.fix(issues)

        content = read_sidebar
        expect(content).to include("text: Start")
        expect(content).to include("icon: rocket")
        expect(fixer.fixed_count).to eq(2)
      end
    end

    context "with non-fixable diagnostics" do
      it "ignores diagnostics without fix data" do
        write_sidebar("- nonexistent\n")
        diagnostic = Docyard::Diagnostic.new(
          severity: :error,
          category: :SIDEBAR,
          code: "SIDEBAR_MISSING_FILE",
          field: "_sidebar.yml: nonexistent",
          message: "file not found"
        )

        fixer = described_class.new(tmpdir)
        fixer.fix([diagnostic])

        expect(fixer.fixed_count).to eq(0)
      end
    end

    context "when sidebar file does not exist" do
      it "does nothing" do
        issue = make_diagnostic(
          field: "_sidebar.yml: test",
          fix: { type: :rename, from: "textt", to: "text" }
        )

        fixer = described_class.new(tmpdir)
        fixer.fix([issue])

        expect(fixer.fixed_count).to eq(0)
      end
    end
  end

  describe "#fixed_issues" do
    it "returns list of issues that were fixed" do
      write_sidebar("- getting-started:\n    textt: Test\n")
      issue = make_diagnostic(
        field: "_sidebar.yml: getting-started",
        fix: { type: :rename, from: "textt", to: "text" }
      )

      fixer = described_class.new(tmpdir)
      fixer.fix([issue])

      expect(fixer.fixed_issues).to eq([issue])
    end
  end
end

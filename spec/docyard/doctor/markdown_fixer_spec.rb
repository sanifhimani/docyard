# frozen_string_literal: true

RSpec.describe Docyard::Doctor::MarkdownFixer do
  let(:tmpdir) { Dir.mktmpdir }

  after { FileUtils.remove_entry(tmpdir) }

  def write_file(name, content)
    File.write(File.join(tmpdir, name), content)
  end

  def read_file(name)
    File.read(File.join(tmpdir, name))
  end

  def make_diagnostic(file:, line:, fix:)
    Docyard::Diagnostic.new(
      severity: :warning,
      category: :COMPONENT,
      code: "TEST",
      file: file,
      line: line,
      message: "test",
      fix: fix
    )
  end

  describe "#fix" do
    context "with line_replace fixes" do
      it "replaces content in the file", :aggregate_failures do
        write_file("test.md", "::: tip\nContent\n:::\n")
        diagnostic = make_diagnostic(
          file: "test.md",
          line: 1,
          fix: { type: :line_replace, from: "::: ", to: ":::" }
        )

        fixer = described_class.new(tmpdir)
        fixer.fix([diagnostic])

        expect(read_file("test.md")).to eq(":::tip\nContent\n:::\n")
        expect(fixer.fixed_count).to eq(1)
      end

      it "tracks fixed issues" do
        write_file("test.md", ":badge[X]{type=\"sucess\"}\n")
        diagnostic = make_diagnostic(
          file: "test.md",
          line: 1,
          fix: { type: :line_replace, from: "type=\"sucess\"", to: "type=\"success\"" }
        )

        fixer = described_class.new(tmpdir)
        fixer.fix([diagnostic])

        expect(fixer.fixed_issues).to eq([diagnostic])
      end
    end

    context "with multiple fixes in same file" do
      it "applies all fixes", :aggregate_failures do
        write_file("test.md", "::: tip\nText\n:::\n\n::: warning\nMore\n:::\n")
        diagnostics = [
          make_diagnostic(file: "test.md", line: 1, fix: { type: :line_replace, from: "::: ", to: ":::" }),
          make_diagnostic(file: "test.md", line: 5, fix: { type: :line_replace, from: "::: ", to: ":::" })
        ]

        fixer = described_class.new(tmpdir)
        fixer.fix(diagnostics)

        content = read_file("test.md")
        expect(content).to include(":::tip")
        expect(content).to include(":::warning")
        expect(fixer.fixed_count).to eq(2)
      end
    end

    context "with multiple fixes on same line" do
      it "applies all fixes to the line" do
        write_file("test.md", ":badge[X]{typo=\"val\" typoo=\"val2\"}\n")
        diagnostics = [
          make_diagnostic(file: "test.md", line: 1, fix: { type: :line_replace, from: "typo=", to: "type=" }),
          make_diagnostic(file: "test.md", line: 1, fix: { type: :line_replace, from: "typoo=", to: "type=" })
        ]

        fixer = described_class.new(tmpdir)
        fixer.fix(diagnostics)

        expect(read_file("test.md")).to include("type=\"val\"")
      end
    end

    context "with non-fixable diagnostics" do
      it "ignores diagnostics without fix data" do
        write_file("test.md", "Content\n")
        diagnostic = Docyard::Diagnostic.new(
          severity: :warning,
          category: :COMPONENT,
          code: "TEST",
          file: "test.md",
          line: 1,
          message: "not fixable"
        )

        fixer = described_class.new(tmpdir)
        fixer.fix([diagnostic])

        expect(fixer.fixed_count).to eq(0)
      end
    end

    context "when file does not exist" do
      it "skips the file" do
        diagnostic = make_diagnostic(
          file: "nonexistent.md",
          line: 1,
          fix: { type: :line_replace, from: "a", to: "b" }
        )

        fixer = described_class.new(tmpdir)
        fixer.fix([diagnostic])

        expect(fixer.fixed_count).to eq(0)
      end
    end

    context "when fix pattern not found in line" do
      it "does not modify the file", :aggregate_failures do
        write_file("test.md", "Different content\n")
        diagnostic = make_diagnostic(
          file: "test.md",
          line: 1,
          fix: { type: :line_replace, from: "not found", to: "replacement" }
        )

        fixer = described_class.new(tmpdir)
        fixer.fix([diagnostic])

        expect(read_file("test.md")).to eq("Different content\n")
        expect(fixer.fixed_count).to eq(0)
      end
    end
  end
end

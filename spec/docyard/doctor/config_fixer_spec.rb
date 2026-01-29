# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ConfigFixer do
  let(:tmpdir) { Dir.mktmpdir }
  let(:config_path) { File.join(tmpdir, "docyard.yml") }

  after { FileUtils.remove_entry(tmpdir) }

  def write_config(content)
    File.write(config_path, content)
  end

  def read_config
    File.read(config_path)
  end

  def make_diagnostic(field:, fix:, got: nil)
    details = got ? { got: got } : nil
    Docyard::Diagnostic.new(
      severity: :error,
      category: :CONFIG,
      code: "CONFIG_VALIDATION",
      field: field,
      message: "test",
      details: details,
      fix: fix
    )
  end

  describe "#fix" do
    context "with rename fixes" do
      it "renames misspelled keys", :aggregate_failures do
        write_config("tittle: My Site\n")
        issue = make_diagnostic(field: "tittle", fix: { type: :rename, from: "tittle", to: "title" })

        fixer = described_class.new(config_path)
        fixer.fix([issue])

        expect(read_config).to eq("title: My Site\n")
        expect(fixer.fixed_count).to eq(1)
      end

      it "preserves indentation when renaming nested keys" do
        write_config("search:\n  enbled: true\n")
        issue = make_diagnostic(field: "search.enbled", fix: { type: :rename, from: "enbled", to: "enabled" })

        fixer = described_class.new(config_path)
        fixer.fix([issue])

        expect(read_config).to eq("search:\n  enabled: true\n")
      end
    end

    context "with replace fixes" do
      it "replaces boolean string with actual boolean" do
        write_config("branding:\n  credits: \"yes\"\n")
        issue = make_diagnostic(
          field: "branding.credits",
          got: "\"yes\"",
          fix: { type: :replace, value: true }
        )

        fixer = described_class.new(config_path)
        fixer.fix([issue])

        expect(read_config).to include("credits: true")
      end

      it "replaces enum values" do
        write_config("sidebar: autoo\n")
        issue = make_diagnostic(
          field: "sidebar",
          got: "autoo",
          fix: { type: :replace, value: "auto" }
        )

        fixer = described_class.new(config_path)
        fixer.fix([issue])

        expect(read_config).to include("sidebar: auto")
      end

      it "adds quotes for paths starting with /" do
        write_config("build:\n  base: docs\n")
        issue = make_diagnostic(
          field: "build.base",
          got: "docs",
          fix: { type: :replace, value: "/docs" }
        )

        fixer = described_class.new(config_path)
        fixer.fix([issue])

        expect(read_config).to include("base: \"/docs\"")
      end
    end

    context "with multiple fixes" do
      it "applies all fixes", :aggregate_failures do
        write_config("tittle: Test\nsidebar: autoo\n")
        issues = [
          make_diagnostic(field: "tittle", fix: { type: :rename, from: "tittle", to: "title" }),
          make_diagnostic(field: "sidebar", got: "autoo", fix: { type: :replace, value: "auto" })
        ]

        fixer = described_class.new(config_path)
        fixer.fix(issues)

        content = read_config
        expect(content).to include("title: Test")
        expect(content).to include("sidebar: auto")
        expect(fixer.fixed_count).to eq(2)
      end
    end

    context "with non-fixable diagnostics" do
      it "ignores diagnostics without fix data" do
        write_config("title: Test\n")
        diagnostic = Docyard::Diagnostic.new(
          severity: :error,
          category: :CONFIG,
          code: "CONFIG_VALIDATION",
          field: "logo",
          message: "file not found"
        )

        fixer = described_class.new(config_path)
        fixer.fix([diagnostic])

        expect(fixer.fixed_count).to eq(0)
      end
    end

    context "when config file does not exist" do
      it "does nothing" do
        issue = make_diagnostic(field: "title", fix: { type: :rename, from: "tittle", to: "title" })

        fixer = described_class.new("/nonexistent/path.yml")
        fixer.fix([issue])

        expect(fixer.fixed_count).to eq(0)
      end
    end
  end

  describe "#fixed_issues" do
    it "returns list of issues that were fixed" do
      write_config("tittle: Test\n")
      issue = make_diagnostic(field: "tittle", fix: { type: :rename, from: "tittle", to: "title" })

      fixer = described_class.new(config_path)
      fixer.fix([issue])

      expect(fixer.fixed_issues).to eq([issue])
    end
  end
end

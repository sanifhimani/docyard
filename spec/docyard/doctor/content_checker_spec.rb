# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ContentChecker do
  let(:docs_path) { Dir.mktmpdir }
  let(:checker) { described_class.new(docs_path) }

  after { FileUtils.remove_entry(docs_path) }

  def check(content, file_path = "#{docs_path}/guide.md")
    checker.check_file(content, file_path)
  end

  describe "#check_file" do
    context "when frontmatter is valid" do
      it "returns empty array" do
        content = <<~MD
          ---
          title: Guide
          description: A guide
          ---

          # Guide
        MD

        expect(check(content)).to be_empty
      end
    end

    context "when frontmatter has invalid YAML" do
      it "returns diagnostic with error details", :aggregate_failures do
        content = <<~MD
          ---
          title: Test
          invalid: [unclosed
          ---

          # Content
        MD

        diagnostics = check(content)

        expect(diagnostics.size).to eq(1)
        expect(diagnostics.first.category).to eq(:CONTENT)
        expect(diagnostics.first.code).to eq("FRONTMATTER_INVALID_YAML")
        expect(diagnostics.first.severity).to eq(:error)
        expect(diagnostics.first.file).to eq("guide.md")
      end
    end

    context "when file has no frontmatter" do
      it "returns empty array" do
        content = <<~MD
          # Just Content

          No frontmatter here.
        MD

        expect(check(content)).to be_empty
      end
    end

    context "when multiple files have errors" do
      it "returns diagnostics for each file via FileScanner", :aggregate_failures do
        File.write(File.join(docs_path, "good.md"), "---\ntitle: Good\n---\n\n# Good")
        File.write(File.join(docs_path, "bad1.md"), "---\ntitle: Bad\nbroken: {invalid\n---\n\n# Bad 1")
        File.write(File.join(docs_path, "bad2.md"), "---\nalso: [broken\n---\n\n# Bad 2")

        scanner = Docyard::Doctor::FileScanner.new(docs_path)
        diagnostics = scanner.scan.select { |d| d.category == :CONTENT }

        expect(diagnostics.size).to eq(2)
        expect(diagnostics.map(&:file)).to contain_exactly("bad1.md", "bad2.md")
      end
    end

    context "when frontmatter has duplicate keys" do
      it "returns empty array" do
        content = <<~MD
          ---
          title: First
          title: Second
          ---

          # Content
        MD

        expect(check(content)).to be_empty
      end
    end

    context "when include references existing file" do
      before do
        FileUtils.mkdir_p(File.join(docs_path, "shared"))
        File.write(File.join(docs_path, "shared", "header.md"), "# Header")
      end

      it "returns empty array" do
        content = "# Guide\n\n<!-- @include: shared/header.md -->"

        expect(check(content)).to be_empty
      end
    end

    context "when include references missing file" do
      it "returns diagnostic with file and line", :aggregate_failures do
        content = "# Guide\n\n<!-- @include: missing.md -->"

        diagnostics = check(content)

        expect(diagnostics.size).to eq(1)
        expect(diagnostics.first.code).to eq("INCLUDE_ERROR")
        expect(diagnostics.first.message).to include("file not found")
        expect(diagnostics.first.file).to eq("guide.md")
        expect(diagnostics.first.line).to eq(3)
      end
    end

    context "when include references non-markdown file" do
      before do
        File.write(File.join(docs_path, "config.json"), '{"key": "value"}')
      end

      it "returns diagnostic for non-markdown file", :aggregate_failures do
        content = "# Guide\n\n<!-- @include: config.json -->"

        diagnostics = check(content)

        expect(diagnostics.size).to eq(1)
        expect(diagnostics.first.message).to include("non-markdown")
      end
    end

    context "when include is inside code block" do
      it "ignores the include" do
        content = <<~MD
          # Guide

          ```markdown
          <!-- @include: missing.md -->
          ```
        MD

        expect(check(content)).to be_empty
      end
    end

    context "when include uses relative path" do
      before do
        FileUtils.mkdir_p(File.join(docs_path, "shared"))
        FileUtils.mkdir_p(File.join(docs_path, "guides"))
        File.write(File.join(docs_path, "shared", "header.md"), "# Header")
      end

      it "resolves relative path correctly" do
        content = "# Intro\n\n<!-- @include: ../shared/header.md -->"

        expect(check(content, "#{docs_path}/guides/intro.md")).to be_empty
      end
    end

    context "when snippet references existing file" do
      before do
        FileUtils.mkdir_p(File.join(docs_path, "examples"))
        File.write(File.join(docs_path, "examples", "app.rb"), "puts 'hello'")
      end

      it "returns empty array" do
        content = "# Guide\n\n<<< @/examples/app.rb"

        expect(check(content)).to be_empty
      end
    end

    context "when snippet references missing file" do
      it "returns diagnostic with file and line", :aggregate_failures do
        content = "# Guide\n\n<<< @/examples/missing.rb"

        diagnostics = check(content)

        expect(diagnostics.size).to eq(1)
        expect(diagnostics.first.code).to eq("SNIPPET_ERROR")
        expect(diagnostics.first.message).to include("file not found")
        expect(diagnostics.first.file).to eq("guide.md")
        expect(diagnostics.first.line).to eq(3)
      end
    end

    context "when snippet references missing region" do
      before do
        FileUtils.mkdir_p(File.join(docs_path, "examples"))
        File.write(File.join(docs_path, "examples", "app.rb"), "puts 'hello'")
      end

      it "returns diagnostic for missing region", :aggregate_failures do
        content = "# Guide\n\n<<< @/examples/app.rb#missing-region"

        diagnostics = check(content)

        expect(diagnostics.size).to eq(1)
        expect(diagnostics.first.message).to include("region 'missing-region' not found")
      end
    end

    context "when snippet references existing region" do
      before do
        FileUtils.mkdir_p(File.join(docs_path, "examples"))
        File.write(File.join(docs_path, "examples", "app.rb"), "# #region setup\nputs 'hello'\n# #endregion")
      end

      it "returns empty array" do
        content = "# Guide\n\n<<< @/examples/app.rb#setup"

        expect(check(content)).to be_empty
      end
    end

    context "when snippet is inside code block" do
      it "ignores the snippet" do
        content = "# Guide\n\n```markdown\n<<< @/missing.rb\n```"

        expect(check(content)).to be_empty
      end
    end
  end
end

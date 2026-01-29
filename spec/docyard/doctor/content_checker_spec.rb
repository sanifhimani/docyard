# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ContentChecker do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_page(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  describe "#check" do
    context "when frontmatter is valid" do
      it "returns empty array" do
        write_page("guide.md", <<~MD)
          ---
          title: Guide
          description: A guide
          ---

          # Guide
        MD

        checker = described_class.new(docs_path)
        expect(checker.check).to be_empty
      end
    end

    context "when frontmatter has invalid YAML" do
      it "returns diagnostic with error details", :aggregate_failures do
        write_page("broken.md", <<~MD)
          ---
          title: Test
          invalid: [unclosed
          ---

          # Content
        MD

        checker = described_class.new(docs_path)
        diagnostics = checker.check

        expect(diagnostics.size).to eq(1)
        expect(diagnostics.first.category).to eq(:CONTENT)
        expect(diagnostics.first.code).to eq("FRONTMATTER_INVALID_YAML")
        expect(diagnostics.first.severity).to eq(:error)
        expect(diagnostics.first.file).to eq("broken.md")
      end
    end

    context "when file has no frontmatter" do
      it "returns empty array" do
        write_page("no-frontmatter.md", <<~MD)
          # Just Content

          No frontmatter here.
        MD

        checker = described_class.new(docs_path)
        expect(checker.check).to be_empty
      end
    end

    context "when multiple files have errors" do
      before do
        write_page("good.md", "---\ntitle: Good\n---\n\n# Good")
        write_page("bad1.md", "---\ntitle: Bad\nbroken: {invalid\n---\n\n# Bad 1")
        write_page("bad2.md", "---\nalso: [broken\n---\n\n# Bad 2")
      end

      it "returns diagnostics for each file", :aggregate_failures do
        checker = described_class.new(docs_path)
        diagnostics = checker.check

        expect(diagnostics.size).to eq(2)
        expect(diagnostics.map(&:file)).to contain_exactly("bad1.md", "bad2.md")
      end
    end

    context "when frontmatter has duplicate keys" do
      it "returns empty array" do
        write_page("duplicate.md", <<~MD)
          ---
          title: First
          title: Second
          ---

          # Content
        MD

        checker = described_class.new(docs_path)
        expect(checker.check).to be_empty
      end
    end

    context "when include references existing file" do
      before do
        write_page("shared/header.md", "# Header")
        write_page("guide.md", "# Guide\n\n<!-- @include: shared/header.md -->")
      end

      it "returns empty array" do
        checker = described_class.new(docs_path)
        expect(checker.check).to be_empty
      end
    end

    context "when include references missing file" do
      it "returns diagnostic with file and line", :aggregate_failures do
        write_page("guide.md", "# Guide\n\n<!-- @include: missing.md -->")

        checker = described_class.new(docs_path)
        diagnostics = checker.check

        expect(diagnostics.size).to eq(1)
        expect(diagnostics.first.code).to eq("INCLUDE_ERROR")
        expect(diagnostics.first.message).to include("file not found")
        expect(diagnostics.first.file).to eq("guide.md")
        expect(diagnostics.first.line).to eq(3)
      end
    end

    context "when include references non-markdown file" do
      before do
        write_page("config.json", '{"key": "value"}')
        write_page("guide.md", "# Guide\n\n<!-- @include: config.json -->")
      end

      it "returns diagnostic for non-markdown file", :aggregate_failures do
        checker = described_class.new(docs_path)
        diagnostics = checker.check

        expect(diagnostics.size).to eq(1)
        expect(diagnostics.first.message).to include("non-markdown")
      end
    end

    context "when include is inside code block" do
      it "ignores the include" do
        write_page("guide.md", <<~MD)
          # Guide

          ```markdown
          <!-- @include: missing.md -->
          ```
        MD

        checker = described_class.new(docs_path)
        expect(checker.check).to be_empty
      end
    end

    context "when include uses relative path" do
      before do
        write_page("shared/header.md", "# Header")
        write_page("guides/intro.md", "# Intro\n\n<!-- @include: ../shared/header.md -->")
      end

      it "resolves relative path correctly" do
        checker = described_class.new(docs_path)
        expect(checker.check).to be_empty
      end
    end

    context "when snippet references existing file" do
      before do
        write_page("examples/app.rb", "puts 'hello'")
        write_page("guide.md", "# Guide\n\n<<< @/examples/app.rb")
      end

      it "returns empty array" do
        checker = described_class.new(docs_path)
        expect(checker.check).to be_empty
      end
    end

    context "when snippet references missing file" do
      it "returns diagnostic with file and line", :aggregate_failures do
        write_page("guide.md", "# Guide\n\n<<< @/examples/missing.rb")

        checker = described_class.new(docs_path)
        diagnostics = checker.check

        expect(diagnostics.size).to eq(1)
        expect(diagnostics.first.code).to eq("SNIPPET_ERROR")
        expect(diagnostics.first.message).to include("file not found")
        expect(diagnostics.first.file).to eq("guide.md")
        expect(diagnostics.first.line).to eq(3)
      end
    end

    context "when snippet references missing region" do
      before do
        write_page("examples/app.rb", "puts 'hello'")
        write_page("guide.md", "# Guide\n\n<<< @/examples/app.rb#missing-region")
      end

      it "returns diagnostic for missing region", :aggregate_failures do
        checker = described_class.new(docs_path)
        diagnostics = checker.check

        expect(diagnostics.size).to eq(1)
        expect(diagnostics.first.message).to include("region 'missing-region' not found")
      end
    end

    context "when snippet references existing region" do
      before do
        write_page("examples/app.rb", "# #region setup\nputs 'hello'\n# #endregion")
        write_page("guide.md", "# Guide\n\n<<< @/examples/app.rb#setup")
      end

      it "returns empty array" do
        checker = described_class.new(docs_path)
        expect(checker.check).to be_empty
      end
    end

    context "when snippet is inside code block" do
      it "ignores the snippet" do
        write_page("guide.md", "# Guide\n\n```markdown\n<<< @/missing.rb\n```")

        checker = described_class.new(docs_path)
        expect(checker.check).to be_empty
      end
    end
  end
end

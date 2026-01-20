# frozen_string_literal: true

RSpec.describe Docyard::Components::Processors::IncludeProcessor do
  include_context "with temp directory"

  let(:docs_root) { File.join(temp_dir, "docs") }
  let(:context) { { docs_root: docs_root } }
  let(:processor) { described_class.new(context) }

  before do
    FileUtils.mkdir_p(docs_root)
  end

  describe "#preprocess" do
    context "with basic file inclusion" do
      before do
        create_file("docs/shared/intro.md", "# Welcome\n\nThis is the intro.")
      end

      it "includes content from referenced file", :aggregate_failures do
        content = "Before\n\n<!--@include: shared/intro.md-->\n\nAfter"
        result = processor.preprocess(content)

        expect(result).to include("# Welcome")
        expect(result).to include("This is the intro.")
        expect(result).to include("Before")
        expect(result).to include("After")
      end

      it "removes the include directive", :aggregate_failures do
        content = "<!--@include: shared/intro.md-->"
        result = processor.preprocess(content)

        expect(result).not_to include("@include")
        expect(result).not_to include("<!--")
      end
    end

    context "with relative path inclusion" do
      let(:current_file) { File.join(docs_root, "guide/setup.md") }
      let(:context) { { docs_root: docs_root, current_file: current_file } }

      before do
        create_file("docs/guide/setup.md", "Setup content")
        create_file("docs/guide/shared/snippet.md", "Shared snippet")
      end

      it "resolves relative paths from current file" do
        content = "<!--@include: ./shared/snippet.md-->"
        result = processor.preprocess(content)

        expect(result).to include("Shared snippet")
      end

      it "resolves parent directory paths" do
        create_file("docs/common.md", "Common content")

        content = "<!--@include: ../common.md-->"
        result = processor.preprocess(content)

        expect(result).to include("Common content")
      end
    end

    context "with non-markdown files" do
      before do
        create_file("docs/example.rb", "def hello; end")
      end

      it "shows warning to use code snippets instead", :aggregate_failures do
        content = "<!--@include: example.rb-->"
        result = processor.preprocess(content)

        expect(result).to include("[!WARNING]")
        expect(result).to include("Use code snippets for non-markdown files")
      end
    end

    context "with missing files" do
      it "shows warning callout for missing file", :aggregate_failures do
        content = "<!--@include: nonexistent.md-->"
        result = processor.preprocess(content)

        expect(result).to include("[!WARNING]")
        expect(result).to include("File not found")
        expect(result).to include("nonexistent.md")
      end
    end

    context "with circular includes" do
      before do
        create_file("docs/a.md", "<!--@include: b.md-->")
        create_file("docs/b.md", "<!--@include: a.md-->")
      end

      it "detects and prevents circular includes", :aggregate_failures do
        content = "<!--@include: a.md-->"
        result = processor.preprocess(content)

        expect(result).to include("[!WARNING]")
        expect(result).to include("Circular include detected")
      end
    end

    context "with deeply nested circular includes" do
      before do
        create_file("docs/a.md", "A start\n<!--@include: b.md-->\nA end")
        create_file("docs/b.md", "B start\n<!--@include: c.md-->\nB end")
        create_file("docs/c.md", "C start\n<!--@include: a.md-->\nC end")
      end

      it "detects circular includes through multiple levels", :aggregate_failures do
        content = "<!--@include: a.md-->"
        result = processor.preprocess(content)

        expect(result).to include("A start")
        expect(result).to include("B start")
        expect(result).to include("C start")
        expect(result).to include("[!WARNING]")
        expect(result).to include("Circular include detected")
      end
    end

    context "with nested includes" do
      before do
        create_file("docs/outer.md", "Outer start\n\n<!--@include: inner.md-->\n\nOuter end")
        create_file("docs/inner.md", "Inner content")
      end

      it "processes nested includes", :aggregate_failures do
        content = "<!--@include: outer.md-->"
        result = processor.preprocess(content)

        expect(result).to include("Outer start")
        expect(result).to include("Inner content")
        expect(result).to include("Outer end")
      end
    end

    context "with multiple includes" do
      before do
        create_file("docs/header.md", "# Header")
        create_file("docs/footer.md", "---\nFooter")
      end

      it "processes all includes in document", :aggregate_failures do
        content = <<~MD
          <!--@include: header.md-->

          Main content

          <!--@include: footer.md-->
        MD

        result = processor.preprocess(content)

        expect(result).to include("# Header")
        expect(result).to include("Main content")
        expect(result).to include("Footer")
      end
    end

    context "with whitespace variations" do
      before do
        create_file("docs/content.md", "Included content")
      end

      it "handles spaces around path" do
        content = "<!--@include:   content.md   -->"
        result = processor.preprocess(content)

        expect(result).to include("Included content")
      end

      it "handles no spaces" do
        content = "<!--@include:content.md-->"
        result = processor.preprocess(content)

        expect(result).to include("Included content")
      end
    end

    context "when include is inside other content" do
      before do
        create_file("docs/snippet.md", "Snippet text")
      end

      it "preserves surrounding content" do
        content = "Paragraph before.\n\n<!--@include: snippet.md-->\n\nParagraph after."
        result = processor.preprocess(content)

        expect(result).to eq("Paragraph before.\n\nSnippet text\n\nParagraph after.")
      end
    end

    context "with code blocks" do
      before do
        create_file("docs/real.md", "Real included content")
      end

      it "does not process include syntax inside code blocks", :aggregate_failures do
        content = <<~MARKDOWN
          <!--@include: real.md-->

          ```markdown
          <!--@include: example.md-->
          ```
        MARKDOWN
        result = processor.preprocess(content)

        expect(result).to include("Real included content")
        expect(result).to include("<!--@include: example.md-->")
      end
    end
  end
end

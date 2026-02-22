# frozen_string_literal: true

RSpec.describe Docyard::Components::Processors::CodeBlockAnnotationPreprocessor do
  let(:context) { {} }
  let(:processor) { described_class.new(context) }

  describe "#preprocess" do
    context "with JS-style comment markers" do
      it "extracts annotation markers and consumes the ordered list", :aggregate_failures do
        content = <<~MD
          ```js
          const x = 1; // (1)
          const y = 2;
          ```

          1. This sets x to 1.
        MD

        result = processor.preprocess(content)

        expect(result).not_to include("// (1)")
        expect(result).not_to include("1. This sets x to 1.")
        expect(context[:code_block_annotation_markers][0]).to eq({ 1 => 1 })
        expect(context[:code_block_annotation_content][0][1]).to include("This sets x to 1.")
      end
    end

    context "with Ruby-style comment markers" do
      it "extracts annotation markers from hash comments" do
        content = <<~MD
          ```ruby
          x = 1 # (1)
          ```

          1. Sets x.
        MD

        processor.preprocess(content)

        expect(context[:code_block_annotation_markers][0]).to eq({ 1 => 1 })
      end
    end

    context "with CSS-style comment markers" do
      it "extracts annotation markers from block comments" do
        content = <<~MD
          ```css
          color: red; /* (1) */
          ```

          1. Sets color.
        MD

        processor.preprocess(content)

        expect(context[:code_block_annotation_markers][0]).to eq({ 1 => 1 })
      end
    end

    context "with SQL-style comment markers" do
      it "extracts annotation markers from double-dash comments" do
        content = <<~MD
          ```sql
          SELECT * FROM users -- (1)
          ```

          1. Selects all users.
        MD

        processor.preprocess(content)

        expect(context[:code_block_annotation_markers][0]).to eq({ 1 => 1 })
      end
    end

    context "with HTML-style comment markers" do
      it "extracts annotation markers from HTML comments" do
        content = <<~MD
          ```html
          <div> <!-- (1) -->
          ```

          1. A div element.
        MD

        processor.preprocess(content)

        expect(context[:code_block_annotation_markers][0]).to eq({ 1 => 1 })
      end
    end

    context "with Lisp-style comment markers" do
      it "extracts annotation markers from semicolon comments" do
        content = <<~MD
          ```lisp
          (defun hello () ; (1)
          ```

          1. Defines a function.
        MD

        processor.preprocess(content)

        expect(context[:code_block_annotation_markers][0]).to eq({ 1 => 1 })
      end
    end

    context "with multiple annotations in one block" do
      let(:content) do
        <<~MD
          ```yaml
          theme:
            features:
              - content.code.annotate # (1)
              - navigation.tabs # (2)
          ```

          1. Enables code annotations.
          2. Adds tab navigation.
        MD
      end

      it "extracts all markers and strips them from output", :aggregate_failures do
        result = processor.preprocess(content)

        expect(result).not_to include("# (1)")
        expect(result).not_to include("# (2)")
        expect(context[:code_block_annotation_markers][0]).to eq({ 3 => 1, 4 => 2 })
        expect(context[:code_block_annotation_content][0][1]).to include("Enables code annotations.")
        expect(context[:code_block_annotation_content][0][2]).to include("Adds tab navigation.")
      end
    end

    context "with multiple code blocks having separate annotation lists" do
      it "tracks each block independently", :aggregate_failures do
        content = <<~MD
          ```js
          const a = 1; // (1)
          ```

          1. First block annotation.

          ```ruby
          b = 2 # (1)
          ```

          1. Second block annotation.
        MD

        processor.preprocess(content)

        expect(context[:code_block_annotation_content][0][1]).to include("First block annotation.")
        expect(context[:code_block_annotation_content][1][1]).to include("Second block annotation.")
      end
    end

    context "without annotations" do
      it "leaves code unchanged and does not consume the list", :aggregate_failures do
        content = <<~MD
          ```js
          const x = 1;
          ```

          1. This is a regular list item.
        MD

        result = processor.preprocess(content)

        expect(result).to include("const x = 1;")
        expect(result).to include("1. This is a regular list item.")
        expect(context[:code_block_annotation_markers][0]).to eq({})
      end
    end

    context "with markers but without a following list" do
      it "leaves markers as-is", :aggregate_failures do
        content = <<~MD
          ```js
          const x = 1; // (1)
          ```

          Some paragraph text here.
        MD

        result = processor.preprocess(content)

        expect(result).to include("// (1)")
        expect(context[:code_block_annotation_markers][0]).to eq({})
      end
    end

    context "when code block is inside :::tabs range" do
      it "skips code blocks inside tabs", :aggregate_failures do
        content = <<~MD
          :::tabs
          == Tab 1
          ```js
          const x = 1; // (1)
          ```

          1. Should be skipped.
          :::
        MD

        result = processor.preprocess(content)

        expect(result).to include("// (1)")
        expect(result).to include("1. Should be skipped.")
      end
    end

    context "when code block is inside :::code-group range" do
      it "skips code blocks inside code groups" do
        content = <<~MD
          :::code-group
          ```js
          const x = 1; // (1)
          ```
          :::
        MD

        result = processor.preprocess(content)

        expect(result).to include("// (1)")
      end
    end

    context "with inline markdown in list items" do
      it "renders markdown to HTML", :aggregate_failures do
        content = <<~MD
          ```js
          const x = 1; // (1)
          ```

          1. This enables **bold** and `inline code`.
        MD

        processor.preprocess(content)

        html = context[:code_block_annotation_content][0][1]
        expect(html).to include("<strong>bold</strong>")
        expect(html).to include("<code>inline code</code>")
      end
    end

    context "with multi-line list items" do
      it "handles continuation lines", :aggregate_failures do
        content = <<~MD
          ```js
          const x = 1; // (1)
          ```

          1. First line of explanation.
             Second line of explanation.
        MD

        processor.preprocess(content)

        html = context[:code_block_annotation_content][0][1]
        expect(html).to include("First line of explanation.")
        expect(html).to include("Second line of explanation.")
      end
    end

    context "with whitespace between code block and list" do
      it "tolerates blank lines", :aggregate_failures do
        content = <<~MD
          ```js
          const x = 1; // (1)
          ```


          1. Annotation with extra blank line.
        MD

        result = processor.preprocess(content)

        expect(result).not_to include("1. Annotation with extra blank line.")
        expect(context[:code_block_annotation_markers][0]).to eq({ 1 => 1 })
      end
    end

    context "when stripping markers from code" do
      it "removes only the annotation marker from the code line", :aggregate_failures do
        content = <<~MD
          ```yaml
          key: value # (1)
          ```

          1. Annotation.
        MD

        result = processor.preprocess(content)

        expect(result).to include("key: value")
        expect(result).not_to include("# (1)")
      end
    end
  end
end

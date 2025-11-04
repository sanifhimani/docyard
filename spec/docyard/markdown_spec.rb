# frozen_string_literal: true

RSpec.describe Docyard::Markdown do
  describe "#initialize" do
    it "accepts markdown text" do
      markdown = described_class.new("# Hello")
      expect(markdown).to be_a(described_class)
    end
  end

  describe "#frontmatter" do
    context "with valid frontmatter" do
      let(:text) do
        <<~MARKDOWN
          ---
          title: Test Page
          description: A test
          ---
          # Content
        MARKDOWN
      end

      it "extracts frontmatter as hash" do
        markdown = described_class.new(text)
        expect(markdown.frontmatter).to eq({ "title" => "Test Page", "description" => "A test" })
      end
    end

    context "without frontmatter" do
      it "returns empty hash" do
        markdown = described_class.new("# Just content")
        expect(markdown.frontmatter).to eq({})
      end
    end

    context "with invalid frontmatter" do
      let(:text) do
        <<~MARKDOWN
          ---
          invalid: [yaml: {syntax
          ---
          # Content
        MARKDOWN
      end

      it "returns empty hash and does not raise" do
        markdown = described_class.new(text)
        expect(markdown.frontmatter).to eq({})
      end
    end
  end

  describe "#content" do
    context "with frontmatter" do
      let(:text) do
        <<~MARKDOWN
          ---
          title: Test
          ---
          # Hello World

          This is content.
        MARKDOWN
      end

      it "returns markdown without frontmatter", :aggregate_failures do
        markdown = described_class.new(text)

        expect(markdown.content).to include("# Hello World")
        expect(markdown.content).not_to include("---")
        expect(markdown.content).not_to include("title: Test")
      end
    end

    context "without frontmatter" do
      it "returns original markdown" do
        text = "# Hello World"
        markdown = described_class.new(text)
        expect(markdown.content).to eq(text)
      end
    end
  end

  describe "#html" do
    let(:text) do
      <<~MARKDOWN
        ---
        title: Test
        ---
        # Content
      MARKDOWN
    end

    it "converts markdown to html", :aggregate_failures do
      markdown = described_class.new("# Hello World")

      expect(markdown.html).to include("<h1")
      expect(markdown.html).to include("Hello World")
    end

    it "supports GFM features" do
      markdown = described_class.new("~~strikethrough~~")
      expect(markdown.html).to include("<del>")
    end

    it "does not include frontmatter in html", :aggregate_failures do
      markdown = described_class.new(text)

      expect(markdown.html).to include("<h1")
      expect(markdown.html).not_to include("title: Test")
    end

    it "memoizes result" do
      markdown = described_class.new("# Hello")

      html1 = markdown.html
      html2 = markdown.html
      expect(html1.object_id).to eq(html2.object_id)
    end

    it "adds syntax highlighting classes to code blocks", :aggregate_failures do
      markdown = described_class.new("```ruby\ndef hello\n  puts 'world'\nend\n```")

      expect(markdown.html).to include("highlight")
      expect(markdown.html).to include("language-ruby")
    end
  end

  describe "#title" do
    context "when title exists in frontmatter" do
      let(:text) do
        <<~MARKDOWN
          ---
          title: My Title
          ---
          # Content
        MARKDOWN
      end

      it "returns the title" do
        markdown = described_class.new(text)
        expect(markdown.title).to eq("My Title")
      end
    end

    context "when title does not exist" do
      it "returns nil" do
        markdown = described_class.new("# Content")
        expect(markdown.title).to be_nil
      end
    end
  end
end

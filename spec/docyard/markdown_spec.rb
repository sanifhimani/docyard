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

    context "with line numbers" do
      it "renders line numbers when :line-numbers is specified", :aggregate_failures do
        markdown = described_class.new("```ruby:line-numbers\nputs 'hello'\nputs 'world'\n```")

        expect(markdown.html).to include("docyard-code-block--line-numbers")
        expect(markdown.html).to include("docyard-code-block__lines")
        expect(markdown.html).to include("<span>1</span>")
        expect(markdown.html).to include("<span>2</span>")
      end

      it "does not render line numbers when :no-line-numbers is specified" do
        markdown = described_class.new("```ruby:no-line-numbers\nputs 'hello'\n```")

        expect(markdown.html).not_to include("docyard-code-block--line-numbers")
      end

      it "starts line numbers from custom value with :line-numbers=N", :aggregate_failures do
        markdown = described_class.new("```ruby:line-numbers=10\nline1\nline2\n```")

        expect(markdown.html).to include("<span>10</span>")
        expect(markdown.html).to include("<span>11</span>")
        expect(markdown.html).not_to include("<span>1</span>")
      end

      it "strips line number options from the code fence", :aggregate_failures do
        markdown = described_class.new("```ruby:line-numbers\nputs 'hello'\n```")

        expect(markdown.html).to include("language-ruby")
        expect(markdown.html).not_to include(":line-numbers")
      end
    end

    context "with global line numbers config" do
      let(:config) do
        instance_double(Docyard::Config, data: { "markdown" => { "lineNumbers" => true } })
      end

      it "renders line numbers for all code blocks when enabled globally" do
        markdown = described_class.new("```ruby\nputs 'hello'\n```", config: config)

        expect(markdown.html).to include("docyard-code-block--line-numbers")
      end

      it "allows :no-line-numbers to override global setting" do
        markdown = described_class.new("```ruby:no-line-numbers\nputs 'hello'\n```", config: config)

        expect(markdown.html).not_to include("docyard-code-block--line-numbers")
      end
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

  describe "#sidebar_icon" do
    context "when sidebar.icon exists in frontmatter" do
      let(:text) do
        <<~MARKDOWN
          ---
          title: Test
          sidebar:
            icon: rocket-launch
          ---
          # Content
        MARKDOWN
      end

      it "returns the icon" do
        markdown = described_class.new(text)
        expect(markdown.sidebar_icon).to eq("rocket-launch")
      end
    end

    context "when sidebar section does not exist" do
      it "returns nil" do
        markdown = described_class.new("---\ntitle: Test\n---\n# Content")
        expect(markdown.sidebar_icon).to be_nil
      end
    end

    context "when frontmatter does not exist" do
      it "returns nil" do
        markdown = described_class.new("# Content")
        expect(markdown.sidebar_icon).to be_nil
      end
    end
  end

  describe "#sidebar_text" do
    context "when sidebar.text exists in frontmatter" do
      let(:text) do
        <<~MARKDOWN
          ---
          title: Full Title
          sidebar:
            text: Short
          ---
          # Content
        MARKDOWN
      end

      it "returns the sidebar text" do
        markdown = described_class.new(text)
        expect(markdown.sidebar_text).to eq("Short")
      end
    end

    context "when sidebar.text does not exist" do
      it "returns nil" do
        markdown = described_class.new("---\ntitle: Test\n---\n# Content")
        expect(markdown.sidebar_text).to be_nil
      end
    end
  end

  describe "#sidebar_collapsed" do
    context "when sidebar.collapsed is true" do
      let(:text) do
        <<~MARKDOWN
          ---
          sidebar:
            collapsed: true
          ---
          # Content
        MARKDOWN
      end

      it "returns true" do
        markdown = described_class.new(text)
        expect(markdown.sidebar_collapsed).to be true
      end
    end

    context "when sidebar.collapsed is false" do
      let(:text) do
        <<~MARKDOWN
          ---
          sidebar:
            collapsed: false
          ---
          # Content
        MARKDOWN
      end

      it "returns false" do
        markdown = described_class.new(text)
        expect(markdown.sidebar_collapsed).to be false
      end
    end

    context "when sidebar.collapsed does not exist" do
      it "returns nil" do
        markdown = described_class.new("---\ntitle: Test\n---\n# Content")
        expect(markdown.sidebar_collapsed).to be_nil
      end
    end
  end
end

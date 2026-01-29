# frozen_string_literal: true

RSpec.describe Docyard::Doctor::CodeBlockChecker do
  let(:docs_path) { "/docs" }
  let(:checker) { described_class.new(docs_path) }

  def check(content)
    checker.check_file(content, "#{docs_path}/guide.md")
  end

  describe "option validation" do
    it "accepts valid :line-numbers option" do
      expect(check("```ruby:line-numbers\nputs 'hello'\n```")).to be_empty
    end

    it "accepts valid :line-numbers=N option" do
      expect(check("```ruby:line-numbers=5\nputs 'hello'\n```")).to be_empty
    end

    it "accepts valid :no-line-numbers option" do
      expect(check("```ruby:no-line-numbers\nputs 'hello'\n```")).to be_empty
    end

    it "detects unknown option", :aggregate_failures do
      diagnostics = check("```ruby:linenumber\nputs 'hello'\n```")

      expect(diagnostics.size).to eq(1)
      expect(diagnostics.first.code).to eq("CODE_BLOCK_UNKNOWN_OPTION")
      expect(diagnostics.first.message).to include("unknown code block option")
    end

    it "suggests correct option for typo", :aggregate_failures do
      diagnostics = check("```ruby:line-number\nputs 'hello'\n```")

      expect(diagnostics.first.message).to include("did you mean ':line-numbers'")
    end
  end

  describe "highlight validation" do
    it "accepts valid single line highlight" do
      expect(check("```ruby {1}\nputs 'hello'\n```")).to be_empty
    end

    it "accepts valid multiple line highlights" do
      expect(check("```ruby {1,3,5}\nputs 'hello'\n```")).to be_empty
    end

    it "accepts valid range highlight" do
      expect(check("```ruby {1-5}\nputs 'hello'\n```")).to be_empty
    end

    it "accepts valid mixed highlights" do
      expect(check("```ruby {1,3-5,7}\nputs 'hello'\n```")).to be_empty
    end

    it "detects invalid highlight syntax", :aggregate_failures do
      diagnostics = check("```ruby {abc}\nputs 'hello'\n```")

      expect(diagnostics.size).to eq(1)
      expect(diagnostics.first.code).to eq("CODE_BLOCK_INVALID_HIGHLIGHT")
      expect(diagnostics.first.message).to include("invalid highlight syntax")
    end
  end

  describe "inline marker validation" do
    it "accepts valid [!code ++] marker" do
      expect(check("```ruby\nputs 'hello' // [!code ++]\n```")).to be_empty
    end

    it "accepts valid [!code --] marker" do
      expect(check("```ruby\nputs 'hello' // [!code --]\n```")).to be_empty
    end

    it "accepts valid [!code focus] marker" do
      expect(check("```ruby\nputs 'hello' // [!code focus]\n```")).to be_empty
    end

    it "accepts valid [!code error] marker" do
      expect(check("```ruby\nputs 'hello' // [!code error]\n```")).to be_empty
    end

    it "accepts valid [!code warning] marker" do
      expect(check("```ruby\nputs 'hello' // [!code warning]\n```")).to be_empty
    end

    it "detects unknown inline marker", :aggregate_failures do
      diagnostics = check("```ruby\nputs 'hello' // [!code highlight]\n```")

      expect(diagnostics.size).to eq(1)
      expect(diagnostics.first.code).to eq("CODE_BLOCK_UNKNOWN_MARKER")
      expect(diagnostics.first.message).to include("unknown inline marker")
    end

    it "suggests correct marker for typo", :aggregate_failures do
      diagnostics = check("```ruby\nputs 'hello' // [!code focs]\n```")

      expect(diagnostics.first.message).to include("did you mean '[!code focus]'")
    end

    it "does not check markers outside code blocks" do
      expect(check("This text has [!code focs] in regular markdown")).to be_empty
    end
  end
end

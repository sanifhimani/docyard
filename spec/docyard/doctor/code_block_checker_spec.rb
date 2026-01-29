# frozen_string_literal: true

RSpec.describe Docyard::Doctor::CodeBlockChecker do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_page(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  describe "option validation" do
    it "accepts valid :line-numbers option" do
      write_page("guide.md", "```ruby:line-numbers\nputs 'hello'\n```")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    it "accepts valid :line-numbers=N option" do
      write_page("guide.md", "```ruby:line-numbers=5\nputs 'hello'\n```")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    it "accepts valid :no-line-numbers option" do
      write_page("guide.md", "```ruby:no-line-numbers\nputs 'hello'\n```")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    it "detects unknown option", :aggregate_failures do
      write_page("guide.md", "```ruby:linenumber\nputs 'hello'\n```")

      checker = described_class.new(docs_path)
      diagnostics = checker.check

      expect(diagnostics.size).to eq(1)
      expect(diagnostics.first.code).to eq("CODE_BLOCK_UNKNOWN_OPTION")
      expect(diagnostics.first.message).to include("unknown code block option")
    end

    it "suggests correct option for typo", :aggregate_failures do
      write_page("guide.md", "```ruby:line-number\nputs 'hello'\n```")

      checker = described_class.new(docs_path)
      diagnostics = checker.check

      expect(diagnostics.first.message).to include("did you mean ':line-numbers'")
    end
  end

  describe "highlight validation" do
    it "accepts valid single line highlight" do
      write_page("guide.md", "```ruby {1}\nputs 'hello'\n```")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    it "accepts valid multiple line highlights" do
      write_page("guide.md", "```ruby {1,3,5}\nputs 'hello'\n```")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    it "accepts valid range highlight" do
      write_page("guide.md", "```ruby {1-5}\nputs 'hello'\n```")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    it "accepts valid mixed highlights" do
      write_page("guide.md", "```ruby {1,3-5,7}\nputs 'hello'\n```")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    it "detects invalid highlight syntax", :aggregate_failures do
      write_page("guide.md", "```ruby {abc}\nputs 'hello'\n```")

      checker = described_class.new(docs_path)
      diagnostics = checker.check

      expect(diagnostics.size).to eq(1)
      expect(diagnostics.first.code).to eq("CODE_BLOCK_INVALID_HIGHLIGHT")
      expect(diagnostics.first.message).to include("invalid highlight syntax")
    end
  end

  describe "inline marker validation" do
    it "accepts valid [!code ++] marker" do
      write_page("guide.md", "```ruby\nputs 'hello' // [!code ++]\n```")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    it "accepts valid [!code --] marker" do
      write_page("guide.md", "```ruby\nputs 'hello' // [!code --]\n```")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    it "accepts valid [!code focus] marker" do
      write_page("guide.md", "```ruby\nputs 'hello' // [!code focus]\n```")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    it "accepts valid [!code error] marker" do
      write_page("guide.md", "```ruby\nputs 'hello' // [!code error]\n```")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    it "accepts valid [!code warning] marker" do
      write_page("guide.md", "```ruby\nputs 'hello' // [!code warning]\n```")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end

    it "detects unknown inline marker", :aggregate_failures do
      write_page("guide.md", "```ruby\nputs 'hello' // [!code highlight]\n```")

      checker = described_class.new(docs_path)
      diagnostics = checker.check

      expect(diagnostics.size).to eq(1)
      expect(diagnostics.first.code).to eq("CODE_BLOCK_UNKNOWN_MARKER")
      expect(diagnostics.first.message).to include("unknown inline marker")
    end

    it "suggests correct marker for typo", :aggregate_failures do
      write_page("guide.md", "```ruby\nputs 'hello' // [!code focs]\n```")

      checker = described_class.new(docs_path)
      diagnostics = checker.check

      expect(diagnostics.first.message).to include("did you mean '[!code focus]'")
    end

    it "does not check markers outside code blocks" do
      write_page("guide.md", "This text has [!code focs] in regular markdown")

      checker = described_class.new(docs_path)
      expect(checker.check).to be_empty
    end
  end
end

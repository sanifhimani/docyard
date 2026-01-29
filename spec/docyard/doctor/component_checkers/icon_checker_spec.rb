# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::IconChecker do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_page(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  it "returns empty array for icons without weight" do
    write_page("guide.md", "Click :arrow-right: to continue")

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "returns empty array for valid weights" do
    write_page("guide.md", <<~MD)
      :arrow-right:regular:
      :arrow-right:bold:
      :arrow-right:fill:
      :arrow-right:light:
      :arrow-right:thin:
      :arrow-right:duotone:
    MD

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "detects unknown weight", :aggregate_failures do
    write_page("guide.md", ":arrow-right:heavy:")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("ICON_UNKNOWN_WEIGHT")
    expect(diagnostics.first.message).to include("unknown icon weight 'heavy'")
  end

  it "suggests valid weight when typo detected" do
    write_page("guide.md", ":star:reguler:")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.first.message).to include("did you mean 'regular'?")
  end

  it "detects multiple invalid weights on same line", :aggregate_failures do
    write_page("guide.md", ":arrow-right:heavy: and :star:solid:")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(2)
  end

  it "ignores icons inside code blocks" do
    write_page("guide.md", <<~MD)
      ```markdown
      :arrow-right:invalid:
      ```
    MD

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "ignores icons inside inline code" do
    write_page("guide.md", <<~MD)
      | Syntax | Description |
      |--------|-------------|
      | `:icon-name:weight:` | Icon with weight |

      Use `:arrow-right:invalid:` for the syntax.
    MD

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end
end

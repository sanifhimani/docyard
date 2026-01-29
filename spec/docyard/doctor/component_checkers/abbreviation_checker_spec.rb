# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::AbbreviationChecker do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_page(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  it "returns empty array for valid abbreviations" do
    write_page("guide.md", <<~MD)
      The API is great.

      *[API]: Application Programming Interface
    MD

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "detects duplicate term definitions", :aggregate_failures do
    write_page("guide.md", <<~MD)
      The API is great.

      *[API]: Application Programming Interface
      *[API]: Another Programming Interface
    MD

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("ABBR_DUPLICATE")
    expect(diagnostics.first.message).to include("already defined on line")
  end

  it "detects unused abbreviations", :aggregate_failures do
    write_page("guide.md", <<~MD)
      Some content here.

      *[SDK]: Software Development Kit
    MD

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("ABBR_UNUSED")
    expect(diagnostics.first.message).to include("defined but never used")
  end

  it "ignores abbreviations inside code blocks" do
    write_page("guide.md", <<~MD)
      ```markdown
      *[API]: Application Programming Interface
      ```
    MD

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "detects multiple issues", :aggregate_failures do
    write_page("guide.md", <<~MD)
      The API is great.

      *[API]: Application Programming Interface
      *[API]: Duplicate
      *[SDK]: Never used
    MD

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(2)
    expect(diagnostics.map(&:code)).to contain_exactly("ABBR_DUPLICATE", "ABBR_UNUSED")
  end
end

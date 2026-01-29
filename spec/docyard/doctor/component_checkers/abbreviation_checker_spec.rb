# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::AbbreviationChecker do
  let(:docs_path) { "/docs" }
  let(:checker) { described_class.new(docs_path) }

  def check(content)
    checker.check_file(content, "#{docs_path}/guide.md")
  end

  it "returns empty array for valid abbreviations" do
    content = <<~MD
      The API is great.

      *[API]: Application Programming Interface
    MD

    expect(check(content)).to be_empty
  end

  it "detects duplicate term definitions", :aggregate_failures do
    content = <<~MD
      The API is great.

      *[API]: Application Programming Interface
      *[API]: Another Programming Interface
    MD

    diagnostics = check(content)

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("ABBR_DUPLICATE")
    expect(diagnostics.first.message).to include("already defined on line")
  end

  it "detects unused abbreviations", :aggregate_failures do
    content = <<~MD
      Some content here.

      *[SDK]: Software Development Kit
    MD

    diagnostics = check(content)

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("ABBR_UNUSED")
    expect(diagnostics.first.message).to include("defined but never used")
  end

  it "ignores abbreviations inside code blocks" do
    content = <<~MD
      ```markdown
      *[API]: Application Programming Interface
      ```
    MD

    expect(check(content)).to be_empty
  end

  it "detects multiple issues", :aggregate_failures do
    content = <<~MD
      The API is great.

      *[API]: Application Programming Interface
      *[API]: Duplicate
      *[SDK]: Never used
    MD

    diagnostics = check(content)

    expect(diagnostics.size).to eq(2)
    expect(diagnostics.map(&:code)).to contain_exactly("ABBR_DUPLICATE", "ABBR_UNUSED")
  end
end

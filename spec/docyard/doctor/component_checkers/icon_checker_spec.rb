# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::IconChecker do
  let(:docs_path) { "/docs" }
  let(:checker) { described_class.new(docs_path) }

  def check(content)
    checker.check_file(content, "#{docs_path}/guide.md")
  end

  it "returns empty array for icons without weight" do
    expect(check("Click :arrow-right: to continue")).to be_empty
  end

  it "returns empty array for valid weights" do
    content = <<~MD
      :arrow-right:regular:
      :arrow-right:bold:
      :arrow-right:fill:
      :arrow-right:light:
      :arrow-right:thin:
      :arrow-right:duotone:
    MD

    expect(check(content)).to be_empty
  end

  it "detects unknown weight", :aggregate_failures do
    diagnostics = check(":arrow-right:heavy:")

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("ICON_UNKNOWN_WEIGHT")
    expect(diagnostics.first.message).to include("unknown icon weight 'heavy'")
  end

  it "suggests valid weight when typo detected" do
    diagnostics = check(":star:reguler:")

    expect(diagnostics.first.message).to include("did you mean 'regular'?")
  end

  it "detects multiple invalid weights on same line", :aggregate_failures do
    diagnostics = check(":arrow-right:heavy: and :star:solid:")

    expect(diagnostics.size).to eq(2)
  end

  it "ignores icons inside code blocks" do
    content = <<~MD
      ```markdown
      :arrow-right:invalid:
      ```
    MD

    expect(check(content)).to be_empty
  end

  it "ignores icons inside inline code" do
    content = <<~MD
      | Syntax | Description |
      |--------|-------------|
      | `:icon-name:weight:` | Icon with weight |

      Use `:arrow-right:invalid:` for the syntax.
    MD

    expect(check(content)).to be_empty
  end
end

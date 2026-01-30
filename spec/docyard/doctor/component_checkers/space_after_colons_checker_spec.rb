# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::SpaceAfterColonsChecker do
  let(:docs_path) { "/docs" }
  let(:checker) { described_class.new(docs_path) }

  def check(content)
    checker.check_file(content, "#{docs_path}/guide.md")
  end

  it "returns empty array for valid syntax without space" do
    content = <<~MD
      :::tip
      This is valid.
      :::

      :::tabs
      == Tab 1
      Content
      :::
    MD

    expect(check(content)).to be_empty
  end

  it "detects space after colons for tip", :aggregate_failures do
    content = <<~MD
      ::: tip
      Invalid syntax.
      :::
    MD

    diagnostics = check(content)

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("COMPONENT_SPACE_AFTER_COLONS")
    expect(diagnostics.first.message).to include("did you mean ':::tip'?")
  end

  it "detects space after colons for any component", :aggregate_failures do
    diagnostics = check("::: tabs\n:::\n\n::: warning\n:::")

    expect(diagnostics.size).to eq(2)
    expect(diagnostics.first.message).to eq("invalid syntax '::: tabs', did you mean ':::tabs'?")
    expect(diagnostics.last.message).to eq("invalid syntax '::: warning', did you mean ':::warning'?")
  end

  it "suggests valid component for typo with space", :aggregate_failures do
    diagnostics = check("::: tab\n:::")

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("COMPONENT_UNKNOWN_TYPE")
    expect(diagnostics.first.message).to eq("unknown component 'tab', did you mean ':::tabs'?")
  end

  it "reports unknown component when no close match", :aggregate_failures do
    diagnostics = check("::: quiz\n:::")

    expect(diagnostics.first.code).to eq("COMPONENT_UNKNOWN_TYPE")
    expect(diagnostics.first.message).to eq("unknown component 'quiz'")
  end

  it "ignores content inside code blocks" do
    content = <<~MD
      ```markdown
      ::: tip
      Example syntax
      :::
      ```
    MD

    expect(check(content)).to be_empty
  end
end

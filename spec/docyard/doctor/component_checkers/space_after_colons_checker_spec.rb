# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::SpaceAfterColonsChecker do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_page(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  it "returns empty array for valid syntax without space" do
    write_page("guide.md", <<~MD)
      :::tip
      This is valid.
      :::

      :::tabs
      == Tab 1
      Content
      :::
    MD

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "detects space after colons for tip", :aggregate_failures do
    write_page("guide.md", <<~MD)
      ::: tip
      Invalid syntax.
      :::
    MD

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("COMPONENT_SPACE_AFTER_COLONS")
    expect(diagnostics.first.message).to include("did you mean ':::tip'?")
  end

  it "detects space after colons for any component", :aggregate_failures do
    write_page("guide.md", "::: tabs\n:::\n\n::: warning\n:::")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(2)
    expect(diagnostics.first.message).to eq("invalid syntax '::: tabs', did you mean ':::tabs'?")
    expect(diagnostics.last.message).to eq("invalid syntax '::: warning', did you mean ':::warning'?")
  end

  it "suggests valid component for typo with space", :aggregate_failures do
    write_page("guide.md", "::: tab\n:::")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("COMPONENT_UNKNOWN_TYPE")
    expect(diagnostics.first.message).to eq("unknown component 'tab', did you mean ':::tabs'?")
  end

  it "reports unknown component when no close match", :aggregate_failures do
    write_page("guide.md", "::: quiz\n:::")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.first.code).to eq("COMPONENT_UNKNOWN_TYPE")
    expect(diagnostics.first.message).to eq("unknown component 'quiz'")
  end

  it "ignores content inside code blocks" do
    write_page("guide.md", <<~MD)
      ```markdown
      ::: tip
      Example syntax
      :::
      ```
    MD

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end
end

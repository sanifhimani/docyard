# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::UnknownTypeChecker do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_page(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  it "detects unknown type with suggestion", :aggregate_failures do
    write_page("guide.md", ":::nite\nThis looks like a typo.\n:::")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("COMPONENT_UNKNOWN_TYPE")
    expect(diagnostics.first.message).to include("did you mean ':::note'")
  end

  it "detects unknown type without suggestion for unrecognizable type" do
    write_page("guide.md", ":::foobar\nUnknown type.\n:::")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.first.message).to eq("unknown component ':::foobar'")
  end

  it "does not report known component types as unknown" do
    write_page("guide.md", ":::tabs\n== Tab 1\nContent\n:::")

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "detects :::tab typo and suggests :::tabs", :aggregate_failures do
    write_page("guide.md", ":::tab\n== Tab 1\nContent\n:::")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("COMPONENT_UNKNOWN_TYPE")
    expect(diagnostics.first.message).to include("did you mean ':::tabs'")
  end
end

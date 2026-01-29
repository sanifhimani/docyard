# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentChecker do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_page(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  it "returns empty array for valid content" do
    write_page("guide.md", ":::note\nThis is a note.\n:::")

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "aggregates diagnostics from all checkers", :aggregate_failures do
    content = <<~MD
      :::note
      :::

      :::tabs
      :::

      :::foobar
      Unknown type.
      :::
    MD
    write_page("guide.md", content)

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(3)
    expect(diagnostics.map(&:code)).to contain_exactly("CALLOUT_EMPTY", "TABS_EMPTY", "COMPONENT_UNKNOWN_TYPE")
  end

  it "checks all markdown files in docs_path", :aggregate_failures do
    write_page("guide.md", ":::note\n:::")
    write_page("nested/page.md", ":::tabs\n:::")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(2)
    expect(diagnostics.map(&:file)).to contain_exactly("guide.md", "nested/page.md")
  end
end

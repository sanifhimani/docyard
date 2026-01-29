# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::TabsChecker do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_page(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  it "returns empty array for valid tabs" do
    write_page("guide.md", ":::tabs\n== Tab 1\nContent\n== Tab 2\nMore content\n:::")

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "detects empty tabs block", :aggregate_failures do
    write_page("guide.md", ":::tabs\n:::")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("TABS_EMPTY")
    expect(diagnostics.first.message).to include("Tab Name")
  end

  it "detects unclosed tabs block", :aggregate_failures do
    write_page("guide.md", ":::tabs\n== Tab 1\nContent")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("TABS_UNCLOSED")
    expect(diagnostics.first.message).to include("unclosed")
  end
end

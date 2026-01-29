# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::DetailsChecker do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_page(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  it "returns empty array for valid details" do
    write_page("guide.md", ":::details{title=\"Title\"}\nContent\n:::")

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "allows details with open attribute" do
    write_page("guide.md", ":::details{title=\"Title\" open}\nContent\n:::")

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "allows details without attributes" do
    write_page("guide.md", ":::details\nContent\n:::")

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "detects unclosed details block", :aggregate_failures do
    write_page("guide.md", ":::details{title=\"Title\"}\nContent")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("DETAILS_UNCLOSED")
    expect(diagnostics.first.message).to include("unclosed")
  end

  it "detects unknown details attribute", :aggregate_failures do
    write_page("guide.md", ":::details{name=\"Invalid\"}\nContent\n:::")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("DETAILS_UNKNOWN_ATTR")
    expect(diagnostics.first.message).to include("unknown details attribute 'name'")
  end

  it "suggests correct attribute for typo", :aggregate_failures do
    write_page("guide.md", ":::details{titl=\"Typo\"}\nContent\n:::")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.first.message).to include("did you mean 'title'")
  end
end

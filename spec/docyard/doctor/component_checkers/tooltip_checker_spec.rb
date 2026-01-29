# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::TooltipChecker do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_page(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  it "returns empty array for valid tooltips" do
    write_page("guide.md", <<~MD)
      :tooltip[API]{description="Application Programming Interface"}
      :tooltip[SDK]{description="Software Development Kit" link="/docs/sdk"}
      :tooltip[CLI]{description="Command Line Interface" link="/docs/cli" link_text="Read more"}
    MD

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "detects missing description", :aggregate_failures do
    write_page("guide.md", ':tooltip[API]{link="/docs/api"}')

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("TOOLTIP_MISSING_DESCRIPTION")
    expect(diagnostics.first.message).to include("missing required 'description'")
  end

  it "detects unknown attribute", :aggregate_failures do
    write_page("guide.md", ':tooltip[API]{description="API" title="hover"}')

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("TOOLTIP_UNKNOWN_ATTR")
    expect(diagnostics.first.message).to include("unknown tooltip attribute 'title'")
  end

  it "suggests valid attribute when typo detected" do
    write_page("guide.md", ':tooltip[API]{description="API" lnik="/docs"}')

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.first.message).to include("did you mean 'link'?")
  end

  it "detects multiple issues", :aggregate_failures do
    write_page("guide.md", ':tooltip[API]{title="hover" color="red"}')

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(3)
    expect(diagnostics.map(&:code)).to include("TOOLTIP_MISSING_DESCRIPTION", "TOOLTIP_UNKNOWN_ATTR")
  end

  it "ignores tooltips inside code blocks" do
    write_page("guide.md", <<~MD)
      ```markdown
      :tooltip[API]{title="hover"}
      ```
    MD

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end
end

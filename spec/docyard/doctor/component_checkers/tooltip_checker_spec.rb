# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::TooltipChecker do
  let(:docs_path) { "/docs" }
  let(:checker) { described_class.new(docs_path) }

  def check(content)
    checker.check_file(content, "#{docs_path}/guide.md")
  end

  it "returns empty array for valid tooltips" do
    content = <<~MD
      :tooltip[API]{description="Application Programming Interface"}
      :tooltip[SDK]{description="Software Development Kit" link="/docs/sdk"}
      :tooltip[CLI]{description="Command Line Interface" link="/docs/cli" link_text="Read more"}
    MD

    expect(check(content)).to be_empty
  end

  it "detects missing description", :aggregate_failures do
    diagnostics = check(':tooltip[API]{link="/docs/api"}')

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("TOOLTIP_MISSING_DESCRIPTION")
    expect(diagnostics.first.message).to include("missing required 'description'")
  end

  it "detects unknown attribute", :aggregate_failures do
    diagnostics = check(':tooltip[API]{description="API" title="hover"}')

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("TOOLTIP_UNKNOWN_ATTR")
    expect(diagnostics.first.message).to include("unknown tooltip attribute 'title'")
  end

  it "suggests valid attribute when typo detected" do
    diagnostics = check(':tooltip[API]{description="API" lnik="/docs"}')

    expect(diagnostics.first.message).to include("did you mean 'link'?")
  end

  it "detects multiple issues", :aggregate_failures do
    diagnostics = check(':tooltip[API]{title="hover" color="red"}')

    expect(diagnostics.size).to eq(3)
    expect(diagnostics.map(&:code)).to include("TOOLTIP_MISSING_DESCRIPTION", "TOOLTIP_UNKNOWN_ATTR")
  end

  it "ignores tooltips inside code blocks" do
    content = <<~MD
      ```markdown
      :tooltip[API]{title="hover"}
      ```
    MD

    expect(check(content)).to be_empty
  end
end

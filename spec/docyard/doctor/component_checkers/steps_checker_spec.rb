# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentCheckers::StepsChecker do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.remove_entry(docs_path) }

  def write_page(path, content)
    full_path = File.join(docs_path, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  it "returns empty array for valid steps" do
    write_page("guide.md", ":::steps\n### Step 1\nDo this first.\n### Step 2\nThen this.\n:::")

    checker = described_class.new(docs_path)
    expect(checker.check).to be_empty
  end

  it "detects empty steps block", :aggregate_failures do
    write_page("guide.md", ":::steps\n:::")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("STEPS_EMPTY")
    expect(diagnostics.first.message).to include("### Step Title")
  end

  it "detects unclosed steps block", :aggregate_failures do
    write_page("guide.md", ":::steps\n### Step 1\nContent")

    checker = described_class.new(docs_path)
    diagnostics = checker.check

    expect(diagnostics.size).to eq(1)
    expect(diagnostics.first.code).to eq("STEPS_UNCLOSED")
    expect(diagnostics.first.message).to include("unclosed")
  end
end

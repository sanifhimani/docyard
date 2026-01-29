# frozen_string_literal: true

RSpec.describe Docyard::Doctor::ComponentChecker do
  let(:docs_path) { "/docs" }
  let(:checker) { described_class.new(docs_path) }

  def check(content)
    checker.check_file(content, "#{docs_path}/guide.md")
  end

  it "returns empty array for valid content" do
    expect(check(":::note\nThis is a note.\n:::")).to be_empty
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

    diagnostics = check(content)

    expect(diagnostics.size).to eq(3)
    expect(diagnostics.map(&:code)).to contain_exactly("CALLOUT_EMPTY", "TABS_EMPTY", "COMPONENT_UNKNOWN_TYPE")
  end

  it "checks all markdown files via FileScanner", :aggregate_failures do
    docs_path = Dir.mktmpdir
    begin
      File.write(File.join(docs_path, "guide.md"), ":::note\n:::")
      FileUtils.mkdir_p(File.join(docs_path, "nested"))
      File.write(File.join(docs_path, "nested", "page.md"), ":::tabs\n:::")

      scanner = Docyard::Doctor::FileScanner.new(docs_path)
      diagnostics = scanner.scan

      component_diagnostics = diagnostics.select { |d| d.category == :COMPONENT }
      expect(component_diagnostics.size).to eq(2)
      expect(component_diagnostics.map(&:file)).to contain_exactly("guide.md", "nested/page.md")
    ensure
      FileUtils.remove_entry(docs_path)
    end
  end
end

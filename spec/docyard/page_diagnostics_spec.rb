# frozen_string_literal: true

RSpec.describe Docyard::PageDiagnostics do
  let(:docs_path) { Dir.mktmpdir }

  after { FileUtils.rm_rf(docs_path) }

  describe "#initialize" do
    it "creates checker instances", :aggregate_failures do
      diagnostics = described_class.new(docs_path)

      expect(diagnostics.instance_variable_get(:@content_checker)).to be_a(Docyard::Doctor::ContentChecker)
      expect(diagnostics.instance_variable_get(:@component_checker)).to be_a(Docyard::Doctor::ComponentChecker)
      expect(diagnostics.instance_variable_get(:@link_checker)).to be_a(Docyard::Doctor::LinkChecker)
      expect(diagnostics.instance_variable_get(:@image_checker)).to be_a(Docyard::Doctor::ImageChecker)
    end
  end

  describe "#check" do
    subject(:diagnostics) { described_class.new(docs_path) }

    let(:file_path) { File.join(docs_path, "test.md") }

    context "with valid content" do
      let(:content) do
        <<~MD
          ---
          title: Test Page
          ---
          # Test Page

          This is valid content.
        MD
      end

      before { File.write(file_path, content) }

      it "returns empty array when no issues found", :aggregate_failures do
        result = diagnostics.check(content, file_path)

        expect(result).to be_an(Array)
        expect(result).to be_empty
      end
    end

    context "with broken internal link" do
      let(:content) do
        <<~MD
          ---
          title: Test Page
          ---
          # Test

          [Broken link](/nonexistent)
        MD
      end

      before { File.write(file_path, content) }

      it "returns diagnostics for broken links", :aggregate_failures do
        result = diagnostics.check(content, file_path)

        expect(result).to be_an(Array)
        link_errors = result.select { |d| d.category == :LINK }
        expect(link_errors).not_to be_empty
      end
    end

    context "with broken image reference" do
      let(:content) do
        <<~MD
          ---
          title: Test Page
          ---
          # Test

          ![Missing image](/missing-image.png)
        MD
      end

      before { File.write(file_path, content) }

      it "returns diagnostics for missing images", :aggregate_failures do
        result = diagnostics.check(content, file_path)

        expect(result).to be_an(Array)
        image_errors = result.select { |d| d.category == :IMAGE }
        expect(image_errors).not_to be_empty
      end
    end

    context "with multiple issues" do
      let(:content) do
        <<~MD
          ---
          title: Test Page
          ---
          # Test

          [Broken](/nonexistent)
          ![Missing](/missing.png)
        MD
      end

      before { File.write(file_path, content) }

      it "aggregates diagnostics from all checkers", :aggregate_failures do
        result = diagnostics.check(content, file_path)

        expect(result).to be_an(Array)
        categories = result.map(&:category).uniq
        expect(categories.length).to be >= 1
      end
    end
  end

  describe "#check flattening behavior" do
    it "flattens results from all checkers" do
      content_diag = Docyard::Diagnostic.new(severity: :error, category: :CONTENT, code: "T", message: "e")
      link_diag = Docyard::Diagnostic.new(severity: :warning, category: :LINK, code: "T", message: "w")
      stub_checkers(content_returns: [content_diag], link_returns: [link_diag])

      result = described_class.new(docs_path).check("content", "file.md")

      expect(result).to eq([content_diag, link_diag])
    end

    def stub_checkers(content_returns: [], component_returns: [], link_returns: [], image_returns: [])
      {
        content: stub_checker(Docyard::Doctor::ContentChecker, content_returns),
        component: stub_checker(Docyard::Doctor::ComponentChecker, component_returns),
        link: stub_checker(Docyard::Doctor::LinkChecker, link_returns),
        image: stub_checker(Docyard::Doctor::ImageChecker, image_returns)
      }
    end

    def stub_checker(klass, return_value)
      instance_double(klass).tap do |checker|
        allow(klass).to receive(:new).and_return(checker)
        allow(checker).to receive(:check_file).and_return(return_value)
      end
    end
  end
end

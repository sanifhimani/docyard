# frozen_string_literal: true

RSpec.describe Docyard::Search::DevIndexer do
  include_context "with docs directory"

  let(:config) do
    Dir.chdir(temp_dir) do
      create_config(<<~YAML)
        title: "Test Docs"
        search:
          enabled: true
      YAML
      Docyard::Config.load
    end
  end

  let(:indexer) { described_class.new(docs_path: docs_dir, config: config) }
  let(:success_status) { instance_double(Process::Status, success?: true) }
  let(:failure_status) { instance_double(Process::Status, success?: false) }

  def stub_pagefind_available(available: true)
    if available
      allow(Docyard::Search::PagefindBinary).to receive(:executable).and_return("npx")
    else
      allow(Docyard::Search::PagefindBinary).to receive(:executable).and_return(nil)
    end
  end

  def stub_pagefind_run(success: true, output: "Running pagefind...", error: "")
    status = success ? success_status : failure_status
    allow(Open3).to receive(:capture3)
      .with("npx", "pagefind", "--site", anything, "--output-subdir", "_docyard/pagefind")
      .and_return([output, error, status])

    allow(Open3).to receive(:capture3)
      .with("npx", "pagefind", "--site", anything, "--output-subdir", "_docyard/pagefind",
            "--exclude-selectors", anything, "--exclude-selectors", anything)
      .and_return([output, error, status])
  end

  before do
    create_doc("index.md", "---\ntitle: Home\n---\n\n# Welcome\n\nThis is the home page.")
    create_doc("guide.md", "---\ntitle: Guide\n---\n\n# Guide\n\nThis is a guide.")
  end

  after do
    indexer.cleanup
    Docyard::Search::PagefindBinary.reset!
  end

  describe "#generate" do
    context "when search is disabled" do
      let(:config) do
        Dir.chdir(temp_dir) do
          create_config(<<~YAML)
            title: "Test Docs"
            search:
              enabled: false
          YAML
          Docyard::Config.load
        end
      end

      it "returns nil without generating" do
        expect(indexer.generate).to be_nil
      end

      it "does not create a temp directory" do
        indexer.generate
        expect(indexer.temp_dir).to be_nil
      end
    end

    context "when pagefind is not available" do
      before { stub_pagefind_available(available: false) }

      it "returns nil" do
        expect(indexer.generate).to be_nil
      end

      it "does not create a temp directory" do
        indexer.generate
        expect(indexer.temp_dir).to be_nil
      end
    end

    context "when pagefind is available" do
      before do
        stub_pagefind_available
        stub_pagefind_run
      end

      it "returns the pagefind path under _docyard" do
        result = indexer.generate
        expect(result).to end_with("_docyard/pagefind")
      end

      it "creates a temp directory", :aggregate_failures do
        indexer.generate
        expect(indexer.temp_dir).not_to be_nil
        expect(Dir.exist?(indexer.temp_dir)).to be true
      end

      it "generates HTML files in the temp directory" do
        indexer.generate
        html_files = Dir.glob(File.join(indexer.temp_dir, "**", "*.html"))
        expect(html_files.size).to eq(2)
      end

      it "sets the pagefind_path under _docyard" do
        indexer.generate
        expect(indexer.pagefind_path).to end_with("_docyard/pagefind")
      end
    end

    context "when search.exclude is configured" do
      let(:config) do
        Dir.chdir(temp_dir) do
          create_config(<<~YAML)
            title: "Test Docs"
            search:
              enabled: true
              exclude:
                - ".docyard-code-block"
                - ".sidebar"
          YAML
          Docyard::Config.load
        end
      end

      before do
        stub_pagefind_available
        stub_pagefind_run
      end

      it "generates index successfully with exclusions configured" do
        result = indexer.generate
        expect(result).to end_with("_docyard/pagefind")
      end
    end

    context "when pagefind fails" do
      before do
        stub_pagefind_available
        stub_pagefind_run(success: false, error: "Error: Invalid site")
      end

      it "returns nil and logs error", :aggregate_failures do
        output = capture_logger_output { indexer.generate }

        expect(output).to match(/Search index generation failed/)
        expect(indexer.pagefind_path).to be_nil
      end

      it "cleans up the temp directory", :aggregate_failures do
        capture_logger_output { indexer.generate }

        expect(indexer.temp_dir).to be_nil.or(satisfy { |dir| dir && !Dir.exist?(dir) })
      end
    end
  end

  describe "#cleanup" do
    context "when temp_dir exists" do
      before do
        stub_pagefind_available
        stub_pagefind_run
        indexer.generate
      end

      it "removes the temp directory", :aggregate_failures do
        temp_path = indexer.temp_dir
        expect(Dir.exist?(temp_path)).to be true

        indexer.cleanup

        expect(Dir.exist?(temp_path)).to be false
      end
    end

    context "when temp_dir is nil" do
      it "does not raise an error" do
        expect { indexer.cleanup }.not_to raise_error
      end
    end

    context "when temp_dir does not exist" do
      before do
        allow(indexer).to receive(:temp_dir).and_return("/nonexistent/path")
      end

      it "does not raise an error" do
        expect { indexer.cleanup }.not_to raise_error
      end
    end
  end

  describe "filtering" do
    context "when docs include landing pages" do
      before do
        create_doc("index.md", <<~MD)
          ---
          landing:
            hero:
              title: Welcome
          ---
          # Landing Page
        MD
        create_doc("guide.md", "---\ntitle: Guide\n---\n\n# Guide")

        stub_pagefind_available
        stub_pagefind_run(output: "Indexed 1 page")
      end

      it "excludes landing pages from indexing", :aggregate_failures do
        indexer.generate
        html_files = Dir.glob(File.join(indexer.temp_dir, "**", "*.html"))

        expect(html_files.size).to eq(1)
        expect(html_files.first).to include("guide")
      end
    end
  end
end

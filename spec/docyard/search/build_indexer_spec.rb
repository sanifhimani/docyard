# frozen_string_literal: true

RSpec.describe Docyard::Search::BuildIndexer do
  include_context "with temp directory"

  let(:config) { Docyard::Config.load(temp_dir) }
  let(:indexer) { described_class.new(config, verbose: false) }
  let(:success_status) { instance_double(Process::Status, success?: true) }
  let(:failure_status) { instance_double(Process::Status, success?: false) }

  after { Docyard::Search::PagefindBinary.reset! }

  def stub_pagefind_available(available: true)
    if available
      allow(Docyard::Search::PagefindBinary).to receive(:executable).and_return("npx")
    else
      allow(Docyard::Search::PagefindBinary).to receive(:executable).and_return(nil)
    end
  end

  def stub_pagefind_run(success: true, page_count: 42, error: nil)
    status = success ? success_status : failure_status
    stdout = success ? "Running Pagefind\nIndexed #{page_count} pages\n" : ""
    stderr = error || ""

    allow(Open3).to receive(:capture3)
      .with("npx", "pagefind", "--site", anything, "--output-subdir", "_docyard/pagefind")
      .and_return([stdout, stderr, status])

    allow(Open3).to receive(:capture3)
      .with("npx", "pagefind", "--site", anything, "--output-subdir", "_docyard/pagefind",
            "--exclude-selectors", anything, "--exclude-selectors", anything)
      .and_return([stdout, stderr, status])
  end

  describe "#index" do
    context "when search is disabled" do
      before do
        create_config(<<~YAML)
          search:
            enabled: false
        YAML
      end

      it "returns 0 without running pagefind" do
        count, _details = indexer.index

        expect(count).to eq(0)
      end
    end

    context "when pagefind is not available" do
      before { stub_pagefind_available(available: false) }

      it "returns 0" do
        count, _details = indexer.index
        expect(count).to eq(0)
      end

      it "logs a warning" do
        output = capture_logger_output { indexer.index }
        expect(output).to include("Search disabled: Pagefind binary not available")
      end
    end

    context "when pagefind is available and succeeds" do
      before do
        stub_pagefind_available
        stub_pagefind_run(success: true, page_count: 42)
      end

      it "returns the page count" do
        count, _details = indexer.index
        expect(count).to eq(42)
      end
    end

    context "when pagefind fails" do
      before do
        stub_pagefind_available
        stub_pagefind_run(success: false, error: "Error: something went wrong")
      end

      it "returns 0" do
        count, _details = indexer.index
        expect(count).to eq(0)
      end
    end

    context "with search exclusions configured" do
      before do
        create_config(<<~YAML)
          search:
            exclude:
              - ".sidebar"
              - ".footer"
        YAML
        stub_pagefind_available
        stub_pagefind_run(success: true, page_count: 10)
      end

      it "returns page count when exclusions are configured" do
        count, _details = indexer.index
        expect(count).to eq(10)
      end
    end

    context "with custom output directory" do
      before do
        create_config(<<~YAML)
          build:
            output: "_site"
        YAML
        stub_pagefind_available
        stub_pagefind_run(success: true, page_count: 5)
      end

      it "returns page count with custom output directory" do
        custom_indexer = described_class.new(Docyard::Config.load(temp_dir))
        count, _details = custom_indexer.index

        expect(count).to eq(5)
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe Docyard::Search::BuildIndexer do
  include_context "with temp directory"

  let(:config) { Docyard::Config.load(temp_dir) }
  let(:indexer) { described_class.new(config, verbose: false) }
  let(:success_status) { instance_double(Process::Status, success?: true) }
  let(:failure_status) { instance_double(Process::Status, success?: false) }

  def stub_pagefind_available(available: true)
    status = available ? success_status : failure_status
    allow(Open3).to receive(:capture3)
      .with("npx", "pagefind", "--version")
      .and_return(["1.0.0", "", status])
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
        result = indexer.index

        expect(result).to eq(0)
      end
    end

    context "when pagefind is not available" do
      before { stub_pagefind_available(available: false) }

      it "logs warning about missing pagefind" do
        output = capture_logger_output { indexer.index }

        expect(output).to match(/Search index skipped/)
      end

      it "returns 0" do
        expect(indexer.index).to eq(0)
      end
    end

    context "when pagefind command not found" do
      before do
        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--version")
          .and_raise(Errno::ENOENT)
      end

      it "returns 0" do
        expect(indexer.index).to eq(0)
      end
    end

    context "when pagefind is available and succeeds" do
      before do
        stub_pagefind_available
        stub_pagefind_run(success: true, page_count: 42)
      end

      it "returns the page count" do
        expect(indexer.index).to eq(42)
      end

      it "logs success message" do
        output = capture_logger_output { indexer.index }

        expect(output).to match(/Generated search index.*42 pages/)
      end
    end

    context "when pagefind fails" do
      before do
        stub_pagefind_available
        stub_pagefind_run(success: false, error: "Error: something went wrong")
      end

      it "returns 0" do
        expect(indexer.index).to eq(0)
      end

      it "logs warning with error message" do
        output = capture_logger_output { indexer.index }

        expect(output).to match(/Search indexing failed/)
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
        expect(indexer.index).to eq(10)
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

        expect(custom_indexer.index).to eq(5)
      end
    end
  end
end

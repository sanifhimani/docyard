# frozen_string_literal: true

RSpec.describe Docyard::Search::BuildIndexer do
  include_context "with temp directory"

  let(:config) { Docyard::Config.load(temp_dir) }
  let(:indexer) { described_class.new(config, verbose: false) }

  describe "#index" do
    context "when search is disabled" do
      before do
        create_config(<<~YAML)
          search:
            enabled: false
        YAML
        allow(Open3).to receive(:capture3)
      end

      it "returns 0 without running pagefind", :aggregate_failures do
        result = indexer.index

        expect(result).to eq(0)
        expect(Open3).not_to have_received(:capture3)
      end
    end

    context "when pagefind is not available" do
      before do
        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--version")
          .and_return(["", "error", instance_double(Process::Status, success?: false)])
      end

      it "logs warning about missing pagefind" do
        expect { indexer.index }.to output(/Search index skipped/).to_stderr
      end

      it "returns 0" do
        result = indexer.index

        expect(result).to eq(0)
      end
    end

    context "when pagefind command not found" do
      before do
        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--version")
          .and_raise(Errno::ENOENT)
      end

      it "returns 0" do
        result = indexer.index

        expect(result).to eq(0)
      end
    end

    context "when pagefind is available and succeeds" do
      before do
        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--version")
          .and_return(["1.0.0", "", instance_double(Process::Status, success?: true)])

        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--site", "dist")
          .and_return([
                        "Running Pagefind\nIndexed 42 pages\n",
                        "",
                        instance_double(Process::Status, success?: true)
                      ])
      end

      it "returns the page count" do
        result = indexer.index

        expect(result).to eq(42)
      end

      it "logs success message" do
        expect { indexer.index }.to output(/Generated search index.*42 pages/).to_stdout
      end
    end

    context "when pagefind fails" do
      before do
        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--version")
          .and_return(["1.0.0", "", instance_double(Process::Status, success?: true)])

        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--site", "dist")
          .and_return([
                        "",
                        "Error: something went wrong",
                        instance_double(Process::Status, success?: false)
                      ])
      end

      it "returns 0" do
        result = indexer.index

        expect(result).to eq(0)
      end

      it "logs warning with error message" do
        expect { indexer.index }.to output(/Search indexing failed/).to_stderr
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

        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--version")
          .and_return(["1.0.0", "", instance_double(Process::Status, success?: true)])

        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--site", "dist",
                "--exclude-selectors", ".sidebar",
                "--exclude-selectors", ".footer")
          .and_return(["Indexed 10 pages", "", instance_double(Process::Status, success?: true)])
      end

      it "passes exclusion patterns to pagefind" do
        indexer.index

        expect(Open3).to have_received(:capture3)
          .with("npx", "pagefind", "--site", "dist",
                "--exclude-selectors", ".sidebar",
                "--exclude-selectors", ".footer")
      end
    end

    context "with custom output directory" do
      before do
        create_config(<<~YAML)
          build:
            output_dir: "_site"
        YAML

        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--version")
          .and_return(["1.0.0", "", instance_double(Process::Status, success?: true)])

        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--site", "_site")
          .and_return(["Indexed 5 pages", "", instance_double(Process::Status, success?: true)])
      end

      it "uses custom output directory" do
        custom_indexer = described_class.new(Docyard::Config.load(temp_dir))

        custom_indexer.index

        expect(Open3).to have_received(:capture3)
          .with("npx", "pagefind", "--site", "_site")
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe Docyard::Search::DevIndexer do
  include_context "with docs directory"

  let(:config) do
    Dir.chdir(temp_dir) do
      create_config(<<~YAML)
        site:
          title: "Test Docs"
        search:
          enabled: true
      YAML
      Docyard::Config.load
    end
  end

  let(:indexer) { described_class.new(docs_path: docs_dir, config: config) }

  before do
    create_doc("index.md", "---\ntitle: Home\n---\n\n# Welcome\n\nThis is the home page.")
    create_doc("guide.md", "---\ntitle: Guide\n---\n\n# Guide\n\nThis is a guide.")
  end

  after do
    indexer.cleanup
  end

  describe "#initialize" do
    it "stores the docs path" do
      expect(indexer.docs_path).to eq(docs_dir)
    end

    it "stores the config" do
      expect(indexer.config).to eq(config)
    end

    it "initializes temp_dir as nil" do
      expect(indexer.temp_dir).to be_nil
    end

    it "initializes pagefind_path as nil" do
      expect(indexer.pagefind_path).to be_nil
    end
  end

  describe "#generate" do
    context "when search is disabled" do
      let(:config) do
        Dir.chdir(temp_dir) do
          create_config(<<~YAML)
            site:
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

    context "when pagefind is not available", :aggregate_failures do
      before do
        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--version")
          .and_return(["", "not found", instance_double(Process::Status, success?: false)])
      end

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
        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--version")
          .and_return(["1.0.0", "", instance_double(Process::Status, success?: true)])

        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--site", anything)
          .and_return(["Running pagefind...", "", instance_double(Process::Status, success?: true)])
      end

      it "returns the pagefind path" do
        result = indexer.generate
        expect(result).to end_with("pagefind")
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

      it "sets the pagefind_path" do
        indexer.generate
        expect(indexer.pagefind_path).to end_with("pagefind")
      end
    end

    context "when search.exclude is configured" do
      let(:config) do
        Dir.chdir(temp_dir) do
          create_config(<<~YAML)
            site:
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
        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--version")
          .and_return(["1.0.0", "", instance_double(Process::Status, success?: true)])
      end

      it "generates index successfully with exclusions configured", :aggregate_failures do
        captured_args = nil
        allow(Open3).to receive(:capture3) do |*args|
          captured_args = args if args.first == "npx" && args[1] == "pagefind" && args[2] != "--version"
          ["Running pagefind...", "", instance_double(Process::Status, success?: true)]
        end

        result = indexer.generate

        expect(result).to end_with("pagefind")
        expect(captured_args).to include("--exclude-selectors", ".docyard-code-block")
        expect(captured_args).to include("--exclude-selectors", ".sidebar")
      end
    end

    context "when pagefind fails" do
      before do
        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--version")
          .and_return(["1.0.0", "", instance_double(Process::Status, success?: true)])

        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--site", anything)
          .and_return(["", "Error: Invalid site", instance_double(Process::Status, success?: false)])
      end

      it "returns nil", :aggregate_failures do
        expect { indexer.generate }.to output(/Search index generation failed/).to_stderr
        expect(indexer.pagefind_path).to be_nil
      end

      it "cleans up the temp directory", :aggregate_failures do
        expect { indexer.generate }.to output.to_stderr
        expect(indexer.temp_dir).to be_nil.or(satisfy { |dir| dir && !Dir.exist?(dir) })
      end
    end
  end

  describe "#cleanup" do
    context "when temp_dir exists" do
      before do
        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--version")
          .and_return(["1.0.0", "", instance_double(Process::Status, success?: true)])

        allow(Open3).to receive(:capture3)
          .with("npx", "pagefind", "--site", anything)
          .and_return(["Running pagefind...", "", instance_double(Process::Status, success?: true)])

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
end

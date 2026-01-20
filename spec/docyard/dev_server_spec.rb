# frozen_string_literal: true

RSpec.describe Docyard::DevServer do
  include_context "with temp directory"

  describe "#initialize" do
    it "uses default port and host", :aggregate_failures do
      server = described_class.new(docs_path: temp_dir)

      expect(server.port).to eq(4200)
      expect(server.host).to eq("localhost")
      expect(server.docs_path).to eq(temp_dir)
    end

    it "accepts custom port and host", :aggregate_failures do
      server = described_class.new(port: 8080, host: "0.0.0.0", docs_path: temp_dir)

      expect(server.port).to eq(8080)
      expect(server.host).to eq("0.0.0.0")
    end

    it "disables search by default" do
      server = described_class.new(docs_path: temp_dir)

      expect(server.search_enabled).to be(false)
    end

    it "accepts search option" do
      server = described_class.new(docs_path: temp_dir, search: true)

      expect(server.search_enabled).to be(true)
    end

    it "loads configuration", :aggregate_failures do
      create_config("title: Test Documentation")
      Dir.chdir(temp_dir) do
        server = described_class.new(docs_path: temp_dir)

        expect(server.config).to be_a(Docyard::Config)
        expect(server.config.title).to eq("Test Documentation")
      end
    end

    it "uses default config when no config file exists" do
      Dir.chdir(temp_dir) do
        server = described_class.new(docs_path: temp_dir)

        expect(server.config.title).to eq("Documentation")
      end
    end
  end
end

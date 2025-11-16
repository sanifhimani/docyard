# frozen_string_literal: true

RSpec.describe Docyard::PreviewServer do
  let(:temp_dir) { Dir.mktmpdir }
  let(:output_dir) { File.join(temp_dir, "dist") }

  before do
    Dir.chdir(temp_dir) do
      FileUtils.mkdir_p(output_dir)
      File.write(File.join(output_dir, "index.html"), "<html><body>Home</body></html>")

      File.write("docyard.yml", <<~YAML)
        build:
          output_dir: "dist"
          base_url: "/"
      YAML
    end
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#initialize" do
    it "sets default port" do
      Dir.chdir(temp_dir) do
        server = described_class.new

        expect(server.port).to eq(4000)
      end
    end

    it "allows custom port" do
      Dir.chdir(temp_dir) do
        server = described_class.new(port: 5000)

        expect(server.port).to eq(5000)
      end
    end

    it "reads output_dir from config" do
      Dir.chdir(temp_dir) do
        server = described_class.new

        expect(server.output_dir).to end_with("dist")
      end
    end
  end

  describe "#start" do
    context "when output directory does not exist" do
      it "aborts with error message" do
        Dir.chdir(temp_dir) do
          FileUtils.rm_rf(output_dir)
          server = described_class.new

          expect { server.start }.to raise_error(SystemExit)
            .and output(/directory not found/).to_stderr
        end
      end
    end

    context "when output directory exists" do
      it "starts without error" do
        Dir.chdir(temp_dir) do
          server = described_class.new
          webrick_server = instance_double(WEBrick::HTTPServer)

          allow(server).to receive(:trap)
          allow(webrick_server).to receive(:start)
          allow(WEBrick::HTTPServer).to receive(:new).and_return(webrick_server)

          expect { server.start }.to output(/Preview server starting/).to_stdout
        end
      end
    end
  end
end

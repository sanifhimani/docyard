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
          output: "dist"
          base: "/"
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

    it "defaults base_url to root" do
      Dir.chdir(temp_dir) do
        server = described_class.new

        expect(server.base_url).to eq("/")
      end
    end

    context "with custom base URL" do
      before do
        Dir.chdir(temp_dir) do
          File.write("docyard.yml", <<~YAML)
            build:
              output: "dist"
              base: "/my-docs"
          YAML
        end
      end

      it "reads base_url from config" do
        Dir.chdir(temp_dir) do
          server = described_class.new

          expect(server.base_url).to eq("/my-docs/")
        end
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
          puma_launcher = instance_double(Puma::Launcher)

          allow(puma_launcher).to receive(:run)
          allow(Puma::Launcher).to receive(:new).and_return(puma_launcher)

          output = capture_stdout { server.start }

          expect(output).to include("Docyard v")
        end
      end
    end

    def capture_stdout
      original = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = original
    end
  end
end

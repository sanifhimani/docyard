# frozen_string_literal: true

RSpec.describe Docyard::StaticFileApp do
  let(:temp_dir) { Dir.mktmpdir }

  before do
    FileUtils.mkdir_p(File.join(temp_dir, "guide"))
    File.write(File.join(temp_dir, "index.html"), "<html>Home</html>")
    File.write(File.join(temp_dir, "guide", "index.html"), "<html>Guide</html>")
    File.write(File.join(temp_dir, "404.html"), "<html>Not Found</html>")
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#call" do
    context "with root base path" do
      let(:app) { described_class.new(temp_dir) }

      it "serves index.html for root path", :aggregate_failures do
        status, _headers, body = app.call("PATH_INFO" => "/")

        expect(status).to eq(200)
        expect(body.first).to include("Home")
      end

      it "serves nested files", :aggregate_failures do
        status, _headers, body = app.call("PATH_INFO" => "/guide/")

        expect(status).to eq(200)
        expect(body.first).to include("Guide")
      end

      it "returns 404 for non-existent paths", :aggregate_failures do
        status, _headers, body = app.call("PATH_INFO" => "/missing")

        expect(status).to eq(404)
        expect(body.first).to include("Not Found")
      end
    end

    context "with custom base path" do
      let(:app) { described_class.new(temp_dir, base_path: "/my-docs/") }

      it "serves index.html for base path", :aggregate_failures do
        status, _headers, body = app.call("PATH_INFO" => "/my-docs/")

        expect(status).to eq(200)
        expect(body.first).to include("Home")
      end

      it "serves nested files under base path", :aggregate_failures do
        status, _headers, body = app.call("PATH_INFO" => "/my-docs/guide/")

        expect(status).to eq(200)
        expect(body.first).to include("Guide")
      end

      it "returns 404 for paths outside base path" do
        status, _headers, _body = app.call("PATH_INFO" => "/other/")

        expect(status).to eq(404)
      end

      it "returns 404 for root path when base path is set" do
        status, _headers, _body = app.call("PATH_INFO" => "/")

        expect(status).to eq(404)
      end

      it "serves base path without trailing slash", :aggregate_failures do
        status, _headers, body = app.call("PATH_INFO" => "/my-docs")

        expect(status).to eq(200)
        expect(body.first).to include("Home")
      end
    end
  end
end

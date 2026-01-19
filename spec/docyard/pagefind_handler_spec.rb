# frozen_string_literal: true

require "fileutils"
require "tmpdir"

RSpec.describe Docyard::PagefindHandler do
  let(:temp_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(temp_dir) }

  describe "#serve" do
    context "when pagefind_path is provided and exists" do
      let(:pagefind_dir) { File.join(temp_dir, "pagefind") }
      let(:handler) { described_class.new(pagefind_path: pagefind_dir, config: nil) }

      before { FileUtils.mkdir_p(pagefind_dir) }

      it "serves JavaScript files with correct content type", :aggregate_failures do
        File.write(File.join(pagefind_dir, "pagefind.js"), "console.log('test');")

        status, headers, body = handler.serve("/_docyard/pagefind/pagefind.js")

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("application/javascript; charset=utf-8")
        expect(body.first).to eq("console.log('test');")
      end

      it "serves CSS files with correct content type", :aggregate_failures do
        File.write(File.join(pagefind_dir, "pagefind.css"), "body { color: red; }")

        status, headers, body = handler.serve("/_docyard/pagefind/pagefind.css")

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("text/css; charset=utf-8")
        expect(body.first).to eq("body { color: red; }")
      end

      it "serves JSON files with correct content type", :aggregate_failures do
        File.write(File.join(pagefind_dir, "index.json"), '{"test": true}')

        status, headers, body = handler.serve("/_docyard/pagefind/index.json")

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("application/json; charset=utf-8")
        expect(body.first).to eq('{"test": true}')
      end

      it "serves unknown file types with octet-stream content type", :aggregate_failures do
        File.write(File.join(pagefind_dir, "data.bin"), "binary data")

        status, headers, _body = handler.serve("/_docyard/pagefind/data.bin")

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("application/octet-stream")
      end

      it "includes no-cache headers", :aggregate_failures do
        File.write(File.join(pagefind_dir, "test.js"), "test")

        _status, headers, _body = handler.serve("/_docyard/pagefind/test.js")

        expect(headers["Cache-Control"]).to eq("no-cache, no-store, must-revalidate")
        expect(headers["Pragma"]).to eq("no-cache")
        expect(headers["Expires"]).to eq("0")
      end

      it "returns 404 when file does not exist", :aggregate_failures do
        status, headers, body = handler.serve("/_docyard/pagefind/nonexistent.js")

        expect(status).to eq(404)
        expect(headers["Content-Type"]).to eq("text/plain")
        expect(body.first).to include("Pagefind not found")
      end
    end

    context "when path contains directory traversal" do
      let(:pagefind_dir) { File.join(temp_dir, "pagefind") }
      let(:handler) { described_class.new(pagefind_path: pagefind_dir, config: nil) }

      before { FileUtils.mkdir_p(pagefind_dir) }

      it "returns 404 not found for .. in path" do
        status, _headers, _body = handler.serve("/_docyard/pagefind/../../../etc/passwd")

        expect(status).to eq(404)
      end
    end

    context "when pagefind_path is nil" do
      let(:handler) { described_class.new(pagefind_path: nil, config: nil) }
      let(:dist_pagefind) { File.join(temp_dir, "dist", "_docyard", "pagefind") }

      before do
        FileUtils.mkdir_p(dist_pagefind)
        File.write(File.join(dist_pagefind, "test.js"), "fallback content")
      end

      it "falls back to dist/_docyard/pagefind directory", :aggregate_failures do
        Dir.chdir(temp_dir) do
          status, _headers, body = handler.serve("/_docyard/pagefind/test.js")

          expect(status).to eq(200)
          expect(body.first).to eq("fallback content")
        end
      end
    end

    context "when pagefind_path is nil with custom output_dir in config" do
      let(:build_config) { Struct.new(:output_dir).new("custom_output") }
      let(:config) { Struct.new(:build).new(build_config) }
      let(:handler) { described_class.new(pagefind_path: nil, config: config) }
      let(:custom_pagefind) { File.join(temp_dir, "custom_output", "_docyard", "pagefind") }

      before do
        FileUtils.mkdir_p(custom_pagefind)
        File.write(File.join(custom_pagefind, "custom.js"), "custom content")
      end

      it "uses config output_dir for fallback path", :aggregate_failures do
        Dir.chdir(temp_dir) do
          status, _headers, body = handler.serve("/_docyard/pagefind/custom.js")

          expect(status).to eq(200)
          expect(body.first).to eq("custom content")
        end
      end
    end
  end
end

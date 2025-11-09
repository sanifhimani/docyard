# frozen_string_literal: true

RSpec.describe Docyard::RackApplication do
  let(:docs_path) { File.expand_path("spec/fixtures") }
  let(:file_watcher) { instance_double(Docyard::FileWatcher) }
  let(:app) { described_class.new(docs_path: docs_path, file_watcher: file_watcher) }

  describe "#call" do
    context "with documentation request" do
      it "returns 200 and renders file when found", :aggregate_failures do
        env = { "PATH_INFO" => "/", "QUERY_STRING" => "" }

        status, headers, body = app.call(env)

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(body.first).to include("Welcome to Docyard")
      end

      it "returns 404 when file not found", :aggregate_failures do
        env = { "PATH_INFO" => "/nonexistent", "QUERY_STRING" => "" }

        status, headers, body = app.call(env)

        expect(status).to eq(404)
        expect(headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(body.first).to include("404 - Page Not Found")
      end

      it "uses default site title when no config provided", :aggregate_failures do
        env = { "PATH_INFO" => "/", "QUERY_STRING" => "" }

        _status, _headers, body = app.call(env)

        expect(body.first).to include("<title>")
        expect(body.first).to include("Documentation")
      end

      it "uses config site title when provided" do
        Dir.mktmpdir do |temp_dir|
          File.write(File.join(temp_dir, "docyard.yml"), "site:\n  title: 'Custom Docs'")
          config = Docyard::Config.load(temp_dir)

          app_with_config = described_class.new(docs_path: docs_path, file_watcher: file_watcher, config: config)
          env = { "PATH_INFO" => "/", "QUERY_STRING" => "" }

          _status, _headers, body = app_with_config.call(env)

          expect(body.first).to include("Custom Docs")
        end
      end
    end

    context "with asset request" do
      it "delegates to asset handler" do
        env = { "PATH_INFO" => "/assets/css/main.css", "QUERY_STRING" => "" }

        status, _headers, _body = app.call(env)

        expect(status).to eq(200).or eq(404)
      end
    end

    context "with reload check request" do
      it "returns reload status when changes detected", :aggregate_failures do
        env = { "PATH_INFO" => "/_docyard/reload", "QUERY_STRING" => "since=#{Time.now.to_f - 10}" }
        allow(file_watcher).to receive(:changed_since?).and_return(true)

        status, headers, body = app.call(env)
        json = JSON.parse(body.first)

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("application/json; charset=utf-8")
        expect(json["reload"]).to be(true)
        expect(json["timestamp"]).to be_a(Float)
      end

      it "returns no reload when no changes", :aggregate_failures do
        env = { "PATH_INFO" => "/_docyard/reload", "QUERY_STRING" => "since=#{Time.now.to_f + 10}" }
        allow(file_watcher).to receive(:changed_since?).and_return(false)

        _status, _headers, body = app.call(env)
        json = JSON.parse(body.first)

        expect(json["reload"]).to be(false)
      end

      it "handles errors gracefully", :aggregate_failures do
        env = { "PATH_INFO" => "/_docyard/reload", "QUERY_STRING" => "since=invalid" }
        allow(file_watcher).to receive(:changed_since?).and_raise(StandardError, "test error")
        allow(Docyard.logger).to receive(:error)
        allow(Docyard.logger).to receive(:debug)

        _status, _headers, body = app.call(env)
        json = JSON.parse(body.first)

        expect(json["reload"]).to be(false)
        expect(Docyard.logger).to have_received(:error).with(/Reload check error/)
      end
    end

    context "with errors" do
      it "returns 500 and error page on exception", :aggregate_failures do
        env = { "PATH_INFO" => "/", "QUERY_STRING" => "" }
        router = instance_double(Docyard::Router)
        allow(Docyard::Router).to receive(:new).and_return(router)
        allow(router).to receive(:resolve).and_raise(StandardError, "test error")

        new_app = described_class.new(docs_path: docs_path, file_watcher: file_watcher)
        status, headers, body = new_app.call(env)

        expect(status).to eq(500)
        expect(headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(body.first).to include("500 - Internal Server Error")
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe Docyard::Server do
  let(:server) { described_class.new(docs_path: "spec/fixtures") }

  describe "#initialize" do
    it "uses default port and host", :aggregate_failures do
      server = described_class.new(docs_path: "docs")

      expect(server.port).to eq(4200)
      expect(server.host).to eq("localhost")
      expect(server.docs_path).to eq("docs")
    end

    it "accepts custom port and host", :aggregate_failures do
      server = described_class.new(port: 8080, host: "0.0.0.0", docs_path: "custom")

      expect(server.port).to eq(8080)
      expect(server.host).to eq("0.0.0.0")
      expect(server.docs_path).to eq("custom")
    end
  end

  describe "Rack app" do
    let(:app) { server.send(:app) }

    describe "asset requests" do
      it "delegates to AssetHandler for /assets/ paths", :aggregate_failures do
        env = { "PATH_INFO" => "/assets/css/main.css" }
        status, headers, _body = app.call(env)

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("text/css; charset=utf-8")
      end

      it "returns 404 for nonexistent assets", :aggregate_failures do
        env = { "PATH_INFO" => "/assets/nonexistent.css" }
        status, _headers, body = app.call(env)

        expect(status).to eq(404)
        expect(body).to eq(["404 Not Found"])
      end
    end

    describe "markdown rendering" do
      it "renders markdown files as HTML", :aggregate_failures do
        env = { "PATH_INFO" => "/sample" }
        status, headers, body = app.call(env)

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(body.first).to include("<h1>")
      end

      it "handles index.md for root path", :aggregate_failures do
        env = { "PATH_INFO" => "/" }
        status, headers, body = app.call(env)

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(body.first).to include("Welcome")
      end

      it "handles URLs with .md extension", :aggregate_failures do
        env = { "PATH_INFO" => "/sample.md" }
        status, headers, body = app.call(env)

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(body.first).to include("<h1>")
      end
    end

    describe "404 handling" do
      it "returns 404 for nonexistent pages", :aggregate_failures do
        env = { "PATH_INFO" => "/nonexistent" }
        status, headers, body = app.call(env)

        expect(status).to eq(404)
        expect(headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(body.first).to include("404").and include("Page Not Found")
      end
    end

    describe "error handling" do
      let(:error_app) do
        router = instance_double(Docyard::Router, resolve: nil)
        allow(Docyard::Router).to receive(:new).and_return(router)
        allow(router).to receive(:resolve).and_raise(StandardError, "Test error")
        described_class.new(docs_path: "spec/fixtures").send(:app)
      end

      it "returns 500 on exceptions", :aggregate_failures do
        status, headers, body = error_app.call({ "PATH_INFO" => "/sample" })

        expect(status).to eq(500)
        expect(headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(body.first).to include("500").and include("Test error")
      end
    end
  end

  describe "Rack environment building" do
    let(:webrick_req) do
      instance_double(
        WEBrick::HTTPRequest,
        request_method: "GET",
        path: "/test",
        query_string: query_string,
        host: "localhost",
        port: 4200
      )
    end
    let(:query_string) { "foo=bar" }

    it "builds valid Rack env with request details", :aggregate_failures do
      env = server.send(:build_rack_env, webrick_req)

      expect(env).to include(
        "REQUEST_METHOD" => "GET", "PATH_INFO" => "/test",
        "QUERY_STRING" => "foo=bar", "SERVER_NAME" => "localhost", "SERVER_PORT" => "4200"
      )
    end

    it "includes Rack-specific fields", :aggregate_failures do
      env = server.send(:build_rack_env, webrick_req)

      expect(env["rack.url_scheme"]).to eq("http")
      expect(env["rack.input"]).to be_a(StringIO)
      expect(env["rack.errors"]).to eq($stderr)
    end

    it "handles nil query string" do
      allow(webrick_req).to receive(:query_string).and_return(nil)
      env = server.send(:build_rack_env, webrick_req)

      expect(env["QUERY_STRING"]).to eq("")
    end
  end
end

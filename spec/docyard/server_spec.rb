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

    it "loads configuration", :aggregate_failures do
      server = described_class.new(docs_path: "docs")

      expect(server.config).to be_a(Docyard::Config)
      expect(server.config.site.title).to eq("Documentation")
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

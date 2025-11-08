# frozen_string_literal: true

RSpec.describe Docyard::AssetHandler do
  let(:handler) { described_class.new }

  describe "#serve" do
    context "when serving valid CSS file" do
      it "returns 200 with correct content type", :aggregate_failures do
        status, headers, body = handler.serve("/assets/css/main.css")

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("text/css; charset=utf-8")
        expect(body.first).to include("@import")
      end
    end

    context "when serving valid JavaScript file" do
      it "returns 200 with correct content type", :aggregate_failures do
        status, headers, _body = handler.serve("/assets/js/theme.js")

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("application/javascript; charset=utf-8")
      end
    end

    context "when file does not exist" do
      it "returns 404", :aggregate_failures do
        status, _headers, body = handler.serve("/assets/nonexistent.css")

        expect(status).to eq(404)
        expect(body).to eq(["404 Not Found"])
      end
    end

    context "when path contains directory traversal" do
      it "returns 403 forbidden", :aggregate_failures do
        status, _headers, body = handler.serve("/assets/../../../etc/passwd")

        expect(status).to eq(403)
        expect(body).to eq(["403 Forbidden"])
      end
    end

    context "when path contains .." do
      it "returns 403 forbidden" do
        status, = handler.serve("/assets/css/../../secret.txt")

        expect(status).to eq(403)
      end
    end
  end
end

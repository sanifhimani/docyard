# frozen_string_literal: true

RSpec.describe Docyard::AssetHandler do
  let(:handler) { described_class.new }

  describe "#serve_docyard_assets" do
    context "when serving valid CSS file" do
      it "returns 200 with correct content type", :aggregate_failures do
        status, headers, body = handler.serve_docyard_assets("/_docyard/css/main.css")

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("text/css; charset=utf-8")
        expect(body.first).to include("@import")
      end
    end

    context "when serving valid JavaScript file" do
      it "returns 200 with correct content type", :aggregate_failures do
        status, headers, _body = handler.serve_docyard_assets("/_docyard/js/theme.js")

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("application/javascript; charset=utf-8")
      end
    end

    context "when file does not exist" do
      it "returns 404", :aggregate_failures do
        status, _headers, body = handler.serve_docyard_assets("/_docyard/nonexistent.css")

        expect(status).to eq(404)
        expect(body).to eq(["404 Not Found"])
      end
    end

    context "when path contains directory traversal" do
      it "returns 403 forbidden", :aggregate_failures do
        status, _headers, body = handler.serve_docyard_assets("/_docyard/../../../etc/passwd")

        expect(status).to eq(403)
        expect(body).to eq(["403 Forbidden"])
      end
    end

    context "when path contains .." do
      it "returns 403 forbidden" do
        status, = handler.serve_docyard_assets("/_docyard/css/../../secret.txt")

        expect(status).to eq(403)
      end
    end

    context "when serving components.css (concatenated)" do
      it "returns 200 with concatenated CSS from all component files", :aggregate_failures do
        status, headers, body = handler.serve_docyard_assets("/_docyard/css/components.css")
        content = body.first

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("text/css; charset=utf-8")

        expect(content).to include(".docyard-callout")
        expect(content).to include(".docyard-icon")
        expect(content).to include(".sidebar nav")
        expect(content).to include(".theme-toggle")
      end

      it "concatenates files in alphabetical order", :aggregate_failures do
        _status, _headers, body = handler.serve_docyard_assets("/_docyard/css/components.css")
        content = body.first

        callout_pos = content.index(".docyard-callout")
        icon_pos = content.index(".docyard-icon")
        navigation_pos = content.index(".sidebar nav")
        theme_pos = content.index(".theme-toggle")

        expect(callout_pos).to be < icon_pos
        expect(icon_pos).to be < navigation_pos
        expect(navigation_pos).to be < theme_pos
      end

      it "separates component files with blank lines" do
        _status, _headers, body = handler.serve_docyard_assets("/_docyard/css/components.css")
        content = body.first

        expect(content).to match(/\}\n\n\./)
      end
    end

    context "when serving components.js (concatenated)" do
      it "returns 200 with concatenated JS from all component files", :aggregate_failures do
        status, headers, body = handler.serve_docyard_assets("/_docyard/js/components.js")
        content = body.first

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("application/javascript; charset=utf-8")

        expect(content).to include("TabsManager")
        expect(content).to include("class TabsManager")
        expect(content).to include("initializeTabs")
      end

      it "concatenates files properly", :aggregate_failures do
        _status, _headers, body = handler.serve_docyard_assets("/_docyard/js/components.js")
        content = body.first

        expect(content).to include("constructor(container)")
        expect(content).to include("activateTab")
        expect(content).to include("handleKeyDown")
        expect(content).to include("localStorage")
      end

      it "separates component files with blank lines", :aggregate_failures do
        _status, _headers, body = handler.serve_docyard_assets("/_docyard/js/components.js")
        content = body.first

        expect(content).to be_a(String)
        expect(content.length).to be > 0
      end

      it "includes auto-initialization code", :aggregate_failures do
        _status, _headers, body = handler.serve_docyard_assets("/_docyard/js/components.js")
        content = body.first

        expect(content).to include("DOMContentLoaded", "querySelectorAll", ".docyard-tabs")
      end
    end
  end

  describe "#serve_public_file" do
    context "when serving user files from docs/public" do
      it "serves user file when it exists in docs/public", :aggregate_failures do
        public_dir = File.join(Dir.pwd, "docs", "public")
        FileUtils.mkdir_p(public_dir)
        user_logo = File.join(public_dir, "test-user-logo.svg")
        File.write(user_logo, "<svg>User Logo</svg>")

        status, _headers, body = handler.serve_public_file("/test-user-logo.svg")

        expect(status).to eq(200)
        expect(body.first).to eq("<svg>User Logo</svg>")
      ensure
        FileUtils.rm_f(user_logo) if user_logo && File.exist?(user_logo)
      end

      it "returns nil when file not found" do
        result = handler.serve_public_file("/nonexistent-file.svg")

        expect(result).to be_nil
      end

      it "returns nil for directory traversal attempts" do
        result = handler.serve_public_file("/../../../etc/passwd")

        expect(result).to be_nil
      end
    end
  end
end

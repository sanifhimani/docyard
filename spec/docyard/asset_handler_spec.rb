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

    context "when serving components.css (concatenated)" do
      it "returns 200 with concatenated CSS from all component files", :aggregate_failures do
        status, headers, body = handler.serve("/assets/css/components.css")
        content = body.first

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("text/css; charset=utf-8")

        expect(content).to include(".docyard-callout")
        expect(content).to include(".docyard-icon")
        expect(content).to include(".sidebar nav")
        expect(content).to include(".theme-toggle")
      end

      it "concatenates files in alphabetical order", :aggregate_failures do
        _status, _headers, body = handler.serve("/assets/css/components.css")
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
        _status, _headers, body = handler.serve("/assets/css/components.css")
        content = body.first

        expect(content).to match(/\}\n\n\./)
      end
    end

    context "when serving components.js (concatenated)" do
      it "returns 200 with concatenated JS from all component files", :aggregate_failures do
        status, headers, body = handler.serve("/assets/js/components.js")
        content = body.first

        expect(status).to eq(200)
        expect(headers["Content-Type"]).to eq("application/javascript; charset=utf-8")

        expect(content).to include("TabsManager")
        expect(content).to include("class TabsManager")
        expect(content).to include("initializeTabs")
      end

      it "concatenates files properly", :aggregate_failures do
        _status, _headers, body = handler.serve("/assets/js/components.js")
        content = body.first

        expect(content).to include("constructor(container)")
        expect(content).to include("activateTab")
        expect(content).to include("handleKeyDown")
        expect(content).to include("localStorage")
      end

      it "separates component files with blank lines", :aggregate_failures do
        _status, _headers, body = handler.serve("/assets/js/components.js")
        content = body.first

        expect(content).to be_a(String)
        expect(content.length).to be > 0
      end

      it "includes auto-initialization code", :aggregate_failures do
        _status, _headers, body = handler.serve("/assets/js/components.js")
        content = body.first

        expect(content).to include("DOMContentLoaded", "querySelectorAll", ".docyard-tabs")
      end
    end

    context "when serving user assets from docs/assets" do
      it "serves user asset when it exists in docs/assets", :aggregate_failures do
        docs_assets_dir = File.join(Dir.pwd, "docs", "assets")
        FileUtils.mkdir_p(docs_assets_dir)
        user_logo = File.join(docs_assets_dir, "test-user-logo.svg")
        File.write(user_logo, "<svg>User Logo</svg>")

        status, _headers, body = handler.serve("/assets/test-user-logo.svg")

        expect(status).to eq(200)
        expect(body.first).to eq("<svg>User Logo</svg>")
      ensure
        FileUtils.rm_f(user_logo) if user_logo && File.exist?(user_logo)
      end

      it "falls back to default assets when user asset not found", :aggregate_failures do
        status, _headers, body = handler.serve("/assets/css/main.css")

        expect(status).to eq(200)
        expect(body.first).to include("@import")
      end
    end
  end
end

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

        # Verify all component CSS files are included
        expect(content).to include("Callouts/Admonitions") # from callout.css
        expect(content).to include("Icon System") # from icon.css
        expect(content).to include("Navigation Components") # from navigation.css
        expect(content).to include("Theme Toggle") # from theme-toggle.css
      end

      it "concatenates files in alphabetical order", :aggregate_failures do
        _status, _headers, body = handler.serve("/assets/css/components.css")
        content = body.first

        # Check that files appear in alphabetical order (callout, icon, navigation, theme-toggle)
        callout_pos = content.index("Callouts/Admonitions")
        icon_pos = content.index("Icon System")
        navigation_pos = content.index("Navigation Components")
        theme_pos = content.index("Theme Toggle")

        expect(callout_pos).to be < icon_pos
        expect(icon_pos).to be < navigation_pos
        expect(navigation_pos).to be < theme_pos
      end

      it "separates component files with blank lines" do
        _status, _headers, body = handler.serve("/assets/css/components.css")
        content = body.first

        # Files should be separated by \n\n (closing brace, blank line, next file's comment)
        expect(content).to match(%r{\}\n\n/\*})
      end
    end
  end
end

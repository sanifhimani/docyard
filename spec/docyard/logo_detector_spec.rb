# frozen_string_literal: true

RSpec.describe Docyard::LogoDetector do
  include_context "with temp directory"

  around do |example|
    Dir.chdir(temp_dir) { example.run }
  end

  describe ".auto_detect_logo" do
    context "when logo.svg exists in docs/public" do
      before { create_file("docs/public/logo.svg", "<svg></svg>") }

      it "returns logo.svg" do
        expect(described_class.auto_detect_logo).to eq("logo.svg")
      end
    end

    context "when logo.png exists but not svg" do
      before { create_file("docs/public/logo.png", "png data") }

      it "returns logo.png" do
        expect(described_class.auto_detect_logo).to eq("logo.png")
      end
    end

    context "when both svg and png exist" do
      before do
        create_file("docs/public/logo.svg", "<svg></svg>")
        create_file("docs/public/logo.png", "png data")
      end

      it "prefers svg over png" do
        expect(described_class.auto_detect_logo).to eq("logo.svg")
      end
    end

    context "when no logo exists" do
      it "returns nil" do
        expect(described_class.auto_detect_logo).to be_nil
      end
    end
  end

  describe ".auto_detect_favicon" do
    context "when favicon.ico exists in docs/public" do
      before { create_file("docs/public/favicon.ico", "ico data") }

      it "returns favicon.ico" do
        expect(described_class.auto_detect_favicon).to eq("favicon.ico")
      end
    end

    context "when favicon.svg exists but not ico" do
      before { create_file("docs/public/favicon.svg", "<svg></svg>") }

      it "returns favicon.svg" do
        expect(described_class.auto_detect_favicon).to eq("favicon.svg")
      end
    end

    context "when multiple favicon formats exist" do
      before do
        create_file("docs/public/favicon.ico", "ico data")
        create_file("docs/public/favicon.svg", "<svg></svg>")
        create_file("docs/public/favicon.png", "png data")
      end

      it "prefers ico over svg and png" do
        expect(described_class.auto_detect_favicon).to eq("favicon.ico")
      end
    end

    context "when no favicon exists" do
      it "returns nil" do
        expect(described_class.auto_detect_favicon).to be_nil
      end
    end
  end

  describe ".detect_dark_logo" do
    context "when logo is nil" do
      it "returns nil" do
        expect(described_class.detect_dark_logo(nil)).to be_nil
      end
    end

    context "with absolute path and dark variant exists" do
      let(:logo_path) { File.join(temp_dir, "logo.svg") }

      before do
        create_file("logo.svg", "<svg></svg>")
        create_file("logo-dark.svg", "<svg>dark</svg>")
      end

      it "returns the dark variant path" do
        dark_path = File.join(temp_dir, "logo-dark.svg")
        expect(described_class.detect_dark_logo(logo_path)).to eq(dark_path)
      end
    end

    context "with absolute path and no dark variant" do
      let(:logo_path) { File.join(temp_dir, "logo.svg") }

      before { create_file("logo.svg", "<svg></svg>") }

      it "returns the original logo path" do
        expect(described_class.detect_dark_logo(logo_path)).to eq(logo_path)
      end
    end

    context "with relative path and dark variant exists" do
      before do
        create_file("docs/public/logo.svg", "<svg></svg>")
        create_file("docs/public/logo-dark.svg", "<svg>dark</svg>")
      end

      it "returns the dark variant filename" do
        expect(described_class.detect_dark_logo("logo.svg")).to eq("logo-dark.svg")
      end
    end

    context "with relative path and no dark variant" do
      before { create_file("docs/public/logo.svg", "<svg></svg>") }

      it "returns the original logo filename" do
        expect(described_class.detect_dark_logo("logo.svg")).to eq("logo.svg")
      end
    end
  end
end

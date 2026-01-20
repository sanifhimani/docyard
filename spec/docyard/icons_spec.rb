# frozen_string_literal: true

RSpec.describe Docyard::Icons do
  describe ".render_file_extension" do
    context "with known file extension" do
      it "renders Devicon for Ruby files", :aggregate_failures do
        result = described_class.render_file_extension("rb")

        expect(result).to include("devicon-ruby-plain")
        expect(result).to include('aria-hidden="true"')
        expect(result).to include("<i")
      end

      it "renders Devicon for JavaScript files", :aggregate_failures do
        result = described_class.render_file_extension("js")

        expect(result).to include("devicon-javascript-plain")
        expect(result).to include("<i")
      end

      it "renders Devicon for TypeScript files" do
        result = described_class.render_file_extension("ts")

        expect(result).to include("devicon-typescript-plain")
      end

      it "renders Devicon for Python files" do
        result = described_class.render_file_extension("py")

        expect(result).to include("devicon-python-plain")
      end
    end

    context "with unknown file extension" do
      it "returns empty string", :aggregate_failures do
        result = described_class.render_file_extension("xyz")

        expect(result).to eq("")
      end
    end
  end

  describe ".render_for_language" do
    context "with known language" do
      it "renders Devicon for bash" do
        result = described_class.render_for_language("bash")

        expect(result).to include("devicon-bash-plain")
      end

      it "renders Devicon for javascript" do
        result = described_class.render_for_language("javascript")

        expect(result).to include("devicon-javascript-plain")
      end

      it "renders Devicon for ruby" do
        result = described_class.render_for_language("ruby")

        expect(result).to include("devicon-ruby-plain")
      end
    end

    context "with unknown language" do
      it "returns empty string" do
        result = described_class.render_for_language("unknownlang")

        expect(result).to eq("")
      end
    end
  end

  describe ".highlight_language" do
    it "maps npm to bash" do
      expect(described_class.highlight_language("npm")).to eq("bash")
    end

    it "maps yarn to bash" do
      expect(described_class.highlight_language("yarn")).to eq("bash")
    end

    it "maps pnpm to bash" do
      expect(described_class.highlight_language("pnpm")).to eq("bash")
    end

    it "maps bun to bash" do
      expect(described_class.highlight_language("bun")).to eq("bash")
    end

    it "maps pip to bash" do
      expect(described_class.highlight_language("pip")).to eq("bash")
    end

    it "returns javascript unchanged" do
      expect(described_class.highlight_language("javascript")).to eq("javascript")
    end

    it "returns ruby unchanged" do
      expect(described_class.highlight_language("ruby")).to eq("ruby")
    end

    it "returns bash unchanged" do
      expect(described_class.highlight_language("bash")).to eq("bash")
    end

    it "is case insensitive for NPM" do
      expect(described_class.highlight_language("NPM")).to eq("bash")
    end

    it "is case insensitive for Yarn" do
      expect(described_class.highlight_language("Yarn")).to eq("bash")
    end
  end
end

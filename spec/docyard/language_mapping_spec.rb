# frozen_string_literal: true

require "spec_helper"

RSpec.describe Docyard::LanguageMapping do
  describe ".extension_for" do
    context "with valid language identifiers" do
      it "maps javascript to js" do
        expect(described_class.extension_for("javascript")).to eq("js")
      end

      it "maps js to js" do
        expect(described_class.extension_for("js")).to eq("js")
      end

      it "maps typescript to ts" do
        expect(described_class.extension_for("typescript")).to eq("ts")
      end

      it "maps ts to ts" do
        expect(described_class.extension_for("ts")).to eq("ts")
      end

      it "maps python to py" do
        expect(described_class.extension_for("python")).to eq("py")
      end

      it "maps py to py" do
        expect(described_class.extension_for("py")).to eq("py")
      end

      it "maps ruby to rb" do
        expect(described_class.extension_for("ruby")).to eq("rb")
      end

      it "maps rb to rb" do
        expect(described_class.extension_for("rb")).to eq("rb")
      end

      it "maps golang to go" do
        expect(described_class.extension_for("golang")).to eq("go")
      end

      it "maps go to go" do
        expect(described_class.extension_for("go")).to eq("go")
      end

      it "maps rust to rs" do
        expect(described_class.extension_for("rust")).to eq("rs")
      end

      it "maps rs to rs" do
        expect(described_class.extension_for("rs")).to eq("rs")
      end
    end

    context "with web languages" do
      it "maps html to html" do
        expect(described_class.extension_for("html")).to eq("html")
      end

      it "maps htm to html" do
        expect(described_class.extension_for("htm")).to eq("html")
      end

      it "maps html5 to html" do
        expect(described_class.extension_for("html5")).to eq("html")
      end

      it "maps css to css" do
        expect(described_class.extension_for("css")).to eq("css")
      end

      it "maps jsx to jsx" do
        expect(described_class.extension_for("jsx")).to eq("jsx")
      end

      it "maps tsx to tsx" do
        expect(described_class.extension_for("tsx")).to eq("tsx")
      end

      it "maps vue to vue" do
        expect(described_class.extension_for("vue")).to eq("vue")
      end

      it "maps svelte to svelte" do
        expect(described_class.extension_for("svelte")).to eq("svelte")
      end
    end

    context "with data languages" do
      it "maps json to json" do
        expect(described_class.extension_for("json")).to eq("json")
      end

      it "maps yaml to yaml" do
        expect(described_class.extension_for("yaml")).to eq("yaml")
      end

      it "maps yml to yaml" do
        expect(described_class.extension_for("yml")).to eq("yaml")
      end

      it "maps toml to toml" do
        expect(described_class.extension_for("toml")).to eq("toml")
      end
    end

    context "with database languages" do
      it "maps sql to sql" do
        expect(described_class.extension_for("sql")).to eq("sql")
      end

      it "maps mysql to mysql" do
        expect(described_class.extension_for("mysql")).to eq("mysql")
      end

      it "maps postgresql to pgsql" do
        expect(described_class.extension_for("postgresql")).to eq("pgsql")
      end

      it "maps postgres to pgsql" do
        expect(described_class.extension_for("postgres")).to eq("pgsql")
      end

      it "maps pgsql to pgsql" do
        expect(described_class.extension_for("pgsql")).to eq("pgsql")
      end

      it "maps graphql to graphql" do
        expect(described_class.extension_for("graphql")).to eq("graphql")
      end

      it "maps gql to graphql" do
        expect(described_class.extension_for("gql")).to eq("graphql")
      end
    end

    context "with other languages" do
      it "maps php to php" do
        expect(described_class.extension_for("php")).to eq("php")
      end

      it "maps proto to proto" do
        expect(described_class.extension_for("proto")).to eq("proto")
      end

      it "maps protobuf to proto" do
        expect(described_class.extension_for("protobuf")).to eq("proto")
      end
    end

    context "with case insensitivity" do
      it "handles uppercase language names" do
        expect(described_class.extension_for("JAVASCRIPT")).to eq("js")
      end

      it "handles mixed case language names" do
        expect(described_class.extension_for("JavaScript")).to eq("js")
      end

      it "handles all caps language names" do
        expect(described_class.extension_for("HTML")).to eq("html")
      end
    end

    context "with symbols" do
      it "accepts symbols as input" do
        expect(described_class.extension_for(:javascript)).to eq("js")
      end

      it "handles symbols case insensitively" do
        expect(described_class.extension_for(:JavaScript)).to eq("js")
      end
    end

    context "with unknown languages" do
      it "returns nil for unknown language" do
        expect(described_class.extension_for("unknown")).to be_nil
      end

      it "returns nil for empty string" do
        expect(described_class.extension_for("")).to be_nil
      end

      it "returns nil for whitespace" do
        expect(described_class.extension_for("   ")).to be_nil
      end
    end
  end

  describe ".terminal_language?" do
    context "with terminal languages" do
      it "returns true for bash" do
        expect(described_class.terminal_language?("bash")).to be true
      end

      it "returns true for sh" do
        expect(described_class.terminal_language?("sh")).to be true
      end

      it "returns true for shell" do
        expect(described_class.terminal_language?("shell")).to be true
      end

      it "returns true for powershell" do
        expect(described_class.terminal_language?("powershell")).to be true
      end
    end

    context "with case insensitivity" do
      it "handles uppercase terminal languages" do
        expect(described_class.terminal_language?("BASH")).to be true
      end

      it "handles mixed case terminal languages" do
        expect(described_class.terminal_language?("Bash")).to be true
      end

      it "handles powershell in various cases", :aggregate_failures do
        expect(described_class.terminal_language?("PowerShell")).to be true
        expect(described_class.terminal_language?("POWERSHELL")).to be true
      end
    end

    context "with symbols" do
      it "accepts symbols as input" do
        expect(described_class.terminal_language?(:bash)).to be true
      end

      it "handles symbols case insensitively" do
        expect(described_class.terminal_language?(:BASH)).to be true
      end
    end

    context "with non-terminal languages" do
      it "returns false for javascript" do
        expect(described_class.terminal_language?("javascript")).to be false
      end

      it "returns false for python" do
        expect(described_class.terminal_language?("python")).to be false
      end

      it "returns false for ruby" do
        expect(described_class.terminal_language?("ruby")).to be false
      end

      it "returns false for unknown language" do
        expect(described_class.terminal_language?("unknown")).to be false
      end

      it "returns false for empty string" do
        expect(described_class.terminal_language?("")).to be false
      end

      it "returns false for whitespace" do
        expect(described_class.terminal_language?("   ")).to be false
      end
    end
  end

  describe "TERMINAL_LANGUAGES constant" do
    it "is frozen" do
      expect(described_class::TERMINAL_LANGUAGES).to be_frozen
    end

    it "contains expected terminal languages" do
      expect(described_class::TERMINAL_LANGUAGES).to include("bash", "sh", "shell", "powershell")
    end

    it "has the correct count" do
      expect(described_class::TERMINAL_LANGUAGES.length).to eq(4)
    end
  end

  describe "LANGUAGE_TO_EXTENSION constant" do
    it "is frozen" do
      expect(described_class::LANGUAGE_TO_EXTENSION).to be_frozen
    end

    it "contains all expected language mappings" do
      expected_keys = %w[
        js javascript ts typescript jsx tsx py python rb ruby
        go golang rs rust php html htm html5 css json yaml yml
        toml sql mysql postgresql postgres pgsql graphql gql
        vue svelte proto protobuf
      ]

      expect(described_class::LANGUAGE_TO_EXTENSION.keys).to include(*expected_keys)
    end

    it "has no duplicate values for same extension", :aggregate_failures do
      expect(described_class::LANGUAGE_TO_EXTENSION["javascript"]).to eq(
        described_class::LANGUAGE_TO_EXTENSION["js"]
      )
      expect(described_class::LANGUAGE_TO_EXTENSION["typescript"]).to eq(
        described_class::LANGUAGE_TO_EXTENSION["ts"]
      )
      expect(described_class::LANGUAGE_TO_EXTENSION["yaml"]).to eq(
        described_class::LANGUAGE_TO_EXTENSION["yml"]
      )
    end
  end
end

# frozen_string_literal: true

RSpec.describe Docyard::CLI do
  describe ".exit_on_failure?" do
    it "returns true" do
      expect(described_class.exit_on_failure?).to be true
    end
  end

  describe "command definitions" do
    it "defines version command" do
      expect(described_class.commands).to have_key("version")
    end

    it "defines init command" do
      expect(described_class.commands).to have_key("init")
    end

    it "defines build command" do
      expect(described_class.commands).to have_key("build")
    end

    it "defines preview command" do
      expect(described_class.commands).to have_key("preview")
    end

    it "defines serve command" do
      expect(described_class.commands).to have_key("serve")
    end
  end

  describe "build command options" do
    let(:command) { described_class.commands["build"] }
    let(:options) { command.options }

    it "has clean option defaulting to true" do
      expect(options[:clean].default).to be true
    end

    it "has verbose option defaulting to false" do
      expect(options[:verbose].default).to be false
    end
  end

  describe "preview command options" do
    let(:command) { described_class.commands["preview"] }
    let(:options) { command.options }

    it "has port option defaulting to 4000" do
      expect(options[:port].default).to eq(4000)
    end
  end

  describe "serve command options" do
    let(:command) { described_class.commands["serve"] }
    let(:options) { command.options }

    it "has port option defaulting to 4200" do
      expect(options[:port].default).to eq(4200)
    end

    it "has host option defaulting to localhost" do
      expect(options[:host].default).to eq("localhost")
    end

    it "has search option defaulting to false" do
      expect(options[:search].default).to be false
    end
  end

  describe "#version" do
    it "outputs the version" do
      cli = described_class.new

      expect { cli.version }.to output(/docyard #{Docyard::VERSION}/).to_stdout
    end
  end
end

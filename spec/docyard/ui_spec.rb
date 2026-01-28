# frozen_string_literal: true

RSpec.describe Docyard::UI do
  after { described_class.reset! }

  describe ".enabled?" do
    it "returns true when explicitly enabled" do
      described_class.enabled = true
      expect(described_class.enabled?).to be true
    end

    it "returns false when explicitly disabled" do
      described_class.enabled = false
      expect(described_class.enabled?).to be false
    end
  end

  describe ".reset!" do
    it "clears the enabled state" do
      described_class.enabled = true
      described_class.reset!
      # After reset, it re-evaluates; in test env stdout is not a TTY
      expect(described_class.enabled?).to be false
    end
  end

  describe "color methods when enabled" do
    before { described_class.enabled = true }

    it "wraps text in red" do
      expect(described_class.red("hello")).to eq("\e[31mhello\e[0m")
    end

    it "wraps text in green" do
      expect(described_class.green("hello")).to eq("\e[32mhello\e[0m")
    end

    it "wraps text in yellow" do
      expect(described_class.yellow("hello")).to eq("\e[33mhello\e[0m")
    end

    it "wraps text in cyan" do
      expect(described_class.cyan("hello")).to eq("\e[36mhello\e[0m")
    end

    it "wraps text in bold" do
      expect(described_class.bold("hello")).to eq("\e[1mhello\e[0m")
    end

    it "wraps text in dim" do
      expect(described_class.dim("hello")).to eq("\e[2mhello\e[0m")
    end

    it "wraps text with success style (green + bold)" do
      expect(described_class.success("hello")).to eq("\e[32m\e[1mhello\e[0m")
    end

    it "wraps text with error style (red + bold)" do
      expect(described_class.error("hello")).to eq("\e[31m\e[1mhello\e[0m")
    end

    it "wraps text with warning style (yellow)" do
      expect(described_class.warning("hello")).to eq("\e[33mhello\e[0m")
    end
  end

  describe "color methods when disabled" do
    before { described_class.enabled = false }

    it "returns plain text for red" do
      expect(described_class.red("hello")).to eq("hello")
    end

    it "returns plain text for green" do
      expect(described_class.green("hello")).to eq("hello")
    end

    it "returns plain text for yellow" do
      expect(described_class.yellow("hello")).to eq("hello")
    end

    it "returns plain text for cyan" do
      expect(described_class.cyan("hello")).to eq("hello")
    end

    it "returns plain text for bold" do
      expect(described_class.bold("hello")).to eq("hello")
    end

    it "returns plain text for dim" do
      expect(described_class.dim("hello")).to eq("hello")
    end

    it "returns plain text for success" do
      expect(described_class.success("hello")).to eq("hello")
    end

    it "returns plain text for error" do
      expect(described_class.error("hello")).to eq("hello")
    end

    it "returns plain text for warning" do
      expect(described_class.warning("hello")).to eq("hello")
    end
  end

  describe ".determine_color_support" do
    it "returns false when NO_COLOR env var is set" do
      described_class.reset!
      allow(ENV).to receive(:key?).with("NO_COLOR").and_return(true)
      expect(described_class.enabled?).to be false
    end

    it "returns false when stdout is not a TTY" do
      described_class.reset!
      allow(ENV).to receive(:key?).with("NO_COLOR").and_return(false)
      allow($stdout).to receive(:tty?).and_return(false)
      expect(described_class.enabled?).to be false
    end

    it "returns true when NO_COLOR is not set and stdout is a TTY" do
      described_class.reset!
      allow(ENV).to receive(:key?).with("NO_COLOR").and_return(false)
      allow($stdout).to receive(:tty?).and_return(true)
      expect(described_class.enabled?).to be true
    end
  end
end

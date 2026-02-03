# frozen_string_literal: true

require "open3"

RSpec.describe Docyard::Search::PagefindBinary do
  after do
    described_class.reset!
  end

  describe ".executable" do
    it "returns a path that exists or npx" do
      path = described_class.executable
      skip "No binary or npx available" unless path

      expect(File.exist?(path) || path == "npx").to be true
    end

    it "returns executable that reports version", :aggregate_failures do
      path = described_class.executable
      skip "No binary or npx available" unless path

      args = path == "npx" ? ["npx", "pagefind", "--version"] : [path, "--version"]
      stdout, _, status = Open3.capture3(*args)

      expect(status.success?).to be true
      expect(stdout).to match(/pagefind \d+\.\d+/i)
    end

    it "caches the executable path" do
      first_call = described_class.executable
      second_call = described_class.executable

      expect(first_call).to eq(second_call)
    end
  end

  describe ".reset!" do
    it "clears the cached executable" do
      described_class.executable
      described_class.reset!

      # After reset, it should resolve again
      expect(described_class.executable).not_to be_nil
    end
  end

  describe "platform detection" do
    it "returns valid platform string for current system" do
      platform = described_class.send(:detect_platform)

      expect(platform).to match(/darwin|linux|windows/)
    end

    it "handles darwin arm64" do
      stub_platform("darwin21.0", "arm64")

      platform = described_class.send(:detect_platform)

      expect(platform).to eq("aarch64-apple-darwin")
    end

    it "handles darwin x86_64" do
      stub_platform("darwin21.0", "x86_64")

      platform = described_class.send(:detect_platform)

      expect(platform).to eq("x86_64-apple-darwin")
    end

    it "handles linux x86_64" do
      stub_platform("linux-gnu", "x86_64")

      platform = described_class.send(:detect_platform)

      expect(platform).to eq("x86_64-unknown-linux-musl")
    end

    it "handles linux aarch64" do
      stub_platform("linux-gnu", "aarch64")

      platform = described_class.send(:detect_platform)

      expect(platform).to eq("aarch64-unknown-linux-musl")
    end

    it "handles windows" do
      stub_platform("mingw32", "x64")

      platform = described_class.send(:detect_platform)

      expect(platform).to eq("x86_64-pc-windows-msvc")
    end

    it "returns nil for unsupported platform" do
      stub_platform("unknown", "unknown")

      platform = described_class.send(:detect_platform)

      expect(platform).to be_nil
    end
  end

  describe "binary path" do
    it "constructs correct path for unix platforms", :aggregate_failures do
      stub_platform("darwin21.0", "arm64")

      path = described_class.send(:binary_path)

      expect(path).to include("pagefind-#{described_class::VERSION}-aarch64-apple-darwin")
      expect(path).to end_with("/pagefind")
    end

    it "constructs correct path for windows", :aggregate_failures do
      stub_platform("mingw32", "x64")

      path = described_class.send(:binary_path)

      expect(path).to include("pagefind-#{described_class::VERSION}-x86_64-pc-windows-msvc")
      expect(path).to end_with("/pagefind.exe")
    end
  end

  describe "download safety" do
    it "has a reasonable download timeout" do
      expect(described_class::DOWNLOAD_TIMEOUT).to be_between(10, 60)
    end

    it "limits redirect depth" do
      expect(described_class::MAX_REDIRECTS).to be_between(3, 10)
    end

    it "returns nil when max redirects exceeded" do
      result = described_class.send(:download_file, "https://example.com", described_class::MAX_REDIRECTS)

      expect(result).to be_nil
    end
  end

  def stub_platform(os, cpu)
    allow(RbConfig::CONFIG).to receive(:[]).and_call_original
    allow(RbConfig::CONFIG).to receive(:[]).with("host_os").and_return(os)
    allow(RbConfig::CONFIG).to receive(:[]).with("host_cpu").and_return(cpu)
  end
end

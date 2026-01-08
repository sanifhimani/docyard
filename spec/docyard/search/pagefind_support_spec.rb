# frozen_string_literal: true

RSpec.describe Docyard::Search::PagefindSupport do
  let(:test_class) do
    Class.new do
      include Docyard::Search::PagefindSupport

      attr_accessor :config
    end
  end

  let(:instance) { test_class.new }
  let(:search_config) { Struct.new(:enabled, :exclude).new(true, []) }
  let(:config) { Struct.new(:search).new(search_config) }

  before { instance.config = config }

  describe "#search_enabled?" do
    it "returns true when search is enabled" do
      expect(instance.search_enabled?).to be true
    end

    it "returns true when enabled is nil (default)" do
      search_config.enabled = nil

      expect(instance.search_enabled?).to be true
    end

    it "returns false when search is explicitly disabled" do
      search_config.enabled = false

      expect(instance.search_enabled?).to be false
    end
  end

  describe "#pagefind_available?" do
    it "returns true when pagefind command succeeds" do
      allow(Open3).to receive(:capture3)
        .with("npx", "pagefind", "--version")
        .and_return(["1.0.0", "", instance_double(Process::Status, success?: true)])

      expect(instance.pagefind_available?).to be true
    end

    it "returns false when pagefind command fails" do
      allow(Open3).to receive(:capture3)
        .with("npx", "pagefind", "--version")
        .and_return(["", "error", instance_double(Process::Status, success?: false)])

      expect(instance.pagefind_available?).to be false
    end

    it "returns false when npx is not found" do
      allow(Open3).to receive(:capture3)
        .with("npx", "pagefind", "--version")
        .and_raise(Errno::ENOENT)

      expect(instance.pagefind_available?).to be false
    end
  end

  describe "#build_pagefind_args" do
    it "returns base args with site directory" do
      result = instance.build_pagefind_args("/path/to/site")

      expect(result).to eq(["pagefind", "--site", "/path/to/site"])
    end

    it "includes exclusion selectors when configured", :aggregate_failures do
      search_config.exclude = [".sidebar", ".nav"]

      result = instance.build_pagefind_args("/path/to/site")

      expect(result).to include("--exclude-selectors", ".sidebar")
      expect(result).to include("--exclude-selectors", ".nav")
    end

    it "handles nil exclude config" do
      search_config.exclude = nil

      result = instance.build_pagefind_args("/path/to/site")

      expect(result).to eq(["pagefind", "--site", "/path/to/site"])
    end
  end
end

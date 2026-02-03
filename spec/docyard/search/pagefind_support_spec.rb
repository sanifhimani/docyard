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

  after { Docyard::Search::PagefindBinary.reset! }

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
    it "returns true when PagefindBinary.executable returns a path" do
      allow(Docyard::Search::PagefindBinary).to receive(:executable).and_return("/path/to/pagefind")

      expect(instance.pagefind_available?).to be true
    end

    it "returns true when PagefindBinary.executable returns npx" do
      allow(Docyard::Search::PagefindBinary).to receive(:executable).and_return("npx")

      expect(instance.pagefind_available?).to be true
    end

    it "returns false when PagefindBinary.executable returns nil" do
      allow(Docyard::Search::PagefindBinary).to receive(:executable).and_return(nil)

      expect(instance.pagefind_available?).to be false
    end
  end

  describe "#pagefind_command" do
    it "returns array with binary path when executable is a path" do
      allow(Docyard::Search::PagefindBinary).to receive(:executable).and_return("/path/to/pagefind")

      expect(instance.pagefind_command).to eq(["/path/to/pagefind"])
    end

    it "returns array with npx and pagefind when executable is npx" do
      allow(Docyard::Search::PagefindBinary).to receive(:executable).and_return("npx")

      expect(instance.pagefind_command).to eq(%w[npx pagefind])
    end

    it "returns nil when executable is nil" do
      allow(Docyard::Search::PagefindBinary).to receive(:executable).and_return(nil)

      expect(instance.pagefind_command).to be_nil
    end
  end

  describe "#build_pagefind_args" do
    it "returns base args with site directory and output subdir", :aggregate_failures do
      result = instance.build_pagefind_args("/path/to/site")

      expect(result).to include("--site", "/path/to/site")
      expect(result).to include("--output-subdir", "_docyard/pagefind")
    end

    it "includes exclusion selectors when configured", :aggregate_failures do
      search_config.exclude = [".sidebar", ".nav"]

      result = instance.build_pagefind_args("/path/to/site")

      expect(result).to include("--exclude-selectors", ".sidebar")
      expect(result).to include("--exclude-selectors", ".nav")
    end

    it "handles nil exclude config", :aggregate_failures do
      search_config.exclude = nil

      result = instance.build_pagefind_args("/path/to/site")

      expect(result).to include("--site", "/path/to/site")
      expect(result).to include("--output-subdir", "_docyard/pagefind")
    end
  end
end

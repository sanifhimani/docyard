# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe Docyard::FileWatcher do
  let(:docs_dir) { Dir.mktmpdir }
  let(:changes) { [] }
  let(:watcher) do
    described_class.new(
      docs_path: docs_dir,
      on_change: ->(type) { changes << type }
    )
  end

  before do
    FileUtils.mkdir_p(docs_dir)
  end

  after do
    watcher.stop
    FileUtils.rm_rf(docs_dir)
  end

  describe "#start" do
    it "starts without error" do
      expect { watcher.start }.not_to raise_error
    end
  end

  describe "#stop" do
    it "stops without error" do
      watcher.start
      expect { watcher.stop }.not_to raise_error
    end
  end

  describe "change categorization" do
    it "categorizes markdown files as content" do
      watcher.send(:categorize_change, "/docs/test.md")
      expect(watcher.instance_variable_get(:@pending_changes)[:content]).to be true
    end

    it "categorizes _sidebar.yml as config" do
      watcher.send(:categorize_change, "/docs/_sidebar.yml")
      expect(watcher.instance_variable_get(:@pending_changes)[:config]).to be true
    end

    it "categorizes docyard.yml as config" do
      watcher.send(:categorize_change, "/project/docyard.yml")
      expect(watcher.instance_variable_get(:@pending_changes)[:config]).to be true
    end

    it "categorizes css files as asset" do
      watcher.send(:categorize_change, "/docs/style.css")
      expect(watcher.instance_variable_get(:@pending_changes)[:asset]).to be true
    end

    it "categorizes js files as asset" do
      watcher.send(:categorize_change, "/docs/script.js")
      expect(watcher.instance_variable_get(:@pending_changes)[:asset]).to be true
    end
  end

  describe "change type determination" do
    it "prioritizes config over content" do
      watcher.instance_variable_set(:@pending_changes, { content: true, config: true, asset: false })
      expect(watcher.send(:determine_change_type, watcher.instance_variable_get(:@pending_changes))).to eq(:full)
    end

    it "returns content when only content changed" do
      watcher.instance_variable_set(:@pending_changes, { content: true, config: false, asset: false })
      expect(watcher.send(:determine_change_type, watcher.instance_variable_get(:@pending_changes))).to eq(:content)
    end

    it "returns asset when only asset changed" do
      watcher.instance_variable_set(:@pending_changes, { content: false, config: false, asset: true })
      expect(watcher.send(:determine_change_type, watcher.instance_variable_get(:@pending_changes))).to eq(:asset)
    end

    it "returns nil when nothing changed" do
      watcher.instance_variable_set(:@pending_changes, { content: false, config: false, asset: false })
      expect(watcher.send(:determine_change_type, watcher.instance_variable_get(:@pending_changes))).to be_nil
    end
  end
end

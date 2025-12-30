# frozen_string_literal: true

RSpec.describe Docyard::FileWatcher do
  include_context "with temp directory"

  let(:watcher) { described_class.new(temp_dir) }

  describe "#changed_since?" do
    it "returns false for timestamps after last modification" do
      future_time = Time.now + 10

      expect(watcher.changed_since?(future_time)).to be(false)
    end

    it "returns true for timestamps before initialization" do
      past_time = Time.now - 10
      # Watcher sets last_modified_time on initialization
      expect(watcher.changed_since?(past_time)).to be(true)
    end

    it "correctly compares against last_modified_time" do
      # Verify the comparison logic works correctly
      expect(watcher.changed_since?(watcher.last_modified_time - 1)).to be(true)
      expect(watcher.changed_since?(watcher.last_modified_time + 1)).to be(false)
    end
  end

  describe "#start and #stop" do
    it "starts and stops without error", :aggregate_failures do
      expect { watcher.start }.not_to raise_error
      expect { watcher.stop }.not_to raise_error
    end

    it "can be started and stopped multiple times" do
      watcher.start
      watcher.stop
      watcher.start

      expect { watcher.stop }.not_to raise_error
    end
  end

  describe "#last_modified_time" do
    it "returns a Time object" do
      expect(watcher.last_modified_time).to be_a(Time)
    end
  end
end

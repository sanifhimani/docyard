# frozen_string_literal: true

RSpec.describe Docyard::FileWatcher do
  let(:docs_path) { "spec/fixtures" }
  let(:watcher) { described_class.new(docs_path) }

  describe "#initialize" do
    it "sets up the watcher with docs path", :aggregate_failures do
      expect(watcher.last_modified_time).to be_a(Time)
      expect(watcher.instance_variable_get(:@docs_path)).to eq(docs_path)
    end
  end

  describe "#changed_since?" do
    it "returns false for timestamps after last modification" do
      future_time = Time.now + 10
      expect(watcher.changed_since?(future_time)).to be(false)
    end

    it "returns true for timestamps before last modification" do
      past_time = Time.now - 10
      watcher.instance_variable_set(:@last_modified_time, Time.now)

      expect(watcher.changed_since?(past_time)).to be(true)
    end
  end

  describe "#start" do
    it "starts the listener", :aggregate_failures do
      watcher.start
      listener = watcher.instance_variable_get(:@listener)

      expect(listener).not_to be_nil
      expect(listener).to be_processing

      watcher.stop
    end
  end

  describe "#stop" do
    it "stops the listener gracefully" do
      watcher.start
      watcher.stop
      listener = watcher.instance_variable_get(:@listener)

      expect(listener).not_to be_processing
    end

    it "handles errors when stopping", :aggregate_failures do
      listener = instance_double(Listen::Listener, stop: nil)
      watcher.instance_variable_set(:@listener, listener)
      allow(listener).to receive(:stop).and_raise(StandardError, "test error")
      allow(Docyard.logger).to receive(:error)

      watcher.stop

      expect(Docyard.logger).to have_received(:error).with(/Error stopping file watcher/)
    end
  end
end

# frozen_string_literal: true

require "listen"

module Docyard
  class FileWatcher
    attr_reader :last_modified_time

    def initialize(docs_path)
      @docs_path = docs_path
      @last_modified_time = Time.now
      @listener = nil
    end

    def start
      @listener = Listen.to(@docs_path, only: /\.md$/) do |modified, added, removed|
        handle_changes(modified, added, removed)
      end

      @listener.start
    end

    def stop
      @listener&.stop
    rescue StandardError => e
      Docyard.logger.error "Error stopping file watcher: #{e.class} - #{e.message}"
    end

    def changed_since?(timestamp)
      @last_modified_time > timestamp
    end

    private

    def handle_changes(modified, added, removed)
      return if modified.empty? && added.empty? && removed.empty?

      @last_modified_time = Time.now
      Docyard.logger.info "Files changed, triggering reload..."
    end
  end
end

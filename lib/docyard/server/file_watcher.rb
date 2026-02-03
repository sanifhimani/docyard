# frozen_string_literal: true

require "listen"

module Docyard
  class FileWatcher
    DEBOUNCE_DELAY = 0.1
    CONFIG_FILES = %w[docyard.yml _sidebar.yml].freeze
    CONTENT_EXTENSIONS = %w[.md .markdown].freeze
    CSS_EXTENSIONS = %w[.css].freeze
    ASSET_EXTENSIONS = %w[.js .html .erb].freeze

    def initialize(docs_path:, on_change:)
      @docs_path = File.expand_path(docs_path)
      @project_root = File.dirname(@docs_path)
      @on_change = on_change
      @docs_listener = nil
      @config_listener = nil
      @pending_changes = { content: false, config: false, css: false, asset: false }
      @debounce_timer = nil
      @mutex = Mutex.new
    end

    def start
      @docs_listener = Listen.to(@docs_path, latency: DEBOUNCE_DELAY) do |modified, added, removed|
        handle_changes(modified + added + removed)
      end
      @docs_listener.start

      @config_listener = Listen.to(@project_root, only: /\Adocyard\.yml\z/) do |modified, added, removed|
        handle_changes(modified + added + removed)
      end
      @config_listener.start
    end

    def stop
      @docs_listener&.stop
      @config_listener&.stop
      @debounce_timer&.kill
    end

    private

    def handle_changes(paths)
      return if paths.empty?

      @mutex.synchronize do
        paths.each { |path| categorize_change(path) }
        schedule_notification
      end
    end

    def categorize_change(path)
      filename = File.basename(path)
      extension = File.extname(path)

      if CONFIG_FILES.include?(filename)
        @pending_changes[:config] = true
      elsif CONTENT_EXTENSIONS.include?(extension)
        @pending_changes[:content] = true
      elsif CSS_EXTENSIONS.include?(extension)
        @pending_changes[:css] = true
      elsif ASSET_EXTENSIONS.include?(extension)
        @pending_changes[:asset] = true
      end
    end

    def schedule_notification
      @debounce_timer&.kill
      @debounce_timer = Thread.new do
        sleep DEBOUNCE_DELAY
        send_notification
      end
    end

    def send_notification
      changes = nil
      @mutex.synchronize do
        changes = @pending_changes.dup
        @pending_changes = { content: false, config: false, css: false, asset: false }
      end

      change_type = determine_change_type(changes)
      @on_change.call(change_type) if change_type
    end

    def determine_change_type(changes)
      return :full if changes[:config]
      return :content if changes[:content]
      return :css if changes[:css]
      return :asset if changes[:asset]

      nil
    end
  end
end

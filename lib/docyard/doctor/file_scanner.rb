# frozen_string_literal: true

module Docyard
  class Doctor
    class FileScanner
      THREAD_COUNT = [Etc.nprocessors, 8].min

      attr_reader :docs_path, :files_scanned, :links_checked, :images_checked

      def initialize(docs_path)
        @docs_path = docs_path
        @files_scanned = 0
        @links_checked = 0
        @images_checked = 0
        @mutex = Mutex.new
      end

      def scan
        files = markdown_files
        return [] if files.empty?

        files.size < THREAD_COUNT ? scan_sequential(files) : scan_parallel(files)
      end

      private

      def scan_sequential(files)
        checkers = build_checkers
        diagnostics = []

        files.each do |file_path|
          diagnostics.concat(process_file(file_path, checkers))
        end

        @files_scanned = files.size
        collect_stats([checkers])
        diagnostics
      end

      def scan_parallel(files)
        queue = build_work_queue(files)
        results = run_worker_threads(queue)

        @files_scanned = files.size
        collect_stats(results[:checkers])
        results[:diagnostics]
      end

      def build_work_queue(files)
        queue = Queue.new
        files.each { |f| queue << f }
        THREAD_COUNT.times { queue << :done }
        queue
      end

      def run_worker_threads(queue)
        all_checkers = []
        all_diagnostics = []

        threads = THREAD_COUNT.times.map { create_worker_thread(queue, all_checkers, all_diagnostics) }
        threads.each(&:join)

        { checkers: all_checkers, diagnostics: all_diagnostics }
      end

      def create_worker_thread(queue, all_checkers, all_diagnostics)
        Thread.new do
          checkers = build_checkers
          thread_diagnostics = process_queue(queue, checkers)

          @mutex.synchronize do
            all_checkers << checkers
            all_diagnostics.concat(thread_diagnostics)
          end
        end
      end

      def process_queue(queue, checkers)
        diagnostics = []
        while (file_path = queue.pop) != :done
          diagnostics.concat(process_file(file_path, checkers))
        end
        diagnostics
      end

      def process_file(file_path, checkers)
        content = File.read(file_path)
        checkers.flat_map { |checker| checker.check_file(content, file_path) }
      end

      def markdown_files
        Dir.glob(File.join(docs_path, "**", "*.md"))
      end

      def build_checkers
        [
          ContentChecker.new(docs_path),
          ComponentChecker.new(docs_path),
          CodeBlockChecker.new(docs_path),
          LinkChecker.new(docs_path),
          ImageChecker.new(docs_path)
        ]
      end

      def collect_stats(checker_sets)
        checker_sets.flatten.each do |checker|
          @links_checked += checker.links_checked if checker.respond_to?(:links_checked)
          @images_checked += checker.images_checked if checker.respond_to?(:images_checked)
        end
      end
    end
  end
end

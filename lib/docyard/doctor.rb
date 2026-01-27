# frozen_string_literal: true

require_relative "doctor/link_checker"
require_relative "doctor/image_checker"
require_relative "doctor/orphan_checker"
require_relative "doctor/reporter"

module Docyard
  class Doctor
    attr_reader :config, :docs_path

    def initialize
      @config = Config.load
      @docs_path = config.source
    end

    def run
      results, stats = collect_results
      reporter = DoctorReporter.new(results, stats)
      reporter.print
      reporter.exit_code
    end

    private

    def collect_results
      link_checker = LinkChecker.new(docs_path)
      image_checker = ImageChecker.new(docs_path)
      orphan_checker = OrphanChecker.new(docs_path, config)

      results = {
        broken_links: link_checker.check,
        missing_images: image_checker.check,
        orphan_pages: orphan_checker.check
      }

      stats = {
        files: link_checker.files_checked,
        links: link_checker.links_checked,
        images: image_checker.images_checked
      }

      [results, stats]
    end
  end
end

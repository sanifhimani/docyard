# frozen_string_literal: true

require_relative "doctor/config_checker"
require_relative "doctor/sidebar_checker"
require_relative "doctor/content_checker"
require_relative "doctor/component_checker"
require_relative "doctor/code_block_checker"
require_relative "doctor/link_checker"
require_relative "doctor/image_checker"
require_relative "doctor/orphan_checker"
require_relative "doctor/file_scanner"
require_relative "doctor/config_fixer"
require_relative "doctor/sidebar_fixer"
require_relative "doctor/markdown_fixer"
require_relative "doctor/reporter"

module Docyard
  class Doctor
    attr_reader :config, :docs_path, :fix

    def initialize(fix: false)
      @fix = fix
      @config = load_config_safely
      @docs_path = config&.source || "docs"
    end

    def run
      fix ? run_with_fix : run_check_only
    end

    private

    def run_check_only
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      diagnostics, stats = collect_diagnostics
      duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

      reporter = Reporter.new(diagnostics, stats, duration: duration)
      reporter.print
      reporter.exit_code
    end

    def run_with_fix
      config_fixer = ConfigFixer.new
      sidebar_fixer = SidebarFixer.new(docs_path)
      markdown_fixer = MarkdownFixer.new(docs_path)

      run_config_fix_loop(config_fixer)
      run_sidebar_fix(sidebar_fixer)
      run_markdown_fix(markdown_fixer)

      print_fix_results(config_fixer, sidebar_fixer, markdown_fixer)

      diagnostics_after, _stats_after = collect_diagnostics
      remaining_errors = diagnostics_after.count(&:error?)

      print_remaining_issues(diagnostics_after) if remaining_errors.positive?
      remaining_errors.positive? ? 1 : 0
    end

    def run_config_fix_loop(fixer)
      max_iterations = 10
      max_iterations.times do
        reload_config
        diagnostics, _stats = collect_diagnostics
        config_diagnostics = diagnostics.select { |d| d.category == :CONFIG && d.fixable? }
        break if config_diagnostics.empty?

        count_before = fixer.fixed_count
        fixer.fix(config_diagnostics)
        break if fixer.fixed_count == count_before # no progress made
      end
    end

    def run_sidebar_fix(fixer)
      diagnostics, _stats = collect_diagnostics
      sidebar_diagnostics = diagnostics.select { |d| d.category == :SIDEBAR && d.fixable? }
      fixer.fix(sidebar_diagnostics)
    end

    def run_markdown_fix(fixer)
      diagnostics, _stats = collect_diagnostics
      component_diagnostics = diagnostics.select { |d| d.category == :COMPONENT && d.fixable? }
      fixer.fix(component_diagnostics)
    end

    def reload_config
      @config = load_config_safely
    end

    def print_fix_results(config_fixer, sidebar_fixer, markdown_fixer)
      print_fix_header
      fixers = [
        [config_fixer, "docyard.yml"],
        [sidebar_fixer, "_sidebar.yml"],
        [markdown_fixer, "markdown files"]
      ]
      total_fixed = fixers.sum { |f, _| f.fixed_count }

      total_fixed.positive? ? print_all_fixes(fixers, total_fixed) : print_no_fixes
    end

    def print_all_fixes(fixers, total_fixed)
      fixers.each { |fixer, name| print_fixer_results(fixer, name) }
      puts "  #{UI.success("Fixed #{total_fixed} issue(s) total")}"
    end

    def print_fixer_results(fixer, name)
      return unless fixer.fixed_count.positive?

      puts "  Fixed #{fixer.fixed_count} issue(s) in #{name}:"
      print_fixed_issues(fixer) if fixer.respond_to?(:fixed_issues)
      puts
    end

    def print_fixed_issues(fixer)
      fixer.fixed_issues.each { |d| puts "    #{UI.dim(d.location)}: #{describe_fix(d)}" }
    end

    def print_no_fixes
      puts "  #{UI.yellow('No issues were auto-fixed.')}"
    end

    def print_fix_header
      puts
      puts "  #{UI.bold('Docyard')} v#{VERSION}"
      puts
    end

    def describe_fix(diagnostic)
      case diagnostic.fix[:type]
      when :rename then "renamed '#{diagnostic.fix[:from]}' to '#{diagnostic.fix[:to]}'"
      when :replace then "changed to #{diagnostic.fix[:value].inspect}"
      when :line_replace then "replaced '#{diagnostic.fix[:from]}' with '#{diagnostic.fix[:to]}'"
      else "fixed"
      end
    end

    def print_remaining_issues(diagnostics)
      puts
      puts "  Remaining issues:"
      diagnostics.reject(&:fixable?).each { |d| puts "    #{d.location}: #{d.message}" }
      puts
    end

    def load_config_safely
      Config.load(Dir.pwd)
    rescue ConfigError
      nil
    end

    def collect_diagnostics
      file_scanner = FileScanner.new(docs_path)
      scanner_diagnostics = file_scanner.scan

      diagnostics = [
        collect_config_and_sidebar_diagnostics,
        scanner_diagnostics,
        config ? OrphanChecker.new(docs_path, config).check : []
      ].flatten

      stats = {
        files: file_scanner.files_scanned,
        links: file_scanner.links_checked,
        images: file_scanner.images_checked
      }

      [diagnostics, stats]
    end

    def collect_config_and_sidebar_diagnostics
      diagnostics = []
      diagnostics.concat(ConfigChecker.new(config).check) if config
      diagnostics.concat(SidebarChecker.new(docs_path).check)
      diagnostics
    end
  end
end

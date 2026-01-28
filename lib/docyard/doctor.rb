# frozen_string_literal: true

require_relative "doctor/config_checker"
require_relative "doctor/sidebar_checker"
require_relative "doctor/link_checker"
require_relative "doctor/image_checker"
require_relative "doctor/orphan_checker"
require_relative "doctor/config_fixer"
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
      if fix
        run_with_fix
      else
        run_check_only
      end
    end

    private

    def run_check_only
      results, stats = collect_results
      reporter = Reporter.new(results, stats)
      reporter.print
      reporter.exit_code
    end

    def run_with_fix
      results, _stats = collect_results
      fixer = ConfigFixer.new
      fixer.fix(results[:config_issues])

      print_fix_results(fixer)

      results_after, _stats_after = collect_results
      remaining_errors = count_errors(results_after)

      if remaining_errors.positive?
        puts
        puts "  Remaining issues:"
        print_remaining_issues(results_after)
      end

      remaining_errors.positive? ? 1 : 0
    end

    def print_fix_results(fixer) # rubocop:disable Metrics/AbcSize
      puts
      puts "  #{UI.bold('Docyard')} v#{VERSION}"
      puts
      if fixer.fixed_count.positive?
        puts "  #{UI.success("Fixed #{fixer.fixed_count} issue(s)")} in docyard.yml:"
        fixer.fixed_issues.each do |issue|
          puts "    #{UI.dim(issue.field)}: #{describe_fix(issue)}"
        end
      else
        puts "  #{UI.yellow('No issues were auto-fixed.')}"
      end
    end

    def describe_fix(issue)
      case issue.fix[:type]
      when :rename
        "renamed from '#{issue.fix[:from]}' to '#{issue.fix[:to]}'"
      when :replace
        "changed to #{issue.fix[:value].inspect}"
      else
        "fixed"
      end
    end

    def print_remaining_issues(results)
      print_config_issues(results[:config_issues])
      print_link_issues(results[:broken_links], "broken link")
      print_link_issues(results[:missing_images], "missing image")
      puts
    end

    def print_config_issues(issues)
      issues.reject(&:fixable?).each { |i| puts "    #{i.field}: #{i.message}" }
    end

    def print_link_issues(issues, label)
      issues.each { |i| puts "    #{i.file}:#{i.line}: #{label} #{i.target}" }
    end

    def count_errors(results)
      config_errors = results[:config_issues].count(&:error?)
      config_errors + results[:broken_links].size + results[:missing_images].size
    end

    def load_config_safely
      Config.load(Dir.pwd, validate: false)
    rescue ConfigError
      nil
    end

    def collect_results
      link_checker = LinkChecker.new(docs_path)
      image_checker = ImageChecker.new(docs_path)

      results = build_results(link_checker, image_checker)
      stats = build_stats(link_checker, image_checker)

      [results, stats]
    end

    def build_results(link_checker, image_checker)
      {
        config_issues: collect_config_issues,
        broken_links: link_checker.check,
        missing_images: image_checker.check,
        orphan_pages: config ? OrphanChecker.new(docs_path, config).check : []
      }
    end

    def collect_config_issues
      issues = []
      issues.concat(ConfigChecker.new(config).check) if config
      issues.concat(SidebarChecker.new(docs_path).check)
      issues
    end

    def build_stats(link_checker, image_checker)
      {
        files: link_checker.files_checked,
        links: link_checker.links_checked,
        images: image_checker.images_checked
      }
    end
  end
end

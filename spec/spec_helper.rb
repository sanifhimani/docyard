# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"

  SimpleCov.formatters = SimpleCov::Formatter::HTMLFormatter
end

SimpleCov.at_exit do
  SimpleCov.result.format!
end

require "docyard"

Dir[File.join(__dir__, "support", "**", "*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = "doc" if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed

  config.before do
    Docyard::Logging.logger = nil
    Docyard::UI.enabled = false
  end
end

module LoggerTestHelpers
  TEST_LOG_FORMATTER = proc do |severity, _datetime, _progname, msg|
    severity == "INFO" ? "#{msg}\n" : "[#{severity}] #{msg}\n"
  end

  def capture_logger_output
    output = StringIO.new
    original_logger = Docyard::Logging.logger
    Docyard::Logging.logger = Logger.new(output).tap { |l| l.formatter = TEST_LOG_FORMATTER }
    yield
    output.string
  ensure
    Docyard::Logging.logger = original_logger
  end
end

RSpec.configure do |config|
  config.include LoggerTestHelpers
end

# frozen_string_literal: true

RSpec.describe Docyard::Logging do
  after do
    described_class.logger = nil
  end

  describe ".logger" do
    it "returns a logger instance" do
      expect(described_class.logger).to be_a(Logger)
    end

    it "allows setting a custom logger" do
      custom_logger = Logger.new(StringIO.new)
      described_class.logger = custom_logger

      expect(described_class.logger).to be(custom_logger)
    end
  end

  describe ".level=" do
    it "sets the log level", :aggregate_failures do
      output = StringIO.new
      described_class.logger = Logger.new(output)

      described_class.level = :error

      described_class.logger.info("This should not appear")
      described_class.logger.error("This should appear")

      expect(output.string).not_to include("This should not appear")
      expect(output.string).to include("This should appear")
    end

    it "accepts symbol log levels", :aggregate_failures do
      expect { described_class.level = :debug }.not_to raise_error
      expect { described_class.level = :info }.not_to raise_error
      expect { described_class.level = :warn }.not_to raise_error
      expect { described_class.level = :error }.not_to raise_error
      expect { described_class.level = :fatal }.not_to raise_error
    end
  end

  describe "Docyard.logger" do
    it "provides convenient access to logger", :aggregate_failures do
      expect(Docyard.logger).to be_a(Logger)
      expect(Docyard.logger).to be(described_class.logger)
    end
  end

  describe "Docyard.log_level=" do
    it "provides convenient access to set log level", :aggregate_failures do
      output = StringIO.new
      described_class.logger = Logger.new(output)

      Docyard.log_level = :warn

      Docyard.logger.info("info message")
      Docyard.logger.warn("warn message")

      expect(output.string).not_to include("info message")
      expect(output.string).to include("warn message")
    end
  end

  describe "log format" do
    it "includes timestamp with correct format" do
      described_class.logger = nil

      expect do
        described_class.logger.info("Test message")
      end.to output(/\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]/).to_stdout
    end

    it "includes Docyard prefix, severity, and message", :aggregate_failures do
      output = StringIO.new
      formatter = proc do |severity, datetime, _progname, msg|
        "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] [Docyard] [#{severity}] #{msg}\n"
      end
      described_class.logger = Logger.new(output).tap { |l| l.formatter = formatter }

      described_class.logger.info("Test message")

      expect(output.string).to include("[Docyard]")
      expect(output.string).to include("[INFO]")
      expect(output.string).to include("Test message")
    end
  end
end

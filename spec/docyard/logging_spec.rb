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
    it "outputs INFO messages without prefix" do
      described_class.logger = nil

      expect do
        described_class.logger.info("Test message")
      end.to output("Test message\n").to_stdout
    end

    it "outputs WARN messages with severity prefix" do
      described_class.logger = nil

      expect do
        described_class.logger.warn("Warning message")
      end.to output("[WARN] Warning message\n").to_stdout
    end

    it "outputs ERROR messages with severity prefix" do
      described_class.logger = nil

      expect do
        described_class.logger.error("Error message")
      end.to output("[ERROR] Error message\n").to_stdout
    end

    it "outputs DEBUG messages with severity prefix" do
      output = StringIO.new
      described_class.logger = Logger.new(output)
      described_class.logger.formatter = proc do |severity, _datetime, _progname, msg|
        case severity
        when "DEBUG"
          "[DEBUG] #{msg}\n"
        when "INFO"
          "#{msg}\n"
        else
          "[#{severity}] #{msg}\n"
        end
      end
      described_class.logger.level = Logger::DEBUG

      described_class.logger.debug("Debug message")

      expect(output.string).to eq("[DEBUG] Debug message\n")
    end
  end
end

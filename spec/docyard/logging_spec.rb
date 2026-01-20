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

  describe "warning buffering" do
    after do
      described_class.stop_buffering
    end

    describe ".start_buffering" do
      it "enables buffering mode" do
        described_class.start_buffering

        expect(described_class.buffering?).to be true
      end
    end

    describe ".stop_buffering" do
      it "disables buffering mode and returns buffered warnings", :aggregate_failures do
        described_class.start_buffering
        described_class.buffer_warning("Warning 1")
        described_class.buffer_warning("Warning 2")

        warnings = described_class.stop_buffering

        expect(described_class.buffering?).to be false
        expect(warnings).to eq(["Warning 1", "Warning 2"])
      end

      it "clears the buffer" do
        described_class.start_buffering
        described_class.buffer_warning("Warning")
        described_class.stop_buffering

        expect(described_class.stop_buffering).to eq([])
      end
    end

    describe "warning buffering during logging" do
      it "buffers warnings instead of outputting them when buffering is enabled", :aggregate_failures do
        described_class.logger = nil
        described_class.start_buffering

        output = capture_stdout { described_class.logger.warn("Buffered warning") }

        expect(output).to eq("")
        expect(described_class.stop_buffering).to eq(["Buffered warning"])
      end

      it "outputs warnings normally when buffering is disabled" do
        described_class.logger = nil

        expect do
          described_class.logger.warn("Normal warning")
        end.to output("[WARN] Normal warning\n").to_stdout
      end

      it "does not buffer info messages" do
        described_class.logger = nil
        described_class.start_buffering

        expect do
          described_class.logger.info("Info message")
        end.to output("Info message\n").to_stdout
      end
    end

    describe ".flush_warnings" do
      it "outputs all buffered warnings" do
        output = StringIO.new
        described_class.logger = Logger.new(output)
        described_class.logger.formatter = described_class.send(:log_formatter)

        described_class.start_buffering
        described_class.logger.warn("Warning 1")
        described_class.logger.warn("Warning 2")
        described_class.flush_warnings

        expect(output.string).to eq("[WARN] Warning 1\n[WARN] Warning 2\n")
      end

      it "clears the buffer after flushing" do
        described_class.start_buffering
        described_class.buffer_warning("Warning")
        described_class.flush_warnings

        expect(described_class.stop_buffering).to eq([])
      end
    end

    def capture_stdout
      original_stdout = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = original_stdout
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

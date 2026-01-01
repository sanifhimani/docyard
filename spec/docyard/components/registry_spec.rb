# frozen_string_literal: true

RSpec.describe Docyard::Components::Registry do
  after do
    described_class.reset!
    [
      Docyard::Components::CodeBlockOptionsPreprocessor,
      Docyard::Components::TabsProcessor,
      Docyard::Components::IconProcessor,
      Docyard::Components::CodeBlockProcessor,
      Docyard::Components::HeadingAnchorProcessor,
      Docyard::Components::TableOfContentsProcessor,
      Docyard::Components::TableWrapperProcessor,
      Docyard::Components::CalloutProcessor
    ].each { |p| described_class.register(p) }
  end

  describe ".register" do
    it "registers a processor" do
      described_class.reset!
      processor = Class.new(Docyard::Components::BaseProcessor)

      expect(described_class.processors).to include(processor)
    end

    it "sorts processors by priority" do
      described_class.reset!
      low_priority = Class.new(Docyard::Components::BaseProcessor) { self.priority = 1 }
      high_priority = Class.new(Docyard::Components::BaseProcessor) { self.priority = 5 }

      expect(described_class.processors.index(low_priority)).to be < described_class.processors.index(high_priority)
    end

    it "uses default priority of 100 if not specified" do
      described_class.reset!
      with_priority = Class.new(Docyard::Components::BaseProcessor) { self.priority = 50 }
      without_priority = Class.new(Docyard::Components::BaseProcessor)

      expect(described_class.processors.index(with_priority)).to be < described_class.processors.index(without_priority)
    end
  end

  describe ".run_preprocessors" do
    it "runs all preprocessors in priority order" do
      described_class.reset!
      first = Class.new(Docyard::Components::BaseProcessor) { self.priority = 10 }
      first.define_method(:preprocess) { |content| "#{content}[first]" }
      second = Class.new(Docyard::Components::BaseProcessor) { self.priority = 20 }
      second.define_method(:preprocess) { |content| "#{content}[second]" }

      expect(described_class.run_preprocessors("start")).to eq("start[first][second]")
    end

    it "passes content through all preprocessors" do
      expect(described_class.run_preprocessors("content")).to be_a(String)
    end
  end

  describe ".run_postprocessors" do
    it "runs all postprocessors in priority order" do
      described_class.reset!
      first = Class.new(Docyard::Components::BaseProcessor) { self.priority = 10 }
      first.define_method(:postprocess) { |html| "#{html}[first]" }
      second = Class.new(Docyard::Components::BaseProcessor) { self.priority = 20 }
      second.define_method(:postprocess) { |html| "#{html}[second]" }

      expect(described_class.run_postprocessors("<p>start</p>")).to eq("<p>start</p>[first][second]")
    end

    it "returns a string from postprocessors" do
      expect(described_class.run_postprocessors("<p>content</p>")).to be_a(String)
    end

    it "preserves content through postprocessors" do
      expect(described_class.run_postprocessors("<p>content</p>")).to include("content")
    end
  end

  describe ".reset!" do
    it "clears all registered processors" do
      Class.new(Docyard::Components::BaseProcessor)
      described_class.reset!

      expect(described_class.processors).to be_empty
    end

    it "allows registration after reset" do
      described_class.reset!
      processor = Class.new(Docyard::Components::BaseProcessor)

      expect(described_class.processors).to include(processor)
    end
  end

  describe "context passing" do
    it "shares context between preprocessors and postprocessors" do
      described_class.reset!
      writer = Class.new(Docyard::Components::BaseProcessor) { self.priority = 10 }
      writer.define_method(:preprocess) { |c| context[:data] = "value"; c } # rubocop:disable Style/Semicolon
      reader = Class.new(Docyard::Components::BaseProcessor) { self.priority = 20 }
      reader.define_method(:postprocess) { |html| "#{html}[#{context[:data]}]" }
      ctx = {}
      described_class.run_preprocessors("content", ctx)

      expect(described_class.run_postprocessors("<p>html</p>", ctx)).to include("[value]")
    end

    it "passes context to processor constructor" do
      described_class.reset!
      processor = Class.new(Docyard::Components::BaseProcessor) { self.priority = 1 }
      processor.define_method(:preprocess) { |c| "#{c}[#{context[:test_key]}]" }

      expect(described_class.run_preprocessors("start", { test_key: "test_value" })).to include("[test_value]")
    end

    it "isolates context between separate runs", :aggregate_failures do
      described_class.reset!
      processor = Class.new(Docyard::Components::BaseProcessor) { self.priority = 1 }
      processor.define_method(:preprocess) { |c| "#{c}[#{context[:run]}]" }

      expect(described_class.run_preprocessors("content", { run: "first" })).to include("[first]")
      expect(described_class.run_preprocessors("content", { run: "second" })).to include("[second]")
    end
  end
end

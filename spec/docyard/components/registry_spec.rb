# frozen_string_literal: true

RSpec.describe Docyard::Components::Registry do
  let(:test_preprocessor) do
    Class.new(Docyard::Components::BaseProcessor) do
      self.priority = 10
      define_method(:preprocess) { |content| "#{content}[first]" }
    end
  end

  let(:another_preprocessor) do
    Class.new(Docyard::Components::BaseProcessor) do
      self.priority = 20
      define_method(:preprocess) { |content| "#{content}[second]" }
    end
  end

  let(:test_postprocessor) do
    Class.new(Docyard::Components::BaseProcessor) do
      self.priority = 10
      define_method(:postprocess) { |html| "#{html}[first]" }
    end
  end

  let(:another_postprocessor) do
    Class.new(Docyard::Components::BaseProcessor) do
      self.priority = 20
      define_method(:postprocess) { |html| "#{html}[second]" }
    end
  end

  after do
    described_class.reset!
    require_relative "../../../lib/docyard/components/callout_processor"
    require_relative "../../../lib/docyard/components/icon_processor"
  end

  describe ".register" do
    it "registers a processor" do
      stub_const("Docyard::Components::TestProcessor", Class.new(Docyard::Components::BaseProcessor))

      expect(described_class.processors).to include(Docyard::Components::TestProcessor)
    end

    it "sorts processors by priority" do
      another_proc = Class.new(Docyard::Components::BaseProcessor) { self.priority = 1 }
      test_proc = Class.new(Docyard::Components::BaseProcessor) { self.priority = 5 }

      described_class.register(another_proc)
      described_class.register(test_proc)

      expect(described_class.processors.index(another_proc)).to be < described_class.processors.index(test_proc)
    end

    it "uses default priority of 100 if not specified" do
      test_proc_with_priority = Class.new(Docyard::Components::BaseProcessor) do
        self.priority = 50
      end
      test_proc_no_priority = Class.new(Docyard::Components::BaseProcessor)

      described_class.register(test_proc_with_priority)
      described_class.register(test_proc_no_priority)

      no_priority_index = described_class.processors.index(test_proc_no_priority)
      with_priority_index = described_class.processors.index(test_proc_with_priority)

      expect(with_priority_index).to be < no_priority_index
    end
  end

  describe ".run_preprocessors" do
    it "runs all preprocessors in priority order" do
      stub_const("Docyard::Components::TestProcessor", test_preprocessor)
      stub_const("Docyard::Components::AnotherTestProcessor", another_preprocessor)

      result = described_class.run_preprocessors("start")

      expect(result).to eq("start[first][second]")
    end

    it "passes content through all preprocessors" do
      result = described_class.run_preprocessors("content")

      expect(result).to be_a(String)
    end
  end

  describe ".run_postprocessors" do
    it "runs all postprocessors in priority order" do
      stub_const("Docyard::Components::TestProcessor", test_postprocessor)
      stub_const("Docyard::Components::AnotherTestProcessor", another_postprocessor)

      result = described_class.run_postprocessors("<p>start</p>")

      expect(result).to eq("<p>start</p>[first][second]")
    end

    it "returns a string from postprocessors" do
      result = described_class.run_postprocessors("<p>content</p>")

      expect(result).to be_a(String)
    end

    it "preserves content through postprocessors" do
      result = described_class.run_postprocessors("<p>content</p>")

      expect(result).to include("content")
    end
  end

  describe ".reset!" do
    it "clears all registered processors" do
      test_proc = Class.new(Docyard::Components::BaseProcessor)
      described_class.register(test_proc)

      described_class.reset!

      expect(described_class.processors).to be_empty
    end

    it "allows registration after reset" do
      described_class.reset!
      test_proc = Class.new(Docyard::Components::BaseProcessor)

      described_class.register(test_proc)

      expect(described_class.processors).to include(test_proc)
    end
  end
end

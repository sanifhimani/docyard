# frozen_string_literal: true

RSpec.describe Docyard::Components::BaseProcessor do
  describe "auto-registration" do
    it "automatically registers subclasses with the registry" do
      test_proc = stub_const("Docyard::Components::TestProcessor", Class.new(described_class))

      expect(Docyard::Components::Registry.processors).to include(test_proc)
    end
  end

  describe "#preprocess" do
    it "returns content unchanged by default" do
      processor = described_class.new
      content = "test content"

      result = processor.preprocess(content)

      expect(result).to eq(content)
    end
  end

  describe "#postprocess" do
    it "returns html unchanged by default" do
      processor = described_class.new
      html = "<p>test</p>"

      result = processor.postprocess(html)

      expect(result).to eq(html)
    end
  end

  describe ".priority" do
    it "allows setting priority" do
      stub_const("Docyard::Components::TestProcessor", Class.new(described_class) do
        self.priority = 42
      end)

      expect(Docyard::Components::TestProcessor.priority).to eq(42)
    end

    it "defaults to nil if not set" do
      stub_const("Docyard::Components::TestProcessor", Class.new(described_class))

      expect(Docyard::Components::TestProcessor.priority).to be_nil
    end
  end
end

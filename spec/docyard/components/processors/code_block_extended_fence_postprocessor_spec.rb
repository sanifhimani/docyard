# frozen_string_literal: true

RSpec.describe Docyard::Components::Processors::CodeBlockExtendedFencePostprocessor do
  let(:context) { {} }
  let(:processor) { described_class.new(context) }

  describe "#postprocess" do
    let(:backtick_placeholder) { "\u200B\u200B\u200B" }
    let(:code_marker_placeholder) { "\u200B!\u200Bcode" }

    it "restores single backtick placeholder" do
      html = "<code>#{backtick_placeholder}js</code>"

      result = processor.postprocess(html)

      expect(result).to eq("<code>`js</code>")
    end

    it "restores multiple backtick placeholders for code fence" do
      three_backticks = backtick_placeholder * 3
      html = "<code>#{three_backticks}js\ncode\n#{three_backticks}</code>"

      result = processor.postprocess(html)

      expect(result).to eq("<code>```js\ncode\n```</code>")
    end

    it "restores code marker placeholders" do
      html = "<code>const x = 1; // #{code_marker_placeholder} ++]</code>"

      result = processor.postprocess(html)

      expect(result).to eq("<code>const x = 1; // [!code ++]</code>")
    end

    it "restores mixed placeholders" do
      three_backticks = backtick_placeholder * 3
      html = "<pre>#{three_backticks}md\n#{code_marker_placeholder} highlight]\n#{three_backticks}</pre>"

      result = processor.postprocess(html)

      expect(result).to eq("<pre>```md\n[!code highlight]\n```</pre>")
    end

    it "leaves content without placeholders unchanged" do
      html = "<code>const x = 1;</code>"

      result = processor.postprocess(html)

      expect(result).to eq(html)
    end
  end
end

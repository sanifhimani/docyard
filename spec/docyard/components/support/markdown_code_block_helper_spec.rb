# frozen_string_literal: true

require_relative "../../../../lib/docyard/components/support/markdown_code_block_helper"

RSpec.describe Docyard::Components::Support::MarkdownCodeBlockHelper do
  let(:helper_class) do
    Class.new do
      include Docyard::Components::Support::MarkdownCodeBlockHelper
    end
  end
  let(:helper) { helper_class.new }

  describe "#process_outside_code_blocks" do
    it "yields text segments outside code blocks" do
      content = "before\n```ruby\ncode\n```\nafter"
      result = helper.process_outside_code_blocks(content, &:upcase)

      expect(result).to eq("BEFORE\n```ruby\ncode\n```\nAFTER")
    end

    it "preserves code block content unchanged", :aggregate_failures do
      content = "text\n```ruby\nAPI = 'test'\n```\nmore text"
      result = helper.process_outside_code_blocks(content) do |segment|
        segment.gsub("API", "REPLACED")
      end

      expect(result).to include("API = 'test'")
      expect(result).not_to include("REPLACED = 'test'")
    end

    it "handles multiple code blocks" do
      content = "one\n```ruby\nfirst\n```\ntwo\n```js\nsecond\n```\nthree"
      result = helper.process_outside_code_blocks(content, &:upcase)

      expect(result).to eq("ONE\n```ruby\nfirst\n```\nTWO\n```js\nsecond\n```\nTHREE")
    end

    it "handles content with no code blocks" do
      content = "just plain text"
      result = helper.process_outside_code_blocks(content, &:upcase)

      expect(result).to eq("JUST PLAIN TEXT")
    end

    it "handles content that is only a code block" do
      content = "```ruby\ncode only\n```"
      result = helper.process_outside_code_blocks(content, &:upcase)

      expect(result).to eq("```ruby\ncode only\n```")
    end

    it "handles tilde fences" do
      content = "before\n~~~ruby\ncode\n~~~\nafter"
      result = helper.process_outside_code_blocks(content, &:upcase)

      expect(result).to eq("BEFORE\n~~~ruby\ncode\n~~~\nAFTER")
    end

    it "handles code blocks with language identifiers" do
      content = "text\n```javascript\nconst x = 1;\n```\ntext"
      result = helper.process_outside_code_blocks(content) do |segment|
        segment.gsub("text", "replaced")
      end

      expect(result).to eq("replaced\n```javascript\nconst x = 1;\n```\nreplaced")
    end

    it "handles code blocks with metadata" do
      content = "text\n```ruby [title] {1,2}\ncode\n```\ntext"
      result = helper.process_outside_code_blocks(content, &:upcase)

      expect(result).to eq("TEXT\n```ruby [title] {1,2}\ncode\n```\nTEXT")
    end

    it "handles nested backticks inside code blocks" do
      content = "text\n```markdown\nUse `code` here\n```\ntext"
      result = helper.process_outside_code_blocks(content, &:upcase)

      expect(result).to include("Use `code` here")
    end

    it "handles code blocks at start of content" do
      content = "```ruby\ncode\n```\nafter"
      result = helper.process_outside_code_blocks(content, &:upcase)

      expect(result).to eq("```ruby\ncode\n```\nAFTER")
    end

    it "handles code blocks at end of content" do
      content = "before\n```ruby\ncode\n```"
      result = helper.process_outside_code_blocks(content, &:upcase)

      expect(result).to eq("BEFORE\n```ruby\ncode\n```")
    end

    it "handles four-backtick fences" do
      content = "text\n````ruby\ncode with ```backticks```\n````\ntext"
      result = helper.process_outside_code_blocks(content, &:upcase)

      expect(result).to eq("TEXT\n````ruby\ncode with ```backticks```\n````\nTEXT")
    end
  end
end

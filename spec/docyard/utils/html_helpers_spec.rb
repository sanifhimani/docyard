# frozen_string_literal: true

RSpec.describe Docyard::Utils::HtmlHelpers do
  let(:helper) { Class.new { include Docyard::Utils::HtmlHelpers }.new }

  describe "#escape_html" do
    it "escapes ampersands" do
      expect(helper.escape_html("Tom & Jerry")).to eq("Tom &amp; Jerry")
    end

    it "escapes less than" do
      expect(helper.escape_html("a < b")).to eq("a &lt; b")
    end

    it "escapes greater than" do
      expect(helper.escape_html("a > b")).to eq("a &gt; b")
    end

    it "escapes double quotes" do
      expect(helper.escape_html('say "hello"')).to eq("say &quot;hello&quot;")
    end

    it "escapes all special characters together" do
      input = '<div class="test">Tom & Jerry</div>'
      expected = "&lt;div class=&quot;test&quot;&gt;Tom &amp; Jerry&lt;/div&gt;"

      expect(helper.escape_html(input)).to eq(expected)
    end

    it "converts non-strings to string", :aggregate_failures do
      expect(helper.escape_html(123)).to eq("123")
      expect(helper.escape_html(nil)).to eq("")
    end

    it "leaves normal text unchanged" do
      expect(helper.escape_html("normal text")).to eq("normal text")
    end
  end

  describe "#escape_html_attribute" do
    it "escapes double quotes" do
      expect(helper.escape_html_attribute('say "hello"')).to eq("say &quot;hello&quot;")
    end

    it "escapes single quotes" do
      expect(helper.escape_html_attribute("it's")).to eq("it&#39;s")
    end

    it "escapes less than" do
      expect(helper.escape_html_attribute("a < b")).to eq("a &lt; b")
    end

    it "escapes greater than" do
      expect(helper.escape_html_attribute("a > b")).to eq("a &gt; b")
    end

    it "escapes all special characters together" do
      input = '<div class="test">it\'s</div>'
      expected = "&lt;div class=&quot;test&quot;&gt;it&#39;s&lt;/div&gt;"

      expect(helper.escape_html_attribute(input)).to eq(expected)
    end

    it "leaves normal text unchanged" do
      expect(helper.escape_html_attribute("normal text")).to eq("normal text")
    end
  end
end

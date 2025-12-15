# frozen_string_literal: true

RSpec.describe Docyard::Components::CodeBlockProcessor do
  let(:context) { {} }
  let(:processor) { described_class.new(context) }

  describe "#postprocess" do
    context "with code blocks" do
      it "wraps code block with container and adds copy button", :aggregate_failures do
        html = <<~HTML
          <div class="highlight"><pre><code>puts "Hello, World!"</code></pre></div>
        HTML

        result = processor.postprocess(html)

        expect(result).to include('class="docyard-code-block"')
        expect(result).to include('class="docyard-code-block__copy"')
        expect(result).to include('aria-label="Copy code to clipboard"')
        expect(result).to include('data-code="puts &quot;Hello, World!&quot;"')
      end

      it "extracts code text correctly from highlighted code", :aggregate_failures do
        html = <<~HTML
          <div class="highlight"><pre><code class="language-ruby"><span class="k">def</span> <span class="nf">hello</span>
            <span class="nb">puts</span> <span class="s2">"Hello"</span>
          <span class="k">end</span></code></pre></div>
        HTML

        result = processor.postprocess(html)

        expect(result).to include('data-code="def hello')
        expect(result).to include("puts &quot;Hello&quot;")
        expect(result).to include('end"')
      end

      it "handles multiple code blocks on the same page", :aggregate_failures do
        html = <<~HTML
          <div class="highlight"><pre><code>First block</code></pre></div>
          <p>Some text</p>
          <div class="highlight"><pre><code>Second block</code></pre></div>
        HTML

        result = processor.postprocess(html)

        expect(result.scan('class="docyard-code-block"').count).to eq(2)
        expect(result.scan('class="docyard-code-block__copy"').count).to eq(2)
        expect(result).to include('data-code="First block"')
        expect(result).to include('data-code="Second block"')
      end

      it "escapes special characters in data-code attribute", :aggregate_failures do
        html = <<~HTML
          <div class="highlight"><pre><code>let name = "John &lt;script&gt;alert('xss')&lt;/script&gt;";</code></pre></div>
        HTML

        result = processor.postprocess(html)

        expect(result).to include("&quot;John &lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;&quot;")
        expect(result).not_to include("<script>")
      end

      it "handles empty code blocks", :aggregate_failures do
        html = <<~HTML
          <div class="highlight"><pre><code></code></pre></div>
        HTML

        result = processor.postprocess(html)

        expect(result).to include('class="docyard-code-block"')
        expect(result).to include('data-code=""')
      end

      it "preserves code block structure", :aggregate_failures do
        html = <<~HTML
          <div class="highlight"><pre><code class="language-ruby">puts "test"</code></pre></div>
        HTML

        result = processor.postprocess(html)

        expected_html = '<div class="highlight"><pre><code class="language-ruby">puts "test"</code></pre></div>'
        expect(result).to include(expected_html)
      end

      it "includes the copy icon SVG", :aggregate_failures do
        html = <<~HTML
          <div class="highlight"><pre><code>test</code></pre></div>
        HTML

        result = processor.postprocess(html)

        expect(result).to include("<svg")
        expect(result).to include("</svg>")
      end

      it "decodes HTML entities in code text", :aggregate_failures do
        html = <<~HTML
          <div class="highlight"><pre><code>if (x &lt; 10 &amp;&amp; y &gt; 5)</code></pre></div>
        HTML

        result = processor.postprocess(html)

        expect(result).to include('data-code="if (x &lt; 10 && y &gt; 5)"')
      end
    end

    context "without code blocks" do
      it "returns HTML unchanged when no code blocks present" do
        html = <<~HTML
          <p>Just a paragraph</p>
          <div class="some-other-div">Content</div>
        HTML

        result = processor.postprocess(html)

        expect(result).to eq(html)
      end
    end

    context "with line numbers" do
      it "shows line numbers when :line-numbers option is set", :aggregate_failures do
        context[:code_block_options] = [{ lang: "ruby", option: ":line-numbers" }]
        html = '<div class="highlight"><pre><code>line 1
line 2
line 3</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include('class="docyard-code-block docyard-code-block--line-numbers"')
        expect(result).to include('class="docyard-code-block__lines"')
        expect(result).to include("<span>1</span>")
        expect(result).to include("<span>2</span>")
        expect(result).to include("<span>3</span>")
      end

      it "does not show line numbers when :no-line-numbers option is set", :aggregate_failures do
        context[:code_block_options] = [{ lang: "ruby", option: ":no-line-numbers" }]
        html = '<div class="highlight"><pre><code>line 1</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).not_to include("docyard-code-block--line-numbers")
        expect(result).not_to include("docyard-code-block__lines")
      end

      it "starts line numbers from custom value with :line-numbers=N", :aggregate_failures do
        context[:code_block_options] = [{ lang: "ruby", option: ":line-numbers=5" }]
        html = '<div class="highlight"><pre><code>line 1
line 2</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include("<span>5</span>")
        expect(result).to include("<span>6</span>")
        expect(result).not_to include("<span>1</span>")
      end

      it "shows line numbers when global config is enabled" do
        context[:config] = { "markdown" => { "lineNumbers" => true } }
        html = '<div class="highlight"><pre><code>line 1</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include("docyard-code-block--line-numbers")
      end

      it "block-level :no-line-numbers overrides global config" do
        context[:config] = { "markdown" => { "lineNumbers" => true } }
        context[:code_block_options] = [{ lang: "ruby", option: ":no-line-numbers" }]
        html = '<div class="highlight"><pre><code>line 1</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).not_to include("docyard-code-block--line-numbers")
      end

      it "block-level :line-numbers overrides global config off" do
        context[:config] = { "markdown" => { "lineNumbers" => false } }
        context[:code_block_options] = [{ lang: "ruby", option: ":line-numbers" }]
        html = '<div class="highlight"><pre><code>line 1</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include("docyard-code-block--line-numbers")
      end

      it "handles multiple code blocks with different options", :aggregate_failures do
        context[:code_block_options] = [
          { lang: "ruby", option: ":line-numbers" },
          { lang: "js", option: nil },
          { lang: "python", option: ":line-numbers=10" }
        ]
        blocks = [
          '<div class="highlight"><pre><code>ruby code</code></pre></div>',
          '<div class="highlight"><pre><code>js code</code></pre></div>',
          '<div class="highlight"><pre><code>python code</code></pre></div>'
        ]
        result = processor.postprocess(blocks.join("\n"))

        expect(result.scan("docyard-code-block--line-numbers").count).to eq(2)
        expect(result).to include("<span>1</span>")
        expect(result).to include("<span>10</span>")
      end
    end
  end

  describe "priority" do
    it "has priority 20 to run after other processors" do
      expect(described_class.priority).to eq(20)
    end
  end
end

# frozen_string_literal: true

RSpec.describe Docyard::Components::CodeBlockProcessor do
  let(:processor) { described_class.new }

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
  end

  describe "priority" do
    it "has priority 20 to run after other processors" do
      expect(described_class.priority).to eq(20)
    end
  end
end

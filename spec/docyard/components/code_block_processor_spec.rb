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

    context "with line highlighting" do
      it "adds highlighted class to container when highlights present" do
        context[:code_block_options] = [{ lang: "ruby", option: nil, highlights: [1, 3] }]
        html = '<div class="highlight"><pre><code>line 1
line 2
line 3</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include("docyard-code-block--highlighted")
      end

      it "wraps lines in span elements with highlight class", :aggregate_failures do
        context[:code_block_options] = [{ lang: "ruby", option: nil, highlights: [2] }]
        html = '<div class="highlight"><pre><code>line 1
line 2
line 3</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include('<span class="docyard-code-line">line 1')
        expect(result).to include('<span class="docyard-code-line docyard-code-line--highlighted">line 2')
        expect(result).to include('<span class="docyard-code-line">line 3')
      end

      it "highlights line numbers in gutter when line numbers enabled", :aggregate_failures do
        context[:code_block_options] = [{ lang: "ruby", option: ":line-numbers", highlights: [2] }]
        html = '<div class="highlight"><pre><code>line 1
line 2
line 3</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include("<span>1</span>")
        expect(result).to include('<span class="docyard-code-block__line--highlighted">2</span>')
        expect(result).to include("<span>3</span>")
      end

      it "respects custom start line for highlight positions", :aggregate_failures do
        context[:code_block_options] = [{ lang: "ruby", option: ":line-numbers=10", highlights: [11] }]
        html = '<div class="highlight"><pre><code>line 1
line 2
line 3</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include('<span class="docyard-code-line">line 1')
        expect(result).to include('<span class="docyard-code-line docyard-code-line--highlighted">line 2')
        expect(result).to include('<span class="docyard-code-line">line 3')
      end

      it "preserves syntax highlighting spans within lines", :aggregate_failures do
        context[:code_block_options] = [{ lang: "ruby", option: nil, highlights: [1] }]
        code = '<span class="k">def</span> <span class="nf">hello</span>'
        html = %(<div class="highlight"><pre><code>#{code}</code></pre></div>)

        result = processor.postprocess(html)

        expect(result).to include("docyard-code-line--highlighted")
        expect(result).to include('<span class="k">def</span>')
        expect(result).to include('<span class="nf">hello</span>')
      end

      it "does not add highlighted class when no highlights", :aggregate_failures do
        context[:code_block_options] = [{ lang: "ruby", option: nil, highlights: [] }]
        html = '<div class="highlight"><pre><code>line 1</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).not_to include("docyard-code-block--highlighted")
        expect(result).not_to include("docyard-code-line")
      end

      it "handles multiple code blocks with different highlights", :aggregate_failures do
        context[:code_block_options] = [
          { lang: "ruby", option: nil, highlights: [1] },
          { lang: "js", option: nil, highlights: [2] }
        ]
        html = [
          '<div class="highlight"><pre><code>ruby line 1
ruby line 2</code></pre></div>',
          '<div class="highlight"><pre><code>js line 1
js line 2</code></pre></div>'
        ].join("\n")

        result = processor.postprocess(html)

        expect(result.scan("docyard-code-block--highlighted").count).to eq(2)
      end
    end

    context "with diff lines" do
      it "adds diff class to container when diff lines present" do
        context[:code_block_diff_lines] = [{ 1 => :addition }]
        html = '<div class="highlight"><pre><code>added line</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include("docyard-code-block--diff")
      end

      it "wraps addition lines with diff-add class", :aggregate_failures do
        context[:code_block_diff_lines] = [{ 2 => :addition }]
        html = '<div class="highlight"><pre><code>line 1
line 2
line 3</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include('<span class="docyard-code-line">line 1')
        expect(result).to include('<span class="docyard-code-line docyard-code-line--diff-add">line 2')
        expect(result).to include('<span class="docyard-code-line">line 3')
      end

      it "wraps deletion lines with diff-remove class", :aggregate_failures do
        context[:code_block_diff_lines] = [{ 1 => :deletion }]
        html = '<div class="highlight"><pre><code>removed line
kept line</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include('<span class="docyard-code-line docyard-code-line--diff-remove">removed line')
        expect(result).to include('<span class="docyard-code-line">kept line')
      end

      it "handles mixed additions and deletions", :aggregate_failures do
        context[:code_block_diff_lines] = [{ 1 => :deletion, 2 => :addition }]
        html = '<div class="highlight"><pre><code>old line
new line</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include("docyard-code-line--diff-remove")
        expect(result).to include("docyard-code-line--diff-add")
      end

      it "shows diff indicators in gutter with line numbers", :aggregate_failures do
        context[:code_block_options] = [{ lang: "ruby", option: ":line-numbers", highlights: [] }]
        context[:code_block_diff_lines] = [{ 1 => :addition, 2 => :deletion }]
        html = '<div class="highlight"><pre><code>added
removed
normal</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include('class="docyard-code-block__line--diff-add">+1</span>')
        expect(result).to include('class="docyard-code-block__line--diff-remove">-2</span>')
        expect(result).to include("<span>3</span>")
      end

      it "shows diff gutter when no line numbers but has diff", :aggregate_failures do
        context[:code_block_diff_lines] = [{ 1 => :addition }]
        html = '<div class="highlight"><pre><code>added line</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include('class="docyard-code-block__diff-gutter"')
        expect(result).to include('class="docyard-code-block__diff-indicator--add">+</span>')
      end

      it "handles diff with custom start line", :aggregate_failures do
        context[:code_block_options] = [{ lang: "ruby", option: ":line-numbers=10", highlights: [] }]
        context[:code_block_diff_lines] = [{ 1 => :addition }]
        html = '<div class="highlight"><pre><code>added line</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include("+10</span>")
      end

      it "combines diff with line highlighting", :aggregate_failures do
        context[:code_block_options] = [{ lang: "ruby", option: nil, highlights: [1] }]
        context[:code_block_diff_lines] = [{ 1 => :addition }]
        html = '<div class="highlight"><pre><code>both highlighted and added</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include("docyard-code-line--highlighted")
        expect(result).to include("docyard-code-line--diff-add")
      end

      it "does not add diff class when no diff lines" do
        context[:code_block_diff_lines] = [{}]
        html = '<div class="highlight"><pre><code>normal line</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).not_to include("docyard-code-block--diff")
      end

      it "handles multiple code blocks with different diff lines", :aggregate_failures do
        context[:code_block_diff_lines] = [
          { 1 => :addition },
          { 1 => :deletion }
        ]
        html = [
          '<div class="highlight"><pre><code>block 1 line</code></pre></div>',
          '<div class="highlight"><pre><code>block 2 line</code></pre></div>'
        ].join("\n")

        result = processor.postprocess(html)

        expect(result.scan("docyard-code-block--diff").count).to eq(2)
      end
    end

    context "with focus lines" do
      it "adds has-focus class to container when focus lines present" do
        context[:code_block_focus_lines] = [{ 1 => true }]
        html = '<div class="highlight"><pre><code>focused line</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include("docyard-code-block--has-focus")
      end

      it "wraps focus lines with focus class", :aggregate_failures do
        context[:code_block_focus_lines] = [{ 2 => true }]
        html = '<div class="highlight"><pre><code>line 1
line 2
line 3</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include('<span class="docyard-code-line">line 1')
        expect(result).to include('<span class="docyard-code-line docyard-code-line--focus">line 2')
        expect(result).to include('<span class="docyard-code-line">line 3')
      end

      it "handles multiple focus lines", :aggregate_failures do
        context[:code_block_focus_lines] = [{ 1 => true, 3 => true }]
        html = '<div class="highlight"><pre><code>focused 1
normal
focused 2</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include('<span class="docyard-code-line docyard-code-line--focus">focused 1')
        expect(result).to include('<span class="docyard-code-line">normal')
        expect(result).to include('<span class="docyard-code-line docyard-code-line--focus">focused 2')
      end

      it "does not add has-focus class when no focus lines" do
        context[:code_block_focus_lines] = [{}]
        html = '<div class="highlight"><pre><code>normal line</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).not_to include("docyard-code-block--has-focus")
      end

      it "combines focus with line numbers", :aggregate_failures do
        context[:code_block_options] = [{ lang: "ruby", option: ":line-numbers", highlights: [] }]
        context[:code_block_focus_lines] = [{ 2 => true }]
        html = '<div class="highlight"><pre><code>line 1
line 2
line 3</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include("docyard-code-block--has-focus")
        expect(result).to include("docyard-code-block--line-numbers")
        expect(result).to include("docyard-code-line--focus")
      end

      it "combines focus with diff lines", :aggregate_failures do
        context[:code_block_diff_lines] = [{ 1 => :addition }]
        context[:code_block_focus_lines] = [{ 1 => true }]
        html = '<div class="highlight"><pre><code>focused addition</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include("docyard-code-block--has-focus")
        expect(result).to include("docyard-code-block--diff")
        expect(result).to include("docyard-code-line--focus")
        expect(result).to include("docyard-code-line--diff-add")
      end

      it "combines focus with highlights", :aggregate_failures do
        context[:code_block_options] = [{ lang: "ruby", option: nil, highlights: [1] }]
        context[:code_block_focus_lines] = [{ 1 => true }]
        html = '<div class="highlight"><pre><code>focused highlighted</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include("docyard-code-block--has-focus")
        expect(result).to include("docyard-code-block--highlighted")
        expect(result).to include("docyard-code-line--focus")
        expect(result).to include("docyard-code-line--highlighted")
      end

      it "handles multiple code blocks with different focus lines", :aggregate_failures do
        context[:code_block_focus_lines] = [
          { 1 => true },
          { 2 => true }
        ]
        html = [
          '<div class="highlight"><pre><code>block 1 line</code></pre></div>',
          '<div class="highlight"><pre><code>block 2 line 1
block 2 line 2</code></pre></div>'
        ].join("\n")

        result = processor.postprocess(html)

        expect(result.scan("docyard-code-block--has-focus").count).to eq(2)
      end
    end

    context "with custom titles" do
      it "adds titled class and renders header when title is present", :aggregate_failures do
        context[:code_block_options] = [{ lang: "js", title: "config.js", option: nil, highlights: [] }]
        html = '<div class="highlight"><pre><code>const x = 1;</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include("docyard-code-block--titled")
        expect(result).to include('class="docyard-code-block__header"')
        expect(result).to include('class="docyard-code-block__title"')
        expect(result).to include("config.js")
      end

      it "includes title attribute on title span for native tooltip", :aggregate_failures do
        context[:code_block_options] = [{ lang: "js", title: "long/path/to/file.js", option: nil, highlights: [] }]
        html = '<div class="highlight"><pre><code>const x = 1;</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include('title="long/path/to/file.js"')
        expect(result).to include('class="docyard-code-block__title" title="long/path/to/file.js"')
      end

      it "renders file extension icon for known languages", :aggregate_failures do
        context[:code_block_options] = [{ lang: "js", title: "app.js", option: nil, highlights: [] }]
        html = '<div class="highlight"><pre><code>const x = 1;</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include('class="docyard-code-block__icon"')
        expect(result).to include("<svg")
      end

      it "renders terminal icon for shell languages", :aggregate_failures do
        context[:code_block_options] = [{ lang: "bash", title: "install.sh", option: nil, highlights: [] }]
        html = '<div class="highlight"><pre><code>echo hello</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include('class="docyard-code-block__icon"')
        expect(result).to include("docyard-icon")
      end

      it "renders file icon for unknown languages", :aggregate_failures do
        context[:code_block_options] = [{ lang: "unknownlang", title: "file.xyz", option: nil, highlights: [] }]
        html = '<div class="highlight"><pre><code>content</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include('class="docyard-code-block__icon"')
      end

      it "parses manual icon prefix from title", :aggregate_failures do
        context[:code_block_options] = [{ lang: "bash", title: ":rocket:Deploy Script", option: nil, highlights: [] }]
        html = '<div class="highlight"><pre><code>echo deploy</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include("Deploy Script")
        expect(result).not_to include(":rocket:")
        expect(result).to include('class="docyard-code-block__icon"')
      end

      it "places copy button in header when title present", :aggregate_failures do
        context[:code_block_options] = [{ lang: "js", title: "config.js", option: nil, highlights: [] }]
        html = '<div class="highlight"><pre><code>const x = 1;</code></pre></div>'

        result = processor.postprocess(html)

        header_match = result.match(%r{class="docyard-code-block__header">(.*?)</div>}m)
        expect(header_match).not_to be_nil
        expect(header_match[1]).to include('class="docyard-code-block__copy"')
      end

      it "does not render header when title is nil", :aggregate_failures do
        context[:code_block_options] = [{ lang: "js", title: nil, option: nil, highlights: [] }]
        html = '<div class="highlight"><pre><code>const x = 1;</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).not_to include("docyard-code-block--titled")
        expect(result).not_to include("docyard-code-block__header")
      end

      it "combines title with line numbers", :aggregate_failures do
        context[:code_block_options] = [{ lang: "ruby", title: "app.rb", option: ":line-numbers", highlights: [] }]
        html = '<div class="highlight"><pre><code>puts "hello"
puts "world"</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include("docyard-code-block--titled")
        expect(result).to include("docyard-code-block--line-numbers")
        expect(result).to include("docyard-code-block__header")
        expect(result).to include("docyard-code-block__lines")
        expect(result).to include("app.rb")
        expect(result).to include("<span>1</span>")
      end

      it "combines title with diff lines", :aggregate_failures do
        context[:code_block_options] = [{ lang: "js", title: "config.js", option: nil, highlights: [] }]
        context[:code_block_diff_lines] = [{ 1 => :addition }]
        html = '<div class="highlight"><pre><code>added line</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include("docyard-code-block--titled")
        expect(result).to include("docyard-code-block--diff")
        expect(result).to include("docyard-code-block__header")
        expect(result).to include("config.js")
      end

      it "combines title with highlights", :aggregate_failures do
        context[:code_block_options] = [{ lang: "ruby", title: "example.rb", option: nil, highlights: [1] }]
        html = '<div class="highlight"><pre><code>highlighted line</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to include("docyard-code-block--titled")
        expect(result).to include("docyard-code-block--highlighted")
        expect(result).to include("docyard-code-block__header")
        expect(result).to include("example.rb")
      end
    end

    context "with scroll spacer for untitled blocks" do
      it "injects scroll spacer at end of first line for untitled blocks", :aggregate_failures do
        html = <<~HTML
          <div class="highlight"><pre><code>line 1
          line 2</code></pre></div>
        HTML

        result = processor.postprocess(html)

        expect(result).to include('class="docyard-code-block__scroll-spacer"')
        expect(result).to include('aria-hidden="true"')
      end

      it "places scroll spacer at end of first line before newline" do
        html = '<div class="highlight"><pre><code>first line
second line</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).to match(%r{first line<span class="docyard-code-block__scroll-spacer".*?></span>\nsecond line})
      end

      it "does not inject scroll spacer for titled blocks" do
        context[:code_block_options] = [{ lang: "js", title: "config.js", option: nil, highlights: [] }]
        html = '<div class="highlight"><pre><code>line 1
line 2</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).not_to include('class="docyard-code-block__scroll-spacer"')
      end

      it "handles single line code blocks without newlines" do
        html = '<div class="highlight"><pre><code>single line</code></pre></div>'

        result = processor.postprocess(html)

        expect(result).not_to include('class="docyard-code-block__scroll-spacer"')
      end
    end
  end
end

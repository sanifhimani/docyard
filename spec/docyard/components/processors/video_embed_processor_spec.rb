# frozen_string_literal: true

RSpec.describe Docyard::Components::Processors::VideoEmbedProcessor do
  let(:context) { {} }
  let(:processor) { described_class.new(context) }

  describe "#preprocess" do
    context "with YouTube embed" do
      it "creates iframe with youtube-nocookie domain" do
        content = "::youtube[dQw4w9WgXcQ]"
        result = processor.preprocess(content)

        expect(result).to include("https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ")
      end

      it "wraps iframe in docyard-video container", :aggregate_failures do
        content = "::youtube[abc123]"
        result = processor.preprocess(content)

        expect(result).to include('<div class="docyard-video docyard-video--youtube"')
        expect(result).to include("</div>")
      end

      it "includes default title for accessibility" do
        content = "::youtube[abc123]"
        result = processor.preprocess(content)

        expect(result).to include('title="YouTube video player"')
      end

      it "includes allowfullscreen by default" do
        content = "::youtube[abc123]"
        result = processor.preprocess(content)

        expect(result).to include("allowfullscreen")
      end

      it "adds rel=0 param to prevent related videos" do
        content = "::youtube[abc123]"
        result = processor.preprocess(content)

        expect(result).to include("rel=0")
      end
    end

    context "with Vimeo embed" do
      it "creates iframe with player.vimeo.com domain" do
        content = "::vimeo[123456789]"
        result = processor.preprocess(content)

        expect(result).to include("https://player.vimeo.com/video/123456789")
      end

      it "wraps iframe in docyard-video container with vimeo class", :aggregate_failures do
        content = "::vimeo[123456]"
        result = processor.preprocess(content)

        expect(result).to include('<div class="docyard-video docyard-video--vimeo"')
        expect(result).to include("</div>")
      end

      it "includes default title for accessibility" do
        content = "::vimeo[123456]"
        result = processor.preprocess(content)

        expect(result).to include('title="Vimeo video player"')
      end

      it "adds dnt=1 param for privacy" do
        content = "::vimeo[123456]"
        result = processor.preprocess(content)

        expect(result).to include("dnt=1")
      end
    end

    context "with custom title" do
      it "uses custom title for YouTube" do
        content = '::youtube[abc123]{title="My Tutorial Video"}'
        result = processor.preprocess(content)

        expect(result).to include('title="My Tutorial Video"')
      end

      it "uses custom title for Vimeo" do
        content = '::vimeo[123456]{title="Product Demo"}'
        result = processor.preprocess(content)

        expect(result).to include('title="Product Demo"')
      end
    end

    context "with width attribute" do
      it "sets max-width on wrapper" do
        content = '::youtube[abc123]{width="640"}'
        result = processor.preprocess(content)

        expect(result).to include('style="max-width: 640px"')
      end
    end

    context "with height attribute" do
      it "sets height on wrapper" do
        content = '::youtube[abc123]{height="360"}'
        result = processor.preprocess(content)

        expect(result).to include('style="height: 360px"')
      end

      it "combines width and height", :aggregate_failures do
        content = '::youtube[abc123]{width="640" height="360"}'
        result = processor.preprocess(content)

        expect(result).to include("max-width: 640px")
        expect(result).to include("height: 360px")
      end
    end

    context "with autoplay attribute" do
      it "adds autoplay param for YouTube", :aggregate_failures do
        content = "::youtube[abc123]{autoplay}"
        result = processor.preprocess(content)

        expect(result).to include("autoplay=1")
        expect(result).to include('allow="autoplay')
      end

      it "adds autoplay param for Vimeo", :aggregate_failures do
        content = "::vimeo[123456]{autoplay}"
        result = processor.preprocess(content)

        expect(result).to include("autoplay=1")
        expect(result).to include('allow="autoplay')
      end
    end

    context "with loop attribute" do
      it "adds loop param for YouTube" do
        content = "::youtube[abc123]{loop}"
        result = processor.preprocess(content)

        expect(result).to include("loop=1")
      end

      it "adds loop param for Vimeo" do
        content = "::vimeo[123456]{loop}"
        result = processor.preprocess(content)

        expect(result).to include("loop=1")
      end
    end

    context "with muted attribute" do
      it "adds mute param for YouTube" do
        content = "::youtube[abc123]{muted}"
        result = processor.preprocess(content)

        expect(result).to include("mute=1")
      end

      it "adds muted param for Vimeo" do
        content = "::vimeo[123456]{muted}"
        result = processor.preprocess(content)

        expect(result).to include("muted=1")
      end
    end

    context "with controls attribute" do
      it "hides controls for YouTube when controls=false" do
        content = '::youtube[abc123]{controls="false"}'
        result = processor.preprocess(content)

        expect(result).to include("controls=0")
      end

      it "hides controls for Vimeo when controls=false" do
        content = '::vimeo[123456]{controls="false"}'
        result = processor.preprocess(content)

        expect(result).to include("controls=0")
      end
    end

    context "with start time (YouTube only)" do
      it "adds start param" do
        content = '::youtube[abc123]{start="120"}'
        result = processor.preprocess(content)

        expect(result).to include("start=120")
      end
    end

    context "with nofullscreen attribute" do
      it "removes allowfullscreen for YouTube", :aggregate_failures do
        content = "::youtube[abc123]{nofullscreen}"
        result = processor.preprocess(content)

        expect(result).not_to include("allowfullscreen")
      end

      it "removes allowfullscreen for Vimeo" do
        content = "::vimeo[123456]{nofullscreen}"
        result = processor.preprocess(content)

        expect(result).not_to include("allowfullscreen")
      end
    end

    context "with combined attributes" do
      it "handles multiple attributes together", :aggregate_failures do
        content = '::youtube[abc123]{width="800" autoplay muted loop title="Background Video"}'
        result = processor.preprocess(content)

        expect(result).to include("max-width: 800px")
        expect(result).to include("autoplay=1")
        expect(result).to include("mute=1")
        expect(result).to include("loop=1")
        expect(result).to include('title="Background Video"')
      end
    end

    context "with multiple videos" do
      it "processes all videos", :aggregate_failures do
        content = <<~MD
          ::youtube[video1]

          Some text here.

          ::vimeo[video2]
        MD

        result = processor.preprocess(content)

        expect(result).to include("youtube-nocookie.com/embed/video1")
        expect(result).to include("player.vimeo.com/video/video2")
        expect(result.scan("docyard-video").count).to eq(4)
      end
    end

    context "with surrounding content" do
      it "preserves surrounding markdown", :aggregate_failures do
        content = <<~MD
          # Video Tutorial

          Watch the video below:

          ::youtube[abc123]

          Thanks for watching!
        MD

        result = processor.preprocess(content)

        expect(result).to include("# Video Tutorial")
        expect(result).to include("Watch the video below:")
        expect(result).to include("Thanks for watching!")
        expect(result).to include("docyard-video")
      end
    end

    context "with special characters" do
      it "escapes HTML in title", :aggregate_failures do
        content = '::youtube[abc123]{title="Video <script>alert(1)</script>"}'
        result = processor.preprocess(content)

        expect(result).to include("&lt;script&gt;")
        expect(result).not_to include("<script>")
      end

      it "escapes quotes in video ID" do
        content = '::youtube[abc"123]'
        result = processor.preprocess(content)

        expect(result).to include("abc&quot;123")
      end
    end

    context "without attributes" do
      it "handles YouTube without braces" do
        content = "::youtube[simpleID]"
        result = processor.preprocess(content)

        expect(result).to include("youtube-nocookie.com/embed/simpleID")
      end

      it "handles Vimeo without braces" do
        content = "::vimeo[987654]"
        result = processor.preprocess(content)

        expect(result).to include("player.vimeo.com/video/987654")
      end
    end

    context "with markdown=0 attribute" do
      it "prevents markdown processing inside embed" do
        content = "::youtube[abc123]"
        result = processor.preprocess(content)

        expect(result).to include('markdown="0"')
      end
    end

    context "with native video embed" do
      it "creates video element with src" do
        content = "::video[/demo.mp4]"
        result = processor.preprocess(content)

        expect(result).to include('src="/demo.mp4"')
      end

      it "wraps video in docyard-video container with native class", :aggregate_failures do
        content = "::video[/demo.mp4]"
        result = processor.preprocess(content)

        expect(result).to include('<div class="docyard-video docyard-video--native"')
        expect(result).to include("<video")
        expect(result).to include("</video>")
      end

      it "includes controls by default" do
        content = "::video[/demo.mp4]"
        result = processor.preprocess(content)

        expect(result).to include("controls")
      end

      it "supports external URLs" do
        content = "::video[https://cdn.example.com/video.mp4]"
        result = processor.preprocess(content)

        expect(result).to include('src="https://cdn.example.com/video.mp4"')
      end

      it "supports local paths" do
        content = "::video[/videos/demo.webm]"
        result = processor.preprocess(content)

        expect(result).to include('src="/videos/demo.webm"')
      end

      it "adds poster to video element" do
        content = '::video[/demo.mp4]{poster="/poster.jpg"}'
        result = processor.preprocess(content)

        expect(result).to include('poster="/poster.jpg"')
      end

      it "adds preload to video element" do
        content = '::video[/demo.mp4]{preload="metadata"}'
        result = processor.preprocess(content)

        expect(result).to include('preload="metadata"')
      end

      it "adds autoplay to video element" do
        content = "::video[/demo.mp4]{autoplay}"
        result = processor.preprocess(content)

        expect(result).to include("autoplay")
      end

      it "adds muted to video element" do
        content = "::video[/demo.mp4]{muted}"
        result = processor.preprocess(content)

        expect(result).to include("muted")
      end

      it "adds loop to video element" do
        content = "::video[/demo.mp4]{loop}"
        result = processor.preprocess(content)

        expect(result).to include("loop")
      end

      it "adds playsinline to video element" do
        content = "::video[/demo.mp4]{playsinline}"
        result = processor.preprocess(content)

        expect(result).to include("playsinline")
      end

      it "removes controls when controls=false" do
        content = '::video[/demo.mp4]{controls="false"}'
        result = processor.preprocess(content)

        expect(result).not_to include("controls")
      end

      it "sets max-width on wrapper with width attribute" do
        content = '::video[/demo.mp4]{width="640"}'
        result = processor.preprocess(content)

        expect(result).to include('style="max-width: 640px"')
      end

      it "handles background video setup", :aggregate_failures do
        content = '::video[/bg.mp4]{autoplay muted loop playsinline controls="false"}'
        result = processor.preprocess(content)

        expect(result).to include("autoplay")
        expect(result).to include("muted")
        expect(result).to include("loop")
        expect(result).to include("playsinline")
        expect(result).not_to match(/<video[^>]*controls[^>]*>/)
      end

      it "handles full-featured video", :aggregate_failures do
        content = '::video[/demo.mp4]{poster="/thumb.jpg" width="800" preload="metadata"}'
        result = processor.preprocess(content)

        expect(result).to include('poster="/thumb.jpg"')
        expect(result).to include("max-width: 800px")
        expect(result).to include('preload="metadata"')
        expect(result).to include("controls")
      end

      it "escapes HTML in src" do
        content = "::video[/demo<script>.mp4]"
        result = processor.preprocess(content)

        expect(result).to include("&lt;script&gt;")
      end

      it "escapes HTML in poster" do
        content = '::video[/demo.mp4]{poster="/img<script>.jpg"}'
        result = processor.preprocess(content)

        expect(result).to include("&lt;script&gt;")
      end
    end

    context "with mixed video types" do
      it "processes all video types together", :aggregate_failures do
        content = <<~MD
          ::youtube[yt123]

          ::vimeo[vim456]

          ::video[/local.mp4]
        MD

        result = processor.preprocess(content)

        expect(result).to include("youtube-nocookie.com/embed/yt123")
        expect(result).to include("player.vimeo.com/video/vim456")
        expect(result).to include('src="/local.mp4"')
        expect(result.scan("docyard-video--youtube").count).to eq(1)
        expect(result.scan("docyard-video--vimeo").count).to eq(1)
        expect(result.scan("docyard-video--native").count).to eq(1)
      end
    end
  end
end

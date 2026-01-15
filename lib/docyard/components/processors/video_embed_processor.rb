# frozen_string_literal: true

require_relative "../base_processor"

module Docyard
  module Components
    module Processors
      class VideoEmbedProcessor < BaseProcessor
        YOUTUBE_PATTERN = /::youtube\[([^\]]+)\](?:\{([^}]*)\})?/
        VIMEO_PATTERN = /::vimeo\[([^\]]+)\](?:\{([^}]*)\})?/
        VIDEO_PATTERN = /::video\[([^\]]+)\](?:\{([^}]*)\})?/

        self.priority = 5

        def preprocess(content)
          result = content.gsub(YOUTUBE_PATTERN) do
            video_id = Regexp.last_match(1)
            attrs_string = Regexp.last_match(2)
            build_youtube_embed(video_id, parse_attributes(attrs_string))
          end

          result = result.gsub(VIMEO_PATTERN) do
            video_id = Regexp.last_match(1)
            attrs_string = Regexp.last_match(2)
            build_vimeo_embed(video_id, parse_attributes(attrs_string))
          end

          result.gsub(VIDEO_PATTERN) do
            src = Regexp.last_match(1)
            attrs_string = Regexp.last_match(2)
            build_native_video(src, parse_attributes(attrs_string))
          end
        end

        private

        def parse_attributes(attrs_string)
          return {} if attrs_string.nil? || attrs_string.empty?

          attrs = {}

          attrs_string.scan(/(\w+)="([^"]*)"/) do |key, value|
            attrs[key] = value
          end

          %w[autoplay loop muted nofullscreen controls playsinline].each do |flag|
            attrs[flag] = true if attrs_string.match?(/\b#{flag}\b/) && !attrs.key?(flag)
          end

          attrs
        end

        def build_youtube_embed(video_id, attrs)
          params = youtube_params(attrs)
          url = "https://www.youtube-nocookie.com/embed/#{escape_attr(video_id)}"
          url += "?#{params.join('&')}" unless params.empty?

          build_iframe(url, attrs, "youtube")
        end

        def build_vimeo_embed(video_id, attrs)
          params = vimeo_params(attrs)
          url = "https://player.vimeo.com/video/#{escape_attr(video_id)}"
          url += "?#{params.join('&')}" unless params.empty?

          build_iframe(url, attrs, "vimeo")
        end

        def build_native_video(src, attrs)
          wrapper_style = build_wrapper_style(attrs)
          video_attrs = build_video_attrs(src, attrs)

          "\n\n" \
            "<div class=\"docyard-video docyard-video--native\"#{wrapper_style} markdown=\"0\">\n  " \
            "<video #{video_attrs.join(' ')}></video>\n" \
            "</div>" \
            "\n\n"
        end

        def build_video_attrs(src, attrs)
          video_attrs = ["src=\"#{escape_attr(src)}\""]
          video_attrs.concat(video_optional_attrs(attrs))
          video_attrs.concat(video_boolean_attrs(attrs))
          video_attrs
        end

        def video_optional_attrs(attrs)
          result = []
          result << "poster=\"#{escape_attr(attrs['poster'])}\"" if attrs["poster"]
          result << "preload=\"#{escape_attr(attrs['preload'])}\"" if attrs["preload"]
          result
        end

        def video_boolean_attrs(attrs)
          result = []
          result << "controls" unless controls_disabled?(attrs)
          result << "autoplay" if attrs["autoplay"]
          result << "muted" if attrs["muted"]
          result << "loop" if attrs["loop"]
          result << "playsinline" if attrs["playsinline"]
          result
        end

        def controls_disabled?(attrs)
          ["false", false].include?(attrs["controls"])
        end

        def youtube_params(attrs)
          params = []
          params << "autoplay=1" if attrs["autoplay"]
          params << "loop=1" if attrs["loop"]
          params << "mute=1" if attrs["muted"]
          params << "controls=0" if ["false", false].include?(attrs["controls"])
          params << "start=#{attrs['start']}" if attrs["start"]
          params << "rel=0"
          params
        end

        def vimeo_params(attrs)
          params = []
          params << "autoplay=1" if attrs["autoplay"]
          params << "loop=1" if attrs["loop"]
          params << "muted=1" if attrs["muted"]
          params << "controls=0" if ["false", false].include?(attrs["controls"])
          params << "dnt=1"
          params
        end

        def build_iframe(url, attrs, provider)
          wrapper_style = build_wrapper_style(attrs)
          iframe_attrs = build_iframe_attrs(url, attrs, provider)

          "\n\n" \
            "<div class=\"docyard-video docyard-video--#{provider}\"#{wrapper_style} markdown=\"0\">\n  " \
            "<iframe #{iframe_attrs.join(' ')}></iframe>\n" \
            "</div>" \
            "\n\n"
        end

        def build_wrapper_style(attrs)
          return "" unless attrs["width"] || attrs["height"]

          styles = []
          styles << "max-width: #{escape_attr(attrs['width'])}px" if attrs["width"]
          styles << "height: #{escape_attr(attrs['height'])}px" if attrs["height"]
          " style=\"#{styles.join('; ')}\""
        end

        def build_iframe_attrs(url, attrs, provider)
          iframe_attrs = [
            "src=\"#{url}\"",
            "title=\"#{escape_attr(attrs['title'] || default_title(provider))}\"",
            "frameborder=\"0\""
          ]

          iframe_attrs << "allow=\"#{build_allow_attr(attrs)}\""
          iframe_attrs << "allowfullscreen" unless attrs["nofullscreen"]

          iframe_attrs
        end

        def build_allow_attr(attrs)
          permissions = %w[encrypted-media picture-in-picture web-share]
          permissions.unshift("autoplay") if attrs["autoplay"]
          permissions << "fullscreen" unless attrs["nofullscreen"]
          permissions.join("; ")
        end

        def default_title(provider)
          case provider
          when "youtube" then "YouTube video player"
          when "vimeo" then "Vimeo video player"
          else "Video player"
          end
        end

        def escape_attr(text)
          text.to_s
            .gsub("&", "&amp;")
            .gsub("<", "&lt;")
            .gsub(">", "&gt;")
            .gsub('"', "&quot;")
        end
      end
    end
  end
end

# frozen_string_literal: true

module Docyard
  module Components
    class CodeLineParser
      def initialize(code_content)
        @code_content = code_content
        @lines = []
        @current_line = ""
        @in_tag = false
        @tag_buffer = ""
      end

      def parse
        @code_content.each_char { |char| process_char(char) }
        finalize
      end

      private

      def process_char(char)
        case char
        when "<" then start_tag(char)
        when ">" then end_tag_if_applicable(char)
        when "\n" then handle_newline
        else handle_regular_char(char)
        end
      end

      def start_tag(char)
        @in_tag = true
        @tag_buffer = char
      end

      def end_tag_if_applicable(char)
        if @in_tag
          @in_tag = false
          @tag_buffer += char
          @current_line += @tag_buffer
          @tag_buffer = ""
        else
          @current_line += char
        end
      end

      def handle_newline
        @lines << "#{@current_line}\n"
        @current_line = ""
      end

      def handle_regular_char(char)
        if @in_tag
          @tag_buffer += char
        else
          @current_line += char
        end
      end

      def finalize
        @lines << @current_line unless @current_line.empty?
        @lines << "" if @lines.empty?
        @lines
      end
    end
  end
end

# frozen_string_literal: true

module Docyard
  class Doctor
    class ComponentChecker
      CALLOUT_TYPES = %w[note tip important warning danger].freeze
      KNOWN_COMPONENTS = %w[tabs cards steps code-group details].freeze
      ALL_CONTAINER_TYPES = (CALLOUT_TYPES + KNOWN_COMPONENTS).freeze
      CONTAINER_PATTERN = /^:::(\w[\w-]*)/
      CLOSE_PATTERN = /^:::\s*$/
      CODE_FENCE_REGEX = /^(`{3,}|~{3,})/
      TAB_ITEM_PATTERN = /^==\s+.+/
      CARD_ITEM_PATTERN = /^::card\{/
      STEP_ITEM_PATTERN = /^###\s+.+/
      CARD_ATTR_PATTERN = /^::card\{([^}]*)\}/
      CARD_VALID_ATTRS = %w[title icon href].freeze

      attr_reader :docs_path

      def initialize(docs_path)
        @docs_path = docs_path
      end

      def check
        markdown_files.flat_map { |file| check_file(file) }
      end

      private

      def markdown_files
        Dir.glob(File.join(docs_path, "**", "*.md"))
      end

      def check_file(file_path)
        relative_file = file_path.delete_prefix("#{docs_path}/")
        content = File.read(file_path)
        blocks = parse_blocks(content)

        diagnostics = []
        diagnostics.concat(check_callouts(blocks, content, relative_file))
        diagnostics.concat(check_tabs(blocks, content, relative_file))
        diagnostics.concat(check_cards(blocks, content, relative_file))
        diagnostics.concat(check_steps(blocks, content, relative_file))
        diagnostics.concat(check_unknown_types(content, relative_file))
        diagnostics
      end

      def parse_blocks(content)
        blocks = []
        open_blocks = []
        in_code_block = false

        content.each_line.with_index(1) do |line, line_number|
          in_code_block = !in_code_block if line.match?(CODE_FENCE_REGEX)
          next if in_code_block

          process_block_line(line, line_number, open_blocks, blocks)
        end

        open_blocks.each { |b| b[:closed] = false }
        blocks + open_blocks
      end

      def process_block_line(line, line_number, open_blocks, blocks)
        if (match = line.match(CONTAINER_PATTERN))
          open_blocks.push({ type: match[1].downcase, line: line_number, closed: true })
        elsif line.match?(CLOSE_PATTERN) && open_blocks.any?
          blocks.push(open_blocks.pop)
        end
      end

      def extract_block_content(content, start_line)
        lines = content.lines
        start_idx = start_line
        end_idx = lines[start_idx..].find_index { |l| l.match?(CLOSE_PATTERN) }
        return nil unless end_idx

        lines[start_idx...(start_idx + end_idx)].join
      end

      def each_line_outside_code_blocks(content)
        return enum_for(__method__, content) unless block_given?

        in_code_block = false
        content.each_line.with_index(1) do |line, line_number|
          in_code_block = !in_code_block if line.match?(CODE_FENCE_REGEX)
          yield line, line_number unless in_code_block
        end
      end

      def check_callouts(blocks, content, relative_file)
        callout_blocks = blocks.select { |b| CALLOUT_TYPES.include?(b[:type]) }
        callout_blocks.flat_map { |block| validate_callout(block, content, relative_file) }.compact
      end

      def validate_callout(block, content, relative_file)
        return build_unclosed_diagnostic("CALLOUT", block, relative_file) unless block[:closed]

        block_content = extract_block_content(content, block[:line])
        return nil unless block_content&.strip&.empty?

        build_diagnostic("CALLOUT_EMPTY", "empty callout block", relative_file, block[:line])
      end

      def check_tabs(blocks, content, relative_file)
        tabs_blocks = blocks.select { |b| b[:type] == "tabs" }
        tabs_blocks.flat_map { |block| validate_tabs(block, content, relative_file) }.compact
      end

      def validate_tabs(block, content, relative_file)
        return build_unclosed_diagnostic("TABS", block, relative_file) unless block[:closed]

        block_content = extract_block_content(content, block[:line])
        return nil if block_content&.match?(TAB_ITEM_PATTERN)

        msg = "empty tabs block, add '== Tab Name' to define tabs"
        build_diagnostic("TABS_EMPTY", msg, relative_file, block[:line])
      end

      def check_cards(blocks, content, relative_file)
        cards_blocks = blocks.select { |b| b[:type] == "cards" }
        diagnostics = cards_blocks.flat_map { |block| validate_cards(block, content, relative_file) }
        diagnostics.concat(check_card_attributes(content, relative_file))
        diagnostics.compact
      end

      def validate_cards(block, content, relative_file)
        return build_unclosed_diagnostic("CARDS", block, relative_file) unless block[:closed]

        block_content = extract_block_content(content, block[:line])
        return nil if block_content&.match?(CARD_ITEM_PATTERN)

        msg = "empty cards block, add '::card{title=\"...\"}' to define cards"
        build_diagnostic("CARDS_EMPTY", msg, relative_file, block[:line])
      end

      def check_card_attributes(content, relative_file)
        each_line_outside_code_blocks(content).flat_map do |line, line_number|
          match = line.match(CARD_ATTR_PATTERN)
          next [] unless match

          validate_card_attrs(match[1], relative_file, line_number)
        end
      end

      def validate_card_attrs(attr_string, relative_file, line_number)
        attrs = attr_string.scan(/(\w+)=/).flatten
        unknown = attrs - CARD_VALID_ATTRS

        unknown.map do |attr|
          suggestion = find_card_attr_suggestion(attr)
          message = "unknown card attribute '#{attr}'"
          message += ", did you mean '#{suggestion}'?" if suggestion
          build_diagnostic("CARD_UNKNOWN_ATTR", message, relative_file, line_number)
        end
      end

      def find_card_attr_suggestion(attr)
        DidYouMean::SpellChecker.new(dictionary: CARD_VALID_ATTRS).correct(attr).first
      end

      def check_steps(blocks, content, relative_file)
        steps_blocks = blocks.select { |b| b[:type] == "steps" }
        steps_blocks.flat_map { |block| validate_steps(block, content, relative_file) }.compact
      end

      def validate_steps(block, content, relative_file)
        return build_unclosed_diagnostic("STEPS", block, relative_file) unless block[:closed]

        block_content = extract_block_content(content, block[:line])
        return nil if block_content&.match?(STEP_ITEM_PATTERN)

        msg = "empty steps block, add '### Step Title' to define steps"
        build_diagnostic("STEPS_EMPTY", msg, relative_file, block[:line])
      end

      def build_unclosed_diagnostic(prefix, block, relative_file)
        build_diagnostic("#{prefix}_UNCLOSED", "unclosed :::#{block[:type]} block", relative_file, block[:line])
      end

      def check_unknown_types(content, relative_file)
        each_line_outside_code_blocks(content).filter_map do |line, line_number|
          match = line.match(CONTAINER_PATTERN)
          next unless match

          type = match[1].downcase
          next if ALL_CONTAINER_TYPES.include?(type)

          build_unknown_type_diagnostic(type, relative_file, line_number)
        end
      end

      def build_unknown_type_diagnostic(type, relative_file, line_number)
        suggestion = find_suggestion(type)
        message = "unknown component ':::#{type}'"
        message += ", did you mean ':::#{suggestion}'?" if suggestion

        build_diagnostic("COMPONENT_UNKNOWN_TYPE", message, relative_file, line_number)
      end

      def find_suggestion(type)
        DidYouMean::SpellChecker.new(dictionary: ALL_CONTAINER_TYPES).correct(type).first
      end

      def build_diagnostic(code, message, file, line)
        Diagnostic.new(
          severity: :warning,
          category: :COMPONENT,
          code: code,
          message: message,
          file: file,
          line: line
        )
      end
    end
  end
end

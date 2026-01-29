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
      CODE_BLOCK_WITH_LABEL = /^```\w*\s*\[/
      CODE_BLOCK_START = /^```(\w+)/

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

        [
          check_callouts(blocks, content, relative_file),
          check_tabs(blocks, content, relative_file),
          check_cards(blocks, content, relative_file),
          check_steps(blocks, content, relative_file),
          check_code_group(blocks, content, relative_file),
          check_unknown_types(content, relative_file)
        ].flatten
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
        end_idx = lines[start_line..].find_index { |l| l.match?(CLOSE_PATTERN) }
        end_idx ? lines[start_line...(start_line + end_idx)].join : nil
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
        filter_blocks(blocks, CALLOUT_TYPES).flat_map do |block|
          validate_simple_block(block, content, relative_file, "CALLOUT") do |block_content|
            block_content&.strip&.empty? ? "empty callout block" : nil
          end
        end.compact
      end

      def check_tabs(blocks, content, relative_file)
        filter_blocks(blocks, "tabs").flat_map do |block|
          validate_simple_block(block, content, relative_file, "TABS") do |block_content|
            block_content&.match?(TAB_ITEM_PATTERN) ? nil : "empty tabs block, add '== Tab Name' to define tabs"
          end
        end.compact
      end

      def check_cards(blocks, content, relative_file)
        block_diags = filter_blocks(blocks, "cards").flat_map do |block|
          validate_simple_block(block, content, relative_file, "CARDS") do |bc|
            bc&.match?(CARD_ITEM_PATTERN) ? nil : "empty cards block, add '::card{title=\"...\"}' to define cards"
          end
        end
        (block_diags + check_card_attributes(content, relative_file)).compact
      end

      def check_card_attributes(content, relative_file)
        each_line_outside_code_blocks(content).flat_map do |line, line_number|
          (match = line.match(CARD_ATTR_PATTERN)) ? validate_card_attrs(match[1], relative_file, line_number) : []
        end
      end

      def validate_card_attrs(attr_string, relative_file, line_number)
        unknown = attr_string.scan(/(\w+)=/).flatten - CARD_VALID_ATTRS
        unknown.map do |attr|
          suggestion = DidYouMean::SpellChecker.new(dictionary: CARD_VALID_ATTRS).correct(attr).first
          msg = "unknown card attribute '#{attr}'"
          msg += ", did you mean '#{suggestion}'?" if suggestion
          build_diagnostic("CARD_UNKNOWN_ATTR", msg, relative_file, line_number)
        end
      end

      def check_steps(blocks, content, relative_file)
        filter_blocks(blocks, "steps").flat_map do |block|
          validate_simple_block(block, content, relative_file, "STEPS") do |block_content|
            block_content&.match?(STEP_ITEM_PATTERN) ? nil : "empty steps block, add '### Step Title' to define steps"
          end
        end.compact
      end

      def filter_blocks(blocks, type_filter)
        blocks.select { |b| type_filter.is_a?(Array) ? type_filter.include?(b[:type]) : b[:type] == type_filter }
      end

      def validate_simple_block(block, content, relative_file, prefix)
        return build_unclosed_diagnostic(prefix, block, relative_file) unless block[:closed]

        block_content = extract_block_content(content, block[:line])
        error_msg = yield(block_content)
        error_msg ? build_diagnostic("#{prefix}_EMPTY", error_msg, relative_file, block[:line]) : nil
      end

      def check_code_group(blocks, content, relative_file)
        filter_blocks(blocks, "code-group").flat_map { |b| validate_code_group(b, content, relative_file) }.compact
      end

      def validate_code_group(block, content, relative_file)
        return build_unclosed_diagnostic("CODE_GROUP", block, relative_file) unless block[:closed]

        block_content = extract_block_content(content, block[:line])
        return empty_code_group_diagnostic(relative_file, block) unless block_content&.match?(CODE_BLOCK_WITH_LABEL)

        check_unlabeled_code_blocks(block_content, relative_file, block[:line])
      end

      def empty_code_group_diagnostic(relative_file, block)
        build_diagnostic("CODE_GROUP_EMPTY", "empty code-group, add code blocks with [labels]", relative_file, block[:line])
      end

      def check_unlabeled_code_blocks(block_content, relative_file, start_line)
        block_content.each_line.with_index(1).filter_map do |line, offset|
          next unless line.match?(CODE_BLOCK_START) && !line.match?(CODE_BLOCK_WITH_LABEL)

          build_diagnostic("CODE_GROUP_MISSING_LABEL", "code block missing label", relative_file, start_line + offset)
        end
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

          suggestion = DidYouMean::SpellChecker.new(dictionary: ALL_CONTAINER_TYPES).correct(type).first
          msg = "unknown component ':::#{type}'"
          msg += ", did you mean ':::#{suggestion}'?" if suggestion
          build_diagnostic("COMPONENT_UNKNOWN_TYPE", msg, relative_file, line_number)
        end
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

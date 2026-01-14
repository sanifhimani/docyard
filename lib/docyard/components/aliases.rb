# frozen_string_literal: true

module Docyard
  module Components
    AccordionProcessor = Processors::AccordionProcessor
    CalloutProcessor = Processors::CalloutProcessor
    CodeBlockProcessor = Processors::CodeBlockProcessor
    CodeBlockDiffPreprocessor = Processors::CodeBlockDiffPreprocessor
    CodeBlockFocusPreprocessor = Processors::CodeBlockFocusPreprocessor
    CodeBlockOptionsPreprocessor = Processors::CodeBlockOptionsPreprocessor
    CodeSnippetImportPreprocessor = Processors::CodeSnippetImportPreprocessor
    HeadingAnchorProcessor = Processors::HeadingAnchorProcessor
    IconProcessor = Processors::IconProcessor
    TableOfContentsProcessor = Processors::TableOfContentsProcessor
    TableWrapperProcessor = Processors::TableWrapperProcessor
    TabsProcessor = Processors::TabsProcessor

    CodeDetector = Support::CodeDetector
    IconDetector = Support::Tabs::IconDetector

    CodeBlockFeatureExtractor = Support::CodeBlock::FeatureExtractor
    CodeBlockIconDetector = Support::CodeBlock::IconDetector
    CodeBlockLineWrapper = Support::CodeBlock::LineWrapper
    CodeBlockPatterns = Support::CodeBlock::Patterns
    CodeLineParser = Support::CodeBlock::LineParser

    TabsParser = Support::Tabs::Parser
    TabsRangeFinder = Support::Tabs::RangeFinder
  end
end

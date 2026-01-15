# frozen_string_literal: true

module Docyard
  module Components
    AbbreviationProcessor = Processors::AbbreviationProcessor
    AccordionProcessor = Processors::AccordionProcessor
    BadgeProcessor = Processors::BadgeProcessor
    StepsProcessor = Processors::StepsProcessor
    CardsProcessor = Processors::CardsProcessor
    CalloutProcessor = Processors::CalloutProcessor
    CodeBlockProcessor = Processors::CodeBlockProcessor
    CodeGroupProcessor = Processors::CodeGroupProcessor
    CodeBlockDiffPreprocessor = Processors::CodeBlockDiffPreprocessor
    CodeBlockFocusPreprocessor = Processors::CodeBlockFocusPreprocessor
    CodeBlockOptionsPreprocessor = Processors::CodeBlockOptionsPreprocessor
    CodeSnippetImportPreprocessor = Processors::CodeSnippetImportPreprocessor
    CustomAnchorProcessor = Processors::CustomAnchorProcessor
    ImageCaptionProcessor = Processors::ImageCaptionProcessor
    IncludeProcessor = Processors::IncludeProcessor
    VideoEmbedProcessor = Processors::VideoEmbedProcessor
    FileTreeProcessor = Processors::FileTreeProcessor
    HeadingAnchorProcessor = Processors::HeadingAnchorProcessor
    IconProcessor = Processors::IconProcessor
    TableOfContentsProcessor = Processors::TableOfContentsProcessor
    TableWrapperProcessor = Processors::TableWrapperProcessor
    TabsProcessor = Processors::TabsProcessor
    TooltipProcessor = Processors::TooltipProcessor

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

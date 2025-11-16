# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2025-01-16

### Added
- **Static site generation** - Build system with `docyard build` command (#27)
- **Preview server** - Test builds locally with `docyard preview` command (#27)
- **Asset bundling** - CSS/JS minification with content hashing for cache busting (#27)
- **SEO files** - Automatic generation of sitemap.xml and robots.txt (#27)
- **Base URL support** - Deploy to subdirectories with configurable base_url (#27)
- **Sidebar customization** - Config-driven navigation with custom ordering, icons, and external links (#26)
- **Improved init templates** - Practical, helpful templates showcasing all features (#28)
- **Clean init output** - Minimal, helpful success message with clear next steps (#28)

### Changed
- Init command now creates focused, practical templates (4 files vs 9 previously) (#28)
- Templates now only include implemented features (no images/HTML/escaping) (#28)
- Config file (docyard.yml) is cleaner with better comments and examples (#28)

### Fixed
- Code block CSS transition performance with GPU acceleration (#25)
- Component CSS accessibility and performance improvements (#24)
- Table responsive styling with proper wrapper element (#23)

## [0.3.0] - 2025-01-09

### Added
- Configuration system with optional `docyard.yml` file (#20)
- Logo and favicon support with light/dark mode switching (#21)
- Dark mode with theme toggle and system preference detection (#14)
- Icon system with 24 Phosphor icons and `:icon:` syntax (#15)
- Callouts/Admonitions with 5 types (note, tip, important, warning, danger) (#16)
- Tabs component with keyboard navigation and icon auto-detection (#17, #18)
- Copy button for code blocks with visual feedback (#19)
- Component-based architecture with processors for extensibility
- Asset handler with dynamic concatenation of component files

### Changed
- CSS architecture now uses CSS variables for comprehensive theming
- Markdown processing enhanced with preprocessor/postprocessor pattern

## [0.2.0] - 2025-11-08

### Added
- Automatic sidebar navigation with nested folders
- Collapsible sidebar sections with active page highlighting
- Sidebar scroll position persistence
- Modern responsive theme with mobile hamburger menu
- Structured logging system with configurable levels
- Custom error classes for better error handling
- Constants module for shared application values
- Utility modules for path resolution and text formatting
- Improved initial templates with nested docs structure

### Changed
- Refactored sidebar rendering to use partial templates
- Modular CSS architecture (split into variables, reset, typography, components, layout)
- Enhanced router with routing resolution result pattern

### Removed
- Legacy syntax.css in favor of modular code.css

## [0.1.0] - 2025-11-04

### Added
- Hot reload
- GitHub Flavored Markdown support (tables, task lists, strikethrough)
- Syntax highlighting for 100+ languages via Rouge
- YAML frontmatter for page metadata
- Customizable 404/500 error templates
- CLI commands: `docyard init`, `docyard serve`
- File watcher for live reload
- Directory traversal protection in asset handler

## [0.0.1] - 2025-11-03

### Added
- Initial gem structure
- Project scaffolding

[Unreleased]: https://github.com/sanifhimani/docyard/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/sanifhimani/docyard/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/sanifhimani/docyard/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/sanifhimani/docyard/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/sanifhimani/docyard/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/sanifhimani/docyard/releases/tag/v0.0.1

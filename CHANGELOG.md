# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/sanifhimani/docyard/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/sanifhimani/docyard/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/sanifhimani/docyard/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/sanifhimani/docyard/releases/tag/v0.0.1

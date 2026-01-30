# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-01-30

### Added
- **Doctor Command** - Health check CLI with `docyard doctor` to find broken links, missing images, orphan pages, and config issues (#135)
- **Auto-fix** - Automatically fix common issues with `docyard doctor --fix` including typos, string booleans, and missing slashes (#135)
- **Config Validation** - Validate `docyard.yml` and `_sidebar.yml` with helpful error messages and suggestions (#138)
- **Dev Server Error Overlay** - Bottom sheet overlay showing errors with syntax-highlighted code snippets, line numbers, and clickable file paths (#143)
- **Strict Mode** - Fail builds on validation errors with `--strict` flag or `build.strict` config (#143)
- **Colored CLI Output** - ANSI colors for better readability with `--no-color` flag and `NO_COLOR` env support (#142)
- **CLI Progress Spinners** - Animated spinners and step-by-step progress display for build and serve commands (#136)
- **Verbose Timing Breakdown** - Per-page timing in `docyard build --verbose` output (#141)

### Fixed
- "Last updated" timestamps now calculate relative time client-side for accurate display (#134)

### Changed
- Build output format updated with progress indicators (#136, #141)
- Config validation now runs on every build (#138)

### Documentation
- Added `docyard doctor` command reference
- Added strict mode documentation to CLI and configuration references
- Added error overlay mention to dev server documentation
- Updated build output examples to match current format

## [1.0.2] - 2026-01-23

### Fixed
- "Last updated" timestamps now show correct dates when deploying via CI (#129)

### Documentation
- Added git history requirements for accurate timestamps on GitHub Actions, Vercel, and Netlify

## [1.0.1] - 2026-01-22

### Added
- **Root Fallback Redirect** - Auto-redirect to first page when no index.md exists (#127)

### Fixed
- Breadcrumb sections without index pages now link to first navigable child (#126)
- Error pages (404/500) now use custom branding colors (#125)
- Base URL now correctly applied to all assets including fonts and search (#124)
- Dev server no longer applies build.base config, always uses root path (#123)

## [1.0.0] - 2026-01-22

### Added
- **Custom Social Links** - Add custom social icons with Phosphor icons or inline SVG via `socials.custom` config (#119)
- **Branding Colors** - Customize primary color theme with `branding.color` supporting light/dark variants (#115)
- **Custom Hero Visuals** - Use custom images/components in landing page hero sections (#114)
- **Feedback Widget** - Collect user feedback on documentation pages (#107)
- **Phosphor Icons CDN** - Load icons from CDN for smaller bundle size (#106)
- **LLMs.txt Generation** - Auto-generate llms.txt files for AI indexing (#105)
- **Copy Page Button** - One-click copy entire page content for LLM context (#104)
- **Configurable Docs Path** - Customize source directory with `source` config option (#101)
- **Parallel Builds** - Multi-threaded site generation for faster builds (#89)
- **Analytics Integration** - Support for Google Analytics, Plausible, Fathom, and custom scripts (#77)
- **Git Integration** - "Edit on GitHub" links and "Last updated" timestamps from git history (#76)
- **Open Graph Meta Tags** - Auto-generated social sharing metadata (#75)
- **Custom Error Pages** - Styled 404 and error pages (#78)
- **GitHub Pages Workflow** - CI workflow for automated deployments (#117)

### Changed
- **Domain Migration** - Project domain changed from docyard.org to docyard.dev (#118)
- **Init Command Revamp** - Improved scaffolding with better defaults (#109)
- **Puma Web Server** - Migrated to Puma for better performance (#84)
- **Search Optimization** - Improved search indexing and relevance (#86)
- **Sidebar Caching** - Faster rebuilds with sidebar state caching (#85)

### Fixed
- Video embed dimension validation (#103)
- Mobile navigation issues (#102)
- Banner layout padding on tablet/mobile (#88)
- TOC dropdown behavior (#87)
- Flash of unstyled content (FOUC) prevention (#79)
- Security and error handling improvements (#99, #100)

### Performance
- Parallel build support for multi-core systems (#89)
- Batch git operations for faster metadata lookup (#91)
- Dev server cache headers (#92)
- Passive event listeners for smoother scrolling (#93)
- Analytics domain preconnect hints (#83)
- CSS will-change hints for animations (#82)
- Font display swap for faster text rendering (#81)
- Deferred script loading (#80)

## [0.9.0] - 2026-01-15

### Added
- **Accordions** - Collapsible content sections with `:::details{title="..."}` syntax (#62)
- **Steps** - Numbered step-by-step instructions with `:::steps` syntax and vertical connector lines (#63)
- **Cards** - Grid of linked content blocks with `:::cards` and `::card{title="" icon="" href=""}` syntax (#64)
- **Badges** - Inline status indicators with `:badge[text]{type="success|warning|danger"}` syntax (#65)
- **Sidebar Badges** - Navigation labels via frontmatter `sidebar.badge` and `sidebar.badge_type` (#66)
- **Announcement Banner** - Dismissible top banner with optional action button via config (#56)
- **Markdown Inclusion** - Include content from other files with `<!--@include: ./file.md-->` syntax (#57)
- **Custom Anchor IDs** - Override auto-generated heading IDs with `## Heading {#custom-id}` syntax (#58)
- **Image Captions** - Figure elements with captions using `![](image.png){caption="..."}` syntax (#59)
- **Video Embeds** - YouTube and Vimeo embedding with `::youtube[ID]` and `::vimeo[ID]` syntax (#60)
- **File Tree** - Display directory structures with icons using `filetree` code blocks (#67)
- **Tooltips** - Inline hover definitions with `:tooltip[term]{description="..."}` syntax (#68)
- **Abbreviations** - Auto-expanding terms with `*[TERM]: Definition` syntax (#68)
- **Code Groups** - Tabbed code blocks with `:::code-group` syntax, syncs selection across page (#70)

### Fixed
- **Copy Button Overlap** - Repositioned copy button to prevent overlapping code content in non-titled blocks (#71)
- **Code Fence Protection** - Preprocessors now skip content inside fenced code blocks, allowing documentation to show raw syntax examples (#72)

## [0.8.0] - 2026-01-13

### Added
- **Landing Pages** - Hero sections, feature grids, and custom footer layouts for documentation homepages (#45)
- **Tab Navigation** - Top-level navigation tabs for organizing documentation into sections like Guide, API, Components (#52)
- **Header CTAs** - Configurable call-to-action buttons in the header with primary/secondary variants (#51)
- **Breadcrumbs** - Path navigation with auto-truncation for deep nesting and configurable via `navigation.breadcrumbs` (#54)
- **Doc Page Footer** - Social icons, "Built with Docyard" attribution, and copyright text in TOC column (#55)
- **Auto-detect Branding** - Automatic logo and favicon detection from `docs/public/` directory (#49)
- **Social Icon Mapping** - 16 social platform icons with automatic platform-to-icon mapping (#55)

### Changed
- **Sidebar Overhaul** - Per-section `_sidebar.yml` files, improved collapsible behavior, and better active state handling (#50, #53)
- **Config Schema** - Reorganized configuration with `branding`, `navigation`, and `socials` sections (#48)
- **Sidebar Convention** - Section-based sidebar configuration in `docs/<section>/_sidebar.yml` (#47)
- **UI Refresh** - Updated typography, spacing, and visual consistency across components (#44)
- **Logo Update** - New logo with cyan accent and dark mode support (#46)

## [0.7.0] - 2026-01-01

### Added
- **Full-text Search** - Pagefind-powered search with Cmd/Ctrl+K modal, keyboard navigation, and highlighting (#41)
- **Search Configuration** - Customize placeholder text, enable/disable search, and exclude paths via `docyard.yml` (#41)
- **Dev Server Search** - Opt-in search indexing during development with `--search` flag (#41)

### Changed
- Major codebase reorganization for improved maintainability (#42)
- Components reorganized into `processors/` and `support/` subdirectories (#42)
- Consolidated `server/`, `rendering/`, `navigation/`, `config/`, and `search/` modules (#42)
- Extracted shared utilities into `utils/` module (#42)

## [0.6.0] - 2025-12-25

### Added
- **Line Numbers** - Display line numbers on code blocks with `:line-numbers` or `:line-numbers=N` syntax, plus global config option (#33)
- **Line Highlighting** - Highlight specific lines in code blocks with `{1,3,5-7}` syntax (#34)
- **Diff Markers** - Show additions/deletions with `// [!code ++]` and `// [!code --]` comments, supports all major comment styles (#35)
- **Code Block Titles** - Add filename titles to code blocks with `[filename.js]` syntax, auto-detects file icons (#36)
- **Focus Mode** - Dim surrounding code with `// [!code focus]` to highlight important lines (#37)
- **Error/Warning Markers** - Highlight problematic lines with `// [!code error]` and `// [!code warning]` (#38)
- **Code Snippet Imports** - Import code from external files with `<<< @/filepath` syntax (#39)
- **VS Code Regions** - Import specific code sections with `<<< @/filepath#region-name` (#39)
- **Line Range Extraction** - Extract specific lines from imports with `<<< @/filepath{2-10}` (#39)
- **Language Override** - Override auto-detected language in imports with `<<< @/filepath{js}` (#39)

### Changed
- Code block processor refactored for better maintainability with shared patterns module
- Improved code block CSS with support for all new marker types

## [0.5.0] - 2025-11-18

### Added
- **Table of Contents** - Auto-generated TOC from h2-h4 headings with clickable anchor links and smooth scrolling (#30)
- **Previous/Next Navigation** - Auto-detection from sidebar order with frontmatter override support and configurable labels (#31)

## [0.4.0] - 2025-11-16

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

## [0.3.0] - 2025-11-09

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

[Unreleased]: https://github.com/sanifhimani/docyard/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/sanifhimani/docyard/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/sanifhimani/docyard/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/sanifhimani/docyard/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/sanifhimani/docyard/compare/v0.9.0...v1.0.0
[0.9.0]: https://github.com/sanifhimani/docyard/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/sanifhimani/docyard/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/sanifhimani/docyard/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/sanifhimani/docyard/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/sanifhimani/docyard/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/sanifhimani/docyard/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/sanifhimani/docyard/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/sanifhimani/docyard/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/sanifhimani/docyard/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/sanifhimani/docyard/releases/tag/v0.0.1

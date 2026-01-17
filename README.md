# Docyard

[![CI](https://github.com/sanifhimani/docyard/actions/workflows/ci.yml/badge.svg)](https://github.com/sanifhimani/docyard/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/docyard.svg)](https://badge.fury.io/rb/docyard)

> Documentation generator for Ruby

Build beautiful documentation sites with hot reload, dark mode, and powerful markdown components.

## Features

### Core
- **Static site generation** - Build static sites with `docyard build`
- **Hot reload** - Changes appear instantly while you write
- **Dark mode** - Beautiful light/dark theme with system preference detection
- **Configuration system** - Optional `docyard.yml` for site metadata, branding, and build settings
- **Custom branding** - Logo and favicon with light/dark mode support
- **Base URL support** - Deploy to subdirectories or custom paths

### Navigation
- **Sidebar navigation** - Automatic sidebar with nested folders and collapsible sections
- **Sidebar customization** - Custom ordering, icons, and external links via config
- **Table of Contents** - Auto-generated TOC with heading anchors and smooth scrolling
- **Previous/Next navigation** - Auto-detection from sidebar with frontmatter override support
- **Active page highlighting** - Always know where you are

### Markdown
- **GitHub Flavored Markdown** - Tables, task lists, strikethrough
- **Syntax highlighting** - 100+ languages via Rouge with copy button
- **Markdown components**:
  - **Callouts** - 5 types (note, tip, important, warning, danger) with GitHub alerts syntax
  - **Tabs** - Code blocks, package managers, and custom tabs with keyboard navigation
  - **Icons** - 24 Phosphor icons with `:icon:` syntax
- **YAML frontmatter** - Add metadata to your pages

### Production
- **Asset bundling** - Minified CSS/JS with content hashing for cache busting
- **SEO** - Automatic sitemap.xml and robots.txt generation
- **Preview server** - Test production builds locally before deploying
- **Mobile responsive** - Looks great on all devices

## Quick Start

```bash
# Install
gem install docyard

# Initialize
docyard init

# Start dev server
docyard serve
# → http://localhost:4200

# Build for production
docyard build
```

Your site is ready to deploy! Upload the `dist/` folder to any static host.

## Installation

Add to your Gemfile:

```ruby
gem 'docyard'
```

Or install directly:

```bash
gem install docyard
```

## Usage

### Initialize a New Project

```bash
docyard init
```

This creates:
```
docs/
  index.md                          # Home page
  getting-started/
    installation.md                 # Installation guide
  guides/
    markdown-features.md            # Markdown features showcase
    configuration.md                # Configuration guide
docyard.yml                         # Optional configuration
```

### Commands

```bash
# Development server with hot reload
docyard serve
docyard serve --port 3000 --host 0.0.0.0

# Build for production
docyard build
docyard build --no-clean  # Don't clean output directory

# Preview production build
docyard preview
docyard preview --port 4001
```

### Writing Docs

Create markdown files in the `docs/` directory:

```markdown
---
title: Getting Started
---

# Getting Started

\`\`\`ruby
class User
  def initialize(name)
    @name = name
  end
end
\`\`\`
```

### Frontmatter

Add YAML frontmatter to customize page metadata:

```yaml
---
title: My Page Title
description: Page description
---
```

Currently supported:
- `title` - Page title (shown in `<title>` tag)
- `prev` - Customize or disable previous link
- `next` - Customize or disable next link

### Customizing Navigation

Control previous/next links per page via frontmatter:

```yaml
---
title: My Page
prev: false                  # Disable previous link
next:
  text: Custom Next Page
  link: /custom-path
---
```

Configure labels globally in `docyard.yml`:

```yaml
navigation:
  footer:
    enabled: true
    prev_text: "← Back"
    next_text: "Forward →"
```

### Linking Between Pages

Write links with `.md` extension, they'll be automatically cleaned:

```markdown
[Getting Started](./getting-started.md)  → /getting-started
[Guide](./guide/index.md)                → /guide
```

### Using Icons

Docyard includes 24 essential Phosphor icons that work out of the box. Just type `:icon-name:` in your markdown:

```markdown
:check: Zero configuration
:lightning: Hot reload
:rocket-launch: Fast and lightweight

Use different weights:
:heart:         → regular weight (default)
:heart:bold:    → bold weight
:heart:fill:    → filled version
```

Available icons: `heart`, `check`, `x`, `warning`, `info`, `question`, `arrow-right`, `arrow-left`, `arrow-up`, `arrow-down`, `code`, `terminal`, `package`, `rocket-launch`, `star`, `lightning`, `moon-stars`, `sun`, `link-external`, `copy`, `github`, `file`, `terminal-window`, `warning-circle`.

Weights: `regular` (default), `bold`, `fill`, `light`, `thin`, `duotone`

Icons automatically match your text size and color.

**Adding new icons:**

1. Get the SVG path from [phosphoricons.com](https://phosphoricons.com)
2. Add to `lib/docyard/icons/phosphor.rb` under the appropriate weight
3. Format: `"icon-name" => '<path d="..."/>',`

### Directory Structure

```
docs/
  index.md              # / (root)
  getting-started.md    # /getting-started
  guide/
    index.md            # /guide
    setup.md            # /guide/setup
    advanced.md         # /guide/advanced
```

## Architecture

Clean separation of concerns:

```
lib/docyard/
  cli.rb              # Command-line interface (Thor)
  initializer.rb      # Project scaffolding (init command)
  server.rb           # Server lifecycle (Puma, signals)
  rack_application.rb # HTTP request handling (routing, rendering)
  router.rb           # URL → file path mapping
  renderer.rb         # Markdown → HTML conversion
  markdown.rb         # Markdown parsing & frontmatter extraction
  asset_handler.rb    # Static asset serving
```

Each class has a single, clear responsibility. Easy to test, easy to extend.

## Development

```bash
git clone https://github.com/sanifhimani/docyard.git
cd docyard
bundle install

# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop

# Use local version
./bin/docyard init
./bin/docyard serve
```

## Roadmap

**v0.5.0 - Just shipped:**
- Table of Contents with heading anchors
- Previous/Next page navigation with auto-detection

**Next up (v0.6.0+):**
- Code block enhancements (line numbers, highlighting, diffs)
- Search functionality (client-side with Cmd/K)
- Details/collapsible blocks
- More markdown extensions

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

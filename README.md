# Docyard

[![CI](https://github.com/sanifhimani/docyard/actions/workflows/ci.yml/badge.svg)](https://github.com/sanifhimani/docyard/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/docyard.svg)](https://badge.fury.io/rb/docyard)

> Documentation generator for Ruby

**Early development** - Core features work, but missing search and build command. See [roadmap](#roadmap).

## Features

- **Sidebar navigation** - Automatic sidebar with nested folders and collapsible sections
- **Hot reload** - Changes appear instantly while you write
- **GitHub Flavored Markdown** - Tables, task lists, strikethrough
- **Syntax highlighting** - 100+ languages via Rouge
- **Icon system** - 1000+ Phosphor icons with simple `:icon:` syntax
- **YAML frontmatter** - Add metadata to your pages
- **Customizable error pages** - Make 404/500 pages your own

## Quick Start

```bash
# Install the gem
gem install docyard

# Create a new docs project
mkdir my-docs && cd my-docs
docyard init

# Start the dev server
docyard serve

# Visit http://localhost:4200
```

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
    introduction.md                 # Getting started guide
    installation.md                 # Installation instructions
    quick-start.md                  # Quick start guide
  core-concepts/
    file-structure.md              # File structure guide
    markdown.md                     # Markdown guide
```

### Start Development Server

```bash
docyard serve

# Custom port and host
docyard serve --port 3000 --host 0.0.0.0
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

### Linking Between Pages

Write links with `.md` extension, they'll be automatically cleaned:

```markdown
[Getting Started](./getting-started.md)  → /getting-started
[Guide](./guide/index.md)                → /guide
```

### Using Icons

Docyard includes 1000+ Phosphor icons that work out of the box. Just type `:icon-name:` in your markdown:

```markdown
:check: Zero configuration
:lightning: Hot reload
:rocket-launch: Fast and lightweight

Use different weights:
:heart:         → regular weight (default)
:heart:bold:    → bold weight
:heart:fill:    → filled version
```

Available icons: `heart`, `check`, `x`, `warning`, `info`, `question`, `arrow-right`, `arrow-left`, `arrow-up`, `arrow-down`, `code`, `terminal`, `package`, `rocket-launch`, `star`, `lightning`, `moon-stars`, `sun`, `link-external`, `copy`, `github`, and many more.

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
  server.rb           # Server lifecycle (WEBrick, signals)
  rack_application.rb # HTTP request handling (routing, rendering)
  router.rb           # URL → file path mapping
  renderer.rb         # Markdown → HTML conversion
  markdown.rb         # Markdown parsing & frontmatter extraction
  file_watcher.rb     # Live reload file monitoring
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

**Recently shipped:**
- Dark mode with theme toggle
- Icon system

**Next up:**
- Markdown components (callouts, code groups, collapsible sections)
- Client-side search
- Static site generation (`docyard build`)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

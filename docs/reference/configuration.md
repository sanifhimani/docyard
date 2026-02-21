---
title: Configuration
description: Complete docyard.yml reference.
social_cards:
  title: Configuration
  description: Complete docyard.yml reference.
---

# Configuration

Complete reference for `docyard.yml` options.

## Site Metadata

```yaml [docyard.yml]
title: My Docs
description: Documentation for my project
url: https://docs.example.com
og_image: /images/og.png
twitter: "@myproject"
source: docs
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | `string` | `Documentation` | Site title |
| `description` | `string` | - | Site description for SEO |
| `url` | `string` | - | Production URL |
| `og_image` | `string` | - | Default Open Graph image |
| `twitter` | `string` | - | Twitter handle for cards |
| `source` | `string` | `docs` | Documentation source directory |

---

## Branding

```yaml [docyard.yml]
branding:
  logo: /logo.svg
  favicon: /favicon.ico
  color: "#3b82f6"
  credits: false
  copyright: "2026 My Company"
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `logo` | `string` | - | Logo image path |
| `favicon` | `string` | - | Favicon path |
| `color` | `string` or `object` | - | Primary brand color |
| `credits` | `boolean` | `true` | Show "Built with Docyard" |
| `copyright` | `string` | - | Footer copyright text |

For different light/dark colors:

```yaml
branding:
  color:
    light: "#3b82f6"
    dark: "#60a5fa"
```

---

## Socials

```yaml [docyard.yml]
socials:
  github: https://github.com/example/repo
  twitter: https://twitter.com/example
  discord: https://discord.gg/example
```

33 platforms supported. See [Branding](/customize/branding#supported-platforms) for the full list.

### Custom Links

```yaml [docyard.yml]
socials:
  github: https://github.com/example
  custom:
    - icon: rss
      href: /feed.xml
    - icon: envelope
      href: mailto:hello@example.com
```

---

## Tabs

Top-level navigation for multi-section documentation.

```yaml [docyard.yml]
tabs:
  - text: Guide
    href: /guide
  - text: API
    href: /api
    icon: code
  - text: Blog
    href: https://blog.example.com
    external: true
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `text` | `string` | - | Tab label |
| `href` | `string` | - | Link URL or path prefix |
| `icon` | `string` | - | Phosphor icon name |
| `external` | `boolean` | `false` | Open in new tab |

Tabs filter the sidebar to show only content under the active tab's path.

---

## Sidebar

```yaml [docyard.yml]
sidebar: config
```

| Mode | Description |
|------|-------------|
| `config` | Manual configuration via `_sidebar.yml` (default) |
| `auto` | Auto-generated from directory structure |
| `distributed` | Local `_sidebar.yml` files in subdirectories |

See [Sidebar](/customize/sidebar) for detailed setup.

---

## Navigation

```yaml [docyard.yml]
navigation:
  cta:
    - text: Get Started
      href: /getting-started
      variant: primary
    - text: GitHub
      href: https://github.com/example
      variant: secondary
      external: true
  breadcrumbs: true
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `cta` | `array` | `[]` | Header CTA buttons (max 2) |
| `cta[].text` | `string` | - | Button text |
| `cta[].href` | `string` | - | Link URL |
| `cta[].variant` | `string` | `primary` | `primary` or `secondary` |
| `cta[].external` | `boolean` | `false` | Open in new tab |
| `breadcrumbs` | `boolean` | `true` | Show breadcrumb navigation |

---

## Search

```yaml [docyard.yml]
search:
  enabled: true
  placeholder: "Search documentation..."
  exclude:
    - "/changelog/*"
    - "/internal/*"
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | `boolean` | `true` | Enable search |
| `placeholder` | `string` | `Search...` | Search input placeholder |
| `exclude` | `array` | `[]` | Glob patterns to exclude |

---

## Announcement

```yaml [docyard.yml]
announcement:
  text: "We just launched v2.0!"
  link: /changelog
  button:
    text: "See what's new"
    link: /changelog
  dismissible: true
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `text` | `string` | - | Banner text (required) |
| `link` | `string` | - | Makes text clickable |
| `button.text` | `string` | - | Button label |
| `button.link` | `string` | - | Button URL |
| `dismissible` | `boolean` | `true` | Allow users to dismiss |

---

## Repository

```yaml [docyard.yml]
repo:
  url: https://github.com/example/docs
  branch: main
  edit_path: docs
  edit_link: true
  last_updated: true
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `url` | `string` | - | Repository URL |
| `branch` | `string` | `main` | Default branch |
| `edit_path` | `string` | `docs` | Path to docs in repo (for monorepos) |
| `edit_link` | `boolean` | `true` | Show "Edit this page" link |
| `last_updated` | `boolean` | `true` | Show last updated date |

---

## Analytics

```yaml [docyard.yml]
analytics:
  google: G-XXXXXXXXXX
  plausible: example.com
  fathom: XXXXXXXX
  script: /custom-analytics.js
```

| Option | Type | Description |
|--------|------|-------------|
| `google` | `string` | Google Analytics measurement ID |
| `plausible` | `string` | Plausible domain |
| `fathom` | `string` | Fathom site ID |
| `script` | `string` | Custom analytics script path |

---

## Feedback

```yaml [docyard.yml]
feedback:
  enabled: true
  question: "Was this page helpful?"
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | `boolean` | `false` | Enable feedback widget |
| `question` | `string` | `Was this page helpful?` | Question text |

Feedback requires analytics to be configured. Responses are sent as events to your analytics provider.

---

## Build

```yaml [docyard.yml]
build:
  output: dist
  base: /
  strict: false
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `output` | `string` | `dist` | Output directory |
| `base` | `string` | `/` | Base path (use `/repo-name` for GitHub project sites) |
| `strict` | `boolean` | `false` | Fail build on validation errors |

---

## Social Cards

```yaml [docyard.yml]
social_cards:
  enabled: true
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | `boolean` | `false` | Generate OG images for all pages |

Requires libvips. See [Social Cards](/customize/social-cards) for setup.

---

## Variables

```yaml [docyard.yml]
variables:
  version: 2.5.0
  min_ruby: "3.0"
  links:
    docs: https://docs.example.com
```

Define values once, reuse across all pages with `{{ name }}` syntax. Supports dot notation for nested values (`{{ links.docs }}`). Not replaced inside code blocks unless the language has a `-vars` suffix.

See [Variables](/write-content/variables) for usage details.

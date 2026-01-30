---
title: Configuration
description: Complete docyard.yml reference
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

:::tip
Setting `description` is recommended for better SEO.
:::

---

## Branding

```yaml [docyard.yml]
branding:
  logo: /logo.svg
  favicon: /favicon.ico
  color: "#3b82f6"
  credits: false
  copyright: "2024 My Company"
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `logo` | `string` | - | Logo image path |
| `favicon` | `string` | - | Favicon path |
| `color` | `string` or `object` | - | Primary brand color |
| `credits` | `boolean` | `true` | Show "Built with Docyard" |
| `copyright` | `string` | - | Footer copyright text |

### Color Variants

Specify different colors for light and dark modes:

```yaml [docyard.yml]
branding:
  color:
    light: "#3b82f6"
    dark: "#60a5fa"
```

:::tip
Use a lighter shade for dark mode to maintain visual contrast.
:::

---

## Socials

```yaml [docyard.yml]
socials:
  github: https://github.com/example/repo
  twitter: https://twitter.com/example
  discord: https://discord.gg/example
```

:::details{title="Supported Platforms (34)"}
`github` `twitter` `x` `discord` `slack` `linkedin` `youtube` `bluesky` `instagram` `facebook` `tiktok` `reddit` `mastodon` `threads` `pinterest` `medium` `gitlab` `figma` `dribbble` `behance` `codepen` `codesandbox` `notion` `spotify` `soundcloud` `whatsapp` `telegram` `snapchat` `patreon` `paypal` `stripe` `twitch` `google-podcasts` `apple-podcasts`
:::

### Custom Links

Add links with custom icons using any [Phosphor icon](https://phosphoricons.com) name:

```yaml [docyard.yml]
socials:
  github: https://github.com/example
  custom:
    - icon: rss
      href: /feed.xml
    - icon: envelope
      href: mailto:hello@example.com
```

You can also use inline SVG for custom icons:

```yaml [docyard.yml]
socials:
  custom:
    - icon: '<svg viewBox="0 0 24 24">...</svg>'
      href: https://example.com
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

:::note
Tabs filter the sidebar to show only content under the active tab's path.
:::

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

See [Sidebar Configuration](/customize/sidebar) for detailed setup.

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
| `breadcrumbs` | `boolean` | `true` | Show breadcrumb navigation |

### CTA Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `text` | `string` | - | Button text |
| `href` | `string` | - | Link URL |
| `variant` | `string` | `primary` | `primary` or `secondary` |
| `external` | `boolean` | `false` | Open in new tab |

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
| `exclude` | `array` | `[]` | URL patterns to exclude |

### Exclude Patterns

| Pattern | Matches |
|---------|---------|
| `/changelog/*` | All pages under `/changelog/` |
| `/draft-*` | Pages starting with `/draft-` |
| `/internal/**` | All nested pages under `/internal/` |

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

:::note
When dismissed, the preference is stored in localStorage for 7 days.
:::

---

## Repository

```yaml [docyard.yml]
repo:
  url: https://github.com/example/docs
  branch: main
  edit_link: true
  last_updated: true
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `url` | `string` | - | Repository URL |
| `branch` | `string` | `main` | Default branch |
| `edit_path` | `string` | `docs` | Path to docs directory in the repo |
| `edit_link` | `boolean` | `true` | Show "Edit this page" link |
| `last_updated` | `boolean` | `true` | Show last updated date |

### Edit Path

Use `edit_path` when your documentation lives in a non-standard location:

```yaml [docyard.yml]
# Monorepo: docs are in packages/docs/
repo:
  url: https://github.com/example/monorepo
  edit_path: packages/docs

# Custom folder name
repo:
  url: https://github.com/example/project
  edit_path: documentation
```

This ensures "Edit this page" links point to the correct file path in your repository.

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

Add a "Was this page helpful?" widget to collect reader feedback.

```yaml [docyard.yml]
feedback:
  enabled: true
  question: "Was this page helpful?"
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | `boolean` | `false` | Enable feedback widget |
| `question` | `string` | `Was this page helpful?` | Question text |

:::important
Feedback requires analytics to be configured. Responses are sent as events to your analytics provider (Google Analytics, Plausible, or Fathom).
:::

### Event Format

:::tabs
== Google Analytics
Event name: `page_feedback`

Properties:
- `feedback_page` - Page path
- `helpful` - `"yes"` or `"no"`
- `value` - `1` or `0`
== Plausible
Event name: `Feedback`

Properties:
- `helpful` - `"yes"` or `"no"`
- `page` - Page path
== Fathom
Event name: `feedback_yes` or `feedback_no`
:::

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
| `base` | `string` | `/` | Base path for deployment |
| `strict` | `boolean` | `false` | Fail build on validation errors |

:::tabs
== Root deployment
```yaml [docyard.yml]
build:
  base: /
```
== Subdirectory deployment
```yaml [docyard.yml]
# For GitHub Pages project sites or subdirectory hosting
build:
  base: /repo-name
```
:::

:::note
`base` must start with `/`. For your production URL, use the top-level `url` field instead.
:::

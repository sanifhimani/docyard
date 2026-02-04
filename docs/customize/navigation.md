---
title: Navigation
description: Configure breadcrumbs, prev/next links, TOC, and header navigation.
social_cards:
  title: Navigation
  description: Breadcrumbs, prev/next links, TOC, and header CTAs.
---

# Navigation

Customize how users navigate your documentation.

## Header CTAs

Add call-to-action buttons to the header:

```yaml [docyard.yml]
navigation:
  cta:
    - text: Get Started
      href: /getting-started
      variant: primary
    - text: GitHub
      href: https://github.com/example/repo
      variant: secondary
      external: true
```

Maximum of 2 CTAs are displayed.

---

## Header Tabs

Add top-level navigation tabs for large documentation sites:

```yaml [docyard.yml]
tabs:
  - text: Docs
    href: /docs
  - text: API
    href: /api
    icon: code
  - text: Blog
    href: https://blog.example.com
    external: true
```

Tabs filter the sidebar to show only content under the active tab's path.

---

## Breadcrumbs

Breadcrumbs show the path to the current page. Enabled by default.

To disable:

```yaml [docyard.yml]
navigation:
  breadcrumbs: false
```

Breadcrumbs are automatically truncated when the path has more than 3 levels.

---

## Prev/Next Links

Navigation links at the bottom of each page are auto-generated from your sidebar structure.

### Disable for a Page

```yaml [page.md]
---
title: My Page
prev: false
next: false
---
```

### Custom Links

Override with a page title:

```yaml
---
title: My Page
prev: "Getting Started"
next: "Advanced Usage"
---
```

Or specify both text and link:

```yaml
---
title: My Page
prev:
  text: "Back to Intro"
  link: /intro
next:
  text: "Continue to API"
  link: /api
---
```

---

## Table of Contents

The table of contents (TOC) is automatically generated from h2-h4 headings on each page. It appears in the right sidebar on desktop.

### Heading Levels

The TOC includes:
- `## Heading 2` - Top level
- `### Heading 3` - Nested
- `#### Heading 4` - Deeply nested

### Best Practices

- Use clear, descriptive headings
- Keep heading text concise
- Maintain a logical hierarchy (don't skip levels)

---

## Complete Example

```yaml [docyard.yml]
# Header tabs for multi-section docs
tabs:
  - text: Guide
    href: /guide
  - text: API Reference
    href: /api
    icon: code
  - text: Examples
    href: /examples

# Header CTAs
navigation:
  cta:
    - text: Get Started
      href: /guide/quickstart
      variant: primary
    - text: GitHub
      href: https://github.com/example/repo
      variant: secondary
      external: true
  breadcrumbs: true
```

---

## Reference

### Header CTA Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `text` | `string` | - | Button text |
| `href` | `string` | - | Link URL |
| `variant` | `string` | `primary` | `primary` or `secondary` |
| `external` | `boolean` | `false` | Open in new tab |

### Header Tab Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `text` | `string` | - | Tab text |
| `href` | `string` | - | Link URL or path prefix |
| `icon` | `string` | - | Icon name |
| `external` | `boolean` | `false` | External link |

### Navigation Config

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `navigation.cta` | `array` | `[]` | Header CTA buttons (max 2) |
| `navigation.breadcrumbs` | `boolean` | `true` | Show breadcrumbs |

### Prev/Next Frontmatter

| Option | Type | Description |
|--------|------|-------------|
| `prev` | `false` | Disable previous link |
| `prev` | `string` | Page title to link to |
| `prev.text` | `string` | Custom link text |
| `prev.link` | `string` | Custom link URL |
| `next` | `false` | Disable next link |
| `next` | `string` | Page title to link to |
| `next.text` | `string` | Custom link text |
| `next.link` | `string` | Custom link URL |

---
title: Frontmatter
description: YAML frontmatter options for pages.
social_cards:
  title: Frontmatter
  description: Page-level YAML configuration options.
---

# Frontmatter

Configure individual pages using YAML frontmatter.

```yaml [page.md]
---
title: My Page Title
description: A brief description for SEO
---

# Page content starts here
```

---

## Page Metadata

| Option | Type | Description |
|--------|------|-------------|
| `title` | `string` | Page title (browser tab and sidebar) |
| `description` | `string` | Page description for SEO |
| `og_image` | `string` | Open Graph image (overrides site default) |

---

## Social Cards

Override auto-generated social card content.

```yaml
---
social_cards:
  title: Custom Card Title
  description: Custom description for sharing
---
```

| Option | Type | Description |
|--------|------|-------------|
| `social_cards.title` | `string` | Card title (~22 chars) |
| `social_cards.description` | `string` | Card description (~70 chars) |

These only affect the generated image, not SEO metadata.

---

## Navigation

Control prev/next links at the bottom of pages.

```yaml
---
prev: false           # Disable previous link
next: "Page Title"    # Link by title
---
```

Or specify custom text and URL:

```yaml
---
prev:
  text: "Back to Intro"
  link: /intro
next:
  text: "Continue to API"
  link: /api
---
```

| Option | Type | Description |
|--------|------|-------------|
| `prev` / `next` | `false` | Disable link |
| `prev` / `next` | `string` | Page title to link to |
| `prev.text` / `next.text` | `string` | Custom link text |
| `prev.link` / `next.link` | `string` | Custom link URL |

---

## Landing Pages

Create landing pages with hero sections and feature grids.

```yaml
---
landing:
  hero:
    title: Build beautiful docs
    tagline: A modern documentation generator
    actions:
      - text: Get Started
        link: /getting-started
        variant: primary
  features:
    - title: Fast
      description: Built for speed
      icon: lightning
---
```

| Option | Type | Description |
|--------|------|-------------|
| `landing.sidebar` | `boolean` | Show sidebar (default: false) |
| `landing.hero.title` | `string` | Main heading |
| `landing.hero.tagline` | `string` | Subheading |
| `landing.hero.badge` | `string` | Small badge above title |
| `landing.hero.background` | `string` | `grid`, `glow`, `mesh`, or `none` |
| `landing.hero.actions` | `array` | CTA buttons |
| `landing.hero.image` | `object` | Hero image |
| `landing.features_header` | `object` | Header above features |
| `landing.features` | `array` | Feature cards |

See [Landing Pages](/customize/landing-pages) for full configuration options.

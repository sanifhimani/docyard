---
title: Frontmatter
description: YAML frontmatter options for title, description, navigation, and landing pages
---

# Frontmatter

Configure individual pages using YAML frontmatter at the top of your markdown files.

```yaml [page.md]
---
title: My Page Title
description: A brief description for SEO
---

# Page content starts here
```

---

## Page Metadata

Basic metadata for SEO and display.

```yaml
---
title: Getting Started
description: Learn how to set up your first Docyard project
og_image: /images/getting-started-og.png
---
```

| Option | Type | Description |
|--------|------|-------------|
| `title` | `string` | Page title (used in browser tab and sidebar) |
| `description` | `string` | Page description for SEO meta tags |
| `og_image` | `string` | Open Graph image for social sharing (overrides site default) |

---

## Social Cards

Override auto-generated social card content for individual pages.

```yaml
---
social_cards:
  title: Custom Card Title
  description: Custom description for social sharing
---
```

| Option | Type | Description |
|--------|------|-------------|
| `social_cards.title` | `string` | Override card title (~22 chars before truncation) |
| `social_cards.description` | `string` | Override card description (~70 chars before truncation) |

:::note
These only affect the generated social card image, not the page's SEO metadata. Requires `social_cards.enabled: true` in your site config. See [Social Cards](/customize/social-cards) for full documentation.
:::

---

## Navigation

Control prev/next links at the bottom of the page.

### Disable Links

```yaml
---
title: Standalone Page
prev: false
next: false
---
```

### Link by Title

Reference another page by its title:

```yaml
---
title: Current Page
prev: "Getting Started"
next: "Advanced Usage"
---
```

### Custom Links

Specify both text and URL:

```yaml
---
title: Current Page
prev:
  text: "Back to Intro"
  link: /intro
next:
  text: "Continue to API"
  link: /api/overview
---
```

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

---

## Landing Pages

Create landing pages with hero sections and feature grids.

```yaml
---
landing:
  sidebar: false
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

### Hero Section

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `landing.sidebar` | `boolean` | `false` | Show sidebar on landing page |
| `landing.hero.background` | `string` | `grid` | Background style: `grid`, `glow`, `mesh`, `none` |
| `landing.hero.badge` | `string` | - | Small badge above title |
| `landing.hero.name` | `string` | - | Small text above title |
| `landing.hero.title` | `string` | - | Main heading |
| `landing.hero.tagline` | `string` | - | Subheading text |
| `landing.hero.gradient` | `boolean` | `true` | Apply gradient to title |

### Hero Image

```yaml
landing:
  hero:
    image:
      src: /images/hero.png
      alt: Hero illustration
```

Or with light/dark variants:

```yaml
landing:
  hero:
    image:
      light: /images/hero-light.png
      dark: /images/hero-dark.png
      alt: Hero illustration
```

| Option | Type | Description |
|--------|------|-------------|
| `landing.hero.image.src` | `string` | Image path |
| `landing.hero.image.light` | `string` | Light mode image |
| `landing.hero.image.dark` | `string` | Dark mode image |
| `landing.hero.image.alt` | `string` | Alt text |

### Hero Custom Visual

Embed custom HTML instead of an image:

```yaml
landing:
  hero:
    custom_visual:
      html: '<div class="custom-animation">...</div>'
      placement: side
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `landing.hero.custom_visual.html` | `string` | - | Custom HTML content |
| `landing.hero.custom_visual.placement` | `string` | `side` | `side` or `bottom` |

### Hero Actions

```yaml
landing:
  hero:
    actions:
      - text: Get Started
        link: /getting-started
        variant: primary
      - text: View on GitHub
        link: https://github.com/example/repo
        icon: github-logo
        variant: secondary
        target: _blank
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `text` | `string` | - | Button text |
| `link` | `string` | - | Button URL |
| `icon` | `string` | - | Phosphor icon name |
| `variant` | `string` | `primary` | `primary` or `secondary` |
| `target` | `string` | - | Link target (e.g., `_blank`) |
| `rel` | `string` | - | Link rel attribute |

### Features Header

Add a header above the features grid:

```yaml
landing:
  features_header:
    label: Features
    title: Everything you need
    description: Built-in components for modern documentation
```

| Option | Type | Description |
|--------|------|-------------|
| `landing.features_header.label` | `string` | Small label text |
| `landing.features_header.title` | `string` | Section title |
| `landing.features_header.description` | `string` | Section description |

### Features

```yaml
landing:
  features:
    - title: Fast Builds
      description: Parallel processing for large sites
      icon: lightning
      color: "#f59e0b"
      link: /features/performance
      link_text: Learn more
      size: large
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | `string` | - | Feature title |
| `description` | `string` | - | Feature description |
| `icon` | `string` | - | Phosphor icon name |
| `color` | `string` | - | Icon color (CSS color value) |
| `link` | `string` | - | Feature link URL |
| `link_text` | `string` | `Learn more` | Link text |
| `size` | `string` | - | `large` for wider cards |
| `target` | `string` | - | Link target |
| `rel` | `string` | - | Link rel attribute |

### Landing Footer

Add footer links to the landing page:

```yaml
landing:
  footer:
    links:
      - text: Documentation
        link: /docs
      - text: GitHub
        link: https://github.com/example/repo
```

| Option | Type | Description |
|--------|------|-------------|
| `landing.footer.links[].text` | `string` | Link text |
| `landing.footer.links[].link` | `string` | Link URL |

---
title: Landing Pages
description: Hero sections, feature grids, and custom visuals for documentation homepages.
social_cards:
  title: Landing Pages
  description: Heroes, feature grids, and custom visuals.
---

# Landing Pages

Build compelling landing pages with heroes, feature grids, and custom visuals.

## Basic Landing Page

Add a `landing` section to your frontmatter:

```yaml [docs/index.md]
---
title: My Project
landing:
  hero:
    title: "Build something amazing"
    tagline: "A short description of your project"
    actions:
      - text: Get Started
        link: /getting-started
---
```

---

## Hero Section

### Title & Tagline

```yaml
landing:
  hero:
    title: "Your Product Name"
    tagline: "One line that explains what it does"
```

### Badge

Add an announcement badge above the title:

```yaml
landing:
  hero:
    badge: "v2.0 Released"
    title: "Your Product Name"
```

### Call-to-Action Buttons

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
```

### Hero Image

Display an image alongside the hero content:

```yaml
landing:
  hero:
    title: "Your Product"
    image:
      src: /images/hero.png
      alt: "Product screenshot"
```

Use different images for light and dark modes:

```yaml
landing:
  hero:
    image:
      light: /images/hero-light.png
      dark: /images/hero-dark.png
      alt: "Product screenshot"
```

### Custom Visual

Embed custom HTML (like animations or interactive elements):

```yaml
landing:
  hero:
    custom_visual:
      html: "hero-animation.html"
      placement: bottom
```

Place the HTML file in `docs/public/`. The `placement` can be `side` (next to content) or `bottom` (below content).

### Background Style

Choose a background effect:

```yaml
landing:
  hero:
    background: grid    # Default grid pattern
    background: glow    # Glowing orbs
    background: mesh    # Gradient mesh
    background: none    # No background
```

### Gradient Title

Add a gradient effect to the title:

```yaml
landing:
  hero:
    title: "Gradient Title"
    gradient: true
```

---

## Features Section

### Basic Features

```yaml
landing:
  features:
    - title: Fast
      description: Optimized for speed
      icon: rocket-launch
    - title: Secure
      description: Built with security in mind
      icon: shield-check
    - title: Simple
      description: Easy to get started
      icon: lightning
```

### Features Header

Add a header above the feature grid:

```yaml
landing:
  features_header:
    label: "Why choose us"
    title: "Built for developers"
    description: "Everything you need to ship fast"
  features:
    - title: Fast
      # ...
```

### Feature Sizes

Create visual hierarchy with different sizes:

```yaml
landing:
  features:
    - title: Main Feature
      description: This gets more attention
      icon: star
      size: large
    - title: Secondary
      description: Regular sized card
      icon: cube
```

### Linked Features

Make feature cards clickable:

```yaml
landing:
  features:
    - title: Documentation
      description: Learn how to use our product
      icon: book-open
      link: /docs
      link_text: "Read the docs"
```

---

## Complete Example

```yaml [docs/index.md]
---
title: My Project
description: A brief description for SEO
landing:
  hero:
    badge: "Now in Beta"
    title: "Ship docs faster"
    tagline: "Write markdown, get a beautiful documentation site"
    background: glow
    actions:
      - text: Get Started
        link: /getting-started
        variant: primary
      - text: GitHub
        link: https://github.com/example/repo
        icon: github-logo
        variant: secondary
    image:
      light: /images/screenshot-light.png
      dark: /images/screenshot-dark.png
      alt: "Product screenshot"

  features_header:
    title: "Everything you need"
    description: "Built for modern documentation"

  features:
    - title: Lightning Fast
      description: Static HTML with no JavaScript overhead
      icon: lightning
      size: large
    - title: Full-text Search
      description: Built-in search powered by Pagefind
      icon: magnifying-glass
    - title: Dark Mode
      description: Automatic theme switching
      icon: moon
    - title: Components
      description: 10+ built-in components
      icon: lego
      link: /components
---
```

---

## Reference

### Hero Options

| Option | Type | Description |
|--------|------|-------------|
| `badge` | `string` | Small text above the title |
| `title` | `string` | Main hero heading |
| `tagline` | `string` | Subtitle below the title |
| `gradient` | `boolean` | Apply gradient effect to title |
| `background` | `string` | `grid`, `glow`, `mesh`, or `none` |
| `image` | `object` | Hero image (see below) |
| `custom_visual` | `object` | Custom HTML embed (see below) |
| `actions` | `array` | CTA buttons (see below) |

### Hero Image

| Option | Type | Description |
|--------|------|-------------|
| `src` | `string` | Image path (single image) |
| `light` | `string` | Light mode image |
| `dark` | `string` | Dark mode image |
| `alt` | `string` | Alt text |

### Hero Actions

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `text` | `string` | - | Button text |
| `link` | `string` | - | URL |
| `variant` | `string` | `primary` | `primary` or `secondary` |
| `icon` | `string` | - | Icon name |
| `target` | `string` | - | Link target (e.g., `_blank`) |
| `rel` | `string` | - | Link rel attribute |

### Custom Visual

| Option | Type | Description |
|--------|------|-------------|
| `html` | `string` | HTML filename in `docs/public/` |
| `placement` | `string` | `side` or `bottom` |

### Features Header

| Option | Type | Description |
|--------|------|-------------|
| `label` | `string` | Small label above title |
| `title` | `string` | Section heading |
| `description` | `string` | Section description |

### Feature Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | `string` | - | Feature title |
| `description` | `string` | - | Feature description |
| `icon` | `string` | - | Icon name |
| `size` | `string` | - | `large` for bigger cards |
| `link` | `string` | - | Makes card clickable |
| `link_text` | `string` | `Learn more` | Link text |
| `color` | `string` | `primary` | Icon color |
| `target` | `string` | - | Link target |
| `rel` | `string` | - | Link rel attribute |

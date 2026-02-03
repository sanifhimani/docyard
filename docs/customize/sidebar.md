---
title: Sidebar
description: Configure sidebar navigation with config, auto, or distributed modes
---

# Sidebar

Control how your documentation navigation is organized.

## Modes

Docyard supports three sidebar modes:

```yaml [docyard.yml]
sidebar: "config"      # Manual YAML (default)
sidebar: "auto"        # Auto-generated from files
sidebar: "distributed" # Per-section configs
```

---

## Config Mode

The default mode. Define your navigation in `docs/_sidebar.yml`:

```yaml [docs/_sidebar.yml]
- getting-started:
    text: Get Started
    icon: rocket-launch
    items:
      - introduction
      - quickstart
      - installation

- guides:
    text: Guides
    icon: book-open
    items:
      - authentication
      - deployment
```

### Page Items

Link to a page by its filename (without `.md`):

```yaml
- quickstart              # Links to docs/quickstart.md
```

Add custom text or icon:

```yaml
- quickstart:
    text: "Quick Start Guide"
    icon: lightning
```

### Groups with Children

Create nested navigation:

```yaml
- api:
    text: API Reference
    icon: code
    items:
      - authentication
      - endpoints
      - errors
```

Pages resolve relative to the group. `authentication` becomes `docs/api/authentication.md`.

### Linkable Groups

Make a group clickable by adding `index: true`:

```yaml
- api:
    text: API Reference
    icon: code
    index: true           # Links to docs/api/index.md
    items:
      - authentication
      - endpoints
```

### Collapsible Sections

Top-level groups are sections by default (always expanded, no toggle). Make them collapsible:

```yaml
- advanced:
    text: Advanced
    icon: gear
    collapsible: true     # Adds expand/collapse toggle
    collapsed: true       # Start collapsed
    items:
      - internals
      - plugins
```

### Virtual Groups

Group items visually without affecting URL paths:

```yaml
- basics:
    text: Basics
    group: true           # No path prefix
    items:
      - intro             # Links to /intro, not /basics/intro
      - setup
```

---

## Auto Mode

Generate sidebar automatically from your directory structure:

```yaml [docyard.yml]
sidebar: "auto"
```

```filetree
docs/
  getting-started/
    introduction.md
    quickstart.md
  guides/
    authentication.md
    deployment.md
```

Becomes:

- **Getting Started**
  - Introduction
  - Quickstart
- **Guides**
  - Authentication
  - Deployment

### Auto Mode Rules

- Directories become sections
- Files sorted alphabetically (case-insensitive)
- `index.md` makes the section clickable
- Ignores files starting with `.` or `_`
- Ignores `public/` directory

---

## Distributed Mode

Manage each section's navigation separately. First, enable it in your config:

```yaml [docyard.yml]
sidebar: "distributed"
```

Then create a root `_sidebar.yml` that lists your sections:

```yaml [docs/_sidebar.yml]
- getting-started
- api
- guides
```

Each section has its own `_sidebar.yml` with full configuration:

:::code-group
```yaml [docs/getting-started/_sidebar.yml]
text: Get Started
icon: rocket-launch
items:
  - introduction
  - quickstart
  - installation
```

```yaml [docs/api/_sidebar.yml]
text: API Reference
icon: code
items:
  - authentication
  - endpoints
  - errors
```
:::

This keeps large documentation projects organized.

---

## External Links

Add links to external resources:

```yaml
- link: "https://github.com/your-org/your-repo"
  text: "GitHub"
  icon: github-logo
  target: "_blank"
```

---

## Badges

Highlight pages with badges:

```yaml
- new-feature:
    text: "New Feature"
    badge: "New"
    badge_type: "success"
```

Badge types: `default`, `success`, `warning`, `danger`

---

## Icons

Use any [Phosphor Icon](https://phosphoricons.com) name:

```yaml
- getting-started:
    text: Get Started
    icon: rocket-launch

- api:
    text: API
    icon: code
```

---

## Complete Example

```yaml [docs/_sidebar.yml]
- index:
    text: Home
    icon: house

- getting-started:
    text: Get Started
    icon: rocket-launch
    items:
      - introduction
      - quickstart:
          text: "5-Minute Quickstart"
      - installation

- guides:
    text: Guides
    icon: book-open
    collapsible: true
    items:
      - authentication:
          badge: "Updated"
          badge_type: "success"
      - deployment
      - troubleshooting

- api:
    text: API Reference
    icon: code
    index: true
    items:
      - endpoints
      - errors
      - rate-limits:
          text: "Rate Limits"

- link: "https://github.com/example/repo"
  text: "GitHub"
  icon: github-logo
  target: "_blank"
```

---

## Reference

### Sidebar Modes

| Mode | Description |
|------|-------------|
| `config` | Manual YAML-based navigation (default) |
| `auto` | Auto-generated from directory structure |
| `distributed` | Per-section `_sidebar.yml` files |

### Item Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `text` | `string` | Titleized filename | Display text |
| `icon` | `string` | - | Phosphor icon name |
| `badge` | `string` | - | Badge text |
| `badge_type` | `string` | `default` | `default`, `success`, `warning`, `danger` |
| `items` | `array` | - | Child items |
| `collapsed` | `boolean` | `true` | Start collapsed (nested groups) |
| `collapsible` | `boolean` | `false` | Add expand/collapse toggle |
| `index` | `boolean` | `false` | Link group to its `index.md` |
| `group` | `boolean` | `false` | Visual grouping only (no path prefix) |

### External Link Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `link` | `string` | - | URL (required) |
| `text` | `string` | - | Display text (required) |
| `icon` | `string` | - | Phosphor icon name |
| `target` | `string` | `_blank` | Link target |

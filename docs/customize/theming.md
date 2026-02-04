---
title: Theming
description: Customize colors, typography, spacing, and other CSS variables.
social_cards:
  title: Theming
  description: Full control over colors, fonts, and layout.
---

# Theming

Customize colors, typography, spacing, and layout with CSS variables.

## Quick Start

Generate customization files with the CLI:

```bash
docyard customize
```

This creates two files in your docs directory:

```filetree
docs/
  _custom/
    styles.css *
    scripts.js
```

Edit `styles.css` to override any CSS variable. Changes apply automatically during development and are bundled into production builds.

---

## The `_custom` Directory

The `_custom/` directory is a convention for theme customization:

- **`styles.css`** - Appended to the CSS bundle after all default styles
- **`scripts.js`** - Appended to the JS bundle after all default scripts

No configuration needed. Docyard automatically detects and includes these files.

---

## Customizing CSS Variables

The generated `styles.css` contains all available CSS variables as comments. Uncomment and modify the ones you want to change:

```css [docs/_custom/styles.css]
:root {
  /* Override the primary color */
  --primary: #8b5cf6;

  /* Change the sidebar width */
  --sidebar-width: 18rem;

  /* Use a different font */
  --font-sans: 'Roboto', sans-serif;
}

.dark {
  /* Different primary for dark mode */
  --primary: #a78bfa;
}
```

:::tip
Delete any variables you don't need to change. This keeps your customization file clean and maintainable.
:::

---

## Variable Categories

### Colors

Core color palette for backgrounds, text, and UI elements:

| Variable | Description |
|----------|-------------|
| `--background` | Page background |
| `--foreground` | Primary text color |
| `--primary` | Brand/accent color |
| `--primary-foreground` | Text on primary color |
| `--secondary` | Secondary backgrounds |
| `--muted` | Muted backgrounds |
| `--muted-foreground` | Muted text |
| `--border` | Border color |
| `--ring` | Focus ring color |

### Sidebar

Sidebar-specific colors:

| Variable | Description |
|----------|-------------|
| `--sidebar` | Sidebar background |
| `--sidebar-foreground` | Sidebar text |
| `--sidebar-primary` | Active item color |
| `--sidebar-accent` | Hover background |
| `--sidebar-border` | Sidebar borders |

### Typography

Font families and sizes:

| Variable | Description |
|----------|-------------|
| `--font-sans` | Body text font |
| `--font-mono` | Code font |
| `--text-xs` through `--text-4xl` | Font sizes |
| `--font-normal` through `--font-bold` | Font weights |
| `--leading-tight`, `--leading-normal`, `--leading-relaxed` | Line heights |

### Spacing

Consistent spacing scale:

| Variable | Value |
|----------|-------|
| `--spacing-1` | 0.25rem |
| `--spacing-2` | 0.5rem |
| `--spacing-4` | 1rem |
| `--spacing-8` | 2rem |
| `--spacing-16` | 4rem |

### Layout

Structural dimensions:

| Variable | Default | Description |
|----------|---------|-------------|
| `--sidebar-width` | 16rem | Desktop sidebar width |
| `--sidebar-width-mobile` | 18rem | Mobile sidebar width |
| `--toc-width` | 17.5rem | Table of contents width |
| `--header-height` | 4rem | Header height |
| `--content-max-width` | 50rem | Maximum content width |
| `--layout-max-width` | 88rem | Maximum layout width |

### Callouts

Colors for different callout types:

| Variable | Description |
|----------|-------------|
| `--callout-note` | Note callout color |
| `--callout-tip` | Tip callout color |
| `--callout-important` | Important callout color |
| `--callout-warning` | Warning callout color |
| `--callout-danger` | Danger callout color |

### Code Blocks

Code block styling:

| Variable | Description |
|----------|-------------|
| `--code-background` | Inline code background |
| `--code-block-bg` | Code block background |
| `--code-block-border` | Code block border |
| `--code-block-header-bg` | Filename header background |

### Other

| Variable | Description |
|----------|-------------|
| `--radius` | Base border radius |
| `--shadow-sm` through `--shadow-2xl` | Shadow scale |
| `--transition-fast`, `--transition-base`, `--transition-slow` | Animation durations |

---

## Custom JavaScript

Add custom behavior in `scripts.js`:

```js [docs/_custom/scripts.js]
document.addEventListener('DOMContentLoaded', function() {
  // Add custom analytics
  trackPageView(window.location.pathname);

  // Initialize third-party widgets
  initChatWidget();
});
```

:::note
Custom scripts run after all default Docyard scripts have loaded.
:::

---

## Examples

### Purple Theme

```css [docs/_custom/styles.css]
:root {
  --primary: oklch(0.65 0.25 300);
  --primary-foreground: white;
  --sidebar-primary: oklch(0.65 0.25 300);
}

.dark {
  --primary: oklch(0.75 0.2 300);
  --sidebar-primary: oklch(0.75 0.2 300);
}
```

### Compact Layout

```css [docs/_custom/styles.css]
:root {
  --sidebar-width: 14rem;
  --content-max-width: 45rem;
  --spacing-4: 0.875rem;
  --spacing-6: 1.25rem;
}
```

### Custom Font

```css [docs/_custom/styles.css]
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

:root {
  --font-sans: 'Inter', system-ui, sans-serif;
}
```

### Warmer Colors

```css [docs/_custom/styles.css]
:root {
  --background: oklch(0.99 0.01 80);
  --foreground: oklch(0.25 0.02 50);
  --muted: oklch(0.95 0.02 80);
  --border: oklch(0.9 0.02 80);
}

.dark {
  --background: oklch(0.15 0.02 50);
  --foreground: oklch(0.95 0.01 80);
}
```

---

## CLI Options

```bash
docyard customize           # Generate annotated files (default)
docyard customize -m        # Generate minimal files (no comments)
docyard customize --minimal # Same as -m
```

The minimal option creates smaller files without category headers and explanatory comments.

---

## How It Works

**Development (`docyard serve`):**
- Custom CSS is loaded as a separate stylesheet after `main.css`
- Custom JS is loaded as a separate script after `components.js`
- Changes trigger hot reload automatically

**Production (`docyard build`):**
- Custom CSS is appended to the main CSS bundle
- Custom JS is appended to the main JS bundle
- Everything is minified together for optimal performance

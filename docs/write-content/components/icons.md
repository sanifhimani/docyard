---
title: Icons
description: Use Phosphor Icons inline in your content
---

# Icons

Add icons inline using Phosphor Icons.

## Basic Usage

The :rocket-launch: icon represents getting started.

Click the :gear-six: settings icon to configure.

Use :check-circle: for success and :x-circle: for errors.

---

## Weights

Phosphor icons come in six weights:

:heart: Regular | :heart:bold: Bold | :heart:fill: Fill | :heart:light: Light | :heart:thin: Thin | :heart:duotone: Duotone

---

## In Headings

### :rocket-launch: Getting Started

### :gear-six: Configuration

### :book-open: Documentation

---

## In Lists

- :check-circle: Install dependencies
- :check-circle: Configure settings
- :circle: Deploy to production

---

## Common Icons

| Icon | Name |
|------|------|
| :rocket-launch: | `rocket-launch` |
| :book-open: | `book-open` |
| :code: | `code` |
| :gear-six: | `gear-six` |
| :warning: | `warning` |
| :check-circle: | `check-circle` |
| :x-circle: | `x-circle` |
| :info: | `info` |
| :lightning: | `lightning` |
| :download: | `download` |
| :link: | `link` |
| :eye: | `eye` |
| :pencil-simple: | `pencil-simple` |
| :trash: | `trash` |
| :plus: | `plus` |

---

## Finding Icons

Browse the complete library at [Phosphor Icons](https://phosphoricons.com).

Use the icon name exactly as shown, with hyphens:
- `rocket-launch` (not `rocketLaunch`)
- `gear-six` (not `gear6` or `gearSix`)
- `arrow-right` (not `arrowRight`)

---

## Syntax

```markdown
:icon-name:
:icon-name:weight:
```

**Examples:**

```markdown
The :rocket-launch: icon represents getting started.
Click the :gear-six: settings icon to configure.

:heart:          Regular (default)
:heart:bold:     Bold
:heart:fill:     Fill
```

---

## Reference

| Feature | Syntax | Description |
|---------|--------|-------------|
| Icon | `:icon-name:` | Renders icon with regular weight |
| Weight | `:icon-name:weight:` | Renders icon with specified weight |

| Weight | Description |
|--------|-------------|
| `regular` | Default outline style |
| `bold` | Thicker strokes |
| `fill` | Solid filled |
| `light` | Thinner strokes |
| `thin` | Thinnest strokes |
| `duotone` | Two-tone style |

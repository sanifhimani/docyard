---
title: Project Structure
description: How files and directories are organized in a Docyard project
---

# Project Structure

```filetree
my-docs/
  docyard.yml
  docs/
    _sidebar.yml
    index.md
    getting-started.md
    guides/
      deployment.md
    public/
      logo.svg
```

## Configuration

The `docyard.yml` file in your project root controls your site's settings.

```yaml [docyard.yml]
title: My Documentation
description: Documentation for my project

build:
  base: https://docs.example.com
```

This is where you set your site title, description, branding, analytics, and more. See [Configuration](/reference/configuration) for all options.

## Content

The `docs/` directory holds your Markdown files. Each file becomes a page on your site.

| File | URL |
|------|-----|
| `docs/index.md` | `/` |
| `docs/getting-started.md` | `/getting-started` |
| `docs/guides/deployment.md` | `/guides/deployment` |

Organize files however makes sense for your project. Directories become URL segments.

:::note
The `index.md` in your docs root is your landing page. It supports a hero section, feature cards, and custom layouts. See [Landing Pages](/customize/landing-pages) to customize it.
:::

## Navigation

The `_sidebar.yml` file defines your sidebar structure.

```yaml [docs/_sidebar.yml]
- guides:
    text: Guides
    icon: book-open
    items:
      - getting-started
      - deployment

- reference:
    text: Reference
    icon: book-bookmark
    items:
      - api
      - cli
```

Reference pages by filename without the `.md` extension.

:::note
Docyard uses [Phosphor Icons](https://phosphoricons.com). Browse their library to find icons for your sidebar, cards, and components.
:::

## Assets

The `public/` directory holds static files like images, fonts, and downloads. Files are copied to your site root during build.

| Source | URL |
|--------|-----|
| `docs/public/hero.png` | `/hero.png` |
| `docs/public/images/screenshot.png` | `/images/screenshot.png` |

Reference images in your Markdown:

```markdown
![Screenshot](/images/screenshot.png)
```

### Auto-detected Files

Place these files in `public/` and Docyard picks them up automatically:

| File | What it does |
|------|--------------|
| `logo.svg` | Site logo in the header |
| `logo-dark.svg` | Logo for dark mode (optional) |
| `favicon.ico` | Browser tab icon |

No configuration required - just drop the files in.

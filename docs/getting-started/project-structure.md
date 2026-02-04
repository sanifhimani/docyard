---
title: Project Structure
description: Learn how Docyard organizes your docs - content, navigation, assets, and configuration.
social_cards:
  title: Project Structure
  description: How files and directories are organized in Docyard.
---

# Project Structure

Running `docyard init` generates everything you need to get started.

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

You only need to edit what you want to change. Everything works out of the box.

## Content

The `docs/` directory is where your Markdown files live. Each file becomes a page.

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

The `_sidebar.yml` file controls your sidebar. It's generated for you based on your files, but you can customize it.

```yaml [docs/_sidebar.yml]
- getting-started

- guides:
    text: Guides
    icon: book-open
    items:
      - deployment
```

Reference pages by filename without the `.md` extension. See [Sidebar](/customize/sidebar) for more options.

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

### Auto-detected files

Drop these files in `public/` and Docyard picks them up automatically:

| File | What it does |
|------|--------------|
| `logo.svg` | Site logo in the header |
| `logo-dark.svg` | Logo for dark mode (optional) |
| `favicon.ico` | Browser tab icon |

No configuration needed.

## Configuration

The `docyard.yml` file sets your site title and description. Most other settings have sensible defaults.

```yaml [docyard.yml]
title: My Documentation
description: Documentation for my project

build:
  base: https://docs.example.com
```

See [Configuration](/reference/configuration) for all options.

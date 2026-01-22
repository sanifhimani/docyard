---
title: Building
description: Build your documentation for production
---

# Building

Generate optimized static files ready for deployment.

## Build Command

```bash
docyard build
```

This generates a production-ready site in the `dist/` directory.

```filetree
dist/
  _docyard/
    bundle.abc123.css
    bundle.abc123.js
    pagefind/
  getting-started/
    index.html
  index.html
  sitemap.xml
  robots.txt
  llms.txt
```

---

## What Gets Generated

### HTML Pages
Each markdown file becomes a standalone HTML page with all assets inlined for fast loading.

### Asset Bundles
CSS and JavaScript are combined into single files with content-based hashes for cache busting:
- `bundle.abc123.css`
- `bundle.abc123.js`

### SEO Files
- `sitemap.xml` - For search engines
- `robots.txt` - Crawler instructions

### AI-Ready Files
- `llms.txt` - A structured index of your documentation for AI assistants and LLM-powered tools. This follows the [llms.txt specification](https://llmstxt.org) and helps AI models understand your documentation structure.
- `llms-full.txt` - Complete documentation content in a single file, optimized for AI context windows.

### Search Index
Pagefind generates a search index in `_docyard/pagefind/` that powers client-side search.

---

## Configuration

Customize build settings in `docyard.yml`:

```yaml [docyard.yml]
build:
  output: dist
  base: https://docs.example.com
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `output` | `string` | `dist` | Output directory |
| `base` | `string` | `/` | Base URL for sitemap and canonical links |

---

## Build Options

### Clean Build

By default, the output directory is cleaned before each build. To preserve existing files:

```bash
docyard build --no-clean
```

### Verbose Output

See detailed build information:

```bash
docyard build --verbose
```

Shows compression stats, file counts, and timing for each step.

---

## Build Output

A successful build displays a summary:

```
==================================================
Build complete in 1.23s
Output: dist/
42 pages, 2 bundles, 15 static files, 42 pages indexed
==================================================
```

---

## Optimization

Docyard automatically optimizes your build:

**CSS & JavaScript**
- Minified and compressed
- Combined into single bundles
- Content-hashed filenames for cache busting

**Fonts**
- Inter Variable font bundled (single file for all weights)
- Preloaded for fast rendering

**Images**
- Copied from `docs/public/` to output
- Original quality preserved (optimize before adding)


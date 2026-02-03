---
title: Building
description: Build static HTML, CSS, JS, sitemap, and search index for production
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
    og/ # social cards (when enabled)
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

### Social Cards
When enabled, PNG images are generated in `_docyard/og/` for social media sharing. See [Social Cards](/customize/social-cards) to enable.

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

Shows per-page timing, compression stats, and file counts.

### Strict Mode

Fail the build on any validation errors:

```bash
docyard build --strict
```

Or enable in your config:

```yaml [docyard.yml]
build:
  strict: true
```

Strict mode catches broken links, missing images, and other issues. Recommended for CI pipelines.

---

## Build Output

A successful build displays a summary:

```
Generating pages    done (42 pages)
Bundling assets     done (120.0 KB CSS, 48.0 KB JS)
Copying files       done (15 files)
Generating SEO      done (sitemap.xml, robots.txt, llms.txt)
Indexing search     done (42 pages indexed)

Build complete in 1.23s
Output: dist/ (3.2 MB)
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


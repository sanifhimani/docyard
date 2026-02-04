---
title: Building
description: Generate static HTML, CSS, and JS for production deployment.
social_cards:
  title: Building
  description: Generate static files for production.
---

# Building

```bash
docyard build
```

Generates a production-ready site in `dist/`:

```filetree
dist/
  index.html
  getting-started/
    index.html
  sitemap.xml
  robots.txt
  llms.txt
  llms-full.txt
  _docyard/
    bundle.abc123.css
    bundle.abc123.js
    pagefind/ # Search index
    og/ # Social cards
```

---

## What Gets Generated

| Output | Description |
|--------|-------------|
| HTML pages | One file per markdown page, fully standalone |
| `sitemap.xml` | Page index for search engines |
| `robots.txt` | Crawler instructions |
| `llms.txt` | Documentation index for AI tools |
| `llms-full.txt` | Complete docs in one file for AI context |
| `_docyard/*.css` | Minified CSS bundle with content hash |
| `_docyard/*.js` | Minified JS bundle with content hash |
| `_docyard/pagefind/` | Client-side search index |
| `_docyard/og/` | Social card images (when enabled) |

---

## Configuration

```yaml [docyard.yml]
build:
  output: dist
  base: /
  strict: false
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `output` | `string` | `dist` | Output directory |
| `base` | `string` | `/` | Base URL for sitemap and canonical links |
| `strict` | `boolean` | `false` | Fail on broken links and missing images |

---

## CLI Options

| Flag | Description |
|------|-------------|
| `--verbose` | Show per-page timing and compression stats |
| `--strict` | Fail on validation errors (same as config) |
| `--no-clean` | Preserve existing files in output directory |

---

## Strict Mode

Enable strict mode for CI pipelines to catch issues before deployment:

```bash
docyard build --strict
```

Strict mode fails the build on:
- Broken internal links
- Missing images
- Invalid frontmatter
- Sidebar references to non-existent pages

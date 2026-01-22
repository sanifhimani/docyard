---
title: Search
description: Configure full-text search
---

# Search

Docyard includes full-text search powered by [Pagefind](https://pagefind.app). Search is client-side, works offline, and requires no server.

## Configuration

Search is enabled by default. Configure it in `docyard.yml`:

```yaml [docyard.yml]
search:
  enabled: true
  placeholder: "Search documentation..."
```

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+K` / `Ctrl+K` | Open search |
| `/` | Open search (when not in an input) |
| `Escape` | Close search |
| `Arrow Up/Down` | Navigate results |
| `Enter` | Go to selected result |

---

## Exclude Pages

Exclude specific pages or patterns from search results:

```yaml [docyard.yml]
search:
  exclude:
    - "/changelog/*"
    - "/internal/*"
    - "/draft-*"
```

Patterns use glob syntax and match against URL paths.

---

## Development Mode

By default, search is only indexed during `docyard build`. To enable search while developing:

```bash
docyard serve --search
```

This generates a search index at startup. Requires Node.js to be installed (Pagefind is downloaded automatically via npx).

---

## Disable Search

To disable search entirely:

```yaml [docyard.yml]
search:
  enabled: false
```

---

## How It Works

1. **Build time**: Docyard runs Pagefind to index all pages
2. **Client-side**: Search runs entirely in the browser
3. **No server**: Static files only, works on any host
4. **Offline**: Once loaded, search works without internet

The search index is stored in `dist/_docyard/pagefind/`.

---

## Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | `boolean` | `true` | Enable search |
| `placeholder` | `string` | `Search...` | Input placeholder text |
| `exclude` | `array` | `[]` | URL patterns to exclude |

### Exclude Patterns

| Pattern | Matches |
|---------|---------|
| `/changelog/*` | All pages under `/changelog/` |
| `/draft-*` | Pages starting with `/draft-` |
| `/internal/**` | All nested pages under `/internal/` |

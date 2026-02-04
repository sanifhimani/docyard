---
title: Docs for AI
description: Generate llms.txt files so AI tools can understand your documentation.
social_cards:
  title: Docs for AI
  description: llms.txt for Claude Code, Cursor, and ChatGPT.
---

# Docs for AI

Docyard generates `llms.txt` files during every build. AI tools like Claude Code, Cursor, and ChatGPT use these files to understand your documentation.

```filetree
dist/
  llms.txt *
  llms-full.txt
```

| File | Description |
|------|-------------|
| `llms.txt` | Index of all pages with titles, URLs, and descriptions |
| `llms-full.txt` | Complete documentation content in a single file |

---

## Example Output

```txt [llms.txt]
# My Project

> Documentation for My Project

## Docs

- [Introduction](https://docs.example.com/): Get started with My Project
- [Quickstart](https://docs.example.com/quickstart): Install and run in 5 minutes
- [API Reference](https://docs.example.com/api): Complete API documentation
```

---

## URL Configuration

Generated URLs use your `url` setting:

```yaml [docyard.yml]
url: "https://docs.example.com"
```

Without this, URLs will use relative paths.

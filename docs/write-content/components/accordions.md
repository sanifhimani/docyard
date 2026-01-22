---
title: Accordions
description: Collapsible content sections
---

# Accordions

Hide content behind a clickable header. Useful for FAQs, optional details, or reducing page length.

## Basic Usage

:::details{title="Click to expand"}
This content is hidden by default. Click the title to reveal it.

You can include any Markdown content here.
:::

---

## Open by Default

Add `open` to show content expanded initially:

:::details{title="This starts expanded" open}
Users see this content immediately but can still collapse it.
:::

---

## Without Title

Omit the title for a default "Details" header:

:::details
This accordion uses the default title.
:::

---

## FAQ Example

:::details{title="What is Docyard?"}
Docyard is a static site generator for documentation. It transforms Markdown files into a polished documentation website with zero configuration.
:::

:::details{title="Do I need Node.js?"}
No. Docyard is built with Ruby and has no JavaScript build dependencies. Install it with `gem install docyard` and you're ready to go.
:::

:::details{title="Where can I deploy?"}
Anywhere that hosts static files: GitHub Pages, Vercel, Netlify, Cloudflare Pages, or your own server. Just upload the `dist/` directory.
:::

---

## With Code

:::details{title="View the full configuration"}
```yaml [docyard.yml]
title: My Documentation
description: Docs for my project

branding:
  color: "#3b82f6"
  logo: /logo.svg

search:
  enabled: true
  placeholder: Search docs...

socials:
  github: https://github.com/username/repo
  twitter: https://twitter.com/username
```
:::

---

## With Rich Content

:::details{title="Supported Markdown features"}
Accordions support all Markdown features:

- **Bold** and *italic* text
- [Links](https://example.com)
- `inline code`
- Lists and tables

| Feature | Supported |
|---------|-----------|
| Code blocks | Yes |
| Tables | Yes |
| Images | Yes |
| Lists | Yes |
:::

---

## Syntax

```markdown
:::details{title="Your Title"}
Content goes here.
:::

:::details{title="Starts Open" open}
This is expanded by default.
:::

:::details
Uses default "Details" title.
:::
```

---

## Reference

| Attribute | Required | Default | Description |
|-----------|----------|---------|-------------|
| `title` | No | "Details" | Header text |
| `open` | No | `false` | Start expanded |
| Content | No | - | Any Markdown content |

---
title: Abbreviations
description: Define abbreviations once, use them throughout your page.
social_cards:
  title: Abbreviations
  description: Add hover definitions for abbreviations.
---

# Abbreviations

Define abbreviations once. Every occurrence on the page gets a hover tooltip automatically.

## Basic Usage

The HTML specification is maintained by the W3C.

*[HTML]: HyperText Markup Language
*[W3C]: World Wide Web Consortium

Hover over HTML or W3C above to see their definitions.

---

## Technical Terms

Use abbreviations for technical acronyms your readers might not know:

The API returns JSON over HTTPS. Configure your DNS to point to the CDN.

*[API]: Application Programming Interface
*[JSON]: JavaScript Object Notation
*[HTTPS]: Hypertext Transfer Protocol Secure
*[DNS]: Domain Name System
*[CDN]: Content Delivery Network

---

## In Paragraphs

Abbreviations work anywhere in your content. The CSS styles are loaded via the DOM when the page renders in the browser.

*[CSS]: Cascading Style Sheets
*[DOM]: Document Object Model

---

## Abbreviations vs Tooltips

| Feature | Abbreviations | Tooltips |
|---------|---------------|----------|
| Detection | Automatic (all instances) | Manual (per instance) |
| Links | Not supported | Supported |
| Definition location | Bottom of page | Inline |
| Best for | Repeated terms | One-off explanations |

Use **[tooltips](/write-content/components/tooltips)** when you need links or want control over which instances show definitions.

---

## Syntax

```markdown
The HTML specification is maintained by the W3C.

*[HTML]: HyperText Markup Language
*[W3C]: World Wide Web Consortium
```

Place definitions anywhere in your Markdown. Typically at the bottom of the page.

---

## Reference

| Feature | Syntax | Description |
|---------|--------|-------------|
| Definition | `*[TERM]: Description` | Defines an abbreviation |
| Placement | Anywhere | Usually at bottom of file |
| Detection | Automatic | All occurrences become hoverable |

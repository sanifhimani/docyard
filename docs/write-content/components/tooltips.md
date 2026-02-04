---
title: Tooltips
description: Add hover explanations for terms, acronyms, and jargon.
social_cards:
  title: Tooltips
  description: Add hover explanations for terms.
---

# Tooltips

Add hover explanations for terms, acronyms, or jargon.

## Basic Usage

Docyard uses :tooltip[GFM]{description="GitHub Flavored Markdown - an extension of standard Markdown with tables, task lists, strikethrough, and more."} for content.

Hover over "GFM" above to see the tooltip.

---

## With Link

Add a link for users who want more information:

The site is built with an :tooltip[SSG]{description="Static Site Generator - a tool that generates HTML files at build time rather than on each request." link="https://en.wikipedia.org/wiki/Static_site_generator"}.

---

## Custom Link Text

Change the default "Learn more" text:

Configure your :tooltip[DNS]{description="Domain Name System - translates domain names to IP addresses." link="https://www.cloudflare.com/learning/dns/what-is-dns/" link_text="DNS guide"} settings for your custom domain.

---

## Technical Acronyms

Use tooltips to explain technical terms without cluttering your prose:

The :tooltip[CLI]{description="Command Line Interface - a text-based interface for running commands."} provides commands for building and serving your site. Configure :tooltip[TLS]{description="Transport Layer Security - cryptographic protocol for secure communication."} certificates for :tooltip[HTTPS]{description="Hypertext Transfer Protocol Secure - encrypted version of HTTP."}.

---

## Product Terms

Explain product-specific terminology:

Enable :tooltip[hot reload]{description="Automatically refreshes the browser when you save changes to your documentation files."} for faster development.

The :tooltip[sidebar]{description="The navigation panel on the left side of your documentation site, defined in _sidebar.yml."} is configured in YAML.

---

## In Tables

| Feature | Description |
|---------|-------------|
| :tooltip[SSR]{description="Server-Side Rendering - HTML is generated on each request."} | Not supported |
| :tooltip[SSG]{description="Static Site Generation - HTML is generated at build time."} | Fully supported |
| :tooltip[ISR]{description="Incremental Static Regeneration - pages are regenerated after deployment."} | Not supported |

---

## Syntax

```markdown
:tooltip[term]{description="Explanation text"}

:tooltip[term]{description="Explanation" link="https://..."}

:tooltip[term]{description="Explanation" link="https://..." link_text="Custom text"}
```

---

## Reference

| Attribute | Required | Default | Description |
|-----------|----------|---------|-------------|
| `description` | Yes | - | Tooltip text shown on hover |
| `link` | No | - | URL for "Learn more" link |
| `link_text` | No | "Learn more" | Custom link text |

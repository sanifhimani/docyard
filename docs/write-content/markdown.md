---
title: Markdown
description: Write documentation using standard Markdown syntax
---

# Markdown

Docyard uses GitHub Flavored Markdown (GFM). If you've written a README, you already know the basics.

:::tip New to Markdown?
Learn the basics in 10 minutes with the [CommonMark tutorial](https://commonmark.org/help/tutorial/).
:::

## Text Formatting

```markdown
**Bold text** and *italic text*

~~Strikethrough~~ and `inline code`

[Link text](https://example.com)
```

**Bold text** and *italic text*

~~Strikethrough~~ and `inline code`

[Link text](https://example.com)

## Headings

```markdown
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
```

Headings automatically generate anchor links. `## Getting Started` becomes `#getting-started`.

## Lists

```markdown
- First item
- Second item
  - Nested item
  - Another nested item
- Third item

1. First step
2. Second step
3. Third step
```

- First item
- Second item
  - Nested item
  - Another nested item
- Third item

1. First step
2. Second step
3. Third step

## Code Blocks

Use triple backticks with a language identifier:

````markdown
```javascript
function greet(name) {
  return `Hello, ${name}!`;
}
```
````

```javascript
function greet(name) {
  return `Hello, ${name}!`;
}
```

See [Code Blocks](/write-content/components/code-blocks) for line highlighting, titles, and more.

## Tables

```markdown
| Name | Role | Status |
|------|------|--------|
| Alice | Admin | Active |
| Bob | Editor | Active |
| Carol | Viewer | Pending |
```

| Name | Role | Status |
|------|------|--------|
| Alice | Admin | Active |
| Bob | Editor | Active |
| Carol | Viewer | Pending |

## Blockquotes

```markdown
> Documentation is a love letter to your future self.
>
> — Damian Conway
```

> Documentation is a love letter to your future self.
>
> — Damian Conway

## Images

```markdown
![Alt text](/images/screenshot.png)
```

Place images in `docs/public/` and reference them with absolute paths.

## Horizontal Rules

```markdown
---
```

Creates a visual separator between sections.

---

## Frontmatter

Every page starts with YAML frontmatter:

```yaml
---
title: Page Title
description: A brief description for SEO and social sharing
---
```

| Field | Purpose |
|-------|---------|
| `title` | Page title (appears in browser tab and sidebar) |
| `description` | Meta description for search engines |

See [Frontmatter Reference](/reference/frontmatter) for all options.

## Custom Anchors

Override auto-generated heading anchors:

```markdown
## My Heading {#custom-id}
```

Link to it with `[text](#custom-id)`.

## Abbreviations

Define abbreviations once, use them everywhere:

```markdown
The HTML specification is maintained by the W3C.

*[HTML]: HyperText Markup Language
*[W3C]: World Wide Web Consortium
```

The HTML specification is maintained by the W3C.

*[HTML]: HyperText Markup Language
*[W3C]: World Wide Web Consortium

Hover over the abbreviations above to see their definitions.

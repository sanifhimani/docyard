---
title: Includes
description: Reuse content across multiple pages by importing Markdown files.
social_cards:
  title: Includes
  description: Import and reuse content across pages.
---

# Includes

Import content from other Markdown files to avoid repetition.

## Basic Usage

Include content from another file:

```markdown
<!-- @include: ./shared/disclaimer.md -->
```

The included file's content replaces the include directive.

---

## Use Cases

### Shared Warnings

Create a file with common warnings:

```markdown [docs/shared/beta-warning.md]
:::warning Beta Feature
This feature is in beta and may change in future releases.
:::
```

Include it in multiple pages:

```markdown
<!-- @include: ./shared/beta-warning.md -->

## Feature Documentation

Your content here...
```

---

### Reusable Snippets

Share installation instructions:

```markdown [docs/shared/install.md]
```bash
gem install docyard
```
```

```markdown
## Installation

<!-- @include: ./shared/install.md -->
```

---

### Common Sections

Share footer content across pages:

```markdown [docs/shared/support.md]
---

## Need Help?

- Check the [FAQ](/faq)
- Join our [Discord](https://discord.gg/example)
- Open an [issue](https://github.com/example/repo/issues)
```

---

## Path Resolution

### Relative Paths

Paths starting with `./` or `../` are relative to the current file:

```markdown
<!-- @include: ./sibling.md -->
<!-- @include: ../parent/file.md -->
<!-- @include: ./subfolder/file.md -->
```

### Docs Root Paths

Paths without `./` resolve from your docs directory:

```markdown
<!-- @include: shared/common.md -->
```

This includes `docs/shared/common.md`.

---

## Nested Includes

Included files can include other files:

```markdown [docs/shared/header.md]
<!-- @include: ./branding.md -->

# Documentation
```

Docyard prevents circular includes and will show a warning if detected.

---

## Syntax

```markdown
<!-- @include: ./relative/path.md -->

<!-- @include: path/from/docs/root.md -->
```

---

## Reference

| Path Type | Example | Resolves From |
|-----------|---------|---------------|
| Relative | `./file.md` | Current file's directory |
| Parent | `../file.md` | Parent directory |
| Docs root | `file.md` | Docs directory |

| Behavior | Description |
|----------|-------------|
| File types | Only `.md`, `.markdown`, `.mdx` files |
| Circular includes | Detected and prevented with warning |
| Missing files | Shows warning callout |
| Nested includes | Fully supported |

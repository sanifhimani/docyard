---
title: Callouts
description: Tip, warning, danger, note, and important callout boxes in Markdown
---

# Callouts

Draw attention to important information with colored callout boxes.

## Types

:::note
Use notes for additional context or background information.
:::

:::tip
Use tips for helpful suggestions and best practices.
:::

:::important
Use important for key information that shouldn't be missed.
:::

:::warning
Use warnings for potential issues or things to watch out for.
:::

:::danger
Use danger for critical information that could cause serious problems.
:::

---

## Custom Titles

Override the default title by adding text after the type:

:::warning Compatibility Notice
This feature requires Ruby 3.2 or higher.
:::

:::note Before You Begin
Make sure you have completed the [quickstart guide](/getting-started/quickstart) first.
:::

---

## Rich Content

Callouts support full Markdown including code blocks, lists, and links:

:::tip Installation Options
You can install Docyard globally or per-project:

```bash
# Global installation
gem install docyard

# Per-project with Bundler
bundle add docyard
```

See the [quickstart guide](/getting-started/quickstart) for more details.
:::

:::danger Breaking Change
The `config.yml` file has been renamed to `docyard.yml` in v2.0.

**Migration steps:**
1. Rename your config file
2. Update any CI/CD scripts
3. Run `docyard build` to verify
:::

---

## GitHub Alerts

Docyard also supports GitHub-style blockquote alerts:

> [!NOTE]
> This uses GitHub alert syntax.

> [!TIP]
> Helpful advice for the reader.

> [!IMPORTANT]
> Key information users need to know.

> [!WARNING]
> Something to be careful about.

> [!CAUTION]
> Critical warning about potential issues.

---

## Syntax

```markdown
:::type [optional title]
Your content here. Supports **Markdown**.
:::
```

**GitHub alert syntax:**

```markdown
> [!TYPE]
> Your content here.
```

---

## Reference

| Type | Default Title | Use Case |
|------|---------------|----------|
| `note` | Note | General information, context |
| `tip` | Tip | Helpful suggestions, best practices |
| `important` | Important | Key information not to miss |
| `warning` | Warning | Potential issues, cautions |
| `danger` | Danger | Critical problems, breaking changes |

| GitHub Alert | Maps To |
|--------------|---------|
| `[!NOTE]` | `note` |
| `[!TIP]` | `tip` |
| `[!IMPORTANT]` | `important` |
| `[!WARNING]` | `warning` |
| `[!CAUTION]` | `danger` |

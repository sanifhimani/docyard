---
title: Cards
description: Link to pages with visual card components.
social_cards:
  title: Cards
  description: Create visual links to pages or resources.
---

# Cards

Create visual links to other pages or resources.

## Basic Usage

:::cards
::card{title="Getting Started" icon="rocket-launch" href="/getting-started/quickstart"}
Learn how to set up your first documentation site.
::

::card{title="Components" icon="lego" href="/write-content/components"}
Explore all available components.
::

::card{title="Configuration" icon="gear-six" href="/reference/configuration"}
Customize your site settings.
::
:::

---

## Without Icons

:::cards
::card{title="Markdown Guide" href="/write-content/markdown"}
Write content using standard Markdown syntax.
::

::card{title="Project Structure" href="/getting-started/project-structure"}
Understand how files are organized.
::
:::

---

## Without Links

Cards without `href` render as static content boxes:

:::cards
::card{title="Coming Soon" icon="clock"}
This feature is currently in development.
::

::card{title="Enterprise Only" icon="buildings"}
Available for enterprise customers.
::
:::

---

## Without Descriptions

:::cards
::card{title="Quickstart" icon="rocket-launch" href="/getting-started/quickstart"}
::

::card{title="Components" icon="lego" href="/write-content/components"}
::

::card{title="Deploy" icon="cloud-arrow-up" href="/deploy/building"}
::
:::

---

## External Links

:::cards
::card{title="GitHub" icon="github-logo" href="https://github.com/sanifhimani/docyard"}
View the source code and contribute.
::

::card{title="Phosphor Icons" icon="diamond" href="https://phosphoricons.com"}
Browse the complete icon library.
::
:::

---

## With Rich Content

Card descriptions support Markdown:

:::cards
::card{title="Code Features" icon="code" href="/write-content/components/code-blocks"}
Includes **syntax highlighting**, `line numbers`, and diff markers.
::

::card{title="Search" icon="magnifying-glass" href="/customize/search"}
Full-text search powered by **Pagefind**.
::
:::

---

## Syntax

```markdown
:::cards
::card{title="Card Title" icon="icon-name" href="/path"}
Optional description with **Markdown** support.
::

::card{title="Another Card" href="https://example.com"}
External link card.
::
:::
```

---

## Reference

| Attribute | Required | Description |
|-----------|----------|-------------|
| `title` | Yes | Card heading text |
| `icon` | No | Phosphor icon name |
| `href` | No | Link URL (internal or external) |
| Content | No | Description text (supports Markdown) |

Cards without `href` render as `<div>` instead of `<a>`.

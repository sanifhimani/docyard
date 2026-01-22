---
title: Badges
description: Inline status indicators
---

# Badges

Add inline labels to highlight status, versions, or categories.

## Types

:badge[Default] :badge[Success]{type="success"} :badge[Warning]{type="warning"} :badge[Danger]{type="danger"}

---

## Feature Status

Highlight new, beta, or deprecated features:

### Search :badge[New]{type="success"}

The search feature now supports fuzzy matching.

### Dark Mode :badge[Beta]{type="warning"}

Dark mode is available for testing.

### Legacy API :badge[Deprecated]{type="danger"}

The old API will be removed in v3.0.

---

## Version Labels

Mark documentation by version:

### Installation :badge[v1.2.0]

This feature is available in version 1.2.0 and later.

### New Syntax :badge[v2.0.0]{type="warning"}

Breaking change introduced in v2.0.

---

## Inline Usage

Badges work inline with text: The :badge[recommended] approach is to use environment variables for :badge[sensitive]{type="warning"} configuration.

---

## In Tables

| Feature | Status |
|---------|--------|
| Dark mode | :badge[Stable]{type="success"} |
| Search | :badge[Beta]{type="warning"} |
| Plugins | :badge[Coming Soon] |
| Old API | :badge[Deprecated]{type="danger"} |

---

## In Lists

- :badge[Required] Install Ruby 3.0 or later
- :badge[Optional]{type="success"} Configure custom domain
- :badge[Advanced]{type="warning"} Enable experimental features

---

## Syntax

```markdown
:badge[Text]
:badge[Text]{type="success"}
:badge[Text]{type="warning"}
:badge[Text]{type="danger"}
```

---

## Reference

| Type | Syntax | Use Case |
|------|--------|----------|
| Default | `:badge[Text]` | General labels, versions |
| Success | `:badge[Text]{type="success"}` | New features, stable, recommended |
| Warning | `:badge[Text]{type="warning"}` | Beta, experimental, caution |
| Danger | `:badge[Text]{type="danger"}` | Deprecated, breaking changes, errors |

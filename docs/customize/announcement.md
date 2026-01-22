---
title: Announcement
description: Add an announcement banner to your site
---

# Announcement

Display a banner at the top of your site for announcements, updates, or promotions.

## Basic Banner

```yaml [docyard.yml]
announcement:
  text: "We just launched v2.0!"
```

---

## With Link

Make the banner clickable:

```yaml [docyard.yml]
announcement:
  text: "We just launched v2.0!"
  link: "/changelog"
```

---

## With Button

Add a call-to-action button:

```yaml [docyard.yml]
announcement:
  text: "We just launched v2.0!"
  button:
    text: "See what's new"
    link: "/changelog"
```

---

## Dismissible

Banners are dismissible by default. Users can click the X to hide it.

To make a banner persistent (cannot be dismissed):

```yaml [docyard.yml]
announcement:
  text: "Important: Scheduled maintenance on Friday"
  dismissible: false
```

When dismissed, the preference is stored in localStorage for 7 days.

---

## Complete Example

```yaml [docyard.yml]
announcement:
  text: "Version 2.0 is here with new features!"
  link: "https://blog.example.com/v2-release"
  button:
    text: "Read the blog post"
    link: "https://blog.example.com/v2-release"
  dismissible: true
```

---

## Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `text` | `string` | - | Banner text (required) |
| `link` | `string` | - | Makes text clickable |
| `button.text` | `string` | - | Button label |
| `button.link` | `string` | Same as `link` | Button URL |
| `dismissible` | `boolean` | `true` | Allow users to dismiss |

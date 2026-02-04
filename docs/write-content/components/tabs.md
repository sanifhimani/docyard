---
title: Tabs
description: Tabbed content for code examples, platform instructions, and comparisons.
social_cards:
  title: Tabs
  description: Organize content into switchable panels.
---

# Tabs

Organize related content into switchable panels.

## Basic Usage

:::tabs
== First Tab
Content for the first tab.

== Second Tab
Content for the second tab.

== Third Tab
Content for the third tab.
:::

---

## With Icons

Add Phosphor icons before tab labels:

:::tabs
== :terminal-window: Terminal
Run commands in your terminal.

== :code: Editor
Edit files in your code editor.

== :browser: Browser
View the result in your browser.
:::

---

## With Code Blocks

Tabs containing code blocks automatically display language icons:

:::tabs
== JavaScript
```javascript
function greet(name) {
  return `Hello, ${name}!`;
}
```

== Python
```python
def greet(name):
    return f"Hello, {name}!"
```

== Ruby
```ruby
def greet(name)
  "Hello, #{name}!"
end
```
:::

---

## Platform Instructions

Combine icons with code for platform-specific content:

:::tabs
== :apple-logo: macOS
```bash
brew install git
```

== :linux-logo: Linux
```bash
sudo apt install git
```

== :windows-logo: Windows
```powershell
winget install Git.Git
```
:::

---

## Synced Tabs

Tabs with identical labels stay in sync across the page. Click "Python" in either group and both switch together:

:::tabs
== JavaScript
```javascript
const x = 1;
```

== Python
```python
x = 1
```

== Ruby
```ruby
x = 1
```
:::

:::tabs
== JavaScript
```javascript
console.log(x);
```

== Python
```python
print(x)
```

== Ruby
```ruby
puts x
```
:::

Your preference is saved and persists across page loads.

---

## Keyboard Navigation

| Key | Action |
|-----|--------|
| `Arrow Left` / `Arrow Right` | Switch between tabs |
| `Home` | Jump to first tab |
| `End` | Jump to last tab |

---

## Syntax

```markdown
:::tabs
== Tab Label
Content for this tab.

== Another Tab
More content here.
:::
```

**With icons:**

```markdown
:::tabs
== :icon-name: Tab Label
Content here.
:::
```

---

## Reference

| Feature | Syntax | Description |
|---------|--------|-------------|
| Container | `:::tabs` | Required. Wraps all tabs |
| Tab | `== Label` | Required. Creates a new tab |
| Icon | `== :icon: Label` | Optional. Phosphor icon before label |
| Content | Markdown | Any Markdown content after the label |

| Behavior | Description |
|----------|-------------|
| Auto icons | Code blocks auto-detect language icons |
| Synced tabs | Same labels sync across page |
| Persistence | Selected tab saved to localStorage |

---
title: Code Groups
description: Group related code blocks with tabs
---

# Code Groups

Show the same concept in different languages or package managers.

:::note
Code groups support all [code block features](/write-content/components/code-blocks) including line numbers, highlighting, and markers.
:::

## Basic Usage

:::code-group
```npm [npm]
npm install docyard
```

```yarn [yarn]
yarn add docyard
```

```pnpm [pnpm]
pnpm add docyard
```
:::

---

## Language Icons

Icons are automatically detected from the code block language:

:::code-group
```javascript [JavaScript]
const name = "Docyard";
console.log(`Hello, ${name}!`);
```

```python [Python]
name = "Docyard"
print(f"Hello, {name}!")
```

```ruby [Ruby]
name = "Docyard"
puts "Hello, #{name}!"
```
:::

---

## With Filenames

Use descriptive filenames as labels:

:::code-group
```yaml [docyard.yml]
title: My Docs
description: Documentation for my project
branding:
  color: "#3b82f6"
```

```yaml [_sidebar.yml]
- getting-started:
    text: Get Started
    icon: rocket-launch
    items:
      - quickstart
```
:::

---

## With Code Block Features

Combine with line numbers, highlighting, and markers:

:::code-group
```javascript [config.js]:line-numbers {2-3}
export default {
  title: "My Docs",
  description: "Documentation site"
}
```

```python [config.py]:line-numbers {2-3}
config = {
    "title": "My Docs",
    "description": "Documentation site"
}
```
:::

:::code-group
```javascript [Before]
const greeting = "Hello, " + name; // [!code --]
const greeting = `Hello, ${name}!`; // [!code ++]
```

```python [Before]
greeting = "Hello, " + name  # [!code --]
greeting = f"Hello, {name}!"  # [!code ++]
```
:::

---

## Synced Groups

Code groups with identical labels stay in sync across the page:

:::code-group
```npm [npm]
npm install
```

```yarn [yarn]
yarn install
```

```pnpm [pnpm]
pnpm install
```
:::

:::code-group
```npm [npm]
npm run build
```

```yarn [yarn]
yarn build
```

```pnpm [pnpm]
pnpm build
```
:::

Click a tab in one group and all matching tabs switch together.

---

## Code Groups vs Tabs

**Use Code Groups** when showing:
- Same code in different languages
- Same command for different package managers
- Alternative implementations

**Use Tabs** when showing:
- Different types of content (text, config, examples)
- Platform-specific instructions with prose
- Content that isn't just code

---

## Syntax

````markdown
:::code-group
```language [Label]
code here
```

```language [Label]:line-numbers {1,3}
code with features
```
:::
````

---

## Reference

| Feature | Syntax | Description |
|---------|--------|-------------|
| Container | `:::code-group` | Required. Wraps code blocks |
| Label | `[Label]` | Required. Tab label after language |
| Language | ` ```language ` | Optional. Syntax highlighting and auto-icon |

See [Code Blocks](/write-content/components/code-blocks) for line numbers, highlighting, and marker syntax.

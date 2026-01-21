---
title: Components
description: Available documentation components
---

# Components

Docyard comes with a rich set of components to make your documentation shine.

## Callouts

Use callouts to highlight important information:

:::note
This is a note callout for general information.
:::

:::tip
This is a tip callout for helpful suggestions.
:::

:::warning
This is a warning callout for things to watch out for.
:::

:::danger
This is a danger callout for critical warnings.
:::

## Code Blocks

Syntax highlighting with copy button:

```javascript
function greet(name) {
  console.log(`Hello, ${name}!`);
}

greet('World');
```

Code blocks can have titles:

```ruby [config/routes.rb]
Rails.application.routes.draw do
  root 'pages#home'
end
```

And line highlighting:

```python {2-3}
def calculate(x, y):
    result = x + y  # This line is highlighted
    return result   # This one too
```

## Code Groups

Group related code blocks with tabs:

:::code-group
```bash [npm]
npm install my-package
```

```bash [yarn]
yarn add my-package
```

```bash [pnpm]
pnpm add my-package
```
:::

## Steps

Create step-by-step guides:

:::steps
### Create a file

Create a new file called `example.md`.

### Add content

Write your documentation content.

### Preview

Run `docyard serve` to preview.
:::

## Cards

Link to other pages with cards:

:::cards
::card{title="Getting Started" icon="rocket-launch" href="/getting-started"}
Learn the basics
::

::card{title="Configuration" icon="code" href="/getting-started"}
Customize your site
::
:::

## Accordion

Collapsible content sections:

:::details{title="Click to expand"}
This content is hidden by default. Click the title to reveal it.

You can put any content here, including code blocks and other components.
:::

## Badges

Inline status indicators: :badge[New]{type="success"} :badge[Beta]{type="warning"} :badge[Deprecated]{type="danger"}

## File Tree

Display directory structures:

```filetree
src/
  components/
    Button.jsx
    Card.jsx
  utils/
    helpers.js
  index.js
```

## Tables

| Feature | Status | Notes |
|---------|--------|-------|
| Markdown | Supported | Full GFM support |
| Dark Mode | Supported | Automatic |
| Search | Supported | Powered by Pagefind |

## More Components

Docyard supports many more components. Visit the [documentation](https://docyard.org) for the complete list.

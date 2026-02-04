---
title: Code Blocks
description: Syntax highlighting, line numbers, line highlighting, and copy button.
social_cards:
  title: Code Blocks
  description: Syntax highlighting with line numbers and highlighting.
---

# Code Blocks

Display code with syntax highlighting, line numbers, and highlighting.

## Basic

```javascript
function greet(name) {
  return `Hello, ${name}!`;
}
```

---

## Titles

Add a filename header with auto-detected language icons:

```jsx [app.jsx]
export default function App() {
  return <h1>Hello World</h1>
}
```

```python [utils.py]
def calculate(a, b):
    return a + b
```

```bash [deploy.sh]
git push origin main
```

---

## Line Numbers

Display line numbers for reference:

```javascript [config.js]:line-numbers
export default {
  title: "My Docs",
  description: "Documentation site",
  theme: "default"
}
```

Start from a specific line number:

```javascript [app.js]:line-numbers=24
function handleSubmit(event) {
  event.preventDefault();
  saveData(formData);
}
```

---

## Line Highlighting

Draw attention to specific lines:

```javascript {2,4}
function example() {
  const highlighted = true;
  const normal = false;
  return highlighted;
}
```

Highlight ranges:

```javascript {1,3-5}
const first = 1;
const second = 2;
const third = 3;
const fourth = 4;
const fifth = 5;
```

---

## Diff Markers

Show code changes with additions and deletions:

```javascript
function greet(name) {
  return "Hello, " + name; // [!code --]
  return `Hello, ${name}!`; // [!code ++]
}
```

---

## Focus

Dim surrounding code to highlight what matters:

```jsx
import { useState } from 'react';

function Counter() {
  const [count, setCount] = useState(0); // [!code focus]

  return (
    <button onClick={() => setCount(count + 1)}>
      Count: {count}
    </button>
  );
}
```

---

## Error & Warning

Mark lines with errors or warnings:

```javascript
const config = {
  title: "My Docs",
  descrption: "Typo here" // [!code error]
}
```

```javascript
const config = {
  legacyMode: true // [!code warning]
}
```

---

## Combined Features

Mix and match any features:

```typescript [utils.ts]:line-numbers {2,5}
export function calculate(a: number, b: number) {
  const sum = a + b;
  const product = a * b; // [!code focus]
  const diff = a - b; // [!code focus]
  return { sum, product, diff };
}
```

---

## Code Imports

Import code directly from files in your docs directory:

````text
<<< @/examples/config.js
````

Import a named region:

````text
<<< @/examples/app.js#setup
````

Define regions in your source files:

```javascript
// #region setup
const app = createApp();
app.use(router);
// #endregion setup
```

Import with line highlighting:

````text
<<< @/examples/config.js {2-4}
````

---

## Syntax

**Basic fence:**

````markdown
```language
code here
```
````

**With title:**

````markdown
```js [filename.js]
code here
```
````

**With line numbers:**

````markdown
```js:line-numbers
code here
```
````

**With highlights:**

````markdown
```js {1,3-5}
code here
```
````

**Inline markers:**

````markdown
```js
const old = true; // [!code --]
const new = true; // [!code ++]
const focused = true; // [!code focus]
const broken = true; // [!code error]
const deprecated = true; // [!code warning]
```
````

**Full syntax:**

````text
```language [title]:line-numbers {highlights}
````

---

## Reference

| Feature | Syntax | Description |
|---------|--------|-------------|
| Title | `[filename]` | Filename header with auto-detected icon |
| Line numbers | `:line-numbers` | Show line numbers |
| Start line | `:line-numbers=N` | Start numbering from N |
| Highlight | `{1,3-5}` | Highlight specific lines or ranges |

| Marker | Syntax | Effect |
|--------|--------|--------|
| Addition | `// [!code ++]` | Green background |
| Deletion | `// [!code --]` | Red background |
| Focus | `// [!code focus]` | Dims other lines |
| Error | `// [!code error]` | Red error highlight |
| Warning | `// [!code warning]` | Yellow warning highlight |

| Import | Syntax |
|--------|--------|
| File | `<<< @/path/file.js` |
| Region | `<<< @/path/file.js#region-name` |
| With highlights | `<<< @/path/file.js {1-3}` |

**Supported comment styles:** `//`, `#`, `/* */`, `--`, `<!-- -->`, `;`

---
title: Variables
description: Define values once in config and reuse them across all pages.
social_cards:
  title: Variables
  description: Define once, reuse everywhere.
---

# Variables

Define values in `docyard.yml` and reference them across all Markdown pages with `{{ }}` syntax.

```yaml [docyard.yml]
variables:
  version: 2.5.0
  repo: github.com/user/project
  min_ruby: "3.0"
```

```markdown [docs/getting-started.md]
Install version {{ version }} from {{ repo }}.
Requires Ruby {{ min_ruby }} or higher.
```

Renders as: Install version 2.5.0 from github.com/user/project. Requires Ruby 3.0 or higher.

---

## Nested Values

Use dot notation to access nested variables:

```yaml [docyard.yml]
variables:
  links:
    docs: https://docs.example.com
    api: https://api.example.com
```

```markdown
- [Documentation]({{ links.docs }})
- [API Reference]({{ links.api }})
```

---

## Code Blocks

Variables are **not** replaced inside fenced code blocks by default. This keeps code examples with `{{ }}` syntax intact.

To opt in to variable substitution in a specific code block, append `-vars` to the language:

````markdown
```bash-vars
gem install my-gem -v {{ version }}
```
````

The `-vars` suffix is stripped from the rendered output — the block above renders as a normal `bash` code block with the variable replaced.

Code blocks without `-vars` are left untouched:

````markdown
```bash
echo "{{ version }}"
```
````

Renders literally as `{{ version }}`.

---

## Undefined Variables

References to variables that don't exist in your config are left as-is. This prevents accidental breakage if your Markdown contains literal `{{ }}` syntax.

---

## Reference

| Feature | Behavior |
|---------|----------|
| Syntax | `{{ name }}` or `{{ nested.key }}` |
| Whitespace | `{{name}}`, `{{ name }}`, `{{  name  }}` all work |
| Code blocks | Skipped unless language has `-vars` suffix |
| Undefined variables | Left as-is |
| Value types | Numbers and booleans converted to strings |
| Empty strings | Replaced (results in empty output) |
| Included files | Variables are substituted in included content |

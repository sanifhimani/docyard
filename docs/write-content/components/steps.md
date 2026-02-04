---
title: Steps
description: Create numbered step-by-step instructions.
social_cards:
  title: Steps
  description: Guide users through numbered instructions.
---

# Steps

Guide users through a process with numbered steps.

## Basic Usage

:::steps
### Clone the repository

```bash
git clone https://github.com/user/repo.git
cd repo
```

### Install dependencies

```bash
bundle install
```

### Run the tests

```bash
bundle exec rspec
```

All tests should pass before submitting a pull request.
:::

---

## With Rich Content

Each step supports full Markdown including code blocks, lists, tables, and callouts:

:::steps
### Configure Your Site

Edit `docyard.yml` to customize your site:

```yaml [docyard.yml]
title: My Documentation
description: Docs for my project
branding:
  color: "#3b82f6"
```

### Organize Your Content

Create pages in the `docs/` directory:

| File | URL |
|------|-----|
| `docs/index.md` | `/` |
| `docs/guide.md` | `/guide` |
| `docs/api/auth.md` | `/api/auth` |

### Add Navigation

Define your sidebar in `_sidebar.yml`:

```yaml [_sidebar.yml]
- getting-started:
    text: Get Started
    icon: rocket-launch
    items:
      - quickstart
      - installation
```

### Build and Deploy

Build your site for production:

```bash
docyard build
```

Upload the `dist/` directory to any static host.
:::

---

## Minimal Steps

Steps can be simple with just titles:

:::steps
### Clone the repository

### Install dependencies

### Run the tests

### Deploy to production
:::

---

## Syntax

```markdown
:::steps
### First Step Title

Content for the first step.

### Second Step Title

Content for the second step.

### Third Step Title

Content for the third step.
:::
```

---

## Reference

| Feature | Syntax | Description |
|---------|--------|-------------|
| Container | `:::steps` | Required. Wraps all steps |
| Step heading | `### Title` | Required. Creates a new step |
| Content | Markdown | Optional. Any Markdown after the heading |

Steps are automatically numbered starting from 1.

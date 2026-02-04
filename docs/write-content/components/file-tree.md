---
title: File Tree
description: Display directory and file structures with highlighting and comments.
social_cards:
  title: File Tree
  description: Visualize folder and file structures.
---

# File Tree

Visualize folder and file structures.

## Basic Usage

```filetree
src/
  components/
    Button.tsx
    Card.tsx
  utils/
    helpers.ts
  index.ts
```

---

## Highlighting Files

Mark important files with `*`:

```filetree
src/
  components/
    Button.tsx *
    Card.tsx
  index.ts
```

---

## With Comments

Add annotations with `#`:

```filetree
my-docs/
  docyard.yml # Site configuration
  docs/
    _sidebar.yml # Navigation structure
    index.md # Landing page
    public/ # Static assets
```

---

## Project Structure

```filetree
my-docs/
  docyard.yml # Main config
  docs/
    _sidebar.yml # Sidebar navigation
    index.md # Landing page *
    getting-started/
      quickstart.md
      installation.md
      project-structure.md
    write-content/
      markdown.md
      components/
        callouts.md
        tabs.md
        code-blocks.md
    public/
      logo.svg
      favicon.ico
      images/
  dist/ # Build output (generated)
```

---

## Nested Folders

```filetree
app/
  controllers/
    api/
      v1/
        users_controller.rb
        posts_controller.rb
      v2/
        users_controller.rb
    application_controller.rb
  models/
    user.rb
    post.rb
  views/
    layouts/
      application.html.erb
```

---

## Mixed Content

```filetree
project/
  .github/
    workflows/
      ci.yml # CI pipeline
      deploy.yml # Deployment
  src/
    index.ts *
    config.ts
  tests/
    index.test.ts
  package.json
  tsconfig.json
  README.md
```

---

## Syntax

````markdown
```filetree
folder/
  subfolder/
    file.txt
  another-file.js
  highlighted.md *
  annotated.yml # This is a comment
```
````

---

## Reference

| Feature | Syntax | Description |
|---------|--------|-------------|
| Folder | `name/` | Trailing slash marks directories |
| File | `name.ext` | No trailing slash for files |
| Nesting | 2 spaces | Indentation creates hierarchy |
| Highlight | `name *` | Visual emphasis |
| Comment | `name # text` | Inline annotation |

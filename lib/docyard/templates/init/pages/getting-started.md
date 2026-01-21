---
title: Getting Started
description: Get up and running with {{PROJECT_NAME}}
---

# Getting Started

This guide will help you get started with {{PROJECT_NAME}}.

## Prerequisites

Before you begin, make sure you have:

- Basic knowledge of Markdown
- A text editor

## Installation

:::steps
### Step 1: Install Docyard

```bash
gem install docyard
```

### Step 2: Create a new project

```bash
docyard init my-docs
cd my-docs
```

### Step 3: Start the development server

```bash
docyard serve
```

Open http://localhost:4200 in your browser.
:::

## Project Structure

After initialization, your project will look like this:

```filetree
my-docs/
  docyard.yml        # Configuration file
  docs/
    _sidebar.yml     # Sidebar navigation
    index.md         # Home page
    getting-started.md
    components.md
    public/          # Static assets (images, etc.)
```

## Writing Content

Create new pages by adding `.md` files to the `docs/` folder:

```markdown
---
title: My New Page
description: A brief description
---

# My New Page

Your content here...
```

Then add it to `_sidebar.yml`:

```yaml
- my-new-page:
    text: My New Page
    icon: file
```

## Building for Production

When you're ready to deploy:

```bash
docyard build
```

This creates a `dist/` folder with static HTML files ready to deploy anywhere.

## Next Steps

- Explore the [Components](/components) page to see what's available
- Configure your site in `docyard.yml`
- Deploy to GitHub Pages, Vercel, or Netlify

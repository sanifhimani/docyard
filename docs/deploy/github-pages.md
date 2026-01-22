---
title: GitHub Pages
description: Deploy to GitHub Pages
---

# GitHub Pages

Deploy your documentation to GitHub Pages with automated builds.

## GitHub Actions Workflow

Create `.github/workflows/docs.yml`:

```yaml [.github/workflows/docs.yml]
name: Deploy Docs

on:
  push:
    branches: [main]

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.2"

      - name: Install Docyard
        run: gem install docyard

      - name: Build
        run: docyard build

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: dist

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

---

## Enable GitHub Pages

1. Go to your repository **Settings**
2. Navigate to **Pages** in the sidebar
3. Under **Build and deployment**, select **GitHub Actions**

---

## Custom Domain

To use a custom domain:

1. Add a `CNAME` file to `docs/public/`:

```filetree
docs/
  public/
    CNAME *
```

```text [docs/public/CNAME]
docs.example.com
```

2. Update your base URL:

```yaml [docyard.yml]
build:
  base: https://docs.example.com
```

3. Configure DNS with your domain provider

---

## Project Sites

For project sites at `username.github.io/repo-name/`:

```yaml [docyard.yml]
build:
  base: https://username.github.io/repo-name
```

---

## Caching

Speed up builds by caching the Ruby environment:

```yaml [.github/workflows/docs.yml]
- uses: ruby/setup-ruby@v1
  with:
    ruby-version: "3.2"
    bundler-cache: true
```

---

## Branch Protection

Recommended settings for production documentation:

1. Go to **Settings** > **Branches**
2. Add a rule for `main`
3. Enable:
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date

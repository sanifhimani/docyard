---
title: GitHub Pages
description: Deploy Docyard to GitHub Pages with GitHub Actions.
social_cards:
  title: GitHub Pages
  description: Automated deployment with GitHub Actions.
---

# GitHub Pages

Deploy your documentation to GitHub Pages with automated builds or the [deploy command](/deploy/deploy-command).

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
        with:
          fetch-depth: 0

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.2"

      - name: Cache Pagefind
        uses: actions/cache@v4
        with:
          path: ~/.docyard/bin
          key: pagefind-${{ runner.os }}

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

:::tip
The cache step stores the Pagefind binary so it doesn't re-download on every build.
:::

:::important
The `fetch-depth: 0` option is required for accurate "Last updated" timestamps. Without it, all pages show the deployment time instead of their actual modification date.
:::

---

## Enable GitHub Pages

1. Go to repository **Settings** > **Pages**
2. Under **Build and deployment**, select **GitHub Actions**

---

## Custom Domain

Add a `CNAME` file to `docs/public/`:

```text [docs/public/CNAME]
docs.example.com
```

Update your config:

```yaml [docyard.yml]
url: https://docs.example.com
```

---

## Project Sites

For project sites at `username.github.io/repo-name/`:

```yaml [docyard.yml]
url: https://username.github.io/repo-name
build:
  base: /repo-name
```

---

## Social Cards

If you've enabled social cards, add libvips before the build step:

```yaml
- name: Install libvips
  run: sudo apt-get update && sudo apt-get install -y libvips-dev
```

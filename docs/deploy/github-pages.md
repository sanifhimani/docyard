---
title: GitHub Pages
description: Deploy Docyard to GitHub Pages with GitHub Actions workflow
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
        with:
          fetch-depth: 0

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

2. Update your site URL:

```yaml [docyard.yml]
url: https://docs.example.com
```

3. Configure DNS with your domain provider

---

## Project Sites

For project sites at `username.github.io/repo-name/`:

```yaml [docyard.yml]
url: https://username.github.io/repo-name
build:
  base: /repo-name
```

---

## Git History

:::important
The `fetch-depth: 0` option in the workflow above is required for accurate "Last updated" timestamps. Without full git history, all pages will show the deployment time instead of their actual modification date.
:::

If you don't need "Last updated" timestamps, you can omit this option for faster checkouts.

---

## Social Cards

If you've enabled [social cards](/customize/social-cards), add libvips to your workflow:

```yaml [.github/workflows/docs.yml]
steps:
  - uses: actions/checkout@v4
    with:
      fetch-depth: 0

  - name: Install libvips
    run: sudo apt-get update && sudo apt-get install -y libvips-dev

  - uses: ruby/setup-ruby@v1
    with:
      ruby-version: "3.2"

  - name: Install Docyard
    run: gem install docyard

  - name: Build
    run: docyard build
```

---

## Caching

Speed up builds by caching the Ruby environment and Pagefind binary:

```yaml [.github/workflows/docs.yml]
- uses: ruby/setup-ruby@v1
  with:
    ruby-version: "3.2"
    bundler-cache: true

- uses: actions/cache@v4
  with:
    path: ~/.docyard/bin
    key: pagefind-${{ runner.os }}
```

The Pagefind binary is downloaded automatically on first build and cached in `~/.docyard/bin/`. Caching this directory avoids re-downloading on every build.

---

## Branch Protection

Recommended settings for production documentation:

1. Go to **Settings** > **Branches**
2. Add a rule for `main`
3. Enable:
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date

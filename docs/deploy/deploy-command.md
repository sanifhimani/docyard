---
title: Deploy Command
description: Deploy your documentation site to any supported platform with a single command.
social_cards:
  title: Deploy Command
  description: One-command deployment to any platform.
---

# Deploy Command

```bash
docyard deploy --to github-pages
```

Builds and deploys your site in one step. Auto-detects the platform if `--to` is omitted.

---

## Supported Platforms

| Platform | `--to` value | Required CLI |
|----------|-------------|--------------|
| Vercel | `vercel` | `npm i -g vercel` |
| Netlify | `netlify` | `npm i -g netlify-cli` |
| Cloudflare Pages | `cloudflare` | `npm i -g wrangler` |
| GitHub Pages | `github-pages` | <a href="https://cli.github.com" target="_blank">gh</a> |

---

## Options

| Flag | Default | Description |
|------|---------|-------------|
| `--to` | auto-detect | Target platform |
| `--no-prod` | `false` | Deploy a preview instead of production |
| `--skip-build` | `false` | Skip the build step and deploy existing output |

---

## Platform Detection

When `--to` is omitted, the platform is detected from project files in this order:

| File or Directory | Detected Platform |
|-------------------|-------------------|
| `vercel.json` or `.vercel/` | Vercel |
| `netlify.toml` or `.netlify/` | Netlify |
| `wrangler.toml` or `wrangler.jsonc` | Cloudflare Pages |
| `.github/workflows/` | GitHub Pages |

---

## GitHub Pages

Pushes the built site to the `gh-pages` branch on your remote. Configure GitHub Pages to deploy from this branch:

1. Go to **Settings** > **Pages**
2. Set Source to **Deploy from a branch**
3. Select **gh-pages** / **/ (root)**

```bash
docyard deploy --to github-pages
```

For project sites, set the base path in your config:

```yaml [docyard.yml]
build:
  base: /repo-name
```

---

## Vercel

```bash
docyard deploy --to vercel
```

Deploys to production by default. Use `--no-prod` for a preview deployment.

:::important
Authenticate first by running `vercel login`.
:::

---

## Netlify

```bash
docyard deploy --to netlify
```

Deploys to production by default. Use `--no-prod` to get a draft URL.

:::important
Authenticate first by running `netlify login` and link your site with `netlify link`.
:::

---

## Cloudflare Pages

```bash
docyard deploy --to cloudflare
```

The project name is derived from your site title in `docyard.yml`.

:::important
Authenticate first by running `wrangler login`.
:::

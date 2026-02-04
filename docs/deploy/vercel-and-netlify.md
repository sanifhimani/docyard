---
title: Vercel & Netlify
description: Deploy Docyard to Vercel or Netlify with zero configuration.
social_cards:
  title: Vercel & Netlify
  description: Zero-config deployment to Vercel or Netlify.
---

# Vercel & Netlify

Deploy your documentation with zero configuration on Vercel or Netlify.

## Vercel

### Quick Deploy

:::steps
### Push to GitHub

Push your project to a GitHub repository.

### Import on Vercel

Import the repository on <a href="https://vercel.com" target="_blank">vercel.com</a>.

### Configure build settings

| Setting | Value |
|---------|-------|
| Framework Preset | Other |
| Build Command | `gem install docyard && docyard build` |
| Output Directory | `dist` |
| Install Command | (leave empty) |

### Deploy

Click **Deploy**.
:::

### vercel.json

For more control, add a `vercel.json`:

```json [vercel.json]
{
  "buildCommand": "gem install docyard && docyard build",
  "outputDirectory": "dist",
  "installCommand": "echo 'skip'"
}
```

### Git History

:::important
For accurate "Last updated" timestamps, enable deep cloning by adding this environment variable in your Vercel project settings:

| Variable | Value |
|----------|-------|
| `VERCEL_DEEP_CLONE` | `true` |

Without this, all pages will show the deployment time instead of their actual modification date.
:::

### Custom Domain

1. Go to **Settings** > **Domains**
2. Add your domain
3. Update your config:

```yaml [docyard.yml]
url: https://docs.example.com
```

---

## Netlify

### Quick Deploy

:::steps
### Push to GitHub

Push your project to a GitHub repository.

### Import on Netlify

Import the repository on <a href="https://netlify.com" target="_blank">netlify.com</a>.

### Configure build settings

| Setting | Value |
|---------|-------|
| Build Command | `gem install docyard && docyard build` |
| Publish Directory | `dist` |

### Deploy

Click **Deploy site**.
:::

### netlify.toml

For more control, add a `netlify.toml`:

```toml [netlify.toml]
[build]
  command = "gem install docyard && docyard build"
  publish = "dist"

[[redirects]]
  from = "/*"
  to = "/404.html"
  status = 404
```

### Git History

:::important
For accurate "Last updated" timestamps, Netlify needs full git history. Update your build command:

```toml [netlify.toml]
[build]
  command = "git fetch --unshallow || true && gem install docyard && docyard build"
  publish = "dist"
```

The `|| true` ensures the build continues even if the repo is already complete (e.g., during local testing).
:::

### Custom Domain

1. Go to **Domain settings**
2. Add your custom domain
3. Update your config:

```yaml [docyard.yml]
url: https://docs.example.com
```

---

:::tip Social Cards
Both Vercel and Netlify build images include libvips, so [social cards](/customize/social-cards) work out of the box.
:::

:::tip Search
The Pagefind binary is downloaded and cached automatically. Both platforms preserve the cache between builds.
:::

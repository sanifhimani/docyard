---
title: CLI
description: Docyard commands - init, serve, build, deploy, preview, doctor, and customize.
social_cards:
  title: CLI Reference
  description: All Docyard commands and options.
---

# CLI

## docyard init

Create a new Docyard project.

```bash
docyard init [PROJECT_NAME]
```

| Option | Alias | Description |
|--------|-------|-------------|
| `--force` | `-f` | Overwrite existing files |

Creates the following structure:

```filetree
my-docs/
  docyard.yml
  docs/
    _sidebar.yml
    index.md
    getting-started.md
    components.md
    public/
```

---

## docyard serve

Start the development server with hot reload.

```bash
docyard serve
```

| Option | Alias | Default | Description |
|--------|-------|---------|-------------|
| `--port` | `-p` | `4200` | Server port |
| `--host` | `-h` | `localhost` | Host to bind to |
| `--search` | `-s` | `false` | Enable search indexing |

:::tip
Use `--host 0.0.0.0` to expose the server to your local network.
:::

---

## docyard build

Build the static site for production.

```bash
docyard build
```

| Option | Alias | Description |
|--------|-------|-------------|
| `--verbose` | `-v` | Show per-page timing and compression stats |
| `--strict` | | Fail on broken links, missing images, invalid config |
| `--no-clean` | | Preserve existing files in output directory |

:::tip
Use `--strict` in CI pipelines to catch issues before deployment.
:::

---

## docyard deploy

Build and deploy to a hosting platform.

```bash
docyard deploy --to github-pages
```

| Option | Default | Description |
|--------|---------|-------------|
| `--to` | auto-detect | Target platform (`vercel`, `netlify`, `cloudflare`, `github-pages`) |
| `--no-prod` | `false` | Deploy a preview instead of production |
| `--skip-build` | `false` | Skip build, deploy existing output |

See [Deploy Command](/deploy/deploy-command) for platform setup details.

---

## docyard preview

Preview the production build locally.

```bash
docyard build && docyard preview
```

| Option | Alias | Default | Description |
|--------|-------|---------|-------------|
| `--port` | `-p` | `4000` | Server port |

---

## docyard doctor

Check for configuration errors, broken links, missing images, and orphan pages.

```bash
docyard doctor
```

| Option | Description |
|--------|-------------|
| `--fix` | Auto-fix typos, string booleans, missing slashes |

| Check | Severity | Description |
|-------|----------|-------------|
| Config errors | Error | Invalid `docyard.yml` |
| Sidebar errors | Error | Invalid `_sidebar.yml` |
| Broken links | Error | Links to non-existent pages |
| Missing images | Error | Images that don't exist |
| Orphan pages | Warning | Pages not in sidebar |

---

## docyard customize

Generate theme customization files.

```bash
docyard customize
```

| Option | Alias | Description |
|--------|-------|-------------|
| `--minimal` | `-m` | Generate without comments |

Creates `docs/_custom/styles.css` and `docs/_custom/scripts.js`. See [Theming](/customize/theming) for details.

---

## docyard version

Show the installed version.

```bash
docyard version
```

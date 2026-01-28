---
title: CLI
description: Command line interface reference
---

# CLI

Complete reference for Docyard commands.

## docyard init

Initialize a new Docyard project.

```bash
docyard init [PROJECT_NAME]
```

| Option | Alias | Default | Description |
|--------|-------|---------|-------------|
| `--force` | `-f` | `false` | Overwrite existing files |

:::tabs
== Initialize in current directory
```bash
docyard init
```
== Initialize in new directory
```bash
docyard init my-docs
```
== Overwrite existing files
```bash
docyard init --force
```
:::

**Generated files:**

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
docyard serve [OPTIONS]
```

| Option | Alias | Default | Description |
|--------|-------|---------|-------------|
| `--port` | `-p` | `4200` | Port to run the server on |
| `--host` | `-h` | `localhost` | Host to bind the server to |
| `--search` | `-s` | `false` | Enable search indexing |

:::tabs
== Default
```bash
docyard serve
```
== Custom port
```bash
docyard serve -p 3000
```
== With search
```bash
docyard serve --search
```
== Expose to network
```bash
docyard serve --host 0.0.0.0
```
:::

:::note Hot Reload
Hot reload runs on a separate port (main port + 1). When serving on port 4200, the hot reload server uses port 4201.
:::

---

## docyard build

Build the static site for production.

```bash
docyard build [OPTIONS]
```

| Option | Alias | Default | Description |
|--------|-------|---------|-------------|
| `--clean` | - | `true` | Clean output directory before building |
| `--verbose` | `-v` | `false` | Show detailed output |
| `--no-clean` | - | - | Preserve existing output files |

:::tabs
== Standard build
```bash
docyard build
```
== Verbose output
```bash
docyard build --verbose
```
== Preserve existing files
```bash
docyard build --no-clean
```
:::

:::tip
Use `--verbose` to see compression stats and detailed timing for each build step.
:::

---

## docyard preview

Preview the built site locally. Useful for testing production builds before deployment.

```bash
docyard preview [OPTIONS]
```

| Option | Alias | Default | Description |
|--------|-------|---------|-------------|
| `--port` | `-p` | `4000` | Port to run preview server on |

:::tabs
== Build and preview
```bash
docyard build && docyard preview
```
== Custom port
```bash
docyard preview -p 8080
```
:::

:::important
Run `docyard build` first. The preview server serves files from the `dist/` directory.
:::

---

## docyard doctor

Check your documentation for configuration errors, broken links, missing images, and orphan pages.

```bash
docyard doctor [OPTIONS]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--fix` | `false` | Auto-fix fixable issues |

:::tabs
== Check for issues
```bash
docyard doctor
```
== Auto-fix issues
```bash
docyard doctor --fix
```
:::

**What it checks:**

| Check | Severity | Description |
|-------|----------|-------------|
| Config errors | Error | Type mismatches, unknown keys, invalid values in `docyard.yml` |
| Sidebar errors | Error | Unknown keys, typos in `_sidebar.yml` |
| Broken links | Error | Internal links pointing to non-existent pages |
| Missing images | Error | Image references pointing to non-existent files |
| Orphan pages | Warning | Pages not listed in the sidebar |

:::tip Auto-fix
Many config errors are auto-fixable. The `--fix` flag can correct:
- Typos in key names (e.g., `tittle` to `title`)
- String booleans (e.g., `"yes"` to `true`)
- Missing leading slashes in paths
- Misspelled enum values (e.g., `autoo` to `auto`)
:::

---

## docyard version

Show the installed Docyard version.

```bash
docyard version
```

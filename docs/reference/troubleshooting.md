---
title: Troubleshooting
description: Common issues and solutions
---

# Troubleshooting

Solutions for common issues.

## Build Errors

### "Config file not found"

Docyard requires a `docyard.yml` file in your project root.

:::steps
### Initialize a new project
```bash
docyard init
```

### Or create the file manually
```bash
touch docyard.yml
```

### Add minimum required config
```yaml [docyard.yml]
title: My Docs
```
:::

### Configuration errors

Docyard validates `docyard.yml` and `_sidebar.yml` on every `serve` and `build`. Errors include the field name and a helpful message:

```
[ERROR] Config errors in docyard.yml:

  tittle
    unknown key, did you mean 'title'?
```

Run `docyard doctor` for a full report of all issues, or `docyard doctor --fix` to auto-fix typos, boolean strings, and other common mistakes.

### Build fails silently

Enable verbose output to see detailed error messages:

```bash
docyard build -v
```

---

## Development Server

### Port already in use

Another process is using the port.

:::tabs
== Use different port
```bash
docyard serve -p 3000
```
== Find and kill process
```bash
lsof -i :4200
kill -9 <PID>
```
:::

:::note
Hot reload uses a separate port (main port + 1). When serving on port 4200, ensure port 4201 is also available.
:::

### Hot reload not working

:::steps
### Check that you're editing files in the `docs/` directory

### Ensure the file has a supported extension
- `.md` - Markdown files
- `.yml` - Sidebar configuration
- `.css` - Stylesheets
- `.js` - JavaScript

### Try restarting the server
```bash
# Stop with Ctrl+C, then restart
docyard serve
```
:::

### Changes not appearing

Clear your browser cache with a hard refresh:

:::tabs
== :apple-logo: Mac
`Cmd + Shift + R`
== Windows / Linux
`Ctrl + Shift + R`
:::

---

## Search

### Search not working in development

Search is disabled by default during development to speed up startup.

```bash
docyard serve --search
```

:::note
This generates a search index at startup, which adds a few seconds to the initial load.
:::

### Search shows no results

:::steps
### Check pages aren't excluded in config
```yaml [docyard.yml]
search:
   exclude:
      - "/draft-*"  # Make sure this isn't matching your pages
```

### Rebuild the search index
```bash
docyard build
```
:::

---

## Sidebar

### Pages not appearing in sidebar

With `sidebar: config` (default), pages must be explicitly listed in `_sidebar.yml`:

```yaml [docs/_sidebar.yml]
- getting-started:
    items:
      - quickstart
      - my-new-page  # Add your page here
```

:::tip
Use `sidebar: auto` to automatically generate the sidebar from your directory structure.
:::

### Sidebar order is wrong

The sidebar follows the order in `_sidebar.yml`, not alphabetical or file system order. Reorder items in the YAML file to change the display order.

---

## Styling

### Custom styles not applying

:::steps
### Place CSS files in `docs/public/`
```filetree
docs/
   public/
      custom.css *
```

### Files are automatically included in the build - no import needed
:::

### Code blocks look broken

Check for unclosed fences. Each code block needs opening and closing backticks:

````markdown
```javascript
// Your code here
```
````

:::danger
Missing closing backticks will break rendering for the rest of the page.
:::

---

## Deployment

### 404 errors on refresh

Docyard generates static HTML for each page, so this usually isn't needed. If you're getting 404s:

:::steps
### Ensure all pages are built
```bash
docyard build --verbose
```

### Check that your hosting serves `.html` files correctly
:::

### Assets not loading

Check your `base` path and `url` match your deployment:

:::tabs
== Custom domain
```yaml [docyard.yml]
url: https://docs.example.com
build:
  base: /
```
== GitHub project site
```yaml [docyard.yml]
url: https://username.github.io/repo-name
build:
  base: /repo-name
```
:::

:::note
`base` is the path prefix (must start with `/`). Use the top-level `url` field for your full production URL.
:::

### Images not displaying

Files in `docs/public/` are copied to the root of your built site. Reference them with root-relative paths (not `/public/...`).

:::steps
### Place images in `docs/public/`
```filetree
docs/
  public/
    images/
      screenshot.png *
```

### Reference from root (not `/public/`)
```markdown
![Screenshot](/images/screenshot.png)
```
:::

---

## Performance

### Build is slow

For large sites (100+ pages), builds run in parallel automatically. If still slow:

:::details{title="Optimization tips"}
- **Optimize images** - Compress before adding to `docs/public/`
- **Reduce includes** - Each include adds processing overhead
- **Simplify nesting** - Deeply nested components are slower to render
:::

### Page load is slow

:::details{title="Optimization tips"}
- **Optimize images** - Use compressed formats (WebP, optimized PNG/JPG)
- **Use video embeds** - Embed YouTube/Vimeo instead of self-hosting videos
- **Check DevTools** - Network tab shows which assets are largest
:::

---

## Getting Help

If you're still stuck:

:::cards
::card{title="GitHub Issues" icon="github-logo"}
Search [existing issues](https://github.com/sanifhimani/docyard/issues) for similar problems.
::

::card{title="Open an Issue" icon="plus-circle"}
Include: Docyard version, Ruby version, OS, steps to reproduce, and error messages with `--verbose` output.
::
:::

<p align="center">
  <a href="https://docyard.dev">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="docs/public/logo-dark.svg">
      <img src="docs/public/logo.svg" height="60" alt="Docyard">
    </picture>
  </a>
</p>

<p align="center">
  Markdown to docs in seconds. No Node.js required.
</p>

<p align="center">
  <a href="https://github.com/sanifhimani/docyard/actions/workflows/ci.yml"><img src="https://github.com/sanifhimani/docyard/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://badge.fury.io/rb/docyard"><img src="https://badge.fury.io/rb/docyard.svg" alt="Gem Version"></a>
  <a href="https://github.com/sanifhimani/docyard/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"></a>
</p>

<p align="center">
  <a href="https://docyard.dev">Docs</a> ·
  <a href="https://docyard.dev/getting-started/quickstart">Quickstart</a> ·
  <a href="https://github.com/sanifhimani/docyard/blob/main/CHANGELOG.md">Changelog</a>
</p>

---

## Install

```bash
gem install docyard
docyard init
docyard serve
```

Open `localhost:4200`. Edits reload instantly.

## Example

```markdown
:::note
Requires Ruby 3.2 or higher.
:::

:::tabs
== macOS
brew install ruby

== Linux
sudo apt install ruby-full
:::
```

Callouts, tabs, steps, cards, code groups, accordions, and more. [See all components](https://docyard.dev/write-content/components)

## Build

```bash
docyard build
```

Static HTML, search index, sitemap, and social cards in `dist/`. Deploy anywhere.

## Docs

[docyard.dev](https://docyard.dev) is built with Docyard.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)

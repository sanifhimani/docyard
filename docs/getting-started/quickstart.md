---
title: Quickstart
description: Install Docyard and create a documentation site in three commands.
social_cards:
  title: Get started in 3 commands
  description: Install Docyard and start writing docs.
---

# Quickstart

Three commands to a running docs site.

:::steps
### Install

```bash-vars
gem install docyard -v {{ version }}
```

### Create

```bash
docyard init my-docs
cd my-docs
```

### Run

```bash
docyard serve
```

Open [localhost:{{ default_port }}](http://localhost:{{ default_port }}). Your site is running.
:::

## Make a change

Open `docs/getting-started.md`, edit something, save. The browser updates automatically.

Try adding a component:

```markdown
:::note
Docyard supports callouts, tabs, steps, and more.
:::
```

## Build for production

```bash
docyard build
```

Static files are generated in `dist/`. Deploy to any host.

## Need Ruby?

Docyard requires Ruby {{ min_ruby }}+. Check your version:

```bash
ruby -v
```

If you need to install or upgrade Ruby, see the official <a href="https://www.ruby-lang.org/en/documentation/installation/" target="_blank">Ruby installation guide</a>.
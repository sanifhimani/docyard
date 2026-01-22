---
title: Introduction
description: What is Docyard and why use it for your documentation
---

# Introduction

Docyard is a static site generator for documentation. It transforms your Markdown files into a polished, searchable documentation website with sensible defaults and zero configuration.

```bash
gem install docyard
docyard init my-docs
docyard serve
```

## Features

:::cards
::card{title="Syntax Highlighting" icon="code"}
Over 100 languages supported out of the box with automatic language detection.
::

::card{title="Full-Text Search" icon="magnifying-glass"}
Pagefind-powered search that works entirely client-side. Fast, private, and offline-capable.
::

::card{title="Dark Mode" icon="moon"}
Automatic theme switching based on system preferences, with manual toggle available.
::

::card{title="Components" icon="lego"}
Callouts, tabs, code groups, steps, cards, and more. All with clean, consistent styling.
::

::card{title="Responsive Design" icon="device-mobile"}
Optimized for every screen size with touch-friendly navigation on mobile.
::

::card{title="Deploy Anywhere" icon="cloud-arrow-up"}
Generates static HTML that works on any hosting platform.
::
:::

## How It Works

:::steps
### Write

Create your documentation in Markdown. Organize files however you like - Docyard figures out the structure.

### Preview

Run `docyard serve` to start a local server with hot reload. See your changes instantly.

### Build

Run `docyard build` to generate optimized static files ready for production.

### Deploy

Upload the output to GitHub Pages, Vercel, Netlify, or any static hosting service.
:::

## Built With Ruby

Docyard is distributed as a Ruby gem. A single install gives you everything - the CLI, the build system, and all dependencies bundled together.

:::tip
Already have Ruby installed? You're one command away from your first docs site.
:::


---
title: Quickstart
description: Create your first Docyard site in under five minutes
---

# Quickstart

Get a documentation site running locally in five minutes.

## Prerequisites

Docyard requires Ruby 3.2 or higher.

:::tabs
== :apple-logo: macOS
```bash
brew install ruby
```

Add Homebrew Ruby to your path by following the instructions shown after installation.

== :linux-logo: Linux
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install ruby-full

# Fedora
sudo dnf install ruby
```

== :windows-logo: Windows
Install [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) and then Ruby:

```bash
wsl --install
```

After WSL installs and you've set up Ubuntu, install Ruby:

```bash
sudo apt update && sudo apt install ruby-full
```
:::

Verify your Ruby version:

```bash
ruby -v
```

## Install Docyard

```bash
gem install docyard
```

Verify the installation:

```bash
docyard version
```

## Create a Project

```bash
docyard init my-docs
cd my-docs
```

This creates a new directory with your configuration and starter pages.

## Start the Server

```bash
docyard serve
```

Open [http://localhost:4200](http://localhost:4200) in your browser. You should see your new documentation site.

:::note
The server watches for changes. Edit any Markdown file and the browser refreshes automatically.
:::

## Edit Your First Page

Open `docs/getting-started.md` in your editor. Make a change, save the file, and watch it update in the browser.

Try adding a callout:

```markdown
:::note
This is my first Docyard site!
:::
```

## Build for Production

When you're ready to deploy:

```bash
docyard build
```

This generates a `dist/` directory containing static HTML, CSS, and JavaScript. Upload these files to any web host.

## What's Next

:::cards
::card{title="Writing" icon="markdown-logo" href="/write-content/markdown"}
Start writing your documentation content.
::

::card{title="Components" icon="lego" href="/write-content/components"}
Explore callouts, tabs, code blocks, and more.
::

::card{title="Configuration" icon="gear-six" href="/reference/configuration"}
Customize your site's title, logo, and colors.
::
:::

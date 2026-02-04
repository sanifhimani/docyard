---
title: Branding
description: Customize logo, favicon, brand colors, copyright, and social links.
social_cards:
  title: Branding
  description: Logo, favicon, colors, and social links.
---

# Branding

Customize your logo, favicon, brand color, and social links.

## Logo

Place a logo file in `docs/public/` and Docyard auto-detects it:

```filetree
docs/
  public/
    logo.svg *
    logo-dark.svg # Optional dark mode variant
```

Supported formats: `.svg`, `.png`

### Dark Mode Logo

If you have a `logo.svg`, Docyard automatically looks for `logo-dark.svg` in the same directory. This variant displays when users switch to dark mode.

### Manual Configuration

Override auto-detection by specifying the path explicitly:

```yaml [docyard.yml]
branding:
  logo: "/images/my-logo.png"
```

---

## Favicon

Place a favicon in `docs/public/` for auto-detection:

```filetree
docs/
  public/
    favicon.svg *
```

Supported formats: `.ico`, `.svg`, `.png` (checked in that order)

Or specify manually:

```yaml [docyard.yml]
branding:
  favicon: "/images/favicon.ico"
```

---

## Primary Color

Set your brand color used for links, buttons, and accents:

```yaml [docyard.yml]
branding:
  color: "#3b82f6"
```

### Light & Dark Variants

Use different colors for light and dark modes:

```yaml [docyard.yml]
branding:
  color:
    light: "#2563eb"
    dark: "#60a5fa"
```

---

## Footer

### Copyright

Add a copyright notice to the footer:

```yaml [docyard.yml]
branding:
  copyright: "2025 Acme Inc. All rights reserved."
```

### Credits

The "Built with Docyard" link appears in the footer by default. To remove it:

```yaml [docyard.yml]
branding:
  credits: false
```

---

## Social Links

Add social media links to your footer:

```yaml [docyard.yml]
socials:
  github: "https://github.com/your-org/your-repo"
  discord: "https://discord.gg/your-server"
  twitter: "https://twitter.com/your-handle"
```

Icons are automatically detected based on the platform name.

### Custom Links

Add links with custom Phosphor icons for platforms not in the built-in list:

```yaml [docyard.yml]
socials:
  github: "https://github.com/your-org/your-repo"
  custom:
    - icon: rss
      href: /feed.xml
    - icon: envelope
      href: mailto:hello@example.com
```

### Supported Platforms

:::tabs
== Popular
| Platform | Key |
|----------|-----|
| GitHub | `github` |
| Discord | `discord` |
| Twitter/X | `twitter` or `x` |
| LinkedIn | `linkedin` |
| YouTube | `youtube` |
| Slack | `slack` |
| Mastodon | `mastodon` |

== Social
| Platform | Key |
|----------|-----|
| Instagram | `instagram` |
| Facebook | `facebook` |
| TikTok | `tiktok` |
| Reddit | `reddit` |
| Threads | `threads` |
| Pinterest | `pinterest` |
| Snapchat | `snapchat` |
| WhatsApp | `whatsapp` |
| Telegram | `telegram` |

== Developer
| Platform | Key |
|----------|-----|
| GitLab | `gitlab` |
| CodePen | `codepen` |
| CodeSandbox | `codesandbox` |
| Figma | `figma` |
| Dribbble | `dribbble` |
| Behance | `behance` |
| Medium | `medium` |
| Notion | `notion` |

== Other
| Platform | Key |
|----------|-----|
| Twitch | `twitch` |
| Spotify | `spotify` |
| SoundCloud | `soundcloud` |
| Patreon | `patreon` |
| PayPal | `paypal` |
| Stripe | `stripe` |
| Apple Podcasts | `apple-podcasts` |
| Google Podcasts | `google-podcasts` |
:::

---

## Complete Example

```yaml [docyard.yml]
title: "My Project"
description: "Documentation for My Project"

branding:
  color:
    light: "#0066cc"
    dark: "#3399ff"
  copyright: "2025 My Company"
  credits: true

socials:
  github: "https://github.com/my-org/my-project"
  discord: "https://discord.gg/my-server"
  twitter: "https://twitter.com/my-handle"
```

---

## Reference

### Auto-Detection

| Asset | Filenames Checked | Location |
|-------|-------------------|----------|
| Logo | `logo.svg`, `logo.png` | `docs/public/` |
| Dark logo | `logo-dark.svg`, `logo-dark.png` | `docs/public/` |
| Favicon | `favicon.ico`, `favicon.svg`, `favicon.png` | `docs/public/` |

### Branding Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `logo` | `string` | Auto-detected | Path to logo file |
| `favicon` | `string` | Auto-detected | Path to favicon file |
| `color` | `string` or `object` | - | Primary brand color |
| `color.light` | `string` | - | Color for light mode |
| `color.dark` | `string` | - | Color for dark mode |
| `copyright` | `string` | - | Footer copyright text |
| `credits` | `boolean` | `true` | Show "Built with Docyard" |

### Socials

| Option | Type | Description |
|--------|------|-------------|
| `socials.<platform>` | `string` | URL for the platform |

All 33 platforms listed above are supported with automatic icon detection.

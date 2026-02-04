---
title: Error Pages
description: Customize the 404 page.
social_cards:
  title: Error Pages
  description: Customize the 404 page.
---

# Error Pages

Customize what users see when they visit a non-existent page.

## Custom 404 Page

Create a `404.html` file in your docs directory:

```filetree
docs/
  404.html *
  index.md
  getting-started.md
```

This file will be used as-is for all 404 responses. You have full control over the HTML, CSS, and JavaScript.

### Example

```html [docs/404.html]
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Page Not Found</title>
  <style>
    body {
      font-family: system-ui, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      text-align: center;
    }
    h1 { font-size: 4rem; margin: 0; }
    p { color: #666; }
    a { color: #3b82f6; }
  </style>
</head>
<body>
  <div>
    <h1>404</h1>
    <p>This page doesn't exist.</p>
    <p><a href="/">Go back home</a></p>
  </div>
</body>
</html>
```

---

## Default 404

If no custom `404.html` exists, Docyard generates a styled fallback page that matches your site's theme.

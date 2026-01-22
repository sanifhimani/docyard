---
title: Images & Videos
description: Add images with captions and embed videos
---

# Images & Videos

Enhance your documentation with images and video embeds.

## Static Assets

Place images and videos in `docs/public/`. During build, these files are copied to the root of your site.

```filetree
docs/
  public/
    images/
      logo.png
    videos/
      demo.mp4
```

Reference them with root-relative paths:

```markdown
![Logo](/images/logo.png)
::video[/videos/demo.mp4]
```

---

## Images

### Basic Image

![Toronto skyline](/images/toronto-skyline.jpg)

### With Caption

Add a caption using the `caption` attribute:

![Toronto skyline at dusk](/images/toronto-skyline.jpg){caption="Photo by Christopher Becke on Pexels"}

### With Dimensions

Control image size with `width` and `height`:

![Toronto skyline](/images/toronto-skyline.jpg){width="400"}

### Disable Lightbox

Prevent the image from opening in a lightbox:

![Toronto skyline](/images/toronto-skyline.jpg){width="200" nozoom}

---

## YouTube

Embed YouTube videos with privacy-friendly mode (no cookies):

::youtube[GXnfBYPsAuE]

### With Start Time

Start the video at a specific time:

::youtube[GXnfBYPsAuE]{start="60"}

---

## Vimeo

Embed Vimeo videos with Do Not Track enabled:

::vimeo[203506981]

---

## Native Video

You can also host your own video files. Place them in `docs/public/` and reference them using the syntax shown below.

---

## Syntax

**Images:**

```markdown
![Alt text](/path/to/image.png)

![Alt text](/image.png){caption="Figure caption"}

![Alt text](/image.png){width="600" height="400"}

![Alt text](/image.png){nozoom}

![Alt text](/image.png){caption="Caption" width="600" nozoom}
```

**YouTube:**

```markdown
::youtube[VIDEO_ID]

::youtube[VIDEO_ID]{start="30"}

::youtube[VIDEO_ID]{autoplay muted loop}
```

**Vimeo:**

```markdown
::vimeo[VIDEO_ID]

::vimeo[VIDEO_ID]{autoplay muted}
```

**Native Video:**

```markdown
::video[/path/to/video.mp4]{controls}

::video[/path/to/video.mp4]{controls autoplay muted loop}

::video[/path/to/video.mp4]{controls poster="/poster.jpg" preload="metadata"}
```

---

## Reference

### Image Attributes

| Attribute | Description |
|-----------|-------------|
| `caption` | Figure caption text |
| `width` | Image width in pixels |
| `height` | Image height in pixels |
| `nozoom` | Disable lightbox on click |

### Video Attributes

| Attribute | YouTube | Vimeo | Native | Description |
|-----------|:-------:|:-----:|:------:|-------------|
| `start` | Yes | - | - | Start time in seconds |
| `autoplay` | Yes | Yes | Yes | Auto-start playback |
| `muted` | Yes | Yes | Yes | Mute audio |
| `loop` | Yes | Yes | Yes | Loop playback |
| `controls` | Yes | Yes | Yes | Show player controls |
| `poster` | - | - | Yes | Preview image URL |
| `preload` | - | - | Yes | `auto`, `metadata`, or `none` |
| `playsinline` | - | - | Yes | Inline playback on mobile |
| `nofullscreen` | Yes | Yes | - | Disable fullscreen |
| `width` | Yes | Yes | Yes | Player width |
| `height` | Yes | Yes | Yes | Player height |
| `title` | Yes | Yes | - | Accessibility title |

### Privacy

- **YouTube**: Uses `youtube-nocookie.com` (no tracking cookies)
- **Vimeo**: Uses `dnt=1` parameter (Do Not Track)

---

*Image credit: [Photo by Christopher Becke](https://www.pexels.com/photo/landscape-photography-of-toronto-canada-2792670/) on Pexels. Video credits: [BBC Earth](https://www.youtube.com/c/bbcearth) on YouTube, [Yosemite Winter Wonders by Rudy Wilms](https://vimeo.com/rudywilms) on Vimeo.*

# Product Context

## Target Audience

Jekyll site authors who want automatic image optimization without manually producing thumbnails. Primary audiences:

- Bloggers and content authors who use Markdown with raw `<img>` tags or `![alt](src)` references and don't want to maintain separate thumbnail assets.
- Theme authors and hobbyist site maintainers who need their images down-sized to layout constraints (max width / max height) without bespoke pipelines.
- Users of the sibling plugins in the Texarkanine Jekyll family (e.g. `jekyll-highlight-cards`, `jekyll-mermaid-prebuild`) who expect a shared "install and forget" UX.

## Use Cases

- **Explicit sizing**: An image has `width` and/or `height` attributes; the plugin produces a thumbnail sized exactly for that slot and rewrites `src`.
- **Global cap**: The site sets `auto_thumbnails.max_width` / `max_height` and raw, unsized images larger than those dimensions are thumbnailed automatically.
- **Markdown-native**: Works transparently with any Markdown renderer because it operates on the rendered HTML, not the Markdown source.
- **CI / incremental builds**: MD5-keyed cache under `.jekyll-cache/` means unchanged images skip regeneration, keeping rebuilds fast.

## Key Benefits

- Zero authoring friction: no special Liquid tags, shortcodes, or front-matter. Authors keep writing normal image references.
- Automatic size-aware optimization that respects layout intent (attribute sizing beats global caps).
- Deterministic, cache-friendly output filenames (source hash + dimensions in the name).
- Works with any Markdown processor and any Jekyll theme that uses `<article>` as the content wrapper.

## Success Criteria

- Images inside `<article>` tags with width/height attributes or exceeding configured caps are replaced with correctly-sized thumbnails in the published site.
- Builds remain correct and fast across repeated runs: unchanged inputs should not regenerate thumbnails.
- The plugin does not break site output for pages that contain no replaceable images (no spurious markup changes, no invalid HTML).
- Output markup remains valid HTML5 on modern themes.

## Key Constraints

- **ImageMagick dependency**: Requires either ImageMagick 6 (`convert`/`identify`) or ImageMagick 7 (`magick convert`/`magick identify`) on the build host. If missing, the plugin logs and skips rather than failing the build.
- **Content scope**: Only images inside `<article>` elements are eligible. Images in headers, sidebars, or non-article regions are deliberately ignored.
- **Licensing**: AGPL-3.0-or-later. Any redistribution or SaaS use must honor AGPL obligations.
- **Ruby / Jekyll floor**: Ruby >= 3.3, Jekyll 4.x (< 5). Nokogiri ~> 1.15 is a hard runtime dependency for HTML rewriting.
- **Safety**: Thumbnails are served from `.jekyll-cache/` and copied into `_site/`. The plugin must never mutate source images or author-provided files in place.

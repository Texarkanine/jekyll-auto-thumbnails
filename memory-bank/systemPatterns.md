# System Patterns

## How This System Works

The gem is a thin Jekyll plugin that hooks three site-level events and threads state through `site.data`:

1. `:site, :post_read` → `Hooks.initialize_system` builds a `Configuration`, an empty `Registry`, and a `Generator`. These three objects are stashed under `site.data["auto_thumbnails_*"]` and are the only long-lived state for the run.
2. `:site, :post_render` → `Hooks.process_site` walks `site.documents + site.pages`, filters to HTML-ish outputs via `Hooks.html_document?`, and feeds each rendered `doc.output` string through `Scanner.scan_html`, which populates the registry with `{src_url => {width, height}}` requirements. After scanning, the generator materializes thumbnails on disk (under `.jekyll-cache/jekyll-auto-thumbnails/`) and a `url_map` of `original_src => thumbnail_src` is built. Finally, every HTML document's `doc.output` is rewritten in place via `Hooks.replace_urls`, which parses the HTML, rewrites matching `<article><img src>` attributes, and re-serializes.
3. `:site, :post_write` → `Hooks.copy_thumbnails` copies each cached thumbnail from `.jekyll-cache/` into the final `_site/` output, preserving the URL directory layout.

The critical coupling: the rewrite pass (`replace_urls`) runs on *every* HTML page, not just pages whose images matched. Any cost or side-effect introduced by the HTML parser/serializer therefore touches the entire site. Today Nokogiri's HTML4 parser injects an `http-equiv` Content-Type `<meta>` on every page it round-trips, which breaks HTML5 validity on themes that already emit `<meta charset="utf-8">`. That is a load-bearing footgun, not an implementation detail: anyone changing the rewrite path must preserve idempotence on pages with no replacements and must not inject new markup.

Ownership stays narrow. The plugin only touches `<article> img` elements. It does not traverse `<head>`, navigation, or sidebars, and it must not. Images outside `<article>` are intentionally invisible to both the scanner and the rewriter.

## Hook State via `site.data`

All cross-hook state lives under keys in `site.data`: `auto_thumbnails_config`, `auto_thumbnails_registry`, `auto_thumbnails_generator`, `auto_thumbnails_url_map`. There is no module-level singleton. This pattern matters because Jekyll may construct multiple sites in one process (tests, `jekyll serve` rebuilds) and isolating state per site is the only thing keeping them from cross-contaminating. New state added to the plugin should follow the same convention rather than introducing class variables or globals.

## MD5-Addressed Cache

Generated thumbnails are named `<base>_thumb-<md5>-<WxH>.<ext>` and stored under `.jekyll-cache/jekyll-auto-thumbnails/`. The hash keys off source bytes (see `digest_calculator.rb`), so changes to the source image break cache and regenerate automatically; changes to requested dimensions pick a different filename entirely. This is why the plugin can safely reuse cached thumbnails without tracking timestamps.

## `<article>` as the Content Boundary

`Scanner.scan_html` and `Hooks.replace_urls` both use the CSS selector `article img`. This is the only boundary the plugin respects. It is deliberate and stable: themes that wrap their main content in `<article>` (including the Jekyll default and the common minimalist themes) get thumbnailing; images in headers, footers, and nav elements are left alone even if they are inside the same HTML document.

## ImageMagick Version Auto-Detection

`ImagemagickWrapper` probes for ImageMagick 7 (`magick convert`) first and falls back to ImageMagick 6 (bare `convert` / `identify`). If neither is present, `process_site` logs a warning and short-circuits without raising. Callers should assume the wrapper may report "unavailable" and plan for a no-op build.

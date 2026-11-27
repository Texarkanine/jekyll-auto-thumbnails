# Automatic Image Thumbnails for Jekyll

[![Gem Version](https://badge.fury.io/rb/jekyll-auto-thumbnails.svg)](https://rubygems.org/gems/jekyll-auto-thumbnails)
[![code coverage](https://codecov.io/gh/Texarkanine/jekyll-auto-thumbnails/graph/badge.svg)](https://codecov.io/gh/Texarkanine/jekyll-auto-thumbnails)

Scans your rendered HTML for local images with `width` or `height` attributes, then automatically generates and uses appropriately-sized thumbnails for them, if the `src` image is bigger than that.

Can also take global maximum dimensions (such as for fixed-width layouts) and thumbnail images that don't have explicit size attributes, too.

Requires [ImageMagick](https://imagemagick.org) to be installed.

## Installation

Add to your `Gemfile`:

```ruby
group :jekyll_plugins do
  gem "jekyll-auto-thumbnails"
end
```

Run:

```bash
bundle install
```

**System Requirement**: ImageMagick must be installed. The gem supports both:
- **ImageMagick 6**: Uses `convert` and `identify` commands directly
- **ImageMagick 7**: Uses `magick convert` and `magick identify` (automatically detected)

## Configuration

```yaml
# _config.yml
auto_thumbnails:
  enabled: true  # default: true
  
  # Maximum dimensions for automatic thumbnailing
  # Images exceeding these get thumbnails even without explicit sizing
  max_width: 1200   # pixels (optional)
  max_height: 800   # pixels (optional)
  
  # JPEG quality for generated thumbnails (0-100)
  quality: 85  # default: 85

  # HTML parser used for scanning and rewriting.
  # - html5 (default, CRuby only): standards-compliant, does not inject a
  #   <meta http-equiv="Content-Type"> when serializing.
  # - html4: legacy libxml2-based parser; re-inserts the encoding meta tag
  #   on serialize. Required on JRuby.
  parser: html5  # default: html5
```

### HTML parser (`parser: html5 | html4`)

As of `v2.0.0`, `jekyll-auto-thumbnails` parses and serializes HTML with Nokogiri's HTML5 parser by default.

Set `parser: html4` to restore the previous behavior (the libxml2-based `Nokogiri::HTML` parser) if you depended on its serialization quirks.

**JRuby note**: `Nokogiri::HTML5` is not available on JRuby. Under JRuby, you **must** explicitly set `parser: html4`; otherwise the plugin will raise a configuration error at build time.

Pages that contain no replaceable `<article><img>` are no longer re-serialized at all - they are passed through byte-for-byte, regardless of which parser is selected.

## How It Works

1. **HTML Scanning**: After all plugins run, scans `<article>` tags for images
2. **Size Detection**: 
   - Images with `width` or `height` attributes → uses those dimensions
   - Unsized images exceeding max config → thumbnails to max dimensions
3. **Generation**: Creates thumbnails with MD5-based caching in `.jekyll-cache/`
4. **Rewrite**: Points `<img src>` at a thumbnail when one was made, and writes `width` and `height` for the file the browser will load. A measured image whose `src` does not change still gets both numbers. A page this step changes also gets a `<style>:where(article img){height:auto}</style>` at the start of `<head>`, so those attributes do not lock the height when the column is narrower than the image.
5. **File Copying**: Copies thumbnails to `_site/` after build

## Usage Examples

### Explicit Sizing

```html
<article>
  <img src="/photo.jpg" width="300" height="200">
  <!-- Generates: photo_thumb-abc123-300x200.jpg -->
</article>
```

### Automatic Optimization

```yaml
# _config.yml
auto_thumbnails:
  max_width: 800
```

```html
<article>
  <img src="/big-photo.jpg">
  <!-- If photo is 2000x1500, generates: big-photo_thumb-def456-800x600.jpg -->
</article>
```

### With Markdown

Works automatically with any Markdown processor, because it checks the rendered HTML!

```markdown
![Photo](photo.jpg)  <!-- Auto-detects size -->
```

## Narrow columns

`width` and `height` reserve the image's ratio, and they also act as a CSS height. The style rule above sets `height: auto` at zero specificity, so a theme that only has `max-width: 100%` or `width: 100%` keeps the ratio when the column shrinks. A stylesheet or inline style that sets `height` still wins.

The rule is not added, or does not apply, in these cases. Add the same rule to your stylesheet, or the extra declaration named here:

- You set a CSS `height` other than `auto` (a class, an `img` rule, or an inline style). That height wins. If the width also shrinks, set `height: auto`, or set `object-fit: contain` or `cover` when the box is capped on both axes.
- `max-width` and `max-height` both limit the box. The bitmap can still stretch, because the default fit is fill. Set `object-fit`. This gem does not.
- The page already has the served `width`, `height`, and `src`, so nothing is rewritten and no style tag is added. Put the rule in your stylesheet.
- Your site blocks inline `<style>`, or a later plugin strips it. Put the rule in a stylesheet the policy allows.
- The browser does not understand `:where()`. It ignores the rule.
- The image is outside `<article>`. It is not rewritten, and the rule does not apply to it.
- You used a mismatched `width` and `height` to stretch the picture, on a page that is rewritten. The picture keeps the file's ratio. Set the box in CSS and set `object-fit`.

## Cache Behavior

- First build: Generates thumbnails, stores in `.jekyll-cache/`
- Subsequent builds: Reuses cached thumbnails (fast!)
- Source changed: MD5 mismatch detected, regenerates automatically
- Dimensions changed: Different filename, generates new thumbnail

## Troubleshooting

### ImageMagick Not Found

```bash
# Ubuntu/Debian
sudo apt-get install imagemagick

# macOS
brew install imagemagick

# Verify installation
# ImageMagick 6:
which convert identify
# ImageMagick 7:
which magick
```

The gem automatically detects which version you have installed and uses the appropriate commands.

### Thumbnails Not Generating

Check build output for warnings:

```bash
bundle exec jekyll build --verbose
# Look for "AutoThumbnails:" messages
```

### Clear Cache

```bash
rm -rf .jekyll-cache/jekyll-auto-thumbnails/
```

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
4. **URL Replacement**: Updates `<img src>` to point to thumbnails
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

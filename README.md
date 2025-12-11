# Jekyll Image Optimizer

Automatic image optimization for Jekyll sites. Generates and serves optimized thumbnails for faster page loads.

## Installation

Add to your `Gemfile`:

```ruby
group :jekyll_plugins do
  gem "jekyll-img-optimizer"
end
```

Run:

```bash
bundle install
```

**System Requirement**: ImageMagick must be installed (`convert` command available).

## Configuration

```yaml
# _config.yml
img_optimizer:
  enabled: true  # default: true
  max_width: 1200   # optional
  max_height: 800   # optional
  quality: 85  # default: 85
```

## Usage

The plugin automatically optimizes images in `<article>` tags.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT License - see LICENSE file for details.


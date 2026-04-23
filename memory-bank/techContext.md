# Tech Context

Ruby gem (Jekyll plugin) targeting Ruby 3.3+ and Jekyll 4.x. HTML rewriting is powered by Nokogiri; image operations shell out to ImageMagick (6 or 7).

## Environment Setup

- Ruby version pinned in `.ruby-version`; target floor declared in `jekyll-auto-thumbnails.gemspec` (`required_ruby_version`).
- Install dev deps with `bundle install` (Bundler config driven by `Gemfile` + `Gemfile.lock`; the gem itself sources from `jekyll-auto-thumbnails.gemspec`).
- **System requirement**: ImageMagick must be installed on the host. Either ImageMagick 6 (`convert`, `identify`) or ImageMagick 7 (`magick convert`, `magick identify`) is acceptable; `ImagemagickWrapper` auto-detects at runtime.

## Build Tools

- Gem packaging: `jekyll-auto-thumbnails.gemspec`.
- Release automation: Release Please, configured in `release-please-config.json` and `.release-please-manifest.json`. Conventional Commits drive version bumps and CHANGELOG entries; breaking changes must be flagged with `!` or a `BREAKING CHANGE:` footer.

## Testing Process

- Tests run with RSpec, configured via `.rspec` and `spec/spec_helper.rb`. Invoke with `bundle exec rspec`.
- Coverage via SimpleCov (with `simplecov-cobertura` formatter); output under `coverage/`.
- Lint with RuboCop (plus `rubocop-rake` and `rubocop-rspec` plugins) as configured in `.rubocop.yml`. Invoke with `bundle exec rubocop`.
- RSpec specs live alongside code in `spec/<name>_spec.rb` and mirror the `lib/jekyll-auto-thumbnails/<name>.rb` layout. Fixtures live under `spec/fixtures/`.

## Runtime Dependencies Worth Knowing

- **Nokogiri ~> 1.15**: used for HTML parsing and serialization in `lib/jekyll-auto-thumbnails/hooks.rb`. Nokogiri ships both an HTML4 parser (`Nokogiri::HTML`, libxml2-based) and an HTML5 parser (`Nokogiri::HTML5`, CRuby-only; JRuby lacks native HTML5 support at the time of writing). The two produce meaningfully different serialized output, so any change to parser choice is user-visible.
- **Jekyll >= 4.0, < 5.0**: the plugin registers three `Jekyll::Hooks` on `:site` (`post_read`, `post_render`, `post_write`). Jekyll 5 is explicitly not supported yet.

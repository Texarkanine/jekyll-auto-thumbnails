# Contributing to jekyll-auto-thumbnails

## Development Setup

### Prerequisites

- Ruby 2.7 or higher
- Bundler
- ImageMagick (`convert` and `identify` commands)

### Clone and Setup

```bash
git clone https://github.com/KeenerA/jekyll-auto-thumbnails.git
cd jekyll-auto-thumbnails
bundle install
```

### Running Tests

Run the full test suite:

```bash
bundle exec rspec
```

Run specific test file:

```bash
bundle exec rspec spec/scanner_spec.rb
```

Run with coverage report:

```bash
bundle exec rspec
open coverage/index.html
```

### Code Quality

Check code style:

```bash
bundle exec rubocop
```

Auto-fix style issues:

```bash
bundle exec rubocop --autocorrect
```

## Development Workflow

### TDD Approach

This project follows Test-Driven Development:

1. **Write tests first** - Define expected behavior in specs
2. **Run tests** - Watch them fail (red)
3. **Write code** - Implement to make tests pass (green)
4. **Refactor** - Improve code while keeping tests green
5. **Verify** - Run full suite and Rubocop

### Adding Features

1. Create feature branch: `git checkout -b feature/my-feature`
2. Write tests in `spec/`
3. Implement feature in `lib/`
4. Run tests: `bundle exec rspec`
5. Check style: `bundle exec rubocop`
6. Commit with conventional commit format
7. Push and create pull request

### Commit Messages

Use conventional commit format:

- `feat: Add new feature`
- `fix: Fix bug in XYZ`
- `docs: Update README`
- `test: Add tests for ABC`
- `refactor: Improve XYZ`
- `chore: Update dependencies`

## Testing Guidelines

### Test Coverage

- Aim for >89% line coverage
- Cover happy paths and edge cases
- Test error handling
- Mock external dependencies (ImageMagick, file I/O)

### Test Structure

```ruby
RSpec.describe MyModule do
  describe ".method_name" do
    context "with valid input" do
      it "returns expected result" do
        # test code
      end
    end
    
    context "with invalid input" do
      it "raises appropriate error" do
        # test code
      end
    end
  end
end
```

## Project Structure

```
jekyll-auto-thumbnails/
├── lib/
│   ├── jekyll-auto-thumbnails.rb          # Main entry point
│   └── jekyll-auto-thumbnails/
│       ├── version.rb                   # Version constant
│       ├── configuration.rb             # Config parsing
│       ├── url_resolver.rb              # Path resolution
│       ├── digest_calculator.rb         # MD5 computation
│       ├── registry.rb                  # Image tracking
│       ├── generator.rb                 # Thumbnail generation
│       ├── scanner.rb                   # HTML parsing
│       └── hooks.rb                     # Jekyll integration
├── spec/                                # Test files
│   ├── spec_helper.rb
│   ├── *_spec.rb                        # Tests for each module
│   └── fixtures/                        # Test fixtures
└── jekyll-auto-thumbnails.gemspec         # Gem specification
```

## Building and Installing

### Build the Gem

```bash
gem build jekyll-auto-thumbnails.gemspec
```

This creates `jekyll-auto-thumbnails-VERSION.gem`.

### Install Locally

```bash
gem install ./jekyll-auto-thumbnails-*.gem
```

Or in a test Jekyll site's Gemfile:

```ruby
gem 'jekyll-auto-thumbnails', path: '/path/to/jekyll-auto-thumbnails'
```

## Troubleshooting

### Tests failing after changes

1. Run full suite: `bundle exec rspec`
2. Check specific failing test
3. Review recent changes
4. Verify ImageMagick is installed

### Rubocop errors

```bash
bundle exec rubocop --autocorrect
```

If auto-correct doesn't work, manually fix reported issues.

### Gem won't build

1. Check `jekyll-auto-thumbnails.gemspec` for errors
2. Verify all required files exist
3. Check Ruby version compatibility

## Questions?

Open an issue on GitHub for questions, bug reports, or feature requests.


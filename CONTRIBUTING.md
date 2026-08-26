# Contributing

Want to contribute? We'd love to see it! Thoughtful issues and PRs that make the project better are enthusiastically welcomed here!

## Issues

Open an issue for a bug, an idea, or a question.

## Pull requests

1. Fork the repository. If you already have write access, a branch on the origin is fine.
2. Open a pull request against `main` and fill in the pull request template.
3. Title the PR as a [conventional commit](https://www.conventionalcommits.org/): `feat`, `fix`, or `chore`. This repository uses release-please: `feat` and `fix` cut a release; `chore` does not.

Keep the change focused: one concern per pull request when practical.

## Development Setup

### Prerequisites

- Ruby 2.7 or higher
- Bundler
- ImageMagick (`convert` and `identify` commands)

### Clone and Setup

```bash
git clone https://github.com/Texarkanine/jekyll-auto-thumbnails.git
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

### Mutation Testing

This project uses [Mutant](https://github.com/mbj/mutant) with the RSpec integration (`mutant-rspec`). Configuration lives in `config/mutant.yml` (`usage: opensource`). Goal: **100% mutation coverage**.

Confirm the suite passes under Mutant before analyzing mutations:

```bash
bundle exec mutant test
```

Run mutation analysis (prefer `--fail-fast` while iterating):

```bash
bundle exec mutant run --fail-fast
bundle exec mutant run
```

#### Alive Mutations

When a mutant survives, decide which bucket it falls into before changing anything:

- **A) The code does too much** for what the tests require. The surviving mutation reveals redundant behavior. Simplify the implementation.
- **B) A test is missing.** The behavior is intentional but no test observes it. Add an observing example.

If unsure, ask before choosing.

#### Constraints

- Keep the RSpec suite green (`bundle exec rspec`).
- Do not skip mutants by configuring Mutant to ignore them. No matcher ignores, no `coverage_criteria:` tweaks.
- Do not use `send` or `__send__` to invoke private methods in tests just to satisfy Mutant.
- Do not stub or mock the system under test (stub collaborators instead).

Done when both are green:

```bash
bundle exec rspec
bundle exec mutant run
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

1. Write tests in `spec/`
2. Implement the feature in `lib/`
3. Run tests: `bundle exec rspec`
4. Check style: `bundle exec rubocop`

## Testing Guidelines

### Test Coverage

- Aim for **100% line coverage** (`bundle exec rspec`; see `coverage/index.html`)
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

## License

By opening a pull request, you license your contribution under this repository's license, and you grant Texarkanine a perpetual, worldwide, non-exclusive right to relicense that contribution as part of this project under any [OSI-approved](https://opensource.org/licenses) license. You keep your copyright.

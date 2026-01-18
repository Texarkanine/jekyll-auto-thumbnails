# Current Tasks

## Task: Standardize Configuration Across Jekyll Gem Repos

### Complexity: Level 2 (Multi-file changes across multiple repos)

### Scope
Three repositories:
1. jekyll-auto-thumbnails
2. jekyll-highlight-cards
3. jekyll-mermaid-prebuild

### Changes Per Repository
1. `.rubocop.yml` - Standardized relaxed config with plugins
2. `.ruby-version` - Update to 3.4.7
3. `*.gemspec` - Update required_ruby_version to >= 3.4.0
4. `.github/dependabot.yaml` - Add chore(deps-dev) for dev deps

### Verification
- Run `bundle exec rubocop` in each repo
- Ensure no new violations introduced
- Create feature branches and draft PRs

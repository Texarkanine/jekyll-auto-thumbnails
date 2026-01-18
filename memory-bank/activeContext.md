# Active Context

## Current Task
Standardizing configuration across three Jekyll gem repositories:
- jekyll-auto-thumbnails
- jekyll-highlight-cards  
- jekyll-mermaid-prebuild

## Focus Areas
1. **RuboCop Configuration**: Standardize on relaxed, convention-focused linting
2. **Ruby Version**: Standardize on Ruby 3.4
3. **Dependabot**: Use `chore(deps-dev)` for development dependency updates

## Key Decisions
- Use jekyll-auto-thumbnails as the base config template
- Relaxed approach: catch obviously bad code, not be overly strict
- Each gem maintains its own Naming/FileName exclusion for its main lib file
- Target Ruby 3.4 across all repos (latest 3.x LTS)

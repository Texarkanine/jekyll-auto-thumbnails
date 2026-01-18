# TASK ARCHIVE: Standardize Configuration Across Jekyll Gem Repos

## METADATA

| Field | Value |
|-------|-------|
| Task ID | standardize-config |
| Date Started | 2026-01-18 |
| Date Completed | 2026-01-18 |
| Complexity | Level 2 |
| Category | Enhancement |
| Scope | Multi-repository |

## SUMMARY

Standardized configuration files across three Jekyll gem repositories to ensure consistent development experience, linting standards, and dependency management.

**Repositories:**
- jekyll-auto-thumbnails
- jekyll-highlight-cards
- jekyll-mermaid-prebuild

**Pull Requests:**
- [jekyll-auto-thumbnails #16](https://github.com/Texarkanine/jekyll-auto-thumbnails/pull/16)
- [jekyll-highlight-cards #26](https://github.com/Texarkanine/jekyll-highlight-cards/pull/26)
- [jekyll-mermaid-prebuild #6](https://github.com/Texarkanine/jekyll-mermaid-prebuild/pull/6)

---

## REQUIREMENTS

### Primary Goals
1. Standardize RuboCop configuration with relaxed, convention-focused linting
2. Standardize Ruby version requirements across all gems
3. Configure Dependabot with proper conventional commit prefixes

### Constraints
- "Not a rubonazi" - catch obviously bad code, not be pedantic
- Support Ruby 3.3+ (oldest actively maintained Ruby)
- Use conventional commits for dependency updates

---

## IMPLEMENTATION

### Files Changed Per Repository

| File | Change |
|------|--------|
| `.rubocop.yml` | Standardized relaxed config with `rubocop-rake` and `rubocop-rspec` plugins |
| `.ruby-version` | Updated to `3.4.7` |
| `*.gemspec` | Updated `required_ruby_version` to `>= 3.3.0` |
| `.github/dependabot.yaml` | Added conventional commit prefixes and grouping |

### Configuration Details

**RuboCop:**
- Target Ruby version: 3.3 (minimum supported)
- Uses `plugins:` syntax (not deprecated `require:`)
- Relaxed metrics (AbcSize: 100, MethodLength: 60, etc.)
- Disabled pedantic RSpec cops (VerifiedDoubles, ContextWording, etc.)
- hooks.rb files excluded from metrics

**Ruby Version Strategy:**
| Setting | Value | Purpose |
|---------|-------|---------|
| Gemspec requirement | `>= 3.3.0` | Minimum for users |
| RuboCop target | `3.3` | Catch compatibility issues |
| .ruby-version | `3.4.7` | Local development |

**Dependabot Prefixes:**
| Dependency Type | Prefix |
|-----------------|--------|
| Production | `fix(deps)` |
| Development | `chore(deps-dev)` |
| GitHub Actions | `chore(deps-ci)` |

### Code Changes

**jekyll-highlight-cards** received additional autocorrections:
- `Style/NumericPredicate`: Changed `idx > 0` to `idx.positive?`
- `Style/NumericPredicate`: Changed `in_liquid == 0` to `in_liquid.zero?`

---

## TESTING

### Verification Steps
1. Ran `bundle exec rubocop` in each repository
2. Verified no offenses detected in all three repos
3. Created feature branches and pushed to origin
4. Opened draft PRs for CI validation

### Results
All three repositories pass RuboCop with zero offenses.

---

## LESSONS LEARNED

### Technical
1. **RuboCop `plugins:` vs `require:`** - Use `plugins:` (current syntax), not `require:` (deprecated)
2. **Dependabot `include: 'scope'`** - Adds dependency name as scope, not literal "deps"
3. **RuboCop TargetRubyVersion** - Set to minimum supported version to catch compatibility issues
4. **Ruby version philosophy** - Don't claim support for versions you don't test

### Process
1. Ask clarifying questions upfront about version requirements
2. Test config changes incrementally
3. When standardizing configs, expect to relax cops for pre-existing code

---

## TECHNICAL DEBT

1. `Lint/DuplicateBranch` disabled - imagemagick_wrapper.rb has intentional duplicate fallbacks
2. Several RSpec cops disabled for practicality - could be enabled with test refactoring

---

## REFERENCES

- Reflection: `memory-bank/reflection/reflection-standardize-config.md`
- RuboCop documentation: https://docs.rubocop.org/
- Dependabot documentation: https://docs.github.com/en/code-security/dependabot

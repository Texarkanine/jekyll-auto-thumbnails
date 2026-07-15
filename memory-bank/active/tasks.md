# Task: issue-48-simplecov-1.0-skip-migration

* Task ID: issue-48-simplecov-1.0-skip-migration
* Complexity: Level 2
* Type: simple enhancement

Bump `simplecov` ~> 1.0 and `simplecov-cobertura` ~> 4.0 (gemspec + lockfile) and migrate `SimpleCov.add_filter` → `SimpleCov.skip` in `spec/spec_helper.rb` in one change set so Dependabot PR #47 is obsolete. See https://github.com/Texarkanine/jekyll-auto-thumbnails/issues/48.

## Test Plan (TDD)

### Behaviors to Verify

- [Gemspec constraint — simplecov]: load gemspec → development dependency `simplecov` has requirement `~> 1.0`
- [Gemspec constraint — cobertura]: load gemspec → development dependency `simplecov-cobertura` has requirement `~> 4.0`
- [Resolved simplecov major]: require SimpleCov in the suite → `SimpleCov::VERSION` matches `/\A1\./`
- [Resolved cobertura major]: `Gem.loaded_specs["simplecov-cobertura"].version` is `>= 4.0` and `< 5.0`
- [Config uses skip]: `spec/spec_helper.rb` source uses `skip` for `spec/` and `vendor/` paths and does not call `add_filter`
- [Regression]: existing RSpec suite continues to pass under the new SimpleCov stack (full suite run)

### Test Infrastructure

- Framework: RSpec (`bundle exec rspec`), configured via `.rspec` and `spec/spec_helper.rb`
- Test location: `spec/`
- Conventions: `spec/<name>_spec.rb` mirroring lib; frozen-string-literal; `require "spec_helper"`; `expect` syntax; `disable_monkey_patching!`
- New test files: `spec/simplecov_setup_spec.rb` (contract tests for gemspec constraints, resolved majors, and skip migration)

## Implementation Plan

1. [x] Stub + implement failing contract tests in `spec/simplecov_setup_spec.rb` for gemspec constraints, resolved majors, and `skip`/`add_filter` source contract; run to confirm red.
   - Files: `spec/simplecov_setup_spec.rb` (new)
   - Changes: add RSpec examples covering the behaviors above
2. [x] Bump gemspec development dependencies to `simplecov ~> 1.0` and `simplecov-cobertura ~> 4.0`.
   - Files: `jekyll-auto-thumbnails.gemspec`
   - Changes: update the two `add_development_dependency` lines
3. [x] Refresh lockfile for those gems (`bundle update simplecov simplecov-cobertura`).
   - Files: `Gemfile.lock`
   - Changes: resolve simplecov 1.x and simplecov-cobertura 4.x (and any required transitive bumps)
4. [x] Migrate SimpleCov config: replace `add_filter` with `skip` for `/spec/` and `/vendor/` (or `spec/` / `vendor/`).
   - Files: `spec/spec_helper.rb`
   - Changes: two-line API rename; no behavior change intended
5. [x] Re-run new contract specs (expect green) then full suite + RuboCop.
   - Files: none beyond fixes if verification fails
   - Changes: verification only (RuboCop: describe `SimpleCov`; `%r` literals)

## Technology Validation

Existing development dependencies at new major versions (not net-new tech). Validated during build via `bundle update simplecov simplecov-cobertura` and suite boot under SimpleCov 1.0 with `skip`. No separate PoC project required.

## Dependencies

- Feature branch `fix/48-simplecov-1.0-skip-migration` from up-to-date `main` (already created)
- Bundler / Ruby environment for lockfile refresh
- SimpleCov 1.0 `skip` API (same matcher grammar as deprecated `add_filter`)

## Challenges & Mitigations

- [Lockfile / transitive conflicts]: Mitigation — run targeted `bundle update simplecov simplecov-cobertura`; if resolution fails, inspect conflict and adjust only as needed for these majors
- [Cobertura formatter API change under 4.0]: Mitigation — keep existing `SimpleCov::Formatter::CoberturaFormatter` usage; fix only if suite fails under CI formatter path
- [Filter string form]: Mitigation — keep `/spec/` and `/vendor/` forms unless tests show otherwise; issue allows clearer `spec/` / `vendor/` equivalents

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Preflight — PASS (no plan amendments; advisory: Gemfile.lock DEPENDENCIES lines sync via `bundle update`)
- [x] Build — PASS (103 examples, 0 failures; RuboCop clean)
- [x] QA — PASS (KISS/DRY/YAGNI/completeness/regression/integrity/docs all clear; no fixes needed)

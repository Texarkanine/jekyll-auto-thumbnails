# Project Brief

## User Story

As a maintainer, I want to bump SimpleCov to 1.0 (and cobertura to 4.0) and migrate `add_filter` → `skip` in the same PR so that Dependabot PR #47 is unnecessary and the suite runs without SimpleCov 1.0 deprecation warnings.

## Use-Case(s)

### Use-Case 1

Developer updates development dependencies and SimpleCov config; CI and local test runs succeed on SimpleCov 1.0 with `skip` filters and no deprecation warnings from `add_filter`.

### Use-Case 2

Maintainers close Dependabot PR #47 as superseded by the human PR that includes both the bump and the config migration.

## Requirements

1. Bump `simplecov` to `~> 1.0` and `simplecov-cobertura` to `~> 4.0` in `jekyll-auto-thumbnails.gemspec` and refresh the lockfile.
2. Migrate `SimpleCov.add_filter` → `SimpleCov.skip` in `spec/spec_helper.rb` for the `/spec/` and `/vendor/` (or `spec/` / `vendor/`) filters in the same change set.
3. Work on a feature branch cut from up-to-date `main`.
4. Open a GitHub PR that Fixes #48 and notes that Dependabot PR #47 is superseded and can be closed.

## Constraints

1. Do not force-push; do not amend unless amend rules are met.
2. Use `git --no-pager` and `git commit --no-gpg-sign`.
3. Conventional commits; reference issue `#48`.
4. Follow TDD and Level 2 Niko phase rules.

## Acceptance Criteria

1. Gemspec and lockfile pin `simplecov ~> 1.0` and `simplecov-cobertura ~> 4.0`.
2. `spec/spec_helper.rb` uses `skip` instead of `add_filter`.
3. Test suite passes under the new SimpleCov stack.
4. PR opened with Fixes #48 and supersession note for #47.

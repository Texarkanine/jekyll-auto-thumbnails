---
task_id: issue-48-simplecov-1.0-skip-migration
complexity_level: 2
date: 2026-07-15
status: completed
---

# TASK ARCHIVE: issue-48-simplecov-1.0-skip-migration

## SUMMARY

Bumped development dependencies `simplecov` to `~> 1.0` (resolved 1.0.1) and `simplecov-cobertura` to `~> 4.0` (resolved 4.0.0), migrated `SimpleCov.add_filter` → `SimpleCov.skip` in `spec/spec_helper.rb`, and added contract specs so Dependabot PR #47 can be closed as superseded.

## REQUIREMENTS

- Gemspec + lockfile majors for simplecov 1.x and simplecov-cobertura 4.x
- Same-PR migration of deprecated `add_filter` to `skip` for `/spec/` and `/vendor/`
- Feature branch from up-to-date `main`; PR that Fixes #48 and notes #47 supersession
- TDD + Level 2 Niko workflow

## IMPLEMENTATION

- New `spec/simplecov_setup_spec.rb`: gemspec constraints, resolved majors, and `skip`/`add_filter` source contract
- `jekyll-auto-thumbnails.gemspec` + `Gemfile.lock` via `bundle update simplecov simplecov-cobertura`
- `spec/spec_helper.rb`: two-line `add_filter` → `skip` rename

## TESTING

- Contract specs written first (5 failures), then made green
- Full suite: 103 examples, 0 failures
- RuboCop clean (DescribeClass / RegexpLiteral fixed during build)
- QA semantic review: PASS

## LESSONS LEARNED

Nothing notable — clean Level 2 dependency + config migration.

## PROCESS IMPROVEMENTS

None.

## TECHNICAL IMPROVEMENTS

None beyond the shipped change.

## NEXT STEPS

- Open PR Fixes #48; note Dependabot #47 can be closed as superseded

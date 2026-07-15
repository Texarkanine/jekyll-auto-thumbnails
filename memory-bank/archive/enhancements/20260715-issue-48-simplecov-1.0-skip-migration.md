---
task_id: issue-48-simplecov-1.0-skip-migration
complexity_level: 2
date: 2026-07-15
status: completed
---

# TASK ARCHIVE: issue-48-simplecov-1.0-skip-migration

## SUMMARY

Bumped development dependencies `simplecov` to `~> 1.0` (resolved 1.0.1) and `simplecov-cobertura` to `~> 4.0` (resolved 4.0.0), and migrated `SimpleCov.add_filter` → `SimpleCov.skip` in `spec/spec_helper.rb`, so Dependabot PR #47 can be closed as superseded.

## REQUIREMENTS

- Gemspec + lockfile majors for simplecov 1.x and simplecov-cobertura 4.x
- Same-PR migration of deprecated `add_filter` to `skip` for `/spec/` and `/vendor/`
- Feature branch from up-to-date `main`; PR that Fixes #48 and notes #47 supersession
- Level 2 Niko workflow

## IMPLEMENTATION

- `jekyll-auto-thumbnails.gemspec` + `Gemfile.lock` via `bundle update simplecov simplecov-cobertura`
- `spec/spec_helper.rb`: two-line `add_filter` → `skip` rename

An early draft added RSpec contract specs that asserted on gemspec constraints and `spec_helper` source (`spec/simplecov_setup_spec.rb`). That was a mistake — unit-testing the unit-test/coverage harness is not a useful pattern — and those specs were removed. Verification for this change is the existing product suite under the bumped SimpleCov stack, not meta-tests of the config.

## TESTING

- Full suite under SimpleCov 1.0 / cobertura 4.0: product examples pass; RuboCop clean
- QA semantic review: PASS (after removal of the config contract specs)

## LESSONS LEARNED

Do not add specs that only assert gemspec pins or that `spec_helper` contains `skip` vs `add_filter`. Coverage/tooling config changes are verified by running the real suite after the bump, not by unit-testing the test configuration.

## PROCESS IMPROVEMENTS

For dependency + harness migrations, prefer "bump, migrate, run the suite" over inventing contract suites around gemspec/lockfile/`spec_helper` text.

## TECHNICAL IMPROVEMENTS

None beyond the shipped change.

## NEXT STEPS

None (PR #49 open; Dependabot #47 closed as superseded).

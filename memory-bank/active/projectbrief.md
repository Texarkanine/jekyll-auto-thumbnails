# Project Brief

## User Story

As a gem maintainer, I want mutation testing (Mutant) wired into jekyll-auto-thumbnails the way jekyll-llms does — adapted for RSpec — so I can review a draft PR that later templates the same rollout for jekyll-highlight-cards and jekyll-mermaid-prebuild.

## Use-Case(s)

### Use-Case 1

Developer runs `bundle exec mutant run` (and related Mutant commands) against this gem and gets a trustworthy mutation-testing workflow modeled on jekyll-llms.

### Use-Case 2

Reviewer inspects a draft PR that shows the reference pattern (deps, config, agent guidance, coverage discipline) for applying Mutant to the other two RSpec-based gems later.

## Requirements

1. Investigate jekyll-llms’ Mutant setup and confirm the approach remains current (not deprecated/superseded).
2. Add Mutant to jekyll-auto-thumbnails using RSpec integration (`mutant-rspec`), not a minitest migration.
3. Mirror jekyll-llms’ philosophy: config, agent guidance, path to 100% mutation coverage, no matcher-ignore / coverage-criteria cheats.
4. Deliver work on feature branch `feat/mutation-testing` (from updated `main`) as a draft PR.

## Constraints

1. Workspace and memory bank: jekyll-auto-thumbnails only for this run.
2. Keep RSpec; do not migrate the suite to minitest.
3. Out of scope for this PR: applying Mutant to jekyll-highlight-cards and jekyll-mermaid-prebuild (reference only).
4. Follow existing project TDD / test-running practices and Niko workflow.

## Acceptance Criteria

1. Mutant is a declared development dependency with RSpec integration configured and documented for agents/developers.
2. `bundle exec rake` / existing RSpec + coverage gates remain green; Mutant is runnable in the jekyll-llms style.
3. Mutation coverage goal matches the jekyll-llms discipline (kill survivors via simplify or tests; no ignore cheats), as far as this PR lands.
4. A draft GitHub PR exists on `feat/mutation-testing` for human review.

## Rework

### PR Feedback (2026-07-18)

As part of review feedback on the current mutation-testing draft PR:

1. Reach **100% SimpleCov line coverage** (currently 286/289). The three uncovered lines are the bodies of the `Jekyll::Hooks.register` blocks in `lib/jekyll-auto-thumbnails/hooks.rb` (`initialize_system` / `process_site` / `copy_thumbnails` wiring).
2. **Correct `CONTRIBUTING.md`** Test Coverage guidance — replace the stale “Aim for >89% line coverage” target with a 100% line-coverage expectation consistent with the project’s coverage discipline.

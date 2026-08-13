---
task_id: log-elapsed-time
complexity_level: 2
date: 2026-08-13
status: completed
---

# TASK ARCHIVE: log-elapsed-time

## SUMMARY

AutoThumbnails completion logs now include elapsed time. `Generated N thumbnails` and `All thumbnails copied` append `in Xs` under a minute and `in X m Y s` at a minute or more. The `Copying N thumbnails to _site` start line is unchanged. Operator verified on a local devblog build.

## REQUIREMENTS

- Elapsed suffix on the Generated completion line from `Hooks.process_site`
- Elapsed suffix on the All thumbnails copied line from `Hooks.copy_thumbnails`
- Sub-minute: `in Xs`; 60s+: `in X m Y s`
- Do not time the Copying start line
- No new runtime dependencies; existing hook behavior unchanged aside from the log suffixes

## IMPLEMENTATION

`Hooks.format_elapsed` rounds to integer seconds and formats the suffix. Monotonic clocks (`Process.clock_gettime(Process::CLOCK_MONOTONIC)`) wrap scan+generate+replace and the copy loop. Elapsed is stored in a local before logging to satisfy Layout/LineLength.

Key files: `lib/jekyll-auto-thumbnails/hooks.rb`, `spec/hooks_spec.rb`.

## TESTING

- TDD: empty `format_elapsed` went red, then clock-stubbed hook examples
- Full suite: 248 examples, 0 failures, 100% line coverage
- RuboCop clean on the changed files
- QA PASS
- Operator: local devblog build with path gems showed the timing lines

## LESSONS LEARNED

Regex log assertions (`Generated\s+1\b`, `/copied/i`) absorb a suffix without a rewrite; exact-string log specs do not. `Hooks.format_elapsed` plus two clock spans is the right shape; a shared duration gem across Jekyll plugins would be a worse foundation for a log suffix.

## PROCESS IMPROVEMENTS

None. Level 2 plan → preflight → build → QA → reflect held.

## TECHNICAL IMPROVEMENTS

None beyond the shipped change.

## NEXT STEPS

None. Draft PR #54; operator merges after this archive lands.

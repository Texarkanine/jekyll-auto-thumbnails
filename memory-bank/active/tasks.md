# Task: log-elapsed-time

* Task ID: log-elapsed-time
* Complexity: Level 2
* Type: simple enhancement

Append elapsed-time suffixes to AutoThumbnails completion log lines: `Generated N thumbnails` and `All thumbnails copied`. Format as `in Xs` under 60 seconds and `in X m Y s` at 60 seconds or more. Do not time the `Copying N thumbnails to _site` start line.

## Test Plan (TDD)

### Behaviors to Verify

- Format under a minute: `format_elapsed(12)` → `"in 12s"`
- Format zero: `format_elapsed(0)` → `"in 0s"`
- Format 59 seconds: `format_elapsed(59)` → `"in 59s"`
- Format exactly one minute: `format_elapsed(60)` → `"in 1 m 0 s"`
- Format minutes plus seconds: `format_elapsed(62)` → `"in 1 m 2 s"`; `format_elapsed(422)` → `"in 7 m 2 s"`
- Round fractional seconds: `format_elapsed(12.4)` → `"in 12s"`; `format_elapsed(12.6)` → `"in 13s"`
- Generate completion: `process_site` logs `Generated N thumbnails in Xs` (or `in X m Y s`) after generation
- Copy completion: `copy_thumbnails` logs `All thumbnails copied in Xs` (or `in X m Y s`) after copy
- Copy start unchanged: `copy_thumbnails` still logs `Copying N thumbnails to _site` with no elapsed suffix
- Early skip: disabled / missing ImageMagick / empty url_map paths do not emit timed completion lines they did not emit before

### Test Infrastructure

- Framework: RSpec
- Test location: `spec/`
- Conventions: one spec file per lib module (`spec/hooks_spec.rb` mirrors `lib/jekyll-auto-thumbnails/hooks.rb`); logger stubbed via `allow(Jekyll).to receive(:logger)`
- New test files: none

## Implementation Plan

1. Add `Hooks.format_elapsed` with tests first
   - Files: `spec/hooks_spec.rb`, `lib/jekyll-auto-thumbnails/hooks.rb`
   - Tests first: `spec/hooks_spec.rb` — describe `.format_elapsed` cases for 0, 12, 59, 60, 62, 422, 12.4, 12.6
   - Changes: module function on `Hooks` that rounds to integer seconds and returns `in Xs` or `in X m Y s`. No new file, no new dependency.

2. Time `process_site` and append elapsed to the Generated line
   - Files: `spec/hooks_spec.rb`, `lib/jekyll-auto-thumbnails/hooks.rb`
   - Tests first: extend `logs how many thumbnails were generated` to require an elapsed suffix; add a case that stubs `Process.clock_gettime` so 12.0s elapsed produces `Generated 1 thumbnails in 12s`
   - Changes: monotonic clock around generate+replace; `Jekyll.logger.info "AutoThumbnails:", "Generated #{url_map.size} thumbnails #{format_elapsed(elapsed)}"`

3. Time `copy_thumbnails` and append elapsed to the All thumbnails copied line
   - Files: `spec/hooks_spec.rb`, `lib/jekyll-auto-thumbnails/hooks.rb`
   - Tests first: extend `logs copy start and completion` so Copying has no elapsed suffix and completion matches `/copied/i` plus elapsed suffix; add a clock-stubbed case for `All thumbnails copied in 1s`
   - Changes: monotonic clock around the copy loop; completion log uses `format_elapsed`

## Technology Validation

No new technology - validation not required

## Dependencies

- `Process.clock_gettime(Process::CLOCK_MONOTONIC)` (Ruby stdlib)
- Existing `Jekyll.logger.info` calls in `Hooks`

## Challenges & Mitigations

- Existing Generated/copied assertions use regex and should keep passing if the suffix is appended; clock-stubbed cases pin the exact format
- Mutant covers `JekyllAutoThumbnails*`; `format_elapsed` rounding and the 60-second boundary need explicit examples so mutants cannot weaken the threshold

## Pre-Mortem

- Timing the wrong span (including ImageMagick skip / scan-only): already covered by Challenge 1 — clock starts after the enabled/ImageMagick guards, around the work that the completion line reports
- Exact log-string breakage in mermaid-style tests: AutoThumbnails already uses regex; clock-stubbed examples pin format without making every spec depend on wall-clock
- `Float#round` half-even at `x.5`: avoid `.5` examples; test 12.4 / 12.6

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [x] Preflight
- [x] Build
- [ ] QA

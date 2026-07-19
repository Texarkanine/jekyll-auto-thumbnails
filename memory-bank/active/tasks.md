# Task: mutation-testing (rework)

* Task ID: mutation-testing-rework-coverage
* Complexity: Level 1
* Type: enhancement / docs (PR feedback)

Reach 100% SimpleCov line coverage for the three uncovered Jekyll hook registration bodies, and correct CONTRIBUTING.md Test Coverage guidance.

## Fix Record

**What was uncovered:** Lines 154, 158, 162 in `lib/jekyll-auto-thumbnails/hooks.rb` — bodies of `Jekyll::Hooks.register` blocks for `:post_read`, `:post_render`, `:post_write`. Specs called the Hooks methods directly, so wiring never ran.

**Fix:** Added `describe "Jekyll hook registration"` in `spec/hooks_spec.rb` that fires `Jekyll::Hooks.trigger` for each event and observes side effects (no SUT stubs). Updated CONTRIBUTING Test Coverage from “>89%” to **100% line coverage**.

**Files:** `spec/hooks_spec.rb`, `CONTRIBUTING.md`

## Status

- [x] Hook registration specs
- [x] CONTRIBUTING coverage target
- [x] Verify: rspec 240/240, SimpleCov 289/289 (100%), rubocop clean, mutant 2338/2338
- [x] QA

### QA Results

- PASS — no semantic issues; rework requirements complete; persistent files unchanged

### Post-QA (SLOBAC)

- [x] Judged 8 findings from `.slobac/2026-07-18T22-26-33/audit.md` (all fix-in-PR)
- [x] Landed `65da102` — SLOBAC remediations + Mutant 100%
- [x] Follow-up: keep skip-identify-when-both-dims-present as intentional optimization with observing example (also CodeRabbit PR #50 item 8 / `discussion_r3609377870`)

---
task_id: mutation-testing
complexity_level: 3
date: 2026-07-18
status: completed
---

# TASK ARCHIVE: mutation-testing

## SUMMARY

Wired Mutant + `mutant-rspec` into jekyll-auto-thumbnails as the reference RSpec mutation-testing pattern for the Texarkanine gem family, drove mutation coverage to 100%, and opened draft PR #50 on `feat/mutation-testing`. Post-reflect rework closed PR feedback gaps: 100% SimpleCov line coverage (Jekyll hook registration bodies), CONTRIBUTING coverage-target correction, SLOBAC suite-smell remediations, and a CodeRabbit-driven identify-skip when both HTML dimensions are present.

## REQUIREMENTS

### Original (Level 3)

1. Investigate jekyll-llms’ Mutant setup and confirm the approach remains current.
2. Add Mutant using RSpec integration (`mutant-rspec`), not a minitest migration.
3. Mirror jekyll-llms discipline: config, agent guidance, path to 100% mutation coverage, no matcher-ignore / coverage-criteria cheats.
4. Deliver on `feat/mutation-testing` as a draft PR (workspace scope: this gem only).

Acceptance: Mutant declared and documented; RSpec/coverage gates green; mutation coverage at full kill discipline; draft PR exists. CI Mutant job intentionally out of scope.

### Rework (Level 1 follow-ups on the same PR)

1. Reach 100% SimpleCov line coverage — uncover the three `Jekyll::Hooks.register` block bodies in `hooks.rb`.
2. Correct CONTRIBUTING Test Coverage guidance from “>89%” to 100% line coverage.
3. Address SLOBAC audit findings (`.slobac/2026-07-18T22-26-33/audit.md`) while keeping Mutant at 100%.
4. Triage LlamaPReview + CodeRabbit reviews on PR #50; fix the valid identify/dimensions item.

## IMPLEMENTATION

### Scaffold

- Dev deps: `mutant`, `mutant-rspec` in `jekyll-auto-thumbnails.gemspec` / `Gemfile.lock`.
- Config: `config/mutant.yml`; helper `spec/support/mutant_setup.rb`; SimpleCov skipped when Mutant is loaded (`spec/spec_helper.rb`).
- Discipline docs folded into `CONTRIBUTING.md` (A/B buckets, no ignore cheats, no SUT stubs).
- Persistent note: `memory-bank/techContext.md` Testing Process updated for Mutant CLI (`mutant test` / `mutant run`).

### Kill loop (product observability)

Survivors were killed primarily by making behavior observable and simplifying unobservable paths — not by ignore lists:

- Prefer `def self.` over `module_function` (`HtmlParser` and similar) so Mutant does not invent unused instance-method subjects.
- Stop stubbing private methods on the SUT; stub collaborators instead.
- Expand describe-local side-effect observations (mutant-rspec selects by describe-prefix match to the subject).
- Prefer public helpers over `.send` for Mutant observability (Hooks/Scanner).
- Per-example tempdirs instead of shared fixture paths (parallel Mutant forks).
- Bucket A for unobserved debug logs / redundant nil-coercion before interpolation.

Key lib touchpoints: `configuration.rb`, `digest_calculator.rb`, `generator.rb`, `hooks.rb`, `html_parser.rb`, `imagemagick_wrapper.rb`, `registry.rb`, `scanner.rb`, `url_resolver.rb`. Specs expanded accordingly (`hooks_spec`, `scanner_spec`, `imagemagick_wrapper_spec`, etc.).

### Rework: SimpleCov hook wiring

Unit tests called Hooks methods directly, so register-block bodies never ran. Added `describe "Jekyll hook registration"` in `spec/hooks_spec.rb` that fires `Jekyll::Hooks.trigger` for `:post_read` / `:post_render` / `:post_write` and asserts side effects (no SUT stubs).

### Rework: SLOBAC + PR bots

- Softened presentation-coupled log matchers to load-bearing topic + count/URL (over-softening let Mutant delete one log while another still matched — pin distinct topics).
- Prefer public `reset_detection_cache!` over `instance_variable_set`.
- Restored intentional `scan_html` identify-skip when both HTML dims present, with an observing example.
- CodeRabbit item 8: gate `calculate_dimensions` when both width/height present; one `execute_identify` only for `dimensions_match_original?`.
- Dismissed false File.join / `nil.dup` crash claims on supported MRI; deferred path-traversal hardening in `to_filesystem_path` / copy to a follow-up issue.

### Creative phase

None. Open questions (keep RSpec; Mutant 0.16 CLI is `mutant test` / `mutant run`) were resolved in planning. That was the right call.

## TESTING

| Gate | Result |
|------|--------|
| RSpec | 240 examples, 0 failures |
| SimpleCov | 289/289 lines (100%) after rework |
| RuboCop | clean |
| Mutant | 100% kill (2338 at initial land; 2336 after identify-skip product change) |
| `/niko-qa` (original) | PASS (trivial techContext / url_resolver wording fixes) |
| `/niko-qa` (rework) | PASS |
| SLOBAC audit | 8 findings judged fix-in-PR; remediated in `65da102` |
| PR bot triage | 10 items → 1 fix-in-PR, 1 defer, 8 dismiss |

Draft PR: #50 on `feat/mutation-testing`.

## LESSONS LEARNED

### Technical

- Prefer `def self.` over `module_function` when Mutant will cover the API — `module_function` leaves an instance-method subject that production never calls.
- Stubbing private methods on the SUT makes those subjects unkillable; stub collaborators instead.
- Mutant-rspec selects examples by describe-prefix match to the subject expression — side-effect observations must live under the method's describe, not a sibling attr_reader describe.
- Shared on-disk fixtures race under Mutant's parallel forks; use per-example tempdirs.
- Method unit tests do not exercise `Jekyll::Hooks.register` block bodies; `Jekyll::Hooks.trigger` is the minimal wiring coverage.
- Softening log oracles too far (e.g. bare digit matchers) can leave Mutant-deletable log lines green; pin distinct topics.
- Bot reviews often confuse `File.join` with `Pathname#join` absolute-path reset semantics.

### Process

- After a green Mutant PoC, inventory all evil survivors once (`mutant run` + JSON parse) before one-at-a-time `--fail-fast` — batching by structural cause beats linear kill.
- Parallel subject-scoped subagents worked well once Mutant A/B constraints were explicit in the prompt.
- PoC during plan/preflight paid off — Build started with green `mutant test`.
- Plan under-emphasized Mutant×RSpec subject/test selection and SUT-stubbing as primary risk; those dominated calendar time more than ImageMagick slowness.
- Level 1 rework on a Level 3 task still belongs in the Level 3 archive when the reflection and journey are one feature story.

## PROCESS IMPROVEMENTS

- When adopting Mutant on an RSpec gem, treat describe-prefix selection and “no SUT stubs” as first-class plan risks, not late kill-loop discoveries.
- Keep optional `rake mutant` wrappers deferred until CLI fidelity to the reference gem is settled (preflight advisory, correctly deferred).
- For PR-bot File.join / nil-safety claims on MRI 3.3+, verify against runtime semantics before accepting as defects.

## TECHNICAL IMPROVEMENTS

None beyond what shipped. Public Hooks/Scanner helpers for Mutant observability were accepted as appropriate, not over-engineering. Optional future `rake mutant` wrapper remains advisory only.

## NEXT STEPS

1. Human review / merge of draft PR #50.
2. Apply the same Mutant + RSpec reference pattern to jekyll-highlight-cards and jekyll-mermaid-prebuild (explicitly out of scope for this PR).
3. Optional follow-up issue: path-traversal hardening in `to_filesystem_path` / thumbnail copy (`discussion_r3609377886`).
4. Optional product polish deferred from bots: reject malformed dimension strings like `30px40`.

## JOURNEY

| Phase | Status |
|-------|--------|
| Complexity analysis | Level 3 (rework later Level 1) |
| Plan | COMPLETE — jekyll-llms → RSpec map; Mutant 0.16 PoC |
| Creative | Skipped (questions resolved in plan) |
| Preflight | PASS |
| Build | COMPLETE — 100% mutation coverage; draft PR #50 |
| QA | PASS |
| Reflect | COMPLETE — `reflection-mutation-testing.md` inlined above |
| Rework build/QA | COMPLETE — SimpleCov 100%; CONTRIBUTING; SLOBAC; PR bot item 8 |
| Archive | COMPLETE |

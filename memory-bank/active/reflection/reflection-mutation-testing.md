---
task_id: mutation-testing
date: 2026-07-18
complexity_level: 3
---

# Reflection: mutation-testing

## Summary

Mutant + `mutant-rspec` was wired into jekyll-auto-thumbnails, driven to 100% mutation coverage (2338 kills), and shipped as draft PR #50 as the reference pattern for the sibling RSpec gems.

## Requirements vs Outcome

All project-brief requirements were met: investigate and confirm Mutant currency, add RSpec integration (not minitest), mirror jekyll-llms discipline without ignore cheats, and open a draft PR on `feat/mutation-testing`. Acceptance criteria for runnable Mutant, green RSpec, and full mutation coverage landed. CI Mutant was intentionally omitted per plan.

## Plan Accuracy

The plan's scaffold → docs → baseline → kill-loop → verify → draft PR sequence held. Estimated challenge of "many survivors" was accurate (~744 evil alive at first full inventory). Surprises were structural rather than product-logic: `module_function` dual methods, SUT stubbing zeroing private-subject kills, and Mutant RSpec describe-prefix selection requiring observations under the matching method describe.

## Creative Phase Review

No creative phase — open questions were resolved during planning (keep RSpec; CLI `mutant test` / `mutant run`). That was the right call; no design mega-unknowns appeared that needed creative exploration.

## Build & QA Observations

Build was dominated by the kill loop. High-leverage fixes (stop stubbing SUT; fix HtmlParser to `def self.parse`; expand describe-local observations) cleared large subject groups at once. Parallel subagents accelerated Config/Registry/Url, ImageMagickWrapper, Hooks, and Scanner. QA was clean aside from trivial documentation/wording fixes (techContext Mutant note; url_resolver example wording).

## Cross-Phase Analysis

PoC during plan/preflight paid off — Build started with green `mutant test`. Preflight's advisory about optional `rake mutant` was correctly deferred. The main plan gap was under-emphasizing Mutant×RSpec subject/test selection and SUT-stubbing as primary risk; those dominated calendar time more than ImageMagick slowness.

## Insights

### Technical

- Prefer `def self.` over `module_function` when Mutant will cover the API — `module_function` leaves an instance-method subject that production never calls.
- Stubbing private methods on the SUT makes those subjects unkillable; stub collaborators instead.
- Mutant-rspec selects examples by describe-prefix match to the subject expression — side-effect observations must live under the method's describe, not a sibling attr_reader describe.
- Shared on-disk fixtures race under Mutant's parallel forks; use per-example tempdirs.

### Process

- After a green Mutant PoC, inventory all evil survivors once (`mutant run` + JSON parse) before one-at-a-time `--fail-fast` — batching by structural cause beats linear kill.
- Parallel subject-scoped subagents worked well once AGENTS constraints and A/B rules were explicit in the prompt.

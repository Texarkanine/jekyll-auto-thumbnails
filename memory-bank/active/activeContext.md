# Active Context

## Current Task

Fix HTML5 validity regression in `replace_urls` (issue #29): swap default
Nokogiri HTML parser to HTML5, short-circuit no-op pages, and preserve
HTML4 behavior behind a new `auto_thumbnails.parser: html4|html5` config
(breaking change, major version bump).

## Phase

PLAN - COMPLETE

## What Was Done

- Read issue #29 and restated intent; user approved with two clarifications
  (config shape `parser: html4|html5`, JRuby + `html5` hard-errors).
- Initialized memory bank persistent files (`productContext.md`,
  `systemPatterns.md`, `techContext.md`).
- Classified as **Level 2 — Simple Enhancement** (breaking change).
- Produced implementation plan in `tasks.md`: 7 ordered steps, TDD-first,
  covering Configuration (parser attribute + validation + JRuby guard),
  Hooks (short-circuits + parser dispatch), Scanner (parser parity),
  wiring, docs, lint/test, single breaking-change commit.
- Technology validation: no new deps (`nokogiri ~> 1.15` already ships
  `Nokogiri::HTML5` on CRuby).

## Next Step

Run the Level 2 preflight phase to validate the plan before building.

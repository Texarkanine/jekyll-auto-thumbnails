# Active Context

## Current Task

Fix HTML5 validity regression in `replace_urls` (issue #29): swap default
Nokogiri HTML parser to HTML5, short-circuit no-op pages, and preserve
HTML4 behavior behind a new `auto_thumbnails.parser: html4|html5` config
(breaking change, major version bump).

## Phase

COMPLEXITY-ANALYSIS - COMPLETE

## What Was Done

- Read issue #29 and restated intent; user approved with two clarifications
  (config shape `parser: html4|html5`, JRuby + `html5` hard-errors).
- Initialized memory bank persistent files (`productContext.md`,
  `systemPatterns.md`, `techContext.md`).
- Classified as **Level 2 — Simple Enhancement** (breaking change):
  bug fix affecting multiple components (Configuration + Hooks + tests +
  docs), contained to the HTML rewriting subsystem.

## Next Step

Load Level 2 workflow and begin the planning phase.

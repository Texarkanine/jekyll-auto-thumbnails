# Active Context

## Current Task

Fix HTML5 validity regression in `replace_urls` (issue #29): swap default
Nokogiri HTML parser to HTML5, short-circuit no-op pages, and preserve
HTML4 behavior behind a new `auto_thumbnails.parser: html4|html5` config
(breaking change, major version bump).

## Phase

REFLECT COMPLETE

## Files Modified

- `lib/jekyll-auto-thumbnails.rb` (added `html_parser` require)
- `lib/jekyll-auto-thumbnails/configuration.rb` (parser attr + validation + JRuby guard)
- `lib/jekyll-auto-thumbnails/hooks.rb` (short-circuits + parser dispatch)
- `lib/jekyll-auto-thumbnails/scanner.rb` (parser parity via helper)
- `lib/jekyll-auto-thumbnails/html_parser.rb` (new - parser dispatch module)
- `spec/configuration_spec.rb` (9 new examples)
- `spec/hooks_spec.rb` (9 new examples + existing double updated)
- `spec/scanner_spec.rb` (1 new example + existing double updated)
- `README.md` (parser config docs)

## Key Implementation Decisions

- Took the preflight advisory: extracted `JekyllAutoThumbnails::HtmlParser`
  module as the single dispatch point so the `require "nokogiri/html5"
  unless RUBY_ENGINE == "jruby"` guard lives in exactly one file.
- Validated `parser` strictly: invalid values raise `ArgumentError` rather
  than silently defaulting. User explicitly prioritized correctness.
- JRuby guard lives in `Configuration#parse_parser`, so misconfiguration
  is caught at site-boot time rather than deep in the rewrite path.

## Deviations from Plan

None — built to plan.

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

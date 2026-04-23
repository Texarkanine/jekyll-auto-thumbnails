---
task_id: issue-29-html5-parser
date: 2026-04-23
complexity_level: 2
---

# Reflection: Fix HTML5 validity regression in `replace_urls` (issue #29)

## Summary

Swapped the default HTML parser in `Hooks.replace_urls` and `Scanner.scan_html`
from libxml2-based `Nokogiri::HTML` to `Nokogiri::HTML5`, added
`html.include?("<img")` + no-op short-circuits so untouched pages are returned
by object identity, and exposed `auto_thumbnails.parser: html4 | html5`
(default `html5`) as a breaking-change opt-out. JRuby + `html5` hard-errors
in `Configuration`. All 8 requirements from the project brief shipped; 102
specs green, 0 RuboCop offenses, end-to-end scenario from the issue verified.

## Requirements vs Outcome

Delivered all requirements as planned: HTML5 default, identity return on
no-op, `<img`-less short-circuit, `parser` config, JRuby guard, README
updates, and a comprehensive test suite (19 new examples across 3 specs).
No scope creep, no descoping. The single deferred item (the substantive
breaking-change commit) is intentional and will be created after archive.

## Plan Accuracy

Plan was accurate: the 7 ordered TDD steps held without reordering or
splitting. Preflight's one advisory (extract a shared `HtmlParser` helper)
was taken during build exactly as flagged. The only surprise was small and
positive: Nokogiri 1.19's `require "nokogiri"` already loads `Nokogiri::
HTML5`, so the explicit `require "nokogiri/html5"` ended up being
belt-and-suspenders rather than strictly necessary — but it's the right
idiom and the JRuby guard remains essential.

## Build & QA Observations

Build was clean and linear — each TDD cycle went red → green on the first
try. Two minor RuboCop nudges (redundant `map(&:to_s).join`, single-quote
strings inside interpolation) were auto-correctable and fixed in one pass.
QA found no substantive issues; the two minor observations (cheap
`include?("<img")` pre-filter, CRuby-only `:html5` branch) were both
pre-accepted design choices already documented inline. No rework needed.

## Insights

### Technical

- `Nokogiri::HTML.to_html` injecting `<meta http-equiv="Content-Type">` is
  a load-bearing quirk, not a bug: any HTML rewriting path in this codebase
  that round-trips HTML through libxml2 will duplicate this `<meta>` on
  HTML5 themes. Future rewrite-adjacent work should default to
  `Nokogiri::HTML5.parse` and treat `Nokogiri::HTML` as an opt-in.
- The "return by object identity when no replacement was made" pattern is
  the right default whenever we parse-and-serialize user content.
  `doc.to_html` is never byte-identical to the input, so returning the
  input string itself (not `doc.to_html`) is the only way to avoid
  whitespace/attribute-quoting churn on pages that didn't actually change.

### Process

- When a user-filed issue includes a concrete suggested fix, the intent
  restatement should nonetheless check for decisions the issue left open
  (here: config shape, JRuby policy). Those clarifications made the plan
  stronger and prevented a late pivot.
- Preflight is worth running even for "obviously correct" Level 2 tasks —
  the `HtmlParser` extraction advisory shaped the build and was a real
  improvement, not a ritual finding.

### Million-Dollar Question

If HTML5 parsing had been the foundational assumption from day one, the
plugin would probably never have had a `replace_urls` that round-tripped
every page unconditionally — it's the HTML4-era habit of "parse it, do
your thing, re-serialize, move on" that bakes in the invisible side-effect.
An HTML5-first design naturally pushes toward a "return input unchanged if
nothing changed" contract, because HTML5 serialization preserves byte-for-
byte structure in ways HTML4 serialization does not. In other words: the
short-circuits we added are not a bolt-on patch; they're the contract the
module would have had from the start under an HTML5-first assumption. The
current implementation is about as close to that elegant endpoint as a
Level 2 task can get.

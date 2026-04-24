---
task_id: issue-29-html5-parser
complexity_level: 2
date: 2026-04-23
status: completed
---

# TASK ARCHIVE: Fix HTML5 validity regression in `replace_urls` (issue #29)

## SUMMARY

The default HTML path for URL replacement and scanning was switched from libxml2-based `Nokogiri::HTML` to `Nokogiri::HTML5`, eliminating the spurious duplicate `<meta http-equiv="Content-Type">` that broke HTML5 validity on themes with `<meta charset="utf-8">`. `Hooks.replace_urls` now short-circuits when the URL map is empty, when the HTML contains no `<img` substring, and when no in-`article` `img` was modified—returning the **original input string** by identity to avoid no-op round-trips. A breaking-change config option `auto_thumbnails.parser: html4 | html5` (default `html5`) restores legacy HTML4 parsing where needed. On JRuby, `parser: html5` (including the default) fails fast in `Configuration` with an actionable error, because `Nokogiri::HTML5` is not available there.

## REQUIREMENTS

- **Functional:** HTML5-by-default parsing/serialization; identity return for no matching replacements; short-circuit when no `<img`; `auto_thumbnails.parser` with `html4` / `html5`; JRuby hard-error for `html5`.
- **Non-functional:** Conventional-Commits breaking change for Release Please; README documentation; test coverage for identity behavior, no duplicate `meta http-equiv`, html4 opt-in, JRuby, and invalid `parser` values.
- **Out of scope (honored):** image selection rules, thumbnail generation, hook registration shape, Jekyll 5.

## IMPLEMENTATION

TDD in seven ordered steps: `Configuration#parser` with `VALID_PARSERS`, case-insensitive strings coerced to symbols, strict `ArgumentError` for invalid values, and JRuby guard in `parse_parser`. New `JekyllAutoThumbnails::HtmlParser#parse(html, parser)` as the single dispatch and `require "nokogiri/html5" unless RUBY_ENGINE == "jruby"` location. `Hooks.replace_urls` tracks whether any in-`article` `src` changed; returns unmodified `html` when not. `Scanner.scan_html` and hooks both use the same parser from `Configuration`. `lib/jekyll-auto-thumbnails.rb` requires the new module. `README` documents the option and JRuby.

**Key files:** `lib/jekyll-auto-thumbnails/html_parser.rb` (new), `configuration.rb`, `hooks.rb`, `scanner.rb`, `jekyll-auto-thumbnails.rb`, matching specs, `README.md`.

## TESTING

- `bundle exec rspec`: 102 examples, 0 failures (~90.94% coverage at time of build).
- `bundle exec rubocop`: clean.
- `/niko-qa` semantic pass; issue #29 scenario verified manually (no `<meta http-equiv="Content-Type">` in HTML5 output when replacements occur).

## LESSONS LEARNED

*From the reflection (inlined; reflection file removed after archive):*

- **Technical:** `Nokogiri::HTML` re-serialization injects `Content-Type` meta on HTML5 themes; any future rewrite work should default to `Nokogiri::HTML5` and treat `Nokogiri::HTML` as opt-in. Returning the **input string** when nothing changed is the only way to avoid spurious `to_html` churn; byte identity matters for `document.output`.
- **Process:** When an issue suggests a fix, still nail open decisions (config shape, JRuby policy)—that strengthened the plan. Preflight for Level 2 was not ritual: the shared `HtmlParser` extraction was a real improvement.
- **Design note:** Under an HTML5-first model, "return input if unchanged" is the natural contract; short-circuits are not a bolt-on but the right default.

## PROCESS IMPROVEMENTS

- Keep running preflight on "obvious" L2 work when the plan touches shared parsing/serialization—low cost, catches consolidation wins (e.g. one `require` guard).

## TECHNICAL IMPROVEMENTS

- The cheap `html.include?("<img")` pre-filter can over-include (e.g. strings in comments); it never under-includes, so behavior stays correct; only a micro-optimization miss. No change required unless profiling shows a hotspot.

## NEXT STEPS

- None for this task. If a substantive `feat(hooks)!:` commit with `BREAKING CHANGE` footer was still intended for Release Please, confirm on `main` / release branch that it exists; the reflection had noted a deferred breaking-change commit—verify against current git history and release process.

## CREATIVE / TROUBLESHOOTING

- **Creative phase:** No `memory-bank/active/creative/` artifacts for this task; nothing to inline.
- **Troubleshooting:** No `memory-bank/active/troubleshooting/` logs; per policy, such logs are not archived verbatim.

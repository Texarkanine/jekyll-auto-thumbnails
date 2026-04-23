# Progress

## Task

Fix HTML5 validity regression in `replace_urls` (issue #29). Default parser
becomes `Nokogiri::HTML5`, `replace_urls` short-circuits when no `<img` or no
matches, and a new `auto_thumbnails.parser: html4|html5` config restores the
legacy HTML4 behavior. JRuby + `html5` hard-errors (HTML5 parser is CRuby-only
in Nokogiri). Shipped as a breaking change via Conventional Commits so
Release Please issues a major version bump.

**Complexity:** Level 2

## Phase Log

- **COMPLEXITY-ANALYSIS — COMPLETE** — Classified Level 2. Multiple components
  touched (Configuration, Hooks, possibly Scanner, tests, docs) but contained
  to the HTML rewriting subsystem; no architectural changes.
- **PLAN — COMPLETE** — Produced 7-step TDD-first plan with 13 testable
  behaviors, no new dependencies. Plan covers Configuration (parser
  attribute + validation + JRuby guard), Hooks (short-circuits + parser
  dispatch), Scanner (parser parity), wiring, docs, lint/test, and a single
  `feat(hooks)!:` breaking-change commit.
- **PREFLIGHT — PASS** — Validated plan against codebase reality:
  reproduced the `<meta http-equiv>` injection locally on Nokogiri 1.19.2,
  confirmed `Nokogiri::HTML5` is autoloaded after `require "nokogiri"`,
  confirmed no existing parser-selection code to conflict with, and verified
  test/convention alignment. One advisory: extract a tiny shared HTML-parser
  helper to concentrate the JRuby `require` guard — within scope, will do
  during build.
- **BUILD — COMPLETE** — Implemented all 7 plan steps.
  `Configuration#parser` validates strictly and hard-errors on JRuby+html5.
  New `JekyllAutoThumbnails::HtmlParser` module dispatches between
  `Nokogiri::HTML5.parse` and `Nokogiri::HTML`. `Hooks.replace_urls` now
  short-circuits on empty `url_map`, missing `<img`, and no-match
  iterations — returning the input by identity to avoid spurious
  round-trips. `Scanner.scan_html` uses the same helper. README updated.
  Issue-29 scenario reproduced and fixed end-to-end. Tests: 102 examples,
  0 failures, 90.94% coverage. RuboCop: 22 files, 0 offenses. The
  substantive `feat(hooks)!:` commit will be created at the end of the
  workflow so it carries all build + QA + reflect changes together.
- **QA — PASS** — Semantic review against KISS/DRY/YAGNI/Completeness/
  Regression/Integrity/Documentation: clean, no fixable issues. Minor
  observations documented but non-blocking: the cheap `html.include?(
  "<img")` pre-filter can over-include (false-positive short-circuit miss
  inside comments/scripts), never under-include; `HtmlParser`'s :html5
  branch is CRuby-only by design and protected upstream by
  `Configuration#parse_parser`'s JRuby hard-error.
- **REFLECT — COMPLETE** — Wrote reflection at
  `memory-bank/active/reflection/reflection-issue-29-html5-parser.md`.
  Reconciled persistent files: surgical updates to `systemPatterns.md`
  (HTML4 footgun narrative rewritten to reflect the HTML5-by-default
  contract and the identity-return short-circuit), `techContext.md`
  (Nokogiri entry updated with the new config exposure + JRuby policy),
  and `productContext.md` (key constraints note JRuby-needs-`html4`).
  Ready for archive.

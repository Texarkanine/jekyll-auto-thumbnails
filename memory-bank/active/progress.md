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

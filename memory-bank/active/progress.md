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
  to the HTML rewriting subsystem; no architectural changes. Next: Plan phase.
